-- ============================================================================
-- Migration: database_architecture_v2
-- Project : IN Schemes (MSS)
-- Version : v2.0 Production-grade Database Update (Phase 1)
-- ============================================================================

begin;

-- ============================================================================
-- 1. Enable Required Extensions
-- ============================================================================
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;
create extension if not exists "uuid-ossp";
create extension if not exists vector;

-- ============================================================================
-- 2. Drop Legacy Catalog-Related Tables (No Backward Compatibility Required)
-- ============================================================================
drop table if exists public.scheme_eligibility_content cascade;
drop table if exists public.scheme_documents cascade;
drop table if exists public.scheme_services cascade;
drop table if exists public.eligibility_rules cascade;
drop table if exists public.document_types cascade;
drop table if exists public.services cascade;
drop table if exists public.search_documents cascade;
drop table if exists public.catalog_releases cascade;
drop table if exists public.schemes cascade;
drop table if exists public.promo_alerts cascade;
drop table if exists public.admin_users cascade;
drop table if exists public.query_cache cascade;

-- ============================================================================
-- 3. Create Custom Target Schemas
-- ============================================================================
create schema if not exists catalog;
create schema if not exists admin;
create schema if not exists private;

-- Revoke public access to private helper schema
revoke all on schema private from public, anon, authenticated;

