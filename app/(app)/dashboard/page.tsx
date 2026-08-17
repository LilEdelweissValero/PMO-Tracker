import Image from "next/image";
import Link from "next/link";
import {
  IconBuildingBank,
  IconGauge,
  IconShieldCheck,
} from "@tabler/icons-react";
import { ProjectStrip } from "@/components/project-strip";
import { demoProjects, isDemoPreview } from "@/lib/demo";
import { listDashboardQueue } from "@/lib/data/dashboard";
import { queueProjectRow } from "@/lib/presentation/project-row";

const kras = [
  {
    name: "Project Efficiency",
    icon: IconGauge,
    metrics: [
      ["Schedule Performance Index", "SPI = EV / PV · target ≥ 1.0"],
      ["Cost Performance Index", "CPI = EV / AC · target ≥ 1.0"],
      ["Project Success Rate", "Target ≥ 90%"],
    ],
  },
  {
    name: "Project Safety",
    icon: IconShieldCheck,
    metrics: [
      ["Change Control Stability", "Stable below 10%"],
      ["Health Recovery Rate", "Target ≥ 75%"],
    ],
  },
  {
    name: "Project Governance",
    icon: IconBuildingBank,
    metrics: [
      ["Methodology Compliance", "Target ≥ 95%"],
      ["Documentation Compliance", "Target 100%"],
      ["Stakeholder Approval", "Target ≥ 4.0 / 5.0"],
    ],
  },
] as const;

export default async function Dashboard() {
  const demoPreview = await isDemoPreview();
  const result = demoPreview ? null : await listDashboardQueue();
  if (result && !["success", "empty"].includes(result.status)) {
    throw new Error("Unable to load the portfolio dashboard.");
  }
  const projects = demoPreview
    ? demoProjects
    : result?.status === "success"
      ? result.data.flatMap((row) => {
          const project = queueProjectRow(row);
          return project ? [project] : [];
        })
      : [];
  const currentBall =
    projects.find((project) => project.group === "PMO") ?? projects[0];

  return (
    <div className="dashboard-board">
      <section
        className="kra-instruments"
        aria-labelledby="dashboard-kpi-title"
      >
        <header className="kpi-toolbar">
          <div>
            <span className="instrument-label">Portfolio measures</span>
            <h1 id="dashboard-kpi-title">KPI definitions</h1>
          </div>
          <div className="dashboard-period">
            <label htmlFor="kpi-period">KPI period</label>
            <select id="kpi-period" defaultValue="quarter">
              <option value="month">Current month</option>
              <option value="quarter">Current quarter</option>
              <option value="year">Current year</option>
              <option value="custom">Custom range</option>
            </select>
          </div>
        </header>
        {kras.map((kra) => {
          const Icon = kra.icon;
          return (
            <article className="kra-instrument" key={kra.name}>
              <div className="kra-title">
                <span className="kra-icon">
                  <Icon size={21} />
                </span>
                <h2>{kra.name}</h2>
              </div>
              <div className="kra-metrics">
                {kra.metrics.map(([name, definition]) => (
                  <div className="metric" key={name}>
                    <strong>{name}</strong>
                    <span>{definition}</span>
                  </div>
                ))}
              </div>
              <span className="status">Not yet calculated</span>
            </article>
          );
        })}
      </section>

      <section
        className="dashboard-progress technical-stage"
        aria-labelledby="progress-title"
      >
        <div className="instrument-heading">
          <div>
            <span className="instrument-label">
              Effective update · oldest first
            </span>
            <h2 id="progress-title">Latest Progress</h2>
          </div>
          {currentBall && (
            <Link
              className="button dashboard-action"
              href={`/projects/${encodeURIComponent(currentBall.code)}?dialog=progress`}
            >
              Add Progress
            </Link>
          )}
        </div>
        <div className="strip-list">
          {projects.map((project) => (
            <ProjectStrip key={project.code} project={project} />
          ))}
          {!projects.length && (
            <div className="notice">No active Project progress to show.</div>
          )}
        </div>
      </section>

      <section
        className="dashboard-bumps technical-stage"
        aria-labelledby="bumps-title"
      >
        <div className="instrument-heading">
          <div>
            <span className="instrument-label">
              Conversation · no Stage change
            </span>
            <h2 id="bumps-title">Latest Bumps</h2>
          </div>
          {currentBall && (
            <Link
              className="bump-button dashboard-action"
              href={`/projects/${encodeURIComponent(currentBall.code)}?dialog=bump`}
            >
              <span>Bump</span>
              <Image src="/assets/fist.png" alt="" width={58} height={58} />
            </Link>
          )}
        </div>
        <div className="bump-feed">
          {[...projects].reverse().map((project) => (
            <Link
              href={`/projects/${project.code}`}
              className="bump-entry"
              key={project.code}
            >
              <span
                className={`bump-dot group-${project.group.toLowerCase().replaceAll(" ", "-")}`}
              />
              <span>
                <small>
                  {project.code} · {project.owner}
                </small>
                <strong>{project.latestBump ?? "No update yet"}</strong>
              </span>
              <time>{project.held}</time>
            </Link>
          ))}
          {!projects.length && (
            <div className="notice">No Project conversations to show.</div>
          )}
        </div>
      </section>
    </div>
  );
}
