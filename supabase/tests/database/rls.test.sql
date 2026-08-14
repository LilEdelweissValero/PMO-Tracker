begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(49);

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

create function pg_temp.affected_rows(command text)
returns bigint
language plpgsql
as $$
declare
  row_count bigint;
begin
  execute command;
  get diagnostics row_count = row_count;
  return row_count;
end;
$$;

select lives_ok(
  $$
  do $fixture$
  declare
    project_id uuid := '40000000-0000-0000-0000-000000000101';
    officer_id uuid := '10000000-0000-0000-0000-000000000102';
  begin
    set constraints all deferred;

    insert into public.departments (id, name)
    values ('d0000000-0000-0000-0000-000000000101', 'RLS Department');

    insert into public.people (
      id, name, department_id, username, position
    ) values
      (
        '10000000-0000-0000-0000-000000000101', 'RLS Administrator',
        'd0000000-0000-0000-0000-000000000101', 'rls.admin', 'Administrator'
      ),
      (
        '10000000-0000-0000-0000-000000000102', 'RLS Assigned PMO',
        'd0000000-0000-0000-0000-000000000101', 'rls.assigned', 'PMO Officer'
      ),
      (
        '10000000-0000-0000-0000-000000000103', 'RLS Unassigned PMO',
        'd0000000-0000-0000-0000-000000000101', 'rls.unassigned', 'PMO Officer'
      ),
      (
        '10000000-0000-0000-0000-000000000104', 'RLS Leadership',
        'd0000000-0000-0000-0000-000000000101', 'rls.leadership', 'Leader'
      ),
      (
        '10000000-0000-0000-0000-000000000105', 'RLS Inactive',
        'd0000000-0000-0000-0000-000000000101', 'rls.inactive', 'PMO Officer'
      );

    insert into auth.users (id, email)
    values
      ('a0000000-0000-0000-0000-000000000101', 'admin@rls.test'),
      ('a0000000-0000-0000-0000-000000000102', 'assigned@rls.test'),
      ('a0000000-0000-0000-0000-000000000103', 'unassigned@rls.test'),
      ('a0000000-0000-0000-0000-000000000104', 'leadership@rls.test'),
      ('a0000000-0000-0000-0000-000000000105', 'inactive@rls.test');

    insert into public.profiles (id, person_id, active)
    values
      (
        'a0000000-0000-0000-0000-000000000101',
        '10000000-0000-0000-0000-000000000101', true
      ),
      (
        'a0000000-0000-0000-0000-000000000102',
        '10000000-0000-0000-0000-000000000102', true
      ),
      (
        'a0000000-0000-0000-0000-000000000103',
        '10000000-0000-0000-0000-000000000103', true
      ),
      (
        'a0000000-0000-0000-0000-000000000104',
        '10000000-0000-0000-0000-000000000104', true
      ),
      (
        'a0000000-0000-0000-0000-000000000105',
        '10000000-0000-0000-0000-000000000105', false
      );

    insert into public.profile_roles (profile_id, role)
    values
      ('a0000000-0000-0000-0000-000000000101', 'administrator'),
      ('a0000000-0000-0000-0000-000000000102', 'pmo_officer'),
      ('a0000000-0000-0000-0000-000000000103', 'pmo_officer'),
      ('a0000000-0000-0000-0000-000000000104', 'leadership_viewer'),
      ('a0000000-0000-0000-0000-000000000105', 'pmo_officer');

    insert into public.priorities (id, name, sort_order)
    values ('20000000-0000-0000-0000-000000000101', 'RLS Priority', 101);

    insert into public.projects (
      id, code, name, priority_id, state, pmo_officer_id, ball_owner_id
    ) values (
      project_id, 'RLS-001', 'RLS Project',
      '20000000-0000-0000-0000-000000000101', 'Pipeline',
      officer_id, officer_id
    );

    insert into public.project_pmo_assignments (
      project_id, person_id, effective_from
    ) values (project_id, officer_id, transaction_timestamp() - interval '1 minute');

    insert into public.project_participant_assignments (
      project_id, person_id, participant_group, effective_from
    ) values (
      project_id, officer_id, 'PMO', transaction_timestamp() - interval '1 minute'
    );

    insert into public.project_events (
      project_id, event_type, effective_at, actor_id, payload,
      resulting_state, resulting_ball_owner_id, resulting_ball_owner_name
    ) values (
      project_id, 'project_created', transaction_timestamp(),
      'a0000000-0000-0000-0000-000000000101',
      '{"code":"RLS-001","name":"RLS Project"}', 'Pipeline', officer_id,
      'RLS Assigned PMO'
    );

    insert into public.audit_log (
      entity_type, entity_id, action, actor_id
    ) values (
      'project', project_id, 'fixture_created',
      'a0000000-0000-0000-0000-000000000101'
    );

    set constraints all immediate;
  end
  $fixture$;
  $$,
  'RLS role fixtures are valid'
);

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';

