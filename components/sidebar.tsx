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
const nav = [
  ["/dashboard", "Dashboard", IconLayoutDashboard],
  ["/projects", "Projects", IconFolders],
  ["/ball", "Ball View", BallIcon],
  ["/reports/as-of", "Reports", IconChartBar],
  ["/directory/people", "Directory", IconUsers],
  ["/admin/workflow", "Administration", IconSettings],
] as const;
export function Sidebar() {
  const pathname = usePathname();

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
          AR
        </span>
        <span>
          <b>Ana Reyes</b>
          <small>Administrator</small>
        </span>
        <Link href="/login" aria-label="Log out">
          <IconLogout size={18} />
        </Link>
      </div>
    </aside>
  );
}
