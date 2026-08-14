import "server-only";

import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/database.types";
import { readServerEnvironment } from "@/lib/env";

export function createAdminClient() {
  const environment = readServerEnvironment();
  if (environment.demoMode || !environment.serviceRoleKey) {
    throw new Error("The Supabase service-role client is not configured.");
  }
  return createClient<Database>(
    environment.supabaseUrl,
    environment.serviceRoleKey,
    {
      auth: { autoRefreshToken: false, persistSession: false },
    },
  );
}