select ok(
  pg_temp.throws_sqlstate('select * from public.projects', '42501'),
  'Anonymous users cannot read Projects'
);
select ok(
  pg_temp.throws_sqlstate('select public.current_roles()', '42501'),
  'Anonymous users cannot execute authorization helpers'
);
select ok(
  pg_temp.throws_sqlstate('select public.create_project(''{}''::jsonb)', '42501'),
  'Anonymous users cannot execute Project commands'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000101","role":"authenticated"}';

select ok(public.has_active_profile(), 'Administrator profile is active');
select ok(public.is_admin(), 'Administrator role is recognized');
select ok(
  public.can_edit_project('40000000-0000-0000-0000-000000000101'),
  'Administrator can edit any Project through a command'
);
select is((select count(*) from public.projects), 1::bigint, 'Administrator reads Projects');
select is((select count(*) from public.profiles), 5::bigint, 'Administrator reads all Profiles');
select is((select count(*) from public.profile_roles), 5::bigint, 'Administrator reads all roles');
select is((select count(*) from public.audit_log), 1::bigint, 'Administrator reads audit rows');
select lives_ok(
  $$insert into public.departments (name) values ('Administrator Created')$$,
  'Administrator can create directory rows'
);
select lives_ok(
  $$update public.priorities set sort_order = 102 where name = 'RLS Priority'$$,
  'Administrator can update configuration rows'
);
select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects set name = 'Direct change', version = version + 1$$,
    '42501'
  ),
  'Administrator cannot bypass Project commands with direct updates'
);
select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.audit_log (entity_type, entity_id, action, actor_id)
      values ('project', '40000000-0000-0000-0000-000000000101', 'forged',
      'a0000000-0000-0000-0000-000000000101')$$,
    '42501'
  ),
  'Administrator cannot forge audit rows directly'
);
select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.project_events (
      project_id, event_type, effective_at, actor_id, payload,
      resulting_state, resulting_ball_owner_id, resulting_ball_owner_name
    ) values (
      '40000000-0000-0000-0000-000000000101', 'bump', now(),
      'a0000000-0000-0000-0000-000000000101', '{"text":"forged"}',
      'Pipeline', '10000000-0000-0000-0000-000000000102', 'RLS Assigned PMO'
    )$$,
    '42501'
  ),
  'Administrator cannot append ledger rows directly'
);
select lives_ok(
  $$
  do $test$
  begin
    insert into public.profile_roles (profile_id, role)
    values ('a0000000-0000-0000-0000-000000000104', 'pmo_officer');
    delete from public.profile_roles
    where profile_id = 'a0000000-0000-0000-0000-000000000104'
      and role = 'pmo_officer';
  end
  $test$
  $$,
  'Administrator can add and remove roles'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000102","role":"authenticated"}';

select ok(public.has_active_profile(), 'Assigned PMO profile is active');
select is(
  public.current_roles(), array['pmo_officer']::public.app_role[],
  'Assigned PMO receives only the PMO role'
);
select ok(
  public.can_edit_project('40000000-0000-0000-0000-000000000101'),
  'Assigned PMO can edit their Project through a command'
);
select is((select count(*) from public.projects), 1::bigint, 'Assigned PMO reads Projects');
select is((select count(*) from public.profiles), 1::bigint, 'Assigned PMO reads only own Profile');
select is((select count(*) from public.profile_roles), 1::bigint, 'Assigned PMO reads only own roles');
select is((select count(*) from public.audit_log), 0::bigint, 'Assigned PMO cannot read audit rows');
select ok(
  pg_temp.throws_sqlstate(
    $$insert into public.departments (name) values ('PMO Forged')$$,
    '42501'
  ),
  'Assigned PMO cannot create directory rows'
);
select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects set name = 'PMO direct', version = version + 1$$,
    '42501'
  ),
  'Assigned PMO cannot bypass Project commands with direct updates'
);
select ok(
  pg_temp.throws_sqlstate(
    $$update public.project_events set payload = '{}'$$,
    '42501'
  ),
  'Assigned PMO cannot update ledger rows directly'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000103","role":"authenticated"}';

select ok(
  not public.can_edit_project('40000000-0000-0000-0000-000000000101'),
  'Unassigned PMO cannot edit another PMO Project'
);
select is((select count(*) from public.projects), 1::bigint, 'Unassigned PMO still reads Projects');
select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects set name = 'Unassigned direct', version = version + 1$$,
    '42501'
  ),
  'Unassigned PMO cannot update Projects directly'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000104","role":"authenticated"}';

