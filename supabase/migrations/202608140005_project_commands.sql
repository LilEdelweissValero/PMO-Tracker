create function public.assert_ball_owner(
  target_project_id uuid,
  target_person_id uuid,
  target_effective_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if target_person_id is null or not exists (
    select 1
    from public.project_participant_assignments as assignment
    join public.people as person on person.id = assignment.person_id
    where assignment.project_id = target_project_id
      and assignment.person_id = target_person_id
      and assignment.effective_from <= target_effective_at
      and (
        assignment.effective_to is null
        or assignment.effective_to > target_effective_at
      )
      and person.active
  ) then
    raise exception using
      errcode = '22023',
      message = 'Ball Owner must be an active Project Participant at the Effective timestamp';
  end if;
end;
$$;

create function public.update_project(input jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid := (input ->> 'projectId')::uuid;
  command_time timestamptz := statement_timestamp();
  before_project public.projects%rowtype;
  after_project public.projects%rowtype;
  requester_department text;
  participant jsonb;
  scope_row jsonb;
  reference_row jsonb;
  reference_updated boolean;
begin
  select * into before_project
  from public.projects
  where id = target_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if not public.can_edit_project(target_id) then
    raise exception using errcode = '42501', message = 'Permission denied';
  end if;

  if before_project.version <> (input ->> 'version')::bigint then
    raise exception using
      errcode = '40001',
      message = 'Project changed since this form loaded';
  end if;

  if before_project.state in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'Terminal Projects cannot be changed';
  end if;

  if input ? 'name' and (
    nullif(btrim(input ->> 'name'), '') is null
    or length(btrim(input ->> 'name')) > 160
  ) then
    raise exception using errcode = '22023', message = 'Valid Project Name is required';
  end if;

  if input ? 'priorityId' and not exists (
    select 1 from public.priorities
    where id = (input ->> 'priorityId')::uuid and active
  ) then
    raise exception using errcode = '22023', message = 'Priority is unavailable';
  end if;

  if input ? 'initiativeId' and input ->> 'initiativeId' is not null
    and not exists (
      select 1 from public.initiatives
      where id = (input ->> 'initiativeId')::uuid and active
    )
  then
    raise exception using errcode = '22023', message = 'Initiative is unavailable';
  end if;

  if input ? 'requestTypeId' and input ->> 'requestTypeId' is not null
    and not exists (
      select 1 from public.request_types
      where id = (input ->> 'requestTypeId')::uuid and active
    )
  then
    raise exception using errcode = '22023', message = 'Request Type is unavailable';
  end if;

  if input ? 'initiatorTypeId' and input ->> 'initiatorTypeId' is not null
    and not exists (
      select 1 from public.initiator_types
      where id = (input ->> 'initiatorTypeId')::uuid and active
    )
  then
    raise exception using errcode = '22023', message = 'Initiator Type is unavailable';
  end if;

  if input ? 'requesterId' then
    if input ->> 'requesterId' is null then
      requester_department := null;
    else
      select department.name
      into requester_department
      from public.people as person
      join public.departments as department on department.id = person.department_id
      where person.id = (input ->> 'requesterId')::uuid and person.active;

      if not found then
        raise exception using errcode = '22023', message = 'Requester is unavailable';
      end if;
    end if;
  else
    requester_department := before_project.requester_department_name;
  end if;

  update public.projects
  set
    name = case when input ? 'name' then btrim(input ->> 'name') else name end,
    initiative_id = case
      when input ? 'initiativeId' then (input ->> 'initiativeId')::uuid
      else initiative_id
    end,
    priority_id = case
      when input ? 'priorityId' then (input ->> 'priorityId')::uuid
      else priority_id
    end,
    scope = case
      when input ? 'scope' then nullif(btrim(input ->> 'scope'), '')
      else scope
    end,
    request_type_id = case
      when input ? 'requestTypeId' then (input ->> 'requestTypeId')::uuid
      else request_type_id
    end,
    initiator_type_id = case
      when input ? 'initiatorTypeId' then (input ->> 'initiatorTypeId')::uuid
      else initiator_type_id
    end,
    requester_id = case
      when input ? 'requesterId' then (input ->> 'requesterId')::uuid
      else requester_id
    end,
    requester_department_name = requester_department,
    updated_at = command_time,
    version = version + 1
  where id = target_id;

  if input ? 'participants' then
    if jsonb_typeof(input -> 'participants') <> 'array' then
      raise exception using errcode = '22023', message = 'Participants must be an array';
    end if;

    if exists (
      select 1
      from jsonb_array_elements(input -> 'participants') as item
      group by item ->> 'personId'
      having count(*) > 1
    ) then
      raise exception using errcode = '22023', message = 'A Person may appear only once in Participants';
    end if;

    update public.project_participant_assignments as assignment
    set effective_to = command_time
    where assignment.project_id = target_id
      and assignment.effective_to is null
      and not exists (
        select 1
        from jsonb_array_elements(input -> 'participants') as item
        where (item ->> 'personId')::uuid = assignment.person_id
          and (item ->> 'group')::public.participant_group = assignment.participant_group
      );

    for participant in
      select value from jsonb_array_elements(input -> 'participants')
    loop
      if not exists (
        select 1 from public.people
        where id = (participant ->> 'personId')::uuid and active
      ) then
        raise exception using errcode = '22023', message = 'Participants must be active People';
      end if;

      if not exists (
        select 1
        from public.project_participant_assignments as assignment
        where assignment.project_id = target_id
          and assignment.person_id = (participant ->> 'personId')::uuid
          and assignment.participant_group =
            (participant ->> 'group')::public.participant_group
          and assignment.effective_to is null
      ) then
        insert into public.project_participant_assignments (
          project_id,
          person_id,
          participant_group,
          effective_from
        ) values (
          target_id,
          (participant ->> 'personId')::uuid,
          (participant ->> 'group')::public.participant_group,
          command_time
        );
      end if;
    end loop;

    if not exists (
      select 1
      from public.project_participant_assignments as assignment
      where assignment.project_id = target_id
        and assignment.person_id = before_project.pmo_officer_id
        and assignment.participant_group = 'PMO'
        and assignment.effective_to is null
    ) then
      raise exception using errcode = '22023', message = 'The accountable PMO Officer must remain a PMO Participant';
    end if;

    if not exists (
      select 1
      from public.project_participant_assignments as assignment
      where assignment.project_id = target_id
        and assignment.person_id = before_project.ball_owner_id
        and assignment.effective_to is null
    ) then
      raise exception using errcode = '22023', message = 'The current Ball Owner must remain a Participant';
    end if;
  end if;

  if input ? 'systemScopes' then
    if jsonb_typeof(input -> 'systemScopes') <> 'array' then
      raise exception using errcode = '22023', message = 'System scopes must be an array';
    end if;

    delete from public.project_system_scopes where project_id = target_id;

    for scope_row in
      select value from jsonb_array_elements(input -> 'systemScopes')
    loop
      if not exists (
        select 1 from public.systems
        where id = (scope_row ->> 'systemId')::uuid and active
      ) then
        raise exception using errcode = '22023', message = 'Affected System is unavailable';
      end if;

      if not coalesce((scope_row ->> 'entireSystem')::boolean, false)
        and not exists (
          select 1 from public.modules
          where id = (scope_row ->> 'moduleId')::uuid
            and system_id = (scope_row ->> 'systemId')::uuid
            and active
        )
      then
        raise exception using errcode = '22023', message = 'Affected Module is unavailable for the selected System';
      end if;

      insert into public.project_system_scopes (
        project_id,
        system_id,
        entire_system,
        module_id
      ) values (
        target_id,
        (scope_row ->> 'systemId')::uuid,
        coalesce((scope_row ->> 'entireSystem')::boolean, false),
        case
          when coalesce((scope_row ->> 'entireSystem')::boolean, false) then null
          else (scope_row ->> 'moduleId')::uuid
        end
      );
    end loop;
  end if;

  if input ? 'references' then
    if jsonb_typeof(input -> 'references') <> 'array' then
      raise exception using errcode = '22023', message = 'References must be an array';
    end if;

    update public.project_references
    set active = false
    where project_id = target_id and active;

    for reference_row in
      select value from jsonb_array_elements(input -> 'references')
    loop
      if not exists (
        select 1 from public.reference_types
        where id = (reference_row ->> 'typeId')::uuid and active
      ) then
        raise exception using errcode = '22023', message = 'Reference Type is unavailable';
      end if;

      reference_updated := false;
      if reference_row ? 'id' and reference_row ->> 'id' is not null then
        update public.project_references
        set
          reference_type_id = (reference_row ->> 'typeId')::uuid,
          label = btrim(reference_row ->> 'label'),
          url = btrim(reference_row ->> 'url'),
          active = true
        where id = (reference_row ->> 'id')::uuid
          and project_id = target_id;
        reference_updated := found;
      end if;

      if not reference_updated then
        insert into public.project_references (
          project_id,
          reference_type_id,
          label,
          url
        ) values (
          target_id,
          (reference_row ->> 'typeId')::uuid,
          btrim(reference_row ->> 'label'),
          btrim(reference_row ->> 'url')
        );
      end if;
    end loop;
  end if;

  select * into after_project from public.projects where id = target_id;

  if after_project.state in ('Planned', 'Active') then
    perform public.assert_project_complete(target_id);
  end if;

  insert into public.project_events (
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
    target_id,
    'project_changed',
    command_time,
    auth.uid(),
    jsonb_build_object('input', input),
    after_project.state,
    after_project.current_stage_id,
    stage.name,
    after_project.ball_owner_id,
    owner.name
  from (select 1) as singleton
  left join public.project_stages as stage
    on stage.id = after_project.current_stage_id
   and stage.project_id = target_id
  join public.people as owner on owner.id = after_project.ball_owner_id;

  perform public.record_project_audit(
    target_id,
    'project_changed',
    to_jsonb(before_project),
    jsonb_build_object('project', to_jsonb(after_project), 'input', input)
  );
end;
$$;

create function public.assert_project_complete(target_project_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  project_row public.projects%rowtype;
begin
  select * into project_row
  from public.projects
  where id = target_project_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if project_row.request_type_id is null
    or project_row.initiator_type_id is null
    or project_row.requester_id is null
    or nullif(btrim(project_row.requester_department_name), '') is null
    or nullif(btrim(project_row.scope), '') is null
    or not exists (
      select 1 from public.project_system_scopes
      where project_id = target_project_id
    )
  then
    raise exception using
      errcode = '22023',
      message = 'Planned and Active Projects require request, requester, scope, and affected areas';
  end if;

  if exists (
    select 1
    from (
      select distinct system_id
      from public.project_system_scopes
      where project_id = target_project_id
    ) as affected_system
    where not exists (
      select 1
      from public.system_developer_assignments as developer
      join public.project_participant_assignments as participant
        on participant.project_id = target_project_id
       and participant.person_id = developer.person_id
       and participant.participant_group = 'Developer'
       and participant.effective_from <= statement_timestamp()
       and (
         participant.effective_to is null
         or participant.effective_to > statement_timestamp()
       )
      join public.people as person
        on person.id = developer.person_id and person.active
      where developer.system_id = affected_system.system_id
        and developer.effective_from <= statement_timestamp()
        and (
          developer.effective_to is null
          or developer.effective_to > statement_timestamp()
        )
    )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Each affected System requires a current Developer Project Participant';
  end if;

  if exists (
    select 1
    from public.project_system_scopes as scope
    where scope.project_id = target_project_id
      and scope.module_id is not null
      and not exists (
        select 1
        from public.module_owner_assignments as module_owner
        join public.project_participant_assignments as participant
          on participant.project_id = target_project_id
         and participant.person_id = module_owner.person_id
         and participant.participant_group = 'System Owner'
         and participant.effective_from <= statement_timestamp()
         and (
           participant.effective_to is null
           or participant.effective_to > statement_timestamp()
         )
        join public.people as person
          on person.id = module_owner.person_id and person.active
        where module_owner.module_id = scope.module_id
          and module_owner.effective_from <= statement_timestamp()
          and (
            module_owner.effective_to is null
            or module_owner.effective_to > statement_timestamp()
          )
      )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Each affected Module requires its current System Owner as a Project Participant';
  end if;
end;
$$;

create function public.record_project_audit(
  target_project_id uuid,
  target_action text,
  target_before jsonb,
  target_after jsonb
)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.audit_log (
    entity_type,
    entity_id,
    action,
    before_data,
    after_data,
    actor_id
  ) values (
    'project',
    target_project_id,
    target_action,
    target_before,
    target_after,
    (select auth.uid())
  );
$$;

create function public.replay_project_projection(target_project_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  latest_event public.project_events%rowtype;
begin
  select event.*
  into latest_event
  from public.project_events as event
  where event.project_id = target_project_id
    and event.event_type in (
      'project_created',
      'progress',
      'bump',
      'state_changed',
      'ball_transferred',
      'corrected'
    )
    and not exists (
      select 1
      from public.project_events as correction
      where correction.supersedes_event_id = event.id
    )
  order by event.effective_at desc, event.recorded_at desc, event.id desc
  limit 1;

  if not found then
    raise exception using
      errcode = '23514',
      message = 'Project projection requires at least one effective event';
  end if;

  update public.projects
  set
    state = latest_event.resulting_state,
    current_stage_id = latest_event.resulting_stage_id,
    ball_owner_id = latest_event.resulting_ball_owner_id,
    updated_at = statement_timestamp(),
    version = version + 1
  where id = target_project_id;
end;
$$;

create function public.create_project(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_project_id uuid := gen_random_uuid();
  actor_id uuid := auth.uid();
  officer_id uuid := (input ->> 'pmoOfficerId')::uuid;
  owner_id uuid := (input ->> 'ballOwnerId')::uuid;
  initial_state public.project_state := (input ->> 'state')::public.project_state;
  command_time timestamptz := statement_timestamp();
  requester_department text;
  participant jsonb;
  scope_row jsonb;
  reference_row jsonb;
  created_project public.projects%rowtype;
begin
  if not (
    'administrator'::public.app_role = any(public.current_roles())
    or 'pmo_officer'::public.app_role = any(public.current_roles())
  ) then
    raise exception using errcode = '42501', message = 'Permission denied';
  end if;

  if actor_id is null then
    raise exception using errcode = '42501', message = 'Authenticated actor required';
  end if;

  if nullif(btrim(input ->> 'code'), '') is null
    or length(btrim(input ->> 'code')) > 40
    or (input ->> 'code') like '%/%'
    or nullif(btrim(input ->> 'name'), '') is null
    or length(btrim(input ->> 'name')) > 160
  then
    raise exception using errcode = '22023', message = 'Valid Project Code and Name are required';
  end if;

  if initial_state in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'A new Project cannot begin terminal';
  end if;

  if not exists (
    select 1
    from public.priorities
    where id = (input ->> 'priorityId')::uuid and active
  ) then
    raise exception using errcode = '22023', message = 'An active Priority is required';
  end if;

  if not exists (
    select 1
    from public.people as person
    join public.profiles as profile
      on profile.person_id = person.id and profile.active
    join public.profile_roles as profile_role
      on profile_role.profile_id = profile.id
     and profile_role.role = 'pmo_officer'
    where person.id = officer_id and person.active
  ) then
    raise exception using
      errcode = '22023',
      message = 'PMO Officer must be an active Person with an active PMO account';
  end if;

  if not exists (
    select 1 from public.people where id = owner_id and active
  ) then
    raise exception using errcode = '22023', message = 'Initial Ball Owner must be active';
  end if;

  if input ? 'initiativeId' and input ->> 'initiativeId' is not null
    and not exists (
      select 1 from public.initiatives
      where id = (input ->> 'initiativeId')::uuid and active
    )
  then
    raise exception using errcode = '22023', message = 'Initiative is unavailable';
  end if;

  if input ? 'requestTypeId' and input ->> 'requestTypeId' is not null
    and not exists (
      select 1 from public.request_types
      where id = (input ->> 'requestTypeId')::uuid and active
    )
  then
    raise exception using errcode = '22023', message = 'Request Type is unavailable';
  end if;

  if input ? 'initiatorTypeId' and input ->> 'initiatorTypeId' is not null
    and not exists (
      select 1 from public.initiator_types
      where id = (input ->> 'initiatorTypeId')::uuid and active
    )
  then
    raise exception using errcode = '22023', message = 'Initiator Type is unavailable';
  end if;

  if input ? 'requesterId' and input ->> 'requesterId' is not null then
    select department.name
    into requester_department
    from public.people as person
    join public.departments as department on department.id = person.department_id
    where person.id = (input ->> 'requesterId')::uuid and person.active;

    if not found then
      raise exception using errcode = '22023', message = 'Requester is unavailable';
    end if;
  end if;

  insert into public.projects (
    id,
    code,
    name,
    initiative_id,
    priority_id,
    scope,
    state,
    pmo_officer_id,
    ball_owner_id,
    request_type_id,
    initiator_type_id,
    requester_id,
    requester_department_name
  ) values (
    new_project_id,
    btrim(input ->> 'code'),
    btrim(input ->> 'name'),
    (input ->> 'initiativeId')::uuid,
    (input ->> 'priorityId')::uuid,
    nullif(btrim(input ->> 'scope'), ''),
    initial_state,
    officer_id,
    owner_id,
    (input ->> 'requestTypeId')::uuid,
    (input ->> 'initiatorTypeId')::uuid,
    (input ->> 'requesterId')::uuid,
    requester_department
  );

  insert into public.project_pmo_assignments (
    project_id,
    person_id,
    effective_from
  ) values (new_project_id, officer_id, command_time);

  if input ? 'participants' then
    if jsonb_typeof(input -> 'participants') <> 'array' then
      raise exception using errcode = '22023', message = 'Participants must be an array';
    end if;

    if exists (
      select 1
      from jsonb_array_elements(input -> 'participants') as item
      group by item ->> 'personId'
      having count(*) > 1
    ) then
      raise exception using errcode = '22023', message = 'A Person may appear only once in Participants';
    end if;

    for participant in
      select value from jsonb_array_elements(input -> 'participants')
    loop
      if not exists (
        select 1
        from public.people
        where id = (participant ->> 'personId')::uuid and active
      ) then
        raise exception using errcode = '22023', message = 'Participants must be active People';
      end if;

      insert into public.project_participant_assignments (
        project_id,
        person_id,
        participant_group,
        effective_from
      ) values (
        new_project_id,
        (participant ->> 'personId')::uuid,
        (participant ->> 'group')::public.participant_group,
        command_time
      );
    end loop;
  end if;

  if exists (
    select 1
    from public.project_participant_assignments as assignment
    where assignment.project_id = new_project_id
      and assignment.person_id = officer_id
      and assignment.participant_group <> 'PMO'
      and assignment.effective_to is null
  ) then
    raise exception using errcode = '22023', message = 'The accountable PMO Officer must be in the PMO Participant group';
  end if;

  if not exists (
    select 1
    from public.project_participant_assignments as assignment
    where assignment.project_id = new_project_id
      and assignment.person_id = officer_id
      and assignment.effective_to is null
  ) then
    insert into public.project_participant_assignments (
      project_id,
      person_id,
      participant_group,
      effective_from
    ) values (new_project_id, officer_id, 'PMO', command_time);
  end if;

  if not exists (
    select 1
    from public.project_participant_assignments as assignment
    where assignment.project_id = new_project_id
      and assignment.person_id = owner_id
      and assignment.effective_to is null
  ) then
    raise exception using errcode = '22023', message = 'Initial Ball Owner must be included as a Project Participant';
  end if;

  if input ? 'systemScopes' then
    if jsonb_typeof(input -> 'systemScopes') <> 'array' then
      raise exception using errcode = '22023', message = 'System scopes must be an array';
    end if;

    for scope_row in
      select value from jsonb_array_elements(input -> 'systemScopes')
    loop
      if not exists (
        select 1 from public.systems
        where id = (scope_row ->> 'systemId')::uuid and active
      ) then
        raise exception using errcode = '22023', message = 'Affected System is unavailable';
      end if;

      if not coalesce((scope_row ->> 'entireSystem')::boolean, false)
        and not exists (
          select 1 from public.modules
          where id = (scope_row ->> 'moduleId')::uuid
            and system_id = (scope_row ->> 'systemId')::uuid
            and active
        )
      then
        raise exception using errcode = '22023', message = 'Affected Module is unavailable for the selected System';
      end if;

      insert into public.project_system_scopes (
        project_id,
        system_id,
        entire_system,
        module_id
      ) values (
        new_project_id,
        (scope_row ->> 'systemId')::uuid,
        coalesce((scope_row ->> 'entireSystem')::boolean, false),
        case
          when coalesce((scope_row ->> 'entireSystem')::boolean, false) then null
          else (scope_row ->> 'moduleId')::uuid
        end
      );
    end loop;
  end if;

  if input ? 'references' then
    if jsonb_typeof(input -> 'references') <> 'array' then
      raise exception using errcode = '22023', message = 'References must be an array';
    end if;

    for reference_row in
      select value from jsonb_array_elements(input -> 'references')
    loop
      if not exists (
        select 1 from public.reference_types
        where id = (reference_row ->> 'typeId')::uuid and active
      ) then
        raise exception using errcode = '22023', message = 'Reference Type is unavailable';
      end if;

      insert into public.project_references (
        project_id,
        reference_type_id,
        label,
        url
      ) values (
        new_project_id,
        (reference_row ->> 'typeId')::uuid,
        btrim(reference_row ->> 'label'),
        btrim(reference_row ->> 'url')
      );
    end loop;
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
    new_project_id,
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

  if initial_state in ('Planned', 'Active') then
    perform public.assert_project_complete(new_project_id);
  end if;

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
    new_project_id,
    'project_created',
    command_time,
    actor_id,
    jsonb_build_object(
      'code', btrim(input ->> 'code'),
      'name', btrim(input ->> 'name'),
      'input', input
    ),
    initial_state,
    owner_id,
    person.name
  from public.people as person
  where person.id = owner_id;

  select * into created_project
  from public.projects
  where id = new_project_id;
  perform public.record_project_audit(
    new_project_id,
    'project_created',
    null,
    jsonb_build_object('project', to_jsonb(created_project), 'input', input)
  );

  return new_project_id;
end;
$$;

create function public.reassign_project_pmo(input jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid := (input ->> 'projectId')::uuid;
  new_officer_id uuid := (input ->> 'pmoOfficerId')::uuid;
  command_time timestamptz := statement_timestamp();
  before_project public.projects%rowtype;
  after_project public.projects%rowtype;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Only Administrators may reassign the PMO Officer';
  end if;

  select * into before_project
  from public.projects
  where id = target_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if before_project.version <> (input ->> 'version')::bigint then
    raise exception using errcode = '40001', message = 'Project changed since this form loaded';
  end if;

  if before_project.state in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'Terminal Projects cannot be changed';
  end if;

  if new_officer_id = before_project.pmo_officer_id then
    raise exception using errcode = '22023', message = 'Select a different PMO Officer';
  end if;

  if not exists (
    select 1
    from public.people as person
    join public.profiles as profile
      on profile.person_id = person.id and profile.active
    join public.profile_roles as profile_role
      on profile_role.profile_id = profile.id
     and profile_role.role = 'pmo_officer'
    where person.id = new_officer_id and person.active
  ) then
    raise exception using
      errcode = '22023',
      message = 'New PMO Officer must be an active Person with an active PMO account';
  end if;

  update public.project_pmo_assignments
  set effective_to = command_time
  where project_id = target_id and effective_to is null;

  insert into public.project_pmo_assignments (
    project_id,
    person_id,
    effective_from
  ) values (target_id, new_officer_id, command_time);

  update public.project_participant_assignments
  set effective_to = command_time
  where project_id = target_id
    and person_id = new_officer_id
    and participant_group <> 'PMO'
    and effective_to is null;

  if not exists (
    select 1
    from public.project_participant_assignments
    where project_id = target_id
      and person_id = new_officer_id
      and participant_group = 'PMO'
      and effective_to is null
  ) then
    insert into public.project_participant_assignments (
      project_id,
      person_id,
      participant_group,
      effective_from
    ) values (target_id, new_officer_id, 'PMO', command_time);
  end if;

  update public.projects
  set
    pmo_officer_id = new_officer_id,
    updated_at = command_time,
    version = version + 1
  where id = target_id;

  select * into after_project from public.projects where id = target_id;

  insert into public.project_events (
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
    target_id,
    'pmo_reassigned',
    command_time,
    auth.uid(),
    jsonb_build_object(
      'fromPersonId', before_project.pmo_officer_id,
      'toPersonId', new_officer_id,
      'reason', nullif(btrim(input ->> 'reason'), '')
    ),
    after_project.state,
    after_project.current_stage_id,
    stage.name,
    after_project.ball_owner_id,
    owner.name
  from (select 1) as singleton
  left join public.project_stages as stage
    on stage.id = after_project.current_stage_id
  join public.people as owner on owner.id = after_project.ball_owner_id;

  perform public.record_project_audit(
    target_id,
    'pmo_reassigned',
    to_jsonb(before_project),
    jsonb_build_object('project', to_jsonb(after_project), 'input', input)
  );
end;
$$;

create function public.configure_project_stage(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid := (input ->> 'projectId')::uuid;
  target_stage_id uuid := (input ->> 'stageId')::uuid;
  command_action text := input ->> 'action';
  command_time timestamptz := statement_timestamp();
  project_row public.projects%rowtype;
  before_data jsonb;
  stage_ids uuid[];
  supplied_count integer;
  active_count integer;
begin
  select * into project_row
  from public.projects
  where id = target_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if not public.can_edit_project(target_id) then
    raise exception using errcode = '42501', message = 'Permission denied';
  end if;

  if project_row.version <> (input ->> 'version')::bigint then
    raise exception using errcode = '40001', message = 'Project changed since this form loaded';
  end if;

  if project_row.state in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'Terminal Projects cannot be changed';
  end if;

  select coalesce(jsonb_agg(to_jsonb(stage) order by stage.sort_order), '[]'::jsonb)
  into before_data
  from public.project_stages as stage
  where stage.project_id = target_id;

  if command_action = 'add' then
    if nullif(btrim(input ->> 'name'), '') is null then
      raise exception using errcode = '22023', message = 'Stage Name is required';
    end if;

    target_stage_id := gen_random_uuid();

    update public.project_stages
    set sort_order = -sort_order
    where project_id = target_id and active;

    update public.project_stages
    set sort_order = case
      when -sort_order >= (input ->> 'sortOrder')::integer
        then -sort_order + 1
      else -sort_order
    end
    where project_id = target_id and active;

    insert into public.project_stages (
      id,
      project_id,
      name,
      sort_order,
      detail_label,
      detail_help,
      detail_required,
      detail_multiline
    ) values (
      target_stage_id,
      target_id,
      btrim(input ->> 'name'),
      (input ->> 'sortOrder')::integer,
      nullif(btrim(input ->> 'detailLabel'), ''),
      nullif(btrim(input ->> 'detailHelp'), ''),
      coalesce((input ->> 'detailRequired')::boolean, false),
      coalesce((input ->> 'detailMultiline')::boolean, false)
    );
  elsif command_action = 'update' then
    update public.project_stages
    set
      name = coalesce(nullif(btrim(input ->> 'name'), ''), name),
      detail_label = case
        when input ? 'detailLabel' then nullif(btrim(input ->> 'detailLabel'), '')
        else detail_label
      end,
      detail_help = case
        when input ? 'detailHelp' then nullif(btrim(input ->> 'detailHelp'), '')
        else detail_help
      end,
      detail_required = case
        when input ? 'detailRequired' then (input ->> 'detailRequired')::boolean
        else detail_required
      end,
      detail_multiline = case
        when input ? 'detailMultiline' then (input ->> 'detailMultiline')::boolean
        else detail_multiline
      end
    where id = target_stage_id and project_id = target_id and active;

    if not found then
      raise exception using errcode = 'P0002', message = 'Project Stage not found';
    end if;
  elsif command_action = 'remove' then
    if target_stage_id = project_row.current_stage_id then
      raise exception using errcode = '22023', message = 'Current Stage cannot be removed';
    end if;

    update public.project_stages
    set
      active = false,
      sort_order = (
        select coalesce(max(other.sort_order), 0) + 1
        from public.project_stages as other
        where other.project_id = target_id
      )
    where id = target_stage_id
      and project_id = target_id
      and active
      and not visited;

    if not found then
      raise exception using errcode = '22023', message = 'Only an upcoming, unvisited Stage may be removed';
    end if;
  elsif command_action = 'reorder' then
    if jsonb_typeof(input -> 'stageIds') <> 'array' then
      raise exception using errcode = '22023', message = 'Stage order must be an array';
    end if;

    select
      array_agg((item.value #>> '{}')::uuid order by item.ordinality),
      count(*),
      count(distinct item.value #>> '{}')
    into stage_ids, supplied_count, active_count
    from jsonb_array_elements(input -> 'stageIds') with ordinality as item(value, ordinality);

    if supplied_count <> active_count then
      raise exception using errcode = '22023', message = 'Stage order contains duplicates';
    end if;

    select count(*) into active_count
    from public.project_stages
    where project_id = target_id and active;

    if supplied_count <> active_count or exists (
      select 1
      from unnest(stage_ids) as supplied(stage_id)
      where not exists (
        select 1 from public.project_stages
        where id = supplied.stage_id and project_id = target_id and active
      )
    ) then
      raise exception using errcode = '22023', message = 'Stage order must include every active Project Stage exactly once';
    end if;

    update public.project_stages
    set sort_order = -sort_order
    where project_id = target_id and active;

    update public.project_stages as stage
    set sort_order = ordered.ordinality
    from unnest(stage_ids) with ordinality as ordered(stage_id, ordinality)
    where stage.id = ordered.stage_id and stage.project_id = target_id;
  else
    raise exception using errcode = '22023', message = 'Unsupported Stage action';
  end if;

  update public.projects
  set updated_at = command_time, version = version + 1
  where id = target_id;

  insert into public.project_events (
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
    target_id,
    'workflow_changed',
    command_time,
    auth.uid(),
    jsonb_build_object('action', command_action, 'input', input),
    project_row.state,
    project_row.current_stage_id,
    current_stage.name,
    project_row.ball_owner_id,
    owner.name
  from (select 1) as singleton
  left join public.project_stages as current_stage
    on current_stage.id = project_row.current_stage_id
  join public.people as owner on owner.id = project_row.ball_owner_id;

  perform public.record_project_audit(
    target_id,
    'workflow_changed',
    before_data,
    jsonb_build_object('action', command_action, 'input', input)
  );

  return target_stage_id;
end;
$$;

create function public.revise_stage_plan(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid := (input ->> 'projectId')::uuid;
  target_stage_id uuid := (input ->> 'stageId')::uuid;
  revision_id uuid := gen_random_uuid();
  effective_time timestamptz := (input ->> 'effectiveAt')::timestamptz;
  project_row public.projects%rowtype;
  previous_revision jsonb;
begin
  select * into project_row
  from public.projects
  where id = target_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if not public.can_edit_project(target_id) then
    raise exception using errcode = '42501', message = 'Permission denied';
  end if;

  if project_row.version <> (input ->> 'version')::bigint then
    raise exception using errcode = '40001', message = 'Project changed since this form loaded';
  end if;

  if project_row.state in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'Terminal Projects cannot be changed';
  end if;

  if nullif(btrim(input ->> 'reason'), '') is null or effective_time is null then
    raise exception using errcode = '22023', message = 'Plan revision reason and Effective timestamp are required';
  end if;

  if not exists (
    select 1 from public.project_stages
    where id = target_stage_id and project_id = target_id and active
  ) then
    raise exception using errcode = 'P0002', message = 'Project Stage not found';
  end if;

  select to_jsonb(revision)
  into previous_revision
  from public.stage_plan_revisions as revision
  where revision.project_id = target_id
    and revision.project_stage_id = target_stage_id
  order by revision.effective_at desc, revision.recorded_at desc, revision.id desc
  limit 1;

  insert into public.stage_plan_revisions (
    id,
    project_id,
    project_stage_id,
    planned_date,
    reason,
    effective_at,
    actor_id
  ) values (
    revision_id,
    target_id,
    target_stage_id,
    (input ->> 'plannedDate')::date,
    btrim(input ->> 'reason'),
    effective_time,
    auth.uid()
  );

  update public.projects
  set updated_at = statement_timestamp(), version = version + 1
  where id = target_id;

  insert into public.project_events (
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
    target_id,
    'plan_revised',
    effective_time,
    auth.uid(),
    jsonb_build_object(
      'stageId', target_stage_id,
      'plannedDate', input ->> 'plannedDate',
      'reason', btrim(input ->> 'reason')
    ),
    project_row.state,
    project_row.current_stage_id,
    current_stage.name,
    project_row.ball_owner_id,
    owner.name
  from (select 1) as singleton
  left join public.project_stages as current_stage
    on current_stage.id = project_row.current_stage_id
  join public.people as owner on owner.id = project_row.ball_owner_id;

  perform public.record_project_audit(
    target_id,
    'plan_revised',
    previous_revision,
    jsonb_build_object('revisionId', revision_id, 'input', input)
  );

  return revision_id;
end;
$$;

create function public.append_project_event(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid := (input ->> 'projectId')::uuid;
  event_id uuid := gen_random_uuid();
  event_kind public.project_event_type :=
    (input ->> 'eventType')::public.project_event_type;
  effective_time timestamptz := (input ->> 'effectiveAt')::timestamptz;
  owner_id uuid;
  next_state public.project_state;
  stage_id uuid;
  stage_row public.project_stages%rowtype;
  current_sort integer;
  expected_next_stage_id uuid;
  project_row public.projects%rowtype;
  after_project public.projects%rowtype;
begin
  select * into project_row
  from public.projects
  where id = target_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if not public.can_edit_project(target_id) then
    raise exception using errcode = '42501', message = 'Permission denied';
  end if;

  if project_row.version <> (input ->> 'version')::bigint then
    raise exception using errcode = '40001', message = 'Project changed since this form loaded';
  end if;

  if project_row.state in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'Terminal Projects cannot be changed';
  end if;

  if event_kind not in ('progress', 'bump', 'state_changed', 'ball_transferred') then
    raise exception using errcode = '22023', message = 'Unsupported operational event type';
  end if;

  if effective_time is null then
    raise exception using errcode = '22023', message = 'Effective timestamp is required';
  end if;

  owner_id := coalesce(
    (input ->> 'resultingBallOwnerId')::uuid,
    project_row.ball_owner_id
  );
  perform public.assert_ball_owner(target_id, owner_id, effective_time);

  if event_kind = 'state_changed' then
    next_state := (input ->> 'resultingState')::public.project_state;
    if next_state is null or next_state = project_row.state then
      raise exception using errcode = '22023', message = 'Select a different resulting State';
    end if;
    if next_state = 'Closed' then
      raise exception using errcode = '22023', message = 'Use the Close Project command with a closeout assessment';
    end if;
    if next_state in ('On Hold', 'Cancelled')
      and nullif(btrim(input -> 'payload' ->> 'reason'), '') is null
    then
      raise exception using errcode = '22023', message = 'On Hold and Cancelled require a reason';
    end if;
  else
    next_state := project_row.state;
    if input ? 'resultingState'
      and (input ->> 'resultingState')::public.project_state <> project_row.state
    then
      raise exception using errcode = '22023', message = 'Only a State-change command may change State';
    end if;
  end if;

  if next_state in ('Planned', 'Active') then
    perform public.assert_project_complete(target_id);
  end if;

  if event_kind = 'progress' then
    stage_id := (input ->> 'stageId')::uuid;
    select * into stage_row
    from public.project_stages
    where id = stage_id and project_id = target_id and active;

    if not found then
      raise exception using errcode = '22023', message = 'Destination Stage is unavailable';
    end if;

    if nullif(btrim(input -> 'payload' ->> 'summary'), '') is null then
      raise exception using errcode = '22023', message = 'Progress summary is required';
    end if;

    if stage_row.detail_required
      and nullif(btrim(input -> 'payload' ->> 'stageDetail'), '') is null
    then
      raise exception using errcode = '22023', message = 'Required Stage Detail is missing';
    end if;

    if project_row.current_stage_id is null then
      select id into expected_next_stage_id
      from public.project_stages
      where project_id = target_id and active
      order by sort_order
      limit 1;
    else
      select sort_order into current_sort
      from public.project_stages
      where id = project_row.current_stage_id and project_id = target_id;

      select id into expected_next_stage_id
      from public.project_stages
      where project_id = target_id and active and sort_order > current_sort
      order by sort_order
      limit 1;
    end if;

    if stage_id is distinct from expected_next_stage_id
      and nullif(btrim(input -> 'payload' ->> 'transitionReason'), '') is null
    then
      raise exception using
        errcode = '22023',
        message = 'A non-sequential Stage transition requires an explanation';
    end if;

    update public.project_stages set visited = true where id = stage_id;
  else
    stage_id := project_row.current_stage_id;
  end if;

  if event_kind = 'bump'
    and nullif(btrim(input -> 'payload' ->> 'text'), '') is null
  then
    raise exception using errcode = '22023', message = 'Bump text is required';
  end if;

  if event_kind = 'ball_transferred' and owner_id = project_row.ball_owner_id then
    raise exception using errcode = '22023', message = 'Select a different Ball Owner';
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
    target_id,
    event_kind,
    effective_time,
    auth.uid(),
    coalesce(input -> 'payload', '{}'::jsonb),
    next_state,
    stage_id,
    stage.name,
    owner_id,
    owner.name
  from (select 1) as singleton
  left join public.project_stages as stage
    on stage.id = stage_id and stage.project_id = target_id
  join public.people as owner on owner.id = owner_id;

  perform public.replay_project_projection(target_id);
  select * into after_project from public.projects where id = target_id;

  perform public.record_project_audit(
    target_id,
    event_kind::text,
    to_jsonb(project_row),
    jsonb_build_object(
      'project', to_jsonb(after_project),
      'eventId', event_id,
      'input', input
    )
  );

  return event_id;
end;
$$;

create function public.close_project(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid := (input ->> 'projectId')::uuid;
  event_id uuid := gen_random_uuid();
  assessment_id uuid;
  effective_time timestamptz := (input ->> 'effectiveAt')::timestamptz;
  project_row public.projects%rowtype;
  after_project public.projects%rowtype;
begin
  select * into project_row
  from public.projects
  where id = target_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if not public.can_edit_project(target_id) then
    raise exception using errcode = '42501', message = 'Permission denied';
  end if;

  if project_row.version <> (input ->> 'version')::bigint then
    raise exception using errcode = '40001', message = 'Project changed since this form loaded';
  end if;

  if project_row.state in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'Terminal Projects cannot be changed';
  end if;

  if effective_time is null
    or jsonb_typeof(input -> 'closeout') <> 'object'
    or nullif(btrim(input -> 'closeout' ->> 'dodExplanation'), '') is null
    or nullif(btrim(input -> 'closeout' ->> 'methodologyExplanation'), '') is null
    or nullif(btrim(input -> 'closeout' ->> 'documentationExplanation'), '') is null
  then
    raise exception using errcode = '22023', message = 'A complete Closeout Assessment is required';
  end if;

  insert into public.closeout_assessments (
    project_id,
    dod_met,
    dod_explanation,
    methodology_compliant,
    methodology_explanation,
    documentation_complete,
    documentation_explanation,
    stakeholder_rating,
    stakeholder_comment,
    actor_id
  ) values (
    target_id,
    (input -> 'closeout' ->> 'dodMet')::boolean,
    btrim(input -> 'closeout' ->> 'dodExplanation'),
    (input -> 'closeout' ->> 'methodologyCompliant')::boolean,
    btrim(input -> 'closeout' ->> 'methodologyExplanation'),
    (input -> 'closeout' ->> 'documentationComplete')::boolean,
    btrim(input -> 'closeout' ->> 'documentationExplanation'),
    (input -> 'closeout' ->> 'stakeholderRating')::integer,
    nullif(btrim(input -> 'closeout' ->> 'stakeholderComment'), ''),
    auth.uid()
  )
  on conflict (project_id) do update
  set
    dod_met = excluded.dod_met,
    dod_explanation = excluded.dod_explanation,
    methodology_compliant = excluded.methodology_compliant,
    methodology_explanation = excluded.methodology_explanation,
    documentation_complete = excluded.documentation_complete,
    documentation_explanation = excluded.documentation_explanation,
    stakeholder_rating = excluded.stakeholder_rating,
    stakeholder_comment = excluded.stakeholder_comment,
    recorded_at = statement_timestamp(),
    actor_id = excluded.actor_id
  returning id into assessment_id;

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
    target_id,
    'state_changed',
    effective_time,
    auth.uid(),
    jsonb_build_object('closeoutAssessmentId', assessment_id),
    'Closed',
    project_row.current_stage_id,
    stage.name,
    project_row.ball_owner_id,
    owner.name
  from (select 1) as singleton
  left join public.project_stages as stage
    on stage.id = project_row.current_stage_id
  join public.people as owner on owner.id = project_row.ball_owner_id;

  perform public.replay_project_projection(target_id);
  select * into after_project from public.projects where id = target_id;

  perform public.record_project_audit(
    target_id,
    'project_closed',
    to_jsonb(project_row),
    jsonb_build_object(
      'project', to_jsonb(after_project),
      'assessmentId', assessment_id,
      'input', input
    )
  );

  return event_id;
end;
$$;

create function public.set_project_archived(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid := (input ->> 'projectId')::uuid;
  should_archive boolean := (input ->> 'archived')::boolean;
  event_id uuid := gen_random_uuid();
  project_row public.projects%rowtype;
  after_project public.projects%rowtype;
begin
  select * into project_row
  from public.projects
  where id = target_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Project not found';
  end if;

  if not public.can_edit_project(target_id) then
    raise exception using errcode = '42501', message = 'Permission denied';
  end if;

  if project_row.version <> (input ->> 'version')::bigint then
    raise exception using errcode = '40001', message = 'Project changed since this form loaded';
  end if;

  if project_row.state not in ('Cancelled', 'Closed') then
    raise exception using errcode = '22023', message = 'Only terminal Projects may be archived';
  end if;

  if (project_row.archived_at is not null) = should_archive then
    raise exception using errcode = '22023', message = 'Project archival state is unchanged';
  end if;

  update public.projects
  set
    archived_at = case when should_archive then statement_timestamp() else null end,
    updated_at = statement_timestamp(),
    version = version + 1
  where id = target_id;

  select * into after_project from public.projects where id = target_id;

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
    target_id,
    'archived',
    statement_timestamp(),
    auth.uid(),
    jsonb_build_object('archived', should_archive),
    after_project.state,
    after_project.current_stage_id,
    stage.name,
    after_project.ball_owner_id,
    owner.name
  from (select 1) as singleton
  left join public.project_stages as stage
    on stage.id = after_project.current_stage_id
  join public.people as owner on owner.id = after_project.ball_owner_id;

  perform public.record_project_audit(
    target_id,
    case when should_archive then 'project_archived' else 'project_restored' end,
    to_jsonb(project_row),
    to_jsonb(after_project)
  );

  return event_id;
end;
$$;

create function public.correct_project_event(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  original_event public.project_events%rowtype;
  project_row public.projects%rowtype;
  after_project public.projects%rowtype;
  event_id uuid := gen_random_uuid();
  corrected_effective_at timestamptz;
  corrected_state public.project_state;
  corrected_stage_id uuid;
  corrected_stage_label text;
  corrected_owner_id uuid;
  corrected_owner_name text;
  corrected_payload jsonb;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Only Administrators may correct history';
  end if;

  select * into original_event
  from public.project_events
  where id = (input ->> 'eventId')::uuid
  for update;

  if not found or original_event.event_type not in (
    'progress', 'bump', 'state_changed', 'ball_transferred'
  ) then
    raise exception using errcode = '22023', message = 'Event cannot be corrected';
  end if;

  select * into project_row
  from public.projects
  where id = original_event.project_id
  for update;

  if project_row.version <> (input ->> 'version')::bigint then
    raise exception using errcode = '40001', message = 'Project changed since this form loaded';
  end if;

  if nullif(btrim(input ->> 'reason'), '') is null then
    raise exception using errcode = '22023', message = 'Correction reason is required';
  end if;

  corrected_effective_at := coalesce(
    (input ->> 'effectiveAt')::timestamptz,
    original_event.effective_at
  );
  corrected_state := coalesce(
    (input ->> 'resultingState')::public.project_state,
    original_event.resulting_state
  );
  corrected_stage_id := case
    when input ? 'stageId' then (input ->> 'stageId')::uuid
    else original_event.resulting_stage_id
  end;
  corrected_owner_id := coalesce(
    (input ->> 'resultingBallOwnerId')::uuid,
    original_event.resulting_ball_owner_id
  );
  corrected_payload := coalesce(input -> 'payload', original_event.payload)
    || jsonb_build_object('correctedEventType', original_event.event_type);

  if original_event.resulting_state in ('Cancelled', 'Closed')
    and corrected_state <> original_event.resulting_state
  then
    raise exception using errcode = '22023', message = 'A terminal State correction must remain in the same terminal State';
  end if;

  if corrected_state = 'Closed' and not exists (
    select 1 from public.closeout_assessments
    where project_id = original_event.project_id
  ) then
    raise exception using errcode = '22023', message = 'Closed requires a closeout assessment';
  end if;

  if corrected_state in ('Planned', 'Active') then
    perform public.assert_project_complete(original_event.project_id);
  end if;

  perform public.assert_ball_owner(
    original_event.project_id,
    corrected_owner_id,
    corrected_effective_at
  );

  if corrected_stage_id is not null then
    select name into corrected_stage_label
    from public.project_stages
    where id = corrected_stage_id
      and project_id = original_event.project_id;

    if not found then
      raise exception using errcode = '22023', message = 'Corrected Stage does not belong to the Project';
    end if;
  end if;

  if original_event.event_type = 'progress' and (
    corrected_stage_id is null
    or nullif(btrim(corrected_payload ->> 'summary'), '') is null
  ) then
    raise exception using errcode = '22023', message = 'Corrected Progress requires a Stage and summary';
  end if;

  if original_event.event_type = 'bump'
    and nullif(btrim(corrected_payload ->> 'text'), '') is null
  then
    raise exception using errcode = '22023', message = 'Corrected Bump requires text';
  end if;

  select name into corrected_owner_name
  from public.people
  where id = corrected_owner_id;

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
  ) values (
    event_id,
    original_event.project_id,
    'corrected',
    corrected_effective_at,
    auth.uid(),
    corrected_payload,
    corrected_state,
    corrected_stage_id,
    corrected_stage_label,
    corrected_owner_id,
    corrected_owner_name,
    original_event.id,
    btrim(input ->> 'reason')
  );

  perform public.replay_project_projection(original_event.project_id);
  select * into after_project
  from public.projects
  where id = original_event.project_id;

  perform public.record_project_audit(
    original_event.project_id,
    'event_corrected',
    jsonb_build_object('project', to_jsonb(project_row), 'event', to_jsonb(original_event)),
    jsonb_build_object('project', to_jsonb(after_project), 'correctionEventId', event_id, 'input', input)
  );

  return event_id;
end;
$$;

revoke execute on function public.assert_ball_owner(uuid, uuid, timestamptz)
from public, anon, authenticated;
revoke execute on function public.assert_project_complete(uuid)
from public, anon, authenticated;
revoke execute on function public.record_project_audit(uuid, text, jsonb, jsonb)
from public, anon, authenticated;
revoke execute on function public.replay_project_projection(uuid)
from public, anon, authenticated;

revoke execute on function public.create_project(jsonb) from public, anon;
revoke execute on function public.update_project(jsonb) from public, anon;
revoke execute on function public.reassign_project_pmo(jsonb) from public, anon;
revoke execute on function public.configure_project_stage(jsonb) from public, anon;
revoke execute on function public.revise_stage_plan(jsonb) from public, anon;
revoke execute on function public.append_project_event(jsonb) from public, anon;
revoke execute on function public.close_project(jsonb) from public, anon;
revoke execute on function public.set_project_archived(jsonb) from public, anon;
revoke execute on function public.correct_project_event(jsonb) from public, anon;

grant execute on function public.create_project(jsonb) to authenticated;
grant execute on function public.update_project(jsonb) to authenticated;
grant execute on function public.reassign_project_pmo(jsonb) to authenticated;
grant execute on function public.configure_project_stage(jsonb) to authenticated;
grant execute on function public.revise_stage_plan(jsonb) to authenticated;
grant execute on function public.append_project_event(jsonb) to authenticated;
grant execute on function public.close_project(jsonb) to authenticated;
grant execute on function public.set_project_archived(jsonb) to authenticated;
grant execute on function public.correct_project_event(jsonb) to authenticated;

comment on function public.create_project(jsonb) is
  'Creates the complete initial Project aggregate and immutable creation evidence atomically.';
comment on function public.update_project(jsonb) is
  'Updates Project overview, request, scope, participants, affected areas, and references atomically.';
comment on function public.reassign_project_pmo(jsonb) is
  'Administrator-only accountable PMO reassignment with effective history.';
comment on function public.configure_project_stage(jsonb) is
  'Adds, edits, reorders, or retires a Project-owned Stage.';
comment on function public.revise_stage_plan(jsonb) is
  'Appends an effective-dated planned completion revision.';
comment on function public.append_project_event(jsonb) is
  'Appends Progress, Bump, State-change, or Ball-transfer evidence and replays the current projection.';
comment on function public.close_project(jsonb) is
  'Persists closeout evidence and the irreversible Closed State in one transaction.';
comment on function public.set_project_archived(jsonb) is
  'Archives or restores a terminal Project without deleting its history.';
comment on function public.correct_project_event(jsonb) is
  'Supersedes an eligible event and replays the current Project projection.';
