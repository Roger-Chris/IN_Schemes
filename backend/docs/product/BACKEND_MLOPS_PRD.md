# Product Requirements Document: Backend and MLOps Platform

**Product:** IN Schemes Regional Offline AI
**Document status:** Corrected draft for engineering review (Rev. 1.1)
**Source:** Regional Offline AI Architecture System Design Specification, Rev. 2-Corrected
**Scope:** Agency Hub backend, scheme-data synchronization, MLOps, vocabulary delivery, telemetry, and over-the-air model delivery
**Out of scope:** Flutter UI implementation, on-device TTS implementation, and detailed Android UI design

## 1. Executive summary

IN Schemes is a Flutter application that helps users discover government schemes. Its regional offline AI track adds colloquial Tamil voice and text support. The backend and MLOps platform must keep regional scheme data and narrow-domain language models current without making the mobile experience dependent on connectivity.

The platform will allow authorized agency staff to ingest and review government-scheme information, generate colloquial Tamil and code-mixed search phrases, publish region-scoped scheme deltas, train and evaluate compact intent/scheme-matching models, and safely distribute approved model artifacts to compatible devices. Mobile clients must remain usable when the backend is unavailable.

### 1.1 Corrected reference architecture

The MVP will use **Supabase-managed PostgreSQL as the single authoritative database**, together with Supabase Auth, Row-Level Security, generated REST endpoints where suitable, and Supabase Storage. NeonDB is removed from the MVP architecture because splitting the database, REST/RLS layer, and authentication assumptions across Neon and Supabase introduces avoidable integration and authorization risk. A future move to Neon requires an architecture decision record, a custom API/data-access layer, equivalent authorization tests, and a migration plan.

```text
Mobile app / Agency dashboard
             |
       Supabase Auth
             |
 API / Edge Functions / generated REST
             |
 Supabase PostgreSQL (single system of record + RLS)
             |
 Supabase Storage (immutable model/vocabulary artifacts)
```

## 2. Problem statement

Government-scheme information changes over time and formal descriptions often do not match the words rural Tamil speakers use. A static mobile build will become stale, while full data or model downloads are too expensive and unreliable on constrained networks. The system therefore needs:

1. A governed source of truth for schemes, regions, eligibility rules, and colloquial language.
2. Incremental, region-filtered synchronization instead of full database downloads.
3. A reproducible pipeline that converts reviewed data into an accurate, compact on-device model.
4. Safe over-the-air delivery with compatibility checks, integrity verification, atomic activation, and rollback.
5. Privacy-preserving operational signals that do not compromise the offline-first promise.

## 3. Goals and success metrics

### 3.1 Product goals

- Publish accurate scheme changes to eligible devices without requiring an app release.
- Support colloquial Tamil and relevant Tamil-English code-mixed queries.
- Produce an INT8 TensorFlow Lite student model suitable for approximately 25 MB on-device deployment.
- Provide a domain vocabulary/grammar artifact for constrained Vosk decoding.
- Prevent unauthorized cross-region access through server-side authorization and row-level controls.
- Make every data and model release auditable, reproducible, and reversible.

### 3.2 Initial service-level objectives

| Measure | Target |
|---|---:|
| Delta manifest/API availability | 99.5% monthly |
| Successful delta-sync responses | >= 99% excluding client network loss |
| P95 delta API latency | <= 750 ms server-side |
| Normal regional delta payload | <= 500 KB compressed; alert above 2 MB |
| Model manifest response | <= 2 KB and P95 <= 300 ms |
| Published model integrity | 100% checksum match in release validation |
| Critical scheme correction publication | <= 4 hours after approval |
| Standard scheme update publication | <= 1 business day after approval |
| Model release rollback initiation | <= 15 minutes after decision |
| Pipeline reproducibility | Same inputs/configuration resolve to traceable dataset, code, and artifact versions |

### 3.3 ML quality gates

Exact thresholds must be baselined on the first representative test set. No model may be promoted without defined gates. Recommended launch gates are:

