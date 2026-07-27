insert into public.organizations (id, code, name)
values ('10000000-0000-0000-0000-000000000001', 'TNGOV', 'Tamil Nadu Government')
on conflict (id) do update set name = excluded.name;

insert into public.regions (id, organization_id, code, name, level, parent_id)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'TN',
    'Tamil Nadu',
    'state',
    null
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'TN-CHENNAI',
    'Chennai',
    'district',
    '20000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000001',
    'TN-MADURAI',
    'Madurai',
    'district',
    '20000000-0000-0000-0000-000000000001'
  )
on conflict (id) do update
set name = excluded.name,
    parent_id = excluded.parent_id,
    active = true;

insert into public.departments (id, organization_id, code, name)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'SOCIAL_WELFARE',
    'Social Welfare and Women Empowerment Department'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'AGRICULTURE',
    'Agriculture and Farmers Welfare Department'
  )
on conflict (id) do update set name = excluded.name, active = true;

insert into public.beneficiary_categories (id, organization_id, code, name)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'WOMEN',
    'Women'
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'FARMERS',
    'Farmers'
  ),
  (
    '40000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000001',
    'STUDENTS',
    'Students'
  )
on conflict (id) do update set name = excluded.name, active = true;
