import Image from "next/image";
import Link from "next/link";
import {
  IconArrowUpRight,
  IconBuildingBank,
  IconClock,
  IconGauge,
  IconShieldCheck,
} from "@tabler/icons-react";
import { ProjectStrip } from "@/components/project-strip";
import { demoProjects } from "@/lib/demo";

const kras = [
  {
    name: "Project Efficiency",
    icon: IconGauge,
    tone: "violet",
    metrics: [
      ["Schedule Performance Index", "SPI = EV / PV · target ≥ 1.0"],
      ["Cost Performance Index", "CPI = EV / AC · target ≥ 1.0"],
      ["Project Success Rate", "Target ≥ 90%"],
    ],
  },
  {
    name: "Project Safety",
    icon: IconShieldCheck,
    tone: "mint",
    metrics: [
      ["Change Control Stability", "Stable below 10%"],
      ["Health Recovery Rate", "Target ≥ 75%"],
    ],
  },
  {
    name: "Project Governance",
    icon: IconBuildingBank,
    tone: "yellow",
    metrics: [
      ["Methodology Compliance", "Target ≥ 95%"],
      ["Documentation Compliance", "Target 100%"],
      ["Stakeholder Approval", "Target ≥ 4.0 / 5.0"],
    ],
  },
] as const;

export default function Dashboard() {
  const currentBall =
    demoProjects.find((project) => project.group === "PMO") ?? demoProjects[0];

  return (
    <div className="dashboard-board">
      <header className="dashboard-intro">
        <div>
          <span className="dashboard-kicker">
            Portfolio control · Philippine time
          </span>
          <h1>
            Good morning,
            <br />
            PMO.
          </h1>
          <p>
            Start with the work that has waited longest, then keep the Ball
            moving.
          </p>
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

      <section className="waiting-deck" aria-labelledby="waiting-title">
        <div className="instrument-heading">
          <div>
            <span className="instrument-label">Attention queue</span>
            <h2 id="waiting-title">Longest waiting</h2>
          </div>
          <Link href="/ball" className="text-link">
            View every handoff <IconArrowUpRight size={17} />
          </Link>
        </div>
        <div className="waiting-list">
          {demoProjects.map((project) => (
            <Link
              href={`/projects/${project.code}`}
              className="waiting-item"
              key={project.code}
            >
              <span
                className={`waiting-signal group-${project.group.toLowerCase().replaceAll(" ", "-")}`}
              />
              <span>
                <small>{project.code}</small>
                <strong>{project.name}</strong>
                <span>
                  {project.owner} · {project.group}
                </span>
              </span>
              <time>
                <IconClock size={14} />
                {project.held}
              </time>
            </Link>
          ))}
        </div>
      </section>

      <section className="kra-instruments" aria-label="KRA and KPI definitions">
        {kras.map((kra) => {
          const Icon = kra.icon;
          return (
            <article
              className={`kra-instrument tone-${kra.tone}`}
              key={kra.name}
            >
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
          <Link
            className="button pink"
            href="/projects/DEMO-021?dialog=progress"
          >
            Add Progress
          </Link>
        </div>
        <div className="strip-list">
          {demoProjects.map((project) => (
            <ProjectStrip key={project.code} project={project} />
          ))}
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
          <Link className="bump-button" href="/projects/DEMO-021?dialog=bump">
            <span>Bump</span>
            <Image
              src="/assets/fist.png"
              alt=""
              width={58}
              height={58}
            />
          </Link>
        </div>
        <div className="bump-feed">
          {[...demoProjects].reverse().map((project) => (
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
        </div>
      </section>

      <aside className="ball-dock" aria-labelledby="ball-title">
        <div className="ball-dock-copy">
          <span className="instrument-label">Currently in play</span>
          <h2 id="ball-title">The Ball</h2>
          <p>One owner. No ambiguity.</p>
        </div>
        <div className="ball-artwork">
          <span className="ball-orbit" aria-hidden="true" />
          <Image
            src="/assets/ball.png"
            alt="A polished 3D basketball representing current Project responsibility"
            width={360}
            height={360}
            priority
          />
        </div>
        <div className="ball-owner">
          <small>Ball with · {currentBall.group}</small>
          <strong>{currentBall.owner}</strong>
          <time>
            <IconClock size={17} />
            Held {currentBall.held}
          </time>
        </div>
        <Link className="button ball-action" href="/ball">
          View Ball relay <IconArrowUpRight size={18} />
        </Link>
        <div className="relay-note">
          <span aria-hidden="true">✦</span>
          <p>
            Small handoffs.
            <br />
            <strong>Clear momentum.</strong>
          </p>
        </div>
      </aside>
    </div>
  );
}