- Macro F1 for intent/scheme matching: >= 0.85 and no worse than 2 percentage points below the approved server-side teacher baseline.
- Recall@3 for scheme retrieval: >= 0.92.
- Critical eligibility/scheme intents: per-class recall >= 0.85.
- Rural-accent and code-mixed evaluation slices: no slice more than 5 percentage points below overall macro F1 without an approved exception.
- Quantized model size: <= 30 MB, with approximately 25 MB as the design target.
- On-device latency and memory must pass the agreed low-end-device benchmark supplied by the mobile team.
- Regression suite: no unresolved severity-1 safety or correctness regression.

## 4. Users and roles

| Role | Core permissions |
|---|---|
| Content editor | Create and edit draft scheme records and colloquial tags for assigned regions |
| Regional reviewer | Approve or reject content for assigned regions |
| ML engineer | Create datasets and training runs; evaluate candidates; cannot alone publish production models |
| Release approver | Promote or roll back approved model/data releases |
| Administrator | Manage users, regions, permissions, and system configuration |
| Mobile client | Read only published, compatible, region-scoped deltas and manifests |
| Auditor | Read immutable history, approvals, lineage, and release records |

Production publication requires separation of duties: the creator of a scheme or model candidate cannot be its sole approver.

## 5. Scope

### 5.1 In scope for the first production release

- Staff authentication and role-/region-based authorization.
- Scheme ingestion through an internal dashboard and structured bulk import.
- Draft, review, approval, publish, archive, and correction workflows.
- LLM-assisted extraction and colloquial-tag generation with mandatory human review.
- Versioned regional scheme data and tombstones for deleted/withdrawn entries.
- Cursor-based delta sync APIs and compact compressed JSON responses.
- Training dataset creation, validation, deduplication, splitting, and versioning.
- MuRIL teacher-based knowledge distillation into a compact student classifier.
- TensorFlow Lite conversion and representative-data INT8 quantization.
- Automated offline evaluation, artifact validation, approval, staged release, rollback, and audit trails.
- Supabase Storage for model and vocabulary artifacts.
- Model and vocabulary manifests containing compatibility and integrity metadata.
- Operational monitoring and privacy-preserving telemetry.
- Resume-capable first-run asset delivery with disk-space, metered-network, retry, and partial-download handling.

### 5.2 Out of scope for the first production release

- Open-ended generative answers on the mobile device.
- Training or serving a general-purpose speech-recognition model.
- Real-time cloud inference as a required user path.
- Automatic publication of LLM-generated content without human approval.
- Personalized models based on identifiable user histories.
- Mandatory upload of raw voice recordings.
- Firebase Remote Config for binary model delivery.

## 6. Product workflows

### 6.1 Scheme content lifecycle

1. An editor creates a scheme or imports a formal source document/structured record.
2. The system stores source provenance, extracts proposed fields, and flags missing or contradictory information.
3. A cloud language service proposes colloquial Tamil/code-mixed phrases and aliases. Generated suggestions are visibly marked as machine-generated and retain the model, prompt, source, confidence, and generation time.
4. An editor corrects the record and suggestions.
5. A regional reviewer approves or rejects it with a reason.
6. Publication creates an immutable content revision and change-log entry.
7. The next regional delta includes the upsert or tombstone.
8. Approved text and tags become eligible for the next training-dataset snapshot and Vosk grammar build.

### 6.2 Model lifecycle

1. An ML engineer creates a dataset snapshot from approved, versioned content plus labeled queries.
2. Validation checks labels, regional representation, duplicates, leakage, personally identifiable information, and data quality.
3. The pipeline trains/fine-tunes the MuRIL teacher where needed, then distills a shallow/MobileBERT-style student for narrow-domain classification.
4. The candidate is converted to TensorFlow Lite and INT8-quantized using a representative calibration set.
5. Automated evaluation runs overall and slice metrics, size checks, compatibility tests, and device benchmarks.
6. A release approver who did not create the run reviews the model card, overall and slice metrics, lineage, and known limitations.
7. The artifact is uploaded to private storage, checksum-verified, and assigned a release channel.
8. A small manifest/version pointer is published. Devices download only when policy and compatibility rules permit.
9. Health metrics are monitored; release may progress, pause, or roll back by changing the manifest pointer.

