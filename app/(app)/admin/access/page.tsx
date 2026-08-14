import { PageHeader } from "@/components/page-header";
import { requireAnyRole, type Role } from "@/lib/auth";
import { listUnlinkedActivePeople } from "@/lib/data/directory";
import { listProfiles, type ProfileWithAccess } from "@/lib/data/session";
import { isDemoPreview } from "@/lib/demo";
import { ManageAccessForm, ProvisionAccountForm } from "./access-forms";

const roleLabels: Record<Role, string> = {
  administrator: "Administrator",
  pmo_officer: "PMO Officer",
  leadership_viewer: "Leadership Viewer",
};

export default async function Access() {
  await requireAnyRole(["administrator"]);
  const demoPreview = await isDemoPreview();
  let accounts: ProfileWithAccess[];
  let availablePeople: { id: string; name: string; position: string }[];
  if (demoPreview) {
    accounts = [
      {
        id: "00000000-0000-4000-8000-000000000001",
        person_id: "00000000-0000-4000-8000-000000000002",
        email: "demo.admin@example.invalid",
        active: true,
        created_at: "2026-08-14T00:00:00.000Z",
        people: { name: "Demo Administrator" },
        profile_roles: [
          { role: "administrator" },
          { role: "pmo_officer" },
          { role: "leadership_viewer" },
        ],
      },
    ];
    availablePeople = [];
  } else {
    const [profilesResult, peopleResult] = await Promise.all([
      listProfiles(),
      listUnlinkedActivePeople(),
    ]);
    if (
      !["success", "empty"].includes(profilesResult.status) ||
      !["success", "empty"].includes(peopleResult.status)
    ) {
      throw new Error("Unable to load application access data.");
    }
    accounts = profilesResult.status === "success" ? profilesResult.data : [];
    availablePeople =
      peopleResult.status === "success" ? peopleResult.data : [];
  }

  return (
    <>
      <PageHeader
        title="Application access"
        description="Invite an existing directory Person, combine roles deliberately, and keep account access separate from directory activity."
        actions={
          <a className="button" href="#provision-account">
            Provision account
          </a>
        }
      />

      <section id="provision-account" className="section access-provisioning">
        <div className="section-head">
          <div>
            <span className="instrument-label">Private invitation</span>
            <h2>Provision account</h2>
          </div>
          <p>Auth creation is rolled back if Profile or role linking fails.</p>
        </div>
        {availablePeople.length === 0 ? (
          <div className="notice">
            Every active directory Person already has an application account.
          </div>
        ) : null}
        <ProvisionAccountForm people={availablePeople} disabled={demoPreview} />
      </section>

      <section className="section">
        <div className="section-head">
          <div>
            <span className="instrument-label">Active profile ledger</span>
            <h2>Provisioned accounts</h2>
          </div>
          <p>
            {accounts.length} account{accounts.length === 1 ? "" : "s"}
          </p>
        </div>
        <div className="table-scroll">
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
              {accounts.map((account) => {
                const accountRoles = account.profile_roles.map(
                  ({ role }) => role,
                );
                return (
                  <tr key={account.id}>
                    <td>
                      <strong>{account.people.name}</strong>
                    </td>
                    <td>{account.email ?? "Email not recorded"}</td>
                    <td>
                      {accountRoles.map((role) => roleLabels[role]).join(" · ")}
                    </td>
                    <td>
                      <span
                        className={`status ${account.active ? "active" : "inactive"}`}
                      >
                        {account.active ? "Active" : "Inactive"}
                      </span>
                    </td>
                    <td>
                      <details className="access-manager">
                        <summary>Manage</summary>
                        <ManageAccessForm
                          profileId={account.id}
                          active={account.active}
                          roles={accountRoles}
                          disabled={demoPreview}
                        />
                      </details>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}
