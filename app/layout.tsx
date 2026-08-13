import "./globals.css";
import "./pixel-theme.css";
import type { Metadata } from "next";
export const metadata: Metadata = {
  title: { default: "PMO Tracker", template: "%s · PMO Tracker" },
  description: "Project governance, responsibility, and history.",
};
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {/* THESIS: A lively controller's ledger makes responsibility instantly scannable and refuses generic card dashboards. OWN-WORLD: cool paper, ink rules, CharmTone-like pink/purple/amber/teal, compact strips, crisp geometric icons. STORY: officers see stale work, find its Ball Owner, and act without losing history. FIRST VIEWPORT: compact sidebar beside title, filters, and operations strips; actions sit upper right. FORM: portfolio control ledger, assigned direction 6, seed 734ca309. FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md */}
        {children}
      </body>
    </html>
  );
}
