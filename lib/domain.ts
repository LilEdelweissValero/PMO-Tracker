export const PROJECT_STATES = [
  "Pipeline",
  "Planned",
  "Active",
  "On Hold",
  "Cancelled",
  "Closed",
] as const;
export const TERMINAL_STATES = ["Cancelled", "Closed"] as const;
export const GROUPS = ["PMO", "Developer", "System Owner"] as const;
export type ProjectState = (typeof PROJECT_STATES)[number];
export type ParticipantGroup = (typeof GROUPS)[number];

export function isTerminal(state: ProjectState) {
  return TERMINAL_STATES.includes(state as "Cancelled" | "Closed");
}
export function assertTransition(from: ProjectState, to: ProjectState) {
  if (isTerminal(from))
    throw new Error(
      `${from} is irreversible. Create a new Project for resumed work.`,
    );
  if (from === to) throw new Error("Choose a different Project State.");
}
export function requireBallOwner(state: ProjectState, ownerId?: string | null) {
  if (!isTerminal(state) && !ownerId)
    throw new Error("A non-terminal Project must have exactly one Ball Owner.");
}
export function stageVariance(planned: string, completed: string) {
  const p = Date.parse(`${planned}T00:00:00+08:00`),
    c = Date.parse(completed);
  const days = Math.round((c - p) / 86_400_000);
  return {
    days,
    label: days < 0 ? "Early" : days > 0 ? "Delayed" : "On Time",
  } as const;
}
export type Span = { start: string; end?: string | null };
export function overlapMs(a: Span, b: Span, now = Date.now()) {
  const start = Math.max(Date.parse(a.start), Date.parse(b.start));
  const end = Math.min(
    a.end ? Date.parse(a.end) : now,
    b.end ? Date.parse(b.end) : now,
  );
  return Math.max(0, end - start);
}
export function netOwnershipMs(period: Span, holds: Span[], now = Date.now()) {
  const periodStart = Date.parse(period.start);
  const periodEnd = period.end ? Date.parse(period.end) : now;
  const gross = Math.max(0, periodEnd - periodStart);
  const overlaps = holds
    .map((hold) => ({
      start: Math.max(periodStart, Date.parse(hold.start)),
      end: Math.min(periodEnd, hold.end ? Date.parse(hold.end) : now),
    }))
    .filter((hold) => hold.end > hold.start)
    .sort((left, right) => left.start - right.start);

  let paused = 0;
  let mergedStart = 0;
  let mergedEnd = 0;
  for (const overlap of overlaps) {
    if (overlap.start > mergedEnd) {
      paused += Math.max(0, mergedEnd - mergedStart);
      mergedStart = overlap.start;
      mergedEnd = overlap.end;
    } else {
      mergedEnd = Math.max(mergedEnd, overlap.end);
    }
  }
  paused += Math.max(0, mergedEnd - mergedStart);

  return Math.max(0, gross - paused);
}
