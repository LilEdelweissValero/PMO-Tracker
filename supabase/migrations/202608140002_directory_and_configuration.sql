create table public.departments (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.people (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  department_id uuid not null references public.departments (id) on delete restrict,
  username extensions.citext not null unique,
  position text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  person_id uuid not null unique references public.people (id) on delete restrict,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.profile_roles (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role public.app_role not null,
  primary key (profile_id, role)
);

create table public.systems (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.modules (
  id uuid primary key default gen_random_uuid(),
  system_id uuid not null references public.systems (id) on delete restrict,
  name text not null,
  active boolean not null default true,
  unique (system_id, name),
  unique (id, system_id)
);

create table public.system_developer_assignments (
  id uuid primary key default gen_random_uuid(),
  system_id uuid not null references public.systems (id) on delete restrict,
  person_id uuid not null references public.people (id) on delete restrict,
  effective_from timestamptz not null,
  effective_to timestamptz,
  constraint system_developer_assignment_dates
    check (effective_to is null or effective_to > effective_from),
  constraint system_developer_assignments_no_overlap
    exclude using gist (
      system_id with =,
      person_id with =,
      tstzrange(effective_from, effective_to, '[)') with &&
    )
);

create unique index one_current_developer_assignment
  on public.system_developer_assignments (system_id, person_id)
  where effective_to is null;

create index system_developer_assignments_person_current_idx
  on public.system_developer_assignments (person_id, system_id)
  where effective_to is null;

create index system_developer_assignments_system_history_idx
  on public.system_developer_assignments (system_id, effective_from desc);

create table public.module_owner_assignments (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules (id) on delete restrict,
  person_id uuid not null references public.people (id) on delete restrict,
  effective_from timestamptz not null,
  effective_to timestamptz,
  constraint module_owner_assignment_dates
    check (effective_to is null or effective_to > effective_from),
  constraint module_owner_assignments_no_overlap
    exclude using gist (
      module_id with =,
      tstzrange(effective_from, effective_to, '[)') with &&
    )
);

create unique index one_current_module_owner
  on public.module_owner_assignments (module_id)
  where effective_to is null;

create index module_owner_assignments_person_current_idx
  on public.module_owner_assignments (person_id, module_id)
  where effective_to is null;

create index module_owner_assignments_module_history_idx
  on public.module_owner_assignments (module_id, effective_from desc);

create table public.priorities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  sort_order integer not null,
  active boolean not null default true
);

create table public.request_types (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true
);

create table public.reference_types (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true
);

create table public.initiator_types (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true
);

create table public.workflow_template_stages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort_order integer not null unique,
  detail_label text,
  detail_help text,
  detail_required boolean not null default false,
  detail_multiline boolean not null default false,
  active boolean not null default true
);

create table public.initiatives (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true
);

create index people_department_idx on public.people (department_id);
create index profile_roles_role_profile_idx
  on public.profile_roles (role, profile_id);
create index modules_system_active_idx
  on public.modules (system_id, active, name);
create index workflow_template_stages_active_order_idx
  on public.workflow_template_stages (sort_order)
  where active;

comment on table public.departments is
  'Retireable organizational directory used by people and request snapshots.';
comment on table public.people is
  'Application people directory; a person may exist without an Auth account.';
comment on table public.profiles is
  'One-to-one link from a Supabase Auth user to an application person.';
comment on table public.profile_roles is
  'Additive role assignments for an authenticated application profile.';
comment on table public.systems is
  'Retireable directory of systems affected by projects.';
comment on table public.modules is
  'Retireable modules owned by a single parent system.';
comment on table public.system_developer_assignments is
  'Effective-dated developer membership for a system.';
comment on table public.module_owner_assignments is
  'Effective-dated ownership history with at most one current owner per module.';
comment on table public.priorities is
  'Ordered, retireable project priority choices.';
comment on table public.request_types is
  'Retireable project request-type choices.';
comment on table public.reference_types is
  'Retireable external-reference choices.';
comment on table public.initiator_types is
  'Retireable project initiator choices.';
comment on table public.workflow_template_stages is
  'Ordered defaults copied into each project when it is created.';
comment on table public.initiatives is
  'Optional portfolio groupings for related projects.';

comment on column public.people.department_id is
  'Owning department for the person.';
comment on column public.profiles.id is
  'The corresponding auth.users identifier.';
comment on column public.profiles.person_id is
  'The single directory person represented by this account.';
comment on index public.one_current_developer_assignment is
  'Prevents duplicate simultaneous assignments of the same developer to one system.';
comment on index public.one_current_module_owner is
  'Enforces exactly zero or one current owner row per module.';
comment on constraint system_developer_assignments_no_overlap
  on public.system_developer_assignments is
  'Prevents overlapping effective periods for the same developer and system.';
comment on constraint module_owner_assignments_no_overlap
  on public.module_owner_assignments is
  'Prevents overlapping ownership periods for the same module.';
