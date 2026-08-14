import "server-only";

import type { Database } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import { listResult } from "./result";

export type ProjectHistoryEvent =
  Database["public"]["Functions"]["report_project_history"]["Returns"][number];

export async function listProjectHistory(
  projectId: string,
  client?: DataClient,
) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase.rpc("report_project_history", {
    target_project_id: projectId,
  });
  return listResult(data, error);
}
