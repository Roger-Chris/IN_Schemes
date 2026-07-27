# ADR 0001: IN Schemes backend governance baseline

- Status: Proposed; engineering scaffold adopted, product defaults pending
- Date: 2026-07-21
- Source: `BACKEND_ONLY_PRD.md` version 1.0

## Context

The existing IN Schemes repository already contains a Flutter client, Supabase
schema, and public recommendation APIs. The next backend milestones depend on a
repeatable Supabase environment, a reviewable administration API contract, and
explicit answers to the open product decisions in PRD section 16.

## Engineering decisions adopted now

1. Supabase PostgreSQL is the only writable system of record.
2. Database changes are forward-only timestamped migrations. A mitigation note
   is required for destructive or irreversible migrations.
3. The Supabase CLI is pinned as a project dependency and run through npm.
4. Database invariants and RLS boundaries are tested with pgTAP.
5. API endpoints use `/v1`, bearer authentication, a stable error envelope,
   request IDs, and idempotency keys for retryable commands.
6. Privileged database functions use `security definer`, `search_path = ''`,
   fully qualified names, explicit authorization, and explicit execution grants.
7. Dates without a time retain local-date semantics; timestamps use UTC.

## Proposed MVP defaults requiring stakeholder confirmation

These values unblock design but are not product commitments:

| Decision | Proposed default | Consequence if changed |
|---|---|---|
| Organization model | One operating organization initially; schema remains tenant-aware | Minimal migration if a second agency is added |
| Region hierarchy | Generic state/district/block/village tree with stable government codes | Seed/import mapping changes, not core schema |
| Region overlap | A revision may target multiple regions | Required for schemes spanning administrative boundaries |
| Admin experience | Complete administration API; no web UI in initial scope | UI can be added without changing backend contracts |
| Spoken variants | Formal Tamil, colloquial Tamil, and Tanglish | Additional language/script codes remain extensible |
| Delta retention | 90 days | Impacts storage, cursor expiry, and snapshot frequency |
| Audit retention | Seven years, subject to policy/legal review | Impacts partitioning and archival operations |
| Expected launch load | Must be supplied before Sprint 3 load-test design | Prevents credible capacity sign-off today |

## Delivery sequence

1. Identity, roles, regions, taxonomies, and their complete adversarial RLS matrix.
2. Stable schemes and immutable revision content model.
3. Review/publication/withdrawal transactions and audit events.
4. Signed cursor delta sync and bounded snapshots.
5. Idempotent CSV/JSON imports.
6. Storage policies, observability, security hardening, and operational runbooks.

## Review gates before Sprint 1 closes

- Confirm all proposed product defaults above.
- Supply authoritative region codes and representative scheme/source files.
- Approve required scheme fields and beneficiary categories.
- Name the owners for Tamil review, publication, emergency correction, and
  withdrawal.
- Create separate development, staging, and production Supabase projects.
