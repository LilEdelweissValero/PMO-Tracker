import type { PostgrestError } from "@supabase/supabase-js";

export type DataIssue = {
  code: string;
  message: string;
  retryable: boolean;
};

export type DataResult<T> =
  | { status: "success"; data: T }
  | { status: "empty" }
  | { status: "not_found" }
  | { status: "permission_denied"; issue: DataIssue }
  | { status: "unavailable"; issue: DataIssue }
  | { status: "failure"; issue: DataIssue };

const permissionCodes = new Set(["42501", "PGRST301"]);
const unavailableCodes = new Set([
  "08000",
  "08001",
  "08003",
  "08004",
  "08006",
  "08007",
  "08P01",
  "53300",
  "57P01",
  "57P02",
  "57P03",
]);

export function mapPostgrestError(error: PostgrestError): DataResult<never> {
  const issue = {
    code: error.code,
    message: error.message,
    retryable: unavailableCodes.has(error.code),
  };
  if (permissionCodes.has(error.code)) {
    return { status: "permission_denied", issue };
  }
  if (error.code === "PGRST116") return { status: "not_found" };
  if (issue.retryable) return { status: "unavailable", issue };
  return { status: "failure", issue };
}

export function listResult<T>(
  data: T[] | null,
  error: PostgrestError | null,
): DataResult<T[]> {
  if (error) return mapPostgrestError(error);
  if (!data?.length) return { status: "empty" };
  return { status: "success", data };
}

export function singleResult<T>(
  data: T | null,
  error: PostgrestError | null,
): DataResult<T> {
  if (error) return mapPostgrestError(error);
  if (!data) return { status: "not_found" };
  return { status: "success", data };
}
