import "server-only";

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/database.types";
import { createClient } from "@/lib/supabase/server";

export type DataClient = SupabaseClient<Database>;

export async function dataClient(client?: DataClient) {
  return client ?? createClient();
}
