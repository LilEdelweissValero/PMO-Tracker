export type ProvisionAccountInput = {
  personId: string;
  email: string;
  roles: string[];
};

export type ProvisionAccountDependencies = {
  createAuthUser(email: string): Promise<string>;
  linkProfile(authUserId: string, input: ProvisionAccountInput): Promise<void>;
  deleteAuthUser(authUserId: string): Promise<void>;
};

export class ProvisioningCompensationError extends Error {
  constructor(
    public readonly provisioningError: unknown,
    public readonly cleanupError: unknown,
  ) {
    super("Account provisioning and Auth-user cleanup both failed.");
    this.name = "ProvisioningCompensationError";
  }
}

export async function provisionApplicationAccount(
  dependencies: ProvisionAccountDependencies,
  input: ProvisionAccountInput,
) {
  const authUserId = await dependencies.createAuthUser(input.email);
  try {
    await dependencies.linkProfile(authUserId, input);
    return authUserId;
  } catch (provisioningError) {
    try {
      await dependencies.deleteAuthUser(authUserId);
    } catch (cleanupError) {
      throw new ProvisioningCompensationError(provisioningError, cleanupError);
    }
    throw provisioningError;
  }
}
