create function public.create_project(input jsonb)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  project_id uuid := gen_random_uuid();
  actor_id uuid := auth.uid();
  officer_id uuid := (input ->> 'pmoOfficerId')::uuid;
  owner_id uuid := (input ->> 'ballOwnerId')::uuid;
  initial_state public.project_state := (input ->> 'state')::public.project_state;
begin
  if not (
    'administrator'::public.app_role = any(public.current_roles())
    or 'pmo_officer'::public.app_role = any(public.current_roles())
  ) then
    raise exception 'Permission denied';
  end if;

  if initial_state in ('Cancelled', 'Closed') then
    raise exception 'A new Project cannot begin terminal';
  end if;

  if not exists (
    select 1 from public.people where id = officer_id and active
  ) or not exists (
    select 1 from public.people where id = owner_id and active
  ) then
    raise exception 'Assignments require active People';
  end if;

  insert into public.projects (
    id,
    code,
    name,
    priority_id,
    scope,
    state,
    pmo_officer_id,
    ball_owner_id
  )
  values (
    project_id,
    input ->> 'code',
    input ->> 'name',
    (input ->> 'priorityId')::uuid,
    nullif(input ->> 'scope', ''),
    initial_state,
    officer_id,
    owner_id
  );

  insert into public.project_pmo_assignments (
    project_id,
    person_id,
    effective_from
  )
  values (project_id, officer_id, now());

  insert into public.project_participant_assignments (
    project_id,
    person_id,
    participant_group,
    effective_from
  )
  values (project_id, officer_id, 'PMO', now());

  if owner_id <> officer_id then
    raise exception 'Add the initial Ball Owner as a participant before creation';
  end if;

  insert into public.project_stages (
    project_id,
    template_stage_id,
    name,
    sort_order,
    detail_label,
    detail_help,
    detail_required,
    detail_multiline
  )
  select
    project_id,
    id,
    name,
    sort_order,
    detail_label,
    detail_help,
    detail_required,
    detail_multiline
  from public.workflow_template_stages
  where active
  order by sort_order;

  insert into public.project_events (
    project_id,
    event_type,
    effective_at,
    actor_id,
    payload,
    resulting_state,
    resulting_ball_owner_id,
    resulting_ball_owner_name
  )
  select
    project_id,
    'project_created',
    now(),
    actor_id,
    jsonb_build_object('code', input ->> 'code', 'name', input ->> 'name'),
    initial_state,
    owner_id,
    p.name
  from public.people as p
  where p.id = owner_id;

  return project_id;
end;
$$;

create function public.append_project_event(input jsonb)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  project_row public.projects%rowtype;
  event_id uuid := gen_random_uuid();
  event_kind public.project_event_type :=
    (input ->> 'eventType')::public.project_event_type;
  effective_time timestamptz := (input ->> 'effectiveAt')::timestamptz;
  owner_id uuid := (input ->> 'ballOwnerId')::uuid;
  next_state public.project_state;
  stage_id uuid;
  owner_name text;
begin
  select *
  into project_row
  from public.projects
  where id = (input ->> 'projectId')::uuid
  for update;

  if not found or not public.can_edit_project(project_row.id) then
    raise exception 'Permission denied';
  end if;

  if project_row.version <> (input ->> 'version')::bigint then
    raise exception 'CONFLICT: Project changed since this form loaded';
  end if;

  if project_row.state in ('Cancelled', 'Closed') then
    raise exception 'Terminal Projects cannot be changed';
  end if;

  if not exists (
    select 1
    from public.project_participant_assignments as assignment
    join public.people as person on person.id = assignment.person_id
    where assignment.project_id = project_row.id
      and assignment.person_id = owner_id
      and assignment.effective_to is null
      and person.active
  ) then
    raise exception 'Ball Owner must be an active Project Participant';
  end if;

  select name into owner_name from public.people where id = owner_id;
  next_state := coalesce(
    (input ->> 'resultingState')::public.project_state,
    project_row.state
  );
  stage_id := coalesce(
    (input ->> 'stageId')::uuid,
    project_row.current_stage_id
  );

  if next_state in ('Planned', 'Active') and (
    project_row.request_type_id is null
    or project_row.requester_id is null
    or coalesce(trim(project_row.scope), '') = ''
    or not exists (
      select 1
      from public.project_system_scopes
      where project_id = project_row.id
    )
  ) then
    raise exception 'Complete request, scope, affected areas, and participants first';
  end if;

  if event_kind = 'progress' then
    update public.project_stages
    set visited = true
    where id = stage_id and project_id = project_row.id;
  end if;

  insert into public.project_events (
    id,
    project_id,
    event_type,
    effective_at,
    actor_id,
    payload,
    resulting_state,
    resulting_stage_id,
    resulting_stage_label,
    resulting_ball_owner_id,
    resulting_ball_owner_name
  )
  select
    event_id,
    project_row.id,
    event_kind,
    effective_time,
    auth.uid(),
    input -> 'payload',
    next_state,
    stage_id,
    stage.name,
    owner_id,
    owner_name
  from (select 1) as singleton
  left join public.project_stages as stage on stage.id = stage_id;

  update public.projects
  set
    state = next_state,
    current_stage_id = case
      when event_kind = 'progress' then stage_id
      else current_stage_id
    end,
    ball_owner_id = owner_id,
    updated_at = now(),
    version = version + 1
  where id = project_row.id;

  return event_id;
end;
$$;

create function public.correct_project_event(input jsonb)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  original_event public.project_events%rowtype;
  event_id uuid := gen_random_uuid();
begin
  if not public.is_admin() then
    raise exception 'Only Administrators may correct history';
  end if;

  select *
  into original_event
  from public.project_events
  where id = (input ->> 'eventId')::uuid
  for update;

  if not found or original_event.supersedes_event_id is not null then
    raise exception 'Event cannot be corrected';
  end if;

  insert into public.project_events (
    id,
    project_id,
    event_type,
    effective_at,
    actor_id,
    payload,
    resulting_state,
    resulting_stage_id,
    resulting_stage_label,
    resulting_ball_owner_id,
    resulting_ball_owner_name,
    supersedes_event_id,
    correction_reason
  )
  values (
    event_id,
    original_event.project_id,
    'corrected',
    (input ->> 'effectiveAt')::timestamptz,
    auth.uid(),
    input -> 'payload',
    coalesce(
      (input ->> 'resultingState')::public.project_state,
      original_event.resulting_state
    ),
    coalesce(
      (input ->> 'stageId')::uuid,
      original_event.resulting_stage_id
    ),
    original_event.resulting_stage_label,
    coalesce(
      (input ->> 'ballOwnerId')::uuid,
      original_event.resulting_ball_owner_id
    ),
    original_event.resulting_ball_owner_name,
    original_event.id,
    input ->> 'reason'
  );

  return event_id;
end;
$$;

revoke all on function public.create_project(jsonb) from public, anon;
revoke all on function public.append_project_event(jsonb) from public, anon;
revoke all on function public.correct_project_event(jsonb) from public, anon;
grant execute on function public.create_project(jsonb) to authenticated, service_role;
grant execute on function public.append_project_event(jsonb) to authenticated, service_role;
grant execute on function public.correct_project_event(jsonb) to authenticated, service_role;

comment on function public.create_project(jsonb) is
  'Creates a project, its initial assignments and stages, and its first event atomically.';
comment on function public.append_project_event(jsonb) is
  'Appends an operational event and updates the current project projection atomically.';
comment on function public.correct_project_event(jsonb) is
  'Creates an Administrator-only superseding event without deleting history.';
