# PMO Tracker production-readiness implementation plan

Status: Approved and in progress

Progress: Tasks 1–7 and 10–13 completed on 2026-08-14. Tasks 8–9 await the
hosted-project gate; Tasks 14–17 are the usable-product fast path.

## 1. Outcome

Turn the current release-one interface and domain prototype into a secure,
database-backed PMO application deployed on Vercel and connected to the
existing empty Supabase project.

The application is ready when:

- Anonymous users cannot access application pages or exports.
- Administrators, PMO Officers, and Leadership Viewers receive the intended
  database-enforced permissions.
- Every visible release-one screen reads live Supabase data.
- Every visible release-one command performs a real, validated, auditable
  mutation.
- Project history, as-of reconstruction, Ball ownership, Hold exclusion, and
  turnaround calculations are correct for effective and recorded time.
- Local database tests, unit tests, integration tests, browser tests,
  formatting, linting, type-checking, and the production build pass in CI.
- The hosted database migration, initial administrator bootstrap, Vercel
  deployment, backup check, smoke test, and PMO acceptance test are complete.

## 2. Scope contract

### Included

- Supabase Postgres schema, migrations, reference data, RLS, grants, RPCs,
  views, indexes, and database tests.
- Supabase Auth with private account provisioning and password login.
- Administrator, PMO Officer, and Leadership Viewer authorization.
- Live directory, configuration, workflow, project, history, dashboard,
  Ball, report, audit, and CSV data.
- Project creation, overview maintenance, participants, references, stages,
  plan revisions, Progress, Bump, Ball transfer, state change, Hold,
  correction, closeout, and archival commands.
- Point-in-time reconstruction and Hold-aware turnaround reporting.
- CI, deployment, monitoring, backup verification, rollback, and UAT.
- Preservation of the approved Kinetic Project Studio design in DESIGN.md.

### Excluded from release one

- Automated KRA/KPI computation.
- Microsoft Entra ID or enterprise SSO.
- Excel import, notifications, file uploads, PDF generation, and reopening
  Closed or Cancelled projects.
- A generalized workflow engine, data warehouse, or enterprise analytics
  platform.

## 3. Decisions and assumptions

1. The existing hosted Supabase project has no application tables or migration
   history. This must be confirmed with Supabase migration and schema checks
   before the first push.
2. Local Supabase is the development and database-test environment. The hosted
   project remains unchanged until the remote migration gate is approved.
3. The existing 0001 and 0002 SQL files have never been applied remotely.
   They may therefore be replaced with a clean, timestamped baseline.
4. Recommended login identifier: email and password. The directory username
   remains a business field. Implementing true username login would require a
   separate secure identifier-resolution design.
5. Public registration remains disabled. The first Administrator is bootstrapped
   once; later accounts are provisioned by an Administrator.
6. The service-role key is server-only and is used solely for Auth
   administration. Normal reads and business writes use the signed-in user's
   publishable-key client so RLS remains authoritative.
7. All business timestamps are stored as timestamptz. Philippine time is a
   display and input interpretation concern, not a storage format.
8. The effective ordering of project facts is effective_at, recorded_at, id.
9. Existing visual behavior may be adjusted for validation, loading, permission,
   empty, and conflict states, but the approved visual identity is not reopened.

Decisions to confirm before the Auth phase:

- Accept email/password as the release-one sign-in identifier.
- Confirm whether provisioned users receive a temporary password or an Auth
  invitation email.
- Confirm the hosted project is the eventual production project rather than a
  staging project.

## 4. Target architecture

### Request and identity path

1. Next.js proxy refreshes Supabase Auth cookies for matching requests.
2. Server layouts, server actions, and route handlers create a request-scoped
   Supabase client.
3. The protected application layout validates the user and active profile.
4. UI visibility uses the loaded role set for usability.
5. Postgres RLS and RPC permission checks remain the security boundary.

### Read path

Server Components and route handlers call typed modules under lib/data. Those
modules query RLS-protected tables, security-invoker views, or read-only RPCs.
Pages do not import demo records directly.

### Write path

Forms call server actions. Each action:

1. Requires an authenticated active profile and the appropriate coarse role.
2. Parses FormData through Zod.
3. Calls one transactional database RPC for the business command.
4. Maps expected database outcomes to typed field, permission, conflict, or
   domain errors.
