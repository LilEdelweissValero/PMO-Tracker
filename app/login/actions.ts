"use server";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { isDemo } from "@/lib/demo";
export async function login(formData: FormData) {
  if (isDemo) redirect("/dashboard");
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({
    email: String(formData.get("email")),
    password: String(formData.get("password")),
  });
  if (error)
    redirect(
      `/login?error=${encodeURIComponent("Email or password was not accepted.")}`,
    );
  redirect("/dashboard");
}
