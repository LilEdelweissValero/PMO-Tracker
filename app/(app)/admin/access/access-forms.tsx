"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import type { Role } from "@/lib/auth";
import {
  manageAccountAction,
  provisionAccountAction,
  type AccessActionState,
} from "./actions";

const initialAccessActionState: AccessActionState = { status: "idle" };

const roleOptions: { value: Role; label: string; description: string }[] = [
  {
    value: "administrator",
    label: "Administrator",
    description:
      "Configuration, account access, corrections, and all commands.",
  },
  {
    value: "pmo_officer",
    label: "PMO Officer",
    description: "Own and operate assigned Projects.",
  },
  {
    value: "leadership_viewer",
    label: "Leadership Viewer",
    description: "Read the portfolio, Ball, and reports.",
  },
];

function SubmitButton({
  children,
  disabled = false,
}: {
  children: React.ReactNode;
  disabled?: boolean;
}) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending || disabled}>
      {pending ? "Working…" : children}
    </button>
  );
}

function ActionMessage({ state }: { state: typeof initialAccessActionState }) {
  if (!state.message) return null;
  return (
    <p className={`form-message ${state.status}`} role="status">
      {state.message}
    </p>
  );
}

function RoleFields({
  selected = [],
  disabled = false,
}: {
  selected?: Role[];
  disabled?: boolean;
}) {
  return (
    <fieldset className="role-picker">
      <legend>Application roles</legend>
      {roleOptions.map((role) => (
        <label key={role.value}>
          <input
            type="checkbox"
            name="roles"
            value={role.value}
            defaultChecked={selected.includes(role.value)}
            disabled={disabled}
          />
          <span>
            <strong>{role.label}</strong>
            <small>{role.description}</small>
          </span>
        </label>
      ))}
    </fieldset>
  );
}

export function ProvisionAccountForm({
  people,
  disabled = false,
}: {
  people: { id: string; name: string; position: string }[];
  disabled?: boolean;
}) {
  const [state, action] = useActionState(
    provisionAccountAction,
    initialAccessActionState,
  );
  return (
    <form action={action} className="form-grid access-form">
      <div className="field">
        <label htmlFor="provision-person">Directory Person</label>
        <select
          id="provision-person"
          name="personId"
          required
          disabled={disabled || people.length === 0}
        >
          <option value="">Choose an active Person</option>
          {people.map((person) => (
            <option key={person.id} value={person.id}>
              {person.name} · {person.position}
            </option>
          ))}
        </select>
      </div>
      <div className="field">
        <label htmlFor="provision-email">Work email</label>
        <input
          id="provision-email"
          name="email"
          type="email"
          autoComplete="email"
          required
          disabled={disabled}
        />
        <small>Supabase sends the password-setup invitation.</small>
      </div>
      <div className="field full">
        <RoleFields disabled={disabled} />
      </div>
      <div className="access-form-actions field full">
        <SubmitButton disabled={disabled || people.length === 0}>
          Send invitation
        </SubmitButton>
        <ActionMessage state={state} />
      </div>
    </form>
  );
}

export function ManageAccessForm({
  profileId,
  active,
  roles,
  disabled = false,
}: {
  profileId: string;
  active: boolean;
  roles: Role[];
  disabled?: boolean;
}) {
  const [state, action] = useActionState(
    manageAccountAction,
    initialAccessActionState,
  );
  return (
    <form action={action} className="manage-access-form">
      <input type="hidden" name="profileId" value={profileId} />
      <label className="account-toggle">
        <input
          type="checkbox"
          name="active"
          defaultChecked={active}
          disabled={disabled}
        />
        <span>Account active</span>
      </label>
      <RoleFields selected={roles} disabled={disabled} />
      <div className="access-form-actions">
        <SubmitButton disabled={disabled}>Save access</SubmitButton>
        <ActionMessage state={state} />
      </div>
    </form>
  );
}