-- ============================================================================
-- 4. public Schema Tables (Client demographical & preference details)
-- ============================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  name text,
  photo_url text,
  language varchar(10) default 'en',
  navigation_mode varchar(20) default 'regular',
  applicant_type text,
  state text,
  district text,
  pincode varchar(10),
  is_profile_complete boolean default false,
  dob date,
  gender varchar(50),
  disability varchar(100),
  veteran boolean default false,
  house text,
  street text,
  area text,
  village text,
  city text,
  qualification text,
  annual_income numeric(15,2) default 0.00,
  community varchar(100),
  notifications boolean default true,
  theme varchar(20) default 'light',
  phone varchar(20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.startup_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  profile_name text not null,
  description text,
  industry text not null,
  applicant_type text not null,
  business_stage text not null check (business_stage in ('Idea', 'Prototype', 'Registered', 'Operational', 'Expansion')),
  business_registered boolean not null default false,
  funding_required_amount numeric(15,2) check (funding_required_amount >= 0),
  funding_purpose text,
  is_first_generation_entrepreneur boolean not null default false,
  is_active boolean not null default false,
  last_used_at timestamptz,
  registration_numbers text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- 5. admin Schema Tables (System Governance & Audits)
-- ============================================================================

create table if not exists admin.roles (
  id smallint generated always as identity primary key,
  code text not null unique check (code ~ '^[a-z][a-z_]{1,31}$'),
  description text not null,
  created_at timestamptz not null default now()
);

-- Seed core administrative system roles
insert into admin.roles (code, description)
values
  ('content_editor', 'Create, edit, and submit drafts in assigned regions'),
  ('regional_reviewer', 'Review assigned-region revisions without self-approval'),
  ('publisher', 'Publish approved revisions and withdraw published schemes'),
  ('administrator', 'Manage staff assignments, regions, and taxonomies'),
  ('auditor', 'Read authorized workflow and audit history')
on conflict (code) do nothing;

create table if not exists admin.permissions (
  id smallint generated always as identity primary key,
  code text not null unique,
  description text not null
);

create table if not exists admin.admins (
  id uuid primary key references public.profiles(id) on delete cascade,
  role_id smallint not null references admin.roles(id),
  created_at timestamptz not null default now()
);

create table if not exists admin.import_batches (
  id uuid primary key default gen_random_uuid(),
  file_name text not null,
  batch_status text not null default 'PENDING' check (batch_status in ('PENDING', 'VALIDATING', 'PROCESSED', 'FAILED')),
  records_count integer default 0,
  errors jsonb default '[]'::jsonb,
  imported_by uuid references admin.admins(id) on delete set null,
  imported_at timestamptz not null default now()
);

create table if not exists admin.catalog_releases (
  id uuid primary key default gen_random_uuid(),
  version bigint generated always as identity unique,
  schema_version integer not null default 2 check (schema_version > 0),
  minimum_app_version text not null default '1.0.0',
  maximum_app_version text,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  is_current boolean not null default false,
  notes text,
  published_by uuid references admin.admins(id) on delete set null,
  published_at timestamptz not null default now()
);

create table if not exists admin.catalog_files (
  id uuid primary key default gen_random_uuid(),
  release_id uuid references admin.catalog_releases(id) on delete cascade,
  file_name text not null,
  checksum text not null,
  byte_size integer not null check (byte_size > 0),
  storage_path text not null,
  compression text default 'identity',
  mime_type text not null default 'application/json',
  etag text,
  download_count integer default 0,
  last_downloaded_at timestamptz
);

create table if not exists admin.catalog_release_history (
  id uuid primary key default gen_random_uuid(),
  release_id uuid references admin.catalog_releases(id) on delete cascade,
  action text not null,
  actor_id uuid references admin.admins(id) on delete set null,
  timestamp timestamptz not null default now()
);

create table if not exists admin.catalog_change_log (
  id bigint generated always as identity primary key,
  entity text not null,
  entity_id text not null,
  field_path text not null,
  previous_value jsonb,
  new_value jsonb,
  reason text,
  changed_by uuid references admin.admins(id) on delete set null,
  approved_by uuid references admin.admins(id) on delete set null,
  timestamp timestamptz not null default now()
);

create table if not exists admin.catalog_validation_runs (
  id uuid primary key default gen_random_uuid(),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  status text not null default 'PENDING' check (status in ('PENDING', 'PASSED', 'FAILED')),
  errors jsonb default '[]'::jsonb,
  run_by uuid references admin.admins(id) on delete set null
);

create table if not exists admin.catalog_publish_jobs (
  id uuid primary key default gen_random_uuid(),
  release_id uuid not null references admin.catalog_releases(id) on delete cascade,
  status text not null default 'PENDING' check (status in ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED'))
);

create table if not exists admin.translation_jobs (
  id uuid primary key default gen_random_uuid(),
  source_lang text not null default 'en',
  target_lang text not null default 'ta',
  entity_type text not null,
  entity_id text not null,
  field_name text not null,
  status text not null default 'PENDING' check (status in ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
  source_text text not null,
  translated_text text,
  errors text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists admin.translation_memory (
  id uuid primary key default gen_random_uuid(),
  english_text text unique not null,
  tamil_text text not null,
  created_at timestamptz not null default now()
);

create table if not exists admin.record_locks (
  entity_type text not null,
  entity_id text not null,
  checked_out_by uuid not null references admin.admins(id) on delete cascade,
  locked_until timestamptz not null,
  primary key (entity_type, entity_id)
);

create table if not exists admin.job_queue (
  id uuid primary key default gen_random_uuid(),
  job_type text not null check (job_type in ('TRANSLATION', 'VALIDATION', 'EMBEDDING', 'JSON_EXPORT', 'MANIFEST', 'CHECKSUMS')),
  payload jsonb not null,
  status text not null default 'PENDING' check (status in ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED')),
  error_log text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists admin.event_log (
  id bigint generated always as identity primary key,
  event_type text not null,
  actor_id uuid references admin.admins(id) on delete set null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- 6. private Helper Schema Functions
-- ============================================================================

-- Function to check if a user is an administrative user (admin / editor / publisher)
create or replace function private.has_admin_role(user_id uuid, role_codes text[])
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 
    from admin.admins a
    join admin.roles r on r.id = a.role_id
    where a.id = user_id and r.code = any(role_codes)
  );
$$;

-- ============================================================================
-- 7. catalog Schema Tables (Offline Catalog Structures - Hybrid Design)
-- ============================================================================

create table if not exists catalog.entity_registry (
  entity_id text primary key,
  entity_type text not null,
  catalog_name text not null,
  current_version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists catalog.common (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null
);

create table if not exists catalog.authority (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns
  code text unique not null,
  name_en text not null,
  name_ta text
);

create table if not exists catalog.institution (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns
  code text unique not null,
  name_en text not null,
  name_ta text,
  authority_id text references catalog.authority(id) on delete set null
);

create table if not exists catalog.scheme (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns
  scheme_code text unique not null,
  name_en text not null,
  name_ta text,
  government_level text not null,
  scheme_type text,
  state text default 'All India',
  primary_authority_id text references catalog.authority(id) on delete set null,
  primary_institution_id text references catalog.institution(id) on delete set null,
  minimum_funding_amount numeric(15,2),
  maximum_funding_amount numeric(15,2),
  is_active boolean default true
);

create table if not exists catalog.finance (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns (Deferred constraint for import order compatibility)
  scheme_id text not null references catalog.scheme(id) on delete cascade deferrable initially deferred,
  interest_subvention_rate numeric(5,2),
  max_loan_amount numeric(15,2)
);

create table if not exists catalog.tax (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns (Deferred constraint for import order compatibility)
  scheme_id text not null references catalog.scheme(id) on delete cascade deferrable initially deferred,
  exemption_percentage numeric(5,2)
);

create table if not exists catalog.export (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns (Deferred constraint for import order compatibility)
  scheme_id text not null references catalog.scheme(id) on delete cascade deferrable initially deferred,
  target_countries text[]
);

create table if not exists catalog.csr (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns (Deferred constraint for import order compatibility)
  scheme_id text not null references catalog.scheme(id) on delete cascade deferrable initially deferred,
  focus_areas text[]
);

create table if not exists catalog.treds (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns (Deferred constraint for import order compatibility)
  scheme_id text not null references catalog.scheme(id) on delete cascade deferrable initially deferred,
  interest_rate_range text
);

create table if not exists catalog.search_index (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,
  
  -- hybrid relational columns (Deferred constraint for import order compatibility)
  scheme_id text unique not null references catalog.scheme(id) on delete cascade deferrable initially deferred,
  content text not null,
  embedding extensions.vector(1536)
);

create table if not exists catalog.relationships (
  id uuid primary key default gen_random_uuid(),
  source_type text not null,
  source_id text not null,
  target_type text not null,
  target_id text not null,
  relationship_type text not null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists catalog.ai_metadata (
  entity_id text primary key references catalog.entity_registry(entity_id) on delete cascade,
  summary_en text,
  summary_ta text,
  keywords text[],
  embedding_status text not null default 'PENDING' check (embedding_status in ('PENDING', 'GENERATED', 'FAILED')),
  generated_at timestamptz,
  approved boolean default false
);

-- ============================================================================
-- 8. public Application Data Tables (Rest of v2.0 Scope)
-- ============================================================================

create table if not exists public.saved_schemes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  scheme_id text not null references catalog.scheme(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, scheme_id)
);

create table if not exists public.recent_schemes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  scheme_id text not null references catalog.scheme(id) on delete cascade,
  viewed_at timestamptz not null default now()
);

create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.user_memory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  key text not null,
  value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, key)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  notification_type text,
  is_read boolean default false,
  created_at timestamptz not null default now()
);

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists public.search_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  query text not null,
  results_count integer,
  created_at timestamptz not null default now()
);

create table if not exists public.bug_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text not null,
  device_info jsonb,
  status text default 'OPEN' check (status in ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
  created_at timestamptz not null default now()
);

create table if not exists public.feature_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text not null,
  upvotes integer default 0,
  status text default 'UNDER_REVIEW' check (status in ('UNDER_REVIEW', 'PLANNED', 'IN_DEVELOPMENT', 'COMPLETED', 'DECLINED')),
  created_at timestamptz not null default now()
);

create table if not exists public.sync_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  device_id text,
  platform text,
  previous_release_version bigint,
  synced_release_version bigint not null,
  status text not null check (status in ('SUCCESS', 'FAILED')),
  error_message text,
  duration_ms integer,
  synced_at timestamptz not null default now()
);

-- ============================================================================
-- 9. Indexes Setup
-- ============================================================================

create index if not exists catalog_scheme_filter_idx on catalog.scheme (government_level, state, scheme_type);
create index if not exists catalog_scheme_name_en_idx on catalog.scheme (name_en);
create index if not exists catalog_scheme_name_ta_idx on catalog.scheme (name_ta);
create index if not exists catalog_scheme_search_idx on catalog.scheme using gin (to_tsvector('english', name_en || ' ' || coalesce(search_keywords, '')));

create index if not exists catalog_relationships_src_idx on catalog.relationships (source_type, source_id);
create index if not exists catalog_relationships_tgt_idx on catalog.relationships (target_type, target_id);

create index if not exists admin_translation_mem_en_idx on admin.translation_memory (english_text);
create index if not exists admin_catalog_releases_one_current_idx on admin.catalog_releases (is_current) where is_current;

create index if not exists catalog_search_index_vector_idx on catalog.search_index using hnsw(embedding vector_cosine_ops);

-- ============================================================================
-- 10. Row Level Security (RLS) & Security Policies
-- ============================================================================

-- Enable RLS everywhere
alter table catalog.entity_registry enable row level security;
alter table catalog.common enable row level security;
alter table catalog.authority enable row level security;
alter table catalog.institution enable row level security;
alter table catalog.scheme enable row level security;
alter table catalog.finance enable row level security;
alter table catalog.tax enable row level security;
alter table catalog.export enable row level security;
alter table catalog.csr enable row level security;
alter table catalog.treds enable row level security;
alter table catalog.search_index enable row level security;
alter table catalog.relationships enable row level security;
alter table catalog.ai_metadata enable row level security;

alter table public.profiles enable row level security;
alter table public.startup_profiles enable row level security;
alter table public.saved_schemes enable row level security;
alter table public.recent_schemes enable row level security;
alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.user_memory enable row level security;
alter table public.notifications enable row level security;
alter table public.feedback enable row level security;
alter table public.search_logs enable row level security;
alter table public.bug_reports enable row level security;
alter table public.feature_requests enable row level security;
alter table public.sync_history enable row level security;

alter table admin.roles enable row level security;
alter table admin.permissions enable row level security;
alter table admin.admins enable row level security;
alter table admin.import_batches enable row level security;
alter table admin.catalog_releases enable row level security;
alter table admin.catalog_files enable row level security;
alter table admin.catalog_release_history enable row level security;
alter table admin.catalog_change_log enable row level security;
alter table admin.catalog_validation_runs enable row level security;
alter table admin.catalog_publish_jobs enable row level security;
alter table admin.translation_jobs enable row level security;
alter table admin.translation_memory enable row level security;
alter table admin.record_locks enable row level security;
alter table admin.job_queue enable row level security;
alter table admin.event_log enable row level security;

-- Policies for catalog tables
create policy "Anon/Public read catalog registry" on catalog.entity_registry for select to anon, authenticated using (status = 'PUBLISHED' and is_deleted = false);
create policy "Anon/Public read common" on catalog.common for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read authority" on catalog.authority for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read institution" on catalog.institution for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read scheme" on catalog.scheme for select to anon, authenticated using (is_active = true and status = 'PUBLISHED');
create policy "Anon/Public read finance" on catalog.finance for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read tax" on catalog.tax for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read export" on catalog.export for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read csr" on catalog.csr for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read treds" on catalog.treds for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read search_index" on catalog.search_index for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Anon/Public read relationships" on catalog.relationships for select to anon, authenticated using (true);
create policy "Anon/Public read ai_metadata" on catalog.ai_metadata for select to anon, authenticated using (approved = true);

-- Catalog Editor/Admin write access
create policy "Admins/Editors manage catalog registry" on catalog.entity_registry for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage common" on catalog.common for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage authority" on catalog.authority for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage institution" on catalog.institution for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage scheme" on catalog.scheme for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage finance" on catalog.finance for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage tax" on catalog.tax for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage export" on catalog.export for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage csr" on catalog.csr for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage treds" on catalog.treds for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage search_index" on catalog.search_index for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage relationships" on catalog.relationships for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Admins/Editors manage ai_metadata" on catalog.ai_metadata for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));

