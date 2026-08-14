"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { requireAnyRole } from "@/lib/auth";
import { dataClient } from "@/lib/data/client";
import { isDemoPreview } from "@/lib/demo";

const departmentSchema = z.object({
  name: z.string().trim().min(1).max(120),
});

const personSchema = z.object({
  name: z.string().trim().min(1).max(160),
  username: z
    .string()
    .trim()
    .min(1)
    .max(120)
    .regex(
      /^[a-zA-Z0-9._-]+$/,
      "Use letters, numbers, dots, dashes, or underscores",
    ),
  position: z.string().trim().min(1).max(160),
  departmentId: z.string().uuid(),
});

async function permitDirectoryWrite() {
  await requireAnyRole(["administrator"]);
  if (await isDemoPreview()) {
    throw new Error("Changes are disabled in demo preview.");
  }
}

export async function createDepartmentAction(formData: FormData) {
  await permitDirectoryWrite();
  const parsed = departmentSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message);
  const supabase = await dataClient();
  const { error } = await supabase.from("departments").insert(parsed.data);
  if (error) throw new Error(error.message);
  revalidatePath("/directory/people");
}

export async function createPersonAction(formData: FormData) {
  await permitDirectoryWrite();
  const parsed = personSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) throw new Error(parsed.error.issues[0]?.message);
  const supabase = await dataClient();
  const { error } = await supabase.from("people").insert({
    name: parsed.data.name,
    username: parsed.data.username,
    position: parsed.data.position,
    department_id: parsed.data.departmentId,
  });
  if (error) throw new Error(error.message);
  revalidatePath("/directory/people");
  revalidatePath("/admin/access");
}
