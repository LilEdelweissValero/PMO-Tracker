import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { expect, test } from "playwright/test";
import type { Database } from "../../lib/database.types";
import { provisionApplicationAccount } from "../../lib/provisioning";

const password = "Browser-test-password-42!";
const nonce = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
const activeEmail = "browser.admin@auth.test";
const inactiveEmail = `inactive-${nonce}@auth.test`;
const invitedEmail = `invited-${nonce}@auth.test`;
const departmentId = "d0000000-0000-4000-8000-000000000501";
const personId = "10000000-0000-4000-8000-000000000501";
const invitedPersonId = crypto.randomUUID();
let activeUserId: string;
let inactiveUserId: string;
let invitedUserId: string | undefined;
let admin: SupabaseClient<Database>;

test.beforeAll(async () => {
  admin = createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );
  const existingUsers = await admin.auth.admin.listUsers({ perPage: 1000 });
  if (existingUsers.error) throw existingUsers.error;
  const staleInvitations = existingUsers.data.users.filter((user) =>
    user.email?.startsWith("invited-"),
  );
  for (const user of staleInvitations) {
    const deleted = await admin.auth.admin.deleteUser(user.id);
    if (deleted.error) throw deleted.error;
  }
  const stalePeople = await admin
    .from("people")
    .delete()
    .like("username", "invited.%");
  if (stalePeople.error) throw stalePeople.error;
  const existingAdmin = existingUsers.data.users.find(
    (user) => user.email === activeEmail,
  );
  const activeUser = existingAdmin
    ? { data: { user: existingAdmin }, error: null }
    : await admin.auth.admin.createUser({
        email: activeEmail,
        password,
        email_confirm: true,
      });
  const inactiveUser = await admin.auth.admin.createUser({
    email: inactiveEmail,
    password,
    email_confirm: true,
  });
  if (activeUser.error || inactiveUser.error) {
    throw activeUser.error ?? inactiveUser.error;
  }
  activeUserId = activeUser.data.user.id;
  inactiveUserId = inactiveUser.data.user.id;

  const department = await admin
    .from("departments")
    .upsert({ id: departmentId, name: "Browser Test Department" });
  const person = await admin.from("people").upsert({
    id: personId,
    department_id: departmentId,
    name: "Browser Test Administrator",
    position: "Administrator",
    username: "browser.test.admin",
  });
  const profile = await admin
    .from("profiles")
    .upsert({ id: activeUserId, person_id: personId, email: activeEmail });
  const role = await admin.from("profile_roles").upsert([
    { profile_id: activeUserId, role: "administrator" },
    { profile_id: activeUserId, role: "leadership_viewer" },
  ]);
  const invitedPerson = await admin.from("people").insert({
    id: invitedPersonId,
    department_id: departmentId,
    name: `Invited PMO ${nonce}`,
    position: "PMO Officer",
    username: `invited.${nonce}`,
  });
  for (const result of [department, person, profile, role, invitedPerson]) {
    if (result.error) throw result.error;
  }
});

test.afterAll(async () => {
  if (!admin) return;
  if (!invitedUserId) {
    const users = await admin.auth.admin.listUsers({ perPage: 1000 });
    invitedUserId = users.data.users.find(
      (user) => user.email === invitedEmail,
    )?.id;
  }
  if (invitedUserId) await admin.auth.admin.deleteUser(invitedUserId);
  await admin.from("people").delete().eq("id", invitedPersonId);
  if (inactiveUserId) await admin.auth.admin.deleteUser(inactiveUserId);
});

test("anonymous routes and exports return to login", async ({
  page,
  request,
}) => {
  await page.goto("/projects?state=Active");
  await expect(page).toHaveURL(
    /\/login\?returnTo=%2Fprojects%3Fstate%3DActive$/,
  );
  await expect(
    page.getByRole("heading", { name: "Welcome back." }),
  ).toBeVisible();

  const exportResponse = await request.get("/api/exports/as-of", {
    maxRedirects: 0,
  });
  expect(exportResponse.status()).toBeGreaterThanOrEqual(300);
  expect(exportResponse.status()).toBeLessThan(400);
  expect(exportResponse.headers().location).toContain("/login?returnTo=");
});

