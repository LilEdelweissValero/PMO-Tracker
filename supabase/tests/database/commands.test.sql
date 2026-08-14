begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(59);

create function pg_temp.throws_sqlstate(command text, expected_state text)
returns boolean
language plpgsql
as $$
declare
  observed_state text;
begin
  begin
    execute command;
    raise exception using errcode = 'ZX001', message = 'Expected statement to fail';
  exception when others then
    observed_state := sqlstate;
  end;

  return observed_state = expected_state;
end;
$$;

create temporary table command_context (
  project_id uuid,
  second_project_id uuid,
  added_stage_id uuid
);
insert into command_context default values;
grant all on command_context to authenticated;

select lives_ok(
  $$
  do $fixture$
  begin
    set constraints all deferred;

    insert into public.departments (id, name)
    values ('d0000000-0000-0000-0000-000000000201', 'Command Department');

    insert into public.people (
      id, name, department_id, username, position
    ) values
      (
        '10000000-0000-0000-0000-000000000201', 'Command Admin',
        'd0000000-0000-0000-0000-000000000201', 'command.admin', 'Administrator'
      ),
      (
        '10000000-0000-0000-0000-000000000202', 'Command PMO One',
        'd0000000-0000-0000-0000-000000000201', 'command.pmo1', 'PMO Officer'
      ),
      (
        '10000000-0000-0000-0000-000000000203', 'Command PMO Two',
        'd0000000-0000-0000-0000-000000000201', 'command.pmo2', 'PMO Officer'
      ),
      (
        '10000000-0000-0000-0000-000000000204', 'Command Developer',
        'd0000000-0000-0000-0000-000000000201', 'command.developer', 'Developer'
      ),
      (
        '10000000-0000-0000-0000-000000000205', 'Command System Owner',
        'd0000000-0000-0000-0000-000000000201', 'command.owner', 'System Owner'
      ),
      (
        '10000000-0000-0000-0000-000000000207', 'Command Leadership',
        'd0000000-0000-0000-0000-000000000201', 'command.leadership', 'Leader'
      );

    insert into auth.users (id, email)
    values
      ('a0000000-0000-0000-0000-000000000201', 'admin@commands.test'),
      ('a0000000-0000-0000-0000-000000000202', 'pmo1@commands.test'),
      ('a0000000-0000-0000-0000-000000000203', 'pmo2@commands.test'),
      ('a0000000-0000-0000-0000-000000000207', 'leadership@commands.test');

    insert into public.profiles (id, person_id)
    values
      (
        'a0000000-0000-0000-0000-000000000201',
        '10000000-0000-0000-0000-000000000201'
      ),
      (
        'a0000000-0000-0000-0000-000000000202',
        '10000000-0000-0000-0000-000000000202'
      ),
      (
        'a0000000-0000-0000-0000-000000000203',
        '10000000-0000-0000-0000-000000000203'
      ),
      (
        'a0000000-0000-0000-0000-000000000207',
        '10000000-0000-0000-0000-000000000207'
      );

    insert into public.profile_roles (profile_id, role)
    values
      ('a0000000-0000-0000-0000-000000000201', 'administrator'),
      ('a0000000-0000-0000-0000-000000000201', 'pmo_officer'),
      ('a0000000-0000-0000-0000-000000000202', 'pmo_officer'),
      ('a0000000-0000-0000-0000-000000000203', 'pmo_officer'),
      ('a0000000-0000-0000-0000-000000000207', 'leadership_viewer');

    insert into public.priorities (id, name, sort_order)
    values ('20000000-0000-0000-0000-000000000201', 'Command Priority', 201);
    insert into public.request_types (id, name)
    values ('21000000-0000-0000-0000-000000000201', 'Command Request');
    insert into public.initiator_types (id, name)
    values ('22000000-0000-0000-0000-000000000201', 'Command Initiator');
    insert into public.reference_types (id, name)
    values ('23000000-0000-0000-0000-000000000201', 'Command Reference');
    insert into public.initiatives (id, name)
    values ('24000000-0000-0000-0000-000000000201', 'Command Initiative');

    insert into public.systems (id, name)
    values ('30000000-0000-0000-0000-000000000201', 'Command System');
    insert into public.modules (id, system_id, name)
    values (
      '31000000-0000-0000-0000-000000000201',
      '30000000-0000-0000-0000-000000000201', 'Command Module'
    );
    insert into public.system_developer_assignments (
      system_id, person_id, effective_from
    ) values (
      '30000000-0000-0000-0000-000000000201',
      '10000000-0000-0000-0000-000000000204',
      statement_timestamp() - interval '1 minute'
    );
    insert into public.module_owner_assignments (
      module_id, person_id, effective_from
    ) values (
      '31000000-0000-0000-0000-000000000201',
      '10000000-0000-0000-0000-000000000205',
      statement_timestamp() - interval '1 minute'
    );

    set constraints all immediate;
    set constraints all deferred;
  end
  $fixture$;
  $$,
  'Command fixtures satisfy directory invariants'
);

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000207","role":"authenticated"}';

