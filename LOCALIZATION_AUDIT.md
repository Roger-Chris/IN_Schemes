# MSS App — Localization Architecture Audit & Implementation Plan

> **Status:** Phases 1–10 complete (read-only analysis). **No app code has been modified.**
> **Scope:** `frontend/` (Flutter). Backend/agent touched only where they own translation data.
> **Date:** 2026-08-07 · **Catalog release:** `1.33.0-alpha` (969 entities)

---

## 1. Architecture Understanding

### 1.1 Repository shape

| Path | Role |
|---|---|
| `frontend/` | Flutter app (72 Dart files under `lib/`) — the only localization surface |
| `backend/` | Python + Supabase (catalog compilation, publishing, translation jobs) |
| `saarthi-agent/` | LiveKit voice agent (server-side prompts, out of Flutter l10n scope) |

### 1.2 Frontend runtime layers

```
assets/catalog/catalog_bundle.json.gz   (632 KB gz / 9.1 MB raw, 969 entities)
        │
        ▼
MssCatalogBundle  ──► MssEntity (identity / content / localization / search / …)
        │
        ▼
MssSchemeAdapter  ──► Scheme            (English + parallel *Ta twin fields)
        │
        ▼
LocalizedScheme.fromScheme(scheme, lang)  ◄── CentralizedTranslator (fallback)
        │
        ▼
Widgets (scheme_card, scheme_details, search, saved, home)
```

Parallel to that, **runtime/static UI text** flows through four *unrelated* mechanisms plus two anti-patterns (§2.1).

### 1.3 Key components identified

| Concern | Owner |
|---|---|
| Locale source of truth | `AppProvider._selectedLanguage` (`'en'` / `'ta'`), persisted via `SessionCacheService` + `profiles.language` |
| Locale wiring | `main.dart:62` → `MaterialApp.locale: Locale(provider.selectedLanguage)` |
| Generated l10n | `lib/l10n/app_localizations*.dart` from `lib/l10n/app_{en,ta}.arb`, `l10n.yaml` |
| Accessor | `context.l10n` extension — `lib/l10n/l10n.dart` |
| Catalog loader | `services/mss_catalog_bundle.dart`, `services/scheme_catalog_store.dart`, `services/scheme_catalog_sync_service.dart` |
| MSS adapter | `services/mss_scheme_adapter.dart` (673 lines) |
| Scheme localization wrapper | `models/localized_scheme.dart` |
| DB repositories | `services/scheme_repository.dart` (Supabase `profiles`), `providers/app_state_provider.dart` (`notifications`, `promo_alerts`, `startup_profiles`, `questionnaire_sessions`) |
| Adaptive questionnaire | `widgets/smart_assessment_bottom_sheet.dart` (1242 lines) |
| AI Companion | `screens/companion_mode/saarthi_home_screen.dart`, `widgets/voice_assistant_overlay.dart` |
| Auth flow | `screens/login_screen.dart` → `otp_screen.dart` → `navigation_mode_screen.dart` |
| Profile completion | `regular_mode/{basic,location,about_you}_profile_screen.dart`, `profile_setup_screen.dart` |

---

## 2. Current Localization Pipeline

### 2.1 Six coexisting mechanisms

| # | Mechanism | Size | Files using it | Verdict |
|---|---|---|---|---|
| 1 | **`AppLocalizations` (ARB / gen-l10n)** — `context.l10n.x` | 234 keys × 2 locales | 8 files | ✅ **Keep — the target system** |
| 2 | **`ProfileL10n`** — hand-rolled `Map<String,String>` + `t(key, isTa)` | 143 keys | 6 files | ⚠️ Parallel system; 30 exact duplicates of ARB |
| 3 | **`CentralizedTranslator`** — 492-entry EN→TA dictionary + 28 regex sentence patterns | 492 entries | 11 files | ⚠️ Correct for *catalog* text; wrongly used for *UI* text |
| 4 | **Catalog `localization.{en,ta,hi}`** — per-record translations in the bundle | see §3.1 | via adapter | ✅ **Keep — the target for content** |
| 5 | **Inline `isTa ? '…' : '…'` ternaries** | ~40 sites | 8 files | ❌ Anti-pattern |
| 6 | **Raw hardcoded English** | 187 literals | 28 files | ❌ Anti-pattern |

