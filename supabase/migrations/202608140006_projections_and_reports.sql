create view public.effective_project_events
with (security_invoker = true)
as
select
  event.id,
  event.project_id,
  case
    when event.event_type = 'corrected'
      then (event.payload ->> 'correctedEventType')::public.project_event_type
    else event.event_type
  end as effective_event_type,
  event.event_type as recorded_event_type,
  event.effective_at,
  event.recorded_at,
  event.actor_id,
  event.payload,
  event.resulting_state,
  event.resulting_stage_id,
  event.resulting_stage_label,
  event.resulting_ball_owner_id,
  event.resulting_ball_owner_name,
  coalesce(event.supersedes_event_id, event.id) as fact_id,
  event.supersedes_event_id,
  event.correction_reason,
  event.event_type = 'corrected' as is_correction
from public.project_events as event
where not exists (
  select 1
  from public.project_events as correction
  where correction.supersedes_event_id = event.id
);

comment on view public.effective_project_events is
  'Canonical event facts: superseded originals are removed and corrections retain the corrected fact type.';

create view public.project_timeline_intervals
with (security_invoker = true)
as
select
  event.id as event_id,
  event.project_id,
  event.effective_event_type,
  event.effective_at as interval_start,
  lead(event.effective_at) over (
    partition by event.project_id
    order by event.effective_at, event.recorded_at, event.id
  ) as interval_end,
  event.resulting_state,
  event.resulting_stage_id,
  event.resulting_stage_label,
  event.resulting_ball_owner_id,
  event.resulting_ball_owner_name
from public.effective_project_events as event
where event.effective_event_type in (
  'project_created',
  'progress',
  'bump',
  'state_changed',
  'ball_transferred'
);

comment on view public.project_timeline_intervals is
  'Ordered effective projection snapshots expressed as half-open timeline intervals.';

create view public.project_ownership_spans
with (security_invoker = true)
as
with eligible as (
  select
    interval.*,
    lag(interval.resulting_ball_owner_id) over (
      partition by interval.project_id
      order by interval.interval_start, interval.event_id
    ) as previous_owner_id
  from public.project_timeline_intervals as interval
  where interval.resulting_state not in ('Cancelled', 'Closed')
    and interval.resulting_ball_owner_id is not null
), marked as (
  select
    eligible.*,
    case
      when eligible.previous_owner_id = eligible.resulting_ball_owner_id then 0
      else 1
    end as begins_span
  from eligible
), grouped as (
  select
    marked.*,
    sum(marked.begins_span) over (
      partition by marked.project_id
      order by marked.interval_start, marked.event_id
      rows unbounded preceding
    ) as span_number
  from marked
)
select
  grouped.project_id,
  grouped.resulting_ball_owner_id as owner_id,
  max(grouped.resulting_ball_owner_name) as owner_name,
  min(grouped.interval_start) as span_start,
  case
    when bool_or(grouped.interval_end is null) then null
    else max(grouped.interval_end)
  end as span_end
from grouped
group by
  grouped.project_id,
  grouped.resulting_ball_owner_id,
  grouped.span_number;

comment on view public.project_ownership_spans is
  'Contiguous effective Ball ownership periods, ending at transfer or terminal State.';

create view public.project_hold_spans
with (security_invoker = true)
as
with marked as (
  select
    interval.*,
    case
      when lag(interval.resulting_state) over (
        partition by interval.project_id
        order by interval.interval_start, interval.event_id
      ) = 'On Hold'
      then 0
      else 1
    end as begins_span
  from public.project_timeline_intervals as interval
), grouped as (
  select
    marked.*,
    sum(marked.begins_span) over (
      partition by marked.project_id
      order by marked.interval_start, marked.event_id
      rows unbounded preceding
    ) as span_number
  from marked
)
select
  grouped.project_id,
  min(grouped.interval_start) as span_start,
  case
    when bool_or(grouped.interval_end is null) then null
    else max(grouped.interval_end)
  end as span_end
from grouped
where grouped.resulting_state = 'On Hold'
group by grouped.project_id, grouped.span_number;

comment on view public.project_hold_spans is
  'Disjoint effective On Hold periods used to subtract paused time exactly once.';

create view public.project_turnaround_report
with (security_invoker = true)
as
select
  ownership.project_id,
  project.code as project_code,
  project.name as project_name,
  project.state as current_state,
  ownership.owner_id,
  ownership.owner_name,
  participant.participant_group as owner_group,
  ownership.span_start,
  ownership.span_end,
  greatest(
    0,
    extract(epoch from (
      coalesce(ownership.span_end, statement_timestamp()) - ownership.span_start
    ))
  )::bigint as gross_seconds,
  coalesce(hold_duration.hold_seconds, 0)::bigint as hold_seconds,
  greatest(
    0,
    extract(epoch from (
      coalesce(ownership.span_end, statement_timestamp()) - ownership.span_start
    )) - coalesce(hold_duration.hold_seconds, 0)
  )::bigint as net_seconds
