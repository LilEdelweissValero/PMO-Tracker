import { redirect } from "next/navigation";
import { createClient } from "./supabase/server";
import { isDemo } from "./demo";
export type Role = "administrator" | "pmo_officer" | "leadership_viewer";
export async function session() {
  if (isDemo) return null;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;
  const { data: profile } = await supabase
    .from("profiles")
    .select("id, person_id, active, profile_roles(role)")
    .eq("id", user.id)
    .single();
  if (!profile?.active) return null;
  const roles = (
    (profile.profile_roles ?? []) as unknown as { role: Role }[]
  ).map((r) => r.role);
  return { user, profile, roles };
}
export async function requireSession() {
  const value = await session();
  if (!value) redirect("/login");
  return value;
}
export function hasRole(roles: Role[], role: Role) {
  return roles.includes(role);
}