select is(
  public.current_roles(), array['leadership_viewer']::public.app_role[],
  'Leadership Viewer role is recognized'
);
select ok(
  not public.can_edit_project('40000000-0000-0000-0000-000000000101'),
  'Leadership Viewer cannot edit Projects'
);
select is((select count(*) from public.projects), 1::bigint, 'Leadership Viewer reads Projects');
select is(
  pg_temp.affected_rows($$update public.priorities set sort_order = 999$$),
  0::bigint,
  'Leadership Viewer cannot update configuration'
);
select ok(
  pg_temp.throws_sqlstate(
    $$update public.projects set name = 'Leadership direct', version = version + 1$$,
    '42501'
  ),
  'Leadership Viewer cannot update Projects directly'
);
select is((select count(*) from public.audit_log), 0::bigint, 'Leadership Viewer cannot read audit rows');
select is(
  pg_temp.affected_rows(
    $$delete from public.profile_roles
      where profile_id = 'a0000000-0000-0000-0000-000000000102'$$
  ),
  0::bigint,
  'Leadership Viewer cannot remove roles'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000105","role":"authenticated"}';

select ok(not public.has_active_profile(), 'Inactive Profile is rejected');
select is(
  public.current_roles(), '{}'::public.app_role[],
  'Inactive Profile receives no roles'
);
select is((select count(*) from public.projects), 0::bigint, 'Inactive Profile reads no Projects');
select is((select count(*) from public.profiles), 0::bigint, 'Inactive Profile cannot read itself');
select ok(
  not public.can_edit_project('40000000-0000-0000-0000-000000000101'),
  'Inactive Profile cannot edit Projects'
);

reset role;
set local role service_role;
reset request.jwt.claims;

select is((select count(*) from public.projects), 1::bigint, 'Service role bypasses Project RLS');
select is((select count(*) from public.audit_log), 1::bigint, 'Service role bypasses audit RLS');

reset role;
select is(
  (
    select count(*)
    from pg_class as relation
    join pg_namespace as namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relkind = 'r'
      and not relation.relrowsecurity
  ),
  0::bigint,
  'Every public table has RLS enabled'
);
select is(
  (
    select count(*)
    from information_schema.table_privileges
    where table_schema = 'public' and grantee = 'anon'
  ),
  0::bigint,
  'Anonymous has no public table privileges'
);
select is(
  (
    select count(*)
    from information_schema.table_privileges
    where table_schema = 'public'
      and grantee = 'authenticated'
      and table_name in (
        'projects', 'project_pmo_assignments', 'project_system_scopes',
        'project_participant_assignments', 'project_references',
        'project_stages', 'stage_plan_revisions', 'closeout_assessments',
        'project_events', 'audit_log'
      )
      and privilege_type <> 'SELECT'
  ),
  0::bigint,
  'Authenticated users have no direct Project or ledger write grants'
);
select is(
  (
    select count(*)
    from pg_proc as procedure
    join pg_namespace as namespace on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'public'
      and procedure.prosecdef
      and not coalesce(
        procedure.proconfig @> array['search_path=""'],
        false
      )
  ),
  0::bigint,
  'Every SECURITY DEFINER function fixes an empty search path'
);
select is(
  (
    select count(*)
    from pg_proc as procedure
    join pg_namespace as namespace on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'public'
      and has_function_privilege('anon', procedure.oid, 'execute')
  ),
  0::bigint,
  'Anonymous cannot execute public-schema functions'
);

select * from finish();
rollback;