### 2.2 Measured duplication (the core defect)

| Finding | Count | Evidence |
|---|---|---|
| ARB keys that exist with Tamil but are **never referenced**, while the same English is hardcoded elsewhere | **24** | `navHome`/`navSearch`/`navProfile` (TA: முகப்பு/தேடல்/சுயவிவரம்) exist but `main.dart:295–324` hardcodes `'Home'`,`'Search'`,`'Discover'`,`'Saved'`,`'Profile'` |
| `ProfileL10n` entries whose **English is byte-identical to an ARB value** | **30** | `ProfileL10n['male']` == `arb['genderMale']`, `['cancel']` == `arb['dialogCancel']`, `['obc']` == `arb['commObc']`, … |
| `CentralizedTranslator` dictionary keys that duplicate an ARB value | **42** | `'cancel'`, `'done'`, `'required documents'`, `'eligibility criteria'`, `'highly relevant'`, `'scheme at a glance'`, … |
| `browseByCategories` / `browseByMinistry` / `browseByState` | in ARB with Tamil, **unused** | `categories_screen.dart:550,558,566` hardcodes `'By Category'`, `'By Ministry'`, `'By State'` |

**Same Tamil string is therefore stored in up to three places.** That is the single highest-value thing to fix, and it can be fixed *without translating anything new*.

### 2.3 What the pipeline gets right (preserve these)

- `LocalizedScheme.fromScheme` implements the correct 3-tier priority: **catalog Tamil → translator fallback → protected passthrough**.
- `CentralizedTranslator.isProtectedText` already guards URLs, emails, phone numbers and `^[A-Z0-9_]{3,20}$` codes.
- **`smart_assessment_bottom_sheet.dart:190` stores the *raw English* option** (`_answers[id] = rawOption`) while displaying the localized one via `LocalizedQuestionNode.rawOptionFor()`. Downstream matching (`ans.contains('Female')`, `ans.contains('Idea')`, lines 226–277) therefore still works in Tamil. **Any refactor must preserve this raw/display split.**
- `main.dart` correctly re-renders on locale change via `Consumer<AppProvider>`.

---

## 3. Where Translations Currently Come From

### 3.1 Catalog JSON (`assets/catalog/catalog_bundle.json.gz`)

Key pattern: `record.localization.{en|ta|hi}.{name, shortName, summary, description, objective, eligibilityText, benefitsText, applicationText}`. `hi` exists structurally but every value is `null`.

**Measured Tamil coverage:**

| Catalog | Records | Tamil coverage |
|---|---|---|
| `scheme_catalog` | 217 | `name` 217/217 · `eligibilityText` 217/217 · `benefitsText` 214/217 · `description` 200 · `summary` 200 · `objective` 158 · `applicationText` 146 · `shortName` 68 |
| `authority_catalog` | 124 | `name` 124/124 ✅ |
| `common_catalog` | 344 | `label` 340/344 · `description` 10/344 |
| `finance_catalog` | 115 | **0** ❌ |
| `institution_catalog` | 83 | **0** ❌ |
| `knowledge_catalog` | 28 | **0** ❌ |
| `csr_catalog` | 16 | **0** ❌ |
| `treds_catalog` | 16 | **0** ❌ |
| `export_catalog` | 13 | **0** ❌ |
| `tax_catalog` | 13 | **0** ❌ |

→ **284 records across 7 catalogs have no Tamil at all** and fall back to `CentralizedTranslator`'s word-substitution, which produces degraded (not natural) Tamil.

### 3.2 Database (Supabase)

Per `DATABASE_ARCHITECTURE.md`:

| Table | Localization status | Correct home |
|---|---|---|
| `catalog.scheme` | `name_en` / `name_ta` mirrored columns + `record_json` | **Catalog** (DB is the publishing source; app reads the compiled bundle) |
| `catalog.authority`, `catalog.institution` | `name_en` / `name_ta` | **Catalog** |
| `catalog.ai_metadata` | `summary_en` / `summary_ta` | **Catalog** |
| `catalog.finance/tax/export/csr/treds` | numeric + `TEXT[]`, **no `_ta`** | **Catalog** — needs schema extension (§7) |
| `public.profiles` | user data + `language` preference | **Never translate** (user-generated) |
| `public.notifications`, `public.promo_alerts` | server-authored copy, **no `_ta` column** | **Database** — needs `title_ta`/`body_ta` |
| `public.saved_schemes`, `recent_schemes`, `ai_*` | IDs / user content | **Never translate** |
| `admin.translation_jobs`, `admin.translation_memory` | **exists server-side, unused by the app** | Should become the authoring source for §5 |

