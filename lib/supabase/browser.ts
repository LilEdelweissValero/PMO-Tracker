"use client";

import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/database.types";
import { getPublicEnvironment } from "@/lib/env";

let browserClient: SupabaseClient<Database> | undefined;

export function createClient() {
  const environment = getPublicEnvironment();
  if (environment.demoMode) {
    throw new Error(
      "Supabase is unavailable while explicit demo mode is enabled.",
    );
  }
  browserClient ??= createBrowserClient<Database>(
    environment.supabaseUrl,
    environment.supabasePublishableKey,
  );
  return browserClient;
}
