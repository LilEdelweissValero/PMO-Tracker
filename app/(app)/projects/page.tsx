import Link from "next/link";
import { PageHeader } from "@/components/page-header";
import { ProjectStrip } from "@/components/project-strip";
import { demoProjects } from "@/lib/demo";
export default function Projects() {
  return (
    <>
      <PageHeader
        title="Projects"
        description="Search the complete portfolio. Archived terminal Projects stay available through filters and reporting."
        actions={
          <>
            <Link className="button secondary" href="/api/exports/projects">
              Export CSV
            </Link>
            <Link className="button pink" href="/projects/new">
              New Project
            </Link>
          </>
        }
      />
      <form className="filterbar">
        <input
          name="q"
          aria-label="Search Projects"
          placeholder="Search code, name, scope, person…"
        />
        <select aria-label="State">
          <option>All States</option>
          <option>Pipeline</option>
          <option>Planned</option>
          <option>Active</option>
          <option>On Hold</option>
          <option>Closed</option>
          <option>Cancelled</option>
        </select>
        <select aria-label="Priority">
          <option>All Priorities</option>
          <option>Critical</option>
          <option>High</option>
          <option>Medium</option>
          <option>Low</option>
        </select>
        <button className="secondary">Apply</button>
      </form>
      <div className="strip-list">
        {demoProjects.map((p) => (
          <ProjectStrip key={p.code} project={p} />
        ))}
      </div>
      <p style={{ color: "var(--muted)" }}>
        Showing 3 demo Projects · Page 1 of 1
      </p>
    </>
  );
}
