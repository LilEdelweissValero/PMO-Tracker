import { PageHeader } from "@/components/page-header";
export default function Audit() {
  return (
    <>
      <PageHeader
        title="Audit history"
        description="Append-only administration, directory, configuration, and Project corrections."
      />
      <table className="data-table">
        <thead>
          <tr>
            <th>Recorded (PHT)</th>
            <th>Actor</th>
            <th>Entity</th>
            <th>Action</th>
            <th>Change</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>13 Aug 2026, 09:04</td>
            <td>Ana Reyes</td>
            <td>Demo Project</td>
            <td>Created</td>
            <td>Initial projection and Workflow Template copy</td>
          </tr>
        </tbody>
      </table>
    </>
  );
}
