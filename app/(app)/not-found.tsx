import Link from "next/link";
export default function NotFound() {
  return (
    <div className="empty">
      <h1>Project not found</h1>
      <p>
        Check the immutable Project Code or include archived Projects in your
        search.
      </p>
      <Link className="button" href="/projects">
        Back to Projects
      </Link>
    </div>
  );
}
