import { describe, expect, it } from "vitest";
import { readPublicEnvironment, readServerEnvironment } from "@/lib/env";

const live = {
  NEXT_PUBLIC_SUPABASE_URL: "https://pmo-project.supabase.co",
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_valid-test-key-123456",
};

describe("environment validation", () => {
  it("falls back to demo preview when Supabase is absent", () => {
    expect(readPublicEnvironment({ NODE_ENV: "development" }).demoMode).toBe(
      true,
    );
    expect(
      readPublicEnvironment({
        NODE_ENV: "development",
        NEXT_PUBLIC_DEMO_MODE: "true",
      }).demoMode,
    ).toBe(true);
  });

  it("allows read-only demo mode but rejects insecure live URLs in production", () => {
    expect(
      readPublicEnvironment({
        NODE_ENV: "production",
        NEXT_PUBLIC_DEMO_MODE: "true",
      }).demoMode,
    ).toBe(true);
    expect(() =>
      readPublicEnvironment({
        ...live,
        NODE_ENV: "production",
        NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
      }),
    ).toThrow(/HTTPS/);
  });

  it("rejects a partial Supabase configuration", () => {
    expect(() =>
      readPublicEnvironment({
        NODE_ENV: "development",
        NEXT_PUBLIC_SUPABASE_URL: live.NEXT_PUBLIC_SUPABASE_URL,
      }),
    ).toThrow(/PUBLISHABLE_KEY/);
  });

  it("rejects documented placeholder values", () => {
    expect(() =>
      readPublicEnvironment({
        ...live,
        NEXT_PUBLIC_SUPABASE_URL: "https://your-project.supabase.co",
      }),
    ).toThrow(/placeholder/);
  });

  it("requires the service-role key in production only", () => {
    expect(() =>
      readServerEnvironment({ ...live, NODE_ENV: "production" }),
    ).toThrow(/SUPABASE_SERVICE_ROLE_KEY/);
    expect(
      readServerEnvironment({ ...live, NODE_ENV: "development" }).demoMode,
    ).toBe(false);
  });
});
