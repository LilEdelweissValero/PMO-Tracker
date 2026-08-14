begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(34);

select lives_ok(
  $$
  do $fixture$
  begin
    set constraints all deferred;

    insert into public.departments (id, name)
    values ('d0000000-0000-0000-0000-000000000301', 'Report Department');

    insert into public.people (id, name, department_id, username, position)
    values
      (
        '10000000-0000-0000-0000-000000000301', 'Report Admin',
        'd0000000-0000-0000-0000-000000000301', 'report.admin', 'Administrator'
      ),
      (
        '10000000-0000-0000-0000-000000000302', 'Report PMO',
        'd0000000-0000-0000-0000-000000000301', 'report.pmo', 'PMO Officer'
      ),
      (
        '10000000-0000-0000-0000-000000000303', 'Report Developer',
        'd0000000-0000-0000-0000-000000000301', 'report.developer', 'Developer'
      ),
      (
        '10000000-0000-0000-0000-000000000304', 'Report System Owner',
        'd0000000-0000-0000-0000-000000000301', 'report.owner', 'System Owner'
      ),
      (
        '10000000-0000-0000-0000-000000000305', 'Report Leadership',
        'd0000000-0000-0000-0000-000000000301', 'report.leadership', 'Leader'
      );

    insert into auth.users (id, email)
    values
      ('a0000000-0000-0000-0000-000000000301', 'admin@reports.test'),
      ('a0000000-0000-0000-0000-000000000305', 'leadership@reports.test');

    insert into public.profiles (id, person_id)
    values
      (
        'a0000000-0000-0000-0000-000000000301',
        '10000000-0000-0000-0000-000000000301'
      ),
      (
        'a0000000-0000-0000-0000-000000000305',
        '10000000-0000-0000-0000-000000000305'
      );

    insert into public.profile_roles (profile_id, role)
    values
      ('a0000000-0000-0000-0000-000000000301', 'administrator'),
      ('a0000000-0000-0000-0000-000000000305', 'leadership_viewer');

    insert into public.priorities (id, name, sort_order)
    values ('20000000-0000-0000-0000-000000000301', 'Report Priority', 301);

    insert into public.projects (
      id, code, name, priority_id, state, current_stage_id,
      pmo_officer_id, ball_owner_id, created_at, updated_at, version,
      archived_at
    ) values
      (
        '40000000-0000-0000-0000-000000000301', 'RPT-001',
        'Golden Timeline', '20000000-0000-0000-0000-000000000301',
        'Closed', '41000000-0000-0000-0000-000000000304',
        '10000000-0000-0000-0000-000000000302',
        '10000000-0000-0000-0000-000000000303',
        '2026-08-01 00:00:00+00', '2026-08-13 00:00:00+00', 12,
        '2026-08-13 00:00:00+00'
      ),
      (
        '40000000-0000-0000-0000-000000000302', 'RPT-002',
        'Live Queue', '20000000-0000-0000-0000-000000000301',
        'Active', '42000000-0000-0000-0000-000000000301',
        '10000000-0000-0000-0000-000000000302',
        '10000000-0000-0000-0000-000000000303',
        '2026-08-02 00:00:00+00', '2026-08-10 00:00:00+00', 2,
        null
      );

    insert into public.project_stages (id, project_id, name, sort_order, visited)
    values
      (
        '41000000-0000-0000-0000-000000000301',
        '40000000-0000-0000-0000-000000000301', 'Intake', 1, true
      ),
      (
        '41000000-0000-0000-0000-000000000302',
        '40000000-0000-0000-0000-000000000301', 'Analysis', 2, true
      ),
      (
        '41000000-0000-0000-0000-000000000303',
        '40000000-0000-0000-0000-000000000301', 'Build', 3, false
      ),
      (
        '41000000-0000-0000-0000-000000000304',
        '40000000-0000-0000-0000-000000000301', 'Release', 4, true
      ),
      (
        '42000000-0000-0000-0000-000000000301',
        '40000000-0000-0000-0000-000000000302', 'Delivery', 1, true
      );

    insert into public.project_pmo_assignments (
      project_id, person_id, effective_from
    ) values
      (
        '40000000-0000-0000-0000-000000000301',
        '10000000-0000-0000-0000-000000000302', '2026-08-01 00:00:00+00'
      ),
      (
        '40000000-0000-0000-0000-000000000302',
        '10000000-0000-0000-0000-000000000302', '2026-08-02 00:00:00+00'
      );

    insert into public.project_participant_assignments (
      project_id, person_id, participant_group, effective_from
    ) values
      (
        '40000000-0000-0000-0000-000000000301',
        '10000000-0000-0000-0000-000000000302', 'PMO',
        '2026-08-01 00:00:00+00'
      ),
      (
        '40000000-0000-0000-0000-000000000301',
        '10000000-0000-0000-0000-000000000303', 'Developer',
        '2026-08-01 00:00:00+00'
      ),
      (
        '40000000-0000-0000-0000-000000000301',
        '10000000-0000-0000-0000-000000000304', 'System Owner',
        '2026-08-01 00:00:00+00'
      ),
      (
        '40000000-0000-0000-0000-000000000302',
        '10000000-0000-0000-0000-000000000302', 'PMO',
        '2026-08-02 00:00:00+00'
      ),
      (
        '40000000-0000-0000-0000-000000000302',
        '10000000-0000-0000-0000-000000000303', 'Developer',
        '2026-08-02 00:00:00+00'
      );

    insert into public.closeout_assessments (
      project_id, dod_met, dod_explanation, methodology_compliant,
      methodology_explanation, documentation_complete,
      documentation_explanation, stakeholder_rating, actor_id,
      recorded_at
    ) values (
      '40000000-0000-0000-0000-000000000301', true, 'Accepted', true,
      'Compliant', true, 'Published', 5,
      'a0000000-0000-0000-0000-000000000301', '2026-08-12 00:00:00+00'
    );

    insert into public.project_events (
      id, project_id, event_type, effective_at, recorded_at, actor_id,
      payload, resulting_state, resulting_stage_id, resulting_stage_label,
      resulting_ball_owner_id, resulting_ball_owner_name
    ) values
      (
        '50000000-0000-0000-0000-000000000301',
        '40000000-0000-0000-0000-000000000301', 'project_created',
        '2026-08-01 00:00:00+00', '2026-08-01 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301',
        '{"code":"RPT-001","name":"Golden Timeline"}', 'Active',
        '41000000-0000-0000-0000-000000000301', 'Intake',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000302',
        '40000000-0000-0000-0000-000000000301', 'progress',
        '2026-08-02 00:00:00+00', '2026-08-02 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301',
        '{"summary":"Analysis started"}', 'Active',
        '41000000-0000-0000-0000-000000000302', 'Analysis',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000303',
        '40000000-0000-0000-0000-000000000301', 'state_changed',
        '2026-08-03 00:00:00+00', '2026-08-03 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301',
        '{"reason":"Waiting for vendor"}', 'On Hold',
        '41000000-0000-0000-0000-000000000302', 'Analysis',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000304',
        '40000000-0000-0000-0000-000000000301', 'bump',
        '2026-08-04 00:00:00+00', '2026-08-04 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301',
        '{"text":"First tied follow-up"}', 'On Hold',
        '41000000-0000-0000-0000-000000000302', 'Analysis',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000305',
        '40000000-0000-0000-0000-000000000301', 'bump',
        '2026-08-04 00:00:00+00', '2026-08-04 00:00:02+00',
        'a0000000-0000-0000-0000-000000000301',
        '{"text":"Second tied follow-up"}', 'On Hold',
        '41000000-0000-0000-0000-000000000302', 'Analysis',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000306',
        '40000000-0000-0000-0000-000000000301', 'ball_transferred',
        '2026-08-05 00:00:00+00', '2026-08-05 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301', '{}',
        'On Hold', '41000000-0000-0000-0000-000000000302', 'Analysis',
        '10000000-0000-0000-0000-000000000304', 'Report System Owner'
      ),
      (
        '50000000-0000-0000-0000-000000000307',
        '40000000-0000-0000-0000-000000000301', 'state_changed',
        '2026-08-06 00:00:00+00', '2026-08-06 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301', '{}',
        'Active', '41000000-0000-0000-0000-000000000302', 'Analysis',
        '10000000-0000-0000-0000-000000000304', 'Report System Owner'
      ),
      (
        '50000000-0000-0000-0000-000000000308',
        '40000000-0000-0000-0000-000000000301', 'progress',
        '2026-08-07 00:00:00+00', '2026-08-07 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301',
        '{"summary":"Superseded build"}', 'Active',
        '41000000-0000-0000-0000-000000000303', 'Build',
        '10000000-0000-0000-0000-000000000304', 'Report System Owner'
      ),
      (
        '50000000-0000-0000-0000-000000000309',
        '40000000-0000-0000-0000-000000000301', 'ball_transferred',
        '2026-08-09 00:00:00+00', '2026-08-09 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301', '{}',
        'Active', '41000000-0000-0000-0000-000000000304', 'Release',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000310',
        '40000000-0000-0000-0000-000000000301', 'state_changed',
        '2026-08-12 00:00:00+00', '2026-08-12 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301', '{}',
        'Closed', '41000000-0000-0000-0000-000000000304', 'Release',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000311',
        '40000000-0000-0000-0000-000000000301', 'archived',
        '2026-08-13 00:00:00+00', '2026-08-13 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301', '{"archived":true}',
        'Closed', '41000000-0000-0000-0000-000000000304', 'Release',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000312',
        '40000000-0000-0000-0000-000000000302', 'project_created',
        '2026-08-02 00:00:00+00', '2026-08-02 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301',
        '{"code":"RPT-002","name":"Live Queue"}', 'Active',
        '42000000-0000-0000-0000-000000000301', 'Delivery',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      ),
      (
        '50000000-0000-0000-0000-000000000313',
        '40000000-0000-0000-0000-000000000302', 'bump',
        '2026-08-10 00:00:00+00', '2026-08-10 00:00:01+00',
        'a0000000-0000-0000-0000-000000000301', '{"text":"Queue follow-up"}',
        'Active', '42000000-0000-0000-0000-000000000301', 'Delivery',
        '10000000-0000-0000-0000-000000000303', 'Report Developer'
      );

    insert into public.project_events (
      id, project_id, event_type, effective_at, recorded_at, actor_id,
      payload, resulting_state, resulting_stage_id, resulting_stage_label,
      resulting_ball_owner_id, resulting_ball_owner_name,
      supersedes_event_id, correction_reason
    ) values (
      '50000000-0000-0000-0000-000000000314',
      '40000000-0000-0000-0000-000000000301', 'corrected',
      '2026-08-08 00:00:00+00', '2026-08-11 00:00:01+00',
      'a0000000-0000-0000-0000-000000000301',
      '{"summary":"Corrected release","correctedEventType":"progress"}',
      'Active', '41000000-0000-0000-0000-000000000304', 'Release',
      '10000000-0000-0000-0000-000000000304', 'Report System Owner',
      '50000000-0000-0000-0000-000000000308', 'Correct effective date and Stage'
    );

    insert into public.audit_log (
      entity_type, entity_id, action, actor_id, recorded_at
    ) values (
      'project', '40000000-0000-0000-0000-000000000301',
      'event_corrected', 'a0000000-0000-0000-0000-000000000301',
      '2026-08-11 00:00:02+00'
    );

    set constraints all immediate;
    set constraints all deferred;
  end
  $fixture$;
  $$,
  'Golden report timeline satisfies database invariants'
);

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000301","role":"authenticated"}';

