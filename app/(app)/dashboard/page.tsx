import Link from "next/link";
import { PageHeader } from "@/components/page-header";
import { ProjectStrip } from "@/components/project-strip";
import { demoProjects } from "@/lib/demo";
import { BumpIcon } from "@/components/icons";
const kras = [
  {
    name: "Project Efficiency",
    metrics: [
      ["Schedule Performance Index", "SPI = EV / PV · target ≥ 1.0"],
      ["Cost Performance Index", "CPI = EV / AC · target ≥ 1.0"],
      ["Project Success Rate", "Target ≥ 90%"],
    ],
  },
  {
    name: "Project Safety",
    metrics: [
      ["Change Control Stability", "Stable below 10%"],
      ["Health Recovery Rate", "Target ≥ 75%"],
    ],
  },
  {
    name: "Project Governance",
    metrics: [
      ["Methodology Compliance", "Target ≥ 95%"],
      ["Documentation Compliance", "Target 100%"],
      ["Stakeholder Approval", "Target ≥ 4.0 / 5.0"],
    ],
  },
];
export default function Dashboard() {
  return (
    <>
      <PageHeader
        title="Good morning, PMO"
        description="The portfolio’s longest-waiting work is first. No invented performance metrics—only agreed definitions until calculation is implemented."
        actions={
          <select aria-label="KPI period" defaultValue="quarter">
            <option value="month">Current month</option>
            <option value="quarter">Current quarter</option>
            <option value="year">Current year</option>
            <option value="custom">Custom range</option>
          </select>
        }
      />
      <div className="kra-grid">
        {kras.map((k) => (
          <section className="kra" key={k.name}>
            <h2>{k.name}</h2>
            {k.metrics.map(([n, d]) => (
              <div className="metric" key={n}>
                <strong>{n}</strong>
                <p>{d}</p>
                <span className="status">Not yet calculated</span>
              </div>
            ))}
          </section>
        ))}
      </div>
      <section className="section">
        <div className="section-head">
          <div>
            <h2>Latest Progress</h2>
            <p>
              Oldest effective update first; no-history Projects appear last.
            </p>
          </div>
          <Link
            className="button pink"
            href="/projects/DEMO-021?dialog=progress"
          >
            Add Progress
          </Link>
        </div>
        <div className="strip-list">
          {demoProjects.map((p) => (
            <ProjectStrip key={p.code} project={p} />
          ))}
        </div>
      </section>
      <section className="section">
        <div className="section-head">
          <div>
            <h2 style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <BumpIcon />
              Latest Bumps
            </h2>
            <p>Conversational updates without a Stage change.</p>
          </div>
          <Link
            className="button secondary"
            href="/projects/DEMO-021?dialog=bump"
          >
            <BumpIcon size={18} />
            Add Bump
          </Link>
        </div>
        <div className="strip-list">
          {[...demoProjects].reverse().map((p) => (
            <ProjectStrip key={p.code} project={p} />
          ))}
        </div>
      </section>
    </>
  );
}