5. Revalidates affected routes and redirects only after success.

The RPC repeats authorization and invariant checks inside Postgres. Multi-table
business changes never depend on a sequence of independent browser writes.

### Project history path

The append-only event ledger is canonical for historical state. Current project
columns are a transactionally maintained projection. Corrections add a
superseding event and replay the project projection in the same transaction.

## 5. Database baseline layout

Because the hosted project is empty, replace the current two files with a
reviewable baseline before the first remote push:

1. 202608140001_extensions_and_types.sql
   - pgcrypto, citext, enums, shared domains.
2. 202608140002_directory_and_configuration.sql
   - departments, people, profiles, roles, systems, modules, assignments,
     configurable lists, workflow template, and indexes.
3. 202608140003_projects_and_history.sql
   - projects, participants, scope, references, project stages, plan revisions,
     closeout assessments, event ledger, audit log, constraints, and indexes.
4. 202608140004_security.sql
   - helper functions, RLS enablement, policies, grants, and function execution
     restrictions.
5. 202608140005_project_commands.sql
   - project creation and all transactional project commands.
6. 202608140006_projections_and_reports.sql
   - effective-event views, replay functions, dashboard queries, Ball query,
     as-of reconstruction, turnaround, and export queries.
7. 202608140007_reference_data.sql
   - idempotent release-one reference choices and default workflow stages.

Local-only sample users and projects belong in supabase/seed.sql and must not
be inserted into production by the baseline migrations.

### Required schema improvements before push

- Fully qualify objects in privileged functions and use an empty search_path
  for every SECURITY DEFINER function.
- Prefer SECURITY INVOKER for business functions and views.
- Revoke default function execution from public and grant only the required
  functions to authenticated or service_role.
- Split SELECT, INSERT, UPDATE, and DELETE policies where their predicates
  differ; avoid a broad ALL policy when a command should be RPC-only.
- Add indexes for foreign keys and columns used by RLS predicates, timeline
  ordering, active assignments, project state, PMO Officer, and Ball Owner.
- Add constraints preventing overlapping effective assignments where the
  domain requires one current assignment.
- Add explicit checks for event-type payload requirements, stage ownership,
  active people, participant membership, terminal-state behavior, and
  optimistic version values.
- Ensure direct writes cannot bypass append-only history. Revoke table writes
  where RPCs are the only supported command path.
- Add audit rows inside the same transaction as administrator and project
  commands.
- Make reference-data inserts idempotent and remove every hard-coded UUID from
  the application.

## 6. Implementation tasks

Each task has an output and a gate. A task is complete only when its gate has
evidence.

### Task 1: Freeze the baseline and toolchain (complete)

What:

- Record current package versions and resolve the Next.js, React, and
  eslint-config-next version mismatch.
- Add explicit flat-config ignores for .next, coverage, reports, and generated
  files.
- Fix the Supabase cookie adapter TypeScript errors and formatting drift.
- Add scripts for database start, reset, lint, type generation, database tests,
  integration tests, and browser tests.

Paths:

- package.json
- package-lock.json
- eslint.config.mjs
- tsconfig.json
- next.config.ts
- lib/supabase/server.ts

Verify:

- npm run format:check
- npm run typecheck
- npm run lint
- npm test
- npm run build

### Task 2: Replace the unapplied SQL baseline (complete)

What:

- Split the current schema into the seven timestamped migrations above.
- Move local-only demo records to supabase/seed.sql.
- Keep production reference choices in an idempotent migration.
- Document every table, important constraint, and ownership relationship.

Paths:

- supabase/migrations/\*
- supabase/seed.sql
- supabase/config.toml

Verify:

- A fresh local supabase db reset applies every migration and seed.
- A second reset produces the same schema and deterministic reference choices.
- Supabase migration list shows only the intended local baseline.

### Task 3: Harden relational invariants and indexes (complete)

What:

- Review all foreign-key delete behaviors.
- Add indexes for every operational foreign key and RLS join.
- Enforce current-assignment uniqueness and required effective date ordering.
- Enforce non-terminal Ball ownership, immutable Project Code, terminal-state
  finality, append-only events, and valid correction relationships.
- Decide whether archived records remain selectable by default or only through
  explicit filters.

