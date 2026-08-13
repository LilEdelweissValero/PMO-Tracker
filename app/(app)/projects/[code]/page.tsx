import Link from "next/link";
import { notFound } from "next/navigation";
import { BallIcon, BumpIcon } from "@/components/icons";
import { demoProjects } from "@/lib/demo";
import { PageHeader } from "@/components/page-header";
export default async function Workspace({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  const p =
    demoProjects.find(
      (x) => x.code.toLowerCase() === decodeURIComponent(code).toLowerCase(),
    ) ??
    (code
      ? {
          ...demoProjects[2],
          code: decodeURIComponent(code),
          name: "New Project",
        }
      : null);
  if (!p) notFound();
  return (
    <>
      <div className="project-hero">
        <div>
          <span className="project-code">{p.code}</span>
          <h1>{p.name}</h1>
          <div className="project-facts">
            <span>{p.state}</span>
            <span>{p.priority}</span>
            <span>{p.stage}</span>
          </div>
        </div>
        <div className="ball-callout">
          <BallIcon size={34} />
          <span>
            <small>Ball with · {p.group}</small>
            <strong>{p.owner}</strong>
            <time>{p.held}</time>
          </span>
        </div>
      </div>
      <div className="page-actions" style={{ marginTop: 14 }}>
        <button className="pink">Add Progress</button>
        <button className="secondary">
          <BumpIcon size={18} />
          Add Bump
        </button>
        <button className="secondary">Change State</button>
      </div>
      <nav className="tabs" aria-label="Project sections">
        <a href="#overview">Overview</a>
        <a href="#timeline">Timeline</a>
        <a href="#stages">Stages</a>
        <a href="#turnaround">Turnaround</a>
        <a href="#history">History</a>
      </nav>
      <section id="overview" className="section">
        <div className="section-head">
          <div>
            <h2>Overview</h2>
            <p>
              Request, affected areas, participants, and external References.
            </p>
          </div>
          <button className="secondary">Edit overview</button>
        </div>
        <table className="data-table">
          <tbody>
            <tr>
              <th>PMO Officer</th>
              <td>{p.pmo}</td>
              <th>Requester</th>
              <td>Not recorded</td>
            </tr>
            <tr>
              <th>Scope / Description</th>
              <td colSpan={3}>Demo scope has not been entered.</td>
            </tr>
            <tr>
              <th>Affected areas</th>
              <td>Demo System · Intake module</td>
              <th>Participants</th>
              <td>
                {p.owner} ({p.group})
              </td>
            </tr>
          </tbody>
        </table>
      </section>
      <section id="timeline" className="section">
        <div className="section-head">
          <div>
            <h2>Timeline</h2>
            <p>
              Ordered by Effective time; Recorded time remains visible for
              audit.
            </p>
          </div>
          <Link
            className="button secondary"
            href={`/api/exports/projects/${encodeURIComponent(p.code)}/history`}
          >
            Export CSV
          </Link>
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>Event</th>
              <th>Effective (PHT)</th>
              <th>Recorded (PHT)</th>
              <th>Result</th>
              <th>Actor</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Project created</td>
              <td>08 Aug 2026, 09:00 PHT</td>
              <td>08 Aug 2026, 09:04 PHT</td>
              <td>Pipeline · Ball with {p.owner}</td>
              <td>Ana Reyes</td>
            </tr>
          </tbody>
        </table>
      </section>
      <section id="stages" className="section">
        <PageHeader
          title="Project Stages"
          description="This list belongs only to this Project. Visited Stages remain in history; upcoming ones can be tailored."
          actions={<button className="secondary">Tailor Stages</button>}
        />
        <table className="data-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Stage</th>
              <th>Stage Detail</th>
              <th>Planned completion</th>
              <th>Variance</th>
            </tr>
          </thead>
          <tbody>
            {[
              "Engagement Meeting",
              "TICRO #1 Requested",
              "Dev Start",
              "Deployed",
            ].map((s, i) => (
              <tr key={s}>
                <td>{i + 1}</td>
                <td>
                  <strong>{s}</strong>
                </td>
                <td>
                  {s === "Deployed" ? "Deployment Version · required" : "—"}
                </td>
                <td>Not planned</td>
                <td>—</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </>
  );
}
