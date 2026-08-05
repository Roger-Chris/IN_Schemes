# MSS Supabase Database Architecture v2.0

## Executive Summary

This document defines the production database architecture for the MSS (MSMEs Scheme Search) platform.

**Architecture Principles**
- Supabase is the canonical source for published catalog data.
- Offline JSON catalogs are generated from Supabase and shipped to the app.
- Flutter reads only local JSON catalogs during normal operation.
- Catalog updates are delivered independently of Play Store releases.
- Every catalog entity maps 1:1 between the database and generated JSON.

---

# High-Level Architecture

```text
Government Sources
        │
        ▼
Catalog Generation Pipeline
        │
        ▼
Supabase (Master Catalog)
        │
 ┌──────┴──────────────┐
 ▼                     ▼
Admin CMS         Catalog Builder
        │              │
        └──────┬───────┘
               ▼
       JSON Catalog Export
               ▼
      Supabase Storage Bucket
               ▼
          Flutter App
        (Offline First)
```

---

# Database Schemas

## catalog
Stores all government catalog entities.

Tables

- common
- authority
- institution
- scheme
- finance
- tax
- export
- csr
- treds
- search_index

Every table should include:

| Column | Type |
|---------|------|
| id | TEXT PRIMARY KEY |
| version | TEXT |
| status | TEXT |
| checksum | TEXT |
| updated_at | TIMESTAMPTZ |
| published_at | TIMESTAMPTZ |
| record_json | JSONB |

`record_json` must mirror the generated JSON catalog exactly.

---

## public

Application data.

Tables

- profiles
- startup_profiles
- saved_schemes
- recent_schemes
- ai_conversations
- ai_messages
- user_memory
- notifications
- feedback
- search_logs
- bug_reports
- feature_requests

---

## admin

Publishing and governance.

Tables

- catalog_releases
- catalog_files
- catalog_release_history
- catalog_change_log
- catalog_validation_runs
- catalog_publish_jobs
- roles
- permissions
- admins

---

# Catalog Release Flow

1. Admin edits catalog entity.
2. Validation executes.
3. JSON catalogs regenerated.
4. Manifest regenerated.
5. Checksums calculated.
6. Files uploaded to Storage.
7. New release published.
8. Flutter syncs automatically.

---

# Catalog Storage

```
catalogs/
    latest/
    1.0.0-alpha/
    1.1.0-alpha/
    1.2.0-alpha/
```

Each release contains:

- manifest.json
- common_catalog.json
- authority_catalog.json
- institution_catalog.json
- scheme_catalog.json
- finance_catalog.json
- tax_catalog.json
- export_catalog.json
- csr_catalog.json
- treds_catalog.json
- search_index.json

---

# Synchronization

Flutter downloads only catalogs whose checksum has changed.

Workflow:

1. Read manifest.
2. Compare local checksums.
3. Download changed catalogs.
4. Replace local copies.
5. Continue offline.

---

# Validation

Required before every release:

- validate_base
- validate_catalog
- validate_cross_catalog
- validate_i18n

Publishing is blocked if validation fails.

---

# Audit

Every catalog modification must record:

- entity
- entity_id
- field_path
- previous_value
- new_value
- reason
- changed_by
- approved_by
- timestamp

---

# Edge Functions

- checkCatalogVersion()
- publishCatalog()
- generateManifest()
- exportCatalog()
- validateCatalog()
- rollbackRelease()

---

# Row Level Security

Roles:

- User
- Editor
- Reviewer
- Publisher
- Administrator

---

# API

- /catalog/version
- /catalog/download
- /catalog/checksum
- /catalog/search
- /admin/publish
- /admin/validate
- /admin/release

---

# Guiding Principles

1. Supabase is the master source of published data.
2. JSON catalogs are generated artifacts.
3. Flutter consumes offline catalogs.
4. Catalog updates never require a Play Store update.
5. Immutable releases are preserved for rollback.
6. IDs remain stable across releases.
7. Validation gates every publication.
