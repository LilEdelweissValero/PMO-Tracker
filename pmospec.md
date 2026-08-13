# PMO Tracker — Next.js Application Specification

Status: Ready for implementation  
Product type: Small internal website  
Deployment: Vercel  
Database and authentication: Supabase  
Business timezone: Asia/Manila

## 1. Product summary

PMO Tracker is the Project Management Office's system of record for Project governance. It tracks the current state and Stage of every Project, records Progress Updates and conversational Bumps, identifies the one person currently responsible for moving each Project forward, and reconstructs the portfolio at any past point in time.

The app is deliberately small. It is expected to contain fewer than 100 Projects and 50 People, with approximately three signed-in users. It should favor direct, understandable workflows over generalized enterprise features.

### Goals

- Give PMO Officers one place to maintain official Project records.
- Make the current Ball Owner and time held immediately visible.
- Preserve an auditable history without preventing backdated data entry or corrections.
- Let each Project adapt its suggested Stage list to its actual workflow.
- Answer “What was the progress of all Projects as of this date?”
- Give Leadership a readable, filterable portfolio view.

### Release-one exclusions

- Automated KRA/KPI calculation
- EV, PV, AC, scope-change, Health Recovery, or portfolio performance inputs
- Excel import
- Email, Teams, or in-app notifications
- File uploads or document storage
- Jira, OneDrive, GDocs, or ELS synchronization
- PDF generation
- Public sign-up, SSO, Microsoft Entra ID, or MFA
- Reopening Closed or Cancelled Projects

CSV export and external document links remain in scope.

## 2. Canonical language and invariants

The complete glossary is in `CONTEXT.md`. The implementation must preserve these rules:

1. A **Project** is one independently governed delivery effort with one accountable PMO Officer.
2. **Stage**, **Project State**, and **Health** are separate concepts.
3. Every non-terminal Project has exactly one **Ball Owner** at all times.
4. A Ball Owner is an individual Project Participant in the PMO, Developer, or System Owner group—not merely a group.
5. Each Project receives its own editable copy of the default Stage suggestions.
6. There is no Skipped or Not Applicable Stage state. An unnecessary upcoming Stage is removed from that Project.
7. Every Project event stores an Effective timestamp and an immutable Recorded timestamp.
8. Corrections supersede prior records; they do not destructively overwrite history.
9. Directory and Project assignments have histories. Directory changes never alter existing Project assignments automatically.
10. Closed and Cancelled are irreversible terminal States.
11. Referenced records are retired, deactivated, archived, or superseded rather than deleted.

## 3. Users and permissions

Developers and System Owners are stored as People and may be assigned to Projects, but they do not sign in during release one.

| Capability                            | Administrator | PMO Officer       | Leadership Viewer |
| ------------------------------------- | ------------- | ----------------- | ----------------- |
| View entire portfolio and reports     | Yes           | Yes               | Yes               |
| Create a Project                      | Yes           | Yes               | No                |
| Edit any Project                      | Yes           | No                | No                |
| Edit assigned Project                 | Yes           | Yes               | No                |
| Add Progress Updates and Bumps        | Yes           | Assigned Projects | No                |
| Change State or Ball Owner            | Yes           | Assigned Projects | No                |
| Tailor a Project's Stages             | Yes           | Assigned Projects | No                |
| Correct historical events             | Yes           | No                | No                |
| Reassign accountable PMO Officer      | Yes           | No                | No                |
| Manage directory and configuration    | Yes           | No                | No                |
| Manage application accounts and roles | Yes           | No                | No                |
| View complete audit history           | Yes           | Yes               | Yes               |

Roles are additive. One account may be both an Administrator and PMO Officer.

All successful mutations record the authenticated actor and Recorded timestamp. Authorization must be enforced on the server and in Supabase policies, not only by hiding controls.

## 4. Information architecture

### Primary navigation

- Dashboard
- Projects
- Ball View
- Reports
- Directory
- Administration

Directory is readable by Administrators and PMO Officers but editable only by Administrators. Administration is visible only to Administrators.

