import { PageHeader } from "@/components/page-header";
export default function Access() {
  return (
    <>
      <PageHeader
        title="Application access"
        description="Accounts link to People. Roles are additive; deactivation does not deactivate the directory Person."
        actions={<button>Provision account</button>}
      />
      <table className="data-table">
        <thead>
          <tr>
            <th>Person</th>
            <th>Email</th>
            <th>Roles</th>
            <th>Account</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Ana Reyes</td>
            <td>demo@example.invalid</td>
            <td>Administrator · PMO Officer</td>
            <td>Active</td>
            <td>
              <button className="secondary">Manage</button>
            </td>
          </tr>
        </tbody>
      </table>
    </>
  );
}
