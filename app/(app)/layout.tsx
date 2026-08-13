import { Sidebar } from "@/components/sidebar";
export const dynamic = "force-dynamic";
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        {!process.env.NEXT_PUBLIC_SUPABASE_URL && (
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
