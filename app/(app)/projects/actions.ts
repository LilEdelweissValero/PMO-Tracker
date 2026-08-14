"use server";
import {
  appendProjectEventInputSchema,
  closeProjectInputSchema,
  projectSchema,
} from "@/lib/validation";
import {
  appendProjectEvent,
  closeProject,
  createProject,
} from "@/lib/actions/project-commands";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { isDemoPreview } from "@/lib/demo";
import type { Json } from "@/lib/database.types";
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

async function appendEventFromForm(
  data: FormData,
  event:
    | { eventType: "progress"; stageId: string; payload: { summary: string } }
    | { eventType: "bump"; payload: { text: string } }
    | {
        eventType: "state_changed";
        resultingState: string;
        payload: { reason?: string };
      }
    | {
        eventType: "ball_transferred";
        resultingBallOwnerId: string;
        payload: Record<string, never>;
      },
) {
  const code = String(data.get("code") ?? "");
  if (await isDemoPreview()) redirect(`/projects/${encodeURIComponent(code)}`);
  const candidate = {
    projectId: String(data.get("projectId") ?? ""),
    version: data.get("version"),
    effectiveAt: new Date().toISOString(),
    resultingBallOwnerId: String(data.get("ballOwnerId") ?? ""),
    ...event,
  };
  const parsed = appendProjectEventInputSchema.safeParse(candidate);
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message);
  const result = await appendProjectEvent(parsed.data as unknown as Json);
  if (result.status !== "success") {
    throw new Error(
      "issue" in result ? result.issue.message : "Project update failed.",
    );
  }
  revalidatePath(`/projects/${encodeURIComponent(code)}`);
  revalidatePath("/dashboard");
  revalidatePath("/ball");
  redirect(`/projects/${encodeURIComponent(code)}`);
}

export async function closeProjectAction(data: FormData) {
  const code = String(data.get("code") ?? "");
  if (await isDemoPreview()) redirect(`/projects/${encodeURIComponent(code)}`);
  const candidate = {
    projectId: String(data.get("projectId") ?? ""),
    version: data.get("version"),
    effectiveAt: new Date().toISOString(),
    closeout: {
      dodMet: data.get("dodMet") === "on",
      dodExplanation: String(data.get("dodExplanation") ?? ""),
      methodologyCompliant: data.get("methodologyCompliant") === "on",
      methodologyExplanation: String(data.get("methodologyExplanation") ?? ""),
      documentationComplete: data.get("documentationComplete") === "on",
      documentationExplanation: String(
        data.get("documentationExplanation") ?? "",
      ),
      stakeholderRating: data.get("stakeholderRating"),
      stakeholderComment: String(data.get("stakeholderComment") ?? "") || null,
    },
  };
  const parsed = closeProjectInputSchema.safeParse(candidate);
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message);
  const result = await closeProject(parsed.data as unknown as Json);
  if (result.status !== "success") {
    throw new Error(
      "issue" in result ? result.issue.message : "Project closeout failed.",
    );
  }
  revalidatePath(`/projects/${encodeURIComponent(code)}`);
  revalidatePath("/projects");
  revalidatePath("/dashboard");
  redirect(`/projects/${encodeURIComponent(code)}`);
}

export async function addProgressAction(data: FormData) {
  return appendEventFromForm(data, {
    eventType: "progress",
    stageId: String(data.get("stageId") ?? ""),
    payload: { summary: String(data.get("summary") ?? "") },
  });
}

export async function addBumpAction(data: FormData) {
  return appendEventFromForm(data, {
    eventType: "bump",
    payload: { text: String(data.get("text") ?? "") },
  });
}

export async function changeStateAction(data: FormData) {
  return appendEventFromForm(data, {
    eventType: "state_changed",
    resultingState: String(data.get("resultingState") ?? ""),
    payload: { reason: String(data.get("reason") ?? "") || undefined },
  });
}

export async function transferBallAction(data: FormData) {
  return appendEventFromForm(data, {
    eventType: "ball_transferred",
    resultingBallOwnerId: String(data.get("newBallOwnerId") ?? ""),
    payload: {},
  });
}
