"use server";
import { projectSchema } from "@/lib/validation";
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { isDemo } from "@/lib/demo";
export async function createProjectAction(data: FormData) {
  const parsed = projectSchema.safeParse(Object.fromEntries(data));
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message);
  if (isDemo) redirect(`/projects/${encodeURIComponent(parsed.data.code)}`);
  const supabase = await createClient();
  const { error } = await supabase.rpc("create_project", {
    input: {
      code: parsed.data.code,
      name: parsed.data.name,
      priorityId: parsed.data.priorityId,
      state: parsed.data.state,
      pmoOfficerId: parsed.data.pmoOfficerId,
      ballOwnerId: parsed.data.ballOwnerId,
      scope: parsed.data.scope,
    },
  });
  if (error) throw new Error(error.message);
  revalidatePath("/projects");
  redirect(`/projects/${encodeURIComponent(parsed.data.code)}`);
}
