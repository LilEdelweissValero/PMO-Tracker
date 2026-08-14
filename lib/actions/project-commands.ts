import "server-only";

import type { Json } from "@/lib/database.types";
import { dataClient, type DataClient } from "@/lib/data/client";
import { mapPostgrestError, type DataResult } from "@/lib/data/result";

export async function createProject(
  input: Json,
  client?: DataClient,
): Promise<DataResult<string>> {
  const supabase = await dataClient(client);
  const { data, error } = await supabase.rpc("create_project", { input });
  if (error) return mapPostgrestError(error);
  return { status: "success", data };
}

export async function appendProjectEvent(
  input: Json,
  client?: DataClient,
): Promise<DataResult<string>> {
  const supabase = await dataClient(client);
  const { data, error } = await supabase.rpc("append_project_event", { input });
  if (error) return mapPostgrestError(error);
  return { status: "success", data };
}