select is(
  (select count(*) from public.effective_project_events
   where id = '50000000-0000-0000-0000-000000000308'),
  0::bigint,
  'Effective events exclude a superseded original'
);
select is(
  (select effective_event_type from public.effective_project_events
   where id = '50000000-0000-0000-0000-000000000314'),
  'progress'::public.project_event_type,
  'A correction retains the corrected fact type'
);
select is(
  (select count(*) from public.effective_project_events
   where project_id = '40000000-0000-0000-0000-000000000301'),
  11::bigint,
  'Effective history replaces one original with one correction'
);
select is(
  (
    select array_agg(id order by effective_at, recorded_at, id)
    from public.effective_project_events
    where project_id = '40000000-0000-0000-0000-000000000301'
      and effective_at = '2026-08-04 00:00:00+00'
  ),
  array[
    '50000000-0000-0000-0000-000000000304'::uuid,
    '50000000-0000-0000-0000-000000000305'::uuid
  ],
  'Equal effective timestamps use recorded time and id as stable tie-breakers'
);

select is(
  (select count(*) from public.report_projects_as_of('2026-08-05 12:00:00+00')),
  2::bigint,
  'As-of reporting returns every Project created by the chosen time'
);
select is(
  (select state from public.report_projects_as_of(
    '2026-08-05 12:00:00+00', '40000000-0000-0000-0000-000000000301'
  )),
  'On Hold'::public.project_state,
  'As-of reporting reconstructs State'
);
select is(
  (select ball_owner_id from public.report_projects_as_of(
    '2026-08-05 12:00:00+00', '40000000-0000-0000-0000-000000000301'
  )),
  '10000000-0000-0000-0000-000000000304'::uuid,
  'As-of reporting reconstructs a transferred Ball Owner'
);
select is(
  (select ball_owner_group from public.report_projects_as_of(
    '2026-08-05 12:00:00+00', '40000000-0000-0000-0000-000000000301'
  )),
  'System Owner'::public.participant_group,
  'As-of reporting reconstructs the Ball Owner group'
);
select is(
  (select stage_name from public.report_projects_as_of(
    '2026-08-05 12:00:00+00', '40000000-0000-0000-0000-000000000301'
  )),
  'Analysis'::text,
  'As-of reporting reconstructs the Stage snapshot'
);
select is(
  (select pmo_officer_id from public.report_projects_as_of(
    '2026-08-05 12:00:00+00', '40000000-0000-0000-0000-000000000301'
  )),
  '10000000-0000-0000-0000-000000000302'::uuid,
  'As-of reporting resolves the effective PMO assignment'
);
select is(
  (select archived from public.report_projects_as_of(
    '2026-08-12 12:00:00+00', '40000000-0000-0000-0000-000000000301'
  )),
  false,
  'As-of reporting does not leak a future archive event'
);
select is(
  (select archived from public.report_projects_as_of(
    '2026-08-14 00:00:00+00', '40000000-0000-0000-0000-000000000301'
  )),
  true,
  'As-of reporting reconstructs archival State'
);

