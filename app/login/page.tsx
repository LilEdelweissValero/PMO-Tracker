import { redirect } from "next/navigation";
import { login } from "./actions";
import { SparkIcon } from "@/components/icons";
import { safeReturnPath, sessionState } from "@/lib/auth";
export default async function Login({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; returnTo?: string }>;
}) {
  const { error, returnTo: requestedReturnPath } = await searchParams;
  const returnTo = safeReturnPath(requestedReturnPath ?? null);
  const state = await sessionState();
  if (state.kind === "active") redirect(returnTo);
  if (state.kind === "inactive") redirect("/permission-denied");
  return (
    <main className="login-page">
      <div className="login-atmosphere" aria-hidden="true">
        <span className="login-orb login-orb-one" />
        <span className="login-orb login-orb-two" />
      </div>
      <form action={login} className="login-card">
        <input type="hidden" name="returnTo" value={returnTo} />
        <div className="brand login-brand">
          <span className="brand-mark">
            <SparkIcon />
          </span>
          <span>
            <b>PMO Tracker</b>
            <small>Kinetic project studio</small>
          </span>
        </div>
        <span className="login-kicker">Portfolio control</span>
        <h1>Welcome back.</h1>
        <p className="login-lede">
          Sign in with your provisioned work account.
        </p>
        {error && (
          <div className="notice" role="alert">
            {error}
          </div>
        )}
        <div className="field">
          <label htmlFor="email">Email</label>
          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
          />
        </div>
        <div className="field">
          <label htmlFor="password">Password</label>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
          />
        </div>
        <button className="login-submit">Sign in</button>
        <small className="login-help">
          No public registration. Contact an Administrator for access.
        </small>
      </form>
    </main>
  );
}