### 6.3 Device synchronization

1. The client authenticates or presents an installation-scoped credential and its authorized region.
2. On an unmetered connection, WorkManager requests changes using an opaque cursor, not the device clock.
3. The API returns ordered upserts/tombstones, a next cursor, schema version, and optional continuation token.
4. The client applies a page transactionally and advances its cursor only after success.
5. It separately requests the model/vocabulary manifest with app version, ABI, locale, and current artifact versions.
6. If a compatible newer artifact exists, the client downloads it from a short-lived signed URL, verifies size and SHA-256, writes a temporary file, validates loadability, atomically renames it, then marks it active.
7. Failed downloads or validation leave the previous artifact active.

## 7. Functional requirements: backend

### 7.1 Authentication and authorization

- **BE-001:** Staff must authenticate through Supabase Auth or the approved identity provider.
- **BE-002:** APIs must enforce role and region authorization server-side; UI restrictions alone are insufficient.
- **BE-003:** Row-level security policies must prevent staff and clients from reading unpublished content or unauthorized regions.
- **BE-004:** Service identities used by pipelines must have narrowly scoped credentials and be separated by environment.
- **BE-005:** Privileged actions, failed access checks, and permission changes must be audited.
- **BE-006:** Supabase PostgreSQL is the sole writable system of record for the MVP. No second database may receive production writes.
- **BE-007:** Automated authorization tests must prove that a user or installation assigned to one region cannot read or mutate another region's restricted records.

### 7.2 Scheme and taxonomy management

- **BE-010:** Store stable scheme IDs separately from revisions.
- **BE-011:** Store title, formal description, benefits, eligibility rules, application steps, required documents, source URL/reference, owning agency, effective dates, status, regions, languages, and provenance.
- **BE-012:** Support draft, in_review, approved, published, withdrawn, and archived states.
- **BE-013:** Changes to published content must create new immutable revisions.
- **BE-014:** Withdrawal/deletion must publish a tombstone so offline clients remove stale records.
- **BE-015:** Colloquial phrases must store language/script, normalized form, region, source type, source scheme, generating model and prompt version where applicable, confidence, reviewer, approval state, and linkage to a scheme or intent.
- **BE-016:** Bulk import must be idempotent and produce row-level validation reports.
- **BE-017:** LLM output is a suggestion and must not enter production deltas or training data before approval.
- **BE-018:** Validation must detect duplicate, contradictory, abusive/offensive, personally identifying, and scheme-irrelevant generated phrases and route them for human resolution.
- **BE-019:** The dashboard must report suggestion acceptance/rejection rates by generator and prompt version.

### 7.3 Delta synchronization

- **BE-020:** Provide a versioned endpoint such as `GET /v1/sync/schemes?cursor=<opaque>&limit=<n>`.
- **BE-021:** Derive accessible regions from authenticated claims/policy; do not trust a client-supplied region alone.
- **BE-022:** Return deterministic ordering, upserts, tombstones, server-issued next cursor, `has_more`, schema version, and generation timestamp.
- **BE-023:** Cursor semantics must avoid missed changes when timestamps collide; use a monotonic change sequence or compound opaque cursor.
- **BE-024:** Retrying the same request must be safe and return an equivalent page while retained.
- **BE-025:** Responses must support gzip/Brotli and ETag/If-None-Match where applicable.
- **BE-026:** Schema changes must be backward compatible for supported app versions or force a declared minimum app version.
- **BE-027:** If a cursor has expired, return a machine-readable resync response and a region-scoped snapshot path, never an unbounded global dump.
- **BE-028:** Publication and change-log creation must occur in the same database transaction.

Example response:

```json
{
  "schema_version": 1,
  "generated_at": "2026-07-21T12:00:00Z",
  "changes": [
    {"sequence": 1042, "operation": "upsert", "entity": "scheme", "id": "sch_123", "revision": 7, "payload": {}},
    {"sequence": 1043, "operation": "delete", "entity": "scheme", "id": "sch_456", "revision": 3}
  ],
  "next_cursor": "opaque-token",
  "has_more": false
}
```

