import { describe, expect, it } from "vitest";
import { safeReturnPath } from "@/lib/auth-paths";

describe("safe authentication return paths", () => {
  it("keeps local paths with query strings", () => {
    expect(safeReturnPath("/projects/PMO-1?dialog=progress")).toBe(
      "/projects/PMO-1?dialog=progress",
    );
  });

  it("rejects absolute, protocol-relative, and malformed destinations", () => {
    expect(safeReturnPath("https://attacker.invalid/path")).toBe("/dashboard");
    expect(safeReturnPath("//attacker.invalid/path")).toBe("/dashboard");
    expect(safeReturnPath("not-a-path")).toBe("/dashboard");
    expect(safeReturnPath(null)).toBe("/dashboard");
  });
});
