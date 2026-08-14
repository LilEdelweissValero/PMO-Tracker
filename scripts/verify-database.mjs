import { spawnSync } from "node:child_process";

const executable = process.platform === "win32" ? "supabase.cmd" : "supabase";
const steps = [
  { arguments: ["start"], hideOutput: true },
  { arguments: ["db", "reset"] },
  { arguments: ["db", "lint", "--local", "--fail-on", "error"] },
  { arguments: ["test", "db"] },
];

for (const step of steps) {
  const result = spawnSync(executable, step.arguments, {
    stdio: step.hideOutput ? ["inherit", "ignore", "inherit"] : "inherit",
  });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  if (result.status !== 0) process.exit(result.status ?? 1);
}