Paths:

- directory/configuration migration
- projects/history migration

Verify:

- Database tests demonstrate allowed rows and reject each invalid relationship.
- Query plans use indexes for role checks, dashboard queues, project history,
  and ownership lookups.

### Task 4: Implement least-privilege RLS and grants (complete)

What:

- Define active-profile, role, and project-editor helpers.
- Permit active authenticated users to read release-one operational data.
- Permit Administrators to manage directory and configuration data.
- Permit assigned PMO Officers to mutate only their projects through approved
  RPCs.
- Give Leadership Viewers read-only access.
- Deny anonymous access and direct ledger deletion or mutation.
- Lock down function ownership, search paths, and EXECUTE grants.

Paths:

- security migration
- supabase/tests/database/rls.test.sql

Verify:

- Anonymous, inactive, Administrator, assigned PMO, unassigned PMO, and
  Leadership test identities pass the policy matrix.
- Direct writes that should be RPC-only are denied.

### Task 5: Implement transactional command RPCs (complete)

What:

- Create Project and copy the workflow template.
- Update overview, request details, scope, initiative, priority, PMO Officer,
  systems/modules, participants, and references.
- Tailor Project stages without changing existing projects when the template
  changes.
- Add/reorder/archive stages and add plan revisions.
- Append Progress, Bump, Ball transfer, state change, Hold, and archive events.
- Record closeout assessment before Closed.
- Correct an event through supersession and projection replay.
- Apply optimistic concurrency with the project version.

Paths:

- project command migration
- lib/validation.ts
- supabase/tests/database/commands.test.sql

Verify:

- Each command succeeds for permitted roles.
- Each permission, validation, terminal-state, participant, stage, and stale
  version case is rejected atomically.
- Failed commands leave no partial rows.

### Task 6: Build projections and report queries (complete)

What:

- Create an effective-event relation that excludes superseded facts.
- Replay current Project state after corrections.
- Reconstruct Project state as of an effective timestamp.
- Derive ownership spans and Hold spans.
- Calculate gross, Hold, and net turnaround durations without double-counting
  overlapping Hold periods.
- Produce dashboard oldest-first queues, Ball bays, project history, audit,
  as-of, and turnaround result sets.
- Use security-invoker views or permission-checking RPCs.

Paths:

- projections/reports migration
- supabase/tests/database/reports.test.sql
- tests/domain.test.ts

Verify:

- Golden timeline fixtures cover ties, backdated events, corrections, Holds,
  Ball transfers, terminal states, and a chosen as-of timestamp.
- Current projection equals replayed projection for every fixture.

### Task 7: Add database test infrastructure (complete)

What:

- Add pgTAP or SQL assertion tests for schema, constraints, RLS, commands,
  projection replay, and reports.
- Add fixtures for every application role and representative project history.
- Make local database tests disposable and repeatable.

Paths:

- supabase/tests/database/\*
- package.json
- scripts only if a small cross-platform test wrapper is needed

Verify:

- One documented command starts/resets local Supabase and runs the full database
  suite from a clean checkout.
- Tests leave no dependency on the hosted project.

### Task 8: Link the hosted project without changing it

What:

- Authenticate the Supabase CLI locally.
- Link this repository to the existing project reference.
- Inspect local and remote migration history.
- Confirm the public application schema is empty.

Commands:

    supabase login
    supabase link --project-ref <PROJECT_REF>
    supabase migration list

Verify:

- Link succeeds.
- Remote migration history and public schema match the empty-project assumption.
- Stop and reconcile if any remote object or migration exists.

Safety:

- Do not run supabase db reset --linked.
- Do not run supabase db push during this task.
- Do not paste access tokens or service-role keys into chat or committed files.

### Task 9: Apply the approved baseline to the hosted project

Prerequisites:

- Tasks 1 through 8 are green.
- The migration diff has been reviewed.
- A database restore point or platform backup state has been confirmed.
- The user approves the remote push.

What:

- Push the migration baseline.
- Compare migration history.
- Generate TypeScript types from the linked schema.

Commands:

    supabase db push
    supabase migration list
    supabase gen types --linked > lib/database.types.ts

Verify:

- All migrations are recorded once.
- Expected tables, policies, functions, views, indexes, and reference choices
  exist.
