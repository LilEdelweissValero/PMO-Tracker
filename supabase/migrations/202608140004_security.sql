create function public.has_active_profile()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles as profile
    join public.people as person on person.id = profile.person_id
    where profile.id = (select auth.uid())
      and profile.active
      and person.active
  );
$$;

create function public.current_roles()
returns public.app_role[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(profile_role.role), '{}'::public.app_role[])
  from public.profile_roles as profile_role
  join public.profiles as profile on profile.id = profile_role.profile_id
  join public.people as person on person.id = profile.person_id
  where profile_role.profile_id = (select auth.uid())
    and profile.active
    and person.active;
$$;

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select 'administrator'::public.app_role = any(public.current_roles());
$$;

create function public.can_edit_project(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_admin()
    or exists (
      select 1
      from public.projects as project
      join public.project_pmo_assignments as assignment
        on assignment.project_id = project.id
       and assignment.person_id = project.pmo_officer_id
       and assignment.effective_from <= transaction_timestamp()
       and (
         assignment.effective_to is null
         or assignment.effective_to > transaction_timestamp()
       )
      join public.profiles as profile
        on profile.person_id = assignment.person_id
       and profile.id = (select auth.uid())
       and profile.active
      join public.people as person
        on person.id = assignment.person_id
       and person.active
      where project.id = target_project_id
        and 'pmo_officer'::public.app_role = any(public.current_roles())
    );
$$;

revoke create on schema public from public, anon, authenticated;
grant usage on schema public to anon, authenticated, service_role;

revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.has_active_profile() to authenticated, service_role;
grant execute on function public.current_roles() to authenticated, service_role;
grant execute on function public.is_admin() to authenticated, service_role;
grant execute on function public.can_edit_project(uuid) to authenticated, service_role;

alter table public.departments enable row level security;
alter table public.people enable row level security;
alter table public.profiles enable row level security;
alter table public.profile_roles enable row level security;
alter table public.systems enable row level security;
alter table public.modules enable row level security;
alter table public.system_developer_assignments enable row level security;
alter table public.module_owner_assignments enable row level security;
alter table public.priorities enable row level security;
alter table public.request_types enable row level security;
alter table public.reference_types enable row level security;
alter table public.initiator_types enable row level security;
alter table public.workflow_template_stages enable row level security;
alter table public.initiatives enable row level security;
alter table public.projects enable row level security;
alter table public.project_pmo_assignments enable row level security;
alter table public.project_system_scopes enable row level security;
alter table public.project_participant_assignments enable row level security;
alter table public.project_references enable row level security;
alter table public.project_stages enable row level security;
alter table public.stage_plan_revisions enable row level security;
alter table public.closeout_assessments enable row level security;
alter table public.project_events enable row level security;
alter table public.audit_log enable row level security;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'departments',
    'people',
    'systems',
    'modules',
    'system_developer_assignments',
    'module_owner_assignments',
    'priorities',
    'request_types',
    'reference_types',
    'initiator_types',
    'workflow_template_stages',
    'initiatives',
    'projects',
    'project_pmo_assignments',
    'project_system_scopes',
    'project_participant_assignments',
    'project_references',
    'project_stages',
    'stage_plan_revisions',
    'closeout_assessments',
    'project_events'
  ]
  loop
    execute format(
      'create policy active_profile_read on public.%I for select to authenticated using ((select public.has_active_profile()))',
      table_name
    );
  end loop;
end;
$$;

create policy own_or_administrator_profile_read
on public.profiles
for select
to authenticated
using (
  (
    id = (select auth.uid())
    and active
    and exists (
      select 1 from public.people
      where id = person_id and active
    )
  )
  or (select public.is_admin())
);

create policy own_or_administrator_role_read
on public.profile_roles
for select
to authenticated
using (
  (
    profile_id = (select auth.uid())
    and (select public.has_active_profile())
  )
  or (select public.is_admin())
);

create policy administrator_audit_read
on public.audit_log
for select
to authenticated
using ((select public.is_admin()));

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'departments',
    'people',
    'systems',
    'modules',
    'system_developer_assignments',
    'module_owner_assignments',
    'priorities',
    'request_types',
    'reference_types',
    'initiator_types',
    'workflow_template_stages',
    'initiatives',
    'profiles'
  ]
  loop
    execute format(
      'create policy administrator_insert on public.%I for insert to authenticated with check ((select public.is_admin()))',
      table_name
    );
    execute format(
      'create policy administrator_update on public.%I for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()))',
      table_name
    );
  end loop;
end;
$$;

create policy administrator_role_insert
on public.profile_roles
for insert
to authenticated
with check ((select public.is_admin()));

create policy administrator_role_delete
on public.profile_roles
for delete
to authenticated
using ((select public.is_admin()));

revoke all privileges on all tables in schema public
from public, anon, authenticated;

grant select on table
  public.departments,
  public.people,
  public.systems,
  public.modules,
  public.system_developer_assignments,
  public.module_owner_assignments,
  public.priorities,
  public.request_types,
  public.reference_types,
  public.initiator_types,
  public.workflow_template_stages,
  public.initiatives,
  public.projects,
  public.project_pmo_assignments,
  public.project_system_scopes,
  public.project_participant_assignments,
  public.project_references,
  public.project_stages,
  public.stage_plan_revisions,
  public.closeout_assessments,
  public.project_events,
  public.profiles,
  public.profile_roles,
  public.audit_log
to authenticated;

grant insert, update on table
  public.departments,
  public.people,
  public.systems,
  public.modules,
  public.system_developer_assignments,
  public.module_owner_assignments,
  public.priorities,
  public.request_types,
  public.reference_types,
  public.initiator_types,
  public.workflow_template_stages,
  public.initiatives,
  public.profiles
to authenticated;

grant insert, delete on table public.profile_roles to authenticated;
grant all privileges on all tables in schema public to service_role;

comment on function public.has_active_profile() is
  'True only for an Auth user linked to active Profile and Person rows.';
comment on function public.current_roles() is
  'Returns additive roles for the active authenticated Profile while bypassing RLS recursion.';
comment on function public.is_admin() is
  'True when the active authenticated Profile has the Administrator role.';
comment on function public.can_edit_project(uuid) is
  'True for Administrators or the active, currently assigned PMO Officer.';
