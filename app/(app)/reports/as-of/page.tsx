import Link from "next/link";
import { PageHeader } from "@/components/page-header";
import { demoProjects } from "@/lib/demo";
export default function AsOf() {
  return (
    <>
      <PageHeader
        title="As-of report"
        description="Reconstruct operational reality by Effective time, or what the tracker contained by Recorded time."
        actions={
          <Link className="button secondary" href="/api/exports/as-of">
            Export CSV
          </Link>
        }
      />
      <form className="filterbar">
        <input
          type="datetime-local"
          aria-label="Philippine cutoff date and time"
          defaultValue="2026-08-13T09:00"
        />
        <select aria-label="Perspective">
          <option value="effective">Effective view</option>
          <option value="recorded">Recorded view</option>
        </select>
        <button>Reconstruct</button>
      </form>
      <div className="notice">
        <strong>Philippine time</strong> The selected cutoff is interpreted in
        Asia/Manila (UTC+08:00).
      </div>
      <table className="data-table">
        <thead>
          <tr>
            <th>Project</th>
            <th>State / Stage</th>
            <th>Priority</th>
            <th>PMO Officer</th>
            <th>Ball Owner</th>
            <th>Latest Progress</th>
          </tr>
        </thead>
        <tbody>
          {demoProjects.map((p) => (
            <tr key={p.code}>
              <td>
                <strong>{p.code}</strong>
                <br />
                {p.name}
              </td>
              <td>
                {p.state}
                <br />
                {p.stage}
              </td>
              <td>{p.priority}</td>
              <td>{p.pmo}</td>
              <td>
                {p.owner}
                <br />
                <small>{p.group}</small>
              </td>
              <td>{p.latestProgress ?? "No update yet"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}
