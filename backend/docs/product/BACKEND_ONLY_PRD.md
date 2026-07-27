# Product Requirements Document: Backend-Only MVP

**Product:** IN Schemes
**Document version:** 1.0
**Status:** Ready for engineering review
**Initial delivery scope:** Backend services and agency administration only
**Primary platform:** Supabase-managed PostgreSQL, Supabase Auth, Row-Level Security, Supabase Storage, and server-side API/Edge Functions where required

## 1. Purpose

Extend the IN Schemes backend into the authoritative, secure, auditable source for government schemes, eligibility information, regional applicability, approved colloquial Tamil content, publication history, and incremental client synchronization.

The first release must be usable by agency administrators through a complete internal API. A minimal administration interface is optional and must be explicitly selected during Sprint 0. The backend must expose stable contracts that the existing Flutter client and future MLOps components can consume without requiring a database redesign.

## 2. Product outcome

At the end of the backend MVP, an authorized agency user must be able to:

1. Create or import a government scheme.
2. Add formal and spoken Tamil content, eligibility rules, application instructions, documents, sources, and regional applicability.
3. Submit the scheme for independent review.
4. Approve and publish an immutable revision.
5. Correct or withdraw previously published content.
6. Retrieve published changes through a region-scoped, cursor-based delta API.
7. Audit who created, reviewed, published, corrected, or withdrew every record.

The backend must continue to support these operations even though the mobile application and model-training pipeline are not part of this delivery.

## 3. Goals

- Establish one authoritative database for all scheme content.
- Protect unpublished and region-restricted data with server-side authorization and RLS.
- Provide a governed content lifecycle with separation of duties.
- Make published content immutable, versioned, traceable, and recoverable.
- Support small incremental downloads using deterministic deltas and tombstones.
- Store display Tamil separately from natural spoken Tamil.
- Prepare stable artifact metadata interfaces for later MLOps integration without implementing model training.
- Deliver production deployment, monitoring, backup, and operational documentation.

## 4. Non-goals

The backend MVP will not include:

- Flutter or Android application development.
- On-device inference, Vosk integration, or Android TTS integration.
- Training, distillation, quantization, evaluation, or registration of ML models.
- Automatic LLM generation of scheme content or colloquial phrases.
- Cloud speech-to-text or text-to-speech.
- Public user accounts, personalized recommendations, or eligibility-profile storage.
- Raw audio or free-form user-query collection.
- Automated model rollout; only the data structures and protected artifact metadata endpoints are prepared.

## 5. Architecture decision

Supabase is the single MVP platform:

```text
Agency administrator
        |
 Supabase Auth
        |
Admin API / Edge Functions
        |
Supabase PostgreSQL
  |             |
 RLS       Transactional change log
        |
Supabase Storage
```

- Supabase PostgreSQL is the only writable system of record.
- Supabase Auth provides staff identity and sessions.
- PostgreSQL RLS enforces organization, role, region, and publication-state boundaries.
- Generated REST endpoints may be used for safe CRUD operations.
- Edge Functions or a dedicated backend service must handle workflows requiring transactions, compound authorization, publication, imports, signed URLs, or privileged service operations.
- Privileged database functions must use a fixed `search_path`, explicit authorization checks, least-privilege execution grants, and tests proving that service-role/RLS bypass cannot be reached from an untrusted client.
- Supabase Storage holds source documents and future immutable artifacts.
- NeonDB is not part of the MVP.

## 6. Users and permissions

| Role | Permissions |
|---|---|
| Content editor | Create and edit drafts for assigned regions; submit for review |
| Regional reviewer | Review and approve/reject content for assigned regions; cannot approve own revision |
| Publisher | Publish approved revisions and withdraw published schemes |
| Administrator | Manage staff, roles, region assignments, taxonomies, and system settings |
| Auditor | Read all permitted revision, approval, publication, and audit records without modifying them |
| Sync client | Read only published records for its server-authorized regions |
| Service worker | Execute narrowly scoped import, publication, maintenance, and future artifact operations |

No user may become privileged by editing client-supplied metadata. Roles and regions must come from trusted server-managed assignments or signed claims.

