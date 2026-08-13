# Release-one acceptance review

Reviewed 13 August 2026. Evidence reflects checks possible without Supabase credentials or a running local Supabase service.

| #   | Result                      | Evidence                                                                                                                                        |
| --- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Deferred                    | Account schema, additive `profile_roles`, RLS, and access screen exist; live Auth provisioning requires Supabase credentials.                   |
| 2   | Partial                     | Directory tables, effective assignment periods, uniqueness constraints, RLS, and screens exist; live database journey not run.                  |
| 3   | Passed (code)               | `create_project` enforces unique immutable Code, active PMO/Ball Owner, initial PMO participation, and copies the Workflow Template atomically. |
| 4   | Passed (code)               | `append_project_event` rejects Planned/Active without request, requester, scope, and affected scope.                                            |
| 5   | Partial                     | Project-owned Stage schema/copy and workspace exist; complete Stage mutation actions remain to be wired.                                        |
| 6   | Partial                     | Transaction function supports Progress, Effective time, Stage, payload and Ball Owner; interactive form remains to be wired.                    |
| 7   | Partial                     | Transaction function supports Bump and Ball transfer; interactive form remains to be wired.                                                     |
| 8   | Partial                     | State/event model supports On Hold; derived Hold reconstruction and interactive form remain.                                                    |
| 9   | Partial                     | Dual timestamps and ordered ledger exist; full projection recalculation for backdated corrections remains.                                      |
| 10  | Partial                     | Administrator-only append-only supersession exists; full current-projection recalculation remains.                                              |
| 11  | Passed (code)               | Transaction rejects all terminal Project changes; schema retains archive timestamp.                                                             |
| 12  | Passed (UI contract)        | Dashboard queues are oldest-first and label empty histories `No update yet`; live query remains to replace demo adapter.                        |
| 13  | Passed (schema/UI contract) | Non-terminal owner check and three labeled Ball bays exist.                                                                                     |
| 14  | Partial                     | Effective/Recorded event fields and As-of controls exist; database reconstruction query remains.                                                |
| 15  | Passed (unit)               | `netOwnershipMs` excludes overlapping Hold time; unit test passes. Live report query remains.                                                   |
| 16  | Passed (UI/schema)          | All agreed KPI definitions show `Not yet calculated`; Closeout schema captures every required answer.                                           |
| 17  | Partial                     | Read policies and missing Leadership mutation policies exist; role-level database test awaits Supabase.                                         |
| 18  | Passed (handlers)           | Project list, As-of, Turnaround, and Project history CSV handlers quote fields and declare private no-store responses.                          |
| 19  | Passed                      | Repository scan finds no import, notification, upload, or reopen UI.                                                                            |
| 20  | Partial                     | Production Next.js build passes and secret naming is server-only; actual Vercel/Supabase deployment requires credentials.                       |

## Automated evidence

- `npm run typecheck`: passed.
- `npm run lint`: passed.
- `npm test`: 5 tests passed.
- `npm run build`: passed; all specified release-one routes compiled.
- Impeccable detector: four intentional warnings retained for the user-pinned pixel grid and specification-required group strip rails.

The application is buildable and provides a complete navigable release-one surface, but it is not production-complete until the Partial/Deferred database journeys and remaining mutation/query wiring above are implemented and exercised against Supabase.
