begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(35);

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

create function pg_temp.make_project(
  project_id uuid,
  project_code text,
  person_id uuid,
  actor_id uuid,
  priority_id uuid,
  stage_id uuid
)
returns void
language plpgsql
as $$
begin
  insert into public.projects (
    id, code, name, priority_id, state, pmo_officer_id, ball_owner_id
  ) values (
    project_id, project_code, project_code, priority_id, 'Pipeline', person_id, person_id
  );

  insert into public.project_pmo_assignments (
    project_id, person_id, effective_from
  ) values (project_id, person_id, transaction_timestamp() - interval '1 minute');

  insert into public.project_participant_assignments (
    project_id, person_id, participant_group, effective_from
  ) values (
    project_id,
    person_id,
    'PMO',
    transaction_timestamp() - interval '1 minute'
  );

  insert into public.project_stages (
    id, project_id, name, sort_order
  ) values (stage_id, project_id, 'Test stage', 1);

  insert into public.project_events (
    project_id,
    event_type,
    effective_at,
    actor_id,
    payload,
    resulting_state,
    resulting_ball_owner_id,
    resulting_ball_owner_name
  ) values (
    project_id,
    'project_created',
    transaction_timestamp(),
    actor_id,
    jsonb_build_object('code', project_code, 'name', project_code),
    'Pipeline',
    person_id,
    'Test Officer'
  );
end;
$$;

create function pg_temp.plan_uses_index(command text, expected_index text)
returns boolean
language plpgsql
as $$
declare
  query_plan json;
begin
  perform set_config('enable_seqscan', 'off', true);
  execute 'explain (format json) ' || command into query_plan;
  return query_plan::text like '%"Index Name": "' || expected_index || '"%';
end;
$$;

select has_table('public', 'projects', 'Project relation exists');

select lives_ok(
  $$
  do $fixture$
  begin
    set constraints all deferred;

    insert into public.departments (id, name)
    values ('d0000000-0000-0000-0000-000000000001', 'Test Department');

    insert into public.people (
      id, name, department_id, username, position, active
    ) values
      (
        '10000000-0000-0000-0000-000000000001',
        'Test Officer',
        'd0000000-0000-0000-0000-000000000001',
        'test.officer',
        'Officer',
        true
      ),
      (
        '10000000-0000-0000-0000-000000000002',
        'Other Person',
        'd0000000-0000-0000-0000-000000000001',
        'other.person',
        'Owner',
        true
      ),
      (
        '10000000-0000-0000-0000-000000000003',
        'Inactive Person',
        'd0000000-0000-0000-0000-000000000001',
        'inactive.person',
        'Developer',
        false
      ),
      (
        '10000000-0000-0000-0000-000000000004',
        'Account Person',
        'd0000000-0000-0000-0000-000000000001',
        'account.person',
        'Viewer',
        true
      );

    insert into auth.users (id, email)
    values
      ('a0000000-0000-0000-0000-000000000001', 'actor@example.test'),
      ('a0000000-0000-0000-0000-000000000002', 'account@example.test');

    insert into public.profiles (id, person_id)
    values
      (
        'a0000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
      ),
      (
        'a0000000-0000-0000-0000-000000000002',
        '10000000-0000-0000-0000-000000000004'
      );

    insert into public.profile_roles (profile_id, role)
    values ('a0000000-0000-0000-0000-000000000001', 'administrator');

    insert into public.priorities (id, name, sort_order)
    values ('20000000-0000-0000-0000-000000000001', 'Test Priority', 100);

    insert into public.systems (id, name)
    values ('30000000-0000-0000-0000-000000000001', 'Test System');

    insert into public.modules (id, system_id, name)
    values (
      '31000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000001',
      'Test Module'
    );

    insert into public.system_developer_assignments (
      system_id, person_id, effective_from
    ) values (
      '30000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      transaction_timestamp() - interval '1 minute'
    );

    insert into public.module_owner_assignments (
      module_id, person_id, effective_from
    ) values (
      '31000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      transaction_timestamp() - interval '1 minute'
    );

    perform pg_temp.make_project(
      '40000000-0000-0000-0000-000000000001',
      'TEST-001',
      '10000000-0000-0000-0000-000000000001',
      'a0000000-0000-0000-0000-000000000001',
      '20000000-0000-0000-0000-000000000001',
      '41000000-0000-0000-0000-000000000001'
    );

    set constraints all immediate;
  end
  $fixture$;
  $$,
  'A valid directory, ownership, and Project aggregate is accepted'
);

