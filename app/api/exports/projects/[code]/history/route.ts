import { csv } from "@/lib/csv";
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ code: string }> },
) {
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
