import { execFileSync } from "node:child_process";
import { defineConfig } from "playwright/test";

type LocalStatus = Record<string, string | undefined>;

function localSupabaseEnvironment() {
  const status = JSON.parse(
    execFileSync("supabase", ["status", "-o", "json"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "inherit"],
    }),
  ) as LocalStatus;
  const environment = {
    NEXT_PUBLIC_SUPABASE_URL: status.API_URL ?? status.api_url,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:
      status.PUBLISHABLE_KEY ?? status.publishable_key ?? status.ANON_KEY,
    SUPABASE_SERVICE_ROLE_KEY:
      status.SERVICE_ROLE_KEY ?? status.service_role_key ?? status.SECRET_KEY,
    NEXT_PUBLIC_DEMO_MODE: "false",
  };
  if (
    !environment.NEXT_PUBLIC_SUPABASE_URL ||
    !environment.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
    !environment.SUPABASE_SERVICE_ROLE_KEY
  ) {
    throw new Error(
      "Local Supabase status did not include the required test keys.",
    );
  }
  Object.assign(process.env, environment);
  return environment as Record<string, string>;
}

const environment = localSupabaseEnvironment();
const webServerEnvironment: Record<string, string> = {
  ...environment,
  PMO_NEXT_DIST_DIR: ".next-playwright",
};
for (const [name, value] of Object.entries(process.env)) {
  if (name !== "NO_COLOR" && value !== undefined) {
    webServerEnvironment[name] = value;
  }
}

export default defineConfig({
  testDir: "./tests/e2e",
  globalSetup: "./tests/e2e/reset-database.ts",
  globalTeardown: "./tests/e2e/reset-database.ts",
  fullyParallel: false,
  use: {
    baseURL: "http://127.0.0.1:3107",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "npm run dev -- --port 3107",
    url: "http://127.0.0.1:3107/login",
    reuseExistingServer: false,
    env: webServerEnvironment,
    timeout: 120_000,
  },
});
