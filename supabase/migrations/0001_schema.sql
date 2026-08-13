create extension if not exists pgcrypto;
create extension if not exists citext;
create type public.app_role as enum ('administrator','pmo_officer','leadership_viewer');
create type public.project_state as enum ('Pipeline','Planned','Active','On Hold','Cancelled','Closed');
create type public.participant_group as enum ('PMO','Developer','System Owner');
create type public.project_event_type as enum ('project_created','project_changed','progress','bump','state_changed','ball_transferred','workflow_changed','participant_changed','pmo_reassigned','plan_revised','corrected','archived');

create table departments(id uuid primary key default gen_random_uuid(), name text not null unique, active boolean not null default true, created_at timestamptz not null default now());
create table people(id uuid primary key default gen_random_uuid(), name text not null, department_id uuid not null references departments, username citext not null unique, position text not null, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table profiles(id uuid primary key references auth.users on delete cascade, person_id uuid not null unique references people, active boolean not null default true, created_at timestamptz not null default now());
create table profile_roles(profile_id uuid references profiles on delete cascade, role app_role not null, primary key(profile_id,role));
create table systems(id uuid primary key default gen_random_uuid(), name text not null unique, active boolean not null default true, created_at timestamptz not null default now());
create table modules(id uuid primary key default gen_random_uuid(), system_id uuid not null references systems, name text not null, active boolean not null default true, unique(system_id,name));
create table system_developer_assignments(id uuid primary key default gen_random_uuid(), system_id uuid not null references systems, person_id uuid not null references people, effective_from timestamptz not null, effective_to timestamptz, check(effective_to is null or effective_to > effective_from));
create unique index one_current_developer_assignment on system_developer_assignments(system_id,person_id) where effective_to is null;
create table module_owner_assignments(id uuid primary key default gen_random_uuid(), module_id uuid not null references modules, person_id uuid not null references people, effective_from timestamptz not null, effective_to timestamptz, check(effective_to is null or effective_to > effective_from));
create unique index one_current_module_owner on module_owner_assignments(module_id) where effective_to is null;

create table priorities(id uuid primary key default gen_random_uuid(), name text not null unique, sort_order int not null, active boolean not null default true);
create table request_types(id uuid primary key default gen_random_uuid(), name text not null unique, active boolean not null default true);
create table reference_types(id uuid primary key default gen_random_uuid(), name text not null unique, active boolean not null default true);
create table initiator_types(id uuid primary key default gen_random_uuid(), name text not null unique, active boolean not null default true);
create table workflow_template_stages(id uuid primary key default gen_random_uuid(), name text not null, sort_order int not null unique, detail_label text, detail_help text, detail_required boolean not null default false, detail_multiline boolean not null default false, active boolean not null default true);
create table initiatives(id uuid primary key default gen_random_uuid(), name text not null unique, active boolean not null default true);

create table projects(id uuid primary key default gen_random_uuid(), code citext not null unique, name text not null, initiative_id uuid references initiatives, priority_id uuid not null references priorities, scope text, state project_state not null, current_stage_id uuid, pmo_officer_id uuid not null references people, ball_owner_id uuid references people, request_type_id uuid references request_types, initiator_type_id uuid references initiator_types, requester_id uuid references people, requester_department_name text, archived_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version bigint not null default 1, check(state in ('Cancelled','Closed') or ball_owner_id is not null));
create table project_pmo_assignments(id uuid primary key default gen_random_uuid(), project_id uuid not null references projects, person_id uuid not null references people, effective_from timestamptz not null, effective_to timestamptz);
create unique index one_current_pmo on project_pmo_assignments(project_id) where effective_to is null;
create table project_system_scopes(id uuid primary key default gen_random_uuid(), project_id uuid not null references projects on delete cascade, system_id uuid not null references systems, entire_system boolean not null default false, module_id uuid references modules, check((entire_system and module_id is null) or (not entire_system and module_id is not null)));
create table project_participant_assignments(id uuid primary key default gen_random_uuid(), project_id uuid not null references projects, person_id uuid not null references people, participant_group participant_group not null, effective_from timestamptz not null, effective_to timestamptz);
create unique index one_current_project_participant on project_participant_assignments(project_id,person_id,participant_group) where effective_to is null;
create table project_references(id uuid primary key default gen_random_uuid(), project_id uuid not null references projects on delete cascade, reference_type_id uuid not null references reference_types, label text not null, url text not null check(url ~ '^https?://'), active boolean not null default true);
create table project_stages(id uuid primary key default gen_random_uuid(), project_id uuid not null references projects on delete cascade, template_stage_id uuid references workflow_template_stages, name text not null, sort_order int not null, detail_label text, detail_help text, detail_required boolean not null default false, detail_multiline boolean not null default false, visited boolean not null default false, active boolean not null default true, unique(project_id,sort_order));
alter table projects add constraint projects_current_stage_fk foreign key(current_stage_id) references project_stages deferrable initially deferred;
create table stage_plan_revisions(id uuid primary key default gen_random_uuid(), project_id uuid not null references projects, project_stage_id uuid not null references project_stages, planned_date date, reason text not null, effective_at timestamptz not null, recorded_at timestamptz not null default now(), actor_id uuid not null references profiles);
create table closeout_assessments(id uuid primary key default gen_random_uuid(), project_id uuid not null unique references projects, dod_met boolean not null, dod_explanation text not null, methodology_compliant boolean not null, methodology_explanation text not null, documentation_complete boolean not null, documentation_explanation text not null, stakeholder_rating int check(stakeholder_rating between 1 and 5), stakeholder_comment text, recorded_at timestamptz not null default now(), actor_id uuid not null references profiles);

create table project_events(id uuid primary key default gen_random_uuid(), project_id uuid not null references projects, event_type project_event_type not null, effective_at timestamptz not null, recorded_at timestamptz not null default now(), actor_id uuid not null references profiles, payload jsonb not null default '{}', resulting_state project_state, resulting_stage_id uuid references project_stages, resulting_stage_label text, resulting_ball_owner_id uuid references people, resulting_ball_owner_name text, supersedes_event_id uuid references project_events, correction_reason text, created_transaction_id bigint not null default txid_current());
create unique index one_correction_per_event on project_events(supersedes_event_id) where supersedes_event_id is not null;
create index project_events_timeline on project_events(project_id,effective_at,recorded_at,id);
create table audit_log(id uuid primary key default gen_random_uuid(), entity_type text not null, entity_id uuid not null, action text not null, before_data jsonb, after_data jsonb, actor_id uuid not null references profiles, recorded_at timestamptz not null default now());

create or replace function current_roles() returns app_role[] language sql stable security definer set search_path=public as $$ select coalesce(array_agg(role), '{}') from profile_roles pr join profiles p on p.id=pr.profile_id where pr.profile_id=auth.uid() and p.active $$;
create or replace function is_admin() returns boolean language sql stable security definer set search_path=public as $$ select 'administrator'=any(current_roles()) $$;
create or replace function can_edit_project(pid uuid) returns boolean language sql stable security definer set search_path=public as $$ select is_admin() or exists(select 1 from projects p join profiles pr on pr.person_id=p.pmo_officer_id where p.id=pid and pr.id=auth.uid() and 'pmo_officer'=any(current_roles())) $$;
create or replace function prevent_project_identity_mutation() returns trigger language plpgsql as $$ begin if old.code <> new.code then raise exception 'Project Code is immutable'; end if; return new; end $$;
create trigger immutable_project_code before update on projects for each row execute function prevent_project_identity_mutation();
create or replace function immutable_event_fields() returns trigger language plpgsql as $$ begin if old.recorded_at <> new.recorded_at or old.actor_id <> new.actor_id then raise exception 'Recorded timestamp and actor are immutable'; end if; return new; end $$;
create trigger immutable_project_event_fields before update on project_events for each row execute function immutable_event_fields();
create or replace function prevent_event_delete() returns trigger language plpgsql as $$ begin raise exception 'Project events are append-only'; end $$;
create trigger no_project_event_delete before delete on project_events for each row execute function prevent_event_delete();

create or replace function create_project(input jsonb) returns uuid language plpgsql security invoker set search_path=public as $$
declare pid uuid:=gen_random_uuid(); actor uuid:=auth.uid(); officer uuid:=(input->>'pmoOfficerId')::uuid; owner uuid:=(input->>'ballOwnerId')::uuid; initial_state project_state:=(input->>'state')::project_state;
begin
 if not ('administrator'=any(current_roles()) or 'pmo_officer'=any(current_roles())) then raise exception 'Permission denied'; end if;
 if initial_state in ('Cancelled','Closed') then raise exception 'A new Project cannot begin terminal'; end if;
 if not exists(select 1 from people where id=officer and active) or not exists(select 1 from people where id=owner and active) then raise exception 'Assignments require active People'; end if;
 insert into projects(id,code,name,priority_id,scope,state,pmo_officer_id,ball_owner_id) values(pid,input->>'code',input->>'name',(input->>'priorityId')::uuid,nullif(input->>'scope',''),initial_state,officer,owner);
 insert into project_pmo_assignments(project_id,person_id,effective_from) values(pid,officer,now());
 insert into project_participant_assignments(project_id,person_id,participant_group,effective_from) values(pid,officer,'PMO',now());
 if owner<>officer then raise exception 'Add the initial Ball Owner as a participant before creation'; end if;
 insert into project_stages(project_id,template_stage_id,name,sort_order,detail_label,detail_help,detail_required,detail_multiline) select pid,id,name,sort_order,detail_label,detail_help,detail_required,detail_multiline from workflow_template_stages where active order by sort_order;
 insert into project_events(project_id,event_type,effective_at,actor_id,payload,resulting_state,resulting_ball_owner_id,resulting_ball_owner_name) select pid,'project_created',now(),actor,jsonb_build_object('code',input->>'code','name',input->>'name'),initial_state,owner,p.name from people p where p.id=owner;
 return pid;
end $$;

create or replace function append_project_event(input jsonb) returns uuid language plpgsql security invoker set search_path=public as $$
declare p projects%rowtype; eid uuid:=gen_random_uuid(); kind project_event_type:=(input->>'eventType')::project_event_type; effective timestamptz:=(input->>'effectiveAt')::timestamptz; owner uuid:=(input->>'ballOwnerId')::uuid; next_state project_state; stage uuid; owner_name text;
begin
 select * into p from projects where id=(input->>'projectId')::uuid for update;
 if not found or not can_edit_project(p.id) then raise exception 'Permission denied'; end if;
 if p.version<>(input->>'version')::bigint then raise exception 'CONFLICT: Project changed since this form loaded'; end if;
 if p.state in ('Cancelled','Closed') then raise exception 'Terminal Projects cannot be changed'; end if;
 if not exists(select 1 from project_participant_assignments pa join people pe on pe.id=pa.person_id where pa.project_id=p.id and pa.person_id=owner and pa.effective_to is null and pe.active) then raise exception 'Ball Owner must be an active Project Participant'; end if;
 select name into owner_name from people where id=owner;
 next_state:=coalesce((input->>'resultingState')::project_state,p.state); stage:=coalesce((input->>'stageId')::uuid,p.current_stage_id);
 if next_state in ('Planned','Active') and (p.request_type_id is null or p.requester_id is null or coalesce(trim(p.scope),'')='' or not exists(select 1 from project_system_scopes where project_id=p.id)) then raise exception 'Complete request, scope, affected areas, and participants first'; end if;
 if kind='progress' then update project_stages set visited=true where id=stage and project_id=p.id; end if;
 insert into project_events(id,project_id,event_type,effective_at,actor_id,payload,resulting_state,resulting_stage_id,resulting_stage_label,resulting_ball_owner_id,resulting_ball_owner_name) select eid,p.id,kind,effective,auth.uid(),input->'payload',next_state,stage,ps.name,owner,owner_name from (select 1) x left join project_stages ps on ps.id=stage;
 update projects set state=next_state,current_stage_id=case when kind='progress' then stage else current_stage_id end,ball_owner_id=owner,updated_at=now(),version=version+1 where id=p.id;
 return eid;
end $$;

create or replace function correct_project_event(input jsonb) returns uuid language plpgsql security invoker set search_path=public as $$
declare original project_events%rowtype; eid uuid:=gen_random_uuid();
begin
 if not is_admin() then raise exception 'Only Administrators may correct history'; end if;
 select * into original from project_events where id=(input->>'eventId')::uuid for update;
 if not found or original.supersedes_event_id is not null then raise exception 'Event cannot be corrected'; end if;
 insert into project_events(id,project_id,event_type,effective_at,actor_id,payload,resulting_state,resulting_stage_id,resulting_stage_label,resulting_ball_owner_id,resulting_ball_owner_name,supersedes_event_id,correction_reason) values(eid,original.project_id,'corrected',(input->>'effectiveAt')::timestamptz,auth.uid(),input->'payload',coalesce((input->>'resultingState')::project_state,original.resulting_state),coalesce((input->>'stageId')::uuid,original.resulting_stage_id),original.resulting_stage_label,coalesce((input->>'ballOwnerId')::uuid,original.resulting_ball_owner_id),original.resulting_ball_owner_name,original.id,input->>'reason');
 return eid;
end $$;

alter table departments enable row level security; alter table people enable row level security; alter table profiles enable row level security; alter table profile_roles enable row level security; alter table systems enable row level security; alter table modules enable row level security; alter table system_developer_assignments enable row level security; alter table module_owner_assignments enable row level security; alter table priorities enable row level security; alter table request_types enable row level security; alter table reference_types enable row level security; alter table initiator_types enable row level security; alter table workflow_template_stages enable row level security; alter table initiatives enable row level security; alter table projects enable row level security; alter table project_pmo_assignments enable row level security; alter table project_system_scopes enable row level security; alter table project_participant_assignments enable row level security; alter table project_references enable row level security; alter table project_stages enable row level security; alter table stage_plan_revisions enable row level security; alter table closeout_assessments enable row level security; alter table project_events enable row level security; alter table audit_log enable row level security;
do $$ declare t text; begin foreach t in array array['departments','people','systems','modules','system_developer_assignments','module_owner_assignments','priorities','request_types','reference_types','initiator_types','workflow_template_stages','initiatives','projects','project_pmo_assignments','project_system_scopes','project_participant_assignments','project_references','project_stages','stage_plan_revisions','closeout_assessments','project_events','audit_log'] loop execute format('create policy authenticated_read on %I for select to authenticated using (exists(select 1 from profiles where id=auth.uid() and active))',t); end loop; end $$;
create policy own_profile_read on profiles for select to authenticated using(id=auth.uid() or is_admin());
create policy own_roles_read on profile_roles for select to authenticated using(profile_id=auth.uid() or is_admin());
do $$ declare t text; begin foreach t in array array['departments','people','systems','modules','system_developer_assignments','module_owner_assignments','priorities','request_types','reference_types','initiator_types','workflow_template_stages','initiatives','profiles','profile_roles','audit_log'] loop execute format('create policy admin_all on %I for all to authenticated using (is_admin()) with check (is_admin())',t); end loop; end $$;
do $$ declare t text; begin foreach t in array array['projects','project_pmo_assignments','project_system_scopes','project_participant_assignments','project_references','project_stages','stage_plan_revisions','closeout_assessments','project_events'] loop execute format('create policy project_editor_write on %I for all to authenticated using (can_edit_project(%s)) with check (can_edit_project(%s))',t,case when t='projects' then 'id' else 'project_id' end,case when t='projects' then 'id' else 'project_id' end); end loop; end $$;