### 7.4 Artifact manifests and delivery

- **BE-030:** Store model binaries and vocabulary/grammar artifacts in versioned, non-overwritten storage paths.
- **BE-031:** Expose a small manifest endpoint, not the binary itself through Remote Config.
- **BE-032:** Select releases by environment/channel, locale, region where required, minimum/maximum app version, ABI/runtime compatibility, and rollout cohort.
- **BE-033:** The manifest must include artifact ID, semantic version, model/schema type, signed storage URL or path, SHA-256, byte size, minimum app version, created time, and optional expiry.
- **BE-034:** Storage downloads should use short-lived signed URLs; production buckets must not allow anonymous writes.
- **BE-035:** An artifact cannot be published until a server-side re-download verifies checksum and size.
- **BE-036:** Publishing a new pointer and rolling back to the last known-good pointer must be atomic and audited.
- **BE-037:** Support staged rollout percentages with deterministic installation bucketing and an emergency kill/pause switch.
- **BE-038:** Retain at least the current and previous known-good artifacts for every supported channel.
- **BE-039:** First-run and OTA downloads must support HTTP range/resume, bounded exponential retry with jitter, pre-download free-space checks, independent per-artifact progress, and unmetered-network defaults. A failed voice-model download must not prevent an already available text path from working.

Example model manifest:

```json
{
  "model_version": "1.4.0",
  "artifact_url": "https://signed.example/model.tflite",
  "sha256_checksum": "<64 lowercase hex characters>",
  "size_bytes": 25873412,
  "min_app_version": "1.3.0",
  "input_contract_version": 2,
  "label_map_version": "2026.07.1",
  "vocabulary_version": "2026.07.1",
  "rollout_id": "prod-1.4.0-a"
}
```

### 7.5 Internal dashboard

- **BE-040:** Provide searchable queues for drafts, validation failures, reviews, scheduled publications, and model releases.
- **BE-041:** Show source text beside extracted fields and generated phrases.
- **BE-042:** Require rejection comments and display complete revision diffs.
- **BE-043:** Provide release views containing metrics, slice comparisons, artifact metadata, approval history, and rollback controls.
- **BE-044:** Destructive or production-impacting actions require confirmation and explicit authorization.

## 8. Functional requirements: MLOps

### 8.1 Data and labeling

- **ML-001:** Only approved scheme revisions and approved colloquial tags may enter production datasets.
- **ML-002:** Every dataset snapshot must be immutable and carry a unique version, query, source revisions, label schema, creation time, and creator.
- **ML-003:** Detect exact and semantic duplicates and prevent train/test leakage by grouping paraphrases and source families before splitting.
- **ML-004:** Maintain train, validation, and locked test sets stratified by intent, region, dialect/accent proxy where available, script, and code-mixing.
- **ML-005:** Scan text and uploaded samples for sensitive personal data; quarantine violations for review.
- **ML-006:** Track label disagreements and reviewer decisions.
- **ML-007:** Build a versioned Vosk grammar/vocabulary from approved scheme names, aliases, and colloquial phrases, with normalization and collision checks.
- **ML-008:** Group all samples from the same speaker, paraphrase family, and source document into only one dataset split to prevent leakage.
- **ML-009:** Before production training, the locked evaluation corpus must include representative districts, rural accents, age/gender groups where appropriate, formal Tamil, colloquial Tamil, Tanglish, Tamil-English code mixing, low-cost microphones, environmental noise, short/ambiguous utterances, and simulated or observed STT errors.

### 8.2 Training and distillation

