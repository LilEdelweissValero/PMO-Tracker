# PMO Tracker

Release-one Next.js App Router application backed by Supabase Auth/Postgres. The UI uses clearly labeled demo records when Supabase environment variables are absent; live deployments require the migration and environment setup below.

## Local setup

1. Copy `.env.example` to `.env.local` and fill in a Supabase URL and publishable key.
2. Run `supabase db reset` to apply `supabase/migrations` and seed configuration records.
3. Provision the first Auth user in Supabase, then link it to a `people` and `profiles` row and assign `profile_roles`. Public registration is disabled.
4. Run `npm run dev`.

Never expose `SUPABASE_SECRET_KEY` (or legacy `SUPABASE_SERVICE_ROLE_KEY`) to the browser. Vercel environments must receive their own Supabase values and migrations must run before promotion.

## Verification

Run `npm run format:check`, `npm run typecheck`, `npm run lint`, `npm test`, and `npm run build`.

Run `npm run db:verify` to start local Supabase, rebuild it from migrations,
lint the resulting schema, and execute the complete disposable pgTAP suite.
