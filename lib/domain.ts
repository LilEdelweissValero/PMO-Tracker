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
  const gross =
    (period.end ? Date.parse(period.end) : now) - Date.parse(period.start);
  return Math.max(
    0,
    gross - holds.reduce((sum, hold) => sum + overlapMs(period, hold, now), 0),
  );
}
