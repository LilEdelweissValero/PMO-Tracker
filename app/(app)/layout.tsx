import { Sidebar } from "@/components/sidebar";
import { demoRequired, isDemoPreview } from "@/lib/demo";
import { requireSession } from "@/lib/auth";
export const dynamic = "force-dynamic";
export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [activeSession, demoPreview] = await Promise.all([
    requireSession(),
    isDemoPreview(),
  ]);
  return (
    <div className="app-shell">
      <Sidebar
        session={activeSession}
        demoPreview={demoPreview}
        demoRequired={demoRequired}
      />
      <main className="main">
        {demoPreview && (
          <div className="notice">
            <strong>Demo preview</strong> Connect Supabase to use authenticated
            live data. All sample records are clearly labeled.
          </div>
        )}
        {children}
      </main>
    </div>
  );
}
