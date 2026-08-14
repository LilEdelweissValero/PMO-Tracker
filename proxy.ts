import { NextResponse, type NextRequest } from "next/server";
import { refreshSession } from "@/lib/supabase/proxy";

function redirectWithSession(
  request: NextRequest,
  destination: string,
  sessionResponse: NextResponse,
) {
  const redirectResponse = NextResponse.redirect(
    new URL(destination, request.url),
  );
  sessionResponse.cookies
    .getAll()
    .forEach((cookie) => redirectResponse.cookies.set(cookie));
  for (const header of ["cache-control", "expires", "pragma"]) {
    const value = sessionResponse.headers.get(header);
    if (value) redirectResponse.headers.set(header, value);
  }
  return redirectResponse;
}

export async function proxy(request: NextRequest) {
  const session = await refreshSession(request);
  if (session.demoMode) return session.response;

  const { pathname, search } = request.nextUrl;
  const isLogin = pathname === "/login";
  const isPermissionDenied = pathname === "/permission-denied";

  if (!session.userId && !isLogin) {
    const returnTo = `${pathname}${search}`;
    return redirectWithSession(
      request,
      `/login?returnTo=${encodeURIComponent(returnTo)}`,
      session.response,
    );
  }
  if (session.userId && isLogin) {
    return redirectWithSession(request, "/dashboard", session.response);
  }
  if (!session.userId && isPermissionDenied) {
    return redirectWithSession(request, "/login", session.response);
  }
  return session.response;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