- **ML-010:** Training runs must record code commit, container/environment, configuration, random seed, dataset version, teacher checkpoint, student architecture, tokenizer/vocabulary, and metrics.
- **ML-011:** MuRIL is server-side only and must never be included in mobile artifacts.
- **ML-012:** Distill into a compact BERT-family student, initially evaluating a four-layer/MobileBERT-style architecture and a smaller embedding-classifier baseline.
- **ML-013:** Optimize for narrow-domain intent classification and scheme matching, not generative response production.
- **ML-014:** Convert the chosen model to TensorFlow Lite/LiteRT and apply full integer INT8 quantization where supported.
- **ML-015:** Package the model with tokenizer contract, vocabulary, label map, preprocessing specification, input/output tensor metadata, and model card.
- **ML-016:** CI must fail if a package references unavailable operators, exceeds size limits, has incompatible contracts, or cannot load in the reference Android harness.
- **ML-017:** The release pipeline must compare at least a four-layer transformer, a MobileBERT-style student, and a lightweight embedding-classifier baseline before the initial architecture is frozen.
- **ML-018:** If post-training INT8 quantization exceeds the approved quality-regression threshold, the pipeline must use quantization-aware training or reject the candidate; it must never waive the quality gate silently.
- **ML-019:** Every package must declare immutable input-contract, tokenizer, vocabulary, label-map, and minimum-app versions. Existing label IDs may not be reordered or reinterpreted in place.

### 8.3 Evaluation and release governance

- **ML-020:** Evaluate accuracy, macro/micro F1, per-class precision/recall, confusion matrix, Recall@K, confidence calibration, model size, latency, and peak memory.
- **ML-021:** Report quality slices for rural-accent transcription text, colloquial Tamil, formal Tamil, Tamil-English code-mixing, region, short/long queries, and noisy STT output.
- **ML-022:** Compare the quantized student with the previous production model and teacher baseline.
- **ML-023:** Run robustness tests for spelling variation, transliteration, missing tokens, ambiguous scheme names, malformed input, and out-of-domain queries.
- **ML-024:** A release requires automated gates plus approval from a person other than the run creator.
- **ML-025:** Store an immutable model registry record and model card for every promoted or rejected candidate.
- **ML-026:** A rollback changes the active manifest pointer; it must not delete the faulty artifact or its audit evidence.
- **ML-027:** Promotion must fail when any approved evaluation slice is more than five percentage points below overall macro F1, unless a documented exception is approved by product, ML, and the affected regional reviewer.
- **ML-028:** Confidence must be calibrated and the mobile contract must support an explicit `no_confident_match` result rather than forcing a scheme recommendation.
- **ML-029:** The exact exported `.tflite` artifact—not a pre-conversion checkpoint—must pass quality and representative-device performance tests.

### 8.4 Continuous improvement

- **ML-030:** Accept only explicit opt-in, minimized feedback such as selected scheme ID, predicted label, confidence bucket, app/model version, coarse region, and failure category. Raw query text is excluded by default.
- **ML-031:** Raw audio upload is disabled by default. Any future audio collection requires explicit consent, retention limits, access controls, and a separate privacy review.
- **ML-032:** Detect drift in label distribution, low-confidence rate, no-match rate, and correction rate by release and coarse region.
- **ML-033:** Drift alerts create review work; they do not automatically publish retrained models.
- **ML-034:** Telemetry must use a random installation identifier, upload asynchronously in bounded batches, honor the same network policy as sync, and expire both queued and server-side events under documented retention limits.
- **ML-035:** Operational telemetry is logically and physically separated from approved training datasets; inclusion in a future dataset requires a separately recorded review and approval action.

## 9. Proposed logical data model

| Table | Purpose / key fields |
|---|---|
| `regions` | Stable region hierarchy and codes |
| `schemes` | Stable identity, owning agency, lifecycle status |
| `scheme_revisions` | Immutable versioned content, effective dates, provenance, author |
| `scheme_regions` | Many-to-many regional applicability |
| `eligibility_rules` | Structured rules linked to a revision |
| `colloquial_terms` | Phrase, normalized phrase, script/language, region, source/confidence, approval |
| `content_reviews` | Reviewer, decision, reason, timestamp |
| `change_log` | Monotonic sequence, entity, operation, revision, region scope, publication time |
| `dataset_versions` | Immutable snapshot metadata and lineage |
| `training_runs` | Dataset/code/config/teacher/student lineage and run status |
| `model_artifacts` | Version, storage path, SHA-256, size, format, contracts, metrics, status |
| `artifact_releases` | Channel, cohort, compatibility, active pointer, rollout state |
| `vocabulary_artifacts` | Grammar/vocabulary version, storage path, checksum, source dataset |
| `sync_installations` | Random pseudonymous installation ID, server-authorized/coarse region, last cursor/version |
| `telemetry_events` | Minimized operational events with retention controls |
| `audit_log` | Actor, action, target, before/after references, timestamp, request ID |

