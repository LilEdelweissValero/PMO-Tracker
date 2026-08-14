"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  IconLayoutDashboard,
  IconFolders,
  IconChartBar,
  IconUsers,
  IconSettings,
  IconLogout,
} from "@tabler/icons-react";
import { BallIcon, SparkIcon } from "./icons";
import type { ActiveSession } from "@/lib/auth";
import { logout } from "@/app/login/actions";
const nav = [
  ["/dashboard", "Dashboard", IconLayoutDashboard],
  ["/projects", "Projects", IconFolders],
  ["/ball", "Ball View", BallIcon],
  ["/reports/as-of", "Reports", IconChartBar],
  ["/directory/people", "Directory", IconUsers],
  ["/admin/workflow", "Administration", IconSettings],
] as const;
const roleLabels = {
  administrator: "Administrator",
  pmo_officer: "PMO Officer",
  leadership_viewer: "Leadership Viewer",
} as const;

export function Sidebar({ session }: { session: ActiveSession }) {
  const pathname = usePathname();
  const initials = session.personName
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase();

  return (
    <aside className="sidebar">
      <Link href="/dashboard" className="brand">
        <span className="brand-mark">
          <SparkIcon />
        </span>
        <span>
          <b>PMO Tracker</b>
          <small>Kinetic project studio</small>
        </span>
      </Link>
      <nav aria-label="Primary">
        {nav.map(([href, label, Icon]) => {
          const current =
            pathname === href ||
            (href !== "/dashboard" && pathname.startsWith(`${href}/`));

          return (
            <Link
              key={href}
              href={href}
              aria-current={current ? "page" : undefined}
            >
              <Icon size={20} />
              <span>{label}</span>
            </Link>
          );
        })}
      </nav>
      <div className="sidebar-foot">
        <span className="avatar" aria-hidden="true">
          {initials}
        </span>
        <span>
          <b>{session.personName}</b>
          <small>
            {session.roles.map((role) => roleLabels[role]).join(" · ")}
          </small>
        </span>
        <form action={logout}>
          <button type="submit" aria-label="Log out">
            <IconLogout size={18} />
          </button>
        </form>
      </div>
    </aside>
  );
}
