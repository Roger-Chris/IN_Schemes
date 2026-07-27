# IN Schemes backend

Supabase backend, administration contracts, and Tamil voice research for the
IN Schemes Flutter application. The existing citizen-facing scheme,
recommendation, and search schema remains intact; the additive administration
foundation introduces tenant-aware staff roles, region assignments,
taxonomies, and append-only audit storage.

## Layout

```text
backend/
├── docs/                    Product requirements, ADRs, and API notes
├── openapi/openapi.yaml     Draft `/v1` administration and sync contract
├── supabase/
│   ├── functions/           recommend, schemes-api, and search Edge Functions
│   ├── migrations/          Forward-only database migrations
│   ├── seed/                Scheme data and organization fixtures
│   └── tests/database/      pgTAP schema and RLS tests
├── voice/                   Offline Tamil ASR benchmark lab
├── package.json             Pinned Supabase and OpenAPI tooling
└── README.md
```

## Local database

Requirements: Node.js 20.19.x or 22.12+ and Docker Desktop using Linux
containers.
Run commands from `backend/`:

```powershell
npm ci
npm run supabase:start
npm run db:validate
npm run openapi:lint
```

Stop the local services without deleting their data:

```powershell
npm run supabase:stop
```

To deploy after linking the intended Supabase project:

```powershell
npx supabase db push
npx supabase functions deploy recommend
npx supabase functions deploy schemes-api
npx supabase functions deploy search
```

## Administration foundation

The `20260727000100_admin_foundation.sql` migration builds on the existing
`public.users` identity table. Staff access is represented by protected
organization memberships, roles, and recursive region assignments. Anonymous
access is revoked only for these administration tables so the Flutter app's
public scheme reads continue to work.

The organization seed currently contains synthetic Tamil Nadu fixtures. It is
safe for local development and must be replaced with authoritative codes before
production use.

## Tamil voice lab

The voice package compares Whisper and AI4Bharat Tamil ASR options and includes
deterministic scheme-vocabulary tests. It is research tooling, not a production
service. See [`voice/README.md`](voice/README.md) for setup, benchmark results,
and model limitations.

## Product status

The administration and offline-sync endpoints in `openapi/openapi.yaml` are a
draft contract; their Edge Function implementations are future milestones. See
`docs/decisions/0001-backend-governance-baseline.md` for adopted engineering
decisions and the product defaults that still require stakeholder approval.
