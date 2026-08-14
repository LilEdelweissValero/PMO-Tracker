import "./globals.css";
import type { Metadata } from "next";
import { Azeret_Mono, Bricolage_Grotesque, Manrope } from "next/font/google";

const display = Bricolage_Grotesque({
  subsets: ["latin"],
  variable: "--font-display",
  display: "swap",
});

const body = Manrope({
  subsets: ["latin"],
  variable: "--font-body",
  display: "swap",
});

const mono = Azeret_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  display: "swap",
});

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
    <html
      lang="en"
      className={`${display.variable} ${body.variable} ${mono.variable}`}
    >
      <body>
        {/* THESIS: PMO work becomes a kinetic project studio, refusing generic enterprise dashboards and childish pastel toyboxes. OWN-WORLD: electric violet atmosphere, cream instrument decks, plum data stages, friendly display type, tactile controls, and original 3D project objects. STORY: officers see who holds responsibility, what has waited longest, and where to act next. FIRST VIEWPORT: a typographic greeting, longest-waiting relay, regular KRA instruments, live Ball dock, Progress, and Bumps share one operational workbench. FORM: The Kinetic Project Studio, grounded direction six, Studio Instrument Wall staging, seed 63f13089. */}
        {children}
      </body>
    </html>
  );
}