## 7. Content lifecycle

```text
Draft → In review → Approved → Published
   ↑         |
   └─ Rejected

Published → Corrected by a new revision
Published → Withdrawn with a tombstone
```

Rules:

- Editing a published revision is prohibited.
- A correction creates a new draft revision linked to the published revision it replaces.
- The revision creator cannot be its sole approver.
- Only approved revisions may be published.
- Publication and change-log creation occur in one database transaction.
- Withdrawing a scheme does not erase history; it creates a withdrawal revision and client tombstone.
- Hard deletion is limited to authorized administrators for never-published test/draft data and must be audited.

## 8. Functional requirements

### 8.1 Identity and authorization

- **BE-001:** Staff authenticate through Supabase Auth.
- **BE-002:** Store application roles and region assignments in protected backend tables; do not rely solely on editable user metadata.
- **BE-003:** Enforce authorization through RLS and server-side workflow checks.
- **BE-004:** A content editor can create and modify only permitted drafts.
- **BE-005:** A reviewer can review only assigned regions and cannot approve a revision they created.
- **BE-006:** A sync client can read only published records in server-authorized regions.
- **BE-007:** Service credentials are environment-specific, narrowly scoped, and never exposed to browsers or mobile clients.
- **BE-008:** Role changes, region assignments, authentication failures, and denied privileged operations are audited.
- **BE-009:** All authorization decisions use the authenticated user/installation identity and protected database assignments; request bodies and editable JWT metadata cannot grant roles or regions.

### 8.2 Scheme management

- **BE-010:** Assign every scheme a stable, non-reused identifier independent of its revisions.
- **BE-011:** Support these core fields:
  - official title;
  - short display title;
  - formal description;
  - concise display summary;
  - reviewed spoken Tamil title and summary;
  - benefits;
  - structured and human-readable eligibility rules;
  - application steps;
  - required documents;
  - application channels and official links;
  - owning department/agency;
  - authoritative source references;
  - effective and expiry dates;
  - lifecycle status;
  - applicable regions and beneficiary categories;
  - language and content-schema versions.
- **BE-012:** Validate required fields and date consistency before review submission.
- **BE-013:** Allow multiple authoritative source references and store source title, URL/reference, publication date, retrieval date, and optional uploaded document.
- **BE-014:** Store `display_text` separately from `spoken_text`; spoken content must be human reviewed before publication.
- **BE-015:** Preserve a complete immutable revision history and show field-level differences.
- **BE-016:** Support draft autosave without producing sync deltas.
- **BE-017:** Support correction, supersession, expiry, withdrawal, and archival without destroying prior revisions.
- **BE-018:** Prevent publication when required source, review, region, or effective-date information is missing.
- **BE-019:** Draft updates must use optimistic concurrency through a revision/version token and return a conflict instead of silently overwriting a newer edit.

### 8.3 Eligibility rules

- **BE-020:** Store a human-readable eligibility description for display and speech.
- **BE-021:** Store common eligibility conditions structurally where possible: age, income, gender, occupation, community/category, disability, marital status, student status, landholding, geography, and other scheme-specific conditions.
- **BE-022:** Structured rules must support logical `all`, `any`, and `not` groups and effective dates.
- **BE-023:** The backend will validate rule shape and units but will not determine a real user's eligibility in the MVP.
- **BE-024:** A material eligibility-rule change requires a new revision and review.

### 8.4 Colloquial and spoken Tamil content

- **BE-030:** Allow editors to add scheme aliases, colloquial Tamil phrases, Tanglish forms, common misspellings, and spoken response text.
- **BE-031:** Store phrase text, normalized text, script/language, region, source type, source reference, reviewer, approval state, and linked scheme/intent.
- **BE-032:** Only approved phrases may be returned by published APIs or used by future MLOps pipelines.
- **BE-033:** Detect exact normalized duplicates at write time and flag possible semantic conflicts for review.
- **BE-034:** Spoken text must expand or clarify currency, dates, percentages, abbreviations, department names, phone numbers, and URLs where necessary for comprehensible speech.
- **BE-035:** Region-specific colloquial content must have an explicit region scope; broadly understood conversational Tamil may be marked as common.