test("active login honors a safe return path, refreshes, and signs out", async ({
  page,
}) => {
  await page.goto("/login?returnTo=%2Fball");
  await page.getByLabel("Email").fill(activeEmail);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page).toHaveURL(/\/ball$/);
  await expect(page.getByText("Browser Test Administrator")).toBeVisible();

  await page.reload();
  await expect(page).toHaveURL(/\/ball$/);
  await page.getByRole("button", { name: "Log out" }).click();
  await expect(page).toHaveURL(/\/login$/);

  await page.goto("/dashboard");
  await expect(page).toHaveURL(/\/login\?returnTo=%2Fdashboard$/);
});

test("inactive profiles are denied and can clear their session", async ({
  page,
}) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill(inactiveEmail);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page).toHaveURL(/\/permission-denied$/);
  await expect(
    page.getByRole("heading", { name: "Access is not active" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page).toHaveURL(/\/login$/);
});

test("unsafe return paths fall back to the Dashboard", async ({ page }) => {
  await page.goto("/login?returnTo=https%3A%2F%2Fattacker.invalid%2Fsteal");
  await page.getByLabel("Email").fill(activeEmail);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page).toHaveURL(/\/dashboard$/);

  await page.context().clearCookies();
  await page.reload();
  await expect(page).toHaveURL(/\/login\?returnTo=%2Fdashboard$/);
});

test("Administrator provisions an account and cannot remove the last Administrator", async ({
  page,
}) => {
  await page.goto("/login?returnTo=%2Fadmin%2Faccess");
  await page.getByLabel("Email").fill(activeEmail);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page).toHaveURL(/\/admin\/access$/);

  const provisionForm = page.locator("#provision-account form");
  await provisionForm
    .getByLabel("Directory Person")
    .selectOption(invitedPersonId);
  await provisionForm.getByLabel("Work email").fill(invitedEmail);
  await provisionForm.getByLabel("PMO Officer").check();
  await provisionForm.getByRole("button", { name: "Send invitation" }).click();
  await expect(
    page.getByText("Invitation sent and application access provisioned."),
  ).toBeVisible();
  await expect(page.getByText(invitedEmail)).toBeVisible();

  const users = await admin.auth.admin.listUsers({ perPage: 1000 });
  if (users.error) throw users.error;
  invitedUserId = users.data.users.find(
    (user) => user.email === invitedEmail,
  )?.id;
  expect(invitedUserId).toBeTruthy();

  const administratorRow = page
    .getByRole("row")
    .filter({ hasText: "Browser Test Administrator" });
  await administratorRow.locator("summary").click();
  await administratorRow.getByLabel("Administrator").uncheck();
  await administratorRow.getByRole("button", { name: "Save access" }).click();
  await expect(
    administratorRow.getByText(
      "Keep at least one active Administrator account.",
    ),
  ).toBeVisible();
});

test("a simulated Profile failure leaves no orphan Auth user", async () => {
  const compensationEmail = `compensation-${nonce}@auth.test`;
  await expect(
    provisionApplicationAccount(
      {
        createAuthUser: async (email) => {
          const created = await admin.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
          });
          if (created.error) throw created.error;
          return created.data.user.id;
        },
        linkProfile: async () => {
          throw new Error("Simulated Profile transaction failure");
        },
        deleteAuthUser: async (authUserId) => {
          const deleted = await admin.auth.admin.deleteUser(authUserId);
          if (deleted.error) throw deleted.error;
        },
      },
      {
        personId: invitedPersonId,
        email: compensationEmail,
        roles: ["pmo_officer"],
      },
    ),
  ).rejects.toThrow("Simulated Profile transaction failure");

  const users = await admin.auth.admin.listUsers({ perPage: 1000 });
  if (users.error) throw users.error;
  expect(
    users.data.users.some((user) => user.email === compensationEmail),
  ).toBe(false);
});
