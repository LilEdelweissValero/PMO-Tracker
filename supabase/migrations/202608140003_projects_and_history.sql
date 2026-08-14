create table public.projects (
  id uuid primary key default gen_random_uuid(),
  code extensions.citext not null unique,
  name text not null,
  initiative_id uuid references public.initiatives (id) on delete restrict,
  priority_id uuid not null references public.priorities (id) on delete restrict,
  scope text,
  state public.project_state not null,
  current_stage_id uuid,
  pmo_officer_id uuid not null references public.people (id) on delete restrict,
  ball_owner_id uuid references public.people (id) on delete restrict,
  request_type_id uuid references public.request_types (id) on delete restrict,
  initiator_type_id uuid references public.initiator_types (id) on delete restrict,
  requester_id uuid references public.people (id) on delete restrict,
  requester_department_name text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  constraint non_terminal_project_has_ball_owner
    check (state in ('Cancelled', 'Closed') or ball_owner_id is not null),
  constraint project_version_is_positive check (version > 0),
  constraint archived_project_is_terminal
    check (archived_at is null or state in ('Cancelled', 'Closed'))
);

create table public.project_pmo_assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  person_id uuid not null references public.people (id) on delete restrict,
  effective_from timestamptz not null,
  effective_to timestamptz,
  constraint project_pmo_assignment_dates
    check (effective_to is null or effective_to > effective_from),
  constraint project_pmo_assignments_no_overlap
    exclude using gist (
      project_id with =,
      tstzrange(effective_from, effective_to, '[)') with &&
    )
);

create unique index one_current_pmo
  on public.project_pmo_assignments (project_id)
  where effective_to is null;

create table public.project_system_scopes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  system_id uuid not null references public.systems (id) on delete restrict,
  entire_system boolean not null default false,
  module_id uuid,
  constraint project_scope_shape
    check (
      (entire_system and module_id is null)
      or (not entire_system and module_id is not null)
    ),
  constraint project_scope_module_belongs_to_system
    foreign key (module_id, system_id)
    references public.modules (id, system_id)
    on delete restrict
);

create table public.project_participant_assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  person_id uuid not null references public.people (id) on delete restrict,
  participant_group public.participant_group not null,
  effective_from timestamptz not null,
  effective_to timestamptz,
  constraint project_participant_assignment_dates
    check (effective_to is null or effective_to > effective_from),
  constraint project_participant_assignments_no_overlap
    exclude using gist (
      project_id with =,
      person_id with =,
      tstzrange(effective_from, effective_to, '[)') with &&
    )
);

create unique index one_current_project_participant
  on public.project_participant_assignments (
    project_id,
    person_id
  )
  where effective_to is null;

create unique index one_entire_system_scope
  on public.project_system_scopes (project_id, system_id)
  where entire_system;

create unique index one_module_scope
  on public.project_system_scopes (project_id, system_id, module_id)
  where module_id is not null;

alter table public.project_system_scopes
  add constraint project_scope_entire_or_modules
  exclude using gist (
    project_id with =,
    system_id with =,
    entire_system with <>
  );

create table public.project_references (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  reference_type_id uuid not null references public.reference_types (id) on delete restrict,
  label text not null,
  url text not null,
  active boolean not null default true,
  constraint project_reference_http_url check (url ~ '^https?://')
);

create table public.project_stages (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  template_stage_id uuid references public.workflow_template_stages (id) on delete restrict,
  name text not null,
  sort_order integer not null,
  detail_label text,
  detail_help text,
  detail_required boolean not null default false,
  detail_multiline boolean not null default false,
  visited boolean not null default false,
  active boolean not null default true,
  unique (project_id, sort_order),
  unique (id, project_id)
);

alter table public.projects
  add constraint projects_current_stage_fk
  foreign key (current_stage_id, id)
  references public.project_stages (id, project_id)
  on delete restrict
  deferrable initially deferred;

create table public.stage_plan_revisions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  project_stage_id uuid not null,
  planned_date date,
  reason text not null,
  effective_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  actor_id uuid not null references public.profiles (id) on delete restrict,
  constraint stage_plan_stage_belongs_to_project
    foreign key (project_stage_id, project_id)
    references public.project_stages (id, project_id)
    on delete restrict
);