-- Policies for public tables
create policy "Profiles select access" on public.profiles for select to anon, authenticated using (true);
create policy "Profiles update access" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "Users manage own startup profile" on public.startup_profiles for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own saved schemes" on public.saved_schemes for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own recent schemes" on public.recent_schemes for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own ai conversations" on public.ai_conversations for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own ai messages" on public.ai_messages for all to authenticated using (exists (select 1 from public.ai_conversations c where c.id = conversation_id and c.user_id = auth.uid())) with check (exists (select 1 from public.ai_conversations c where c.id = conversation_id and c.user_id = auth.uid()));
create policy "Users manage own user memory" on public.user_memory for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own notifications" on public.notifications for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users create feedback" on public.feedback for insert to authenticated with check (auth.uid() = user_id);
create policy "Admins read feedback" on public.feedback for select to authenticated using (private.has_admin_role(auth.uid(), array['administrator']));

create policy "Users create search logs" on public.search_logs for insert to authenticated with check (auth.uid() = user_id);
create policy "Admins read search logs" on public.search_logs for select to authenticated using (private.has_admin_role(auth.uid(), array['administrator']));

create policy "Users manage own bug reports" on public.bug_reports for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Admins manage all bug reports" on public.bug_reports for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator'])) with check (private.has_admin_role(auth.uid(), array['administrator']));

