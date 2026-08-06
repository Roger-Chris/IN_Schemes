


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "admin";


ALTER SCHEMA "admin" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "catalog";


ALTER SCHEMA "catalog" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "private";


ALTER SCHEMA "private" OWNER TO "postgres";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "public";






CREATE TYPE "public"."region_level" AS ENUM (
    'country',
    'state',
    'district',
    'block',
    'village',
    'other'
);


ALTER TYPE "public"."region_level" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."belongs_to_organization"("target_organization_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select exists (
    select 1
    from public.organization_memberships as profile
    where profile.user_id = auth.uid()
      and profile.organization_id = target_organization_id
      and profile.active
  );
$$;


ALTER FUNCTION "private"."belongs_to_organization"("target_organization_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."catalog_parse_numeric"("display_value" "text") RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
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


ALTER FUNCTION "private"."catalog_parse_numeric"("display_value" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."catalog_release_immutable"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
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


ALTER FUNCTION "private"."catalog_release_immutable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."catalog_text"("value" "jsonb", "key_name" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
  select nullif(btrim(coalesce(value ->> key_name, '')), '');
$$;


ALTER FUNCTION "private"."catalog_text"("value" "jsonb", "key_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."catalog_url"("value" "jsonb", "key_name" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
  select case
    when private.catalog_text(value, key_name) ~* '^https?://' then
      private.catalog_text(value, key_name)
    else null
  end;
$$;


ALTER FUNCTION "private"."catalog_url"("value" "jsonb", "key_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."has_admin_role"("user_id" "uuid", "role_codes" "text"[]) RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select exists (
    select 1 
    from admin.admins a
    join admin.roles r on r.id = a.role_id
    where a.id = user_id and r.code = any(role_codes)
  );
$$;


ALTER FUNCTION "private"."has_admin_role"("user_id" "uuid", "role_codes" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."has_region"("target_region_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  with recursive ancestors as (
    select region.id, region.parent_id, region.organization_id
    from public.regions as region
    where region.id = target_region_id

    union all

    select parent.id, parent.parent_id, parent.organization_id
    from public.regions as parent
    join ancestors as child
      on parent.id = child.parent_id
     and parent.organization_id = child.organization_id
  )
  select exists (
    select 1
    from ancestors
    join public.user_regions as assignment
      on assignment.region_id = ancestors.id
     and assignment.organization_id = ancestors.organization_id
    join public.organization_memberships as profile
      on profile.user_id = assignment.user_id
     and profile.organization_id = assignment.organization_id
    where assignment.user_id = auth.uid()
      and profile.active
  );
$$;


ALTER FUNCTION "private"."has_region"("target_region_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."has_role"("target_organization_id" "uuid", "required_role_codes" "text"[]) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select exists (
    select 1
    from public.user_roles as assignment
    join public.roles as role on role.id = assignment.role_id
    join public.organization_memberships as profile
      on profile.user_id = assignment.user_id
     and profile.organization_id = assignment.organization_id
    where assignment.user_id = auth.uid()
      and assignment.organization_id = target_organization_id
      and role.code = any(required_role_codes)
      and profile.active
  );
$$;


ALTER FUNCTION "private"."has_role"("target_organization_id" "uuid", "required_role_codes" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."prevent_audit_mutation"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
  raise exception using
    errcode = 'P0001',
    message = 'audit_log is append-only';
end;
$$;


ALTER FUNCTION "private"."prevent_audit_mutation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."promote_catalog_release"("release_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
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


ALTER FUNCTION "private"."promote_catalog_release"("release_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "private"."publish_scheme_catalog"("notes" "text" DEFAULT NULL::"text", "allow_large_drop" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
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


ALTER FUNCTION "private"."publish_scheme_catalog"("notes" "text", "allow_large_drop" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "private"."publish_scheme_catalog"("notes" "text", "allow_large_drop" boolean) IS 'Dashboard-only publication action. Invoke from SQL editor after reviewing catalog changes.';



CREATE OR REPLACE FUNCTION "private"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
  new.updated_at = statement_timestamp();
  return new;
end;
$$;


ALTER FUNCTION "private"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_import_scheme_catalog"("catalog" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $_$
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
$_$;


ALTER FUNCTION "public"."admin_import_scheme_catalog"("catalog" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."admin_import_scheme_catalog"("catalog" "jsonb") IS 'Service-role-only transactional import of the curated four-section JSON catalog.';



CREATE OR REPLACE FUNCTION "public"."admin_publish_scheme_catalog"("notes" "text" DEFAULT NULL::"text", "allow_large_drop" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select private.publish_scheme_catalog(notes, allow_large_drop);
$$;


ALTER FUNCTION "public"."admin_publish_scheme_catalog"("notes" "text", "allow_large_drop" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recommend_schemes"("startup_profile_id" "uuid") RETURNS TABLE("scheme_id" "uuid", "scheme_name" "text", "match_score" numeric, "matched_rules" "jsonb", "failed_rules" "jsonb", "recommendation_reason" "text")
    LANGUAGE "plpgsql"
    AS $$
declare
  sp_row public.startup_profiles%rowtype;
  sp_json jsonb;
  s_row record;
  r_row record;
  rule_passed boolean;
  val_text text;
  rule_val_numeric numeric;
  rule_val_min numeric;
  rule_val_max numeric;
  rule_single_numeric numeric;
  temp_matched jsonb;
  temp_failed jsonb;
  total_rules integer;
  passed_rules integer;
  final_score numeric;
  reason text;
begin
  select *
  into sp_row
  from public.startup_profiles as startup_profile
  where startup_profile.id = recommend_schemes.startup_profile_id;

  if not found then
    return;
  end if;

  sp_json := to_jsonb(sp_row);

  for s_row in
    select * from public.schemes as scheme where scheme.is_active = true
  loop
    temp_matched := '[]'::jsonb;
    temp_failed := '[]'::jsonb;
    total_rules := 0;
    passed_rules := 0;

    for r_row in
      select *
      from public.eligibility_rules as eligibility_rule
      where eligibility_rule.scheme_id = s_row.id
    loop
      total_rules := total_rules + 1;
      rule_passed := false;
      val_text := sp_json->>r_row.parameter_name;

      if val_text is not null then
        if r_row.operator = '=' then
          rule_passed := lower(val_text) = lower(r_row.value);
        elsif r_row.operator = '!=' then
          rule_passed := lower(val_text) <> lower(r_row.value);
        elsif r_row.operator = 'IN' then
          rule_passed := exists (
            select 1
            from unnest(string_to_array(r_row.value, ',')) as elem
            where trim(lower(elem)) = trim(lower(val_text))
          );
        elsif r_row.operator = 'NOT IN' then
          rule_passed := not exists (
            select 1
            from unnest(string_to_array(r_row.value, ',')) as elem
            where trim(lower(elem)) = trim(lower(val_text))
          );
        elsif r_row.operator = 'CONTAINS' then
          rule_passed := position(lower(r_row.value) in lower(val_text)) > 0;
        elsif r_row.operator = 'BETWEEN' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_val_min := public.safe_cast_to_numeric(split_part(r_row.value, ',', 1));
          rule_val_max := public.safe_cast_to_numeric(split_part(r_row.value, ',', 2));
          rule_passed := rule_val_numeric is not null
            and rule_val_min is not null
            and rule_val_max is not null
            and rule_val_numeric between rule_val_min and rule_val_max;
        elsif r_row.operator = '>' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric > rule_single_numeric;
        elsif r_row.operator = '>=' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric >= rule_single_numeric;
        elsif r_row.operator = '<' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric < rule_single_numeric;
        elsif r_row.operator = '<=' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric <= rule_single_numeric;
        end if;
      end if;

      if rule_passed then
        passed_rules := passed_rules + 1;
        temp_matched := temp_matched || jsonb_build_object(
          'rule_id', r_row.id,
          'parameter', r_row.parameter_name,
          'description', r_row.description
        );
      else
        temp_failed := temp_failed || jsonb_build_object(
          'rule_id', r_row.id,
          'parameter', r_row.parameter_name,
          'description', r_row.description
        );
      end if;
    end loop;

    if total_rules > 0 then
      final_score := round((passed_rules::numeric / total_rules::numeric) * 100, 2);
    else
      final_score := 100.00;
    end if;

    if jsonb_array_length(temp_failed) = 0 then
      reason := 'Your startup profile perfectly matches all eligibility criteria for this scheme.';
    elsif jsonb_array_length(temp_failed) <= 1 then
      reason := 'Your startup profile matches most of the eligibility criteria.';
    else
      reason := 'Your startup profile does not meet several eligibility criteria.';
    end if;

    scheme_id := s_row.id;
    scheme_name := s_row.scheme_name;
    match_score := final_score;
    matched_rules := temp_matched;
    failed_rules := temp_failed;
    recommendation_reason := reason;
    return next;
  end loop;
end;
$$;


ALTER FUNCTION "public"."recommend_schemes"("startup_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."safe_cast_to_numeric"("val" "text") RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    RETURN val::numeric;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."safe_cast_to_numeric"("val" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_schemes"("query_embedding" "public"."vector") RETURNS TABLE("scheme_id" "uuid", "scheme_code" character varying, "scheme_name" "text", "similarity_score" numeric, "overview" "text", "issuing_department" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id AS scheme_id,
        s.scheme_code,
        s.scheme_name,
        round((1 - (sd.embedding <=> query_embedding))::numeric, 4) AS similarity_score,
        s.overview,
        s.issuing_department
    FROM public.search_documents sd
    JOIN public.schemes s ON sd.scheme_id = s.id
    WHERE sd.is_active = true AND s.is_active = true
    ORDER BY sd.embedding <=> query_embedding
    LIMIT 10;
END;
$$;


ALTER FUNCTION "public"."search_schemes"("query_embedding" "public"."vector") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "admin"."admins" (
    "id" "uuid" NOT NULL,
    "role_id" smallint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_change_log" (
    "id" bigint NOT NULL,
    "entity" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "field_path" "text" NOT NULL,
    "previous_value" "jsonb",
    "new_value" "jsonb",
    "reason" "text",
    "changed_by" "uuid",
    "approved_by" "uuid",
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."catalog_change_log" OWNER TO "postgres";


ALTER TABLE "admin"."catalog_change_log" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."catalog_change_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."catalog_files" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "release_id" "uuid",
    "file_name" "text" NOT NULL,
    "checksum" "text" NOT NULL,
    "byte_size" integer NOT NULL,
    "storage_path" "text" NOT NULL,
    "compression" "text" DEFAULT 'identity'::"text",
    "mime_type" "text" DEFAULT 'application/json'::"text" NOT NULL,
    "etag" "text",
    "download_count" integer DEFAULT 0,
    "last_downloaded_at" timestamp with time zone,
    CONSTRAINT "catalog_files_byte_size_check" CHECK (("byte_size" > 0))
);


ALTER TABLE "admin"."catalog_files" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_publish_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "release_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    CONSTRAINT "catalog_publish_jobs_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'RUNNING'::"text", 'COMPLETED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."catalog_publish_jobs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_release_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "release_id" "uuid",
    "action" "text" NOT NULL,
    "actor_id" "uuid",
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."catalog_release_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_releases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "version" bigint NOT NULL,
    "schema_version" integer DEFAULT 2 NOT NULL,
    "minimum_app_version" "text" DEFAULT '1.0.0'::"text" NOT NULL,
    "maximum_app_version" "text",
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "is_current" boolean DEFAULT false NOT NULL,
    "notes" "text",
    "published_by" "uuid",
    "published_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "catalog_releases_schema_version_check" CHECK (("schema_version" > 0)),
    CONSTRAINT "catalog_releases_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'published'::"text", 'archived'::"text"])))
);


ALTER TABLE "admin"."catalog_releases" OWNER TO "postgres";


ALTER TABLE "admin"."catalog_releases" ALTER COLUMN "version" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."catalog_releases_version_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."catalog_validation_runs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "errors" "jsonb" DEFAULT '[]'::"jsonb",
    "run_by" "uuid",
    CONSTRAINT "catalog_validation_runs_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'PASSED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."catalog_validation_runs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."event_log" (
    "id" bigint NOT NULL,
    "event_type" "text" NOT NULL,
    "actor_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."event_log" OWNER TO "postgres";


ALTER TABLE "admin"."event_log" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."event_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."import_batches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "file_name" "text" NOT NULL,
    "batch_status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "records_count" integer DEFAULT 0,
    "errors" "jsonb" DEFAULT '[]'::"jsonb",
    "imported_by" "uuid",
    "imported_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "import_batches_batch_status_check" CHECK (("batch_status" = ANY (ARRAY['PENDING'::"text", 'VALIDATING'::"text", 'PROCESSED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."import_batches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."job_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_type" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "error_log" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "job_queue_job_type_check" CHECK (("job_type" = ANY (ARRAY['TRANSLATION'::"text", 'VALIDATION'::"text", 'EMBEDDING'::"text", 'JSON_EXPORT'::"text", 'MANIFEST'::"text", 'CHECKSUMS'::"text"]))),
    CONSTRAINT "job_queue_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'RUNNING'::"text", 'COMPLETED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."job_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."permissions" (
    "id" smallint NOT NULL,
    "code" "text" NOT NULL,
    "description" "text" NOT NULL
);


ALTER TABLE "admin"."permissions" OWNER TO "postgres";


ALTER TABLE "admin"."permissions" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."record_locks" (
    "entity_type" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "checked_out_by" "uuid" NOT NULL,
    "locked_until" timestamp with time zone NOT NULL
);


ALTER TABLE "admin"."record_locks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."roles" (
    "id" smallint NOT NULL,
    "code" "text" NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "roles_code_check" CHECK (("code" ~ '^[a-z][a-z_]{1,31}$'::"text"))
);


ALTER TABLE "admin"."roles" OWNER TO "postgres";


ALTER TABLE "admin"."roles" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."roles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."translation_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source_lang" "text" DEFAULT 'en'::"text" NOT NULL,
    "target_lang" "text" DEFAULT 'ta'::"text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "field_name" "text" NOT NULL,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "source_text" "text" NOT NULL,
    "translated_text" "text",
    "errors" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "translation_jobs_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'PROCESSING'::"text", 'COMPLETED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."translation_jobs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."translation_memory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "english_text" "text" NOT NULL,
    "tamil_text" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."translation_memory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."ai_metadata" (
    "entity_id" "text" NOT NULL,
    "summary_en" "text",
    "summary_ta" "text",
    "keywords" "text"[],
    "embedding_status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "generated_at" timestamp with time zone,
    "approved" boolean DEFAULT false,
    CONSTRAINT "ai_metadata_embedding_status_check" CHECK (("embedding_status" = ANY (ARRAY['PENDING'::"text", 'GENERATED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "catalog"."ai_metadata" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."authority" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "code" "text",
    "name_en" "text" NOT NULL,
    "name_ta" "text",
    CONSTRAINT "authority_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."authority" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."common" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    CONSTRAINT "common_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."common" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."csr" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "focus_areas" "text"[],
    CONSTRAINT "csr_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."csr" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."entity_registry" (
    "entity_id" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "catalog_name" "text" NOT NULL,
    "current_version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "validation_status" "text" DEFAULT 'NOT_VALIDATED'::"text" NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "deleted_reason" "text",
    "checksum" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "entity_registry_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"]))),
    CONSTRAINT "entity_registry_validation_status_check" CHECK (("validation_status" = ANY (ARRAY['PASSED'::"text", 'FAILED'::"text", 'WARNING'::"text", 'NOT_VALIDATED'::"text"])))
);


ALTER TABLE "catalog"."entity_registry" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."export" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "target_countries" "text"[],
    CONSTRAINT "export_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."export" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."finance" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "interest_subvention_rate" numeric(5,2),
    "max_loan_amount" numeric(15,2),
    CONSTRAINT "finance_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."finance" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."institution" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "code" "text",
    "name_en" "text" NOT NULL,
    "name_ta" "text",
    "authority_id" "text",
    CONSTRAINT "institution_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."institution" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."knowledge" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "title" "text" NOT NULL,
    "item_type" "text",
    "category" "text",
    CONSTRAINT "knowledge_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."knowledge" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."relationships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source_type" "text" NOT NULL,
    "source_id" "text" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text" NOT NULL,
    "relationship_type" "text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "catalog"."relationships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."scheme" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_code" "text",
    "name_en" "text" NOT NULL,
    "name_ta" "text",
    "government_level" "text",
    "scheme_type" "text",
    "state" "text" DEFAULT 'All India'::"text",
    "ministry" "text",
    "department" "text",
    "search_keywords" "text",
    "primary_authority_id" "text",
    "primary_institution_id" "text",
    "minimum_funding_amount" numeric(15,2),
    "maximum_funding_amount" numeric(15,2),
    "is_active" boolean DEFAULT true,
    CONSTRAINT "scheme_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."scheme" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."search_index" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "content" "text" NOT NULL,
    "embedding" "public"."vector"(1536),
    CONSTRAINT "search_index_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."search_index" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."tax" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "exemption_percentage" numeric(5,2),
    CONSTRAINT "tax_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."tax" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."treds" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "interest_rate_range" "text",
    CONSTRAINT "treds_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."treds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ai_conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ai_conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ai_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ai_messages_role_check" CHECK (("role" = ANY (ARRAY['user'::"text", 'assistant'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."ai_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_log" (
    "id" bigint NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "actor_user_id" "uuid",
    "action" "text" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text" NOT NULL,
    "request_id" "uuid" NOT NULL,
    "reason" "text",
    "before_revision_id" "uuid",
    "after_revision_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_log_action_check" CHECK ((("length"("btrim"("action")) >= 3) AND ("length"("btrim"("action")) <= 100))),
    CONSTRAINT "audit_log_metadata_check" CHECK (("jsonb_typeof"("metadata") = 'object'::"text")),
    CONSTRAINT "audit_log_target_id_check" CHECK ((("length"("btrim"("target_id")) >= 1) AND ("length"("btrim"("target_id")) <= 200))),
    CONSTRAINT "audit_log_target_type_check" CHECK ((("length"("btrim"("target_type")) >= 2) AND ("length"("btrim"("target_type")) <= 100)))
);


ALTER TABLE "public"."audit_log" OWNER TO "postgres";


ALTER TABLE "public"."audit_log" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."audit_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."auth_user_id" (
    "id" "uuid"
);


ALTER TABLE "public"."auth_user_id" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."beneficiary_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "beneficiary_categories_code_check" CHECK ((("length"("btrim"("code")) >= 1) AND ("length"("btrim"("code")) <= 64))),
    CONSTRAINT "beneficiary_categories_name_check" CHECK ((("length"("btrim"("name")) >= 2) AND ("length"("btrim"("name")) <= 200)))
);


ALTER TABLE "public"."beneficiary_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bug_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "device_info" "jsonb",
    "status" "text" DEFAULT 'OPEN'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "bug_reports_status_check" CHECK (("status" = ANY (ARRAY['OPEN'::"text", 'IN_PROGRESS'::"text", 'RESOLVED'::"text", 'CLOSED'::"text"])))
);


ALTER TABLE "public"."bug_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."departments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "departments_code_check" CHECK ((("length"("btrim"("code")) >= 1) AND ("length"("btrim"("code")) <= 64))),
    CONSTRAINT "departments_name_check" CHECK ((("length"("btrim"("name")) >= 2) AND ("length"("btrim"("name")) <= 200)))
);


ALTER TABLE "public"."departments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "upvotes" integer DEFAULT 0,
    "status" "text" DEFAULT 'UNDER_REVIEW'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "feature_requests_status_check" CHECK (("status" = ANY (ARRAY['UNDER_REVIEW'::"text", 'PLANNED'::"text", 'IN_DEVELOPMENT'::"text", 'COMPLETED'::"text", 'DECLINED'::"text"])))
);


ALTER TABLE "public"."feature_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "rating" integer NOT NULL,
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "feedback_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "notification_type" "text",
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


COMMENT ON TABLE "public"."notifications" IS 'Stores notifications for users.';



CREATE TABLE IF NOT EXISTS "public"."organization_memberships" (
    "user_id" "uuid" NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "display_name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "organization_memberships_display_name_check" CHECK ((("length"("btrim"("display_name")) >= 2) AND ("length"("btrim"("display_name")) <= 200)))
);


ALTER TABLE "public"."organization_memberships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "organizations_code_check" CHECK (("code" ~ '^[A-Z0-9][A-Z0-9_-]{1,31}$'::"text")),
    CONSTRAINT "organizations_name_check" CHECK ((("length"("btrim"("name")) >= 2) AND ("length"("btrim"("name")) <= 200)))
);


ALTER TABLE "public"."organizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "name" "text",
    "photo_url" "text",
    "language" character varying(10) DEFAULT 'en'::character varying,
    "navigation_mode" character varying(20) DEFAULT 'regular'::character varying,
    "applicant_type" "text",
    "state" "text",
    "district" "text",
    "pincode" character varying(10),
    "is_profile_complete" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_login_at" timestamp with time zone DEFAULT "now"(),
    "dob" "date",
    "gender" character varying(50),
    "disability" character varying(100),
    "veteran" boolean DEFAULT false,
    "house" "text",
    "street" "text",
    "area" "text",
    "village" "text",
    "city" "text",
    "qualification" "text",
    "annual_income" numeric(15,2) DEFAULT 0.0,
    "community" character varying(100),
    "notifications" boolean DEFAULT true,
    "theme" character varying(20) DEFAULT 'light'::character varying,
    "phone" character varying(20)
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."question_options" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "question_id" "uuid" NOT NULL,
    "option_label" "text" NOT NULL,
    "option_value" "text" NOT NULL,
    "next_question_id" "uuid",
    "display_order" integer DEFAULT 1,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."question_options" OWNER TO "postgres";


COMMENT ON TABLE "public"."question_options" IS 'Options available for select-type questions.';



CREATE TABLE IF NOT EXISTS "public"."questionnaire_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "startup_profile_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'IN_PROGRESS'::"text",
    "completed_percentage" numeric(5,2) DEFAULT 0,
    "started_at" timestamp with time zone DEFAULT "now"(),
    "completed_at" timestamp with time zone
);


ALTER TABLE "public"."questionnaire_sessions" OWNER TO "postgres";


COMMENT ON TABLE "public"."questionnaire_sessions" IS 'Tracks questionnaire progress for a startup profile.';



CREATE TABLE IF NOT EXISTS "public"."questions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "question_text" "text" NOT NULL,
    "description" "text",
    "field_name" "text" NOT NULL,
    "input_type" "text" NOT NULL,
    "is_required" boolean DEFAULT true,
    "display_order" integer DEFAULT 1,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."questions" OWNER TO "postgres";


COMMENT ON TABLE "public"."questions" IS 'Master list of questionnaire questions.';



CREATE TABLE IF NOT EXISTS "public"."recent_schemes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "scheme_id" "text" NOT NULL,
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."recent_schemes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recommendations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "startup_profile_id" "uuid" NOT NULL,
    "scheme_id" "uuid" NOT NULL,
    "match_score" numeric(5,2) NOT NULL,
    "recommendation_rank" integer NOT NULL,
    "recommendation_reason" "text",
    "generated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."recommendations" OWNER TO "postgres";


COMMENT ON TABLE "public"."recommendations" IS 'Stores generated scheme recommendations for each startup profile.';



CREATE TABLE IF NOT EXISTS "public"."regions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "level" "public"."region_level" NOT NULL,
    "parent_id" "uuid",
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "regions_check" CHECK ((("parent_id" IS NULL) OR ("parent_id" <> "id"))),
    CONSTRAINT "regions_code_check" CHECK ((("length"("btrim"("code")) >= 1) AND ("length"("btrim"("code")) <= 64))),
    CONSTRAINT "regions_name_check" CHECK ((("length"("btrim"("name")) >= 1) AND ("length"("btrim"("name")) <= 200)))
);


ALTER TABLE "public"."regions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" smallint NOT NULL,
    "code" "text" NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "roles_code_check" CHECK (("code" ~ '^[a-z][a-z_]{1,31}$'::"text"))
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


ALTER TABLE "public"."roles" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."roles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."saved_schemes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "scheme_id" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."saved_schemes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."search_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "query" "text" NOT NULL,
    "results_count" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."search_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."startup_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "profile_name" "text" NOT NULL,
    "description" "text",
    "industry" "text" NOT NULL,
    "applicant_type" "text" NOT NULL,
    "business_stage" "text" NOT NULL,
    "business_registered" boolean DEFAULT false NOT NULL,
    "funding_required_amount" numeric(15,2),
    "funding_purpose" "text",
    "is_first_generation_entrepreneur" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT false NOT NULL,
    "last_used_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "registration_numbers" "text",
    CONSTRAINT "chk_business_stage" CHECK (("business_stage" = ANY (ARRAY['Idea'::"text", 'Prototype'::"text", 'Registered'::"text", 'Operational'::"text", 'Expansion'::"text"]))),
    CONSTRAINT "chk_funding_amount" CHECK ((("funding_required_amount" IS NULL) OR ("funding_required_amount" >= (0)::numeric)))
);


