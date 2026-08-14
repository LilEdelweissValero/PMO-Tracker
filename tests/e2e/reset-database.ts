import { execFileSync } from "node:child_process";

export default function resetLocalDatabase() {
  execFileSync("supabase", ["db", "reset"], {
    stdio: ["ignore", "ignore", "inherit"],
    timeout: 180_000,
  });
}
