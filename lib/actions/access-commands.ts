import "server-only";

import type { Json } from "@/lib/database.types";
import { dataClient, type DataClient } from "@/lib/data/client";
import { mapPostgrestError, type DataResult } from "@/lib/data/result";

export async function provisionProfile(
  input: Json,
  client?: DataClient,
): Promise<DataResult<string>> {
  const supabase = await dataClient(client);
  const { data, error } = await supabase.rpc("provision_profile", { input });
  if (error) return mapPostgrestError(error);
  return { status: "success", data };
}

export async function manageProfileAccess(
  input: Json,
  client?: DataClient,
): Promise<DataResult<string>> {
  const supabase = await dataClient(client);
  const { data, error } = await supabase.rpc("manage_profile_access", {
    input,
  });
  if (error) return mapPostgrestError(error);
  return { status: "success", data };
}
