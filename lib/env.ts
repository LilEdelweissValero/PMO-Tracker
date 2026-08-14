import { z } from "zod";

const placeholder =
  /(your[-_ ]?project|placeholder|example\.invalid|server-only)/i;
const publicSchema = z.object({
  supabaseUrl: z.string().trim().url().optional(),
  supabasePublishableKey: z.string().trim().min(20).optional(),
  demoMode: z.enum(["true", "false"]).default("false"),
  nodeEnv: z.enum(["development", "test", "production"]).default("development"),
  vercelEnv: z.enum(["development", "preview", "production"]).optional(),
});

type EnvironmentSource = Partial<Record<string, string | undefined>>;
export type PublicEnvironment =
  | { demoMode: true; supabaseUrl: null; supabasePublishableKey: null }
  | {
      demoMode: false;
      supabaseUrl: string;
      supabasePublishableKey: string;
    };

function publicSource(source: EnvironmentSource) {
  return {
    supabaseUrl: source.NEXT_PUBLIC_SUPABASE_URL,
    supabasePublishableKey: source.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    demoMode: source.NEXT_PUBLIC_DEMO_MODE,
    nodeEnv: source.NODE_ENV,
    vercelEnv: source.VERCEL_ENV,
  };
}

export function readPublicEnvironment(
  source: EnvironmentSource = process.env,
): PublicEnvironment {
  const parsed = publicSchema.parse(publicSource(source));
  const production =
    parsed.nodeEnv === "production" || parsed.vercelEnv === "production";

  if (parsed.demoMode === "true") {
    return {
      demoMode: true,
      supabaseUrl: null,
      supabasePublishableKey: null,
    };
  }

  if (!parsed.supabaseUrl && !parsed.supabasePublishableKey) {
    return {
      demoMode: true,
      supabaseUrl: null,
      supabasePublishableKey: null,
    };
  }

  if (!parsed.supabaseUrl || placeholder.test(parsed.supabaseUrl)) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL is required and cannot be a placeholder.",
    );
  }
  if (
    !parsed.supabasePublishableKey ||
    placeholder.test(parsed.supabasePublishableKey)
  ) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY is required and cannot be a placeholder.",
    );
  }
  if (production && new URL(parsed.supabaseUrl).protocol !== "https:") {
    throw new Error("Production Supabase URLs must use HTTPS.");
  }

  return {
    demoMode: false,
    supabaseUrl: parsed.supabaseUrl,
    supabasePublishableKey: parsed.supabasePublishableKey,
  };
}

export function readServerEnvironment(source: EnvironmentSource = process.env) {
  const publicEnvironment = readPublicEnvironment(source);
  if (publicEnvironment.demoMode) return publicEnvironment;

  const serviceRoleKey =
    source.SUPABASE_SECRET_KEY?.trim() ??
    source.SUPABASE_SERVICE_ROLE_KEY?.trim();
  const production =
    source.NODE_ENV === "production" || source.VERCEL_ENV === "production";
  if (
    production &&
    (!serviceRoleKey ||
      serviceRoleKey.length < 20 ||
      placeholder.test(serviceRoleKey))
  ) {
    throw new Error(
      "SUPABASE_SECRET_KEY (or legacy SUPABASE_SERVICE_ROLE_KEY) is required and cannot be a placeholder in production.",
    );
  }

  return { ...publicEnvironment, serviceRoleKey: serviceRoleKey ?? null };
}

export function getPublicEnvironment() {
  return readPublicEnvironment({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    NEXT_PUBLIC_DEMO_MODE: process.env.NEXT_PUBLIC_DEMO_MODE,
    NODE_ENV: process.env.NODE_ENV,
    VERCEL_ENV: process.env.VERCEL_ENV,
  });
}
