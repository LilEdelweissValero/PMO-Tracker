import { PageHeader } from "@/components/page-header";
import { requireAnyRole } from "@/lib/auth";
import { listDepartments, listPeople } from "@/lib/data/directory";
import { isDemoPreview } from "@/lib/demo";
import { createDepartmentAction, createPersonAction } from "./actions";

const demoDepartments = [{ id: "demo", name: "Demo · PMO", active: true }];
const demoPeople = [
  {
    id: "demo",
    name: "Ana Reyes",
    username: "demo.areyes",
    position: "PMO Officer",
    active: true,
    departments: { name: "Demo · PMO" },
  },
];

export default async function People() {
  await requireAnyRole(["administrator"]);
  const demoPreview = await isDemoPreview();
  const [departmentResult, peopleResult] = demoPreview
    ? [null, null]
    : await Promise.all([listDepartments(), listPeople()]);
  if (
    (departmentResult &&
      !["success", "empty"].includes(departmentResult.status)) ||
    (peopleResult && !["success", "empty"].includes(peopleResult.status))
  ) {
    throw new Error("Unable to load the People directory.");
  }
  const departments = demoPreview
    ? demoDepartments
    : departmentResult?.status === "success"
      ? departmentResult.data
      : [];
  const people = demoPreview
    ? demoPeople
    : peopleResult?.status === "success"
      ? peopleResult.data
      : [];
  return (
    <>
      <PageHeader
        title="People & Departments"
        description="Inactive People remain in history but cannot receive a new assignment or the Ball."
        actions={null}
      />
      <div className="form-grid">
        <form action={createDepartmentAction} className="field">
          <label htmlFor="department-name">New Department</label>
          <input
            id="department-name"
            name="name"
            placeholder="Department name"
            required
            disabled={demoPreview}
          />
          <button disabled={demoPreview}>Add Department</button>
        </form>
        <form action={createPersonAction} className="field">
          <label htmlFor="person-name">New Person</label>
          <input
            id="person-name"
            name="name"
            placeholder="Full name"
            required
            disabled={demoPreview}
          />
          <input
            name="username"
            placeholder="Username"
            required
            disabled={demoPreview}
          />
          <input
            name="position"
            placeholder="Position"
            required
            disabled={demoPreview}
          />
          <select
            name="departmentId"
            required
            disabled={demoPreview || !departments.length}
          >
            <option value="">Select Department</option>
            {departments
              .filter((department) => department.active)
              .map((department) => (
                <option value={department.id} key={department.id}>
                  {department.name}
                </option>
              ))}
          </select>
          <button disabled={demoPreview || !departments.length}>
            Add Person
          </button>
        </form>
      </div>
      <table className="data-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Department</th>
            <th>Username</th>
            <th>Position</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {people.map((person) => (
            <tr key={person.id}>
              <td>{person.name}</td>
              <td>{person.departments.name}</td>
              <td>{person.username}</td>
              <td>{person.position}</td>
              <td>{person.active ? "Active" : "Inactive"}</td>
              <td>—</td>
            </tr>
          ))}
        </tbody>
      </table>
      {!people.length && (
        <div className="notice">
          No People yet. Add a Department, then add the first Person.
        </div>
      )}
    </>
  );
}
