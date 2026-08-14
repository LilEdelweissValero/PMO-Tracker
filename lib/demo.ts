import { cookies } from "next/headers";
import { cache } from "react";
import { DEMO_PREVIEW_COOKIE } from "./demo-constants";
import { getPublicEnvironment } from "./env";

export type ProjectRow = {
  code: string;
  name: string;
  state: string;
  priority: string;
  stage: string;
  owner: string;
  group: "PMO" | "Developer" | "System Owner";
  held: string;
  pmo: string;
  latestProgress?: string;
  latestBump?: string;
};
export const demoProjects: ProjectRow[] = [
  {
    code: "DEMO-014",
    name: "Permit workflow refresh",
    state: "Active",
    priority: "Critical",
    stage: "UAT Start",
    owner: "Mika Santos",
    group: "System Owner",
    held: "1d 6h",
    pmo: "Ana Reyes",
    latestProgress: "UAT environment handed over",
    latestBump: "Review session set for Friday",
  },
  {
    code: "DEMO-008",
    name: "Service desk routing",
    state: "On Hold",
    priority: "High",
    stage: "Dev End",
    owner: "Luis Cruz",
    group: "Developer",
    held: "3d 2h",
    pmo: "Ana Reyes",
    latestProgress: "Integration tests completed",
    latestBump: "Waiting on vendor credentials",
  },
  {
    code: "DEMO-021",
    name: "Records search upgrade",
    state: "Planned",
    priority: "Medium",
    stage: "Engagement Meeting",
    owner: "Ana Reyes",
    group: "PMO",
    held: "0d 8h",
    pmo: "Ana Reyes",
  },
];

export { DEMO_PREVIEW_COOKIE } from "./demo-constants";
export const demoRequired = getPublicEnvironment().demoMode;
export const isDemoPreview = cache(async () => {
  if (demoRequired) return true;
  const store = await cookies();
  return store.get(DEMO_PREVIEW_COOKIE)?.value === "1";
});