create table public.closeout_assessments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null unique references public.projects (id) on delete restrict,
  dod_met boolean not null,
  dod_explanation text not null,
  methodology_compliant boolean not null,
  methodology_explanation text not null,
  documentation_complete boolean not null,
  documentation_explanation text not null,
  stakeholder_rating integer check (stakeholder_rating between 1 and 5),
  stakeholder_comment text,
  recorded_at timestamptz not null default now(),
  actor_id uuid not null references public.profiles (id) on delete restrict
);

create table public.project_events (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete restrict,
  event_type public.project_event_type not null,
  effective_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  actor_id uuid not null references public.profiles (id) on delete restrict,
  payload jsonb not null default '{}',
  resulting_state public.project_state,
  resulting_stage_id uuid,
  resulting_stage_label text,
  resulting_ball_owner_id uuid references public.people (id) on delete restrict,
  resulting_ball_owner_name text,
  supersedes_event_id uuid,
  correction_reason text,
  created_transaction_id bigint not null default txid_current(),
  unique (id, project_id),
  constraint project_event_payload_is_object
    check (jsonb_typeof(payload) = 'object'),
  constraint project_event_snapshot_pairs
    check (
      (resulting_stage_id is null) = (resulting_stage_label is null)
      and (resulting_ball_owner_id is null) = (resulting_ball_owner_name is null)
    ),
  constraint project_event_result_shape
    check (
      event_type not in (
        'project_created',
        'progress',
        'bump',
        'state_changed',
        'ball_transferred',
        'corrected'
      )
      or (
        resulting_state is not null
        and resulting_ball_owner_id is not null
      )
    ),
  constraint project_event_type_payload
    check (
      (
        event_type = 'project_created'
        and nullif(btrim(payload ->> 'code'), '') is not null
        and nullif(btrim(payload ->> 'name'), '') is not null
      )
      or (
        event_type = 'progress'
        and resulting_stage_id is not null
        and nullif(btrim(payload ->> 'summary'), '') is not null
      )
      or (
        event_type = 'bump'
        and nullif(btrim(payload ->> 'text'), '') is not null
      )
      or (
        event_type = 'state_changed'
        and (
          resulting_state not in ('On Hold', 'Cancelled')
          or nullif(btrim(payload ->> 'reason'), '') is not null
        )
      )
      or (
        event_type = 'archived'
        and resulting_state in ('Cancelled', 'Closed')
      )
      or event_type in (
        'project_changed',
        'ball_transferred',
        'workflow_changed',
        'participant_changed',
        'pmo_reassigned',
        'plan_revised',
        'corrected'
      )
    ),
  constraint correction_event_shape
    check (
      (
        event_type = 'corrected'
        and supersedes_event_id is not null
        and nullif(btrim(correction_reason), '') is not null
      )
      or (
        event_type <> 'corrected'
        and supersedes_event_id is null
        and correction_reason is null
      )
    ),
  constraint correction_does_not_supersede_itself
    check (supersedes_event_id is null or supersedes_event_id <> id),
  constraint event_stage_belongs_to_project
    foreign key (resulting_stage_id, project_id)
    references public.project_stages (id, project_id)
    on delete restrict,
  constraint correction_event_belongs_to_project
    foreign key (supersedes_event_id, project_id)
    references public.project_events (id, project_id)
    on delete restrict
);

create unique index one_correction_per_event
  on public.project_events (supersedes_event_id)
  where supersedes_event_id is not null;

create unique index one_project_created_event
  on public.project_events (project_id)
  where event_type = 'project_created';

create index project_events_timeline
  on public.project_events (project_id, effective_at, recorded_at, id);

create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  actor_id uuid not null references public.profiles (id) on delete restrict,
  recorded_at timestamptz not null default now()
);

create index projects_initiative_idx on public.projects (initiative_id);
create index projects_priority_idx on public.projects (priority_id);
create index projects_request_type_idx on public.projects (request_type_id);
create index projects_initiator_type_idx on public.projects (initiator_type_id);
create index projects_requester_idx on public.projects (requester_id);
create index projects_current_stage_idx
  on public.projects (current_stage_id, id);
