"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { setDemoPreview } from "@/app/demo-preview/actions";

export function DemoPreviewToggle({
  enabled,
  required,
}: {
  enabled: boolean;
  required: boolean;
}) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const query = searchParams.toString();
  const returnTo = `${pathname}${query ? `?${query}` : ""}`;

  return (
    <form action={setDemoPreview} className="demo-toggle">
      <input type="hidden" name="enabled" value={enabled ? "false" : "true"} />
      <input type="hidden" name="returnTo" value={returnTo} />
      <span>
        <strong>Demo preview</strong>
        <small>
          {required ? "Supabase not configured" : "Use sample data"}
        </small>
      </span>
      <button
        type="submit"
        role="switch"
        aria-checked={enabled}
        aria-label="Toggle demo preview"
        disabled={required}
        className={enabled ? "on" : undefined}
      >
        <span />
      </button>
    </form>
  );
}