### Routes

| Route                 | Purpose                                                                  |
| --------------------- | ------------------------------------------------------------------------ |
| `/login`              | Email/password login                                                     |
| `/dashboard`          | KRA/KPI reference and staleness queues                                   |
| `/projects`           | Searchable and filterable Project list                                   |
| `/projects/new`       | Project creation                                                         |
| `/projects/[code]`    | Project workspace                                                        |
| `/ball`               | Current Ball ownership board                                             |
| `/reports/as-of`      | Point-in-time portfolio reconstruction                                   |
| `/reports/turnaround` | Individual and group Ball-duration reporting                             |
| `/directory/people`   | People and Departments                                                   |
| `/directory/systems`  | Systems, Modules, Developers, and System Owners                          |
| `/admin/workflow`     | Default Workflow Template                                                |
| `/admin/lists`        | Priority, Request Type, Reference Type, and Initiator Type configuration |
| `/admin/access`       | Login accounts and additive roles                                        |
| `/admin/audit`        | Cross-entity audit log                                                   |

Use the immutable Project Code in the public Project route. URL-encode it rather than exposing the database UUID.

## 5. Visual and interaction direction

### Operating mode

This is an **Operate** interface. Scanability, accountability, and fast updates outrank decoration.

### Operations-strip concept

Project responsibility should read like a flight-progress strip passed between controller bays:

- Project rows are compact horizontal strips, not generic floating cards.
- Project Code, Stage, Ball Owner, and elapsed ownership time form a fixed, scannable rhythm.
- The Ball View uses three clear bays: PMO, Developers, and System Owners.
- A Ball transfer gives the strip a short directional transition to its new bay; reduced-motion mode changes it instantly.
- Dates and durations use tabular numerals.

Use a light, cool-neutral canvas suited to a bright office, dark ink, crisp rules, and restrained group colors:

- PMO: cobalt
- Developers: amber
- System Owners: teal
- Success, warning, and danger colors must always include text or icons and never communicate meaning alone.

Avoid gradients, glass effects, oversized dashboard cards, excessive rounded containers, decorative charts, and motion that delays work.

### Responsive behavior

The product is a normal responsive website. Desktop receives the full dense table and three-column board. At narrow widths:

- Tables preserve the most important columns and expose secondary information in an expandable row.
- Ball View bays stack vertically without changing their PMO → Developer → System Owner order.
- Reading Projects, adding a Bump, recording Progress, and transferring the Ball remain usable.
- Dense Administration screens may use horizontal scrolling where simplification would hide required data.

### Common states

Every surface must define loading, empty, validation-error, permission-denied, save-in-progress, save-success, and unexpected-error states. Empty Project activity belongs last in staleness queues and is labeled “No update yet.”

## 6. Authentication and accounts

- Use Supabase Auth with email and password.
- Do not provide public registration.
- An Administrator provisions and deactivates the small set of application accounts.
- An application account links to one Person and receives one or more roles.
- The Person directory's `username` field is storage used outside the app; it is not the login identifier.
- Use cookie-based server-side sessions.
- Logout ends the current session and returns to `/login`.
- Inactive accounts cannot sign in. Deactivating an account does not deactivate its linked Person automatically.

“Low security” means minimal account features, not plaintext passwords or client-only authorization. Password storage and session issuance remain Supabase Auth responsibilities.

## 7. Directory and configuration

### 7.1 Departments and People

A Person contains:

- Name — required
- Department — required, selected from the directory
- Username — required and stored for external use
- Position — required
- Active/Inactive — required

The database supplies an immutable internal ID. A name, username, position, or Department change is logged. An inactive Person remains visible in history but cannot receive a new assignment or become Ball Owner.

### 7.2 Systems and Modules

- A System contains one or more Modules.
- A System has one or more current assigned Developers.
- Each Module has exactly one current System Owner.
- One Developer may belong to several Systems.
- One System Owner may own several Modules.
- Developer and Module-owner changes close the previous Assignment Period and create a new one.
- Existing Project Participants do not change when the directory changes.

