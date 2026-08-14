# PMO Tracker functional production plan

The active implementation plan is:

- docs/production-readiness-plan.md
- 24 tasks across database, security, application wiring, reports, testing,
  deployment, and UAT.
- Tasks 1–2 are complete; Task 3 (relational invariants and indexes) is next.
- Remote Supabase changes are gated on local database evidence and explicit
  user approval.

## Previous completed plan

# PMO Tracker visual overhaul plan

Goal: Implement the approved Kinetic Project Studio across the existing web interface without changing business behavior or data flows.

1. Replace the pixel-era root theme and obsolete direction contract.
   - Paths: `app/layout.tsx`, `app/globals.css`
   - Verify: root layout uses the new font variables and only the replacement theme is imported.
2. Rebuild the shared navigation, headers, project records, controls, tables, forms, notices, and state surfaces.
   - Paths: `components/sidebar.tsx`, `components/page-header.tsx`, `components/project-strip.tsx`, `components/icons.tsx`, `app/globals.css`
   - Verify: every current route inherits the new system with visible focus and responsive behavior.
3. Implement the approved Studio Instrument Wall Dashboard with regular KRA/KPI panels.
   - Paths: `app/(app)/dashboard/page.tsx`, `app/globals.css`
   - Verify: Ball, oldest waiting, honest KRA definitions, Progress, and Bumps are visible and legible on common laptop sizes.
4. Integrate original 3D Ball and Bump assets.
   - Paths: `public/assets/ball-3d.png`, `public/assets/bump-fist-3d.png`
   - Verify: transparent edges, compact rendering, explicit written labels, and reduced-motion fallbacks.
5. Remove inline styling from exceptional surfaces and carry the new system through login and Project detail.
   - Paths: `app/login/page.tsx`, `app/(app)/projects/[code]/page.tsx`, `app/(app)/ball/page.tsx`
   - Verify: no old pixel styling remains visible and business controls remain present.
6. Validate and refine.
   - Paths: all changed UI files
   - Verify: format, lint, typecheck, tests, build, desktop/mobile Playwright screenshots, browser console, Impeccable detector, and independent finish review.

## Completion

Completed 2026-08-14. The approved visual world is implemented across the shell, Dashboard, Project detail, Ball View, login, forms, lists, tables, notices, and responsive navigation. The narrow-dashboard collision is fixed by stacking Progress and Bumps at 1320px and below; mobile Progress preserves written Ball ownership. Functional and live-data work is intentionally deferred to the next session.
