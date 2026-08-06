# MSS Catalog Import Specification v1.0

## Document Information

-   **Project:** MSS (MSME Scheme Search)
-   **Version:** 1.0
-   **Status:** Draft for Implementation
-   **Purpose:** Define the complete import contract between generated
    JSON catalogs and the Supabase Database Architecture v2.0.

------------------------------------------------------------------------

# 1. Purpose

This specification defines the deterministic import pipeline used to
load generated MSS JSON catalogs into Supabase.

The importer shall:

-   Preserve entity IDs.
-   Preserve provenance.
-   Preserve localization.
-   Preserve AI metadata.
-   Preserve relationships.
-   Support full and incremental imports.
-   Be transaction-safe and idempotent.

------------------------------------------------------------------------

# 2. Scope

Applies to all MSS catalog JSON files:

1.  common_catalog.json
2.  authority_catalog.json
3.  institution_catalog.json
4.  finance_catalog.json
5.  tax_catalog.json
6.  export_catalog.json
7.  csr_catalog.json
8.  treds_catalog.json
9.  scheme_catalog.json
10. search_index.json

------------------------------------------------------------------------

# 3. Import Architecture

``` text
Generated JSON Catalogs
        │
        ▼
Manifest Validation
        │
        ▼
Checksum Validation
        │
        ▼
Schema Validation
        │
        ▼
Catalog Import Engine
        │
        ▼
Supabase Database
        │
        ├── catalog tables
        ├── entity registry
        ├── relationships
        └── import batches
```

------------------------------------------------------------------------

# 4. Import Order

The following order is mandatory:

1.  common
2.  authority
3.  institution
4.  finance
5.  tax
6.  export
7.  csr
8.  treds
9.  scheme
10. search_index

Dependencies must exist before dependent catalogs are imported.

------------------------------------------------------------------------

# 5. Import Lifecycle

1.  Load manifest.
2.  Verify schema version.
3.  Verify release version.
4.  Verify file checksums.
5.  Validate JSON schema.
6.  Validate entity IDs.
7.  Open database transaction.
8.  Import catalog entities.
9.  Update entity registry.
10. Resolve relationships.
11. Commit transaction.
12. Generate import report.

Any fatal failure shall rollback the entire transaction.

------------------------------------------------------------------------

# 6. Entity Mapping

Each imported entity shall populate:

-   Hybrid relational columns
-   record_json (canonical entity)
-   entity_registry
-   relationship records
-   import metadata

The complete JSON entity must remain intact inside `record_json`.

------------------------------------------------------------------------

# 7. Validation Rules

Every entity must validate:

-   Required fields
-   JSON schema
-   Entity ID format
-   Version
-   Checksum
-   Localization block
-   Provenance block
-   Verification block
-   AI block
-   Analytics block

------------------------------------------------------------------------

# 8. Relationship Resolution

Relationships shall be resolved using immutable IDs.

Supported relationships include:

-   Scheme → Authority
-   Scheme → Institution
-   Scheme → Finance
-   Scheme → Tax
-   Scheme → Export
-   Scheme → CSR
-   Scheme → TReDS
-   Scheme → Search Index

Broken references are fatal validation errors.

------------------------------------------------------------------------

# 9. Conflict Handling

  Condition            Action
  -------------------- -----------------------
  Duplicate ID         Reject import
  Invalid checksum     Reject import
  Missing dependency   Rollback
  Schema mismatch      Reject import
  Duplicate checksum   Skip unchanged record

------------------------------------------------------------------------

# 10. Rollback Strategy

Any fatal validation or database error must:

1.  Rollback transaction.
2.  Preserve previous database state.
3.  Record failure in import_batches.
4.  Generate failure report.

------------------------------------------------------------------------

# 11. Incremental Imports

Importer must support:

-   Full release import
-   Single catalog import
-   Single entity import
-   Incremental update based on checksum

------------------------------------------------------------------------

# 12. Import Batch Tracking

Each import creates an `admin.import_batches` record including:

-   Batch ID
-   Release Version
-   Catalogs Imported
-   Start Time
-   End Time
-   Duration
-   Status
-   Errors
-   Warnings

------------------------------------------------------------------------

# 13. Logging

Every import shall log:

-   Start
-   Completion
-   Imported entities
-   Updated entities
-   Skipped entities
-   Warnings
-   Errors
-   Relationship count

------------------------------------------------------------------------

# 14. Security

Only authorized roles may execute imports.

-   Administrator
-   Publisher
-   Editor (if permitted)

Anonymous users cannot import catalogs.

------------------------------------------------------------------------

# 15. Version Compatibility

Importer shall verify:

-   Manifest version
-   Catalog schema version
-   Database schema version
-   Minimum supported application version

------------------------------------------------------------------------

# 16. Acceptance Tests

The importer is accepted only if:

-   Manifest validation passes.
-   Checksums validate.
-   All entities import successfully.
-   Relationships resolve.
-   Entity registry updates correctly.
-   Localization remains unchanged.
-   Provenance remains unchanged.
-   Round-trip import/export succeeds.
-   Import report is generated.

------------------------------------------------------------------------

# 17. Round-Trip Requirement

The following workflow must be lossless:

``` text
JSON Catalog
     ↓
Import
     ↓
Database
     ↓
Export
     ↓
JSON Catalog
```

The exported catalog must be structurally identical to the imported
catalog except for approved metadata (checksums, timestamps, release
identifiers).

------------------------------------------------------------------------

# 18. Idempotency

Importing the same catalog multiple times shall produce the same
database state.

Requirements:

-   No duplicate entities.
-   Immutable IDs preserved.
-   Unchanged records skipped by checksum.
-   Import batch still recorded for audit.

------------------------------------------------------------------------

# 19. Success Criteria

Phase 2 is complete only when:

-   All catalogs import successfully.
-   No schema changes are required for future catalogs.
-   Database and JSON remain structurally compatible.
-   Referential integrity is preserved.
-   All validation suites pass.
-   Import is repeatable, deterministic, and auditable.