The source specification names a minimal `model_versions` table containing `version`, `storage_url`, `sha256_checksum`, `size_bytes`, and `min_app_version`. The production design must preserve these fields while separating immutable artifacts from mutable release pointers, allowing staged rollout and safe rollback. All application tables reside in the single Supabase PostgreSQL system of record.

## 10. Non-functional requirements

### 10.1 Offline-first and resilience

- Backend failure must not block already-installed mobile functionality.
- Sync APIs and imports must be idempotent.
- Database publication, change-log creation, and active release pointer changes must be transactional.
- Object-storage artifacts are immutable; new content gets a new version/path.
- Disaster-recovery procedures must restore database content, release pointers, and audit history. Initial targets: RPO <= 24 hours and RTO <= 8 hours, to be tightened after usage is known.

### 10.2 Security

- TLS in transit and platform-managed encryption at rest.
- Secrets held in a managed secret store and rotated; none committed to source or model packages.
- Least-privilege database roles, service identities, storage policies, and RLS tests in CI.
- Dependency, container, and artifact scanning before deployment.
- Rate limiting and abuse protection on public/client endpoints.
- Signed URLs with short expiry; SHA-256 assures integrity after transport.
- Immutable or append-only audit records with controlled retention.

### 10.3 Privacy

- Do not require names, phone numbers, exact addresses, raw utterances, or eligibility answers for ordinary sync/manifest access.
- Use random installation identifiers and coarse region data.
- Document retention periods and deletion procedures before telemetry launches.
- Separate operational logs from training data; production logs never become training data implicitly.

### 10.4 Observability

- Structured logs with correlation/request IDs and no raw sensitive query text by default.
- Metrics for API latency/errors, delta size, expired cursors, publication lag, storage failures, checksum failures, model adoption, activation failures, low-confidence/no-match rates, and pipeline duration/failures.
- Alerts for availability/SLO breaches, unexpected cross-region access denials, stale scheme publication, checksum mismatch, release regression, and abnormal sync payload growth.
- Dashboards must segment by environment, app version, model version, and coarse region without identifying individuals.

### 10.5 Environments and deployment

- Separate development, staging, and production projects, credentials, databases, and storage buckets.
- Schema migrations are version controlled, reviewed, forward tested, and supplied with rollback/mitigation steps.
- Infrastructure and access policies should be defined as code where supported.
- CI/CD must run unit, integration, contract, RLS, migration, security, and artifact-validation tests.
- Production releases require approval and record the build/source revision.
- Application and model compatibility tests must cover every app version still inside the declared support window.

## 11. API surface for MVP

| Method and path | Consumer | Purpose |
|---|---|---|
| `GET /v1/sync/schemes` | Mobile | Cursor-based region-scoped scheme changes |
| `GET /v1/artifacts/model-manifest` | Mobile | Resolve compatible active model release |
| `GET /v1/artifacts/vocabulary-manifest` | Mobile | Resolve compatible Vosk grammar/vocabulary |
| `POST /v1/telemetry/batch` | Mobile | Optional, minimized batched operational telemetry |
| `POST /v1/admin/imports` | Staff | Create an idempotent bulk-ingestion job |
| `GET /v1/admin/imports/{id}` | Staff | Inspect validation and processing results |
| `POST /v1/admin/schemes/{id}/submit` | Staff | Submit a draft revision for review |
| `POST /v1/admin/schemes/{id}/approve` | Reviewer | Approve a revision |
| `POST /v1/admin/schemes/{id}/publish` | Publisher | Publish approved revision and delta |
| `POST /v1/admin/model-releases` | Release approver | Create/stage an artifact release |
| `POST /v1/admin/model-releases/{id}/promote` | Release approver | Advance rollout |
| `POST /v1/admin/model-releases/{id}/rollback` | Release approver | Atomically restore known-good pointer |

