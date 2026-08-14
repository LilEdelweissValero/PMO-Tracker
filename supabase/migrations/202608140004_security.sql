create function public.current_roles()
returns public.app_role[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(pr.role), '{}'::public.app_role[])
  from public.profile_roles as pr
  join public.profiles as p on p.id = pr.profile_id
  where pr.profile_id = (select auth.uid())
    and p.active;
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

create function public.can_edit_project(project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_admin()
    or exists (
      select 1
      from public.projects as p
      join public.profiles as pr on pr.person_id = p.pmo_officer_id
      where p.id = project_id
        and pr.id = (select auth.uid())
        and 'pmo_officer'::public.app_role = any(public.current_roles())
    );
$$;

revoke all on function public.current_roles() from public, anon;
revoke all on function public.is_admin() from public, anon;
revoke all on function public.can_edit_project(uuid) from public, anon;
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
    'project_events',
    'audit_log'
  ]
  loop
    execute format(
      'create policy authenticated_read on public.%I for select to authenticated using (exists (select 1 from public.profiles where id = (select auth.uid()) and active))',
      table_name
    );
  end loop;
end;
$$;

create policy own_profile_read
on public.profiles
for select
to authenticated
using (id = (select auth.uid()) or public.is_admin());

create policy own_roles_read
on public.profile_roles
for select
to authenticated
using (profile_id = (select auth.uid()) or public.is_admin());

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
    'profiles',
    'profile_roles',
    'audit_log'
  ]
  loop
    execute format(
      'create policy admin_all on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())',
      table_name
    );
  end loop;
end;
$$;

do $$
declare
  table_name text;
  project_key text;
begin
  foreach table_name in array array[
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
    project_key := case when table_name = 'projects' then 'id' else 'project_id' end;
    execute format(
      'create policy project_editor_write on public.%I for all to authenticated using (public.can_edit_project(%I)) with check (public.can_edit_project(%I))',
      table_name,
      project_key,
      project_key
    );
  end loop;
end;
$$;

revoke all privileges on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant all privileges on all tables in schema public to service_role;

comment on function public.current_roles() is
  'Returns roles for the active authenticated profile while bypassing RLS recursion.';
comment on function public.is_admin() is
  'True when the active authenticated profile has the Administrator role.';
comment on function public.can_edit_project(uuid) is
  'True for Administrators or the active PMO Officer assigned to the project.';
