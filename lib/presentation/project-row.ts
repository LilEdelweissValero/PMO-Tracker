import type { Tables } from "@/lib/database.types";
import type { ProjectRow } from "@/lib/demo";
import type { ProjectListItem } from "@/lib/data/projects";
import { duration } from "@/lib/time";

type QueueRow =
  | Tables<"project_dashboard_queue">
  | Tables<"project_ball_queue">;

export function queueProjectRow(row: QueueRow): ProjectRow | null {
  if (
    !row.project_code ||
    !row.project_name ||
    !row.state ||
    !row.priority_name ||
    !row.ball_owner_name ||
    !row.ball_owner_group ||
    !row.pmo_officer_name
  ) {
    return null;
  }
  const seconds =
    "held_seconds" in row ? row.held_seconds : row.waiting_seconds;
  return {
    code: row.project_code,
    name: row.project_name,
    state: row.state,
    priority: row.priority_name,
    stage: row.current_stage_name ?? "Not started",
    owner: row.ball_owner_name,
    group: row.ball_owner_group,
    held: duration((seconds ?? 0) * 1000),
    pmo: row.pmo_officer_name,
  };
}

export function listedProjectRow(row: ProjectListItem): ProjectRow | null {
  if (!row.ball_owner || !row.ball_owner_group) return null;
  return {
    code: row.code,
    name: row.name,
    state: row.state,
    priority: row.priority.name,
    stage: row.stage?.name ?? "Not started",
    owner: row.ball_owner.name,
    group: row.ball_owner_group,
    held:
      row.waiting_seconds === null ? "—" : duration(row.waiting_seconds * 1000),
    pmo: row.pmo_officer.name,
  };
}
