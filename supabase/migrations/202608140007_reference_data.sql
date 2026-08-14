insert into public.priorities (name, sort_order, active)
values
  ('Critical', 1, true),
  ('High', 2, true),
  ('Medium', 3, true),
  ('Low', 4, true)
on conflict (name) do update
set sort_order = excluded.sort_order, active = excluded.active;

insert into public.request_types (name, active)
values
  ('Enhancement', true),
  ('New System', true),
  ('New Module', true)
on conflict (name) do update
set active = excluded.active;

insert into public.reference_types (name, active)
values
  ('GDocs', true),
  ('OneDrive', true),
  ('ELS', true),
  ('Jira', true)
on conflict (name) do update
set active = excluded.active;

insert into public.initiator_types (name, active)
values
  ('System Owner', true),
  ('PMO', true),
  ('Developer', true),
  ('Higher Authority', true)
on conflict (name) do update
set active = excluded.active;

insert into public.workflow_template_stages (
  name,
  sort_order,
  detail_label,
  detail_required,
  detail_multiline,
  active
)
values
  ('Engagement Meeting', 1, null, false, false, true),
  ('TICRO #1 Requested', 2, 'Documents Submitted', true, true, true),
  ('TICRO #1 Approved', 3, null, false, false, true),
  ('TICRO #2 Requested', 4, 'Documents Submitted', true, true, true),
  ('TICRO #2 Approved', 5, null, false, false, true),
  ('Signed All Required Documents', 6, null, false, false, true),
  ('WBS Onboarded in Jira', 7, null, false, false, true),
  ('Dev Start', 8, null, false, false, true),
  ('Dev End', 9, null, false, false, true),
  ('UAT Start', 10, null, false, false, true),
  ('UAT End', 11, null, false, false, true),
  ('UAT Signed Off', 12, null, false, false, true),
  ('Deployed', 13, 'Deployment Version', true, false, true),
  ('All Required Documents Submitted', 14, null, false, false, true)
on conflict (sort_order) do update
set
  name = excluded.name,
  detail_label = excluded.detail_label,
  detail_required = excluded.detail_required,
  detail_multiline = excluded.detail_multiline,
  active = excluded.active;