All APIs return a stable error envelope containing `code`, user-safe `message`, `request_id`, and optional retry guidance. OpenAPI contracts must be versioned and tested against the mobile client.

## 12. Acceptance criteria

### 12.1 Backend release readiness

- A reviewer can ingest, edit, approve, publish, withdraw, and audit a region-scoped scheme.
- A published change appears exactly once logically in ordered deltas; retries create no duplicate local state.
- A client authorized for one region cannot retrieve another region's restricted rules under positive and negative RLS tests.
- Concurrent publications with identical timestamps do not cause missed records.
- Withdrawn schemes reach clients as tombstones.
- An expired cursor produces a bounded regional recovery flow.
- API contracts pass supported-old-client compatibility tests.
- Positive and negative RLS tests prove every role's regional and lifecycle boundaries, including direct REST/API attempts that bypass the dashboard.

### 12.2 MLOps release readiness

- A training run is reproducible from recorded dataset, code, configuration, and environment identifiers.
- MuRIL is used only as a server-side teacher and is absent from the shipped package.
- The candidate passes agreed quality, size, compatibility, latency, and memory gates.
- Evaluation includes rural/colloquial, code-mixed, noisy-STT, regional, and out-of-domain slices.
- Speaker, paraphrase-family, and source-document leakage tests pass before evaluation metrics are accepted.
- The exported INT8 `.tflite` model passes the same locked evaluation suite used for promotion decisions.
- The model card states intended use, dataset lineage, metrics, limitations, and approval.
- The Vosk vocabulary artifact is derived only from approved content and is versioned/checksummed.

### 12.3 OTA release readiness

- The manifest never selects a model for an incompatible app version/runtime.
- A corrupted or truncated download fails SHA-256/size validation and leaves the current model active.
- Process interruption during download or swap leaves either the old or new complete artifact, never a partial active file.
- The client verifies the model's tensor contract and runs a known-answer inference before switching the active pointer.
- A staged rollout is deterministic per installation and can be paused.
- Rollback restores the previous pointer within 15 minutes without uploading a replacement binary.
- Interrupted first-run downloads resume without restarting completed artifacts; insufficient disk space produces a recoverable state; failure to obtain Vosk does not disable the text experience.

## 13. Delivery plan

### Phase 0 — validation and contract definition (1–2 weeks)

- Provision Supabase-managed PostgreSQL, Auth, and Storage as the single MVP platform; document NeonDB removal in an architecture decision record.
- Define region hierarchy, scheme schema, label taxonomy, API contracts, privacy rules, and representative device matrix.
- Collect and label an initial rural-accent/colloquial Tamil validation corpus before UI dependency.
- Establish baseline teacher/student and Vosk grammar experiments.

### Phase 1 — backend foundation (3–4 weeks)

- Environments, identity, roles, RLS, schema, migrations, audit logging, and storage.
- Scheme CRUD/review/publish workflow and import validation.
- Transactional change log and cursor-based delta API.
- Contract tests and mobile integration sandbox.

### Phase 2 — reproducible MLOps pipeline (4–6 weeks)

- Dataset registry, quality checks, dataset splits, training tracking, teacher/student distillation.
- INT8 conversion, model packaging, automated evaluation, model cards, and registry.
- Versioned Vosk vocabulary generation.

### Phase 3 — OTA and controlled rollout (2–3 weeks)

- Artifact upload/verification, manifests, signed URLs, compatibility resolver, rollout cohorts, rollback.
- Android end-to-end checksum/temp-write/atomic-swap failure testing with the mobile team.

### Phase 4 — hardening and launch (2–3 weeks)

- Load, security, RLS, disaster-recovery, old-client compatibility, and low-bandwidth testing.
- Operational dashboards, alerts, runbooks, on-call ownership, and launch review.

## 14. Dependencies