**Critical:** `notifications` and `promo_alerts` are rendered directly to the user with no Tamil path. `notifications_screen.dart` routes them through `CentralizedTranslator`, which is a machine-substitution fallback on *server-authored prose* — the wrong tool.

### 3.3 Static assets

`assets/` contains **only images and the catalog bundle** — no `translations/`, no extra JSON. Confirmed: nothing reusable is hiding there. State/emblem PNGs are keyed by English state name (`assets/images/States assets/…`), which is a filename key, not display text — correctly untranslated.

---

## 4. Classification of Every User-Facing String

| Cat | Description | Correct source | Current reality |
|---|---|---|---|
| **A** | Scheme title, overview, benefits, eligibility, docs, process | Catalog `localization.ta` | ✅ Working via `LocalizedScheme`; gaps where catalog `ta` is null |
| **B** | Ministry / department / authority / institution names | Catalog `authority_catalog` + `institution_catalog` | ⚠️ Authority 100%; **institution 0%** → falls to translator |
| **C** | Runtime UI ("Profile Saved", "Retry", "Loading…", snackbars) | ARB | ❌ Split across ARB + ProfileL10n + ternaries + hardcoded |
| **D** | Static app text (Login, OTP, Profile Completion, section labels) | ARB | ❌ Mostly `ProfileL10n` + hardcoded |
| **E** | Adaptive questionnaire | ARB (chrome) + `QuestionNode.*Ta` (content) | ⚠️ Structure is correct; `Step X of Y`/`Back`/`Skip to Results` are inline ternaries (`smart_assessment_bottom_sheet.dart:341–345`) |
| **F** | AI Companion (greetings, prompts, states, placeholders) | ARB | ❌ **Entirely hardcoded English**, plus romanized-Tamil literals |

### 4.1 Category F detail (worst-affected module)

`saarthi_home_screen.dart` contains hardcoded English for every conversational surface: `'Ready to help'`, `'Listening to you'`, `'Checking your details'`, `'Speaking now'`, `'Connection needs attention'`, `'Voice connected'`/`'Voice offline'`, `'Ask Saarthi anything...'`, `'Recommended for you'`, `'View eligibility'`, `'Review match'`, `'Official source checked'`, `'Verify with the department'`, `'Tell me what support you need. I will ask one detail at a time.'`, and the composed greeting `'Good Morning, '` + `'$userName! 👋'` + `', your AI companion for\nMSME success.'`.

Lines 841–858 hold **romanized Tamil (Tanglish)** eligibility prompts — `'Unga vayasu enna?'`, `'Neenga entha state-la irukkeenga?'`. These are neither English nor Tamil script and belong in the ARB as proper `ta` values with English `en` counterparts. **Flagged as a product decision, not a mechanical fix** (§9).

---

## 5. Missing Translations, Grouped by Module

Sweep method: regex over all 72 `lib/**.dart` for `Text(…)`, `RichText`, `TextSpan`, `hintText`, `labelText`, `errorText`, `helperText`, `tooltip`, `semanticLabel`, `title`, `subtitle`, `label`, `message` bound to a literal starting with a capital letter, excluding asset paths, URLs, and identifier-shaped keys.

**Total: 187 hardcoded user-facing literals across 28 files.**

