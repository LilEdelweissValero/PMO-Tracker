import { PageHeader } from "@/components/page-header";
export default function Systems() {
  return (
    <>
      <PageHeader
        title="Systems & Modules"
        description="Directory assignments use effective periods. They never silently change existing Project Participants."
        actions={<button>Add System</button>}
      />
      <table className="data-table">
        <thead>
          <tr>
            <th>System</th>
            <th>Module</th>
            <th>Current Developers</th>
            <th>Current System Owner</th>
            <th>Effective from</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Demo System</td>
            <td>Intake</td>
            <td>Luis Cruz</td>
            <td>Mika Santos</td>
            <td>01 Aug 2026, 08:00 PHT</td>
          </tr>
        </tbody>
      </table>
    </>
  );
}
