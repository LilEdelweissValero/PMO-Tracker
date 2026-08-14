import "server-only";

import type { Tables } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import { listResult } from "./result";

export type DashboardQueueItem = Tables<"project_dashboard_queue">;

export async function listDashboardQueue(limit = 20, client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("project_dashboard_queue")
    .select("*")
    .order("waiting_seconds", { ascending: false })
    .limit(limit);
  return listResult(data, error);
}