create index projects_active_portfolio_idx
  on public.projects (state, priority_id, updated_at desc)
  where archived_at is null;
create index projects_pmo_queue_idx
  on public.projects (pmo_officer_id, state, updated_at desc)
  where archived_at is null;
create index projects_ball_queue_idx
  on public.projects (ball_owner_id, state, updated_at desc)
  where archived_at is null and state not in ('Cancelled', 'Closed');

create index project_pmo_assignments_person_current_idx
  on public.project_pmo_assignments (person_id, project_id)
  where effective_to is null;
create index project_pmo_assignments_history_idx
  on public.project_pmo_assignments (project_id, effective_from desc);
create index project_system_scopes_system_idx
  on public.project_system_scopes (system_id, project_id);
create index project_system_scopes_module_idx
  on public.project_system_scopes (module_id, system_id);
create index project_participants_person_current_idx
  on public.project_participant_assignments (person_id, project_id, participant_group)
  where effective_to is null;
create index project_participants_project_group_current_idx
  on public.project_participant_assignments (project_id, participant_group, person_id)
  where effective_to is null;
create index project_participants_history_idx
  on public.project_participant_assignments (project_id, effective_from desc);
create index project_references_type_idx
  on public.project_references (reference_type_id);
create index project_references_active_idx
  on public.project_references (project_id, label)
  where active;
create index project_stages_template_idx
  on public.project_stages (template_stage_id)
  where template_stage_id is not null;
create index stage_plan_revisions_timeline_idx
  on public.stage_plan_revisions (
    project_id,
    project_stage_id,
    effective_at desc,
    recorded_at desc
  );
create index stage_plan_revisions_stage_project_idx
  on public.stage_plan_revisions (project_stage_id, project_id);
create index stage_plan_revisions_actor_idx
  on public.stage_plan_revisions (actor_id);
create index closeout_assessments_actor_idx
  on public.closeout_assessments (actor_id);
create index project_events_actor_idx on public.project_events (actor_id);
create index project_events_stage_idx
  on public.project_events (resulting_stage_id, project_id);
create index project_events_supersedes_project_idx
  on public.project_events (supersedes_event_id, project_id);
create index project_events_ball_owner_idx
  on public.project_events (resulting_ball_owner_id, effective_at desc)
  where resulting_ball_owner_id is not null;
create index project_events_kind_timeline_idx
  on public.project_events (
    project_id,
    event_type,
    effective_at desc,
    recorded_at desc,
    id desc
  );
create index audit_log_entity_timeline_idx
  on public.audit_log (entity_type, entity_id, recorded_at desc);
create index audit_log_actor_idx on public.audit_log (actor_id);

create function public.enforce_project_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.code::text is distinct from new.code::text then
    raise exception 'Project Code is immutable';
  end if;

  if new.version <> old.version + 1 then
    raise exception 'Project version must increment by exactly one';
  end if;

  if old.state in ('Cancelled', 'Closed') then
    if new.state is distinct from old.state then
      raise exception 'Terminal Projects cannot reopen or change terminal State';
    end if;

    if (
      to_jsonb(new) - 'archived_at' - 'updated_at' - 'version'
    ) is distinct from (
      to_jsonb(old) - 'archived_at' - 'updated_at' - 'version'
    ) then
      raise exception 'Terminal Projects may only be archived or restored';
    end if;
  end if;

  return new;
end;
$$;

create trigger enforce_project_update
before update on public.projects
for each row execute function public.enforce_project_update();

create function public.prevent_project_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Projects are archived rather than deleted';
end;
$$;

create trigger prevent_project_delete
before delete on public.projects
for each row execute function public.prevent_project_delete();

create function public.prevent_append_only_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception '% is append-only', tg_table_name;
end;
$$;

create trigger project_events_are_append_only
before update or delete on public.project_events
for each row execute function public.prevent_append_only_mutation();