### 7.3 Configurable lists

Administrators can add, rename, reorder where applicable, and retire:

- Priorities, initially `Critical`, `High`, `Medium`, and `Low`
- Request Types, initially `Enhancement`, `New System`, and `New Module`
- Reference Types, initially `GDocs`, `OneDrive`, `ELS`, and `Jira`
- Initiator Types, initially `System Owner`, `PMO`, `Developer`, and `Higher Authority`

Retired choices remain readable on existing Projects but cannot be newly selected. Unreferenced mistakes may be deleted; referenced choices may only be retired.

### 7.4 Default Workflow Template

The initial default Stages are:

1. Engagement Meeting
2. TICRO #1 Requested
3. TICRO #1 Approved
4. TICRO #2 Requested
5. TICRO #2 Approved
6. Signed All Required Documents
7. WBS Onboarded in Jira
8. Dev Start
9. Dev End
10. UAT Start
11. UAT End
12. UAT Signed Off
13. Deployed
14. All Required Documents Submitted

`Project Closed` is not a Stage. Closing is a Project State change with a required Closeout Assessment.

Each template Stage may configure one Stage Detail:

- Label
- Optional help text
- Required or optional
- Single-line or multiline text

Initial special configurations:

- TICRO #1 Requested: required multiline `Documents Submitted`
- TICRO #2 Requested: required multiline `Documents Submitted`
- Deployed: required single-line `Deployment Version`

Administrators may change the template at any time. Existing Projects are unaffected.

## 8. Project management

### 8.1 Project fields

| Group      | Field                        | Rule                                                                        |
| ---------- | ---------------------------- | --------------------------------------------------------------------------- |
| Identity   | Project Code                 | Required, user-entered, unique, immutable after creation                    |
| Identity   | Project Name                 | Required, editable                                                          |
| Identity   | Initiative                   | Optional link grouping related Projects                                     |
| Identity   | Priority                     | Required configurable choice                                                |
| Identity   | Scope/Description            | Multiline, editable, change logged                                          |
| Governance | Project State                | Required                                                                    |
| Governance | Current Stage                | Empty until the first Progress Update is allowed                            |
| Governance | PMO Officer                  | Exactly one current accountable officer                                     |
| Governance | Ball Owner                   | Exactly one for every non-terminal Project                                  |
| Request    | Initiator Type               | Required before Planned or Active                                           |
| Request    | Request Type                 | Required before Planned or Active; configurable choice                      |
| Request    | Requester                    | Required before Planned or Active                                           |
| Request    | Requester Department         | Captured from the directory as a historical snapshot                        |
| Impact     | Affected Systems and Modules | Required before Planned or Active                                           |
| People     | Developers                   | Zero or more in Pipeline; multiple allowed                                  |
| People     | System Owners                | Zero or more in Pipeline; relevant owners required before Planned or Active |
| References | External References          | Zero or more; each has Type, label, and valid HTTP(S) URL                   |

### 8.2 Creation rules

Creating a Project requires:

- Project Code
- Project Name
- Priority
- Project State
- Accountable PMO Officer
- Initial Ball Owner

Other fields may remain incomplete while the Project is in Pipeline. Moving a Project to Planned or Active requires Request Type, Requester, Scope/Description, at least one affected System or Module, and relevant Project Participants.

The initial Ball Owner must be an active Project Participant. If no delivery participant is known in Pipeline, the accountable PMO Officer holds the Ball.

### 8.3 Systems and Project Participants

For each affected System, a Project selects either:

- Entire System, or
- One or more Modules

Selecting a System suggests its current Developers. Selecting Modules additionally suggests their current System Owners. The PMO Officer selects the actual Project Participants and may add an exceptional Person outside those suggestions.

Project Participant assignments have effective start and end timestamps. Changing the directory never silently adds or removes a Project Participant.

### 8.4 Project workspace

The Project page contains:

