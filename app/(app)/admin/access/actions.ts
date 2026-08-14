"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import {
  manageProfileAccess,
  provisionProfile,
} from "@/lib/actions/access-commands";
import { requireAnyRole } from "@/lib/auth";
import { isDemo } from "@/lib/demo";
import {
  provisionApplicationAccount,
  ProvisioningCompensationError,
} from "@/lib/provisioning";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

const roles = ["administrator", "pmo_officer", "leadership_viewer"] as const;
const selectedRoles = z
  .array(z.enum(roles))
  .min(1, "Choose at least one role.")
  .refine(
    (value) => new Set(value).size === value.length,
    "Roles must be unique.",
  );
const provisionSchema = z.object({
  personId: z.string().uuid(),
  email: z.string().trim().email().max(254),
  roles: selectedRoles,
});
const manageSchema = z.object({
  profileId: z.string().uuid(),
  active: z.boolean(),
  roles: selectedRoles,
});

export type AccessActionState = {
  status: "idle" | "success" | "error";
  message?: string;
};

function rolesFrom(formData: FormData) {
  return formData.getAll("roles").map(String);
}

export async function provisionAccountAction(
  _previous: AccessActionState,
  formData: FormData,
): Promise<AccessActionState> {
  await requireAnyRole(["administrator"]);
  if (isDemo) {
    return {
      status: "error",
      message: "Changes are disabled in demo preview.",
    };
  }
  const parsed = provisionSchema.safeParse({
    personId: formData.get("personId"),
    email: formData.get("email"),
    roles: rolesFrom(formData),
  });
  if (!parsed.success) {
    return { status: "error", message: parsed.error.issues[0]?.message };
  }

  try {
    const authAdmin = createAdminClient();
    const userClient = await createClient();
    await provisionApplicationAccount(
      {
        createAuthUser: async (email) => {
          const { data, error } =
            await authAdmin.auth.admin.inviteUserByEmail(email);
          if (error || !data.user)
            throw error ?? new Error("Auth user was not created");
          return data.user.id;
        },
        linkProfile: async (authUserId, input) => {
          const result = await provisionProfile(
            {
              authUserId,
              personId: input.personId,
              email: input.email,
              roles: input.roles,
            },
            userClient,
          );
          if (result.status !== "success") {
            throw new Error(
              "issue" in result
                ? result.issue.message
                : "Profile provisioning failed.",
            );
          }
        },
        deleteAuthUser: async (authUserId) => {
          const { error } = await authAdmin.auth.admin.deleteUser(authUserId);
          if (error) throw error;
        },
      },
      parsed.data,
    );
    revalidatePath("/admin/access");
    return {
      status: "success",
      message: "Invitation sent and application access provisioned.",
    };
  } catch (error) {
    if (error instanceof ProvisioningCompensationError) {
      console.error("Account provisioning compensation failed", {
        provisioningError: String(error.provisioningError),
        cleanupError: String(error.cleanupError),
      });
      return {
        status: "error",
        message:
          "Provisioning failed and automatic cleanup needs review in Supabase Auth.",
      };
    }
    return {
      status: "error",
      message:
        "The invitation could not be provisioned. Confirm that the email and Person are unused.",
    };
  }
}

export async function manageAccountAction(
  _previous: AccessActionState,
  formData: FormData,
): Promise<AccessActionState> {
  await requireAnyRole(["administrator"]);
  if (isDemo) {
    return {
      status: "error",
      message: "Changes are disabled in demo preview.",
    };
  }
  const parsed = manageSchema.safeParse({
    profileId: formData.get("profileId"),
    active: formData.get("active") === "on",
    roles: rolesFrom(formData),
  });
  if (!parsed.success) {
    return { status: "error", message: parsed.error.issues[0]?.message };
  }

  const result = await manageProfileAccess(parsed.data);
  if (result.status !== "success") {
    return {
      status: "error",
      message:
        "issue" in result && result.issue.code === "23514"
          ? "Keep at least one active Administrator account."
          : "Access could not be updated. Refresh and try again.",
    };
  }
  revalidatePath("/admin/access");
  return { status: "success", message: "Application access updated." };
}