create trigger stage_plan_revisions_are_append_only
before update or delete on public.stage_plan_revisions
for each row execute function public.prevent_append_only_mutation();

create trigger audit_log_is_append_only
before update or delete on public.audit_log
for each row execute function public.prevent_append_only_mutation();

create function public.validate_correction_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  original_type public.project_event_type;
begin
  if new.event_type <> 'corrected' then
    return new;
  end if;

  select event_type
  into original_type
  from public.project_events
  where id = new.supersedes_event_id
    and project_id = new.project_id;

  if not found then
    raise exception 'A correction must supersede an event from the same Project';
  end if;

  if original_type not in (
    'progress',
    'bump',
    'state_changed',
    'ball_transferred'
  ) then
    raise exception 'Only Progress, Bump, State change, or Ball transfer events may be corrected';
  end if;

  return new;
end;
$$;

create trigger validate_correction_event
before insert on public.project_events
for each row execute function public.validate_correction_event();

create function public.validate_project_creation_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_project_id uuid;
begin
  if tg_table_name = 'projects' then
    if tg_op = 'DELETE' then
      target_project_id := old.id;
    else
      target_project_id := new.id;
    end if;
  elsif tg_op = 'DELETE' then
    target_project_id := old.project_id;
  else
    target_project_id := new.project_id;
  end if;

  if exists (
    select 1 from public.projects where id = target_project_id
  ) and not exists (
    select 1
    from public.project_events
    where project_id = target_project_id
      and event_type = 'project_created'
  ) then
    raise exception 'Every Project requires exactly one creation event';
  end if;

  return null;
end;
$$;

create constraint trigger validate_project_creation_event
after insert on public.projects
deferrable initially deferred
for each row execute function public.validate_project_creation_event();

create constraint trigger validate_project_event_creation_event
after insert on public.project_events
deferrable initially deferred
for each row execute function public.validate_project_creation_event();

create function public.protect_visited_project_stage()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' and old.visited then
    raise exception 'Visited Project stages cannot be deleted';
  end if;

  if tg_op = 'UPDATE' and old.visited and not new.visited then
    raise exception 'Visited Project stages cannot be marked unvisited';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger protect_visited_project_stage
before update or delete on public.project_stages
for each row execute function public.protect_visited_project_stage();

create function public.protect_effective_assignment_history()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (
    to_jsonb(new) - 'effective_to'
  ) is distinct from (
    to_jsonb(old) - 'effective_to'
  ) then
    raise exception 'Assignment identity and effective start are immutable';
  end if;

  if old.effective_to is not null and new.effective_to is distinct from old.effective_to then
    raise exception 'Closed assignment periods are immutable';
  end if;

  return new;
end;
$$;

create function public.prevent_effective_assignment_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Assignment periods are closed rather than deleted';
end;
$$;

create trigger protect_system_developer_history
before update on public.system_developer_assignments
for each row execute function public.protect_effective_assignment_history();
create trigger prevent_system_developer_delete
before delete on public.system_developer_assignments
for each row execute function public.prevent_effective_assignment_delete();

create trigger protect_module_owner_history
before update on public.module_owner_assignments
for each row execute function public.protect_effective_assignment_history();
create trigger prevent_module_owner_delete
before delete on public.module_owner_assignments
for each row execute function public.prevent_effective_assignment_delete();

create trigger protect_project_pmo_history
before update on public.project_pmo_assignments
for each row execute function public.protect_effective_assignment_history();
create trigger prevent_project_pmo_delete
before delete on public.project_pmo_assignments
for each row execute function public.prevent_effective_assignment_delete();

create trigger protect_project_participant_history
before update on public.project_participant_assignments
for each row execute function public.protect_effective_assignment_history();
create trigger prevent_project_participant_delete
before delete on public.project_participant_assignments
for each row execute function public.prevent_effective_assignment_delete();

create function public.validate_active_assignment_person()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.person_id = old.person_id then
    return null;
  end if;

  if not exists (
    select 1
    from public.people
    where id = new.person_id and active
  ) then
    raise exception 'New assignments require an active Person';
  end if;

  return null;
end;
$$;