- Anonymous smoke queries are denied.
- Generated types compile.

Rollback:

- Before production data exists, repair by a reviewed forward migration or,
  only with approval, recreate the empty project database.
- After production data exists, use forward-only corrective migrations and
  restore procedures; never reset the linked database.

### Task 10: Add typed environment and Supabase clients (complete)

What:

- Validate required environment variables at startup.
- Add typed browser, server, request-refresh, and admin clients.
- Keep the service-role client in a server-only module.
- Remove implicit demo-mode behavior based solely on a missing URL.
- If demo mode is retained for screenshots, require an explicit development-only
  flag and prevent it in production.

Paths:

- lib/env.ts
- lib/database.types.ts
- lib/supabase/browser.ts
- lib/supabase/server.ts
- lib/supabase/admin.ts
- lib/supabase/proxy.ts
- proxy.ts
- .env.example

Verify:

- Missing or placeholder production variables stop startup with a clear message.
- Client bundles contain no service-role key.
- Auth cookies refresh through the request boundary.

### Task 11: Enforce authentication and session lifecycle (complete)

What:

- Protect all application routes and exports.
- Redirect anonymous users to login with a safe return path.
- Redirect authenticated users without an active profile to permission denied.
- Add real sign-out and clear the session.
- Avoid trusting an unvalidated cookie session for authorization.

Paths:

- proxy.ts
- app/(app)/layout.tsx
- app/login/actions.ts
- app/login/page.tsx
- lib/auth.ts
- components/sidebar.tsx
- app/api/exports/\*\*

Verify:

- Anonymous requests cannot render or export protected data.
- Login, refresh, expiration, sign-out, inactive profile, and return-path flows
  pass browser tests.

### Task 12: Bootstrap and provision application users (complete)

What:

- Create a documented one-time initial Administrator bootstrap transaction
  using an Auth user UUID created in the Supabase Dashboard.
- Replace hard-coded sidebar identity with the active profile.
- Implement Administrator-only account provisioning and role management.
- Use the Auth Admin API only from a server-only action.
- Compensate for Auth creation if profile/role creation fails.
- Prevent removal of the last active Administrator.

Paths:

- docs/initial-admin-bootstrap.md
- app/(app)/admin/access/page.tsx
- app/(app)/admin/access/actions.ts
- lib/supabase/admin.ts
- security and command migrations

Verify:

- The initial Administrator signs in.
- Administrator can provision PMO and Leadership accounts.
- Non-Administrators cannot invoke provisioning even by direct requests.
- No orphan Auth user remains after a simulated profile failure.

### Task 13: Create the typed data-access layer (complete)

What:

- Centralize query result types and error handling.
- Keep query functions server-only.
- Add modules for session, directory, configuration, projects, events,
  dashboard, Ball, reports, exports, and audit.
- Return explicit empty, unavailable, permission, and not-found outcomes.

Paths:

- lib/data/session.ts
- lib/data/directory.ts
- lib/data/configuration.ts
- lib/data/projects.ts
- lib/data/events.ts
- lib/data/dashboard.ts
- lib/data/reports.ts
- lib/data/audit.ts
- lib/actions/\*

Verify:

- Pages and handlers do not contain duplicated raw query chains.
- Database types flow through the repositories without any.
- Repository integration tests cover success and mapped Postgres errors.

### Task 14: Wire directory and administration

What:

- People and department create/edit/archive.
- Systems, modules, developer assignments, and module-owner assignments.
- Configurable priorities, request types, reference types, and initiator types.
- Workflow-template stage add/edit/reorder/archive.
- Access and role management.
- Read-only audit log.

Paths:

- app/(app)/directory/\*\*
- app/(app)/admin/\*\*
- lib/data/directory.ts
- lib/data/configuration.ts
- corresponding server actions

Verify:

- Administrator journeys pass end to end.
- PMO and Leadership users receive the correct read-only or denied behavior.
- Template changes affect only subsequently created Projects.

### Task 15: Wire project creation and overview

What:

- Load live active priorities, PMO Officers, Ball-owner candidates, initiatives,
  request types, initiator types, systems, modules, and reference types.
- Remove hard-coded UUIDs.
- Enforce Pipeline-versus-Planned/Active completeness.
- Create the Project atomically with PMO assignment, participant, copied stages,
  initial Ball Owner, and creation event.