### 8.5 Review and publication

- **BE-040:** Editors can submit valid drafts for review.
- **BE-041:** Reviewers can approve or reject with mandatory comments on rejection.
- **BE-042:** The review screen/API must present the proposed revision, previous published revision, field differences, and sources.
- **BE-043:** Publishers can publish only an approved revision.
- **BE-044:** Publication writes the immutable published revision and corresponding change-log records in one transaction.
- **BE-045:** Scheduled publication is optional for MVP; if implemented, it must use the same transactional publication path.
- **BE-046:** Emergency corrections still require recorded approval, but authorized personnel may use an expedited workflow with a mandatory reason.

### 8.6 Bulk import

- **BE-050:** Accept UTF-8 CSV and JSON imports using a documented template.
- **BE-051:** Validate the complete file before committing records unless the user explicitly chooses valid-row import.
- **BE-052:** Return row-level errors with stable error codes, field names, and remediation messages.
- **BE-053:** Require an idempotency key and prevent accidental duplicate imports.
- **BE-054:** Imports create drafts and never publish automatically.
- **BE-055:** Record importer, source file checksum, processing summary, created records, failures, and timestamps.

### 8.7 Delta synchronization

- **BE-060:** Provide `GET /v1/sync/schemes` with an opaque server-issued cursor and bounded page limit.
- **BE-061:** Derive region access from the authenticated installation/session; a query parameter cannot grant region access.
- **BE-062:** Maintain a monotonic `change_sequence`; do not use timestamps alone as synchronization cursors.
- **BE-063:** Return deterministic ordered upserts and tombstones, `next_cursor`, `has_more`, schema version, and generation time.
- **BE-064:** Retrying a cursor must be idempotent while that cursor remains valid.
- **BE-065:** Clients advance their cursor only after applying a complete page; API documentation must state this contract.
- **BE-066:** Support gzip/Brotli compression and conditional requests where appropriate.
- **BE-067:** Define a retention window for delta history. An expired cursor receives a machine-readable recovery response and a bounded region-scoped snapshot mechanism.
- **BE-068:** Never expose draft, rejected, expired-without-validity, or future-unpublished revisions through the sync API.
- **BE-069:** Deletions and withdrawals produce tombstones rather than silently disappearing.
- **BE-069A:** Cursors must be opaque and tamper-evident, encode the last authorized sequence and relevant contract version, and be validated against the authenticated region scope.

Example response:

```json
{
  "schema_version": 1,
  "generated_at": "2026-07-21T12:00:00Z",
  "changes": [
    {
      "sequence": 1042,
      "operation": "upsert",
      "entity": "scheme",
      "id": "sch_123",
      "revision": 7,
      "payload": {}
    },
    {
      "sequence": 1043,
      "operation": "delete",
      "entity": "scheme",
      "id": "sch_456",
      "revision": 3
    }
  ],
  "next_cursor": "opaque-signed-token",
  "has_more": false
}
```

### 8.8 Future artifact registry foundation

This phase does not train or publish ML models, but it establishes compatible backend structures.

- **BE-070:** Store immutable artifact metadata: type, semantic version, storage path, SHA-256, byte size, minimum app version, contract versions, status, and creator.
- **BE-071:** Separate immutable artifact records from mutable release pointers.
- **BE-072:** Allow only authorized service workers to create artifact records and only release approvers to change production pointers.
- **BE-073:** Production storage paths cannot be overwritten; new content requires a new version/path.
- **BE-074:** Provide protected manifest endpoints behind a disabled feature flag until MLOps/mobile integration is approved.

### 8.9 Audit and administration

- **BE-080:** Record actor, action, target, timestamp, request ID, reason, and before/after revision references for privileged mutations.
- **BE-081:** Application users cannot update or delete audit records.
- **BE-082:** Administrators can manage departments, categories, document types, region hierarchy, roles, and assignments.
- **BE-083:** Auditors can search/export audit events within their authorization scope.
- **BE-084:** All production-impacting actions require explicit confirmation and return a traceable request ID.