create constraint trigger validate_system_developer_person
after insert or update on public.system_developer_assignments
deferrable initially deferred
for each row execute function public.validate_active_assignment_person();

create constraint trigger validate_module_owner_person
after insert or update on public.module_owner_assignments
deferrable initially deferred
for each row execute function public.validate_active_assignment_person();

create constraint trigger validate_project_pmo_person
after insert or update on public.project_pmo_assignments
deferrable initially deferred
for each row execute function public.validate_active_assignment_person();

create constraint trigger validate_project_participant_person
after insert or update on public.project_participant_assignments
deferrable initially deferred
for each row execute function public.validate_active_assignment_person();

create function public.validate_system_configuration()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  system_ids uuid[];
  target_system_id uuid;
begin
  if tg_table_name = 'systems' then
    if tg_op = 'DELETE' then
      system_ids := array[old.id];
    else
      system_ids := array[new.id];
    end if;
  elsif tg_op = 'INSERT' then
    system_ids := array[new.system_id];
  elsif tg_op = 'DELETE' then
    system_ids := array[old.system_id];
  else
    system_ids := array[old.system_id, new.system_id];
  end if;

  foreach target_system_id in array system_ids
  loop
    continue when target_system_id is null;
    continue when not exists (
      select 1 from public.systems where id = target_system_id
    );

    if not exists (
      select 1
      from public.modules
      where system_id = target_system_id
    ) then
      raise exception 'A System requires at least one Module';
    end if;

    if not exists (
      select 1
      from public.system_developer_assignments
      where system_id = target_system_id
        and effective_from <= transaction_timestamp()
        and (effective_to is null or effective_to > transaction_timestamp())
    ) then
      raise exception 'A System requires at least one current Developer assignment';
    end if;
  end loop;

  return null;
end;
$$;

create constraint trigger validate_system_configuration
after insert or update on public.systems
deferrable initially deferred
for each row execute function public.validate_system_configuration();

create constraint trigger validate_system_module_configuration
after insert or update or delete on public.modules
deferrable initially deferred
for each row execute function public.validate_system_configuration();

create constraint trigger validate_system_developer_configuration
after insert or update or delete on public.system_developer_assignments
deferrable initially deferred
for each row execute function public.validate_system_configuration();

create function public.validate_module_ownership()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  module_ids uuid[];
  target_module_id uuid;
  current_owner_count integer;
begin
  if tg_table_name = 'modules' then
    if tg_op = 'DELETE' then
      module_ids := array[old.id];
    else
      module_ids := array[new.id];
    end if;
  elsif tg_op = 'INSERT' then
    module_ids := array[new.module_id];
  elsif tg_op = 'DELETE' then
    module_ids := array[old.module_id];
  else
    module_ids := array[old.module_id, new.module_id];
  end if;

  foreach target_module_id in array module_ids
  loop
    continue when target_module_id is null;
    continue when not exists (
      select 1 from public.modules where id = target_module_id
    );

    select count(*)
    into current_owner_count
    from public.module_owner_assignments
    where module_id = target_module_id
      and effective_from <= transaction_timestamp()
      and (effective_to is null or effective_to > transaction_timestamp());

    if current_owner_count <> 1 then
      raise exception 'A Module requires exactly one current Owner assignment';
    end if;
  end loop;

  return null;
end;
$$;

create constraint trigger validate_module_ownership
after insert or update on public.modules
deferrable initially deferred
for each row execute function public.validate_module_ownership();

create constraint trigger validate_module_owner_configuration
after insert or update or delete on public.module_owner_assignments
deferrable initially deferred
for each row execute function public.validate_module_ownership();

create function public.validate_project_relationships()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_project_id uuid;
  project_row public.projects%rowtype;