| Module | File | Count | Nature |
|---|---|---|---|
| **Discover / Categories** | `regular_mode/categories_screen.dart` | 47 | 8 category titles, 3 section headers, 7 tool titles, 12 form `helperText`, calculator result labels |
| **Search taxonomy** | `services/intelligent_scheme_search.dart` | 18 | 18 category `label`s (Agriculture, Education, Women, Loans, Housing, Fisheries, …) |
| **Filters** | `widgets/filter_panel.dart` | 16 | Every filter group label (State, District, Ministry, Category, Gender, Community, …) |
| **Profile completion** | `regular_mode/about_you_profile_screen.dart` | 12 | 6 persona titles + subtitles — **all 12 already exist in `ProfileL10n`** |
| **Profile setup** | `regular_mode/profile_setup_screen.dart` | 11 | 9 employment options — **all exist in `ProfileL10n`/ARB** |
| **Notifications** | `screens/notifications_screen.dart` | 9 | 4 preference titles + subtitles, 2 tooltips |
| **AI Companion** | `companion_mode/saarthi_home_screen.dart` | 8 (+~25 in bodies) | see §4.1 |
| **AI Companion onboarding** | `companion_mode/saarthi_welcome_screen.dart` | 8 | 4 feature titles, language card labels, preview tooltip |
| **Mode selection** | `screens/navigation_mode_screen.dart` | 7 | Full screen — zero l10n import |
| **Help & Support** | `regular_mode/help_support_screen.dart` | 7 | Form labels + hints |
| **Voice overlay** | `widgets/voice_assistant_overlay.dart` | 6 | Tooltips + accessibility labels |
| **Basic profile** | `regular_mode/basic_profile_screen.dart` | 5 | Field labels — **all exist in `ProfileL10n`** |
| **Location profile** | `regular_mode/location_profile_screen.dart` | 4 | Address `hintText` examples |
| **Settings** | `regular_mode/settings_screen.dart` | 4 | Navigation-mode titles + subtitles |
| **MSME modules** | `regular_mode/msme_module_details_screen.dart` | 3 | Section titles + search hint |
| **Search results** | `regular_mode/search_results_screen.dart` | 3 (+9) | Hint, sort options, empty/loading states |
| **Eligibility results** | `regular_mode/eligibility_results_screen.dart` | 2 (+8) | Whole screen unlocalized |
| **Discover results** | `regular_mode/discover_results_screen.dart` | 1 (+6) | Sort/filter option arrays |
| **Splash** | `screens/splash_screen.dart` | — (2) | `'Loading...'`, `'Please wait while we prepare\nsomething amazing for you'` |
| **Shell** | `main.dart` | 1 (+5) | 5 bottom-nav labels — **3 already in ARB unused** |
| **Service-layer user messages** | `edge_model_pack`, `edge_slm_understanding_engine`, `livekit_voice_agent_controller`, `voice_agent_controller`, `voice_recognition_controller`, `scheme_catalog_sync_service` | 9 | Error/status strings surfaced in UI from the service layer |

### 5.1 Sixteen files with **zero** localization import

`companion_voice_agent_launcher` · `navigation_mode_screen` · `basic_profile_screen` · `discover_results_screen` · `eligibility_results_screen` · `location_profile_screen` · `msme_module_details_screen` · `search_results_screen` · `splash_screen` · `category_card` · `custom_button` · `custom_confirm_dialog` · `filter_bottom_sheet` · `filter_panel` · `floating_logo` · `gradient_scaffold`

(The last three are layout-only and legitimately need none.)

### 5.2 How much is *actually* new translation work

| Bucket | Strings | Action |
|---|---|---|
| Already translated, wrong plumbing | **~96** | **Rewire only — zero new Tamil** |
| Genuinely missing UI Tamil | **~91** | New ARB entries, human-authored Tamil |
| Missing catalog Tamil | **284 records** | Backend `admin.translation_jobs` |
| Missing DB Tamil | `notifications`, `promo_alerts` | Schema + content |

---

## 6. Protected Text — Phase 9 Confirmation

`CentralizedTranslator.isProtectedText` guards URLs, emails, phone numbers, and `^[A-Z0-9_]{3,20}$` codes. Cross-checked against every Phase 8 hit:

✅ **Correctly protected:** scheme codes (`TN001`, `SCH000001`, `AUTH000026`), entity IDs, `officialWebsite`/`applicationUrl`/`guidelinesUrl`/`sourceUrl` (pass-through getters on `LocalizedScheme`, never routed through the translator), `helplineContactsMap` (pass-through), `lastUpdated` (pass-through), acronyms held identical in both ARB locales (`SC`, `ST`, `OBC`, `EWS`, `TReDS`), and explicit acronym preservation in the dictionary (`MSME`, `SIDBI`, `KVIC`, `DGFT`, `GST`, `DBT`, `KYC`, `ESDP`, `EDII-TN`, `TANGEDCO`).