select ok(
  pg_temp.throws_sqlstate(
    $$select public.create_project(jsonb_build_object(
      'code', 'CMD-LEAD', 'name', 'Leadership Project',
      'priorityId', '20000000-0000-0000-0000-000000000201',
      'state', 'Pipeline',
      'pmoOfficerId', '10000000-0000-0000-0000-000000000202',
      'ballOwnerId', '10000000-0000-0000-0000-000000000202'
    ))$$,
    '42501'
  ),
  'Leadership cannot create a Project'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000201","role":"authenticated"}';

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      perform public.create_project(jsonb_build_object(
        'code', 'CMD-BAD', 'name', 'Incomplete Active',
        'priorityId', '20000000-0000-0000-0000-000000000201',
        'state', 'Active',
        'pmoOfficerId', '10000000-0000-0000-0000-000000000202',
        'ballOwnerId', '10000000-0000-0000-0000-000000000202'
      ));
      set constraints all immediate;
    end
    $test$
    $$,
    '22023'
  ),
  'Incomplete Active creation is rejected atomically'
);
select is(
  (select count(*) from public.projects where code = 'CMD-BAD'),
  0::bigint,
  'Rejected creation leaves no Project row'
);

select lives_ok(
  $$
  do $test$
  declare
    created_id uuid;
  begin
    created_id := public.create_project(jsonb_build_object(
      'code', 'CMD-001',
      'name', 'Command Project',
      'priorityId', '20000000-0000-0000-0000-000000000201',
      'state', 'Pipeline',
      'pmoOfficerId', '10000000-0000-0000-0000-000000000202',
      'ballOwnerId', '10000000-0000-0000-0000-000000000204',
      'participants', jsonb_build_array(
        jsonb_build_object(
          'personId', '10000000-0000-0000-0000-000000000202', 'group', 'PMO'
        ),
        jsonb_build_object(
          'personId', '10000000-0000-0000-0000-000000000204', 'group', 'Developer'
        )
      )
    ));
    update command_context set project_id = created_id;
    set constraints all immediate;
    set constraints all deferred;
  end
  $test$
  $$,
  'Administrator creates a Pipeline Project with an arbitrary participant Ball Owner'
);
select is(
  (select ball_owner_id from public.projects where code = 'CMD-001'),
  '10000000-0000-0000-0000-000000000204'::uuid,
  'Creation stores the selected individual Ball Owner'
);
select is(
  (
    select count(*)
    from public.project_stages
    where project_id = (select project_id from command_context) and active
  ),
  14::bigint,
  'Creation copies the active Workflow Template'
);
select is(
  (
    select count(*) from public.project_events
    where project_id = (select project_id from command_context)
      and event_type = 'project_created'
  ),
  1::bigint,
  'Creation appends exactly one creation event'
);
select is(
  (
    select count(*) from public.audit_log
    where entity_id = (select project_id from command_context)
      and action = 'project_created'
  ),
  1::bigint,
  'Creation records same-transaction audit evidence'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.create_project(jsonb_build_object(
      'code', 'cmd-001', 'name', 'Duplicate',
      'priorityId', '20000000-0000-0000-0000-000000000201',
      'state', 'Pipeline',
      'pmoOfficerId', '10000000-0000-0000-0000-000000000202',
      'ballOwnerId', '10000000-0000-0000-0000-000000000202'
    ))$$,
    '23505'
  ),
  'Duplicate Project Code is rejected case-insensitively'
);
select is((select count(*) from public.projects where code = 'CMD-001'), 1::bigint, 'Duplicate creation leaves the original intact');

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000202","role":"authenticated"}';