## 9. Proposed data model

| Table | Purpose |
|---|---|
| `organizations` | Agency/tenant identity if more than one organization operates the system |
| `profiles` | Protected application profile linked to Supabase Auth user |
| `roles` / `user_roles` | Application roles and assignments |
| `regions` | Stable hierarchical village/block/district/state codes |
| `user_regions` | Trusted staff region assignments |
| `client_installations` | Random installation identity and server-authorized region subscriptions |
| `departments` | Scheme-owning government bodies |
| `schemes` | Stable scheme identity and current lifecycle pointer |
| `scheme_revisions` | Immutable versioned scheme content and workflow state |
| `scheme_regions` | Regional applicability of each revision |
| `eligibility_rule_sets` | Versioned structured eligibility expression |
| `scheme_documents` | Required-document definitions |
| `scheme_sources` | Authoritative provenance and storage references |
| `colloquial_terms` | Reviewed aliases, Tamil/Tanglish phrases, normalization and region scope |
| `content_reviews` | Reviewer decisions, comments and timestamps |
| `change_log` | Monotonic client-facing publication sequence and tombstones |
| `import_jobs` / `import_rows` | Idempotent import processing and row-level results |
| `artifact_records` | Future immutable model/vocabulary metadata |
| `artifact_releases` | Future environment/channel release pointers |
| `audit_log` | Append-only privileged activity history |

Database migrations must define primary keys, foreign keys, uniqueness constraints, check constraints, indexes, RLS policies, and update restrictions. Important invariants must not depend only on application code.

All stored timestamps use UTC. Region and content effective dates retain their declared local-date semantics where a time of day is not applicable.

## 10. API surface

