import { execFileSync } from "node:child_process";
import { createClient } from "@supabase/supabase-js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import type { Database } from "@/lib/database.types";
import { listProjectAudit } from "@/lib/data/audit";
import { listDashboardQueue } from "@/lib/data/dashboard";
import { listDepartments } from "@/lib/data/directory";
import { getProjectByCode } from "@/lib/data/projects";

type LocalStatus = Record<string, string | undefined>;

function localStatus() {
  return JSON.parse(
    execFileSync("supabase", ["status", "-o", "json"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "inherit"],
    }),
  ) as LocalStatus;
}

describe("server repositories against local Supabase", () => {
  const departmentId = crypto.randomUUID();
  const personId = crypto.randomUUID();
  const email = `repository-${crypto.randomUUID()}@test.invalid`;
  const password = "Repository-test-password-42!";
  let serviceClient: ReturnType<typeof createClient<Database>>;
  let authenticatedClient: ReturnType<typeof createClient<Database>>;
  let anonymousClient: ReturnType<typeof createClient<Database>>;
  let authUserId: string;

  beforeAll(async () => {
    const status = localStatus();
    const url = status.API_URL ?? status.api_url;
    const serviceKey =
      status.SERVICE_ROLE_KEY ?? status.service_role_key ?? status.SECRET_KEY;
    const publicKey =
      status.PUBLISHABLE_KEY ?? status.publishable_key ?? status.ANON_KEY;
    if (!url || !serviceKey || !publicKey) {
      throw new Error("Local Supabase did not return the required test keys.");
    }
    serviceClient = createClient<Database>(url, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    anonymousClient = createClient<Database>(url, publicKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const fixture = await serviceClient.from("departments").insert({
      id: departmentId,
      name: "Repository Integration Department",
    });
    if (fixture.error) throw fixture.error;
    const person = await serviceClient.from("people").insert({
      id: personId,
      department_id: departmentId,
      name: "Repository Test Viewer",
      position: "Leadership",
      username: `repository.${personId}`,
    });
    if (person.error) throw person.error;
    const authUser = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (authUser.error) throw authUser.error;
    authUserId = authUser.data.user.id;
    const profile = await serviceClient.from("profiles").insert({
      id: authUserId,
      person_id: personId,
      email,
    });
    const role = await serviceClient.from("profile_roles").insert({
      profile_id: authUserId,
      role: "leadership_viewer",
    });
    if (profile.error || role.error) throw profile.error ?? role.error;
    authenticatedClient = createClient<Database>(url, publicKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const signIn = await authenticatedClient.auth.signInWithPassword({
      email,
      password,
    });
    if (signIn.error) throw signIn.error;
  });

  afterAll(async () => {
    if (authUserId) await serviceClient.auth.admin.deleteUser(authUserId);
    await serviceClient.from("people").delete().eq("id", personId);
    await serviceClient.from("departments").delete().eq("id", departmentId);
  });

  it("returns typed directory rows on a successful query", async () => {
    const result = await listDepartments(authenticatedClient);
    expect(result.status).toBe("success");
    if (result.status === "success") {
      expect(result.data).toContainEqual(
        expect.objectContaining({
          name: "Repository Integration Department",
          active: true,
        }),
      );
    }
  });

  it("distinguishes a missing Project from an empty queue", async () => {
    const missing = await getProjectByCode(
      "DOES-NOT-EXIST",
      authenticatedClient,
    );
    const emptyQueue = await listDashboardQueue(20, authenticatedClient);
    expect(missing).toEqual({ status: "not_found" });
    expect(emptyQueue).toEqual({ status: "empty" });
  });

  it("maps an anonymous audit call to permission denied", async () => {
    const result = await listProjectAudit(undefined, anonymousClient);
    expect(result.status).toBe("permission_denied");
  });
});
