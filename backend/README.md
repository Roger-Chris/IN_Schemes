# SearchEngine Backend Monorepo

This directory contains the entire backend codebase, database schemas, and edge functions of the project.

## Directory Structure

```
backend/
    docs/               # API documentation and technical reference documents
    supabase/           # Supabase project configuration, migrations, and Edge Functions
        config.toml     # Supabase project config
        migrations/     # Database migration scripts (001 to hardening)
        functions/      # Edge functions (recommend, schemes-api, search)
        seed.sql        # Database seeding scripts
    tests/              # Integration and unit tests
    README.md           # This document
```

## Running Supabase Commands

All Supabase commands must be run from this directory (`backend/`):

```bash
# 1. Navigate to the backend directory
cd backend

# 2. Deploy/push migrations to remote database
supabase db push

# 3. Deploy Edge Functions
supabase functions deploy recommend
supabase functions deploy schemes-api
supabase functions deploy search

# 4. Check migration status
supabase migration list

# 5. Seed the database
supabase db seed
```