create policy "Public read feature requests" on public.feature_requests for select to anon, authenticated using (true);
create policy "Users create/upvote feature requests" on public.feature_requests for insert to authenticated with check (auth.uid() = user_id);
create policy "Admins manage feature requests" on public.feature_requests for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator'])) with check (private.has_admin_role(auth.uid(), array['administrator']));

create policy "Users create sync history" on public.sync_history for insert to authenticated with check (auth.uid() = user_id);
create policy "Admins read sync history" on public.sync_history for select to authenticated using (private.has_admin_role(auth.uid(), array['administrator']));

-- Policies for admin tables
create policy "Admins manage admin roles" on admin.roles for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator'])) with check (private.has_admin_role(auth.uid(), array['administrator']));
create policy "Admins manage admin permissions" on admin.permissions for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator'])) with check (private.has_admin_role(auth.uid(), array['administrator']));
create policy "Admins manage admins list" on admin.admins for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator'])) with check (private.has_admin_role(auth.uid(), array['administrator']));

create policy "Staff manage import batches" on admin.import_batches for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher']));

create policy "Public view catalog releases" on admin.catalog_releases for select to anon, authenticated using (status = 'published');
create policy "Staff manage catalog releases" on admin.catalog_releases for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'publisher']));

create policy "Public view catalog files" on admin.catalog_files for select to anon, authenticated using (true);
create policy "Staff manage catalog files" on admin.catalog_files for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'publisher']));

