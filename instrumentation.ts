import { readServerEnvironment } from "@/lib/env";

export function register() {
  readServerEnvironment();
}
