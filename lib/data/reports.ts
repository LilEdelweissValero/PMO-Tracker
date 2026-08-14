import "server-only";

import type { Database, Tables } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import { listResult } from "./result";

export type TurnaroundRow = Tables<"project_turnaround_report">;
export type AsOfRow =
  Database["public"]["Functions"]["report_projects_as_of"]["Returns"][number];

export async function listTurnaround(projectId?: string, client?: DataClient) {
  const supabase = await dataClient(client);
  let query = supabase
    .from("project_turnaround_report")
    .select("*")
    .order("span_start", { ascending: false });
  if (projectId) query = query.eq("project_id", projectId);
  const { data, error } = await query;
  return listResult(data, error);
}

export async function listProjectsAsOf(
  asOfTime: string,
  projectId?: string,
  client?: DataClient,
) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase.rpc("report_projects_as_of", {
    as_of_time: asOfTime,
    ...(projectId ? { target_project_id: projectId } : {}),
  });
  return listResult(data, error);
}