begin
  if tg_table_name = 'projects' then
    target_project_id := case when tg_op = 'DELETE' then old.id else new.id end;
  else
    target_project_id := case
      when tg_op = 'DELETE' then old.project_id
      else new.project_id
    end;
  end if;

  select *
  into project_row
  from public.projects
  where id = target_project_id;

  if not found or project_row.state in ('Cancelled', 'Closed') then
    return null;
  end if;

  if not exists (
    select 1
    from public.project_pmo_assignments as assignment
    join public.people as person on person.id = assignment.person_id
    where assignment.project_id = project_row.id
      and assignment.person_id = project_row.pmo_officer_id
      and assignment.effective_from <= transaction_timestamp()
      and (
        assignment.effective_to is null
        or assignment.effective_to > transaction_timestamp()
      )
      and person.active
  ) then
    raise exception 'A non-terminal Project requires one current active PMO Officer assignment';
  end if;

  if not exists (
    select 1
    from public.project_participant_assignments as assignment
    join public.people as person on person.id = assignment.person_id
    where assignment.project_id = project_row.id
      and assignment.person_id = project_row.ball_owner_id
      and assignment.effective_from <= transaction_timestamp()
      and (
        assignment.effective_to is null
        or assignment.effective_to > transaction_timestamp()
      )
      and person.active
  ) then
    raise exception 'A non-terminal Project Ball Owner must be an active current Participant';
  end if;

  return null;
end;
$$;

create constraint trigger validate_project_relationships
after insert or update on public.projects
deferrable initially deferred
for each row execute function public.validate_project_relationships();

create function public.validate_closed_project_closeout()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_project_id uuid;
begin
  if tg_table_name = 'projects' then
    if tg_op = 'DELETE' then
      target_project_id := old.id;
    else
      target_project_id := new.id;
    end if;
  elsif tg_op = 'DELETE' then
    target_project_id := old.project_id;
  else
    target_project_id := new.project_id;
  end if;

  if exists (
    select 1
    from public.projects as project
    where project.id = target_project_id
      and project.state = 'Closed'
  ) and not exists (
    select 1
    from public.closeout_assessments as assessment
    where assessment.project_id = target_project_id
  ) then
    raise exception 'A Closed Project requires a closeout assessment';
  end if;

  return null;
end;
$$;

create constraint trigger validate_closed_project_closeout
after insert or update on public.projects
deferrable initially deferred
for each row execute function public.validate_closed_project_closeout();

create constraint trigger validate_closeout_project_state
after insert or update or delete on public.closeout_assessments
deferrable initially deferred
for each row execute function public.validate_closed_project_closeout();

create function public.protect_final_closeout()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.projects
    where id = old.project_id and state = 'Closed'
  ) then
    raise exception 'A Closed Project closeout assessment is final';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger protect_final_closeout
before update or delete on public.closeout_assessments
for each row execute function public.protect_final_closeout();

create constraint trigger validate_project_pmo_relationships
after insert or update or delete on public.project_pmo_assignments
deferrable initially deferred
for each row execute function public.validate_project_relationships();

create constraint trigger validate_project_participant_relationships
after insert or update or delete on public.project_participant_assignments
deferrable initially deferred
for each row execute function public.validate_project_relationships();

create function public.validate_person_deactivation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.active = new.active or new.active then
    return null;
  end if;

  if exists (
    select 1 from public.system_developer_assignments
    where person_id = new.id
      and effective_from <= transaction_timestamp()
      and (effective_to is null or effective_to > transaction_timestamp())
  ) or exists (
    select 1 from public.module_owner_assignments
    where person_id = new.id
      and effective_from <= transaction_timestamp()
      and (effective_to is null or effective_to > transaction_timestamp())
  ) or exists (
    select 1 from public.project_pmo_assignments
    where person_id = new.id
      and effective_from <= transaction_timestamp()
      and (effective_to is null or effective_to > transaction_timestamp())
  ) or exists (
    select 1 from public.project_participant_assignments
    where person_id = new.id
      and effective_from <= transaction_timestamp()
      and (effective_to is null or effective_to > transaction_timestamp())
  ) then
    raise exception 'Close all current assignments before deactivating a Person';
  end if;

  if exists (
    select 1 from public.profiles
    where person_id = new.id and active
  ) then
    raise exception 'Deactivate the Person account before deactivating the Person';
  end if;

  return null;
end;
$$;

create constraint trigger validate_person_deactivation
after update on public.people
deferrable initially deferred
for each row execute function public.validate_person_deactivation();

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