create policy "Staff manage catalog release history" on admin.catalog_release_history for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'publisher']));
create policy "Staff manage catalog change logs" on admin.catalog_change_log for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher']));
create policy "Staff manage validation runs" on admin.catalog_validation_runs for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher']));
create policy "Staff manage publish jobs" on admin.catalog_publish_jobs for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'publisher']));

create policy "Staff manage translation jobs" on admin.translation_jobs for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));
create policy "Staff manage translation memory" on admin.translation_memory for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));

create policy "Staff manage locks" on admin.record_locks for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor', 'publisher']));
create policy "Staff manage job queue" on admin.job_queue for all to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'publisher'])) with check (private.has_admin_role(auth.uid(), array['administrator', 'publisher']));
create policy "Staff view event logs" on admin.event_log for select to authenticated using (private.has_admin_role(auth.uid(), array['administrator', 'auditor']));

-- ============================================================================
-- 11. Storage Bucket Config Infrastructure (catalogs Bucket)
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('catalogs', 'catalogs', true)
on conflict (id) do nothing;

create policy "Public Access to catalogs bucket"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'catalogs');

create policy "Admins/Publishers modify catalogs bucket"
on storage.objects for all
to authenticated
using (
  bucket_id = 'catalogs' and
  private.has_admin_role(auth.uid(), array['administrator', 'publisher'])
);

commit;
