import Link from "next/link";
import { PageHeader } from "@/components/page-header";
import { ProjectStrip } from "@/components/project-strip";
import { demoProjects, isDemoPreview } from "@/lib/demo";
import { listPriorities } from "@/lib/data/configuration";
import { listProjects } from "@/lib/data/projects";
import { listedProjectRow } from "@/lib/presentation/project-row";
import type { Enums } from "@/lib/database.types";

const states: Enums<"project_state">[] = [
  "Pipeline",
  "Planned",
  "Active",
  "On Hold",
  "Closed",
  "Cancelled",
];

type SearchParams = Promise<Record<string, string | string[] | undefined>>;

function one(value: string | string[] | undefined) {
  return typeof value === "string" ? value : undefined;
}

export default async function Projects({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, demoPreview] = await Promise.all([
    searchParams,
    isDemoPreview(),
  ]);
  const query = one(params.q) ?? "";
  const requestedState = one(params.state);
  const state = states.find((item) => item === requestedState);
  const priorityId = one(params.priority);
  const page = Math.max(1, Number.parseInt(one(params.page) ?? "1", 10) || 1);
  const [projectResult, priorityResult] = demoPreview
    ? [null, null]
    : await Promise.all([
        listProjects({ query, state, priorityId, page }),
        listPriorities(),
      ]);
  if (
    (projectResult && !["success", "empty"].includes(projectResult.status)) ||
    (priorityResult && !["success", "empty"].includes(priorityResult.status))
  ) {
    throw new Error("Unable to load the Project portfolio.");
  }
  const projects = demoPreview
    ? demoProjects
    : projectResult?.status === "success"
      ? projectResult.data.items.flatMap((item) => {
          const project = listedProjectRow(item);
          return project ? [project] : [];
        })
      : [];
  const priorities =
    priorityResult?.status === "success" ? priorityResult.data : [];
  const total =
    projectResult?.status === "success"
      ? projectResult.data.total
      : demoPreview
        ? demoProjects.length
        : 0;
  const pageSize =
    projectResult?.status === "success" ? projectResult.data.pageSize : 25;
  const pages = Math.max(1, Math.ceil(total / pageSize));
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
          defaultValue={query}
        />
        <select aria-label="State" name="state" defaultValue={state ?? ""}>
          <option value="">All States</option>
          {states.map((item) => (
            <option value={item} key={item}>
              {item}
            </option>
          ))}
        </select>
        <select
          aria-label="Priority"
          name="priority"
          defaultValue={priorityId ?? ""}
          disabled={demoPreview}
        >
          <option value="">All Priorities</option>
          {priorities.map((priority) => (
            <option value={priority.id} key={priority.id}>
              {priority.name}
            </option>
          ))}
        </select>
        <button className="secondary">Apply</button>
      </form>
      <div className="strip-list">
        {projects.map((p) => (
          <ProjectStrip key={p.code} project={p} />
        ))}
        {!projects.length && (
          <div className="notice">
            No Projects match the current filters. Create a Project or broaden
            the search.
          </div>
        )}
      </div>
      <p style={{ color: "var(--muted)" }}>
        Showing {projects.length} of {total} {demoPreview ? "demo " : ""}
        Projects · Page {Math.min(page, pages)} of {pages}
      </p>
    </>
  );
}
