"use server";

import { redirect } from "next/navigation";
import { demoRequired, isDemoPreview } from "@/lib/demo";
import { safeReturnPath } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";

export async function login(formData: FormData) {
  const returnTo = safeReturnPath(formData.get("returnTo"));
  if (await isDemoPreview()) redirect(returnTo);

  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  if (!email || !password) {
    redirect(
      `/login?error=${encodeURIComponent("Enter your email and password.")}&returnTo=${encodeURIComponent(returnTo)}`,
    );
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    redirect(
      `/login?error=${encodeURIComponent("Email or password was not accepted.")}&returnTo=${encodeURIComponent(returnTo)}`,
    );
  }
  redirect(returnTo);
}

export async function logout() {
  if (!demoRequired) {
    const supabase = await createClient();
    await supabase.auth.signOut();
  }
  redirect("/login");
}