- Persistent header: Code, Name, State, Priority, current Stage, Ball Owner, elapsed ownership time
- Primary actions: `Add Progress`, `Add Bump`, `Change State`
- Overview: request, scope, affected areas, participants, and references
- Timeline: combined chronological Project events
- Stages: current Project Stage list, planned dates, revisions, and variance
- Turnaround: ownership and hold periods
- History: audit and correction details

Leadership Viewers see the same information without mutation controls.

## 9. Project-specific Stages and schedules

When a Project is created, copy the current Workflow Template and each Stage Detail configuration into Project-owned Stage records.

An assigned PMO Officer or Administrator may:

- Add a Stage
- Rename a Stage
- Reorder Stages
- Remove an upcoming, never-visited Stage
- Configure its Stage Detail
- Add or revise an optional Planned Completion date

Completed/visited Stages cannot be deleted. Renaming a visited Stage changes its current Project label, while historical transitions retain a snapshot of the label used at the time.

There is no separate skipped state. If an upcoming Stage does not apply, remove it. Stage order remains a suggested route; a Project may move forward, backward, or revisit a Stage. A transition to anything other than the immediately next Stage requires a short explanation.

### Planned dates and variance

- Each Stage has an optional Planned Completion date.
- Changing a planned date requires a reason and creates a plan revision; it never overwrites earlier plans.
- The Progress Update's Effective timestamp is the actual Stage-attainment time.
- Calculate calendar-day variance against both the original planned date and the latest plan active at completion.
- Display `Early`, `On Time`, or `Delayed`, with signed day counts.
- A repeat transition into the same Stage uses the latest plan active for that occurrence.

## 10. Project events and history

### 10.1 Common event fields

Every Project event records:

- Project
- Event type
- Effective date and time, entered in Asia/Manila and stored as UTC
- Recorded date and time, generated by the server and immutable
- Authenticated actor
- Event-specific content
- Resulting Project State, Stage, and Ball Owner where applicable
- Superseded-event reference and correction reason when corrected

The Effective timestamp defaults to now but may be backdated. Backdating shows a warning and causes the affected timeline, ownership durations, hold durations, and current projection to be recalculated; it is not blocked.

### 10.2 Progress Update

A Progress Update means the Project moves into a Stage.

Required input:

- Effective timestamp
- Destination Stage
- Short progress summary
- Stage Detail when configured as required
- Resulting Ball Owner, defaulted to the current owner
- Explanation when the destination is not the immediately next Stage

Saving a Progress Update may retain or transfer the Ball. Every actual owner change closes the prior Ball Ownership Period and opens another.

Repeated Deployed transitions are allowed. Each requires its own free-form Deployment Version; do not enforce semantic-version syntax.

### 10.3 Bump

A Bump is a conversational update and does not change the current Stage.

Required input:

- Effective timestamp
- Bump text
- Resulting Ball Owner, defaulted to the current owner

A Bump may transfer the Ball. Clicking a Bump in a list opens the relevant Project and the add-Bump action for users with edit permission.

### 10.4 State change

Non-terminal Projects may move between Pipeline, Planned, Active, and On Hold, subject to the completeness rules for Planned and Active.

- Entering On Hold requires a reason and may retain or transfer the Ball.
- The selected Ball Owner remains responsible while On Hold, but their turnaround clock pauses.
- Leaving On Hold closes the Hold Period and resumes the current ownership clock unless the Ball is transferred.
- Moving to Cancelled requires a reason.
- Moving to Closed requires the Closeout Assessment.
- Closed and Cancelled Projects retain their final Ball Owner historically but have no running Ball clock.
- Closed and Cancelled Projects cannot transition to another State.

### 10.5 Closeout Assessment

Closing requires:

- Definition of Done met: Yes/No and explanation
- Methodology compliant: Yes/No and explanation
- Documentation complete: Yes/No and explanation
- Stakeholder rating: optional 1–5 score
- Stakeholder comment: optional

This data is captured now even though automated KPI calculations are deferred.

### 10.6 Corrections

Only Administrators may correct a historical Progress Update, Bump, State change, or Ball transfer.