select lives_ok(
  $$
  do $test$
  declare
    created_id uuid;
  begin
    created_id := public.create_project(jsonb_build_object(
      'code', 'CMD-002', 'name', 'PMO Created',
      'priorityId', '20000000-0000-0000-0000-000000000201',
      'state', 'Pipeline',
      'pmoOfficerId', '10000000-0000-0000-0000-000000000202',
      'ballOwnerId', '10000000-0000-0000-0000-000000000202'
    ));
    update command_context set second_project_id = created_id;
    set constraints all immediate;
    set constraints all deferred;
  end
  $test$
  $$,
  'PMO Officer can create a Project'
);

select lives_ok(
  $$
  do $test$
  begin
    perform public.update_project(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'name', 'Command Project Updated',
      'initiativeId', '24000000-0000-0000-0000-000000000201',
      'scope', 'Deliver the command layer',
      'requestTypeId', '21000000-0000-0000-0000-000000000201',
      'initiatorTypeId', '22000000-0000-0000-0000-000000000201',
      'requesterId', '10000000-0000-0000-0000-000000000205',
      'participants', jsonb_build_array(
        jsonb_build_object('personId', '10000000-0000-0000-0000-000000000202', 'group', 'PMO'),
        jsonb_build_object('personId', '10000000-0000-0000-0000-000000000204', 'group', 'Developer'),
        jsonb_build_object('personId', '10000000-0000-0000-0000-000000000205', 'group', 'System Owner')
      ),
      'systemScopes', jsonb_build_array(
        jsonb_build_object(
          'systemId', '30000000-0000-0000-0000-000000000201',
          'moduleId', '31000000-0000-0000-0000-000000000201',
          'entireSystem', false
        )
      ),
      'references', jsonb_build_array(
        jsonb_build_object(
          'typeId', '23000000-0000-0000-0000-000000000201',
          'label', 'Command Reference', 'url', 'https://example.test/command'
        )
      )
    ));
    set constraints all immediate;
    set constraints all deferred;
  end
  $test$
  $$,
  'Assigned PMO updates overview, request, participants, scope, and references atomically'
);
select is(
  (select requester_department_name from public.projects where id = (select project_id from command_context)),
  'Command Department',
  'Requester Department is captured as a historical snapshot'
);
select is(
  (
    select count(*) from public.project_participant_assignments
    where project_id = (select project_id from command_context) and effective_to is null
  ),
  3::bigint,
  'Participant replacement creates the intended current set'
);
select is(
  (select count(*) from public.project_system_scopes where project_id = (select project_id from command_context)),
  1::bigint,
  'Affected Module scope is persisted'
);
select is(
  (select count(*) from public.project_references where project_id = (select project_id from command_context) and active),
  1::bigint,
  'External Reference replacement is persisted'
);

select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'state_changed', 'effectiveAt', statement_timestamp(),
    'resultingState', 'Planned',
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
    'payload', '{}'::jsonb
  ))$$,
  'Complete Pipeline Project can move to Planned'
);
select is(
  (select state from public.projects where id = (select project_id from command_context)),
  'Planned'::public.project_state,
  'State command replays the Planned projection'
);

