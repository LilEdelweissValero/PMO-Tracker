import { PageHeader } from "@/components/page-header";
import { ProjectStrip } from "@/components/project-strip";
import { demoProjects, isDemoPreview } from "@/lib/demo";
import { listBallQueue } from "@/lib/data/ball";
import { queueProjectRow } from "@/lib/presentation/project-row";
import { BallIcon } from "@/components/icons";
import Image from "next/image";
const bays = ["PMO", "Developer", "System Owner"] as const;
export default async function Ball() {
  const demoPreview = await isDemoPreview();
  const result = demoPreview ? null : await listBallQueue();
  if (result && !["success", "empty"].includes(result.status)) {
    throw new Error("Unable to load the Ball queue.");
  }
  const projects = demoPreview
    ? demoProjects
    : result?.status === "success"
      ? result.data.flatMap((row) => {
          const project = queueProjectRow(row);
          return project ? [project] : [];
        })
      : [];
  return (
    <>
      <PageHeader
        title="Ball View"
        description="Every non-terminal Project sits with one individual in exactly one bay. Held time excludes On Hold periods."
        actions={
          <div className="ball-view-header-art" aria-hidden="true">
            <span />
            <Image
              src="/assets/ball.png"
              alt=""
              width={150}
              height={150}
              priority
            />
          </div>
        }
      />
      <form className="filterbar">
        <select aria-label="System" disabled>
          <option>All Systems · scope setup pending</option>
        </select>
        <select aria-label="Module" disabled>
          <option>All Modules · scope setup pending</option>
        </select>
        <select aria-label="PMO Officer" disabled>
          <option>All PMO Officers</option>
        </select>
        <select aria-label="Project State" disabled>
          <option>All States</option>
        </select>
        <select aria-label="Priority" disabled>
          <option>All Priorities</option>
        </select>
      </form>
      <div className="bay-grid">
        {bays.map((b) => (
          <section
            key={b}
            className={`bay ${b.toLowerCase().replaceAll(" ", "-")}`}
          >
            <h2>
              <BallIcon />
              {b}
              {b === "Developer" ? "s" : ""}
            </h2>
            {projects
              .filter((p) => p.group === b)
              .map((p) => (
                <div key={p.code}>
                  <strong className="bay-label">{p.owner}</strong>
                  <ProjectStrip project={p} />
                </div>
              ))}
            {!projects.some((project) => project.group === b) && (
              <div className="notice">No Projects in this bay.</div>
            )}
          </section>
        ))}
      </div>
    </>
  );
}
