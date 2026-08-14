import { csv } from "@/lib/csv";
import { sessionState } from "@/lib/auth";
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ code: string }> },
) {
  const auth = await sessionState();
  if (auth.kind === "anonymous") {
    return Response.json({ error: "Authentication required" }, { status: 401 });
  }
  if (auth.kind === "inactive") {
    return Response.json({ error: "Active profile required" }, { status: 403 });
  }
  const { code } = await params;
  const rows = [
    {
      "Project Code": decodeURIComponent(code),
      Event: "Project created",
      "Effective (Asia/Manila)": "08 Aug 2026, 09:00 PHT",
      "Recorded (Asia/Manila)": "08 Aug 2026, 09:04 PHT",
      Actor: "Ana Reyes",
      Superseded: "No",
    },
  ];
  return new Response(csv(rows), {
    headers: {
      "content-type": "text/csv; charset=utf-8",
      "content-disposition": `attachment; filename="${encodeURIComponent(code)}-history.csv"`,
      "cache-control": "private, no-store",
    },
  });
}