⚠️ **Three protection gaps found:**

1. **`_phoneRegex` is dangerously broad** — `(\+91[\s-]?)?(\(?\d{3,5}\)?[\s-]?)?\d{6,8}` matches any bare 6–8 digit run. It is currently saved by a second guard (`^\+?[0-9\s-]{7,15}$` on the *whole* trimmed string, line 48), so behaviour is correct today — but the regex is a latent hazard if that guard is ever relaxed.
2. **Currency amounts survive by accident, not by rule.** `'₹5 lakh'` → the `_termMap` entry `'lakh' → 'இலட்சம்'` fires and yields `'₹5 இலட்சம்'`. That is desirable, but there is **no `₹`/amount protection rule** — catalog record `SCH000001` already shows the inconsistency: Tamil `benefitsText` ends `"அதிகபட்சம் ₹5 lakh வரை"` (English "lakh" left in Tamil prose) while the translator would have produced `₹5 இலட்சம்`. **Same value, two renderings.**
3. **Dates and numbers have no protection rule at all** — they pass through untouched only because no dictionary key matches them.

---

## 7. Recommended Implementation Order (lowest risk first)

> Each stage is independently shippable and independently revertable.

### Stage 0 — Guardrails (no behaviour change)
1. Add a CI lint that fails on new hardcoded literals inside `Text(` / `hintText:` / `labelText:` in `lib/screens` and `lib/widgets`.
2. Add `lib/utils/responsive.dart` — an adaptive-sizing helper (§8/Phase 11). Nothing consumes it yet.

**Risk: none.**

### Stage 1 — Consume the 24 orphaned ARB keys ★ start here
Rewire only where the ARB key **already exists with Tamil**: `main.dart` nav labels → `navHome`/`navSearch`/`navProfile`; `categories_screen.dart:550,558,566` → `browseByCategories`/`browseByMinistry`/`browseByState`; plus `viewAll`, `dialogCancel`, `smartAssessment`, `featuredCollections`, `manageSaved`, `applicationsClosingSoon`.

**Risk: very low** — pure substitution, no new strings, no logic. Delivers visible Tamil immediately.

### Stage 2 — Collapse `ProfileL10n`'s 30 duplicates into ARB
Keep `ProfileL10n.t()` as a **thin shim** initially so the 6 call sites don't all change at once; point the 30 duplicated keys at `AppLocalizations`. Migrate the remaining 113 keys into ARB in a second pass, then delete the shim.

**Risk: low** — `ProfileL10n.t` falls back `_ta[key] ?? _en[key] ?? key`, so a missed key degrades to English, never to a crash.

### Stage 3 — Fix the ~96 "already translated, wrong plumbing" strings
`about_you_profile_screen` (12), `profile_setup_screen` (11), `basic_profile_screen` (5), and the `CentralizedTranslator` UI-text call sites in `notifications_screen`, `help_support_screen`, `login_screen`.

**Risk: low.** ⚠️ **Do not touch `smart_assessment_bottom_sheet.dart:190`** — the raw/display split is load-bearing.

### Stage 4 — Localize the 16 zero-coverage screens
Splash → Navigation Mode → Basic/Location Profile → Search Results → Discover Results → Eligibility Results → MSME Modules → `filter_panel` → `intelligent_scheme_search` category labels.

**Risk: medium** — `search_results_screen.dart:131–135,184,547` and `discover_results_screen.dart:348–366` compare against **English literals** (`'Central Government'`, `'Relevance'`, `'Sponsoring Body'`). Apply the `rawOption` pattern: localize the label, key the logic on a stable English/enum value.

### Stage 5 — AI Companion (Category F)
Largest and most sensitive. Includes the Tanglish decision (§9).

**Risk: medium-high** — voice prompts feed TTS and the LiveKit agent; changing them changes what the user *hears*.

### Stage 6 — Backfill catalog Tamil (backend)
284 records across `finance` / `institution` / `knowledge` / `csr` / `treds` / `export` / `tax` via `admin.translation_jobs` + `admin.translation_memory`. Republish the bundle. **No app change required** — `LocalizedScheme` picks it up automatically.

**Risk: low to the app, high value.**

### Stage 7 — DB Tamil columns
Add `title_ta` / `body_ta` to `notifications` and `promo_alerts`; read them in `app_state_provider`; drop the `CentralizedTranslator` call from `notifications_screen`.