select ok(
  pg_temp.throws_sqlstate(
    $$select public.append_project_event(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', 1, 'eventType', 'bump', 'effectiveAt', statement_timestamp(),
      'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
      'payload', jsonb_build_object('text', 'Stale')
    ))$$,
    '40001'
  ),
  'Stale Project version is rejected'
);
select is(
  (
    select count(*) from public.project_events
    where project_id = (select project_id from command_context)
      and payload ->> 'text' = 'Stale'
  ),
  0::bigint,
  'Stale command leaves no partial event'
);

select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'progress', 'effectiveAt', statement_timestamp(),
    'stageId', (
      select id from public.project_stages
      where project_id = (select project_id from command_context) and sort_order = 1
    ),
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
    'payload', jsonb_build_object('summary', 'Engagement complete')
  ))$$,
  'Sequential Progress visits the first Stage'
);
select is(
  (
    select sort_order from public.project_stages
    where id = (select current_stage_id from public.projects where id = (select project_id from command_context))
  ),
  1,
  'Progress updates the current Stage projection'
);

select ok(
  pg_temp.throws_sqlstate(
    $$select public.append_project_event(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'eventType', 'progress', 'effectiveAt', statement_timestamp(),
      'stageId', (
        select id from public.project_stages
        where project_id = (select project_id from command_context) and sort_order = 4
      ),
      'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
      'payload', jsonb_build_object('summary', 'Jumped')
    ))$$,
    '22023'
  ),
  'Non-sequential Progress requires an explanation'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.append_project_event(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'eventType', 'progress', 'effectiveAt', statement_timestamp(),
      'stageId', (
        select id from public.project_stages
        where project_id = (select project_id from command_context) and sort_order = 2
      ),
      'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
      'payload', jsonb_build_object('summary', 'Requested')
    ))$$,
    '22023'
  ),
  'Configured required Stage Detail is enforced'
);
select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'progress', 'effectiveAt', statement_timestamp(),
    'stageId', (
      select id from public.project_stages
      where project_id = (select project_id from command_context) and sort_order = 2
    ),
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
    'payload', jsonb_build_object('summary', 'TICRO requested', 'stageDetail', 'Documents A and B')
  ))$$,
  'Progress accepts the required Stage Detail'
);

select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'bump', 'effectiveAt', statement_timestamp(),
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000205',
    'payload', jsonb_build_object('text', 'Owner reviewing documents')
  ))$$,
  'Bump may transfer the Ball'
);
select is(
  (select ball_owner_id from public.projects where id = (select project_id from command_context)),
  '10000000-0000-0000-0000-000000000205'::uuid,
  'Bump transfer updates the Ball projection'
);
select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'ball_transferred', 'effectiveAt', statement_timestamp(),
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
    'payload', jsonb_build_object('reason', 'Development action')
  ))$$,
  'Dedicated Ball transfer command is accepted'
);

select ok(
  pg_temp.throws_sqlstate(
    $$select public.append_project_event(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'eventType', 'state_changed', 'effectiveAt', statement_timestamp(),
      'resultingState', 'On Hold',
      'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
      'payload', '{}'::jsonb
    ))$$,
    '22023'
  ),
  'Entering On Hold requires a reason'
);
select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'state_changed', 'effectiveAt', statement_timestamp(),
    'resultingState', 'On Hold',
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
    'payload', jsonb_build_object('reason', 'External dependency')
  ))$$,
  'Project may enter On Hold with a reason'
);
select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'state_changed', 'effectiveAt', statement_timestamp(),
    'resultingState', 'Active',
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
    'payload', '{}'::jsonb
  ))$$,
  'Project may leave On Hold for Active when complete'
);

