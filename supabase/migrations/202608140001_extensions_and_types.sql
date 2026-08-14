create extension if not exists pgcrypto;
create extension if not exists citext with schema extensions;

create type public.app_role as enum (
  'administrator',
  'pmo_officer',
  'leadership_viewer'
);

create type public.project_state as enum (
  'Pipeline',
  'Planned',
  'Active',
  'On Hold',
  'Cancelled',
  'Closed'
);

create type public.participant_group as enum (
  'PMO',
  'Developer',
  'System Owner'
);

create type public.project_event_type as enum (
  'project_created',
  'project_changed',
  'progress',
  'bump',
  'state_changed',
  'ball_transferred',
  'workflow_changed',
  'participant_changed',
  'pmo_reassigned',
  'plan_revised',
  'corrected',
  'archived'
);

comment on type public.app_role is
  'Additive application roles attached to an authenticated profile.';
comment on type public.project_state is
  'Lifecycle state of the current project projection.';
comment on type public.participant_group is
  'Operational group in which a person participates on a project.';
comment on type public.project_event_type is
  'Supported event kinds in the append-only project history ledger.';
