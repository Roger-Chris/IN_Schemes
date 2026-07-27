begin;

select plan(10);

insert into public.organizations (id, code, name)
values
  ('91000000-0000-0000-0000-000000000001', 'ORG_A', 'Organization A'),
  ('91000000-0000-0000-0000-000000000002', 'ORG_B', 'Organization B');

insert into auth.users (id, aud, role, email)
values
  ('92000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'admin-a@example.test'),
  ('92000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'editor-a@example.test'),
  ('92000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'auditor-a@example.test'),
  ('92000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'member-b@example.test');

insert into public.users (id, full_name)
values
  ('92000000-0000-0000-0000-000000000001', 'Admin A'),
  ('92000000-0000-0000-0000-000000000002', 'Editor A'),
  ('92000000-0000-0000-0000-000000000003', 'Auditor A'),
  ('92000000-0000-0000-0000-000000000004', 'Member B');

insert into public.organization_memberships (user_id, organization_id, display_name)
values
  ('92000000-0000-0000-0000-000000000001', '91000000-0000-0000-0000-000000000001', 'Admin A'),
  ('92000000-0000-0000-0000-000000000002', '91000000-0000-0000-0000-000000000001', 'Editor A'),
  ('92000000-0000-0000-0000-000000000003', '91000000-0000-0000-0000-000000000001', 'Auditor A'),
  ('92000000-0000-0000-0000-000000000004', '91000000-0000-0000-0000-000000000002', 'Member B');

insert into public.user_roles (user_id, organization_id, role_id)
select '92000000-0000-0000-0000-000000000001',
       '91000000-0000-0000-0000-000000000001',
       id
from public.roles where code = 'administrator';

insert into public.user_roles (user_id, organization_id, role_id)
select '92000000-0000-0000-0000-000000000002',
       '91000000-0000-0000-0000-000000000001',
       id
from public.roles where code = 'content_editor';

insert into public.user_roles (user_id, organization_id, role_id)
select '92000000-0000-0000-0000-000000000003',
       '91000000-0000-0000-0000-000000000001',
       id
from public.roles where code = 'auditor';

insert into public.regions (id, organization_id, code, name, level, parent_id)
values
  (
    '93000000-0000-0000-0000-000000000001',
    '91000000-0000-0000-0000-000000000001',
    'A-STATE',
    'State A',
    'state',
    null
  ),
  (
    '93000000-0000-0000-0000-000000000002',
    '91000000-0000-0000-0000-000000000001',
    'A-DISTRICT',
    'District A',
    'district',
    '93000000-0000-0000-0000-000000000001'
  ),
  (
    '93000000-0000-0000-0000-000000000003',
    '91000000-0000-0000-0000-000000000002',
    'B-STATE',
    'State B',
    'state',
    null
  );

insert into public.user_regions (user_id, organization_id, region_id)
values (
  '92000000-0000-0000-0000-000000000002',
  '91000000-0000-0000-0000-000000000001',
  '93000000-0000-0000-0000-000000000001'
);

insert into public.audit_log (
  organization_id,
  action,
  target_type,
  target_id,
  request_id
)
values
  (
    '91000000-0000-0000-0000-000000000001',
    'test.created',
    'test',
    'audit-a',
    '94000000-0000-0000-0000-000000000001'
  ),
  (
    '91000000-0000-0000-0000-000000000002',
    'test.created',
    'test',
    'audit-b',
    '94000000-0000-0000-0000-000000000002'
  );

set local role anon;
select throws_ok(
  $$select * from public.organizations$$,
  '42501',
  'permission denied for table organizations',
  'anonymous callers cannot read organization records'
);

select lives_ok(
  $$select id from public.schemes limit 1$$,
  'the administration migration preserves anonymous scheme discovery'
);
reset role;

select set_config(
  'request.jwt.claim.sub',
  '92000000-0000-0000-0000-000000000001',
  true
);
set local role authenticated;

select results_eq(
  $$select code from public.organizations order by code$$,
  $$values ('ORG_A'::text)$$,
  'administrators see only their own organization'
);

select lives_ok(
  $$
    insert into public.departments (organization_id, code, name)
    values (
      '91000000-0000-0000-0000-000000000001',
      'ADMIN_CREATED',
      'Administrator Created Department'
    )
  $$,
  'administrators can create taxonomies in their organization'
);
reset role;

select set_config(
  'request.jwt.claim.sub',
  '92000000-0000-0000-0000-000000000002',
  true
);
set local role authenticated;

select is(
  private.has_region('93000000-0000-0000-0000-000000000002'),
  true,
  'a parent region assignment grants access to descendants'
);

select is(
  private.has_region('93000000-0000-0000-0000-000000000003'),
  false,
  'region assignments never cross organizations'
);

select is_empty(
  $$select id from public.audit_log$$,
  'content editors cannot read audit records'
);

select throws_ok(
  $$
    insert into public.departments (organization_id, code, name)
    values (
      '91000000-0000-0000-0000-000000000001',
      'EDITOR_CREATED',
      'Editor Created Department'
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "departments"',
  'content editors cannot create taxonomies'
);
reset role;

select set_config(
  'request.jwt.claim.sub',
  '92000000-0000-0000-0000-000000000003',
  true
);
set local role authenticated;

select results_eq(
  $$select target_id from public.audit_log order by target_id$$,
  $$values ('audit-a'::text)$$,
  'auditors see only audit records from their organization'
);
reset role;

select set_config(
  'request.jwt.claim.sub',
  '92000000-0000-0000-0000-000000000004',
  true
);
set local role authenticated;

select results_eq(
  $$select code from public.organizations order by code$$,
  $$values ('ORG_B'::text)$$,
  'ordinary members cannot read another organization'
);
reset role;

select * from finish();
rollback;
