import Link from "next/link";
import { BallIcon } from "./icons";
import type { ProjectRow } from "@/lib/demo";
export function ProjectStrip({ project }: { project: ProjectRow }) {
  return (
    <Link
      className={`strip group-${project.group.toLowerCase().replaceAll(" ", "-")}`}
      href={`/projects/${encodeURIComponent(project.code)}`}
    >
      <div className="strip-code">{project.code}</div>
      <div className="strip-title">
        <strong>{project.name}</strong>
        <span>
          {project.state} · {project.priority}
        </span>
      </div>
      <div className="strip-stage">
        <span>Stage</span>
        <strong>{project.stage || "Not started"}</strong>
      </div>
      <div className="strip-owner">
        <BallIcon size={21} />
        <span>
          <small>Ball with</small>
          <strong>{project.owner}</strong>
        </span>
      </div>
      <time className="strip-time">{project.held}</time>
    </Link>
  );
}
