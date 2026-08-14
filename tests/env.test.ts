import { describe, expect, it } from "vitest";
import { readPublicEnvironment, readServerEnvironment } from "@/lib/env";

const live = {
  NEXT_PUBLIC_SUPABASE_URL: "https://pmo-project.supabase.co",
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_valid-test-key-123456",
};

describe("environment validation", () => {
  it("requires an explicit demo flag when Supabase is absent", () => {
    expect(() => readPublicEnvironment({ NODE_ENV: "development" })).toThrow(
      /NEXT_PUBLIC_SUPABASE_URL/,
    );
    expect(
      readPublicEnvironment({
        NODE_ENV: "development",
        NEXT_PUBLIC_DEMO_MODE: "true",
      }).demoMode,
    ).toBe(true);
  });

  it("rejects demo mode and insecure URLs in production", () => {
    expect(() =>
      readPublicEnvironment({
        NODE_ENV: "production",
        NEXT_PUBLIC_DEMO_MODE: "true",
      }),
    ).toThrow(/cannot be enabled/);
    expect(() =>
      readPublicEnvironment({
        ...live,
        NODE_ENV: "production",
        NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
      }),
    ).toThrow(/HTTPS/);
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
