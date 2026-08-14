import { PageHeader } from "@/components/page-header";
import { ProjectStrip } from "@/components/project-strip";
import { demoProjects } from "@/lib/demo";
import { BallIcon } from "@/components/icons";
import Image from "next/image";
const bays = ["PMO", "Developer", "System Owner"] as const;
export default function Ball() {
  return (
    <>
      <PageHeader
        title="Ball View"
        description="Every non-terminal Project sits with one individual in exactly one bay. Held time excludes On Hold periods."
        actions={
          <div className="ball-view-header-art" aria-hidden="true">
            <span />
            <Image
              src="/assets/ball-3d.png"
              alt=""
              width={150}
              height={150}
              priority
            />
          </div>
        }
      />
      <form className="filterbar">
        <select aria-label="System">
          <option>All Systems</option>
        </select>
        <select aria-label="Module">
          <option>All Modules</option>
        </select>
        <select aria-label="PMO Officer">
          <option>All PMO Officers</option>
        </select>
        <select aria-label="Project State">
          <option>All States</option>
        </select>
        <select aria-label="Priority">
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
            {demoProjects
              .filter((p) => p.group === b)
              .map((p) => (
                <div key={p.code}>
                  <strong className="bay-label">{p.owner}</strong>
                  <ProjectStrip project={p} />
                </div>
              ))}
          </section>
        ))}
      </div>
    </>
  );
}
