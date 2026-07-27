begin;

create extension if not exists pgcrypto with schema extensions;

-- This migration is additive to the existing citizen-facing IN Schemes schema.
-- Staff identities reuse public.users, while organization membership and
-- authorization assignments remain protected application records.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create type public.region_level as enum (
  'country',
  'state',
  'district',
  'block',
  'village',
  'other'
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z0-9][A-Z0-9_-]{1,31}$'),
  name text not null check (length(btrim(name)) between 2 and 200),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_memberships (
  user_id uuid not null references public.users(id) on delete restrict,
  organization_id uuid not null references public.organizations(id) on delete restrict,
  display_name text not null check (length(btrim(display_name)) between 2 and 200),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, organization_id)
);

create table public.roles (
  id smallint generated always as identity primary key,
  code text not null unique check (code ~ '^[a-z][a-z_]{1,31}$'),
  description text not null,
  created_at timestamptz not null default now()
);

insert into public.roles (code, description)
values
  ('content_editor', 'Create, edit, and submit drafts in assigned regions'),
  ('regional_reviewer', 'Review assigned-region revisions without self-approval'),
  ('publisher', 'Publish approved revisions and withdraw published schemes'),
  ('administrator', 'Manage staff assignments, regions, and taxonomies'),
  ('auditor', 'Read authorized workflow and audit history')
on conflict (code) do nothing;

create table public.user_roles (
  user_id uuid not null,
  organization_id uuid not null,
  role_id smallint not null references public.roles(id) on delete restrict,
  granted_by uuid references auth.users(id) on delete set null,
  granted_at timestamptz not null default now(),
  primary key (user_id, organization_id, role_id),
  foreign key (user_id, organization_id)
    references public.organization_memberships(user_id, organization_id) on delete cascade
);

create table public.regions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  code text not null check (length(btrim(code)) between 1 and 64),
  name text not null check (length(btrim(name)) between 1 and 200),
  level public.region_level not null,
  parent_id uuid,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, code),
  unique (id, organization_id),
  foreign key (parent_id, organization_id)
    references public.regions(id, organization_id) on delete restrict,
  check (parent_id is null or parent_id <> id)
);

create index regions_parent_idx on public.regions (parent_id);
create index regions_organization_level_idx
  on public.regions (organization_id, level) where active;

create table public.user_regions (
  user_id uuid not null,
  organization_id uuid not null,
  region_id uuid not null,
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (user_id, region_id),
  foreign key (user_id, organization_id)
    references public.organization_memberships(user_id, organization_id) on delete cascade,
  foreign key (region_id, organization_id)
    references public.regions(id, organization_id) on delete cascade
);

create index user_regions_user_organization_idx
  on public.user_regions (user_id, organization_id);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  code text not null check (length(btrim(code)) between 1 and 64),
  name text not null check (length(btrim(name)) between 2 and 200),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, code)
);

create table public.beneficiary_categories (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  code text not null check (length(btrim(code)) between 1 and 64),
  name text not null check (length(btrim(name)) between 2 and 200),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, code)
);