- Implement overview, scope, participants, affected systems/modules, and
  references maintenance.

Paths:

- app/(app)/projects/new/page.tsx
- app/(app)/projects/actions.ts
- app/(app)/projects/[code]/page.tsx
- project form components
- lib/data/projects.ts

Verify:

- Valid Pipeline, Planned, and Active creation journeys pass.
- Duplicate code, inactive person, incomplete scope, invalid module, and
  unassigned Ball Owner cases show actionable errors without partial writes.

### Task 16: Wire the project workspace commands

What:

- Progress with effective time, stage detail, summary, and optional Ball transfer.
- Bump with summary and optional Ball transfer.
- State change including On Hold, Cancelled, and Closed rules.
- PMO reassignment and participant changes.
- Stage tailoring and plan-date revisions.
- Conflict response when the loaded project version is stale.

Paths:

- app/(app)/projects/[code]/\*\*
- app/(app)/projects/actions.ts or scoped action modules
- reusable dialog/form components
- lib/validation.ts

Verify:

- Every visible command creates the expected event and current projection.
- Stale forms preserve entered values and explain the conflict.
- Terminal projects render history but expose no mutation path.

### Task 17: Wire corrections, closeout, and audit

What:

- Administrator-only correction form with required reason.
- Supersede rather than edit or delete the original event.
- Replay the current projection after correction.
- Require and persist the closeout assessment before Closed.
- Show audit actor, before/after data, and recorded time.

Paths:

- project history UI
- closeout UI
- app/(app)/admin/audit/page.tsx
- corresponding actions and data modules

Verify:

- Corrected timelines, as-of results, dashboard state, and turnaround all agree.
- Original events remain queryable as superseded evidence.

### Task 18: Replace demo dashboard, Ball, and project lists

What:

- Replace every demoProjects import with live queries.
- Implement oldest-first waiting, Progress, and Bump queues.
- Populate PMO, Developer, and System Owner Ball bays.
- Add search, filters, pagination, and explicit empty states.
- Retain the existing responsive visual contract.

Paths:

- app/(app)/dashboard/page.tsx
- app/(app)/ball/page.tsx
- app/(app)/projects/page.tsx
- components/project-strip.tsx
- lib/data/dashboard.ts
- lib/data/projects.ts

Verify:

- UI ordering matches database fixtures.
- Filters and paging survive URL refresh and are covered by browser tests.
- No production route imports lib/demo.ts.

### Task 19: Wire reports and CSV exports

What:

- Implement effective-time As-of controls and reconstruction.
- Implement period-filtered turnaround with Hold exclusion.
- Generate Project list, As-of, Turnaround, and Project history CSV from the same
  typed query modules used by pages.
- Protect exports with Auth/RLS and private no-store headers.
- Add safe filenames and formula-injection protection for spreadsheet consumers.

Paths:

- app/(app)/reports/\*\*
- app/api/exports/\*\*
- lib/data/reports.ts
- lib/csv.ts

Verify:

- HTML and CSV values match for identical filters.
- CSV quoting, Unicode, newlines, dangerous leading characters, permissions,
  and no-store headers pass tests.

### Task 20: Preserve honest KRA/KPI and complete UX states

What:

- Keep release-one KPI definitions and Not yet calculated values.
- Load persisted closeout assessment values.
- Add pending, field error, database error, permission, empty, not-found,
  conflict, retry, and success feedback.
- Preserve keyboard access, focus restoration, labels, reduced motion, mobile
  layout, and the approved design system.

Paths:

- all affected pages and form components
- app/(app)/loading.tsx
- app/(app)/error.tsx
- app/(app)/permission-denied/page.tsx
- app/(app)/not-found.tsx

Verify:

- Accessibility and responsive browser checks pass for every primary journey.
- No control appears actionable without a wired result.

### Task 21: Expand automated application tests

What:

- Unit-test validation, domain transitions, time math, and CSV safety.
- Integration-test repositories and server actions against local Supabase.
- Browser-test each role and primary business journey.
- Test anonymous access to every protected page and export.
- Add regression fixtures for corrections and historical reports.

Paths:

- tests/unit/\*
- tests/integration/\*
- tests/e2e/\*
- playwright.config.ts
- vitest.config.ts

