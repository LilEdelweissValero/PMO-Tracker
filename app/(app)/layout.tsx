import { Sidebar } from "@/components/sidebar";
import { isDemo } from "@/lib/demo";
export const dynamic = "force-dynamic";
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="app-shell">
      <Sidebar />
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
