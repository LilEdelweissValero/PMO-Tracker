import Link from "next/link";
import { PageHeader } from "@/components/page-header";
export default function Turnaround() {
  return (
    <>
      <PageHeader
        title="Turnaround report"
        description="Elapsed responsibility, not employee performance. Hold time is excluded from People and shown separately."
        actions={
          <Link className="button secondary" href="/api/exports/turnaround">
            Export CSV
          </Link>
        }
      />
      <form className="filterbar">
        <input type="date" aria-label="Start date" />
        <input type="date" aria-label="End date" />
        <select aria-label="Group">
          <option>All groups</option>
          <option>PMO</option>
          <option>Developer</option>
          <option>System Owner</option>
        </select>
        <button>Apply period</button>
      </form>
      <table className="data-table">
        <thead>
          <tr>
            <th>Project</th>
            <th>Person / group</th>
            <th>Received (PHT)</th>
            <th>Released (PHT)</th>
            <th>Net duration</th>
            <th>Hold excluded</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>DEMO-008</td>
            <td>
              Luis Cruz
              <br />
              <small>Developer</small>
            </td>
            <td>10 Aug 2026, 08:00</td>
            <td>Current</td>
            <td>3d 2h</td>
            <td>1d 4h</td>
          </tr>
        </tbody>
      </table>
    </>
  );
}
