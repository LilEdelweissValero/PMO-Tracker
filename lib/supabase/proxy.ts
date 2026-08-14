import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import type { Database } from "@/lib/database.types";
import { getPublicEnvironment } from "@/lib/env";

export async function refreshSession(request: NextRequest) {
  const environment = getPublicEnvironment();
  if (environment.demoMode) {
    return {
      response: NextResponse.next({ request }),
      userId: "demo",
      demoMode: true,
    } as const;
  }

  let response = NextResponse.next({ request });
  const supabase = createServerClient<Database>(
    environment.supabaseUrl,
    environment.supabasePublishableKey,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (items, headers) => {
          items.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          items.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
          Object.entries(headers).forEach(([name, value]) =>
            response.headers.set(name, value),
          );
        },
      },
    },
  );

  const { data } = await supabase.auth.getClaims();
  return {
    response,
    userId: data?.claims.sub ?? null,
    demoMode: false,
  } as const;
}