- A correction requires a reason.
- The original record remains visible and is marked superseded.
- The corrected record points to the original.
- Current state and all derived historical views are recalculated.
- Audit mode must still be able to show what was recorded before the correction existed.

## 11. Ball ownership and turnaround

### Ball Ownership Period

A period starts when a Person receives the Ball and ends when another Person receives it or the Project becomes terminal. The Person's Project Participant group at the time of receipt determines whether the period belongs to PMO, Developers, or System Owners.

Use exact elapsed calendar time, displayed in days and hours. Exclude overlapping Hold Period duration from the Ball Owner's turnaround while reporting the Hold duration separately.

### Ball View

Show three bays:

1. PMO
2. Developers
3. System Owners

Within each bay, group Project strips by current Ball Owner. Each strip shows:

- Project Code and Name
- current Stage and State
- Priority
- current Ball Owner
- time currently held, excluding hold time
- On Hold duration when applicable
- latest Bump excerpt and Effective timestamp
- Health only when KPI calculation is implemented later

Filters:

- System
- Module
- PMO Officer
- Project State
- Priority

### Turnaround report

For a selected reporting period, show:

- Every Ball Ownership Period and duration
- Total and average duration by individual
- Total and average duration by group
- Number of times each individual received the Ball
- Hold duration per Project
- Filters by Project, Person, group, System, PMO Officer, and date range

Do not rank People as best or worst. The report describes elapsed responsibility, not causation or employee performance.

## 12. Dashboard

### 12.1 KRA/KPI reference

Release one shows the following definitions, formulas, targets, and a visible `Not yet calculated` state. It must not display invented metric values.

#### KRA 1 — Project Efficiency

| KPI                        | Definition                                                                               | Formula/target                   |
| -------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------- |
| Schedule Performance Index | Schedule efficiency based on accomplished versus planned work                            | `SPI = EV / PV`; target `>= 1.0` |
| Cost Performance Index     | Cost efficiency based on accomplished work versus actual cost                            | `CPI = EV / AC`; target `>= 1.0` |
| Project Success Rate       | Closed Projects that met Definition of Done divided by all Closed Projects in the period | Target `>= 90%`                  |

#### KRA 2 — Project Safety

| KPI                          | Definition                                                             | Formula/target                                                             |
| ---------------------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Change Control Stability     | Approved scope added against the original baseline                     | `(Approved change hours or cost / Original baseline hours or cost) × 100%` |
| Project Health Recovery Rate | Projects Red at period start that become Yellow or Green by period end | Target `>= 75%`                                                            |

Change Control Stability thresholds:

- Stable: below 10%
- Volatile: 10%–20%
- Unstable: above 20%

Future Health matrix:

| SPI      | CPI      | Health |
| -------- | -------- | ------ |
| `>= 1.0` | `>= 1.0` | Green  |
| `< 1.0`  | `>= 1.0` | Yellow |
| `>= 1.0` | `< 1.0`  | Yellow |
| `< 1.0`  | `< 1.0`  | Red    |

#### KRA 3 — Project Governance

| KPI                         | Definition                                                  | Target         |
| --------------------------- | ----------------------------------------------------------- | -------------- |
| Methodology Compliance      | Closed Projects that followed the PMO methodology and SDLC  | `>= 95%`       |
| Documentation Compliance    | Closed Projects with all mandatory documents complete       | `100%`         |
| Stakeholder Approval Rating | Average stakeholder score for PMO support and communication | `>= 4.0 / 5.0` |

Provide period controls for current month, current quarter, current year, and custom range. Default to the current quarter even while metrics are informational.

### 12.2 Latest Progress

- Include at most one latest Progress Update per non-archived Project.
- Sort by Effective timestamp from oldest to newest so Projects waiting longest appear first.
- Projects with no Progress Update appear last and display `No update yet`.
- Show Project Code, Name, Stage, update summary, Effective timestamp, age, PMO Officer, and Ball Owner.
- Allow newest-first sorting and filters for PMO Officer, State, future Health, and date range.
- Clicking a row opens the Project. Users with edit permission receive a prominent `Add Progress` action.

