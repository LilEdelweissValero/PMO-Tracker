import { PageHeader } from "@/components/page-header";
import { requireAnyRole } from "@/lib/auth";
import { listPriorities } from "@/lib/data/configuration";
import { listProfiles } from "@/lib/data/session";
import { isDemoPreview } from "@/lib/demo";
import { createProjectAction } from "../actions";

const demoPriorities = [
  { id: "00000000-0000-0000-0000-000000000001", name: "Medium" },
];
const demoOfficers = [
  { id: "00000000-0000-0000-0000-000000000002", name: "Ana Reyes" },
];

export default async function NewProject() {
  await requireAnyRole(["administrator", "pmo_officer"]);
  const demoPreview = await isDemoPreview();
  const [priorityResult, profileResult] = demoPreview
    ? [null, null]
    : await Promise.all([listPriorities(), listProfiles()]);
  if (
    (priorityResult && !["success", "empty"].includes(priorityResult.status)) ||
    (profileResult && !["success", "empty"].includes(profileResult.status))
  ) {
    throw new Error("Unable to load Project creation choices.");
  }
  const priorities = demoPreview
    ? demoPriorities
    : priorityResult?.status === "success"
      ? priorityResult.data.filter((priority) => priority.active)
      : [];
  const officers = demoPreview
    ? demoOfficers
    : profileResult?.status === "success"
      ? profileResult.data.flatMap((profile) =>
          profile.active &&
          profile.profile_roles.some((role) => role.role === "pmo_officer")
            ? [{ id: profile.person_id, name: profile.people.name }]
            : [],
        )
      : [];
  const ready = priorities.length > 0 && officers.length > 0;
  return (
    <>
      <PageHeader
        title="Create a Project"
        description="Pipeline allows incomplete delivery details. The accountable PMO Officer is the initial participant and may hold the Ball."
      />
      {!ready && (
        <div className="notice">
          Project creation needs at least one active Priority and one active
          account with the PMO Officer role. Configure those first in Admin and
          Access.
        </div>
      )}
      <form action={createProjectAction} className="form-grid">
        <div className="field">
          <label htmlFor="code">Project Code</label>
          <input id="code" name="code" required />
          <small>Unique and immutable after creation.</small>
        </div>
        <div className="field">
          <label htmlFor="name">Project Name</label>
          <input id="name" name="name" required />
        </div>
        <div className="field">
          <label htmlFor="priorityId">Priority</label>
          <select id="priorityId" name="priorityId" required disabled={!ready}>
            {priorities.map((priority) => (
              <option value={priority.id} key={priority.id}>
                {priority.name}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="state">Project State</label>
          <select id="state" name="state" disabled={!ready}>
            <option>Pipeline</option>
          </select>
          <small>
            Start in Pipeline; delivery details can be completed before planning
            or activation.
          </small>
        </div>
        <div className="field">
          <label htmlFor="pmoOfficerId">Accountable PMO Officer</label>
          <select
            id="pmoOfficerId"
            name="pmoOfficerId"
            required
            disabled={!ready}
          >
            {officers.map((officer) => (
              <option value={officer.id} key={officer.id}>
                {demoPreview ? "Demo · " : ""}
                {officer.name}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="ballOwnerId">Initial Ball Owner</label>
          <select
            id="ballOwnerId"
            name="ballOwnerId"
            required
            disabled={!ready}
          >
            {officers.map((officer) => (
              <option value={officer.id} key={officer.id}>
                {demoPreview ? "Demo · " : ""}
                {officer.name} (PMO)
              </option>
            ))}
          </select>
        </div>
        <div className="field full">
          <label htmlFor="scope">
            Scope / Description <small>(optional in Pipeline)</small>
          </label>
          <textarea id="scope" name="scope" rows={6} />
        </div>
        <input type="hidden" name="version" value="0" />
        <div className="field full">
          <button disabled={!ready}>
            Create Project & copy Workflow Template
          </button>
        </div>
      </form>
    </>
  );
}
