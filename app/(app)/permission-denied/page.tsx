import Link from "next/link";
export default function Denied() {
  return (
    <div className="empty">
      <h1>Read only from here</h1>
      <p>
        Your current roles do not permit this change. The portfolio remains
        available to inspect.
      </p>
      <Link className="button" href="/dashboard">
        Return to Dashboard
      </Link>
    </div>
  );
}
