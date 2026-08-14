import "server-only";

import type { Database } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import { listResult } from "./result";

export type ProjectAuditRow =
  Database["public"]["Functions"]["report_project_audit"]["Returns"][number];

export async function listProjectAudit(
  projectId?: string,
  client?: DataClient,
) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase.rpc("report_project_audit", {
    ...(projectId ? { target_project_id: projectId } : {}),
  });
  return listResult(data, error);
}