Verify:

- Test matrix below is green from a clean local database.
- Tests do not depend on execution order or hosted production data.

### Task 22: Add CI and migration gates

What:

- Add pull-request checks for install, format, typecheck, source lint, unit tests,
  local Supabase reset, database tests, integration tests, browser smoke tests,
  and production build.
- Generate database types in CI and fail if committed types drift.
- Reject edited migration files after they have appeared in remote history.
- Keep remote deployment and migration credentials out of pull-request jobs.

Paths:

- .github/workflows/ci.yml
- package.json
- database test scripts

Verify:

- CI passes on the implementation branch.
- A deliberate type drift, RLS failure, formatting drift, and migration edit
  each fail the expected gate.

### Task 23: Configure Vercel and hosted Supabase

What:

- Set production and preview environment variables.
- Configure Auth site URL and allowed redirect URLs.
- Confirm public signup is disabled.
- Confirm backup/PITR availability and document the selected recovery target.
- Configure application and Supabase error monitoring without logging secrets or
  sensitive payloads.
- Resolve Next.js workspace-root warnings.

Verify:

- Preview and production builds use the intended environment.
- Auth cookies, redirects, and server actions work on the deployed origin.
- Backup status and restoration instructions are recorded.

### Task 24: Run UAT and release

What:

- Bootstrap the first Administrator.
- Load real directory and configuration records.
- Provision the PMO Officer and Leadership Viewer.
- Run the full acceptance matrix with representative, non-sensitive Projects.
- Reconcile every release-one acceptance item.
- Create release notes, operational runbook, and rollback checkpoint.

Verify:

- Administrator, PMO, Leadership, and anonymous acceptance journeys pass.
- Historical answers are independently checked against the entered event fixture.
- No demo records or placeholder credentials appear in production.
- The user approves production release.

## 7. Route and capability matrix

| Surface           | Live read source                | Commands             | Required access                      |
| ----------------- | ------------------------------- | -------------------- | ------------------------------------ |
| Login             | Supabase Auth                   | Sign in              | Anonymous                            |
| Dashboard         | Dashboard query                 | Links only           | Any active profile                   |
| Projects          | Project list query              | Create link          | Read: all; create: Admin/PMO         |
| New Project       | Active configuration and People | create_project       | Admin/PMO                            |
| Project workspace | Project aggregate and ledger    | Project RPCs         | Read: all; write: Admin/assigned PMO |
| Ball View         | Current Ball query              | Links only           | Any active profile                   |
| As-of report      | project_as_of                   | Filter/export        | Any active profile                   |
| Turnaround report | turnaround query                | Filter/export        | Any active profile                   |
| People/Systems    | Directory queries               | CRUD/assignments     | Admin writes                         |
| Workflow/Lists    | Configuration queries           | CRUD/reorder/archive | Admin writes                         |
| Access            | Profiles, roles, Auth admin     | Provision/manage     | Admin only                           |
| Audit             | Audit query                     | None                 | Admin only                           |
| CSV endpoints     | Same report repositories        | Download             | Authenticated plus RLS               |

## 8. Verification matrix

### Identity and security

- Anonymous user: login only; protected pages and exports denied.
- Inactive profile: permission-denied result.
- Leadership Viewer: all operational reads, no writes.
- PMO Officer: assigned-project writes only.
- Administrator: configuration, access, correction, and all project commands.
- Service-role key: absent from client chunks, logs, test snapshots, and Git.

### Domain

- Unique immutable Project Code.
- Non-terminal Project always has one active participant Ball Owner.
- Planned/Active completeness rules.
- Project-specific stages copied once and independently tailored.
- Terminal states irreversible.
- Optimistic version conflict.
- Append-only ledger and correction supersession.
- Closeout required before Closed.

### Time and reporting

- Effective and recorded timestamps preserved.
- Deterministic ordering for ties.
- Backdated event behavior.
- Correction replay.
- As-of reconstruction before, at, and after events.
- Ownership duration, overlapping Hold duration, and net duration.
- HTML/CSV parity.

### Application

- Loading, empty, validation, permission, conflict, retry, and not-found states.
- Keyboard and mobile journeys.
- No demo adapter in production.
- Private no-store exports.
- Build and runtime logs contain no secrets.

