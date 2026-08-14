alter table public.profiles
  add column email extensions.citext;

create unique index profiles_email_unique
  on public.profiles (email)
  where email is not null;

create function public.protect_last_active_administrator()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affects_administrator boolean := false;
begin
  if tg_table_name = 'profile_roles' then
    affects_administrator := old.role = 'administrator' and (
      tg_op = 'DELETE' or new.role <> 'administrator'
    );
  elsif tg_table_name = 'profiles' then
    affects_administrator := old.active and (
      tg_op = 'DELETE' or not new.active
    ) and exists (
      select 1 from public.profile_roles
      where profile_id = old.id and role = 'administrator'
    );
  elsif tg_table_name = 'people' then
    affects_administrator := old.active and (
      tg_op = 'DELETE' or not new.active
    ) and exists (
      select 1
      from public.profiles as profile
      join public.profile_roles as role on role.profile_id = profile.id
      where profile.person_id = old.id
        and profile.active
        and role.role = 'administrator'
    );
  end if;

  if affects_administrator and not exists (
    select 1
    from public.profiles as profile
    join public.people as person on person.id = profile.person_id
    join public.profile_roles as role on role.profile_id = profile.id
    where profile.active
      and person.active
      and role.role = 'administrator'
  ) then
    raise exception using
      errcode = '23514',
      message = 'At least one active Administrator account is required';
  end if;

  return null;
end;
$$;

create constraint trigger protect_last_administrator_role
after update or delete on public.profile_roles
deferrable initially deferred
for each row execute function public.protect_last_active_administrator();

create constraint trigger protect_last_administrator_profile
after update or delete on public.profiles
deferrable initially deferred
for each row execute function public.protect_last_active_administrator();

create constraint trigger zz_protect_last_administrator_person
after update or delete on public.people
deferrable initially deferred
for each row execute function public.protect_last_active_administrator();

create function public.provision_profile(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  auth_user_id uuid := (input ->> 'authUserId')::uuid;
  target_person_id uuid := (input ->> 'personId')::uuid;
  target_email extensions.citext := nullif(btrim(input ->> 'email'), '')::extensions.citext;
  role_count integer;
  total_role_count integer;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Only Administrators may provision accounts';
  end if;

  if target_email is null
    or jsonb_typeof(input -> 'roles') <> 'array'
    or jsonb_array_length(input -> 'roles') = 0
  then
    raise exception using errcode = '22023', message = 'Email and at least one role are required';
  end if;

  if not exists (
    select 1 from auth.users
    where id = auth_user_id and email::extensions.citext = target_email
  ) then
    raise exception using errcode = '22023', message = 'Auth user and email do not match';
  end if;

  if not exists (
    select 1 from public.people where id = target_person_id and active
  ) then
    raise exception using errcode = '22023', message = 'Choose an active Person';
  end if;

  if exists (
    select 1 from public.profiles
    where id = auth_user_id or person_id = target_person_id or email = target_email
  ) then
    raise exception using errcode = '23505', message = 'This Auth user, Person, or email already has access';
  end if;

  select count(distinct value), count(*)
  into role_count, total_role_count
  from jsonb_array_elements_text(input -> 'roles') as role(value);

  if exists (
    select 1
    from jsonb_array_elements_text(input -> 'roles') as role(value)
    where value not in ('administrator', 'pmo_officer', 'leadership_viewer')
  ) or role_count <> total_role_count then
    raise exception using errcode = '22023', message = 'Roles must be valid and unique';
  end if;

  insert into public.profiles (id, person_id, email)
  values (auth_user_id, target_person_id, target_email);

  insert into public.profile_roles (profile_id, role)
  select auth_user_id, value::public.app_role
  from jsonb_array_elements_text(input -> 'roles') as role(value);

  insert into public.audit_log (
    entity_type, entity_id, action, after_data, actor_id
  ) values (
    'profile', auth_user_id, 'account_provisioned', input, (select auth.uid())
  );

  return auth_user_id;
end;
$$;

create function public.manage_profile_access(input jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_profile_id uuid := (input ->> 'profileId')::uuid;
  should_be_active boolean := (input ->> 'active')::boolean;
  before_profile jsonb;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Only Administrators may manage access';
  end if;

  if should_be_active is null
    or jsonb_typeof(input -> 'roles') <> 'array'
    or jsonb_array_length(input -> 'roles') = 0
  then
    raise exception using errcode = '22023', message = 'Account State and at least one role are required';
  end if;

  if exists (
    select 1
    from jsonb_array_elements_text(input -> 'roles') as role(value)
    where value not in ('administrator', 'pmo_officer', 'leadership_viewer')
  ) or (
    select count(distinct value) <> count(*)
    from jsonb_array_elements_text(input -> 'roles') as role(value)
  ) then
    raise exception using errcode = '22023', message = 'Roles must be valid and unique';
  end if;

  select to_jsonb(profile.*) into before_profile
  from public.profiles as profile
  where profile.id = target_profile_id
  for update;

  if before_profile is null then
    raise exception using errcode = 'P0002', message = 'Profile not found';
  end if;

  update public.profiles
  set active = should_be_active
  where id = target_profile_id;

  delete from public.profile_roles as existing
  where existing.profile_id = target_profile_id
    and existing.role::text not in (
      select value from jsonb_array_elements_text(input -> 'roles') as role(value)
    );

  insert into public.profile_roles (profile_id, role)
  select target_profile_id, value::public.app_role
  from jsonb_array_elements_text(input -> 'roles') as role(value)
  on conflict do nothing;

  set constraints all immediate;

  insert into public.audit_log (
    entity_type, entity_id, action, before_data, after_data, actor_id
  ) values (
    'profile', target_profile_id, 'account_access_changed', before_profile,
    jsonb_build_object(
      'profile', (select to_jsonb(profile.*) from public.profiles as profile where id = target_profile_id),
      'roles', input -> 'roles'
    ),
    (select auth.uid())
  );

  return target_profile_id;
end;
$$;

revoke execute on function public.protect_last_active_administrator()
from public, anon, authenticated;
revoke execute on function public.provision_profile(jsonb) from public, anon;
revoke execute on function public.manage_profile_access(jsonb) from public, anon;

grant execute on function public.provision_profile(jsonb) to authenticated;
grant execute on function public.manage_profile_access(jsonb) to authenticated;

comment on function public.provision_profile(jsonb) is
  'Atomically links an existing Auth user to one active Person and additive application roles.';
comment on function public.manage_profile_access(jsonb) is
  'Atomically changes Profile activity and additive roles while preserving an active Administrator.';
