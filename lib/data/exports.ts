import "server-only";

import type { DataClient } from "./client";
import { listProjectHistory } from "./events";
import { listProjects, type ProjectListFilters } from "./projects";
import { listProjectsAsOf, listTurnaround } from "./reports";

export function projectHistoryExportRows(
  projectId: string,
  client?: DataClient,
) {
  return listProjectHistory(projectId, client);
}

export function projectExportRows(
  filters: ProjectListFilters = {},
  client?: DataClient,
) {
  return listProjects({ ...filters, page: 1, pageSize: 100 }, client);
}

export function asOfExportRows(
  asOfTime: string,
  projectId?: string,
  client?: DataClient,
) {
  return listProjectsAsOf(asOfTime, projectId, client);
}

export function turnaroundExportRows(projectId?: string, client?: DataClient) {
  return listTurnaround(projectId, client);
}