### 12.3 Latest Bump

Apply the same behavior as Latest Progress, using the most recent Bump per Project. Empty Bump histories appear last.

## 13. As-of reporting

The As-of View accepts a Philippine date and time and offers two modes:

1. **Effective view** — operational reality reconstructed from all non-superseded events effective on or before the selected time, including corrections or backdated entries recorded later.
2. **Recorded view** — what the tracker contained by the selected Recorded timestamp; events and corrections recorded later are excluded.

Output one row per Project that existed by the selected cutoff:

- Project Code and Name
- Project State and Stage
- Priority
- PMO Officer
- Ball Owner and group
- affected Systems and Modules
- planned Stage completion
- Stage variance known in the selected mode
- latest Progress Update
- latest Bump
- future Health when implemented

Provide filters and CSV export. The on-screen result is the release-one authoritative report.

## 14. Search, filtering, archiving, and export

### Project list

Search across Project Code, Name, Scope/Description, System, Module, Person, and Reference label. Filter by State, Stage, Priority, PMO Officer, Ball Owner group, System, Module, and archived status. Paginate on the server even at the expected small scale.

### Archiving

- Only Closed or Cancelled Projects may be archived.
- Archiving removes them from default operational lists.
- They remain available through explicit filters, search, reporting, As-of Views, and history.
- Archiving is reversible; terminal State is not.

### CSV exports

Support CSV export for:

- Current filtered Project list
- As-of View
- Turnaround report
- Individual Project history

Export only data the viewer may access. Format timestamps in Asia/Manila and include timezone information in headings or values. There is no CSV or Excel import.

## 15. Data model

Use UUID primary keys internally, `timestamptz` for event timestamps, and UTC storage. Project Code has a case-insensitive unique constraint and cannot be updated after insertion.

### Access and directory

| Table                          | Purpose                                                                                   |
| ------------------------------ | ----------------------------------------------------------------------------------------- |
| `profiles`                     | Links a Supabase Auth user to a Person and stores account active state                    |
| `profile_roles`                | Additive Administrator, PMO Officer, and Leadership Viewer roles                          |
| `departments`                  | Department directory with active state                                                    |
| `people`                       | Name, Department, username, position, active state                                        |
| `systems`                      | System directory                                                                          |
| `modules`                      | Modules belonging to Systems                                                              |
| `system_developer_assignments` | Effective Developer-to-System Assignment Periods                                          |
| `module_owner_assignments`     | Effective System-Owner-to-Module Assignment Periods; exactly one current owner per Module |

### Configuration

| Table                      | Purpose                                                          |
| -------------------------- | ---------------------------------------------------------------- |
| `priorities`               | Ordered, retireable Priority choices                             |
| `request_types`            | Retireable Request Type choices                                  |
| `reference_types`          | Retireable external Reference Types                              |
| `initiator_types`          | Retireable Initiator Types                                       |
| `workflow_template_stages` | Ordered default Stage suggestions and Stage Detail configuration |

### Portfolio

| Table                             | Purpose                                                                                              |
| --------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `initiatives`                     | Optional grouping for related Projects                                                               |
| `projects`                        | Current Project projection, identity, State, current Stage, current Ball Owner, and archive metadata |
| `project_pmo_assignments`         | Effective accountable PMO Officer history                                                            |
| `project_system_scopes`           | Entire-System or selected-Module impact                                                              |
| `project_participant_assignments` | Effective PMO, Developer, and System Owner Project assignments                                       |
| `project_references`              | Type, label, and URL                                                                                 |
| `project_stages`                  | Project-owned copied and custom Stages, order, and Stage Detail configuration                        |
| `stage_plan_revisions`            | Original and revised Planned Completion dates with reason and actor                                  |
| `closeout_assessments`            | Required governance answers for Closed Projects                                                      |

### History

