"use server";
import { projectSchema } from "@/lib/validation";
import { createProject } from "@/lib/actions/project-commands";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { isDemoPreview } from "@/lib/demo";
export async function createProjectAction(data: FormData) {
  const parsed = projectSchema.safeParse(Object.fromEntries(data));
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message);
  if (await isDemoPreview()) {
    redirect(`/projects/${encodeURIComponent(parsed.data.code)}`);
  }
  const result = await createProject({
    code: parsed.data.code,
    name: parsed.data.name,
    priorityId: parsed.data.priorityId,
    state: parsed.data.state,
    pmoOfficerId: parsed.data.pmoOfficerId,
    ballOwnerId: parsed.data.ballOwnerId,
    scope: parsed.data.scope,
    participants: [parsed.data.pmoOfficerId, parsed.data.ballOwnerId]
      .filter((personId, index, people) => people.indexOf(personId) === index)
      .map((personId) => ({ personId, group: "PMO" })),
    systemScopes: [],
    references: [],
  });
  if (result.status !== "success") {
    throw new Error(
      "issue" in result ? result.issue.message : "Project creation failed.",
    );
  }
  revalidatePath("/projects");
  redirect(`/projects/${encodeURIComponent(parsed.data.code)}`);
}
