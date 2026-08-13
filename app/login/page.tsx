import { login } from "./actions";
import { SparkIcon } from "@/components/icons";
export default async function Login({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  return (
    <main
      style={{
        minHeight: "100vh",
        display: "grid",
        placeItems: "center",
        padding: 20,
        background: "#262130",
      }}
    >
      <form
        action={login}
        style={{
          width: "min(420px,100%)",
          background: "white",
          padding: 30,
          borderRadius: 16,
        }}
      >
        <div
          className="brand"
          style={{ color: "#201c2b", padding: 0, marginBottom: 25 }}
        >
          <span className="brand-mark">
            <SparkIcon />
          </span>
          <span>
            PMO <b>Tracker</b>
          </span>
        </div>
        <h1 style={{ marginBottom: 5 }}>Welcome back</h1>
        <p style={{ color: "var(--muted)", marginTop: 0 }}>
          Sign in with your provisioned work account.
        </p>
        {error && (
          <div className="notice" role="alert">
            {error}
          </div>
        )}
        <div className="field" style={{ marginTop: 20 }}>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
          />
        </div>
        <div className="field" style={{ marginTop: 14 }}>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
          />
        </div>
        <button style={{ width: "100%", marginTop: 22 }}>Sign in</button>
        <small
          style={{ display: "block", marginTop: 14, color: "var(--muted)" }}
        >
          No public registration. Contact an Administrator for access.
        </small>
      </form>
    </main>
  );
}