select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects set code = 'test-001', version = version + 1
      where id = '40000000-0000-0000-0000-000000000001'$$,
    'P0001'
  ),
  'Project Code is immutable even when only case changes'
);

select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects set name = 'Changed'
      where id = '40000000-0000-0000-0000-000000000001'$$,
    'P0001'
  ),
  'Project updates must increment the optimistic version'
);

select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects set ball_owner_id = null, version = version + 1
      where id = '40000000-0000-0000-0000-000000000001'$$,
    '23514'
  ),
  'A non-terminal Project cannot lose its Ball Owner'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      update public.projects
      set state = 'Closed', version = version + 1
      where id = '40000000-0000-0000-0000-000000000001';
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'Closed requires a closeout assessment'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      perform pg_temp.make_project(
        '40000000-0000-0000-0000-000000000002', 'TEST-002',
        '10000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        '20000000-0000-0000-0000-000000000001',
        '41000000-0000-0000-0000-000000000002'
      );
      insert into public.closeout_assessments (
        project_id, dod_met, dod_explanation, methodology_compliant,
        methodology_explanation, documentation_complete,
        documentation_explanation, actor_id
      ) values (
        '40000000-0000-0000-0000-000000000002', true, 'Met', true,
        'Compliant', true, 'Complete',
        'a0000000-0000-0000-0000-000000000001'
      );
      update public.projects
      set state = 'Closed', version = version + 1
      where id = '40000000-0000-0000-0000-000000000002';
      set constraints all immediate;
      update public.projects
      set state = 'Active', version = version + 1
      where id = '40000000-0000-0000-0000-000000000002';
    end
    $test$
    $$,
    'P0001'
  ),
  'Terminal Projects cannot reopen'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      perform pg_temp.make_project(
        '40000000-0000-0000-0000-000000000003', 'TEST-003',
        '10000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        '20000000-0000-0000-0000-000000000001',
        '41000000-0000-0000-0000-000000000003'
      );
      insert into public.closeout_assessments (
        project_id, dod_met, dod_explanation, methodology_compliant,
        methodology_explanation, documentation_complete,
        documentation_explanation, actor_id
      ) values (
        '40000000-0000-0000-0000-000000000003', true, 'Met', true,
        'Compliant', true, 'Complete',
        'a0000000-0000-0000-0000-000000000001'
      );
      update public.projects
      set state = 'Closed', version = version + 1
      where id = '40000000-0000-0000-0000-000000000003';
      set constraints all immediate;
      update public.closeout_assessments
      set stakeholder_comment = 'Changed'
      where project_id = '40000000-0000-0000-0000-000000000003';
    end
    $test$
    $$,
    'P0001'
  ),
  'A Closed Project closeout is final'
);

select ok(
  pg_temp.throws_sqlstate(
    $$delete from public.projects
      where id = '40000000-0000-0000-0000-000000000001'$$,
    'P0001'
  ),
  'Projects are archived rather than deleted'
);

select ok(
  pg_temp.throws_sqlstate(
    $$update public.project_events set payload = '{}' where project_id =
      '40000000-0000-0000-0000-000000000001'$$,
    'P0001'
  ),
  'Project events cannot be updated'
);

select ok(
  pg_temp.throws_sqlstate(
    $$delete from public.project_events where project_id =
      '40000000-0000-0000-0000-000000000001'$$,
    'P0001'
  ),
  'Project events cannot be deleted'
);

select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.project_events (
      project_id, event_type, effective_at, actor_id, payload,
      resulting_state, resulting_ball_owner_id, resulting_ball_owner_name,
      supersedes_event_id, correction_reason
    ) select project_id, 'corrected', transaction_timestamp(),
      'a0000000-0000-0000-0000-000000000001', '{}', resulting_state,
      resulting_ball_owner_id, resulting_ball_owner_name, id, 'Not eligible'
      from public.project_events
      where project_id = '40000000-0000-0000-0000-000000000001'
        and event_type = 'project_created'$$,
    'P0001'
  ),
  'Creation events cannot be corrected'
);