### 10.1 Public/client-facing

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/v1/sync/schemes` | Retrieve authorized scheme deltas |
| `GET` | `/v1/sync/snapshot` | Recover a bounded regional snapshot after cursor expiry |
| `GET` | `/v1/health` | Minimal service health response |

### 10.2 Administration

| Method | Endpoint | Purpose |
|---|---|---|
| `GET/POST` | `/v1/admin/schemes` | Search or create schemes |
| `GET/PATCH` | `/v1/admin/schemes/{id}/draft` | Retrieve or edit current draft |
| `GET` | `/v1/admin/schemes/{id}/revisions` | Revision history and diffs |
| `POST` | `/v1/admin/schemes/{id}/submit` | Submit draft for review |
| `POST` | `/v1/admin/revisions/{id}/approve` | Approve revision |
| `POST` | `/v1/admin/revisions/{id}/reject` | Reject revision with reason |
| `POST` | `/v1/admin/revisions/{id}/publish` | Transactionally publish revision |
| `POST` | `/v1/admin/schemes/{id}/withdraw` | Withdraw and create tombstone |
| `POST/GET` | `/v1/admin/imports` | Create/list import jobs |
| `GET` | `/v1/admin/imports/{id}` | Import results |
| `GET` | `/v1/admin/audit` | Authorized audit search |
| `GET/POST/PATCH` | `/v1/admin/taxonomies/*` | Manage controlled reference data |

All endpoints use a stable error envelope:

```json
{
  "error": {
    "code": "REVISION_NOT_APPROVED",
    "message": "The revision must be approved before publication.",
    "request_id": "req_01...",
    "retryable": false
  }
}
```

An OpenAPI specification is a required backend deliverable.

## 11. Non-functional requirements

### 11.1 Availability and performance

| Measure | MVP target |
|---|---:|
| Monthly sync API availability | >= 99.5% |
| P95 sync API server latency | <= 750 ms |
| P95 administrative read latency | <= 1 second |
| P95 administrative mutation latency | <= 2 seconds excluding file imports |
| Normal compressed regional delta | <= 500 KB; alert above 2 MB |
| Critical content correction publication | <= 4 hours after approval |
| Standard approved update publication | <= 1 business day |

### 11.2 Security

- TLS for all network traffic and provider-managed encryption at rest.
- Least-privilege RLS and storage policies with positive and negative automated tests.
- Service-role keys only in protected server environments.
- Rate limiting on authentication, sync, import, and administrative mutation endpoints.
- Input validation, parameterized database access, upload type/size limits, and malware scanning for source documents.
- Dependency, secret, and migration scanning in CI.
- Separate development, staging, and production projects and credentials.
- Multi-factor authentication required for publishers and administrators.

### 11.3 Privacy

- Do not store beneficiary names, phone numbers, exact addresses, eligibility answers, raw queries, or audio in this phase.
- Use random installation IDs rather than advertising or hardware identifiers.
- Store only the minimum coarse region required for synchronization authorization.
- Define retention and deletion policies for authentication, import, application, and audit logs.
- Remove sensitive values from logs and error responses.

### 11.4 Reliability and recovery

- Transactional publication and change-log generation.
- Idempotency keys for import and publication commands.
- Point-in-time recovery where supported and scheduled backup verification.
- Initial disaster-recovery targets: RPO <= 24 hours and RTO <= 8 hours.
- Quarterly restore exercise before production maturity; one successful restore test is required before launch.
- Immutable source-document and future artifact object paths.

### 11.5 Observability

Capture:

- Request count, latency, status, and rate-limit events.
- Authentication and authorization failures.
- Delta page size, change count, cursor age, expired cursors, and snapshot recoveries.
- Draft-to-approval and approval-to-publication duration.
- Import duration and failure distribution.
- Database connections, slow queries, storage errors, and Edge Function failures.
- RLS denial anomalies and privileged operation volume.

Logs must use request IDs and structured fields without exposing content or credentials unnecessarily.

## 12. Testing requirements

- Unit tests for validation, workflow transitions, cursor encoding, normalization, and error mapping.
- Database tests for constraints, triggers/functions, publication transactions, and immutability.
- RLS tests for every role, table, operation, lifecycle state, and cross-region attempt.
- API integration tests using real staging authentication and PostgreSQL policies.
- Contract tests generated from OpenAPI.
- Import tests covering repeated files, partial failures, invalid encodings, oversized files, and duplicate rows.
- Concurrency tests covering simultaneous edits, approvals, and publications.
- Privileged-function tests covering fixed `search_path`, execution grants, forged claims, direct RPC invocation, and service-role boundary assumptions.
- Sync tests covering pagination, retries, concurrent publication, identical timestamps, tombstones, cursor expiry, and interrupted client application.
- Load tests using expected launch traffic multiplied by an agreed safety factor.
- Backup restoration and rollback tests.
- Security review of Auth claims, RLS, service keys, signed URLs, file uploads, and administrative endpoints.

## 13. Acceptance criteria

The backend MVP is accepted when:

1. A staff administrator can invite a user and assign a role and region without exposing service credentials.
2. An editor can create a complete scheme draft with formal, display, and spoken Tamil fields.
3. The creator cannot approve their own revision.
4. A reviewer outside the assigned region cannot read or approve the revision.
5. A publisher can publish an approved revision and the operation produces exactly one logical change-log event transactionally.
6. Retrying the publication command does not duplicate the revision or delta.
7. A published record cannot be edited in place.
8. A correction creates a new revision and a withdrawal generates a tombstone.
9. A sync client receives only published records for server-authorized regions.
10. Concurrent changes and equal timestamps do not result in missed deltas because ordering uses `change_sequence`.
11. An expired cursor produces a bounded regional recovery response.
12. A repeated import with the same idempotency key cannot duplicate content.
13. Audit records identify every privileged actor and cannot be mutated through application roles.
14. OpenAPI, migrations, seed data, RLS policies, automated tests, deployment instructions, and operational runbooks are delivered.
15. Performance, security, backup restoration, and staging-to-production release checks pass.

## 14. Delivery plan

### Sprint 0 — decisions and setup

- Confirm region hierarchy, organization model, role matrix, required scheme fields, and content workflow.
- Create development, staging, and production Supabase projects.
- Establish repository, migrations, CI/CD, secrets, branching, and review rules.
- Deliver OpenAPI and schema drafts for approval.

### Sprint 1 — identity and core data

- Auth integration, protected profiles, roles, region assignments, base taxonomies.
- Scheme identity/revision schema, source records, eligibility structures, and storage policies.
- Initial RLS and database constraint tests.

### Sprint 2 — workflow and administration

- Draft editing, review, approval, rejection, publication, correction, and withdrawal.
- Field diffs, spoken-Tamil fields, colloquial terms, and audit events.
- Minimal administration screens or complete admin API, depending on delivery choice.

### Sprint 3 — sync and import

- Transactional monotonic change log, cursor API, tombstones, recovery snapshots, and compression.
- Idempotent CSV/JSON imports and validation reporting.
- Mobile-facing OpenAPI contract and sample payload fixtures.

### Sprint 4 — hardening and launch

- Complete RLS matrix, security review, load tests, backup restoration, alerts, dashboards, and runbooks.
- Staging acceptance test and controlled production deployment.

Indicative duration: 8–10 weeks for a small backend team, subject to the administration-interface depth and stakeholder review turnaround.

## 15. Backend deliverables

- Version-controlled database migrations and rollback/mitigation notes.
- RLS and Storage policies.
- Backend API/Edge Function source.
- OpenAPI specification and example client fixtures.
- Administration interface or documented admin API agreed for the MVP.
- CSV/JSON import templates.
- Automated test suite and CI/CD configuration.
- Environment and deployment documentation.
- Security, backup/restore, incident, publication, and cursor-recovery runbooks.
- Monitoring dashboards and alert definitions.
- Seeded staging environment with representative synthetic scheme data.

## 16. Dependencies and decisions required before Sprint 1

Stakeholders must confirm:

1. Whether one government agency or multiple organizations will operate the platform.
2. The authoritative village/block/district/state hierarchy and whether schemes can overlap regions.
3. Required versus optional scheme fields and controlled beneficiary categories.
4. Who may edit, review, publish, expedite, withdraw, and administer each region.
5. Whether the MVP adds a minimal web administration interface; the complete administration API remains mandatory either way.
6. Accepted CSV/JSON import formats and representative source documents.
7. Spoken Tamil review ownership and the initial supported Tamil variants.
8. Delta-retention duration and expected launch volume.
9. Production availability, RPO/RTO, and audit-retention obligations.

## 17. Definition of done

The backend-only MVP is complete when the full scheme lifecycle works in production-like staging; region and role boundaries pass automated adversarial RLS tests; publication produces deterministic, retry-safe deltas and tombstones; imports are validated and idempotent; audit history is protected; documented backup restoration succeeds; the OpenAPI contract and fixtures are integrated with the Flutter client; and the production environment has approved monitoring, alerts, operating ownership, and runbooks.

## 18. Source traceability and intentional deviations

| Architecture source requirement | Backend MVP treatment |
|---|---|
| PostgreSQL database and regional RLS | Included; Supabase-managed PostgreSQL is the single system of record |
| NeonDB plus Supabase | Intentionally corrected to Supabase-only for the MVP to avoid split ownership and unsupported RLS/API assumptions |
| JSON deltas since the last synchronization point | Included and strengthened with a monotonic sequence and opaque cursor instead of device timestamps |
| Region-specific rules | Included through server-managed assignments and RLS |
| Supabase Storage for `.tflite` artifacts | Storage and immutable metadata are prepared; model upload/release remains disabled until the MLOps phase |
| `model_versions` metadata | Represented by `artifact_records` and `artifact_releases`, separating immutable files from mutable release pointers |
| Colloquial tagging output | Backend stores and reviews colloquial terms; automatic LLM generation is deferred to MLOps |
| Vosk grammar derived from approved tags | Data is prepared; grammar generation is deferred to MLOps |
| WorkManager, Isar, checksum verification, atomic device swap | Excluded because these are mobile-client responsibilities; backend API contracts support their future implementation |
| MuRIL distillation and INT8 conversion | Explicitly excluded from the backend phase |
| Native Tamil TTS | Backend stores reviewed `spoken_text`; speech synthesis remains a mobile responsibility |
