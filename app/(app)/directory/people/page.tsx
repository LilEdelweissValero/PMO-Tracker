import { PageHeader } from "@/components/page-header";
export default function People() {
  return (
    <>
      <PageHeader
        title="People & Departments"
        description="Inactive People remain in history but cannot receive a new assignment or the Ball."
        actions={<button>Add Person</button>}
      />
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
          <tr>
            <td>Ana Reyes</td>
            <td>Demo · PMO</td>
            <td>demo.areyes</td>
            <td>PMO Officer</td>
            <td>Active</td>
            <td>
              <button className="secondary">Edit</button>
            </td>
          </tr>
        </tbody>
      </table>
    </>
  );
}
