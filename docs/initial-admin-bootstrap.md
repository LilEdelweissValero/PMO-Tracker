# Initial Administrator bootstrap

Use this once, after the hosted migrations are applied and before anyone else
receives application access. Public registration stays disabled.

## 1. Create the Auth user

In Supabase Dashboard, open **Authentication → Users → Add user**. Create the
initial Administrator with their work email and a strong temporary password.
Copy the resulting User UUID. Do not copy a service-role key into SQL or chat.

## 2. Run one database transaction

In Supabase SQL Editor, replace every `REPLACE_...` value below, review the
resolved Person details, and run the block once. The Profile ID must exactly
match the Auth User UUID and the email must match the Auth user.

```sql
begin;

do $$
declare
  auth_user_id uuid := 'REPLACE_AUTH_USER_UUID';
  work_email extensions.citext := 'REPLACE_WORK_EMAIL';
  department_name text := 'REPLACE_DEPARTMENT';
  person_name text := 'REPLACE_DISPLAY_NAME';
  person_username text := 'REPLACE_USERNAME';
  person_position text := 'REPLACE_POSITION';
  department_id uuid;
  person_id uuid;
begin
  if not exists (
    select 1 from auth.users
    where id = auth_user_id and email::extensions.citext = work_email
  ) then
    raise exception 'Auth User UUID and email do not match';
  end if;

  insert into public.departments (name)
  values (department_name)
  on conflict (name) do update set name = excluded.name
  returning id into department_id;

  insert into public.people (
    name, department_id, username, position
  ) values (
    person_name, department_id, person_username, person_position
  )
  returning id into person_id;

  insert into public.profiles (id, person_id, email)
  values (auth_user_id, person_id, work_email);

  insert into public.profile_roles (profile_id, role)
  values
    (auth_user_id, 'administrator'),
    (auth_user_id, 'pmo_officer');
end;
$$;

commit;
```

Any error rolls back the Department, Person, Profile, and roles together. Do
not retry without first reading the error; duplicate email, username, Person,
or Profile constraints indicate that access may already be linked.

## 3. Verify and hand off

1. Sign in at `/login` using the initial account.
2. Confirm the sidebar shows the correct Person and both roles.
3. Open `/admin/access` and provision a second Administrator before changing
   the bootstrap account.
4. Confirm PMO and Leadership invitations arrive through the configured
   Supabase SMTP provider.

The database rejects any role or account change that would leave no active
Administrator. Subsequent accounts must be created through **Application
access**, which compensates Auth creation if Profile linking fails.