| Table            | Purpose                                                                                                        |
| ---------------- | -------------------------------------------------------------------------------------------------------------- |
| `project_events` | Append-only Progress, Bump, State, Ball, workflow, assignment, correction, archive, and Project-change history |
| `audit_log`      | Append-only Administration and directory mutations with before/after values                                    |

`project_events` contains common event columns plus a validated JSON payload for type-specific values. It stores snapshots of display labels needed to keep historical output intelligible after directory or Stage renames.

The current values in `projects` are a read projection for fast screens; they are updated in the same PostgreSQL transaction as the corresponding event. Ball Ownership Periods, Hold Periods, and As-of results are derived from the ordered event ledger. With fewer than 100 Projects, compute these on demand first; add materialized projections only if measured performance requires them.

## 16. Next.js and Supabase architecture

### Application stack

- Next.js App Router with TypeScript
- React Server Components for authenticated reads by default
- Server Actions for form mutations and Route Handlers for CSV downloads
- Supabase Postgres, Auth, and Row Level Security
- `@supabase/ssr` for cookie-based sessions
- Tailwind CSS plus accessible unstyled/headless primitives for custom controls
- Zod schemas shared by forms and server mutation boundaries
- SQL migrations and seed data stored under `supabase/migrations`

Do not pin this specification to a framework version; use compatible stable releases at implementation time and commit the package lockfile.

### Data flow

```text
Browser
  -> Next.js Server Component / Server Action
      -> session and role verification
          -> Supabase RLS + transactional database function
              -> append event/audit row
              -> update current projection
                  -> revalidate affected Project and report views
```

Critical operations—Progress, Bump with transfer, State change, correction, PMO reassignment, and archive—must be atomic database transactions. A partial event/projection write is never acceptable.

### Authorization

- All authenticated application roles may read portfolio data and history.
- Leadership Viewers receive no mutation policies.
- PMO Officers may mutate only Projects for which they hold the current accountable assignment.
- Administrators may mutate all Projects and configuration and may correct history.
- Recheck authorization inside every Server Action or Route Handler.
- Enable RLS on every exposed application table.
- A Supabase service-role key, if needed for account provisioning, is server-only and never exposed through a `NEXT_PUBLIC_` variable.

### Rendering and caching

Authenticated portfolio pages are dynamically rendered and must not leak one user's response through a public cache. Revalidate the smallest affected routes after successful mutations. The small dataset does not require Supabase Realtime, background jobs, or a client-side global state store.

### Vercel environments

- Configure Supabase URL and publishable key separately for local, preview, and production environments.
- Store server secrets only in Vercel protected environment variables.
- Run database migrations before promoting a deployment that depends on them.
- Use Vercel preview deployments for pull requests.

## 17. Validation and failure behavior

- Validate all inputs on the server; client validation is convenience only.
- Reject duplicate Project Codes with a field-level error.
- Reject inactive People as new Participants or Ball Owners.
- Reject a non-participant Ball Owner.
- Reject any mutation that would leave a non-terminal Project without a Ball Owner.
- Reject deletion of visited Stages and referenced directory/configuration records.
- Reject any transition out of Closed or Cancelled.
- Warn before backdated events and planned-date changes; require confirmation and reasons where specified.
- Use optimistic concurrency on Project mutations. If another user changed the Project after the form loaded, preserve the user's input and require refresh/review instead of silently overwriting.
- Failed multi-record operations roll back completely and present a recoverable error.
- External Reference URLs open in a new tab with safe link attributes.

## 18. Accessibility and usability baseline

- All actions are keyboard reachable with visible focus.
- Every field has a persistent text label and an associated validation message.
- Dialogs trap focus, close predictably, and return focus to the invoking control.
- Tables have semantic headers and remain understandable without color.
- Group and Health colors always include a written label.
- Motion respects `prefers-reduced-motion`.
- Dates display explicitly as Philippine time; do not rely on the browser's local timezone.
- Destructive-looking terminal actions require explicit confirmation and state their irreversible effect.

## 19. Acceptance criteria

Release one is complete when all of the following pass:

