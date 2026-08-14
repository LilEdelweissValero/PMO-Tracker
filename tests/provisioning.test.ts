import { describe, expect, it, vi } from "vitest";
import {
  provisionApplicationAccount,
  ProvisioningCompensationError,
} from "@/lib/provisioning";

const input = {
  personId: "11111111-1111-4111-8111-111111111111",
  email: "person@example.test",
  roles: ["pmo_officer"],
};

describe("account provisioning compensation", () => {
  it("keeps the Auth user after the Profile transaction succeeds", async () => {
    const deleteAuthUser = vi.fn();
    await expect(
      provisionApplicationAccount(
        {
          createAuthUser: vi.fn().mockResolvedValue("auth-user"),
          linkProfile: vi.fn().mockResolvedValue(undefined),
          deleteAuthUser,
        },
        input,
      ),
    ).resolves.toBe("auth-user");
    expect(deleteAuthUser).not.toHaveBeenCalled();
  });

  it("deletes the Auth user when Profile creation fails", async () => {
    const deleteAuthUser = vi.fn().mockResolvedValue(undefined);
    await expect(
      provisionApplicationAccount(
        {
          createAuthUser: vi.fn().mockResolvedValue("orphan-candidate"),
          linkProfile: vi.fn().mockRejectedValue(new Error("Profile failed")),
          deleteAuthUser,
        },
        input,
      ),
    ).rejects.toThrow("Profile failed");
    expect(deleteAuthUser).toHaveBeenCalledWith("orphan-candidate");
  });

  it("surfaces a distinct error when compensation also fails", async () => {
    await expect(
      provisionApplicationAccount(
        {
          createAuthUser: vi.fn().mockResolvedValue("orphan-candidate"),
          linkProfile: vi.fn().mockRejectedValue(new Error("Profile failed")),
          deleteAuthUser: vi.fn().mockRejectedValue(new Error("Delete failed")),
        },
        input,
      ),
    ).rejects.toBeInstanceOf(ProvisioningCompensationError);
  });
});
