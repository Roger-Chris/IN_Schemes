begin;

select plan(12);

select has_table('public', 'organizations', 'organizations table exists');
select has_table('public', 'organization_memberships', 'organization memberships table exists');
select has_table('public', 'roles', 'roles table exists');
select has_table('public', 'user_roles', 'user_roles table exists');
select has_table('public', 'regions', 'regions table exists');
select has_table('public', 'user_regions', 'user_regions table exists');
select has_table('public', 'departments', 'departments table exists');
select has_table('public', 'audit_log', 'audit_log table exists');

select has_function(
  'private',
  'has_role',
  array['uuid', 'text[]'],
  'role checks are isolated in a private helper'
);

select is(
  (select count(*)::integer from public.roles),
  5,
  'the five staff roles are seeded'
);

select ok(
  (
    select bool_and(class.relrowsecurity)
    from pg_class as class
    join pg_namespace as namespace on namespace.oid = class.relnamespace
    where namespace.nspname = 'public'
      and class.relname in (
        'organizations', 'organization_memberships', 'roles', 'user_roles', 'regions',
        'user_regions', 'departments', 'beneficiary_categories', 'audit_log'
      )
  ),
  'all application tables have RLS enabled'
);

insert into public.organizations (id, code, name)
values ('90000000-0000-0000-0000-000000000001', 'TEST_ORG', 'Test Organization');

insert into public.audit_log (
  organization_id,
  action,
  target_type,
  target_id,
  request_id
)
values (
  '90000000-0000-0000-0000-000000000001',
  'test.created',
  'test',
  'test-1',
  '90000000-0000-0000-0000-000000000002'
);

select throws_ok(
  $$update public.audit_log set action = 'test.changed' where target_id = 'test-1'$$,
  'P0001',
  'audit_log is append-only',
  'audit rows cannot be updated'
);

select * from finish();
rollback;
