import "server-only";

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "@/lib/database.types";
import { getPublicEnvironment } from "@/lib/env";

export async function createClient() {
  const environment = getPublicEnvironment();
  if (environment.demoMode) {
    throw new Error(
      "Supabase is unavailable while explicit demo mode is enabled.",
    );
  }
  const store = await cookies();
  return createServerClient<Database>(
    environment.supabaseUrl,
    environment.supabasePublishableKey,
    {
      cookies: {
        getAll: () => store.getAll(),
        setAll: (items) => {
          try {
            items.forEach(({ name, value, options }) =>
              store.set(name, value, options),
            );
          } catch {
            // Server Components cannot mutate cookies. proxy.ts refreshes them
            // before rendering; Server Actions and Route Handlers can write here.
          }
        },
      },
    },
  );
}
