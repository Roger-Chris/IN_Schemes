begin;

select plan(13);

select has_table('public', 'catalog_releases', 'catalog release table exists');
select has_table(
  'public',
  'scheme_eligibility_content',
  'eligibility display content table exists'
);

create temporary table catalog_test_releases (id uuid primary key, ordinal integer);

insert into public.scheme_eligibility_content (
  scheme_id,
  eligibility_criteria,
  verified_eligibility,
  verification_status
)
select
  id,
  'Test eligibility criteria',
  'Verified test eligibility',
  'Verified'
from public.schemes
where is_active;

insert into catalog_test_releases
select (private.publish_scheme_catalog('first test release', true) ->> 'id')::uuid, 1;

select is(
  (select count(*)::integer from public.catalog_releases where is_current),
  1,
  'publishing creates exactly one current release'
);

select is(
  (select length(sha256) from public.catalog_releases where is_current),
  64,
  'published payload has a SHA-256 checksum'
);

select is(
  (select scheme_count from public.catalog_releases where is_current),
  (select count(*)::integer from public.schemes where is_active),
  'release manifest count matches active schemes'
);

update public.schemes
set overview = coalesce(overview, '') || ' catalog release test'
where id = (select id from public.schemes where is_active limit 1);

insert into catalog_test_releases
select (private.publish_scheme_catalog('second test release', false) ->> 'id')::uuid, 2;

select is(
  (select count(*)::integer from public.catalog_releases where is_current),
  1,
  'a second publication still leaves one current release'
);

select isnt(
  (select id from public.catalog_releases where is_current),
  (select id from catalog_test_releases where ordinal = 1),
  'the new release becomes current'
);

select throws_ok(
  $$update public.catalog_releases set payload = '{}' where is_current$$,
  'P0001',
  'published catalog release content is immutable',
  'published payload cannot be changed'
);

select lives_ok(
  $$select private.promote_catalog_release((select id from catalog_test_releases where ordinal = 1))$$,
  'a previous release can be promoted for rollback'
);

select is(
  (select id from public.catalog_releases where is_current),
  (select id from catalog_test_releases where ordinal = 1),
  'rollback changes only the current release pointer'
);

set local role anon;
select is(
  (select count(*)::integer from public.catalog_releases),
  1,
  'anonymous callers see only the current published release'
);
select throws_ok(
  $$insert into public.catalog_releases (payload, sha256, byte_size, scheme_count, document_count, service_count) values ('{}', repeat('a', 64), 2, 1, 0, 0)$$,
  '42501',
  'permission denied for table catalog_releases',
  'anonymous callers cannot publish releases'
);
select is(
  has_function_privilege('anon', 'public.admin_import_scheme_catalog(jsonb)', 'EXECUTE'),
  false,
  'anonymous callers cannot execute the catalog importer'
);
reset role;

select * from finish();
rollback;