from public.project_ownership_spans as ownership
join public.projects as project on project.id = ownership.project_id
left join lateral (
  select assignment.participant_group
  from public.project_participant_assignments as assignment
  where assignment.project_id = ownership.project_id
    and assignment.person_id = ownership.owner_id
    and assignment.effective_from <= ownership.span_start
    and (
      assignment.effective_to is null
      or assignment.effective_to > ownership.span_start
    )
  order by assignment.effective_from desc
  limit 1
) as participant on true
left join lateral (
  select sum(
    greatest(
      0,
      extract(epoch from (
        least(
          coalesce(ownership.span_end, statement_timestamp()),
          coalesce(hold.span_end, statement_timestamp())
        ) - greatest(ownership.span_start, hold.span_start)
      ))
    )
  ) as hold_seconds
  from public.project_hold_spans as hold
  where hold.project_id = ownership.project_id
    and hold.span_start < coalesce(ownership.span_end, 'infinity'::timestamptz)
    and ownership.span_start < coalesce(hold.span_end, 'infinity'::timestamptz)
) as hold_duration on true;

comment on view public.project_turnaround_report is
  'Ball ownership turnaround with gross, merged Hold, and net elapsed seconds.';

create view public.project_dashboard_queue
with (security_invoker = true)
as
select
  project.id as project_id,
  project.code as project_code,
  project.name as project_name,
  project.state,
  project.current_stage_id,
  stage.name as current_stage_name,
  project.priority_id,
  priority.name as priority_name,
  project.pmo_officer_id,
  pmo.name as pmo_officer_name,
  project.ball_owner_id,
  owner.name as ball_owner_name,
  participant.participant_group as ball_owner_group,
  activity.effective_at as last_effective_activity_at,
  greatest(
    0,
    extract(epoch from (statement_timestamp() - activity.effective_at))
  )::bigint as waiting_seconds,
  project.version
from public.projects as project
join public.priorities as priority on priority.id = project.priority_id
join public.people as pmo on pmo.id = project.pmo_officer_id
join public.people as owner on owner.id = project.ball_owner_id
left join public.project_stages as stage on stage.id = project.current_stage_id
left join public.project_participant_assignments as participant
  on participant.project_id = project.id
 and participant.person_id = project.ball_owner_id
 and participant.effective_from <= statement_timestamp()
 and (
   participant.effective_to is null
   or participant.effective_to > statement_timestamp()
 )
join lateral (
  select event.effective_at
  from public.effective_project_events as event
  where event.project_id = project.id
    and event.effective_event_type in (
      'project_created', 'progress', 'bump', 'state_changed', 'ball_transferred'
    )
  order by event.effective_at desc, event.recorded_at desc, event.id desc
  limit 1
) as activity on true
where project.archived_at is null
  and project.state not in ('Cancelled', 'Closed');

comment on view public.project_dashboard_queue is
  'Live non-terminal portfolio queue with oldest-effective-activity sort fields.';

create view public.project_ball_queue
with (security_invoker = true)
as
select
  dashboard.*,
  ownership.span_start as owner_since,
  greatest(
    0,
    extract(epoch from (statement_timestamp() - ownership.span_start))
  )::bigint as held_seconds
from public.project_dashboard_queue as dashboard
join public.project_ownership_spans as ownership
  on ownership.project_id = dashboard.project_id
 and ownership.owner_id = dashboard.ball_owner_id
 and ownership.span_end is null;

comment on view public.project_ball_queue is
  'Current Ball bays with the effective start and elapsed duration of each ownership period.';

