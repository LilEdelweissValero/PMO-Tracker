import Link from "next/link";
import Image from "next/image";
import { notFound } from "next/navigation";
import { demoProjects, isDemoPreview, type ProjectRow } from "@/lib/demo";
import { getProjectByCode } from "@/lib/data/projects";
import { listProjectHistory } from "@/lib/data/events";
import { formatPhilippine } from "@/lib/time";
import { PageHeader } from "@/components/page-header";
import {
  addBumpAction,
  addProgressAction,
  changeStateAction,
  closeProjectAction,
  transferBallAction,
} from "../actions";
export default async function Workspace({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  const decodedCode = decodeURIComponent(code);
  const demoPreview = await isDemoPreview();
  const demoProject = demoProjects.find(
    (x) => x.code.toLowerCase() === decodeURIComponent(code).toLowerCase(),
  ) ?? {
    ...demoProjects[2],
    code: decodedCode,
    name: "New Project",
  };
  const projectResult = demoPreview
    ? null
    : await getProjectByCode(decodedCode);
  if (projectResult?.status === "not_found") notFound();
  if (projectResult && projectResult.status !== "success") {
    throw new Error("Unable to load this Project workspace.");
  }
  const workspace =
    projectResult?.status === "success" ? projectResult.data : null;
  const currentAssignment = workspace?.project_participant_assignments.find(
    (assignment) =>
      assignment.person_id === workspace.ball_owner_id &&
      assignment.effective_to === null,
  );
  const currentStage = workspace?.project_stages.find(
    (stage) => stage.id === workspace.current_stage_id,
  );
  const p: ProjectRow = demoPreview
    ? demoProject
    : {
        code: workspace!.code,
        name: workspace!.name,
        state: workspace!.state,
        priority: workspace!.priorities.name,
        stage: currentStage?.name ?? "Not started",
        owner: workspace!.ball_owner?.name ?? "Unassigned",
        group: currentAssignment?.participant_group ?? "PMO",
        held: "—",
        pmo: workspace!.pmo_officer.name,
      };
  const historyResult = workspace
    ? await listProjectHistory(workspace.id)
    : null;
  if (historyResult && !["success", "empty"].includes(historyResult.status)) {
    throw new Error("Unable to load this Project history.");
  }
  const history = historyResult?.status === "success" ? historyResult.data : [];
  return (
    <>
      <div className="project-hero">
        <div>
          <span className="project-code">{p.code}</span>
          <h1>{p.name}</h1>
          <div className="project-facts">
            <span>{p.state}</span>
            <span>{p.priority}</span>
            <span>{p.stage}</span>
          </div>
        </div>
        <div className="ball-callout">
          <Image src="/assets/ball.png" alt="" width={92} height={92} />
          <span>
            <small>Ball with · {p.group}</small>
            <strong>{p.owner}</strong>
            <time>{p.held}</time>
          </span>
        </div>
      </div>
      <div className="page-actions project-actions">
        <details>
          <summary className="button pink">Add Progress</summary>
          <form action={addProgressAction} className="action-popover">
            <input
              type="hidden"
              name="projectId"
              value={workspace?.id ?? "00000000-0000-4000-8000-000000000021"}
            />
            <input
              type="hidden"
              name="version"
              value={workspace?.version ?? 0}
            />
            <input
              type="hidden"
              name="ballOwnerId"
              value={
                workspace?.ball_owner_id ??
                "00000000-0000-0000-0000-000000000002"
              }
            />
            <input type="hidden" name="code" value={p.code} />
            <label htmlFor="progress-stage">Stage</label>
            <select id="progress-stage" name="stageId" required>
              {demoPreview && (
                <option value="00000000-0000-4000-8000-000000000031">
                  {p.stage}
                </option>
              )}
              {(workspace?.project_stages ?? [])
                .filter((stage) => stage.active)
                .map((stage) => (
                  <option value={stage.id} key={stage.id}>
                    {stage.name}
                  </option>
                ))}
            </select>
            <label htmlFor="progress-summary">Progress summary</label>
            <textarea
              id="progress-summary"
              name="summary"
              required
              maxLength={4000}
            />
            <button
              disabled={!demoPreview && !workspace?.project_stages.length}
            >
              Save Progress
            </button>
          </form>
        </details>
        <details>
          <summary className="button secondary">
            <Image src="/assets/fist.png" alt="" width={34} height={34} />
            Add Bump
          </summary>
          <form action={addBumpAction} className="action-popover">
            <input
              type="hidden"
              name="projectId"
              value={workspace?.id ?? "00000000-0000-4000-8000-000000000021"}
            />
            <input
              type="hidden"
              name="version"
              value={workspace?.version ?? 0}
            />
            <input
              type="hidden"
              name="ballOwnerId"
              value={
                workspace?.ball_owner_id ??
                "00000000-0000-0000-0000-000000000002"
              }
            />
            <input type="hidden" name="code" value={p.code} />
            <label htmlFor="bump-text">Conversation note</label>
            <textarea id="bump-text" name="text" required maxLength={4000} />
            <button>Save Bump</button>
          </form>
        </details>
        <details>
          <summary className="button secondary">Change State</summary>
          <form action={changeStateAction} className="action-popover">
            <input
              type="hidden"
              name="projectId"
              value={workspace?.id ?? "00000000-0000-4000-8000-000000000021"}
            />
            <input
              type="hidden"
              name="version"
              value={workspace?.version ?? 0}
            />
            <input
              type="hidden"
              name="ballOwnerId"
              value={
                workspace?.ball_owner_id ??
                "00000000-0000-0000-0000-000000000002"
              }
            />
            <input type="hidden" name="code" value={p.code} />
            <label htmlFor="resulting-state">New state</label>
            <select
              id="resulting-state"
              name="resultingState"
              defaultValue={p.state}
            >
              <option>Pipeline</option>
              <option>Planned</option>
              <option>Active</option>
              <option>On Hold</option>
              <option>Cancelled</option>
            </select>
            <label htmlFor="state-reason">Reason</label>
            <textarea id="state-reason" name="reason" maxLength={4000} />
            <button>Change State</button>
          </form>
        </details>
        <details>
          <summary className="button secondary">Transfer Ball</summary>
          <form action={transferBallAction} className="action-popover">
            <input
              type="hidden"
              name="projectId"
              value={workspace?.id ?? "00000000-0000-4000-8000-000000000021"}
            />
            <input
              type="hidden"
              name="version"
              value={workspace?.version ?? 0}
            />
            <input
              type="hidden"
              name="ballOwnerId"
              value={
                workspace?.ball_owner_id ??
                "00000000-0000-0000-0000-000000000002"
              }
            />
            <input type="hidden" name="code" value={p.code} />
            <label htmlFor="new-ball-owner">New Ball Owner</label>
            <select
              id="new-ball-owner"
              name="newBallOwnerId"
              required
              defaultValue={workspace?.ball_owner_id ?? ""}
            >
              {demoPreview && (
                <option value="00000000-0000-0000-0000-000000000002">
                  Ana Reyes
                </option>
              )}
              {(workspace?.project_participant_assignments ?? [])
                .filter((assignment) => assignment.effective_to === null)
                .map((assignment) => (
                  <option
                    value={assignment.person_id}
                    key={assignment.person_id}
                  >
                    {assignment.people.name} ({assignment.participant_group})
                  </option>
                ))}
            </select>
            <button
              disabled={
                !demoPreview &&
                !workspace?.project_participant_assignments.some(
                  (assignment) => assignment.effective_to === null,
                )
              }
            >
              Transfer Ball
            </button>
          </form>
        </details>
        <details>
          <summary className="button secondary">Close Project</summary>
          <form
            action={closeProjectAction}
            className="action-popover closeout-form"
          >
            <input
              type="hidden"
              name="projectId"
              value={workspace?.id ?? "00000000-0000-4000-8000-000000000021"}
            />
            <input
              type="hidden"
              name="version"
              value={workspace?.version ?? 0}
            />
            <input type="hidden" name="code" value={p.code} />
            <label>
              <input type="checkbox" name="dodMet" /> Definition of Done met
            </label>
            <label htmlFor="dod-explanation">DoD explanation</label>
            <textarea id="dod-explanation" name="dodExplanation" required />
            <label>
              <input type="checkbox" name="methodologyCompliant" /> Methodology
              compliant
            </label>
            <label htmlFor="methodology-explanation">
              Methodology explanation
            </label>
            <textarea
              id="methodology-explanation"
              name="methodologyExplanation"
              required
            />
            <label>
              <input type="checkbox" name="documentationComplete" />{" "}
              Documentation complete
            </label>
            <label htmlFor="documentation-explanation">
              Documentation explanation
            </label>
            <textarea
              id="documentation-explanation"
              name="documentationExplanation"
              required
            />
            <label htmlFor="stakeholder-rating">Stakeholder rating</label>
            <select
              id="stakeholder-rating"
              name="stakeholderRating"
              defaultValue="3"
              required
            >
              <option value="1">1 — Poor</option>
              <option value="2">2 — Needs improvement</option>
              <option value="3">3 — Acceptable</option>
              <option value="4">4 — Good</option>
              <option value="5">5 — Excellent</option>
            </select>
            <label htmlFor="stakeholder-comment">Stakeholder comment</label>
            <textarea id="stakeholder-comment" name="stakeholderComment" />
            <button>Save Closeout &amp; Close Project</button>
          </form>
        </details>
      </div>
      <nav className="tabs" aria-label="Project sections">
        <a href="#overview">Overview</a>
        <a href="#timeline">Timeline</a>
        <a href="#stages">Stages</a>
        <a href="#turnaround">Turnaround</a>
        <a href="#history">History</a>
      </nav>
      <section id="overview" className="section">
        <div className="section-head">
          <div>
            <h2>Overview</h2>
            <p>
              Request, affected areas, participants, and external References.
            </p>
          </div>
          <button className="secondary">Edit overview</button>
        </div>
        <table className="data-table">
          <tbody>
            <tr>
              <th>PMO Officer</th>
              <td>{p.pmo}</td>
              <th>Requester</th>
              <td>{workspace?.requester_department_name ?? "Not recorded"}</td>
            </tr>
            <tr>
              <th>Scope / Description</th>
              <td colSpan={3}>{workspace?.scope ?? "Not recorded"}</td>
            </tr>
            <tr>
              <th>Affected areas</th>
              <td>
                {workspace
                  ? `${workspace.project_system_scopes.length} affected area${workspace.project_system_scopes.length === 1 ? "" : "s"}`
                  : "Demo System · Intake module"}
              </td>
              <th>Participants</th>
              <td>
                {p.owner} ({p.group})
              </td>
            </tr>
          </tbody>
        </table>
      </section>
      <section id="timeline" className="section">
        <div className="section-head">
          <div>
            <h2>Timeline</h2>
            <p>
              Ordered by Effective time; Recorded time remains visible for
              audit.
            </p>
          </div>
          <Link
            className="button secondary"
            href={`/api/exports/projects/${encodeURIComponent(p.code)}/history`}
          >
            Export CSV
          </Link>
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>Event</th>
              <th>Effective (PHT)</th>
              <th>Recorded (PHT)</th>
              <th>Result</th>
              <th>Actor</th>
            </tr>
          </thead>
          <tbody>
            {demoPreview ? (
              <tr>
                <td>Project created</td>
                <td>08 Aug 2026, 09:00 PHT</td>
                <td>08 Aug 2026, 09:04 PHT</td>
                <td>Pipeline · Ball with {p.owner}</td>
                <td>Ana Reyes</td>
              </tr>
            ) : (
              history.map((event) => (
                <tr key={event.event_id}>
                  <td>{event.effective_event_type.replaceAll("_", " ")}</td>
                  <td>{formatPhilippine(event.effective_at)}</td>
                  <td>{formatPhilippine(event.recorded_at)}</td>
                  <td>
                    {event.resulting_state ?? "—"} ·{" "}
                    {event.resulting_stage_label ?? "No stage"}
                  </td>
                  <td>
                    {event.actor_id ? event.actor_id.slice(0, 8) : "System"}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </section>
      <section id="stages" className="section">
        <PageHeader
          title="Project Stages"
          description="This list belongs only to this Project. Visited Stages remain in history; upcoming ones can be tailored."
          actions={<button className="secondary">Tailor Stages</button>}
        />
        <table className="data-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Stage</th>
              <th>Stage Detail</th>
              <th>Planned completion</th>
              <th>Variance</th>
            </tr>
          </thead>
          <tbody>
            {(workspace
              ? workspace.project_stages
              : [
                  {
                    id: "demo-1",
                    name: "Engagement Meeting",
                    sort_order: 1,
                    detail_label: null,
                  },
                  {
                    id: "demo-2",
                    name: "TICRO #1 Requested",
                    sort_order: 2,
                    detail_label: null,
                  },
                  {
                    id: "demo-3",
                    name: "Dev Start",
                    sort_order: 3,
                    detail_label: null,
                  },
                  {
                    id: "demo-4",
                    name: "Deployed",
                    sort_order: 4,
                    detail_label: "Deployment Version",
                  },
                ]
            ).map((stage) => (
              <tr key={stage.id}>
                <td>{stage.sort_order}</td>
                <td>
                  <strong>{stage.name}</strong>
                </td>
                <td>{stage.detail_label ?? "—"}</td>
                <td>Not planned</td>
                <td>—</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </>
  );
}
