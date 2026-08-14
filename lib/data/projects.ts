import "server-only";

import type { Enums, Tables } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import {
  listResult,
  mapPostgrestError,
  singleResult,
  type DataResult,
} from "./result";

export type ProjectListItem = Pick<
  Tables<"projects">,
  | "id"
  | "code"
  | "name"
  | "state"
  | "version"
  | "updated_at"
  | "archived_at"
  | "priority_id"
> & {
  priority: Pick<Tables<"priorities">, "name">;
  stage: Pick<Tables<"project_stages">, "name"> | null;
  pmo_officer: Pick<Tables<"people">, "id" | "name">;
  ball_owner: Pick<Tables<"people">, "id" | "name"> | null;
  ball_owner_group: Enums<"participant_group"> | null;
  waiting_seconds: number | null;
};
type ProjectListRecord = Omit<
  ProjectListItem,
  "stage" | "ball_owner_group" | "waiting_seconds"
> & {
  current_stage_id: string | null;
};
export type ProjectListFilters = {
  query?: string;
  state?: Enums<"project_state">;
  priorityId?: string;
  includeArchived?: boolean;
  page?: number;
  pageSize?: number;
};
export type ProjectPage = {
  items: ProjectListItem[];
  page: number;
  pageSize: number;
  total: number;
};

export type ProjectWorkspace = Tables<"projects"> & {
  priorities: Pick<Tables<"priorities">, "name">;
  pmo_officer: Pick<Tables<"people">, "name">;
  ball_owner: Pick<Tables<"people">, "name"> | null;
  project_stages: Tables<"project_stages">[];
  project_participant_assignments: (Tables<"project_participant_assignments"> & {
    people: Pick<Tables<"people">, "id" | "name">;
  })[];
  project_references: Tables<"project_references">[];
  project_system_scopes: Tables<"project_system_scopes">[];
};

function safeSearch(value: string) {
  return value
    .replace(/[,%_().]/g, " ")
    .trim()
    .slice(0, 100);
}

export async function listProjects(
  filters: ProjectListFilters = {},
  client?: DataClient,
): Promise<DataResult<ProjectPage>> {
  const supabase = await dataClient(client);
  const page = Math.max(1, filters.page ?? 1);
  const pageSize = Math.min(100, Math.max(1, filters.pageSize ?? 25));
  const first = (page - 1) * pageSize;
  let query = supabase
    .from("projects")
    .select(
      `id, code, name, state, version, updated_at, archived_at, priority_id, current_stage_id, priority:priorities!inner(name), pmo_officer:people!projects_pmo_officer_id_fkey(id, name), ball_owner:people!projects_ball_owner_id_fkey(id, name)`,
      { count: "exact" },
    )
    .order("updated_at", { ascending: false })
    .range(first, first + pageSize - 1);
  if (filters.state) query = query.eq("state", filters.state);
  if (filters.priorityId) query = query.eq("priority_id", filters.priorityId);
  if (!filters.includeArchived) query = query.is("archived_at", null);
  const search = safeSearch(filters.query ?? "");
  if (search) {
    query = query.or(`code.ilike.%${search}%,name.ilike.%${search}%`);
  }
  const { data, error, count } = await query;
  const result = listResult(
    (data ?? null) as ProjectListRecord[] | null,
    error,
  );
  if (result.status !== "success") return result;
  const stageIds = [
    ...new Set(
      result.data.flatMap(({ current_stage_id }) =>
        current_stage_id ? [current_stage_id] : [],
      ),
    ),
  ];
  const stages = stageIds.length
    ? await supabase
        .from("project_stages")
        .select("id, name")
        .in("id", stageIds)
    : { data: [], error: null };
  if (stages.error) return mapPostgrestError(stages.error);
  const stageNames = new Map(
    (stages.data ?? []).map((stage) => [stage.id, stage.name]),
  );
  const projectIds = result.data.map(({ id }) => id);
  const [participants, waiting] = await Promise.all([
    supabase
      .from("project_participant_assignments")
      .select("project_id, person_id, participant_group")
      .in("project_id", projectIds)
      .is("effective_to", null),
    supabase
      .from("project_dashboard_queue")
      .select("project_id, waiting_seconds")
      .in("project_id", projectIds),
  ]);
  if (participants.error) return mapPostgrestError(participants.error);
  if (waiting.error) return mapPostgrestError(waiting.error);
  const groups = new Map(
    (participants.data ?? []).map((assignment) => [
      `${assignment.project_id}:${assignment.person_id}`,
      assignment.participant_group,
    ]),
  );
  const waits = new Map(
    (waiting.data ?? []).map((item) => [item.project_id, item.waiting_seconds]),
  );
  const items = result.data.map(({ current_stage_id, ...project }) => ({
    ...project,
    stage: current_stage_id
      ? { name: stageNames.get(current_stage_id) ?? "Unknown Stage" }
      : null,
    ball_owner_group: project.ball_owner
      ? (groups.get(`${project.id}:${project.ball_owner.id}`) ?? null)
      : null,
    waiting_seconds: waits.get(project.id) ?? null,
  }));
  return {
    status: "success",
    data: { items, page, pageSize, total: count ?? 0 },
  };
}

export async function getProjectByCode(code: string, client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("projects")
    .select(
      `*, priorities!inner(name), pmo_officer:people!projects_pmo_officer_id_fkey(name), ball_owner:people!projects_ball_owner_id_fkey(name)`,
    )
    .eq("code", decodeURIComponent(code))
    .maybeSingle();
  const projectResult = singleResult(data, error);
  if (projectResult.status !== "success") return projectResult;
  const project = projectResult.data;
  const [stages, participants, references, scopes] = await Promise.all([
    supabase
      .from("project_stages")
      .select("*")
      .eq("project_id", project.id)
      .order("sort_order"),
    supabase
      .from("project_participant_assignments")
      .select("*, people!inner(id, name)")
      .eq("project_id", project.id)
      .order("effective_from"),
    supabase
      .from("project_references")
      .select("*")
      .eq("project_id", project.id)
      .order("label"),
    supabase
      .from("project_system_scopes")
      .select("*")
      .eq("project_id", project.id),
  ]);
  for (const related of [stages, participants, references, scopes]) {
    if (related.error) return mapPostgrestError(related.error);
  }
  return {
    status: "success" as const,
    data: {
      ...project,
      project_stages: stages.data ?? [],
      project_participant_assignments: (participants.data ??
        []) as ProjectWorkspace["project_participant_assignments"],
      project_references: references.data ?? [],
      project_system_scopes: scopes.data ?? [],
    } as ProjectWorkspace,
  };
}
