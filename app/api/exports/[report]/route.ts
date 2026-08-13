import { csv } from "@/lib/csv";
import { demoProjects } from "@/lib/demo";
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ report: string }> },
) {
  const { report } = await params;
  let rows: Record<string, unknown>[];
  if (report === "turnaround")
    rows = [
      {
        "Project Code": "DEMO-008",
        Person: "Luis Cruz",
        Group: "Developer",
        "Net Duration": "3d 2h",
        "Hold Duration": "1d 4h",
        Timezone: "Asia/Manila",
      },
    ];
  else
    rows = demoProjects.map((p) => ({
      "Project Code": p.code,
      "Project Name": p.name,
      State: p.state,
      Stage: p.stage,
      Priority: p.priority,
      "PMO Officer": p.pmo,
      "Ball Owner": p.owner,
      "Ball Owner Group": p.group,
      "Held (hold excluded)": p.held,
      Timezone: "Asia/Manila",
    }));
  return new Response(csv(rows), {
    headers: {
      "content-type": "text/csv; charset=utf-8",
      "content-disposition": `attachment; filename="pmo-${report}.csv"`,
      "cache-control": "private, no-store",
    },
  });
}
