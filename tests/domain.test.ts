import { describe, it, expect } from "vitest";
import {
  assertTransition,
  netOwnershipMs,
  requireBallOwner,
  stageVariance,
} from "@/lib/domain";
describe("Project invariants", () => {
  it("makes terminal States irreversible", () => {
    expect(() => assertTransition("Closed", "Active")).toThrow(/irreversible/);
    expect(() => assertTransition("Cancelled", "Pipeline")).toThrow(
      /irreversible/,
    );
  });
  it("requires one owner for non-terminal work", () => {
    expect(() => requireBallOwner("Active", null)).toThrow(/exactly one/);
    expect(() => requireBallOwner("Closed", null)).not.toThrow();
  });
  it("calculates Philippine calendar variance", () => {
    expect(stageVariance("2026-08-13", "2026-08-12T16:00:00Z")).toEqual({
      days: 0,
      label: "On Time",
    });
    expect(stageVariance("2026-08-13", "2026-08-14T00:00:00Z")).toEqual({
      days: 1,
      label: "Delayed",
    });
  });
  it("excludes overlapping holds from ownership", () => {
    const period = {
      start: "2026-08-01T00:00:00Z",
      end: "2026-08-05T00:00:00Z",
    };
    const holds = [
      { start: "2026-08-02T00:00:00Z", end: "2026-08-03T12:00:00Z" },
    ];
    expect(netOwnershipMs(period, holds)).toBe(60 * 60 * 1000 * 60);
  });
  it("merges overlapping Holds before subtracting paused time", () => {
    const period = {
      start: "2026-08-01T00:00:00Z",
      end: "2026-08-05T00:00:00Z",
    };
    const holds = [
      { start: "2026-08-02T00:00:00Z", end: "2026-08-03T12:00:00Z" },
      { start: "2026-08-03T00:00:00Z", end: "2026-08-04T00:00:00Z" },
    ];
    expect(netOwnershipMs(period, holds)).toBe(48 * 60 * 60 * 1000);
  });
});