create function public.report_projects_as_of(
  as_of_time timestamptz,
  target_project_id uuid default null
)
returns table (
  project_id uuid,
  project_code text,
  project_name text,
  state public.project_state,
  stage_id uuid,
  stage_name text,
  ball_owner_id uuid,
  ball_owner_name text,
  ball_owner_group public.participant_group,
  pmo_officer_id uuid,
  pmo_officer_name text,
  archived boolean,
  effective_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    project.id,
    project.code::text,
    project.name,
    event.resulting_state,
    event.resulting_stage_id,
    event.resulting_stage_label,
    event.resulting_ball_owner_id,
    event.resulting_ball_owner_name,
    participant.participant_group,
    pmo_assignment.person_id,
    pmo.name,
    coalesce(archive.archived, false),
    event.effective_at
  from public.projects as project
  join lateral (
    select effective.*
    from public.effective_project_events as effective
    where effective.project_id = project.id
      and effective.effective_at <= as_of_time
      and effective.effective_event_type in (
        'project_created', 'progress', 'bump', 'state_changed', 'ball_transferred'
      )
    order by effective.effective_at desc, effective.recorded_at desc, effective.id desc
    limit 1
  ) as event on true
  left join lateral (
    select (effective.payload ->> 'archived')::boolean as archived
    from public.effective_project_events as effective
    where effective.project_id = project.id
      and effective.effective_event_type = 'archived'
      and effective.effective_at <= as_of_time
    order by effective.effective_at desc, effective.recorded_at desc, effective.id desc
    limit 1
  ) as archive on true
  left join public.project_participant_assignments as participant
    on participant.project_id = project.id
   and participant.person_id = event.resulting_ball_owner_id
   and participant.effective_from <= event.effective_at
   and (
     participant.effective_to is null
     or participant.effective_to > event.effective_at
   )
  left join lateral (
    select assignment.person_id
    from public.project_pmo_assignments as assignment
    where assignment.project_id = project.id
      and assignment.effective_from <= as_of_time
      and (
        assignment.effective_to is null
        or assignment.effective_to > as_of_time
      )
    order by assignment.effective_from desc
    limit 1
  ) as pmo_assignment on true
  left join public.people as pmo on pmo.id = pmo_assignment.person_id
  where as_of_time is not null
    and (target_project_id is null or project.id = target_project_id)
    and project.created_at <= as_of_time;
$$;

comment on function public.report_projects_as_of(timestamptz, uuid) is
  'Reconstructs effective project state at a timestamp, including historical Ball and PMO ownership.';

create function public.report_project_history(target_project_id uuid)
returns table (
  event_id uuid,
  effective_event_type public.project_event_type,
  recorded_event_type public.project_event_type,
  effective_at timestamptz,
  recorded_at timestamptz,
  actor_id uuid,
  payload jsonb,
  resulting_state public.project_state,
  resulting_stage_id uuid,
  resulting_stage_label text,
  resulting_ball_owner_id uuid,
  resulting_ball_owner_name text,
  supersedes_event_id uuid,
  correction_reason text,
  is_effective boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    event.id,
    case
      when event.event_type = 'corrected'
        then (event.payload ->> 'correctedEventType')::public.project_event_type
      else event.event_type
    end,
    event.event_type,
    event.effective_at,
    event.recorded_at,
    event.actor_id,
    event.payload,
    event.resulting_state,
    event.resulting_stage_id,
    event.resulting_stage_label,
    event.resulting_ball_owner_id,
    event.resulting_ball_owner_name,
    event.supersedes_event_id,
    event.correction_reason,
    not exists (
      select 1 from public.project_events as correction
      where correction.supersedes_event_id = event.id
    )
  from public.project_events as event
  where event.project_id = target_project_id
  order by event.effective_at, event.recorded_at, event.id;
$$;

comment on function public.report_project_history(uuid) is
  'Full immutable Project history with effective/superseded status and correction metadata.';

create function public.report_project_audit(target_project_id uuid default null)
returns table (
  audit_id uuid,
  project_id uuid,
  action text,
  before_data jsonb,
  after_data jsonb,
  actor_id uuid,
  recorded_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    audit.id,
    audit.entity_id,
    audit.action,
    audit.before_data,
    audit.after_data,
    audit.actor_id,
    audit.recorded_at
  from public.audit_log as audit
  where audit.entity_type = 'project'
    and (target_project_id is null or audit.entity_id = target_project_id)
  order by audit.recorded_at desc, audit.id desc;
$$;

comment on function public.report_project_audit(uuid) is
  'Administrator-only Project audit stream; audit_log RLS remains the authorization boundary.';

revoke all on table
  public.effective_project_events,
  public.project_timeline_intervals,
  public.project_ownership_spans,
  public.project_hold_spans,
  public.project_turnaround_report,
  public.project_dashboard_queue,
  public.project_ball_queue
from public, anon;

grant select on table
  public.effective_project_events,
  public.project_timeline_intervals,
  public.project_ownership_spans,
  public.project_hold_spans,
  public.project_turnaround_report,
  public.project_dashboard_queue,
  public.project_ball_queue
to authenticated;

revoke execute on function public.report_projects_as_of(timestamptz, uuid)
from public, anon;
revoke execute on function public.report_project_history(uuid)
from public, anon;
revoke execute on function public.report_project_audit(uuid)
from public, anon;

grant execute on function public.report_projects_as_of(timestamptz, uuid)
to authenticated;
grant execute on function public.report_project_history(uuid)
to authenticated;
grant execute on function public.report_project_audit(uuid)
to authenticated;