ALTER TABLE "public"."startup_profiles" OWNER TO "postgres";


COMMENT ON TABLE "public"."startup_profiles" IS 'Stores multiple startup ideas created by an entrepreneur.';



COMMENT ON COLUMN "public"."startup_profiles"."profile_name" IS 'Friendly name of the startup idea. Example: AI Startup';



COMMENT ON COLUMN "public"."startup_profiles"."industry" IS 'Technology, Agriculture, Manufacturing, Healthcare, etc.';



COMMENT ON COLUMN "public"."startup_profiles"."applicant_type" IS 'Student, Woman Entrepreneur, SHG, Farmer, Artisan, MSME, etc.';



COMMENT ON COLUMN "public"."startup_profiles"."business_stage" IS 'Current stage of the startup.';



COMMENT ON COLUMN "public"."startup_profiles"."funding_required_amount" IS 'Estimated funding required for the startup.';



CREATE TABLE IF NOT EXISTS "public"."sync_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "device_id" "text",
    "platform" "text",
    "previous_release_version" bigint,
    "synced_release_version" bigint NOT NULL,
    "status" "text" NOT NULL,
    "error_message" "text",
    "duration_ms" integer,
    "synced_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sync_history_status_check" CHECK (("status" = ANY (ARRAY['SUCCESS'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "public"."sync_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_memory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_memory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_regions" (
    "user_id" "uuid" NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "region_id" "uuid" NOT NULL,
    "assigned_by" "uuid",
    "assigned_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_regions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_responses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "question_id" "uuid" NOT NULL,
    "answer" "text",
    "answered_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_responses" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_responses" IS 'Stores answers given during questionnaire.';



CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "user_id" "uuid" NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "role_id" smallint NOT NULL,
    "granted_by" "uuid",
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


ALTER TABLE ONLY "admin"."admins"
    ADD CONSTRAINT "admins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_change_log"
    ADD CONSTRAINT "catalog_change_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_files"
    ADD CONSTRAINT "catalog_files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_publish_jobs"
    ADD CONSTRAINT "catalog_publish_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_release_history"
    ADD CONSTRAINT "catalog_release_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_releases"
    ADD CONSTRAINT "catalog_releases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_releases"
    ADD CONSTRAINT "catalog_releases_version_key" UNIQUE ("version");



ALTER TABLE ONLY "admin"."catalog_validation_runs"
    ADD CONSTRAINT "catalog_validation_runs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."event_log"
    ADD CONSTRAINT "event_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."import_batches"
    ADD CONSTRAINT "import_batches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."job_queue"
    ADD CONSTRAINT "job_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."permissions"
    ADD CONSTRAINT "permissions_code_key" UNIQUE ("code");



ALTER TABLE ONLY "admin"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."record_locks"
    ADD CONSTRAINT "record_locks_pkey" PRIMARY KEY ("entity_type", "entity_id");



ALTER TABLE ONLY "admin"."roles"
    ADD CONSTRAINT "roles_code_key" UNIQUE ("code");



ALTER TABLE ONLY "admin"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."translation_jobs"
    ADD CONSTRAINT "translation_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."translation_memory"
    ADD CONSTRAINT "translation_memory_english_text_key" UNIQUE ("english_text");



ALTER TABLE ONLY "admin"."translation_memory"
    ADD CONSTRAINT "translation_memory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."ai_metadata"
    ADD CONSTRAINT "ai_metadata_pkey" PRIMARY KEY ("entity_id");



ALTER TABLE ONLY "catalog"."authority"
    ADD CONSTRAINT "authority_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."common"
    ADD CONSTRAINT "common_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."csr"
    ADD CONSTRAINT "csr_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."entity_registry"
    ADD CONSTRAINT "entity_registry_pkey" PRIMARY KEY ("entity_id");



ALTER TABLE ONLY "catalog"."export"
    ADD CONSTRAINT "export_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."finance"
    ADD CONSTRAINT "finance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."institution"
    ADD CONSTRAINT "institution_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."knowledge"
    ADD CONSTRAINT "knowledge_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."relationships"
    ADD CONSTRAINT "relationships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."scheme"
    ADD CONSTRAINT "scheme_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."scheme"
    ADD CONSTRAINT "scheme_scheme_code_key" UNIQUE ("scheme_code");



ALTER TABLE ONLY "catalog"."search_index"
    ADD CONSTRAINT "search_index_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."tax"
    ADD CONSTRAINT "tax_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."treds"
    ADD CONSTRAINT "treds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ai_conversations"
    ADD CONSTRAINT "ai_conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ai_messages"
    ADD CONSTRAINT "ai_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."beneficiary_categories"
    ADD CONSTRAINT "beneficiary_categories_organization_id_code_key" UNIQUE ("organization_id", "code");



ALTER TABLE ONLY "public"."beneficiary_categories"
    ADD CONSTRAINT "beneficiary_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bug_reports"
    ADD CONSTRAINT "bug_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_organization_id_code_key" UNIQUE ("organization_id", "code");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feature_requests"
    ADD CONSTRAINT "feature_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organization_memberships"
    ADD CONSTRAINT "organization_memberships_pkey" PRIMARY KEY ("user_id", "organization_id");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."question_options"
    ADD CONSTRAINT "question_options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questionnaire_sessions"
    ADD CONSTRAINT "questionnaire_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questions"
    ADD CONSTRAINT "questions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recent_schemes"
    ADD CONSTRAINT "recent_schemes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_startup_profile_id_scheme_id_key" UNIQUE ("startup_profile_id", "scheme_id");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_id_organization_id_key" UNIQUE ("id", "organization_id");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_organization_id_code_key" UNIQUE ("organization_id", "code");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_schemes"
    ADD CONSTRAINT "saved_schemes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_schemes"
    ADD CONSTRAINT "saved_schemes_user_id_scheme_id_key" UNIQUE ("user_id", "scheme_id");



ALTER TABLE ONLY "public"."search_logs"
    ADD CONSTRAINT "search_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."startup_profiles"
    ADD CONSTRAINT "startup_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sync_history"
    ADD CONSTRAINT "sync_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_memory"
    ADD CONSTRAINT "user_memory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_memory"
    ADD CONSTRAINT "user_memory_user_id_key_key" UNIQUE ("user_id", "key");



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_pkey" PRIMARY KEY ("user_id", "region_id");



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_session_id_question_id_key" UNIQUE ("session_id", "question_id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id", "organization_id", "role_id");



CREATE INDEX "admin_catalog_releases_one_current_idx" ON "admin"."catalog_releases" USING "btree" ("is_current") WHERE "is_current";



CREATE INDEX "admin_translation_mem_en_idx" ON "admin"."translation_memory" USING "btree" ("english_text");



CREATE INDEX "catalog_relationships_src_idx" ON "catalog"."relationships" USING "btree" ("source_type", "source_id");



CREATE INDEX "catalog_relationships_tgt_idx" ON "catalog"."relationships" USING "btree" ("target_type", "target_id");



CREATE INDEX "catalog_scheme_filter_idx" ON "catalog"."scheme" USING "btree" ("government_level", "state", "scheme_type");



CREATE INDEX "catalog_scheme_name_en_idx" ON "catalog"."scheme" USING "btree" ("name_en");



CREATE INDEX "catalog_scheme_name_ta_idx" ON "catalog"."scheme" USING "btree" ("name_ta");



CREATE INDEX "catalog_scheme_search_idx" ON "catalog"."scheme" USING "gin" ("to_tsvector"('"english"'::"regconfig", (("name_en" || ' '::"text") || COALESCE("search_keywords", ''::"text"))));



CREATE INDEX "catalog_search_index_vector_idx" ON "catalog"."search_index" USING "hnsw" ("embedding" "public"."vector_cosine_ops");



CREATE INDEX "audit_log_organization_created_idx" ON "public"."audit_log" USING "btree" ("organization_id", "created_at" DESC);



CREATE INDEX "audit_log_request_id_idx" ON "public"."audit_log" USING "btree" ("request_id");



CREATE INDEX "audit_log_target_idx" ON "public"."audit_log" USING "btree" ("organization_id", "target_type", "target_id", "created_at" DESC);



CREATE INDEX "idx_notifications_user" ON "public"."notifications" USING "btree" ("user_id");



CREATE INDEX "idx_question_options_question" ON "public"."question_options" USING "btree" ("question_id");



CREATE INDEX "idx_recommendations_profile" ON "public"."recommendations" USING "btree" ("startup_profile_id");



CREATE INDEX "idx_recommendations_score" ON "public"."recommendations" USING "btree" ("match_score" DESC);



CREATE INDEX "idx_startup_profiles_active" ON "public"."startup_profiles" USING "btree" ("is_active");



CREATE INDEX "idx_startup_profiles_user" ON "public"."startup_profiles" USING "btree" ("user_id");



CREATE INDEX "idx_user_responses_session" ON "public"."user_responses" USING "btree" ("session_id");



CREATE INDEX "regions_organization_level_idx" ON "public"."regions" USING "btree" ("organization_id", "level") WHERE "active";



CREATE INDEX "regions_parent_idx" ON "public"."regions" USING "btree" ("parent_id");



CREATE INDEX "user_regions_user_organization_idx" ON "public"."user_regions" USING "btree" ("user_id", "organization_id");



CREATE OR REPLACE TRIGGER "audit_log_prevent_update_delete" BEFORE DELETE OR UPDATE ON "public"."audit_log" FOR EACH ROW EXECUTE FUNCTION "private"."prevent_audit_mutation"();



CREATE OR REPLACE TRIGGER "beneficiary_categories_set_updated_at" BEFORE UPDATE ON "public"."beneficiary_categories" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "departments_set_updated_at" BEFORE UPDATE ON "public"."departments" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "organization_memberships_set_updated_at" BEFORE UPDATE ON "public"."organization_memberships" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "organizations_set_updated_at" BEFORE UPDATE ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "regions_set_updated_at" BEFORE UPDATE ON "public"."regions" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



ALTER TABLE ONLY "admin"."admins"
    ADD CONSTRAINT "admins_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."admins"
    ADD CONSTRAINT "admins_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "admin"."roles"("id");



ALTER TABLE ONLY "admin"."catalog_change_log"
    ADD CONSTRAINT "catalog_change_log_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_change_log"
    ADD CONSTRAINT "catalog_change_log_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_files"
    ADD CONSTRAINT "catalog_files_release_id_fkey" FOREIGN KEY ("release_id") REFERENCES "admin"."catalog_releases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."catalog_publish_jobs"
    ADD CONSTRAINT "catalog_publish_jobs_release_id_fkey" FOREIGN KEY ("release_id") REFERENCES "admin"."catalog_releases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."catalog_release_history"
    ADD CONSTRAINT "catalog_release_history_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_release_history"
    ADD CONSTRAINT "catalog_release_history_release_id_fkey" FOREIGN KEY ("release_id") REFERENCES "admin"."catalog_releases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."catalog_releases"
    ADD CONSTRAINT "catalog_releases_published_by_fkey" FOREIGN KEY ("published_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_validation_runs"
    ADD CONSTRAINT "catalog_validation_runs_run_by_fkey" FOREIGN KEY ("run_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."event_log"
    ADD CONSTRAINT "event_log_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."import_batches"
    ADD CONSTRAINT "import_batches_imported_by_fkey" FOREIGN KEY ("imported_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."record_locks"
    ADD CONSTRAINT "record_locks_checked_out_by_fkey" FOREIGN KEY ("checked_out_by") REFERENCES "admin"."admins"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "catalog"."ai_metadata"
    ADD CONSTRAINT "ai_metadata_entity_id_fkey" FOREIGN KEY ("entity_id") REFERENCES "catalog"."entity_registry"("entity_id") ON DELETE CASCADE;



ALTER TABLE ONLY "catalog"."csr"
    ADD CONSTRAINT "csr_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."export"
    ADD CONSTRAINT "export_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."finance"
    ADD CONSTRAINT "finance_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."institution"
    ADD CONSTRAINT "institution_authority_id_fkey" FOREIGN KEY ("authority_id") REFERENCES "catalog"."authority"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "catalog"."search_index"
    ADD CONSTRAINT "search_index_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."tax"
    ADD CONSTRAINT "tax_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."treds"
    ADD CONSTRAINT "treds_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."ai_conversations"
    ADD CONSTRAINT "ai_conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ai_messages"
    ADD CONSTRAINT "ai_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."ai_conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."beneficiary_categories"
    ADD CONSTRAINT "beneficiary_categories_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."bug_reports"
    ADD CONSTRAINT "bug_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."feature_requests"
    ADD CONSTRAINT "feature_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."organization_memberships"
    ADD CONSTRAINT "organization_memberships_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."organization_memberships"
    ADD CONSTRAINT "organization_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."question_options"
    ADD CONSTRAINT "question_options_next_question_id_fkey" FOREIGN KEY ("next_question_id") REFERENCES "public"."questions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."question_options"
    ADD CONSTRAINT "question_options_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."questionnaire_sessions"
    ADD CONSTRAINT "questionnaire_sessions_startup_profile_id_fkey" FOREIGN KEY ("startup_profile_id") REFERENCES "public"."startup_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recent_schemes"
    ADD CONSTRAINT "recent_schemes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_startup_profile_id_fkey" FOREIGN KEY ("startup_profile_id") REFERENCES "public"."startup_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_parent_id_organization_id_fkey" FOREIGN KEY ("parent_id", "organization_id") REFERENCES "public"."regions"("id", "organization_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."saved_schemes"
    ADD CONSTRAINT "saved_schemes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."search_logs"
    ADD CONSTRAINT "search_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."startup_profiles"
    ADD CONSTRAINT "startup_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sync_history"
    ADD CONSTRAINT "sync_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_memory"
    ADD CONSTRAINT "user_memory_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_region_id_organization_id_fkey" FOREIGN KEY ("region_id", "organization_id") REFERENCES "public"."regions"("id", "organization_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_user_id_organization_id_fkey" FOREIGN KEY ("user_id", "organization_id") REFERENCES "public"."organization_memberships"("user_id", "organization_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."questionnaire_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_organization_id_fkey" FOREIGN KEY ("user_id", "organization_id") REFERENCES "public"."organization_memberships"("user_id", "organization_id") ON DELETE CASCADE;



CREATE POLICY "Admins manage admin permissions" ON "admin"."permissions" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins manage admin roles" ON "admin"."roles" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins manage admins list" ON "admin"."admins" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Public view catalog files" ON "admin"."catalog_files" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Public view catalog releases" ON "admin"."catalog_releases" FOR SELECT TO "authenticated", "anon" USING (("status" = 'published'::"text"));



CREATE POLICY "Staff manage catalog change logs" ON "admin"."catalog_change_log" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage catalog files" ON "admin"."catalog_files" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage catalog release history" ON "admin"."catalog_release_history" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage catalog releases" ON "admin"."catalog_releases" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage import batches" ON "admin"."import_batches" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage job queue" ON "admin"."job_queue" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage locks" ON "admin"."record_locks" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage publish jobs" ON "admin"."catalog_publish_jobs" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage translation jobs" ON "admin"."translation_jobs" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Staff manage translation memory" ON "admin"."translation_memory" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Staff manage validation runs" ON "admin"."catalog_validation_runs" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff view event logs" ON "admin"."event_log" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'auditor'::"text"]));



ALTER TABLE "admin"."admins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_change_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_files" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_publish_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_release_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_releases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_validation_runs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."event_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."import_batches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."job_queue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."record_locks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."translation_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."translation_memory" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Admins/Editors manage ai_metadata" ON "catalog"."ai_metadata" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage authority" ON "catalog"."authority" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage catalog registry" ON "catalog"."entity_registry" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage common" ON "catalog"."common" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage csr" ON "catalog"."csr" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage export" ON "catalog"."export" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage finance" ON "catalog"."finance" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage institution" ON "catalog"."institution" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage knowledge" ON "catalog"."knowledge" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage relationships" ON "catalog"."relationships" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage scheme" ON "catalog"."scheme" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage search_index" ON "catalog"."search_index" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage tax" ON "catalog"."tax" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage treds" ON "catalog"."treds" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Anon/Public read ai_metadata" ON "catalog"."ai_metadata" FOR SELECT TO "authenticated", "anon" USING (("approved" = true));



CREATE POLICY "Anon/Public read authority" ON "catalog"."authority" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read catalog registry" ON "catalog"."entity_registry" FOR SELECT TO "authenticated", "anon" USING ((("status" = 'PUBLISHED'::"text") AND ("is_deleted" = false)));



CREATE POLICY "Anon/Public read common" ON "catalog"."common" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read csr" ON "catalog"."csr" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read export" ON "catalog"."export" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read finance" ON "catalog"."finance" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read institution" ON "catalog"."institution" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read knowledge" ON "catalog"."knowledge" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read relationships" ON "catalog"."relationships" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Anon/Public read scheme" ON "catalog"."scheme" FOR SELECT TO "authenticated", "anon" USING ((("is_active" = true) AND ("status" = 'PUBLISHED'::"text")));



CREATE POLICY "Anon/Public read search_index" ON "catalog"."search_index" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read tax" ON "catalog"."tax" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read treds" ON "catalog"."treds" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



ALTER TABLE "catalog"."ai_metadata" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."authority" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."common" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."csr" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."entity_registry" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."export" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."finance" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."institution" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."knowledge" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."relationships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."scheme" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."search_index" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."tax" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."treds" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Admins manage all bug reports" ON "public"."bug_reports" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins manage feature requests" ON "public"."feature_requests" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins read feedback" ON "public"."feedback" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins read search logs" ON "public"."search_logs" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins read sync history" ON "public"."sync_history" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Profiles select access" ON "public"."profiles" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Profiles update access" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Public read feature requests" ON "public"."feature_requests" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Users create feedback" ON "public"."feedback" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users create search logs" ON "public"."search_logs" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users create sync history" ON "public"."sync_history" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users create/upvote feature requests" ON "public"."feature_requests" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own ai conversations" ON "public"."ai_conversations" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own ai messages" ON "public"."ai_messages" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."ai_conversations" "c"
  WHERE (("c"."id" = "ai_messages"."conversation_id") AND ("c"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."ai_conversations" "c"
  WHERE (("c"."id" = "ai_messages"."conversation_id") AND ("c"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own bug reports" ON "public"."bug_reports" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own notifications" ON "public"."notifications" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own recent schemes" ON "public"."recent_schemes" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own saved schemes" ON "public"."saved_schemes" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own startup profile" ON "public"."startup_profiles" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own user memory" ON "public"."user_memory" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."ai_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."auth_user_id" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."beneficiary_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bug_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."departments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feature_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feedback" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organization_memberships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."question_options" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questionnaire_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recent_schemes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recommendations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."regions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."saved_schemes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."search_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."startup_profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sync_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_memory" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_regions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_responses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "service_role";






















































































































































REVOKE ALL ON FUNCTION "private"."belongs_to_organization"("target_organization_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "private"."belongs_to_organization"("target_organization_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "private"."catalog_parse_numeric"("display_value" "text") FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."catalog_release_immutable"() FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."catalog_text"("value" "jsonb", "key_name" "text") FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."catalog_url"("value" "jsonb", "key_name" "text") FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."has_region"("target_region_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "private"."has_region"("target_region_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "private"."has_role"("target_organization_id" "uuid", "required_role_codes" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "private"."has_role"("target_organization_id" "uuid", "required_role_codes" "text"[]) TO "authenticated";



REVOKE ALL ON FUNCTION "private"."prevent_audit_mutation"() FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."promote_catalog_release"("release_id" "uuid") FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."publish_scheme_catalog"("notes" "text", "allow_large_drop" boolean) FROM PUBLIC;



REVOKE ALL ON FUNCTION "private"."set_updated_at"() FROM PUBLIC;



REVOKE ALL ON FUNCTION "public"."admin_import_scheme_catalog"("catalog" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_import_scheme_catalog"("catalog" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_publish_scheme_catalog"("notes" "text", "allow_large_drop" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_publish_scheme_catalog"("notes" "text", "allow_large_drop" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "postgres";
GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "anon";
GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "authenticated";
GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "service_role";



GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "postgres";
GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "anon";
GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "authenticated";
GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "service_role";



GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."recommend_schemes"("startup_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recommend_schemes"("startup_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recommend_schemes"("startup_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."safe_cast_to_numeric"("val" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."safe_cast_to_numeric"("val" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."safe_cast_to_numeric"("val" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."search_schemes"("query_embedding" "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."search_schemes"("query_embedding" "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_schemes"("query_embedding" "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";












GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "service_role";









GRANT ALL ON TABLE "public"."ai_conversations" TO "anon";
GRANT ALL ON TABLE "public"."ai_conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."ai_conversations" TO "service_role";



GRANT ALL ON TABLE "public"."ai_messages" TO "anon";
GRANT ALL ON TABLE "public"."ai_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."ai_messages" TO "service_role";



GRANT ALL ON TABLE "public"."audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."auth_user_id" TO "anon";
GRANT ALL ON TABLE "public"."auth_user_id" TO "authenticated";
GRANT ALL ON TABLE "public"."auth_user_id" TO "service_role";



GRANT ALL ON TABLE "public"."beneficiary_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."beneficiary_categories" TO "service_role";



GRANT ALL ON TABLE "public"."bug_reports" TO "anon";
GRANT ALL ON TABLE "public"."bug_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."bug_reports" TO "service_role";



GRANT ALL ON TABLE "public"."departments" TO "authenticated";
GRANT ALL ON TABLE "public"."departments" TO "service_role";



GRANT ALL ON TABLE "public"."feature_requests" TO "anon";
GRANT ALL ON TABLE "public"."feature_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_requests" TO "service_role";



GRANT ALL ON TABLE "public"."feedback" TO "anon";
GRANT ALL ON TABLE "public"."feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."feedback" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."organization_memberships" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_memberships" TO "service_role";



GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."question_options" TO "anon";
GRANT ALL ON TABLE "public"."question_options" TO "authenticated";
GRANT ALL ON TABLE "public"."question_options" TO "service_role";



GRANT ALL ON TABLE "public"."questionnaire_sessions" TO "anon";
GRANT ALL ON TABLE "public"."questionnaire_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."questionnaire_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."questions" TO "anon";
GRANT ALL ON TABLE "public"."questions" TO "authenticated";
GRANT ALL ON TABLE "public"."questions" TO "service_role";



GRANT ALL ON TABLE "public"."recent_schemes" TO "anon";
GRANT ALL ON TABLE "public"."recent_schemes" TO "authenticated";
GRANT ALL ON TABLE "public"."recent_schemes" TO "service_role";



GRANT ALL ON TABLE "public"."recommendations" TO "anon";
GRANT ALL ON TABLE "public"."recommendations" TO "authenticated";
GRANT ALL ON TABLE "public"."recommendations" TO "service_role";



GRANT ALL ON TABLE "public"."regions" TO "authenticated";
GRANT ALL ON TABLE "public"."regions" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."saved_schemes" TO "anon";
GRANT ALL ON TABLE "public"."saved_schemes" TO "authenticated";
GRANT ALL ON TABLE "public"."saved_schemes" TO "service_role";



GRANT ALL ON TABLE "public"."search_logs" TO "anon";
GRANT ALL ON TABLE "public"."search_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."search_logs" TO "service_role";



GRANT ALL ON TABLE "public"."startup_profiles" TO "anon";
GRANT ALL ON TABLE "public"."startup_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."startup_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."sync_history" TO "anon";
GRANT ALL ON TABLE "public"."sync_history" TO "authenticated";
GRANT ALL ON TABLE "public"."sync_history" TO "service_role";



GRANT ALL ON TABLE "public"."user_memory" TO "anon";
GRANT ALL ON TABLE "public"."user_memory" TO "authenticated";
GRANT ALL ON TABLE "public"."user_memory" TO "service_role";



GRANT ALL ON TABLE "public"."user_regions" TO "authenticated";
GRANT ALL ON TABLE "public"."user_regions" TO "service_role";



GRANT ALL ON TABLE "public"."user_responses" TO "anon";
GRANT ALL ON TABLE "public"."user_responses" TO "authenticated";
GRANT ALL ON TABLE "public"."user_responses" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































