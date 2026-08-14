import "server-only";

import type { Tables } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import { listResult } from "./result";

export type PersonDirectoryRow = Pick<
  Tables<"people">,
  "id" | "name" | "username" | "position" | "department_id" | "active"
> & { departments: Pick<Tables<"departments">, "name"> };

export async function listDepartments(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("departments")
    .select("*")
    .order("active", { ascending: false })
    .order("name");
  return listResult(data, error);
}

export async function listPeople(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("people")
    .select(
      "id, name, username, position, department_id, active, departments!inner(name)",
    )
    .order("active", { ascending: false })
    .order("name");
  return listResult((data ?? null) as PersonDirectoryRow[] | null, error);
}

export async function listSystems(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("systems")
    .select("*, modules(*)")
    .order("active", { ascending: false })
    .order("name");
  return listResult(data, error);
}

export async function listUnlinkedActivePeople(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data: profiles, error: profilesError } = await supabase
    .from("profiles")
    .select("person_id");
  if (profilesError) return listResult<never>(null, profilesError);
  let query = supabase
    .from("people")
    .select("id, name, position")
    .eq("active", true)
    .order("name");
  const linkedIds = (profiles ?? []).map(({ person_id }) => person_id);
  if (linkedIds.length)
    query = query.not("id", "in", `(${linkedIds.join(",")})`);
  const { data, error } = await query;
  return listResult(data, error);
}
