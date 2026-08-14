import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { expect, test } from "playwright/test";
import type { Database } from "../../lib/database.types";

const password = "Browser-test-password-42!";
const nonce = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
const activeEmail = `active-${nonce}@auth.test`;
const inactiveEmail = `inactive-${nonce}@auth.test`;
const departmentId = crypto.randomUUID();
const personId = crypto.randomUUID();
let activeUserId: string;
let inactiveUserId: string;
let admin: SupabaseClient<Database>;

test.beforeAll(async () => {
  admin = createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );
  const activeUser = await admin.auth.admin.createUser({
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
    .insert({ id: departmentId, name: `Browser Test ${nonce}` });
  const person = await admin.from("people").insert({
    id: personId,
    department_id: departmentId,
    name: "Browser Test User",
    position: "Leadership",
    username: `browser.${nonce}`,
  });
  const profile = await admin
    .from("profiles")
    .insert({ id: activeUserId, person_id: personId });
  const role = await admin
    .from("profile_roles")
    .insert({ profile_id: activeUserId, role: "leadership_viewer" });
  for (const result of [department, person, profile, role]) {
    if (result.error) throw result.error;
  }
});

test.afterAll(async () => {
  if (!admin) return;
  await admin.from("profile_roles").delete().eq("profile_id", activeUserId);
  await admin.from("profiles").delete().eq("id", activeUserId);
  await admin.from("people").delete().eq("id", personId);
  await admin.from("departments").delete().eq("id", departmentId);
  if (activeUserId) await admin.auth.admin.deleteUser(activeUserId);
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
  await expect(page.getByText("Browser Test User")).toBeVisible();

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