select lives_ok(
  $$
  do $test$
  begin
    insert into public.project_events (
      id, project_id, event_type, effective_at, actor_id, payload,
      resulting_state, resulting_ball_owner_id, resulting_ball_owner_name
    ) values (
      '42000000-0000-0000-0000-000000000001',
      '40000000-0000-0000-0000-000000000001', 'bump',
      transaction_timestamp(), 'a0000000-0000-0000-0000-000000000001',
      '{"text":"Waiting"}', 'Pipeline',
      '10000000-0000-0000-0000-000000000001', 'Test Officer'
    );
    insert into public.project_events (
      project_id, event_type, effective_at, actor_id, payload,
      resulting_state, resulting_ball_owner_id, resulting_ball_owner_name,
      supersedes_event_id, correction_reason
    ) values (
      '40000000-0000-0000-0000-000000000001', 'corrected',
      transaction_timestamp(), 'a0000000-0000-0000-0000-000000000001',
      '{}', 'Pipeline',
      '10000000-0000-0000-0000-000000000001', 'Test Officer',
      '42000000-0000-0000-0000-000000000001', 'Corrected summary'
    );
  end
  $test$
  $$,
  'An eligible operational event may be corrected once'
);

select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.project_events (
      project_id, event_type, effective_at, actor_id, payload,
      resulting_state, resulting_ball_owner_id, resulting_ball_owner_name,
      supersedes_event_id, correction_reason
    ) values (
      '40000000-0000-0000-0000-000000000001', 'corrected',
      transaction_timestamp(), 'a0000000-0000-0000-0000-000000000001',
      '{}', 'Pipeline',
      '10000000-0000-0000-0000-000000000001', 'Test Officer',
      '42000000-0000-0000-0000-000000000001', 'Second correction'
    )$$,
    '23505'
  ),
  'An event cannot be corrected twice'
);

select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.project_participant_assignments (
      project_id, person_id, participant_group, effective_from
    ) values (
      '40000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001', 'Developer',
      transaction_timestamp()
    )$$,
    '23P01'
  ),
  'A Project participant cannot occupy overlapping groups'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      update public.projects
      set ball_owner_id = '10000000-0000-0000-0000-000000000002',
          version = version + 1
      where id = '40000000-0000-0000-0000-000000000001';
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'A non-terminal Ball Owner must be a current Project participant'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      insert into public.project_participant_assignments (
        project_id, person_id, participant_group, effective_from
      ) values (
        '40000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000003', 'Developer',
        transaction_timestamp()
      );
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'Inactive People cannot receive assignments'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      update public.people set active = false
      where id = '10000000-0000-0000-0000-000000000001';
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'People with current assignments cannot be deactivated'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      update public.people set active = false
      where id = '10000000-0000-0000-0000-000000000004';
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'People with an active account cannot be deactivated'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      insert into public.project_system_scopes (
        project_id, system_id, entire_system
      ) values (
        '40000000-0000-0000-0000-000000000001',
        '30000000-0000-0000-0000-000000000001', true
      );
      insert into public.project_system_scopes (
        project_id, system_id, entire_system, module_id
      ) values (
        '40000000-0000-0000-0000-000000000001',
        '30000000-0000-0000-0000-000000000001', false,
        '31000000-0000-0000-0000-000000000001'
      );
    end
    $test$
    $$,
    '23P01'
  ),
  'A Project cannot mix entire-System and module scope for one System'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      update public.project_stages set visited = true
      where id = '41000000-0000-0000-0000-000000000001';
      delete from public.project_stages
      where id = '41000000-0000-0000-0000-000000000001';
    end
    $test$
    $$,
    'P0001'
  ),
  'A visited Project stage cannot be deleted'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      insert into public.systems (id, name)
      values ('30000000-0000-0000-0000-000000000002', 'No Module');
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'A System requires at least one Module'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      insert into public.systems (id, name)
      values ('30000000-0000-0000-0000-000000000003', 'No Developer');
      insert into public.modules (id, system_id, name)
      values (
        '31000000-0000-0000-0000-000000000003',
        '30000000-0000-0000-0000-000000000003', 'Owned Module'
      );
      insert into public.module_owner_assignments (
        module_id, person_id, effective_from
      ) values (
        '31000000-0000-0000-0000-000000000003',
        '10000000-0000-0000-0000-000000000001',
        transaction_timestamp()
      );
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'A System requires at least one current Developer'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      insert into public.modules (id, system_id, name)
      values (
        '31000000-0000-0000-0000-000000000004',
        '30000000-0000-0000-0000-000000000001', 'No Owner'
      );
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'A Module requires exactly one current Owner'
);

select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.system_developer_assignments (
      system_id, person_id, effective_from, effective_to
    ) values (
      '30000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000002',
      transaction_timestamp(), transaction_timestamp() - interval '1 minute'
    )$$,
    '23514'
  ),
  'Effective assignment end must follow its start'
);

