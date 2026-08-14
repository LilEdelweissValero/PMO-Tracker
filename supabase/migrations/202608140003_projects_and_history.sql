create table public.projects (
  id uuid primary key default gen_random_uuid(),
  code extensions.citext not null unique,
  name text not null,
  initiative_id uuid references public.initiatives (id),
  priority_id uuid not null references public.priorities (id),
  scope text,
  state public.project_state not null,
  current_stage_id uuid,
  pmo_officer_id uuid not null references public.people (id),
  ball_owner_id uuid references public.people (id),
  request_type_id uuid references public.request_types (id),
  initiator_type_id uuid references public.initiator_types (id),
  requester_id uuid references public.people (id),
  requester_department_name text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  constraint non_terminal_project_has_ball_owner
    check (state in ('Cancelled', 'Closed') or ball_owner_id is not null)
);

create table public.project_pmo_assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id),
  person_id uuid not null references public.people (id),
  effective_from timestamptz not null,
  effective_to timestamptz
);

create unique index one_current_pmo
  on public.project_pmo_assignments (project_id)
  where effective_to is null;

create table public.project_system_scopes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  system_id uuid not null references public.systems (id),
  entire_system boolean not null default false,
  module_id uuid references public.modules (id),
  constraint project_scope_shape
    check (
      (entire_system and module_id is null)
      or (not entire_system and module_id is not null)
    )
);

create table public.project_participant_assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id),
  person_id uuid not null references public.people (id),
  participant_group public.participant_group not null,
  effective_from timestamptz not null,
  effective_to timestamptz
);

create unique index one_current_project_participant
  on public.project_participant_assignments (
    project_id,
    person_id,
    participant_group
  )
  where effective_to is null;

create table public.project_references (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  reference_type_id uuid not null references public.reference_types (id),
  label text not null,
  url text not null,
  active boolean not null default true,
  constraint project_reference_http_url check (url ~ '^https?://')
);

create table public.project_stages (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  template_stage_id uuid references public.workflow_template_stages (id),
  name text not null,
  sort_order integer not null,
  detail_label text,
  detail_help text,
  detail_required boolean not null default false,
  detail_multiline boolean not null default false,
  visited boolean not null default false,
  active boolean not null default true,
  unique (project_id, sort_order)
);

alter table public.projects
  add constraint projects_current_stage_fk
  foreign key (current_stage_id)
  references public.project_stages (id)
  deferrable initially deferred;

create table public.stage_plan_revisions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id),
  project_stage_id uuid not null references public.project_stages (id),
  planned_date date,
  reason text not null,
  effective_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  actor_id uuid not null references public.profiles (id)
);

create table public.closeout_assessments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null unique references public.projects (id),
  dod_met boolean not null,
  dod_explanation text not null,
  methodology_compliant boolean not null,
  methodology_explanation text not null,
  documentation_complete boolean not null,
  documentation_explanation text not null,
  stakeholder_rating integer check (stakeholder_rating between 1 and 5),
  stakeholder_comment text,
  recorded_at timestamptz not null default now(),
  actor_id uuid not null references public.profiles (id)
);

create table public.project_events (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id),
  event_type public.project_event_type not null,
  effective_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  actor_id uuid not null references public.profiles (id),
  payload jsonb not null default '{}',
  resulting_state public.project_state,
  resulting_stage_id uuid references public.project_stages (id),
  resulting_stage_label text,
  resulting_ball_owner_id uuid references public.people (id),
  resulting_ball_owner_name text,
  supersedes_event_id uuid references public.project_events (id),
  correction_reason text,
  created_transaction_id bigint not null default txid_current()
);

create unique index one_correction_per_event
  on public.project_events (supersedes_event_id)
  where supersedes_event_id is not null;

create index project_events_timeline
  on public.project_events (project_id, effective_at, recorded_at, id);

create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  actor_id uuid not null references public.profiles (id),
  recorded_at timestamptz not null default now()
);

create function public.prevent_project_identity_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.code <> new.code then
    raise exception 'Project Code is immutable';
  end if;
  return new;
end;
$$;

create trigger immutable_project_code
before update on public.projects
for each row execute function public.prevent_project_identity_mutation();

create function public.immutable_event_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.recorded_at <> new.recorded_at or old.actor_id <> new.actor_id then
    raise exception 'Recorded timestamp and actor are immutable';
  end if;
  return new;
end;
$$;

create trigger immutable_project_event_fields
before update on public.project_events
for each row execute function public.immutable_event_fields();

create function public.prevent_event_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Project events are append-only';
end;
$$;

create trigger no_project_event_delete
before delete on public.project_events
for each row execute function public.prevent_event_delete();

comment on table public.projects is
  'Current project projection and immutable business identity.';
comment on table public.project_pmo_assignments is
  'Effective-dated accountable PMO Officer history; one row may be current.';
comment on table public.project_system_scopes is
  'Systems or individual modules affected by a project.';
comment on table public.project_participant_assignments is
  'Effective-dated PMO, Developer, and System Owner project membership.';
comment on table public.project_references is
  'Active external links attached to a project.';
comment on table public.project_stages is
  'Project-owned workflow stages copied from the default template.';
comment on table public.stage_plan_revisions is
  'Append-oriented planned-date history with effective and recorded times.';
comment on table public.closeout_assessments is
  'One governance closeout assessment for a closed project.';
comment on table public.project_events is
  'Canonical append-only project history ordered by effective and recorded time.';
comment on table public.audit_log is
  'Administrative mutation audit trail with before and after snapshots.';

comment on column public.projects.pmo_officer_id is
  'Current accountable PMO Officer projection; assignment history is authoritative.';
comment on column public.projects.ball_owner_id is
  'Current Ball Owner projection maintained with the event ledger.';
comment on column public.projects.version is
  'Optimistic concurrency token incremented by every project command.';
comment on column public.project_events.supersedes_event_id is
  'Original event corrected by this event; the original row remains intact.';
comment on constraint projects_current_stage_fk on public.projects is
  'Deferred because project-owned stages are created in the same transaction as a project.';
comment on index public.one_current_pmo is
  'Allows at most one current accountable PMO assignment per project.';
comment on index public.one_current_project_participant is
  'Prevents duplicate current membership in the same project group.';
comment on index public.project_events_timeline is
  'Supports deterministic effective/recorded project-history ordering.';
