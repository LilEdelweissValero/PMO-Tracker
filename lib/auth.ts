import "server-only";

import { cache } from "react";
import { redirect } from "next/navigation";
import { getProfileForUser } from "./data/session";
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

const loadSessionState = async (): Promise<SessionState> => {
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
  const profileResult = await getProfileForUser(userId, supabase);
  if (profileResult.status === "not_found") {
    return { kind: "inactive", userId, email };
  }
  if (profileResult.status !== "success") {
    throw new Error(
      "issue" in profileResult
        ? profileResult.issue.message
        : "Unable to load the signed-in Profile.",
    );
  }
  const profile = profileResult.data;

  return {
    kind: "active",
    userId,
    email,
    personId: profile.person_id,
    personName: profile.people.name,
    roles: profile.profile_roles.map(({ role }) => role),
  };
};

export const sessionState = cache(loadSessionState);

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