select lives_ok(
  $$select public.append_project_event(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'eventType', 'bump',
    'effectiveAt', (
      select effective_at from public.project_events
      where project_id = (select project_id from command_context)
        and event_type = 'project_created'
    ),
    'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
    'payload', jsonb_build_object('text', 'Backdated context')
  ))$$,
  'Backdated Bump is accepted'
);
select is(
  (select state from public.projects where id = (select project_id from command_context)),
  'Active'::public.project_state,
  'Backdated event replay preserves the later current State'
);
select is(
  (
    select sort_order from public.project_stages
    where id = (select current_stage_id from public.projects where id = (select project_id from command_context))
  ),
  2,
  'Backdated event replay preserves the later current Stage'
);

select lives_ok(
  $$select public.revise_stage_plan(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'stageId', (
      select id from public.project_stages
      where project_id = (select project_id from command_context) and sort_order = 3
    ),
    'plannedDate', '2026-09-01', 'reason', 'Dependency changed',
    'effectiveAt', statement_timestamp()
  ))$$,
  'Plan revision appends an effective-dated record'
);
select is(
  (select count(*) from public.stage_plan_revisions where project_id = (select project_id from command_context)),
  1::bigint,
  'Plan revision history is retained'
);

select lives_ok(
  $$
  do $test$
  declare
    stage_id uuid;
  begin
    stage_id := public.configure_project_stage(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'action', 'add', 'name', 'Command Added Stage', 'sortOrder', 3,
      'detailRequired', false, 'detailMultiline', false
    ));
    update command_context set added_stage_id = stage_id;
  end
  $test$
  $$,
  'Assigned PMO adds a Project-owned Stage'
);
select lives_ok(
  $$select public.configure_project_stage(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'action', 'update', 'stageId', (select added_stage_id from command_context),
    'name', 'Command Renamed Stage', 'detailLabel', 'Evidence'
  ))$$,
  'Assigned PMO edits a Project-owned Stage'
);
select lives_ok(
  $$select public.configure_project_stage(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'action', 'reorder',
    'stageIds', (
      select jsonb_agg(id order by sort_order desc)
      from public.project_stages
      where project_id = (select project_id from command_context) and active
    )
  ))$$,
  'Assigned PMO reorders every active Project Stage'
);
select lives_ok(
  $$select public.configure_project_stage(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'action', 'remove', 'stageId', (select added_stage_id from command_context)
  ))$$,
  'Assigned PMO retires an upcoming unvisited Stage'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.configure_project_stage(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'action', 'remove',
      'stageId', (select current_stage_id from public.projects where id = (select project_id from command_context))
    ))$$,
    '22023'
  ),
  'Visited current Stage cannot be removed'
);

select ok(
  pg_temp.throws_sqlstate(
    $$select public.reassign_project_pmo(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'pmoOfficerId', '10000000-0000-0000-0000-000000000203'
    ))$$,
    '42501'
  ),
  'PMO Officer cannot reassign accountable PMO ownership'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000201","role":"authenticated"}';

select lives_ok(
  $$select public.reassign_project_pmo(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'pmoOfficerId', '10000000-0000-0000-0000-000000000203',
    'reason', 'Portfolio rebalance'
  ))$$,
  'Administrator reassigns the accountable PMO Officer'
);
select is(
  (
    select count(*) from public.project_pmo_assignments
    where project_id = (select project_id from command_context) and effective_to is null
  ),
  1::bigint,
  'PMO reassignment leaves exactly one current assignment'
);
select is(
  (select pmo_officer_id from public.projects where id = (select project_id from command_context)),
  '10000000-0000-0000-0000-000000000203'::uuid,
  'PMO reassignment updates the current projection'
);

