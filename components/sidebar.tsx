import Link from "next/link";
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
  return (
    <aside className="sidebar">
      <Link href="/dashboard" className="brand">
        <span className="brand-mark">
          <SparkIcon />
        </span>
        <span>
          PMO
          <br />
          <b>Tracker</b>
        </span>
      </Link>
      <nav aria-label="Primary">
        {nav.map(([href, label, Icon]) => (
          <Link key={href} href={href}>
            <Icon size={20} />
            <span>{label}</span>
          </Link>
        ))}
      </nav>
      <div className="sidebar-foot">
        <span className="avatar">AR</span>
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