**Risk: low** — additive schema.

---

## 8. Architectural Improvements (non-breaking)

1. **One accessor, one source.** Target end state: `context.l10n` for Categories C/D/E-chrome/F; catalog `localization.ta` for A/B; `CentralizedTranslator` demoted to *catalog-content fallback only* and never called from a widget.
2. **Keep `LocalizedScheme` as the sole content boundary.** Extend the same wrapper pattern to `MssEntity` types that lack one (finance, institution, knowledge) instead of translating inside widgets.
3. **Promote `admin.translation_memory` to the authoring source.** Catalog Tamil, DB Tamil, and new ARB Tamil should all be authored once there and emitted downstream — this is what structurally prevents the triple-storage problem from recurring.
4. **Add explicit protection rules** for `₹`-amounts, dates, and numerals in `CentralizedTranslator`, and normalize the `₹5 lakh` / `₹5 இலட்சம்` inconsistency (§6.2). Tighten `_phoneRegex`.
5. **Remove the forced `TextScaler.linear(1.20)`** in `main.dart:69`. It overrides the OS accessibility setting *and* inflates every string by 20%, which is a direct multiplier on every overflow in §Phase 11. Replace with `TextScaler.linear(mediaQuery.textScaler.scale(1.0).clamp(1.0, 1.3))` or similar so user preference is respected and bounded. **This is a prerequisite for durable overflow fixes.**
6. **`hi` locale is pre-wired but empty** — `localization.hi` exists on every catalog record with `null` values. Adding Hindi later is a data task, not an architecture task, *provided* Stages 1–5 land first. `AppLocalizations.supportedLocales` currently lists only `en`/`ta`.

---

## 9. Ambiguities — Flagged, Not Guessed