select ok(
  pg_temp.throws_sqlstate(
    $$select public.close_project(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'effectiveAt', statement_timestamp(),
      'closeout', jsonb_build_object(
        'dodMet', true, 'dodExplanation', '',
        'methodologyCompliant', true, 'methodologyExplanation', '',
        'documentationComplete', true, 'documentationExplanation', ''
      )
    ))$$,
    '22023'
  ),
  'Incomplete Closeout Assessment is rejected'
);
select lives_ok(
  $$select public.close_project(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'effectiveAt', statement_timestamp(),
    'closeout', jsonb_build_object(
      'dodMet', true, 'dodExplanation', 'Definition met',
      'methodologyCompliant', true, 'methodologyExplanation', 'Method followed',
      'documentationComplete', true, 'documentationExplanation', 'Documents complete',
      'stakeholderRating', 5, 'stakeholderComment', 'Approved'
    )
  ))$$,
  'Close command persists assessment and terminal event atomically'
);
select is(
  (select state from public.projects where id = (select project_id from command_context)),
  'Closed'::public.project_state,
  'Close command sets the irreversible Closed projection'
);
select is(
  (select count(*) from public.closeout_assessments where project_id = (select project_id from command_context)),
  1::bigint,
  'Closed Project has exactly one Closeout Assessment'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.append_project_event(jsonb_build_object(
      'projectId', (select project_id from command_context),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'eventType', 'bump', 'effectiveAt', statement_timestamp(),
      'resultingBallOwnerId', '10000000-0000-0000-0000-000000000204',
      'payload', jsonb_build_object('text', 'Too late')
    ))$$,
    '22023'
  ),
  'Terminal Project rejects further operational events'
);
select lives_ok(
  $$select public.set_project_archived(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'archived', true
  ))$$,
  'Closed Project may be archived'
);
select lives_ok(
  $$select public.set_project_archived(jsonb_build_object(
    'projectId', (select project_id from command_context),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'archived', false
  ))$$,
  'Archived Project may be restored without reopening State'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000203","role":"authenticated"}';

select ok(
  pg_temp.throws_sqlstate(
    $$select public.correct_project_event(jsonb_build_object(
      'eventId', (
        select id from public.project_events
        where project_id = (select project_id from command_context) and event_type = 'bump'
        order by effective_at desc limit 1
      ),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'reason', 'Not permitted'
    ))$$,
    '42501'
  ),
  'PMO Officer cannot correct historical events'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000201","role":"authenticated"}';

select lives_ok(
  $$select public.correct_project_event(jsonb_build_object(
    'eventId', (
      select id from public.project_events
      where project_id = (select project_id from command_context)
        and event_type = 'bump' and payload ->> 'text' = 'Owner reviewing documents'
    ),
    'version', (select version from public.projects where id = (select project_id from command_context)),
    'reason', 'Clarify wording',
    'payload', jsonb_build_object('text', 'Owner reviewing governance documents')
  ))$$,
  'Administrator supersedes an eligible event'
);
select is(
  (
    select count(*) from public.project_events
    where supersedes_event_id = (
      select id from public.project_events
      where project_id = (select project_id from command_context)
        and event_type = 'bump' and payload ->> 'text' = 'Owner reviewing documents'
    )
  ),
  1::bigint,
  'Correction retains the original and links one superseding event'
);
select is(
  (select state from public.projects where id = (select project_id from command_context)),
  'Closed'::public.project_state,
  'Correction replay preserves the later terminal projection'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.correct_project_event(jsonb_build_object(
      'eventId', (
        select id from public.project_events
        where project_id = (select project_id from command_context)
          and event_type = 'bump' and payload ->> 'text' = 'Owner reviewing documents'
      ),
      'version', (select version from public.projects where id = (select project_id from command_context)),
      'reason', 'Second correction'
    ))$$,
    '23505'
  ),
  'An event cannot be corrected twice'
);
select cmp_ok(
  (select count(*) from public.audit_log where entity_id = (select project_id from command_context)),
  '>=',
  14::bigint,
  'Successful Project commands record audit evidence'
);

reset role;
select * from finish();
rollback;
