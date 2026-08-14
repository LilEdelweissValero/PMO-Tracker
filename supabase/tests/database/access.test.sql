begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(20);

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

select lives_ok(
  $$
  do $fixture$
  begin
    insert into public.departments (id, name)
    values ('d0000000-0000-0000-0000-000000000401', 'Access Department');

    insert into public.people (id, name, department_id, username, position)
    values
      (
        '10000000-0000-0000-0000-000000000401', 'Access Admin',
        'd0000000-0000-0000-0000-000000000401', 'access.admin', 'Administrator'
      ),
      (
        '10000000-0000-0000-0000-000000000402', 'Access PMO',
        'd0000000-0000-0000-0000-000000000401', 'access.pmo', 'PMO Officer'
      ),
      (
        '10000000-0000-0000-0000-000000000403', 'Access Leadership',
        'd0000000-0000-0000-0000-000000000401', 'access.leadership', 'Leader'
      ),
      (
        '10000000-0000-0000-0000-000000000404', 'Access Admin Two',
        'd0000000-0000-0000-0000-000000000401', 'access.admin2', 'Administrator'
      );

    insert into auth.users (id, email)
    values
      ('a0000000-0000-0000-0000-000000000401', 'admin@access.test'),
      ('a0000000-0000-0000-0000-000000000402', 'pmo@access.test'),
      ('a0000000-0000-0000-0000-000000000403', 'leadership@access.test'),
      ('a0000000-0000-0000-0000-000000000404', 'admin2@access.test');

    insert into public.profiles (id, person_id, email)
    values (
      'a0000000-0000-0000-0000-000000000401',
      '10000000-0000-0000-0000-000000000401', 'admin@access.test'
    );
    insert into public.profile_roles (profile_id, role)
    values ('a0000000-0000-0000-0000-000000000401', 'administrator');
  end
  $fixture$;
  $$,
  'Access fixtures create the initial Administrator'
);

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000401","role":"authenticated"}';

select lives_ok(
  $$select public.provision_profile(jsonb_build_object(
    'authUserId', 'a0000000-0000-0000-0000-000000000402',
    'personId', '10000000-0000-0000-0000-000000000402',
    'email', 'pmo@access.test',
    'roles', jsonb_build_array('pmo_officer')
  ))$$,
  'Administrator provisions a PMO account atomically'
);
select is(
  (select email::text from public.profiles
   where id = 'a0000000-0000-0000-0000-000000000402'),
  'pmo@access.test'::text,
  'Provisioning stores the account email snapshot'
);
select is(
  (select array_agg(role order by role) from public.profile_roles
   where profile_id = 'a0000000-0000-0000-0000-000000000402'),
  array['pmo_officer']::public.app_role[],
  'Provisioning stores additive roles'
);
select is(
  (select count(*) from public.audit_log
   where entity_id = 'a0000000-0000-0000-0000-000000000402'
     and action = 'account_provisioned'),
  1::bigint,
  'Provisioning records audit evidence'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.provision_profile(jsonb_build_object(
      'authUserId', 'a0000000-0000-0000-0000-000000000403',
      'personId', '10000000-0000-0000-0000-000000000402',
      'email', 'leadership@access.test',
      'roles', jsonb_build_array('leadership_viewer')
    ))$$,
    '23505'
  ),
  'A Person cannot receive two application accounts'
);
select is(
  (select count(*) from public.profiles
   where id = 'a0000000-0000-0000-0000-000000000403'),
  0::bigint,
  'Rejected provisioning leaves no partial Profile'
);

select lives_ok(
  $$select public.provision_profile(jsonb_build_object(
    'authUserId', 'a0000000-0000-0000-0000-000000000403',
    'personId', '10000000-0000-0000-0000-000000000403',
    'email', 'leadership@access.test',
    'roles', jsonb_build_array('leadership_viewer')
  ))$$,
  'Administrator provisions a Leadership account'
);
select lives_ok(
  $$select public.manage_profile_access(jsonb_build_object(
    'profileId', 'a0000000-0000-0000-0000-000000000403',
    'active', false,
    'roles', jsonb_build_array('leadership_viewer')
  ))$$,
  'Administrator deactivates access without deactivating the Person'
);
select is(
  (select active from public.profiles
   where id = 'a0000000-0000-0000-0000-000000000403'),
  false,
  'Access management stores the inactive account State'
);
select is(
  (select active from public.people
   where id = '10000000-0000-0000-0000-000000000403'),
  true,
  'Account deactivation leaves the directory Person active'
);

select ok(
  pg_temp.throws_sqlstate(
    $$select public.manage_profile_access(jsonb_build_object(
      'profileId', 'a0000000-0000-0000-0000-000000000401',
      'active', true,
      'roles', jsonb_build_array('pmo_officer')
    ))$$,
    '23514'
  ),
  'The last active Administrator role cannot be removed'
);
select is(
  (select count(*) from public.profile_roles
   where profile_id = 'a0000000-0000-0000-0000-000000000401'
     and role = 'administrator'),
  1::bigint,
  'Rejected last-Administrator mutation rolls back atomically'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.manage_profile_access(jsonb_build_object(
      'profileId', 'a0000000-0000-0000-0000-000000000401',
      'active', false,
      'roles', jsonb_build_array('administrator')
    ))$$,
    '23514'
  ),
  'The last active Administrator Profile cannot be deactivated'
);
select is(
  (select active from public.profiles
   where id = 'a0000000-0000-0000-0000-000000000401'),
  true,
  'Rejected Administrator deactivation preserves the active Profile'
);

select lives_ok(
  $$select public.provision_profile(jsonb_build_object(
    'authUserId', 'a0000000-0000-0000-0000-000000000404',
    'personId', '10000000-0000-0000-0000-000000000404',
    'email', 'admin2@access.test',
    'roles', jsonb_build_array('administrator')
  ))$$,
  'A second Administrator can be provisioned'
);
select lives_ok(
  $$select public.manage_profile_access(jsonb_build_object(
    'profileId', 'a0000000-0000-0000-0000-000000000401',
    'active', true,
    'roles', jsonb_build_array('pmo_officer')
  ))$$,
  'An Administrator role can be removed when another remains active'
);

set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000404","role":"authenticated"}';

select ok(
  pg_temp.throws_sqlstate(
    $$
    do $test$
      begin
        update public.people set active = false
        where id = '10000000-0000-0000-0000-000000000404';
        set constraints all immediate;
      end
    $test$
    $$,
    'P0001'
  ),
  'An active Administrator account prevents Person deactivation'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000402","role":"authenticated"}';

select ok(
  pg_temp.throws_sqlstate(
    $$select public.provision_profile(jsonb_build_object(
      'authUserId', 'a0000000-0000-0000-0000-000000000403',
      'personId', '10000000-0000-0000-0000-000000000403',
      'email', 'leadership@access.test',
      'roles', jsonb_build_array('leadership_viewer')
    ))$$,
    '42501'
  ),
  'PMO Officers cannot invoke account provisioning'
);
select ok(
  pg_temp.throws_sqlstate(
    $$select public.manage_profile_access(jsonb_build_object(
      'profileId', 'a0000000-0000-0000-0000-000000000402',
      'active', false,
      'roles', jsonb_build_array('pmo_officer')
    ))$$,
    '42501'
  ),
  'PMO Officers cannot invoke access management'
);

reset role;
select * from finish();
rollback;