## 9. Supabase operator runbook

### Information needed from the user

- Supabase project reference, visible in Project Settings or the project URL.
- Confirmation that the public schema contains no application tables.
- A local Supabase CLI login; do not send the access token.
- Production Supabase URL and publishable key entered locally or in Vercel.
- Service-role key entered only in server-side local/Vercel secret storage.
- The first Administrator's email, display name, username, department, and
  position when bootstrap begins.

### Local preparation

    supabase login
    supabase link --project-ref <PROJECT_REF>
    supabase start
    supabase db reset
    supabase migration list
    npm run db:test
    npm run typecheck
    npm test

### Remote hold point

Before supabase db push, present:

- Migration list and reviewed SQL diff.
- Local reset and database-test receipt.
- RLS role-matrix receipt.
- Confirmation that the remote schema remains empty.
- Backup/restore status.

Only after explicit approval:

    supabase db push
    supabase migration list
    supabase gen types --linked > lib/database.types.ts

### Application environment

Local .env.local and Vercel server environment:

    NEXT_PUBLIC_SUPABASE_URL=<project URL>
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<publishable key>
    SUPABASE_SERVICE_ROLE_KEY=<server-only service role key>

Never commit .env.local. Never prefix the service-role key with NEXT_PUBLIC.

### Initial Administrator bootstrap

1. Create the first Auth user in the Supabase Dashboard with public signup still
   disabled.
2. Copy its Auth UUID.
3. Run the reviewed parameterized bootstrap transaction to create or select the
   department, create the Person, link Profile.id to the Auth UUID, and grant
   administrator.
4. Sign in and confirm the active profile and Administrator role.
5. Use the application Access screen for subsequent accounts.

## 10. Execution waves and dependencies

| Wave                    | Tasks | Exit gate                                      | Relative effort  |
| ----------------------- | ----- | ---------------------------------------------- | ---------------- |
| Foundation              | 1–4   | Clean build, resettable schema, RLS matrix     | Medium           |
| Database behavior       | 5–7   | Commands and historical reports proven locally | Large            |
| Hosted baseline         | 8–9   | Reviewed migration applied and types generated | Small, high risk |
| Identity and data layer | 10–13 | Protected typed app shell and provisioning     | Medium           |
| Operational screens     | 14–20 | Every release-one control and read is live     | Large            |
| Release quality         | 21–24 | CI, deployment, UAT, release approval          | Large            |

Likely scale for one focused engineer is 18–30 engineering days,
depending on the number of correction/report edge cases surfaced during
database testing and UAT. Calendar time also depends on user availability for
Supabase access, account bootstrap, and acceptance decisions.

## 11. Principal risks and mitigations

1. RLS self-lockout or privilege escalation.
   - Mitigation: role-matrix database tests and RPC-only write grants before
     remote push.
2. Backdated correction changes current state incorrectly.
   - Mitigation: canonical replay function, golden timelines, and projection
     equality tests.
3. Auth user and application profile become inconsistent.
   - Mitigation: one-time bootstrap procedure, compensated provisioning, and
     orphan-account tests.
4. Current UI hides incomplete behavior.
   - Mitigation: inventory every control and require a browser assertion or
     explicit non-actionable rendering.
5. Production is migrated before the baseline is stable.
   - Mitigation: local-first database gate and explicit approval before db push.
6. Demo fallback leaks into production.
   - Mitigation: explicit development-only flag and CI scan for demo imports in
     production routes.
7. Service-role key reaches the client.
   - Mitigation: server-only module, bundle scan, secret scanning, and no
     NEXT_PUBLIC prefix.

## 12. Definition of done

Release one is operational only when all 24 tasks are complete, CI is green,
the hosted migration and generated types agree, the first three users can
perform their role-specific journeys, all 20 acceptance items are reconciled,
historical fixtures produce independently verified answers, production contains
no demo data, and the user approves release.

## 13. Documentation baseline

This plan incorporates current guidance from:

- Supabase CLI: https://github.com/supabase/cli/blob/develop/README.md
- Supabase SSR patterns:
  https://github.com/supabase/ssr/blob/main/_autodocs/common-patterns.md
- Supabase database-function security:
  https://github.com/supabase/supabase/blob/master/apps/docs/content/guides/database/functions.mdx