| # | Module | Ambiguity | Reasoning |
|---|---|---|---|
| 1 | AI Companion | `saarthi_home_screen.dart:841–858` uses **romanized Tamil (Tanglish)** for eligibility prompts in *both* locales. Is this deliberate (spoken-voice register / accessibility for users who don't read Tamil script) or leftover scaffolding? | Determines whether these become `ta` ARB values in Tamil script, a third "Tanglish" register, or voice-only strings excluded from the visual l10n system. **Cannot be inferred from code.** |
| 2 | Catalog | `SCH000001` Tamil `benefitsText` renders `"₹5 lakh"` while `CentralizedTranslator` renders `"₹5 இலட்சம்"`. Which is canonical? | Catalog authors may have intentionally kept English magnitude words. Needs a documented convention before backfilling 284 records. |
| 3 | Notifications | Server-authored `notifications`/`promo_alerts` copy currently goes through the machine translator. Should Tamil be authored server-side (new columns) or should the app stop translating and show English? | Depends on who authors notification copy operationally. Recommendation: server-side columns (§7 Stage 7). |
| 4 | Search/Discover | Sort & filter option arrays are English literals used as both label *and* comparison key. | Recommendation is the `rawOption` split (proven in the questionnaire), but if these values are persisted anywhere the migration needs care. Not verified as persisted. |
| 5 | Scope of catalog backfill | 7 catalogs have 0% Tamil. Are `csr`/`treds`/`export`/`tax` user-facing in the Tamil journey at all, or English-only power-user surfaces? | Changes whether Stage 6 is 284 records or ~226. |
| 6 | Delivery | The prompt ends Phase 11 with **"use caveman"**. | Read as a style instruction it would make an architecture audit unusable as a working document; read as a stray token it should be ignored. Delivered in standard technical prose — **please confirm if a terse register was intended.** |

---

## 10. Risk Assessment — Where Localization Changes Could Regress Behaviour

| # | Risk | Severity | Location | Mitigation |
|---|---|---|---|---|
| R1 | **Localized text used as a logic key.** `ans.contains('Female')`, `ans.contains('Idea')`, `stateName == 'Tamil Nadu'` | 🔴 **High** | `smart_assessment_bottom_sheet.dart:226–277, 1184–1217` | Currently **safe** (raw English stored at `:190`). Any refactor must preserve the raw/display split. Add a regression test. |
| R2 | Same pattern, **not** currently protected | 🔴 **High** | `search_results_screen.dart:131,135,184,547`; `discover_results_screen.dart:348–366` | Introduce the `rawOption` split *before* localizing these labels, not after |
| R3 | State asset lookup keyed by English name | 🟠 Medium | `smart_assessment_bottom_sheet.dart:_getStateMapAsset`, `assets/images/States assets/` | Never localize the lookup key; localize only the display label |
| R4 | Longer Tamil breaks fixed layouts | 🟠 Medium | 118 sites (see Phase 11) | Phase 11 — do adaptive sizing **before/with** new Tamil, not after |
| R5 | `ProfileL10n` deletion drops a key silently | 🟡 Low | 6 files | Shim-then-migrate (Stage 2); fallback chain already degrades to English |
| R6 | Removing `CentralizedTranslator` calls from widgets loses fallback for catalog gaps | 🟠 Medium | `notifications_screen`, `categories_screen`, `login_screen` | Only remove where the string is Category C/D; keep the translator on Category A/B until Stage 6 backfill lands |
| R7 | Catalog checksum/version coupling | 🟡 Low | `release.json` `bundleSha256`, `scheme_catalog_sync_service.dart:135` | Backfilling Tamil changes the bundle hash → must go through the normal release pipeline, not a hand-edited asset |
| R8 | Voice/TTS prompt changes alter spoken output | 🟠 Medium | `saarthi_home_screen`, `speech_output_controller`, `livekit_voice_agent_controller` | Stage 5 last; validate TTS pronunciation of new Tamil |
| R9 | `TextScaler.linear(1.20)` interacts with every layout fix | 🟠 Medium | `main.dart:69` | Fix in Stage 0 so Phase 11 measurements are meaningful |
| R10 | 30 duplicated strings could drift apart mid-migration | 🟡 Low | ARB ↔ `ProfileL10n` | Do Stage 2 as one atomic change per key, not per file |

---

# Phase 11 — Overflow Findings (Deliverable Item 1)

> **No code written.** This is the pre-fix inventory. Scan method: balanced-paren AST-lite walk of every `Row(…)` subtree containing a `Text`/`RichText`/`SelectableText` with no `Expanded`/`Flexible`/`FittedBox`/`Wrap`/`Spacer` escape hatch, plus every `SizedBox`/`Container` with a literal `width:` wrapping a `Text`.

**118 overflow-risk sites across 31 files.** App-wide, only 2 files use `FittedBox` at all, and `TextOverflow.ellipsis` appears in 17 of 72 files. There is **no responsive-sizing helper anywhere** — `lib/utils/constants.dart` (80 lines) is colors and gradients only.

### 11.1 OTP screen — root causes (the reported bug)

| Line | Widget | Cause | Verdict |
|---|---|---|---|
| **194–222** | `Row(mainAxisAlignment: center)` → `Text(l('enter_otp_sent'))` + phone `Text` + edit `Icon` | **Primary overflow.** Neither `Text` is `Flexible`. EN `"Enter the 6-digit OTP sent to"` (29 chars) vs **TA `"இந்த எண்ணிற்கு அனுப்பப்பட்ட 6 இலக்க OTP ஐ உள்ளிடவும்:"` (52 chars, ~1.8×)**, then `+91 XXXXX XXXXX` (15 ch) + 13px icon + 4px gap on one unwrappable line at `fontSize: 10.5` × **global 1.20 textScaler** | 🔴 **Confirmed overflow** — long localized string in a fixed single-line `Row` |
| **255–301** | `Row(spaceBetween)` → 6 × `SizedBox(width: 42, height: 52)` | Fixed 252 px of boxes. Available = `screenWidth − 40` (page padding) `− 40` (card padding) = `w − 80`. At 360 dp → 280 px (fits, 28 px total gap). **At 320 dp → 240 px < 252 px → overflow.** Independent of locale | 🟠 **Confirmed on ≤340 dp** — fixed box size, not responsive |
| **317–345** | `Row(center)` → `Icon` + `RichText` timer | `RichText` not `Flexible`. TA `"OTP காலாவதியாகும் நேரம் "` ≈ 1.7× EN `"OTP expires in "` at `fontSize: 11` × 1.20 | 🟠 **At-risk** — narrow screens / raised text scale |
| **402–420** | Button `Row(center)` → `Text(l('verify_otp'))` + gap + `Icon` | Unguarded. TA `"OTP சரிபார்க்கவும்"` at 15 pt bold × 1.20 | 🟡 **Latent** — fits today, no headroom |
| 428–446 | Resend `RichText` | `softWrap` default true → wraps | ✅ Safe |
| 450–466 | OR divider | `Expanded` dividers | ✅ Safe |
| 480–504 | Change-number row | Already `Expanded` | ✅ Safe |
| 333, 366–368, 456, 490 | 4 inline `isTa ? … : …` ternaries | Category C/D text bypassing both ARB and `ProfileL10n` | ❌ l10n defect (Stage 3), not layout |

**Amplifier:** `main.dart:69` forces `TextScaler.linear(1.20)` globally. Every measurement above is 20% larger than the code's nominal font sizes suggest, and the OTP screen's smallest text is `10.5 pt` → `12.6 pt` effective.

### 11.2 App-wide, ranked

| File | Sites | Dominant cause |
|---|---|---|
| `regular_mode/categories_screen.dart` | 22 | 4 fixed-width `Container`s (88/134/134/134/142 px) around chip text + 17 calculator result `Row`s (`Text(label)` + `Text('₹ …')`, both unguarded, values grow with magnitude) |
| `regular_mode/search_screen.dart` | 8 | Unguarded filter/result `Row`s |
| `screens/notifications_screen.dart` | 7 | Notification title + timestamp `Row`s — text is **server-authored, unbounded length** |
| `companion_mode/saarthi_home_screen.dart` | 7 | Status/label `Row`s; text is **AI-generated, unbounded** |
| `regular_mode/home_screen.dart` | 7 | 3 fixed-width `Text` boxes (56/88/150 px) + 4 `Row`s |
| `regular_mode/msme_module_details_screen.dart` | 7 | Section header `Row`s |
| `regular_mode/scheme_details_screen.dart` | 6 | Catalog-string `Row`s + `width: 24` — **worst-case: full catalog Tamil prose** |
| `screens/login_screen.dart` | 4 | `ProfileL10n` text in unguarded `Row`s |
| `companion_mode/saarthi_welcome_screen.dart` | 4 | Feature cards + `width: 44` |
| `regular_mode/eligibility_results_screen.dart` | 4 | `width: 40` + 3 `Row`s |
| `regular_mode/search_results_screen.dart` | 4 | Result-count `Row` |
| **`screens/otp_screen.dart`** | **3** | **see §11.1** |
| `screens/profile_screen.dart` | 3 | Field-label `Row`s |
| `regular_mode/discover_results_screen.dart` | 3 | Filter chips |
| `regular_mode/profile_setup_screen.dart` | 3 | `CentralizedTranslator` output in `Row`s |
| `widgets/smart_assessment_bottom_sheet.dart` | 3 | Question header + step label `Row` |
| 15 more files | 1–2 each | Mixed |

### 11.3 Cause taxonomy

| Cause | Sites | Planned fix (Phase 11 execution) |
|---|---|---|
| `Row` + `Text`, no flex child | ~100 | `Flexible` + `softWrap: true` where wrapping is acceptable; `Expanded` where the sibling is a fixed icon |
| Fixed `width:` around text | ~14 | Replace constant with `LayoutBuilder`/`MediaQuery`-derived fraction via a new `lib/utils/responsive.dart` |
| Fixed-size input boxes (OTP pins) | 1 (×6) | `LayoutBuilder`-computed box width, clamped, so 6 boxes + gaps always fit |
| Must-stay-one-line, variable length (timer, chips, button labels) | ~12 | `FittedBox(fit: BoxFit.scaleDown)` |
| Global text-scale inflation | 1 root cause | Remove/bound the forced `1.20` scaler |

**Fix policy (per the brief):** wrap / shrink / scroll — never silent truncation. `TextOverflow.ellipsis` only where the full value is reachable elsewhere (e.g. a card title whose detail screen shows it in full).

---

## Awaiting Review

Phases 1–10 are complete and Phase 11's inventory is done. **No application code has been modified.**

Blocking on your call for: **§9 items 1, 2, 5 and 6**, and confirmation of the Stage order in §7. On approval I'll execute Stage 0 + Phase 11 (layout/sizing only, zero business-logic change), starting with the OTP screen.
