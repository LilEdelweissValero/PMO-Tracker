import Link from "next/link";
import { logout } from "@/app/login/actions";

export default function Denied() {
  return (
    <main className="login-page">
      <div className="empty">
        <h1>Access is not active</h1>
        <p>
          Your account is signed in, but it is not linked to an active PMO
          Tracker profile. Contact an Administrator to restore access.
        </p>
        <Link className="button" href="/login">
          Return to sign in
        </Link>
        <form action={logout}>
          <button className="button secondary" type="submit">
            Sign out
          </button>
        </form>
      </div>
    </main>
  );
}
