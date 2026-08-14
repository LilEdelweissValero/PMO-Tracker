import { describe, expect, it } from "vitest";
import type { PostgrestError } from "@supabase/supabase-js";
import { listResult, mapPostgrestError, singleResult } from "@/lib/data/result";

function error(code: string): PostgrestError {
  return {
    code,
    message: `Postgres ${code}`,
    details: "",
    hint: "",
  } as unknown as PostgrestError;
}

describe("data result mapping", () => {
  it("keeps empty lists distinct from missing records", () => {
    expect(listResult([], null)).toEqual({ status: "empty" });
    expect(singleResult(null, null)).toEqual({ status: "not_found" });
  });

  it("maps authorization and connectivity failures explicitly", () => {
    expect(mapPostgrestError(error("42501")).status).toBe("permission_denied");
    expect(mapPostgrestError(error("08006"))).toMatchObject({
      status: "unavailable",
      issue: { retryable: true },
    });
  });

  it("preserves an actionable code for other database failures", () => {
    expect(mapPostgrestError(error("23505"))).toMatchObject({
      status: "failure",
      issue: { code: "23505", retryable: false },
    });
  });
});
