"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { safeReturnPath } from "@/lib/auth-paths";
import { DEMO_PREVIEW_COOKIE, demoRequired } from "@/lib/demo";

export async function setDemoPreview(formData: FormData) {
  const enabled = demoRequired || formData.get("enabled") === "true";
  const store = await cookies();
  store.set(DEMO_PREVIEW_COOKIE, enabled ? "1" : "0", {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 30,
  });
  redirect(safeReturnPath(formData.get("returnTo")));
}
