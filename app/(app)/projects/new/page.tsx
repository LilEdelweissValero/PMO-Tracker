import { PageHeader } from "@/components/page-header";
import { createProjectAction } from "../actions";
export default function NewProject() {
  return (
    <>
      <PageHeader
        title="Create a Project"
        description="Pipeline allows incomplete delivery details. The accountable PMO Officer is the initial participant and may hold the Ball."
      />
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
          <select id="priorityId" name="priorityId" required>
            <option value="00000000-0000-0000-0000-000000000001">Medium</option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="state">Project State</label>
          <select id="state" name="state">
            <option>Pipeline</option>
            <option>Planned</option>
            <option>Active</option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="pmoOfficerId">Accountable PMO Officer</label>
          <select id="pmoOfficerId" name="pmoOfficerId">
            <option value="00000000-0000-0000-0000-000000000002">
              Demo · Ana Reyes
            </option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="ballOwnerId">Initial Ball Owner</label>
          <select id="ballOwnerId" name="ballOwnerId">
            <option value="00000000-0000-0000-0000-000000000002">
              Demo · Ana Reyes (PMO)
            </option>
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
          <button>Create Project & copy Workflow Template</button>
        </div>
      </form>
    </>
  );
}
