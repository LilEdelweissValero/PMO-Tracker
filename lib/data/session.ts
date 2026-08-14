import "server-only";

import type { Tables } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import { listResult, singleResult } from "./result";

export type ProfileWithAccess = Pick<
  Tables<"profiles">,
  "id" | "person_id" | "email" | "active" | "created_at"
> & {
  people: Pick<Tables<"people">, "name">;
  profile_roles: Array<Pick<Tables<"profile_roles">, "role">>;
};

const profileSelection =
  "id, person_id, email, active, created_at, people!inner(name), profile_roles(role)";

export async function getProfileForUser(userId: string, client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("profiles")
    .select(profileSelection)
    .eq("id", userId)
    .maybeSingle();
  return singleResult(data as ProfileWithAccess | null, error);
}

export async function listProfiles(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("profiles")
    .select(profileSelection)
    .order("created_at");
  return listResult((data ?? null) as ProfileWithAccess[] | null, error);
}
