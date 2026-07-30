begin;

create schema if not exists extensions;
do $$
begin
  if exists (
    select 1
    from pg_extension extension
    join pg_namespace namespace on namespace.oid = extension.extnamespace
    where extension.extname = 'pgcrypto' and namespace.nspname <> 'extensions'
  ) then
    alter extension pgcrypto set schema extensions;
  end if;
end;
$$;

-- The profile-unification migration removes public.users after the admin
-- foundation is created. Restore the staff identity FK against its successor.
alter table public.organization_memberships
  drop constraint if exists organization_memberships_user_id_fkey;
alter table public.organization_memberships
  add constraint organization_memberships_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete restrict;

-- Preserve the display/source fields carried by the curated mobile catalogue.
alter table public.schemes
  add column if not exists ministry text,
  add column if not exists district_applicable text,
  add column if not exists source_url text,
  add column if not exists source_version text,
  add column if not exists source_last_updated text,
  add column if not exists verified_text text,
  add column if not exists verification_status text,
  add column if not exists verification_notes text,
  add column if not exists subsidy_percentage_display text,
  add column if not exists subsidy_amount_display text,
  add column if not exists minimum_funding_display text,
  add column if not exists maximum_funding_display text;

create table if not exists public.scheme_eligibility_content (
  scheme_id uuid primary key references public.schemes(id) on delete cascade,
  source_name text,
  eligibility_criteria text,
  verified_eligibility text,
  research_status text,
  official_source text,
  verification_status text,
  verification_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.scheme_documents
  add column if not exists description text,
  add column if not exists issuing_authority text,
  add column if not exists estimated_cost text,
  add column if not exists source_url text;

alter table public.scheme_services
  add column if not exists source_service_name text,
  add column if not exists source_category text,
  add column if not exists source_description text,
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.catalog_releases (
  id uuid primary key default gen_random_uuid(),
  version bigint generated always as identity unique,
  schema_version integer not null default 1 check (schema_version > 0),
  payload text not null,
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  byte_size integer not null check (byte_size > 0),
  scheme_count integer not null check (scheme_count > 0),
  document_count integer not null check (document_count >= 0),
  service_count integer not null check (service_count >= 0),
  status text not null default 'published' check (status in ('published')),
  is_current boolean not null default false,
  notes text,
  published_by uuid references auth.users(id) on delete set null,
  published_at timestamptz not null default now()
);

create unique index if not exists catalog_releases_one_current_idx
  on public.catalog_releases ((is_current)) where is_current;
create index if not exists catalog_releases_published_at_idx
  on public.catalog_releases (published_at desc);

create or replace function private.catalog_text(value jsonb, key_name text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(btrim(coalesce(value ->> key_name, '')), '');
$$;

create or replace function private.catalog_parse_numeric(display_value text)
returns numeric
language plpgsql
immutable
set search_path = ''
as $$
declare
  normalized text := lower(replace(coalesce(display_value, ''), ',', ''));
  parsed numeric;
begin
  parsed := substring(normalized from '([0-9]+(?:\.[0-9]+)?)')::numeric;
  if parsed is null then
    return null;
  elsif normalized like '%crore%' then
    return parsed * 10000000;
  elsif normalized like '%lakh%' then
    return parsed * 100000;
  elsif normalized like '%thousand%' then
    return parsed * 1000;
  end if;
  return parsed;
exception when others then
  return null;
end;
$$;

create or replace function private.catalog_url(value jsonb, key_name text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when private.catalog_text(value, key_name) ~* '^https?://' then
      private.catalog_text(value, key_name)
    else null
  end;
$$;

create or replace function private.catalog_release_immutable()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'catalog releases are immutable';
  end if;
  if (to_jsonb(new) - 'is_current') is distinct from
     (to_jsonb(old) - 'is_current') then
    raise exception 'published catalog release content is immutable';
  end if;
  return new;
end;
$$;

drop trigger if exists catalog_releases_immutable on public.catalog_releases;
create trigger catalog_releases_immutable
before update or delete on public.catalog_releases
for each row execute function private.catalog_release_immutable();

create or replace function public.admin_import_scheme_catalog(catalog jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  info_row jsonb;
  eligibility_row jsonb;
  document_row jsonb;
  service_row jsonb;
  target_scheme_id uuid;
  target_document_id uuid;
  target_service_id uuid;
  code text;
  parsed_service_name text;
  incoming_codes text[];
  scheme_total integer;
  document_total integer;
  service_total integer;
begin
  if jsonb_typeof(catalog) <> 'object'
     or jsonb_typeof(catalog -> 'Scheme Info') <> 'array'
     or jsonb_typeof(catalog -> 'All Schemes') <> 'array'
     or jsonb_typeof(catalog -> 'Documents Required') <> 'array'
     or jsonb_typeof(catalog -> 'Services Required') <> 'array' then
    raise exception 'catalog must contain the four required arrays';
  end if;

  select count(*), array_agg(item ->> 'Scheme Code' order by item ->> 'Scheme Code')
    into scheme_total, incoming_codes
  from jsonb_array_elements(catalog -> 'Scheme Info') as item;

  if scheme_total = 0 or exists (
    select 1
    from jsonb_array_elements(catalog -> 'Scheme Info') as item
    where coalesce(item ->> 'Scheme Code', '') !~ '^IN[0-9]{3}$'
       or btrim(coalesce(item ->> 'Scheme Name', '')) = ''
  ) then
    raise exception 'scheme codes and names are required; codes must match IN000';
  end if;

  if (select count(distinct item ->> 'Scheme Code')
      from jsonb_array_elements(catalog -> 'Scheme Info') as item) <> scheme_total then
    raise exception 'duplicate scheme codes are not allowed';
  end if;

  -- Keep legacy rows and foreign-key history, but remove them from publication.
  update public.schemes
  set is_active = false, updated_at = now()
  where is_active and not (scheme_code = any(incoming_codes));

  for info_row in select value from jsonb_array_elements(catalog -> 'Scheme Info') loop
    code := info_row ->> 'Scheme Code';
    insert into public.schemes (
      scheme_code, scheme_name, government_level, ministry,
      issuing_department, issuing_body, state, district_applicable,
      target_sector, target_beneficiary, scheme_type, scheme_category,
      overview, objectives, benefits_description,
      subsidy_percentage, subsidy_amount, minimum_funding_amount,
      max_funding_amount, subsidy_percentage_display,
      subsidy_amount_display, minimum_funding_display,
      maximum_funding_display, application_mode, official_website,
      application_url, guidelines_url, source_url, source_version,
      source_last_updated, verified_text, search_keywords, status,
      is_active, updated_at
    ) values (
      code,
      info_row ->> 'Scheme Name',
      coalesce(private.catalog_text(info_row, 'Government Level'), 'Central'),
      private.catalog_text(info_row, 'Ministry'),
      private.catalog_text(info_row, 'Department'),
      private.catalog_text(info_row, 'Implementing Agency'),
      coalesce(private.catalog_text(info_row, 'State'), 'All India'),
      private.catalog_text(info_row, 'District Applicable'),
      private.catalog_text(info_row, 'Target Sector'),
      private.catalog_text(info_row, 'Target Beneficiary'),
      private.catalog_text(info_row, 'Scheme Type'),
      coalesce(private.catalog_text(info_row, 'Target Sector'), private.catalog_text(info_row, 'Scheme Type')),
      private.catalog_text(info_row, 'Overview'),
      private.catalog_text(info_row, 'Objectives'),
      private.catalog_text(info_row, 'Benefits Description'),
      private.catalog_parse_numeric(info_row ->> 'Subsidy Percentage'),
      private.catalog_parse_numeric(info_row ->> 'Subsidy Amount'),
      private.catalog_parse_numeric(info_row ->> 'Minimum Funding Amount'),
      private.catalog_parse_numeric(info_row ->> 'Maximum Funding Amount'),
      private.catalog_text(info_row, 'Subsidy Percentage'),
      private.catalog_text(info_row, 'Subsidy Amount'),
      private.catalog_text(info_row, 'Minimum Funding Amount'),
      private.catalog_text(info_row, 'Maximum Funding Amount'),
      private.catalog_text(info_row, 'Application Mode'),
      private.catalog_url(info_row, 'Official Website'),
      private.catalog_url(info_row, 'Application URL'),
      private.catalog_url(info_row, 'Guidelines URL'),
      private.catalog_url(info_row, 'Source URL'),
      private.catalog_text(info_row, 'Version'),
      private.catalog_text(info_row, 'Last Updated'),
      private.catalog_text(info_row, 'Verified (Yes/No)'),
      concat_ws(' ', info_row ->> 'Scheme Name', info_row ->> 'Target Sector',
        info_row ->> 'Target Beneficiary', info_row ->> 'Overview',
        info_row ->> 'Objectives', info_row ->> 'Benefits Description'),
      coalesce(private.catalog_text(info_row, 'Status'), 'ACTIVE'),
      true,
      now()
    )
    on conflict (scheme_code) do update set
      scheme_name = excluded.scheme_name,
      government_level = excluded.government_level,
      ministry = excluded.ministry,
      issuing_department = excluded.issuing_department,
      issuing_body = excluded.issuing_body,
      state = excluded.state,
      district_applicable = excluded.district_applicable,
      target_sector = excluded.target_sector,
      target_beneficiary = excluded.target_beneficiary,
      scheme_type = excluded.scheme_type,
      scheme_category = excluded.scheme_category,
      overview = excluded.overview,
      objectives = excluded.objectives,
      benefits_description = excluded.benefits_description,
      subsidy_percentage = excluded.subsidy_percentage,
      subsidy_amount = excluded.subsidy_amount,
      minimum_funding_amount = excluded.minimum_funding_amount,
      max_funding_amount = excluded.max_funding_amount,
      subsidy_percentage_display = excluded.subsidy_percentage_display,
      subsidy_amount_display = excluded.subsidy_amount_display,
      minimum_funding_display = excluded.minimum_funding_display,
      maximum_funding_display = excluded.maximum_funding_display,
      application_mode = excluded.application_mode,
      official_website = excluded.official_website,
      application_url = excluded.application_url,
      guidelines_url = excluded.guidelines_url,
      source_url = excluded.source_url,
      source_version = excluded.source_version,
      source_last_updated = excluded.source_last_updated,
      verified_text = excluded.verified_text,
      search_keywords = excluded.search_keywords,
      status = excluded.status,
      is_active = true,
      updated_at = now();
  end loop;

  for eligibility_row in select value from jsonb_array_elements(catalog -> 'All Schemes') loop
    code := eligibility_row ->> 'Scheme ID';
    select id into target_scheme_id from public.schemes where scheme_code = code;
    if target_scheme_id is null then
      raise exception 'eligibility row references unknown scheme %', code;
    end if;
    insert into public.scheme_eligibility_content (
      scheme_id, source_name, eligibility_criteria, verified_eligibility,
      research_status, official_source, verification_status,
      verification_notes, updated_at
    ) values (
      target_scheme_id,
      private.catalog_text(eligibility_row, 'Source'),
      private.catalog_text(eligibility_row, 'Eligibility Criteria'),
      private.catalog_text(eligibility_row, 'Verified Eligibility'),
      private.catalog_text(eligibility_row, 'Eligibility Research Status'),
      private.catalog_text(eligibility_row, 'Official Source'),
      private.catalog_text(eligibility_row, 'Verification Status'),
      private.catalog_text(eligibility_row, 'Verification Notes'),
      now()
    ) on conflict (scheme_id) do update set
      source_name = excluded.source_name,
      eligibility_criteria = excluded.eligibility_criteria,
      verified_eligibility = excluded.verified_eligibility,
      research_status = excluded.research_status,
      official_source = excluded.official_source,
      verification_status = excluded.verification_status,
      verification_notes = excluded.verification_notes,
      updated_at = now();
  end loop;

  update public.schemes scheme
  set search_keywords = concat_ws(
    ' ',
    scheme.search_keywords,
    eligibility.source_name,
    eligibility.eligibility_criteria,
    eligibility.verified_eligibility
  )
  from public.scheme_eligibility_content eligibility
  where eligibility.scheme_id = scheme.id
    and scheme.scheme_code = any(incoming_codes);

  delete from public.scheme_documents
  where scheme_id in (select id from public.schemes where scheme_code = any(incoming_codes));

  for document_row in select value from jsonb_array_elements(catalog -> 'Documents Required') loop
    code := document_row ->> 'Scheme Code';
    select id into target_scheme_id from public.schemes where scheme_code = code;
    if target_scheme_id is null then
      raise exception 'document row references unknown scheme %', code;
    end if;
    insert into public.document_types (document_name, description, issuing_authority, is_mandatory_default)
    values (
      document_row ->> 'Document',
      private.catalog_text(document_row, 'Description'),
      private.catalog_text(document_row, 'Issuing Authority'),
      lower(coalesce(document_row ->> 'Mandatory', '')) = 'yes'
    ) on conflict (document_name) do update set
      description = excluded.description,
      issuing_authority = excluded.issuing_authority,
      is_mandatory_default = excluded.is_mandatory_default,
      updated_at = now()
    returning id into target_document_id;

    insert into public.scheme_documents (
      scheme_id, document_type_id, is_mandatory, remarks, description,
      issuing_authority, estimated_cost, source_url
    ) values (
      target_scheme_id, target_document_id,
      lower(coalesce(document_row ->> 'Mandatory', '')) = 'yes',
      private.catalog_text(document_row, 'Remarks'),
      private.catalog_text(document_row, 'Description'),
      private.catalog_text(document_row, 'Issuing Authority'),
      private.catalog_text(document_row, 'Estimated Cost'),
      private.catalog_url(document_row, 'Source URL')
    );
  end loop;

  delete from public.scheme_services
  where scheme_id in (select id from public.schemes where scheme_code = any(incoming_codes));

  for service_row in select value from jsonb_array_elements(catalog -> 'Services Required') loop
    code := substring(service_row ->> 'Service Name' from '^(IN[0-9]{3})');
    parsed_service_name := btrim(regexp_replace(service_row ->> 'Service Name', '^IN[0-9]{3}\s*', ''));
    select id into target_scheme_id from public.schemes where scheme_code = code;
    if target_scheme_id is null or parsed_service_name = '' then
      raise exception 'service row has invalid scheme prefix: %', service_row ->> 'Service Name';
    end if;
    insert into public.services (service_name, category, description, is_active, updated_at)
    values (
      parsed_service_name,
      private.catalog_text(service_row, 'Category'),
      private.catalog_text(service_row, 'Description'),
      true,
      now()
    ) on conflict (service_name) do update set
      category = excluded.category,
      description = excluded.description,
      is_active = true,
      updated_at = now()
    returning id into target_service_id;

    insert into public.scheme_services (
      scheme_id, service_id, is_required, remarks, source_service_name,
      source_category, source_description
    )
    values (
      target_scheme_id,
      target_service_id,
      lower(coalesce(service_row ->> 'Mandatory (TRUE/FALSE)', 'false')) = 'true',
      private.catalog_text(service_row, 'Description'),
      service_row ->> 'Service Name',
      private.catalog_text(service_row, 'Category'),
      private.catalog_text(service_row, 'Description')
    ) on conflict (scheme_id, service_id) do update set
      is_required = excluded.is_required,
      remarks = excluded.remarks,
      source_service_name = excluded.source_service_name,
      source_category = excluded.source_category,
      source_description = excluded.source_description,
      updated_at = now();
  end loop;

  select count(*) into document_total
  from public.scheme_documents sd
  join public.schemes s on s.id = sd.scheme_id
  where s.scheme_code = any(incoming_codes);
  select count(*) into service_total
  from public.scheme_services ss
  join public.schemes s on s.id = ss.scheme_id
  where s.scheme_code = any(incoming_codes);

  return jsonb_build_object(
    'scheme_count', scheme_total,
    'document_count', document_total,
    'service_count', service_total
  );
end;
$$;

create or replace function private.publish_scheme_catalog(
  notes text default null,
  allow_large_drop boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  snapshot jsonb;
  payload_text text;
  active_count integer;
  documents_count integer;
  services_count integer;
  previous_count integer;
  created_release public.catalog_releases;
begin
  select count(*) into active_count from public.schemes where is_active;
  if active_count = 0 then
    raise exception 'cannot publish an empty scheme catalog';
  end if;
  if exists (
    select 1 from public.schemes
    where is_active and (btrim(scheme_code) = '' or btrim(scheme_name) = '')
  ) then
    raise exception 'active schemes must have a code and name';
  end if;
  if exists (
    select 1
    from public.schemes scheme
    left join public.scheme_eligibility_content eligibility
      on eligibility.scheme_id = scheme.id
    where scheme.is_active and eligibility.scheme_id is null
  ) then
    raise exception 'every active scheme must have eligibility content';
  end if;
  if exists (
    select 1
    from public.schemes
    where is_active and (
      (coalesce(official_website, '') <> '' and official_website !~* '^https?://')
      or (coalesce(application_url, '') <> '' and application_url !~* '^https?://')
      or (coalesce(guidelines_url, '') <> '' and guidelines_url !~* '^https?://')
      or (coalesce(source_url, '') <> '' and source_url !~* '^https?://')
    )
  ) then
    raise exception 'scheme URLs must use http or https';
  end if;
  if exists (
    select 1 from public.scheme_documents sd
    left join public.schemes s on s.id = sd.scheme_id
    left join public.document_types dt on dt.id = sd.document_type_id
    where s.id is null or dt.id is null
  ) or exists (
    select 1 from public.scheme_services ss
    left join public.schemes s on s.id = ss.scheme_id
    left join public.services service on service.id = ss.service_id
    where s.id is null or service.id is null
  ) then
    raise exception 'catalog contains orphaned document or service mappings';
  end if;

  select scheme_count into previous_count
  from public.catalog_releases where is_current limit 1;
  if previous_count is not null and active_count < ceil(previous_count * 0.9)
     and not allow_large_drop then
    raise exception 'active scheme count dropped by more than 10%% (% to %)', previous_count, active_count;
  end if;

  select count(*) into documents_count
  from public.scheme_documents sd join public.schemes s on s.id = sd.scheme_id
  where s.is_active;
  select count(*) into services_count
  from public.scheme_services ss join public.schemes s on s.id = ss.scheme_id
  where s.is_active;

  snapshot := jsonb_build_object(
    'Catalog Metadata', jsonb_build_object(
      'Schema Version', 1,
      'Generated At', now(),
      'Scheme Count', active_count
    ),
    'All Schemes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'Scheme ID', s.scheme_code,
        'Scheme Name', s.scheme_name,
        'Source', coalesce(ec.source_name, ''),
        'Eligibility Criteria', coalesce(ec.eligibility_criteria, ''),
        'Verified Eligibility', coalesce(ec.verified_eligibility, ''),
        'Eligibility Research Status', coalesce(ec.research_status, ''),
        'Official Source', coalesce(ec.official_source, ''),
        'Verification Status', coalesce(ec.verification_status, ''),
        'Verification Notes', coalesce(ec.verification_notes, '')
      ) order by s.scheme_code)
      from public.schemes s
      left join public.scheme_eligibility_content ec on ec.scheme_id = s.id
      where s.is_active
    ), '[]'::jsonb),
    'Scheme Info', coalesce((
      select jsonb_agg(jsonb_build_object(
        'Scheme Code', s.scheme_code,
        'Scheme Name', s.scheme_name,
        'Government Level', coalesce(s.government_level, ''),
        'Ministry', coalesce(s.ministry, ''),
        'Department', coalesce(s.issuing_department, ''),
        'Implementing Agency', coalesce(s.issuing_body, ''),
        'State', coalesce(s.state, ''),
        'District Applicable', coalesce(s.district_applicable, ''),
        'Target Sector', coalesce(s.target_sector, ''),
        'Target Beneficiary', coalesce(s.target_beneficiary, ''),
        'Scheme Type', coalesce(s.scheme_type, ''),
        'Overview', coalesce(s.overview, ''),
        'Objectives', coalesce(s.objectives, ''),
        'Benefits Description', coalesce(s.benefits_description, ''),
        'Subsidy Percentage', coalesce(s.subsidy_percentage_display, ''),
        'Subsidy Amount', coalesce(s.subsidy_amount_display, ''),
        'Minimum Funding Amount', coalesce(s.minimum_funding_display, ''),
        'Maximum Funding Amount', coalesce(s.maximum_funding_display, ''),
        'Application Mode', coalesce(s.application_mode, ''),
        'Official Website', coalesce(s.official_website, ''),
        'Application URL', coalesce(s.application_url, ''),
        'Guidelines URL', coalesce(s.guidelines_url, ''),
        'Status', coalesce(s.status, ''),
        'Version', coalesce(s.source_version, ''),
        'Last Updated', coalesce(s.source_last_updated, ''),
        'Source URL', coalesce(s.source_url, ''),
        'Verified (Yes/No)', coalesce(s.verified_text, '')
      ) order by s.scheme_code)
      from public.schemes s where s.is_active
    ), '[]'::jsonb),
    'Documents Required', coalesce((
      select jsonb_agg(jsonb_build_object(
        'Scheme Code', s.scheme_code,
        'Scheme Name', s.scheme_name,
        'Document', dt.document_name,
        'Mandatory', case when sd.is_mandatory then 'Yes' else 'No' end,
        'Issuing Authority', coalesce(sd.issuing_authority, dt.issuing_authority, ''),
        'Description', coalesce(sd.description, dt.description, ''),
        'Estimated Cost', coalesce(sd.estimated_cost, ''),
        'Remarks', coalesce(sd.remarks, ''),
        'Source URL', coalesce(sd.source_url, '')
      ) order by s.scheme_code, dt.document_name)
      from public.scheme_documents sd
      join public.schemes s on s.id = sd.scheme_id and s.is_active
      join public.document_types dt on dt.id = sd.document_type_id
    ), '[]'::jsonb),
    'Services Required', coalesce((
      select jsonb_agg(jsonb_build_object(
        'Service Name', coalesce(ss.source_service_name, s.scheme_code || ' — ' || service.service_name),
        'Category', coalesce(ss.source_category, service.category, ''),
        'Mandatory (TRUE/FALSE)', ss.is_required,
        'Description', coalesce(ss.source_description, service.description, ss.remarks, '')
      ) order by s.scheme_code, ss.display_order, service.service_name)
      from public.scheme_services ss
      join public.schemes s on s.id = ss.scheme_id and s.is_active
      join public.services service on service.id = ss.service_id
    ), '[]'::jsonb)
  );

  payload_text := snapshot::text;
  update public.catalog_releases set is_current = false where is_current;
  insert into public.catalog_releases (
    schema_version, payload, sha256, byte_size, scheme_count,
    document_count, service_count, is_current, notes, published_by
  ) values (
    1,
    payload_text,
    encode(extensions.digest(convert_to(payload_text, 'UTF8'), 'sha256'), 'hex'),
    octet_length(payload_text),
    active_count,
    documents_count,
    services_count,
    true,
    notes,
    auth.uid()
  ) returning * into created_release;
  return jsonb_build_object(
    'id', created_release.id,
    'version', created_release.version,
    'schema_version', created_release.schema_version,
    'sha256', created_release.sha256,
    'byte_size', created_release.byte_size,
    'scheme_count', created_release.scheme_count,
    'document_count', created_release.document_count,
    'service_count', created_release.service_count,
    'published_at', created_release.published_at
  );
end;
$$;

create or replace function private.promote_catalog_release(release_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  promoted public.catalog_releases;
begin
  select * into promoted from public.catalog_releases where id = release_id;
  if promoted.id is null then
    raise exception 'catalog release % does not exist', release_id;
  end if;
  update public.catalog_releases set is_current = false where is_current;
  update public.catalog_releases set is_current = true where id = release_id
  returning * into promoted;
  return jsonb_build_object(
    'id', promoted.id,
    'version', promoted.version,
    'schema_version', promoted.schema_version,
    'sha256', promoted.sha256,
    'scheme_count', promoted.scheme_count,
    'published_at', promoted.published_at
  );
end;
$$;

create or replace function public.admin_publish_scheme_catalog(
  notes text default null,
  allow_large_drop boolean default false
)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select private.publish_scheme_catalog(notes, allow_large_drop);
$$;

alter table public.scheme_eligibility_content enable row level security;
alter table public.catalog_releases enable row level security;

drop policy if exists "Public can view scheme eligibility content" on public.scheme_eligibility_content;
create policy "Public can view scheme eligibility content"
on public.scheme_eligibility_content for select to anon, authenticated using (true);

drop policy if exists "Public can view current catalog release" on public.catalog_releases;
create policy "Public can view current catalog release"
on public.catalog_releases for select to anon, authenticated
using (is_current and status = 'published');

grant select on public.scheme_eligibility_content to anon, authenticated;
grant select on public.catalog_releases to anon, authenticated;

revoke all on function public.admin_import_scheme_catalog(jsonb) from public, anon, authenticated;
revoke all on function public.admin_publish_scheme_catalog(text, boolean) from public, anon, authenticated;
grant execute on function public.admin_import_scheme_catalog(jsonb) to service_role;
grant execute on function public.admin_publish_scheme_catalog(text, boolean) to service_role;

revoke all on function private.catalog_text(jsonb, text) from public;
revoke all on function private.catalog_parse_numeric(text) from public;
revoke all on function private.catalog_url(jsonb, text) from public;
revoke all on function private.catalog_release_immutable() from public;
revoke all on function private.publish_scheme_catalog(text, boolean) from public;
revoke all on function private.promote_catalog_release(uuid) from public;

comment on table public.catalog_releases is
  'Immutable, versioned mobile catalog snapshots. Anonymous callers see only the current published release.';
comment on function public.admin_import_scheme_catalog(jsonb) is
  'Service-role-only transactional import of the curated four-section JSON catalog.';
comment on function private.publish_scheme_catalog(text, boolean) is
  'Dashboard-only publication action. Invoke from SQL editor after reviewing catalog changes.';

commit;
