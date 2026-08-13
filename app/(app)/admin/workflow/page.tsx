import Link from "next/link";
import { PageHeader } from "@/components/page-header";
const stages = [
  "Engagement Meeting",
  "TICRO #1 Requested",
  "TICRO #1 Approved",
  "TICRO #2 Requested",
  "TICRO #2 Approved",
  "Signed All Required Documents",
  "WBS Onboarded in Jira",
  "Dev Start",
  "Dev End",
  "UAT Start",
  "UAT End",
  "UAT Signed Off",
  "Deployed",
  "All Required Documents Submitted",
];
export default function Workflow() {
  return (
    <>
      <PageHeader
        title="Workflow Template"
        description="New Projects receive a copy. Existing Project Stage lists are never changed."
        actions={<button>Add Stage</button>}
      />
      <nav className="tabs">
        <a href="/admin/workflow">Workflow</a>
        <Link href="/admin/lists">Lists</Link>
        <Link href="/admin/access">Access</Link>
        <Link href="/admin/audit">Audit</Link>
      </nav>
      <table className="data-table">
        <thead>
          <tr>
            <th>Order</th>
            <th>Stage suggestion</th>
            <th>Stage Detail</th>
            <th>Required</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {stages.map((s, i) => (
            <tr key={s}>
              <td>{i + 1}</td>
              <td>
                <strong>{s}</strong>
              </td>
              <td>
                {s.includes("Requested")
                  ? "Documents Submitted"
                  : s === "Deployed"
                    ? "Deployment Version"
                    : "—"}
              </td>
              <td>
                {s.includes("Requested") || s === "Deployed" ? "Yes" : "No"}
              </td>
              <td>
                <button className="secondary">Edit</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}