select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects
      set archived_at = transaction_timestamp(), version = version + 1
      where id = '40000000-0000-0000-0000-000000000001'$$,
    '23514'
  ),
  'Only terminal Projects may be archived'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      insert into public.projects (
        id, code, name, priority_id, state, pmo_officer_id, ball_owner_id
      ) values (
        '40000000-0000-0000-0000-000000000004', 'TEST-004', 'No event',
        '20000000-0000-0000-0000-000000000001', 'Pipeline',
        '10000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
      );
      insert into public.project_pmo_assignments (
        project_id, person_id, effective_from
      ) values (
        '40000000-0000-0000-0000-000000000004',
        '10000000-0000-0000-0000-000000000001', transaction_timestamp()
      );
      insert into public.project_participant_assignments (
        project_id, person_id, participant_group, effective_from
      ) values (
        '40000000-0000-0000-0000-000000000004',
        '10000000-0000-0000-0000-000000000001', 'PMO',
        transaction_timestamp()
      );
      set constraints all immediate;
    end
    $test$
    $$,
    'P0001'
  ),
  'Every Project requires exactly one creation event'
);

select ok(
  pg_temp.throws_sqlstate(
    $$delete from public.priorities
      where id = '20000000-0000-0000-0000-000000000001'$$,
    '23503'
  ),
  'Referenced configuration rows use restrictive deletion'
);

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
    begin
      set constraints all deferred;
      perform pg_temp.make_project(
        '40000000-0000-0000-0000-000000000005', 'TEST-005',
        '10000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        '20000000-0000-0000-0000-000000000001',
        '41000000-0000-0000-0000-000000000005'
      );
      insert into public.project_events (
        project_id, event_type, effective_at, actor_id, payload,
        resulting_state, resulting_stage_id, resulting_stage_label,
        resulting_ball_owner_id, resulting_ball_owner_name
      ) values (
        '40000000-0000-0000-0000-000000000005', 'progress',
        transaction_timestamp(), 'a0000000-0000-0000-0000-000000000001',
        '{"summary":"Wrong Project"}', 'Pipeline',
        '41000000-0000-0000-0000-000000000001', 'Test stage',
        '10000000-0000-0000-0000-000000000001', 'Test Officer'
      );
      set constraints all immediate;
    end
    $test$
    $$,
    '23503'
  ),
  'Event stage snapshots must belong to the same Project'
);

select ok(
  pg_temp.plan_uses_index(
    $$select 1 from public.profile_roles
      where profile_id = 'a0000000-0000-0000-0000-000000000001'
        and role = 'administrator'$$,
    'profile_roles_role_profile_idx'
  ),
  'Role checks use the profile-role index'
);

select ok(
  pg_temp.plan_uses_index(
    $$select id from public.projects
      where archived_at is null and state = 'Pipeline'
        and priority_id = '20000000-0000-0000-0000-000000000001'
      order by updated_at desc$$,
    'projects_active_portfolio_idx'
  ),
  'Dashboard portfolio queues use the active portfolio index'
);

select ok(
  pg_temp.plan_uses_index(
    $$select id from public.project_events
      where project_id = '40000000-0000-0000-0000-000000000001'
      order by effective_at, recorded_at, id$$,
    'project_events_timeline'
  ),
  'Project history uses the timeline index'
);

select ok(
  pg_temp.plan_uses_index(
    $$select person_id from public.project_participant_assignments
      where project_id = '40000000-0000-0000-0000-000000000001'
        and participant_group = 'PMO' and effective_to is null$$,
    'project_participants_project_group_current_idx'
  ),
  'Current ownership lookups use the participant-group index'
);

select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.project_system_scopes (
      project_id, system_id, entire_system, module_id
    ) values (
      '40000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000001', false,
      '31000000-0000-0000-0000-000000000003'
    )$$,
    '23503'
  ),
  'A scoped Module must belong to the selected System'
);

select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.projects (
      id, code, name, priority_id, state, pmo_officer_id, ball_owner_id
    ) values (
      '40000000-0000-0000-0000-000000000099', 'TEST-001', 'Duplicate code',
      '20000000-0000-0000-0000-000000000001', 'Pipeline',
      '10000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001'
    )$$,
    '23505'
  ),
  'Project Codes remain unique case-insensitively'
);

select * from finish();
rollback;