1. An Administrator can create three application accounts and assign additive roles.
2. An Administrator can manage Departments, People, Systems, Modules, System Developers, and one current System Owner per Module while retaining prior assignments.
3. A PMO Officer can create a Pipeline Project with a unique immutable Project Code and required initial Ball Owner.
4. Moving a Project to Planned or Active enforces the required request, scope, affected-area, and participant information.
5. A Project receives a copy of the default Stages and can independently add, rename, reorder, configure, or remove upcoming Stages.
6. A PMO Officer can record a Progress Update with Effective time, Stage Detail, summary, and confirmed or changed Ball Owner.
7. A PMO Officer can add a Bump without changing Stage and may transfer the Ball in the same action.
8. Entering On Hold can transfer the Ball, pauses its turnaround clock, and tracks Hold duration separately.
9. Backdated events recalculate current and historical views without changing their Recorded timestamp.
10. Only an Administrator can supersede an erroneous historical event, and the original remains visible.
11. Closed and Cancelled Projects cannot reopen; only those States can be archived.
12. Latest Progress and Latest Bump show one latest item per Project, oldest first, with no-history Projects last.
13. Ball View always places every non-terminal Project under exactly one individual in exactly one group.
14. The As-of report produces different Effective and Recorded perspectives when late entry or correction makes them differ.
15. Turnaround reporting excludes Hold time from People while showing Hold time separately.
16. KRA/KPI cards show the agreed definitions and `Not yet calculated`, while Closeout Assessment data is captured.
17. Leadership Viewers can inspect all portfolio and audit views but cannot mutate data through either UI or direct requests.
18. The Project list, As-of report, Turnaround report, and Project history export valid CSV files.
19. No Excel import, project notifications, upload control, or reopen action appears in the release-one UI.
20. The production build deploys successfully to Vercel and uses the production Supabase environment without exposing secret keys.

## 20. Suggested implementation sequence

1. **Foundation** — Next.js scaffold, Supabase migrations, seed configuration, authentication, roles, and RLS.
2. **Directory** — Departments, People, Systems, Modules, and effective assignment histories.
3. **Projects** — creation, affected areas, participants, References, Project-owned Stages, and planned dates.
4. **History engine** — Progress, Bumps, Ball ownership, Hold periods, State changes, correction, and projections.
5. **Operational UI** — Project workspace, Dashboard queues, and Ball View.
6. **Reporting** — As-of reconstruction, Turnaround report, Closeout Assessment, and CSV exports.
7. **Hardening** — concurrency, error states, accessibility, role-boundary tests, and Vercel deployment.

Automated KPI calculation is a separate later phase and must not block release one.

## 21. Verification strategy

- Unit-test Stage variance, ownership duration, Hold exclusion, State invariants, and event ordering.
- Database-test RLS policies and transactional mutation functions for each role.
- Integration-test Effective versus Recorded As-of reconstruction, including backdated and superseded events.
- End-to-end test the Administrator, assigned PMO Officer, unassigned PMO Officer, and Leadership Viewer journeys.
- Test CSV quoting, timezone output, archived filters, empty activity, and repeated deployment versions.
- Run production builds against a non-production Supabase project before release.

## 22. Authoritative supporting documents

- `CONTEXT.md` — canonical domain vocabulary
- `docs/adr/0001-preserve-effective-and-recorded-dates.md`
- `docs/adr/0002-preserve-history-through-supersession-and-archival.md`
- `docs/adr/0003-make-closed-and-cancelled-projects-terminal.md`
- `docs/adr/0004-copy-default-stages-into-each-project.md`
- `docs/adr/0005-use-an-append-only-project-event-ledger.md`
- `PRODUCT.md` — durable product context

Technical implementation should follow the current official [Next.js authentication](https://nextjs.org/docs/app/guides/authentication) and [data mutation](https://nextjs.org/docs/app/getting-started/mutating-data) guidance, [Supabase SSR/Auth](https://supabase.com/docs/guides/auth/server-side) and [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) guidance, and [Vercel's Next.js deployment model](https://vercel.com/docs/frameworks/full-stack/nextjs).
