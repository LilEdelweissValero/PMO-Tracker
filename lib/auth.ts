import "server-only";

import { redirect } from "next/navigation";
import { isDemo } from "./demo";
import { createClient } from "./supabase/server";
export { safeReturnPath } from "./auth-paths";

export type Role = "administrator" | "pmo_officer" | "leadership_viewer";
export type ActiveSession = {
  kind: "active";
  userId: string;
  email: string | null;
  personId: string;
  personName: string;
  roles: Role[];
};
export type SessionState =
  | ActiveSession
  | { kind: "anonymous" }
  | { kind: "inactive"; userId: string; email: string | null };

const demoSession: ActiveSession = {
  kind: "active",
  userId: "demo",
  email: null,
  personId: "demo",
  personName: "Demo Preview",
  roles: ["administrator", "pmo_officer", "leadership_viewer"],
};

export async function sessionState(): Promise<SessionState> {
  if (isDemo) return demoSession;

  const supabase = await createClient();
  const { data: claimsData, error: claimsError } =
    await supabase.auth.getClaims();
  if (claimsError || !claimsData?.claims.sub) return { kind: "anonymous" };

  const userId = claimsData.claims.sub;
  const email =
    typeof claimsData.claims.email === "string"
      ? claimsData.claims.email
      : null;
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id, person_id, people!inner(name), profile_roles(role)")
    .eq("id", userId)
    .maybeSingle();

  if (profileError) throw profileError;
  if (!profile) return { kind: "inactive", userId, email };

  return {
    kind: "active",
    userId,
    email,
    personId: profile.person_id,
    personName: profile.people.name,
    roles: profile.profile_roles.map(({ role }) => role),
  };
}

export async function session() {
  const state = await sessionState();
  return state.kind === "active" ? state : null;
}

export async function requireSession() {
  const state = await sessionState();
  if (state.kind === "anonymous") redirect("/login");
  if (state.kind === "inactive") redirect("/permission-denied");
  return state;
}

export async function requireAnyRole(requiredRoles: Role[]) {
  const activeSession = await requireSession();
  if (!requiredRoles.some((role) => activeSession.roles.includes(role))) {
    redirect("/permission-denied");
  }
  return activeSession;
}

export function hasRole(roles: Role[], role: Role) {
  return roles.includes(role);
}
