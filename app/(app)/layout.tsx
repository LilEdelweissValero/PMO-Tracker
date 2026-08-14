import { Sidebar } from "@/components/sidebar";
import { isDemo } from "@/lib/demo";
import { requireSession } from "@/lib/auth";
export const dynamic = "force-dynamic";
export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const activeSession = await requireSession();
  return (
    <div className="app-shell">
      <Sidebar session={activeSession} />
      <main className="main">
        {isDemo && (
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