select is(
  (select count(*) from public.project_ownership_spans
   where project_id = '40000000-0000-0000-0000-000000000301'),
  3::bigint,
  'Ball transfers produce three contiguous ownership spans'
);
select is(
  (select gross_seconds from public.project_turnaround_report
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000303'
   order by span_start limit 1),
  345600::bigint,
  'First ownership span has four gross days'
);
select is(
  (select hold_seconds from public.project_turnaround_report
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000303'
   order by span_start limit 1),
  172800::bigint,
  'First ownership span subtracts two Hold days exactly once'
);
select is(
  (select net_seconds from public.project_turnaround_report
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000303'
   order by span_start limit 1),
  172800::bigint,
  'First ownership span has two net days'
);
select is(
  (select gross_seconds from public.project_turnaround_report
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000304'),
  345600::bigint,
  'System Owner span has four gross days'
);
select is(
  (select hold_seconds from public.project_turnaround_report
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000304'),
  86400::bigint,
  'System Owner span overlaps one Hold day'
);
select is(
  (select net_seconds from public.project_turnaround_report
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000304'),
  259200::bigint,
  'System Owner span has three net days'
);
select is(
  (select span_end from public.project_ownership_spans
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000303'
   order by span_start desc limit 1),
  '2026-08-12 00:00:00+00'::timestamptz,
  'Terminal State ends the final ownership span'
);
select is(
  (select gross_seconds from public.project_turnaround_report
   where project_id = '40000000-0000-0000-0000-000000000301'
     and owner_id = '10000000-0000-0000-0000-000000000303'
   order by span_start desc limit 1),
  259200::bigint,
  'Final ownership span has three gross days'
);
select is(
  (select count(*) from public.project_hold_spans
   where project_id = '40000000-0000-0000-0000-000000000301'),
  1::bigint,
  'Repeated events while On Hold remain one disjoint Hold span'
);
select is(
  (select span_start from public.project_hold_spans
   where project_id = '40000000-0000-0000-0000-000000000301'),
  '2026-08-03 00:00:00+00'::timestamptz,
  'Hold span starts at the effective Hold event'
);
select is(
  (select span_end from public.project_hold_spans
   where project_id = '40000000-0000-0000-0000-000000000301'),
  '2026-08-06 00:00:00+00'::timestamptz,
  'Hold span ends when effective State resumes'
);

select is(
  (select count(*) from public.project_dashboard_queue),
  1::bigint,
  'Dashboard queue excludes archived and terminal Projects'
);
select is(
  (select last_effective_activity_at from public.project_dashboard_queue),
  '2026-08-10 00:00:00+00'::timestamptz,
  'Dashboard waiting time starts at the latest effective activity'
);
select is(
  (select owner_since from public.project_ball_queue),
  '2026-08-02 00:00:00+00'::timestamptz,
  'Ball queue preserves ownership across same-owner Bumps'
);
select is(
  (select ball_owner_group from public.project_ball_queue),
  'Developer'::public.participant_group,
  'Ball queue resolves the current participant group'
);

select is(
  (
    select count(*)
    from public.projects as project
    join lateral (
      select event.*
      from public.effective_project_events as event
      where event.project_id = project.id
        and event.effective_event_type in (
          'project_created', 'progress', 'bump', 'state_changed', 'ball_transferred'
        )
      order by event.effective_at desc, event.recorded_at desc, event.id desc
      limit 1
    ) as replay on true
    where project.state is not distinct from replay.resulting_state
      and project.current_stage_id is not distinct from replay.resulting_stage_id
      and project.ball_owner_id is not distinct from replay.resulting_ball_owner_id
      and project.id in (
        '40000000-0000-0000-0000-000000000301',
        '40000000-0000-0000-0000-000000000302'
      )
  ),
  2::bigint,
  'Current projection equals canonical replay for every fixture'
);
select is(
  (select count(*) from public.report_project_history(
    '40000000-0000-0000-0000-000000000301'
  ) where not is_effective),
  1::bigint,
  'Project history marks the superseded original as ineffective'
);
select is(
  (select count(*) from public.report_project_audit(
    '40000000-0000-0000-0000-000000000301'
  )),
  1::bigint,
  'Administrator can read Project audit evidence'
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"a0000000-0000-0000-0000-000000000305","role":"authenticated"}';

select is(
  (select count(*) from public.report_project_audit(null)),
  0::bigint,
  'Leadership cannot read Administrator audit evidence'
);
select is(
  (select count(*) from public.project_dashboard_queue),
  1::bigint,
  'Leadership can read operational report views'
);

reset role;
select * from finish();
rollback;