- Mobile team: installation identity, region onboarding, delta application, artifact contract, first-launch asset flow, and device benchmark harness.
- Content/agency team: authoritative scheme sources, region ownership, reviewer staffing, turnaround SLAs, and taxonomy approval.
- Tamil-language specialists: colloquial phrase review and rural/code-mixed evaluation design.
- Legal/privacy: consent and retention policy for telemetry or any future audio collection.
- Platform providers: PostgreSQL, Supabase Auth/API/Storage, CI compute, model-training compute, and cloud language services.

## 15. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| A future attempt to reintroduce a second database fragments authorization and consistency | Auth/RLS/API assumptions may fail | Keep Supabase PostgreSQL as the sole MVP system of record; require an architecture decision record, custom data layer, migration plan, and equivalent authorization tests before any change |
| LLM-generated slang is wrong, offensive, or misleading | Bad matches and loss of trust | Human approval, provenance, confidence, rejection feedback, and no auto-publication |
| Sparse rural-accent/code-mixed data | Misleading aggregate accuracy | Early field validation, locked slice tests, targeted collection with consent |
| Student loses accuracy after quantization | Poor scheme matching | Quantization-aware training if needed; compare architectures; hard promotion gates |
| Label/taxonomy changes break old clients | Crashes or incorrect output mapping | Version input/output contracts and label maps; compatibility resolver; old-client tests |
| Delta cursor based only on timestamps misses writes | Stale client data | Monotonic change sequence and opaque cursor |
| Model update is interrupted or corrupted | App loses inference capability | Size/SHA-256 verification, temp write, load test, atomic rename, last-known-good fallback |
| Region rules leak across authorization boundaries | Privacy/policy breach | Server-derived region scope, RLS, negative tests, audit and alerts |
| Telemetry undermines offline/privacy promise | User harm and compliance risk | Opt-in/minimized events, no raw audio by default, coarse region, retention limits |
| Large first-run assets fail on constrained networks | Delayed usable experience | Resume-capable downloads, unmetered default, clear asset state, compact artifacts, retry/backoff |

## 16. Remaining product decisions

The infrastructure topology, generated-content review policy, cursor strategy, compatibility versioning, privacy defaults, and failure-safe OTA mechanism are resolved in this corrected PRD. The following product-specific decisions still require stakeholder input before final estimates:

1. **Client authorization:** Decide whether users authenticate or devices receive installation-scoped anonymous Supabase sessions. In either case, the server assigns authorized region claims; the client cannot self-authorize a region.
2. **Region model:** Define village/block/district/state hierarchy, overlaps, migrations, and whether a device can subscribe to multiple regions.
3. **Model target contract:** Finalize intent taxonomy, ranking behavior, safety-critical classes, tokenizer contract, and maximum artifact size. The contract must retain `no_confident_match` and immutable version identifiers.
4. **ML quality thresholds:** Ratify launch thresholds after the representative locked corpus establishes baselines. Threshold reductions require documented cross-functional approval.
5. **Telemetry launch:** Decide whether minimized telemetry ships in MVP, its consent wording, and exact retention period. Raw query text and audio remain excluded unless a separate privacy review changes the requirement.
6. **Rollout policy:** Define channels, cohort percentages, soak periods, automatic pause thresholds, and approving roles.
7. **Data freshness:** Confirm critical versus standard content-update SLAs and who owns emergency corrections.
8. **Artifact packaging:** Prefer one signed release bundle containing the model, tokenizer/vocabulary, label map, and manifest to prevent mismatch; confirm whether runtime constraints require separate files under one immutable bundle version.
9. **Cloud STT safety net:** If retained, define provider, explicit consent, trigger confidence, cost cap, retention, and privacy controls. It must remain optional and never block the offline path.

## 17. Definition of done

The backend and MLOps scope is production-ready when all acceptance criteria pass; security, privacy, RLS, migration, recovery, and compatibility reviews are signed off; at least one real scheme correction has completed the full publish-to-device flow; at least one candidate model has completed reproducible distillation through staged OTA activation; rollback has been exercised on a representative low-end Android device; and operating dashboards, alerts, ownership, and runbooks are active.