create table public.audit_log (
  id bigint generated always as identity primary key,
  organization_id uuid not null references public.organizations(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null check (length(btrim(action)) between 3 and 100),
  target_type text not null check (length(btrim(target_type)) between 2 and 100),
  target_id text not null check (length(btrim(target_id)) between 1 and 200),
  request_id uuid not null,
  reason text,
  before_revision_id uuid,
  after_revision_id uuid,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now()
);

create index audit_log_organization_created_idx
  on public.audit_log (organization_id, created_at desc);
create index audit_log_request_id_idx on public.audit_log (request_id);
create index audit_log_target_idx
  on public.audit_log (organization_id, target_type, target_id, created_at desc);

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = statement_timestamp();
  return new;
end;
$$;

create trigger organizations_set_updated_at
before update on public.organizations
for each row execute function private.set_updated_at();

create trigger organization_memberships_set_updated_at
before update on public.organization_memberships
for each row execute function private.set_updated_at();

create trigger regions_set_updated_at
before update on public.regions
for each row execute function private.set_updated_at();

create trigger departments_set_updated_at
before update on public.departments
for each row execute function private.set_updated_at();

create trigger beneficiary_categories_set_updated_at
before update on public.beneficiary_categories
for each row execute function private.set_updated_at();

create function private.prevent_audit_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using
    errcode = 'P0001',
    message = 'audit_log is append-only';
end;
$$;

create trigger audit_log_prevent_update_delete
before update or delete on public.audit_log
for each row execute function private.prevent_audit_mutation();

create function private.belongs_to_organization(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_memberships as profile
    where profile.user_id = auth.uid()
      and profile.organization_id = target_organization_id
      and profile.active
  );
$$;

create function private.has_role(
  target_organization_id uuid,
  required_role_codes text[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
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

create function private.has_region(target_region_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
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

revoke all on function private.set_updated_at() from public;
revoke all on function private.prevent_audit_mutation() from public;
revoke all on function private.belongs_to_organization(uuid) from public;
revoke all on function private.has_role(uuid, text[]) from public;
revoke all on function private.has_region(uuid) from public;

grant usage on schema private to authenticated;
grant execute on function private.belongs_to_organization(uuid) to authenticated;
grant execute on function private.has_role(uuid, text[]) to authenticated;
grant execute on function private.has_region(uuid) to authenticated;

alter table public.organizations enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
alter table public.regions enable row level security;
alter table public.user_regions enable row level security;
alter table public.departments enable row level security;
alter table public.beneficiary_categories enable row level security;
alter table public.audit_log enable row level security;

create policy organizations_read_members
on public.organizations for select to authenticated
using (private.belongs_to_organization(id));

create policy organizations_update_administrators
on public.organizations for update to authenticated
using (private.has_role(id, array['administrator']))
with check (private.has_role(id, array['administrator']));

create policy organization_memberships_read_self_or_oversight
on public.organization_memberships for select to authenticated
using (
  user_id = auth.uid()
  or private.has_role(organization_id, array['administrator', 'auditor'])
);

create policy organization_memberships_manage_administrators
on public.organization_memberships for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

create policy roles_read_authenticated
on public.roles for select to authenticated
using (true);

create policy user_roles_read_self_or_oversight
on public.user_roles for select to authenticated
using (
  user_id = auth.uid()
  or private.has_role(organization_id, array['administrator', 'auditor'])
);

create policy user_roles_manage_administrators
on public.user_roles for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

create policy regions_read_members
on public.regions for select to authenticated
using (private.belongs_to_organization(organization_id));

create policy regions_manage_administrators
on public.regions for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

create policy user_regions_read_self_or_oversight
on public.user_regions for select to authenticated
using (
  user_id = auth.uid()
  or private.has_role(organization_id, array['administrator', 'auditor'])
);

create policy user_regions_manage_administrators
on public.user_regions for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

create policy departments_read_members
on public.departments for select to authenticated
using (private.belongs_to_organization(organization_id));

create policy departments_manage_administrators
on public.departments for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

create policy beneficiary_categories_read_members
on public.beneficiary_categories for select to authenticated
using (private.belongs_to_organization(organization_id));

create policy beneficiary_categories_manage_administrators
on public.beneficiary_categories for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

create policy audit_log_read_oversight
on public.audit_log for select to authenticated
using (private.has_role(organization_id, array['administrator', 'auditor']));

revoke all on table
  public.organizations,
  public.organization_memberships,
  public.roles,
  public.user_roles,
  public.regions,
  public.user_regions,
  public.departments,
  public.beneficiary_categories,
  public.audit_log
from anon;
grant select, insert, update on public.organizations to authenticated;
grant select, insert, update on public.organization_memberships to authenticated;
grant select on public.roles to authenticated;
grant select, insert, update, delete on public.user_roles to authenticated;
grant select, insert, update on public.regions to authenticated;
grant select, insert, update, delete on public.user_regions to authenticated;
grant select, insert, update on public.departments to authenticated;
grant select, insert, update on public.beneficiary_categories to authenticated;
grant select on public.audit_log to authenticated;

commit;
