# AI Companion Mode — Localization String Inventory

Scope: `lib/screens/companion_mode/saarthi_home_screen.dart`, `lib/screens/companion_mode/saarthi_welcome_screen.dart`,
`lib/screens/companion_mode/companion_voice_agent_launcher.dart`, `lib/widgets/voice_assistant_overlay.dart`
(shared by both `VoiceAgentSurface.regular` and `VoiceAgentSurface.companion`, and explicitly in scope for this task).

Sweep method: manual read of all four files plus a regex grep pass (`Text(`, `hintText:`, `tooltip:`, `semanticLabel:`,
`label:`, string literals bound to `SnackBar`/dialog titles, and interpolated literals) cross-checked against
`lib/l10n/app_en.arb` / `app_ta.arb`, per the audit's Phase 8 methodology.

**Note on concurrency:** a separate workstream is concurrently landing Phase 11 (overflow/layout) fixes and new
filter/label ARB keys across the app, including these same four files. This inventory reflects the file contents
*after* those concurrent layout-only changes (re-read immediately before this inventory was finalized). No content
strings were changed by that workstream in the files below — only `Flexible`/`FitOneLine`/`adaptiveSize` wrapping.

Legend:
- **A** — Already has a Tamil-equivalent ARB key; wired in Part 2.
- **B** — Genuinely new; proposed in `companion_mode_new_arb_keys_proposal.json`.
- **C** — Excluded (Tanglish protected range, proper noun/brand, dynamic/computed value, or already correctly routed).

---

## 1. `lib/screens/companion_mode/saarthi_home_screen.dart`

| Line(s) | String / description | Category | ARB key / proposed key | Notes |
|---|---|---|---|---|
| 230 | `'Voice service is unavailable. Tap retry.'` | B | `companionVoiceUnavailableRetry` | Cloud connect failure, no controller |
| 263 | `'LiveKit did not enter cloud mode.'` | C | — | Never shown to user; consumed only as fallback `Object` message inside `_cloudErrorMessage`'s substring matching, not rendered directly |
| 286 | `'Please sign in again, then retry voice.'` | B | `companionSignInRetryVoice` | |
| 291 | `'Check your internet, then retry voice.'` | B | `companionCheckInternetRetryVoice` | |
| 293 | `'Voice service could not connect. Tap retry.'` | B | `companionVoiceConnectFailedRetry` | |
| 615 | `'An error occurred. Please try again.'` | B | `companionGenericErrorRetry` | Fallback assistant message |
| 842-859 | Tanglish switch (`'Unga vayasu enna?'` etc.) | **C — PROTECTED** | — | Lines 841-858 (0-indexed content matches the flagged 841-858 range in the original task); reviewed intentional Tanglish, **not modified** |
| 878 | `'Connection needs attention'` | B | `companionConnectionNeedsAttention` | `_getStatusLabel()` |
| 879 / 1209 | `'Connecting'` | B | `companionConnectingShort` | Appears twice, same literal |
| 882 / 2185 | `'Listening to you'` | B | `companionListeningToYou` | Appears twice, same literal |
| 884 | `'Checking your details'` | B | `companionCheckingYourDetails` | |
| 886 | `'Speaking now'` | B | `companionSpeakingNow` | |
| 888 | `'Ready to help'` | B | `companionReadyToHelp` | Default status label |
| 903 | `'Praveen'` | C | — | Default placeholder username fallback, not translatable UI copy |
| 975 | `provider.selectedLanguage == 'ta' ? 'தமிழ்' : 'English'` | C | — | Self-referential language name (shows the language's own name in its own script), same convention used in `voice_assistant_overlay.dart` `_languageBadgeLabel` and the welcome screen's language cards |
| 1154 | `'MSS Saarthi'` | C | — | Brand/product name, kept identical across locales elsewhere in the app |
| 1207 / 1210 | `'Voice connected'` / `'Voice offline'` | B | `companionVoiceConnected` / `companionVoiceOffline` | |
| 1285 | `'Good Morning, '` (TextSpan) | **A** | `goodMorning` (`"Good Morning,"`) | **Wired.** Code now reads `'${context.l10n.goodMorning} '` |
| 1307 | `'Saarthi'` (TextSpan) | C | — | Brand name |
| 1305 / 1313 | `"I'm "` / `', your AI companion for\nMSME success.'` | B | `companionIntroPrefix` / `companionIntroSuffix` | Split to mirror the existing two `TextSpan`s |
| 1349 | `'Tell me what support you need. I will ask one detail at a time.'` | B | `companionEmptyStateHint` | |
| 1381 | `CentralizedTranslator.instance.translate('Latest')` | B | `companionScrollToLatest` | Anti-pattern call (mechanism 3); no ARB value equals `"Latest"` (closest is `latestUpdates` = "Latest Updates", not exact) |
| 1536 | `'Speaking'` | B | `companionSpeakingBadge` | Waveform label on assistant bubble |
| 1574 | `'Recommended for you'` | **A** (case-normalized) | `recommendedForYou` (`"Recommended For You"`) | **Wired.** Confirmed via grep that `home_screen.dart:1264` uses this exact key for the same "recommended schemes" heading concept; only the capitalisation of "for you" → "For You" changes on screen |
| 1587 | `'Ranked from the details you shared. Final eligibility is confirmed by the department.'` | B | `companionRankedResultsCaption` | |
| 1734 | `'Review match'` | B | `companionReviewMatch` | |
| 1735 | `'$confidence% match'` | C | — | Dynamic numeric value |
| 1775 | `'Official source checked'` | B | `companionOfficialSourceChecked` | |
| 1776 | `'Official source checked · ${...} confidence'` | B | `companionOfficialSourceCheckedConfidence` (`"Official source checked · {confidence} confidence"`) | Placeholder-based; capitalisation of `sourceConfidence` stays in Dart code |
| 1777 | `'Verify with the department'` | B | `companionVerifyWithDepartment` | |
| 1788 | `'View eligibility'` | B | `companionViewEligibility` | Distinct from `tabEligibility` ("Eligibility") — this is a CTA phrase |
| 1416 | `'You  $timeStr'` | B | `companionYouTimestampLabel` (`"You  {time}"`) | Sender label, double space is intentional (existing layout spacing) |
| 1487 | `'MSS Saarthi  $timeStr'` | B | `companionAiTimestampLabel` (`"MSS Saarthi  {time}"`) | Same brand name in both `en`/`ta` values (brand not translated) |
| 1885 | `'Ask Saarthi anything...'` | B | `companionAskAnything` | |
| 1894 | `'Tap below and speak your question'` | B | `companionTapToSpeakHint` | |
| 1940 | `'Retry voice'` | B | `companionRetryVoice` | Button label |
| 1961 | `'Secure live voice session'` | B | `companionSecureLiveSession` | |
| 1962 | `'Live voice connection required'` | B | `companionLiveConnectionRequired` | |
| 1981 | `'Start speaking to Saarthi'` | B | `companionStartSpeakingSemantic` | Semantics label |
| 2000 | `'Tap to speak'` | B | `companionTapToSpeak` | |
| 2068 | `'Stop'` | B | `companionStop` | |
| 2070 | `'Interrupt'` | B | `companionInterrupt` | |
| 2071 | `'Speak'` | B | `companionSpeak` | |
| 2089 | `'$primaryLabel voice control'` | C | — | Composed from the three strings above; ARB owner can build with existing/new keys, no separate literal to propose |
| 2126 | `'End'` | B | `companionEnd` | Button label |
| 2181 | `'Voice is not connected'` | B | `companionVoiceNotConnected` | `_getVoiceStatusText()` |
| 2182 | `'Connecting securely'` | B | `companionConnectingSecurely` | |
| 2187 | `'Finding the best match'` | B | `companionFindingBestMatch` | |
| 2189 | `'Saarthi is speaking'` | B | `companionSaarthiIsSpeaking` | |
| 2191 | `'Ready'` | B | `companionReadyShort` | Default fallback |

## 2. `lib/screens/companion_mode/saarthi_welcome_screen.dart`

| Line(s) | String / description | Category | ARB key / proposed key | Notes |
|---|---|---|---|---|
| 46 | `error.toString().replaceFirst(...)` (SnackBar) | C | — | Dynamic/computed error text |
| 119 | `'Meet'` | B | `welcomeMeetPrefix` | |
| 128 | `'Saarthi'` | C | — | Brand name |
| 200 | `"I'm Saarthi, your smart assistant."` | B | `welcomeIntroLine1` | |
| 209 | `"I'll help you discover the right schemes, explain everything simply, and guide you at every step."` | B | `welcomeIntroLine2` | |
| 244 | `'Saarthi can help you with'` | B | `welcomeSectionHeader` | |
| 266 | `'Talk Naturally'` | B | `welcomeFeatureTalkNaturally` | |
| 273 | `'Find Right Schemes'` | B | `welcomeFeatureFindSchemes` | |
| 284 | `'Business Roadmap'` | B | `welcomeFeatureBusinessRoadmap` | |
| 291 | `'Application Support'` | B | `welcomeFeatureApplicationSupport` | Distinct concept from ARB's `csrSupport`/etc. |
| 315 | `"Choose Language"` | B | `welcomeChooseLanguage` | Not an exact match to `languageSetting` ("Language") |
| 328 | `"Choose your preferred language so Saarthi can talk to you better."` | B | `welcomeChooseLanguageSubtitle` | Longer than `subLanguage` ("Choose your preferred language"), not an exact match |
| 337-338 | Language card title/subtitle `'English'` | C | — | Self-referential language name shown in its own script; convention preserved elsewhere |
| 345-346 | Language card title `'தமிழ்'` / subtitle `'Tamil'` | C | — | Same convention |
| 361 | `'Voice'` | B | `welcomeVoiceLabel` | |
| 370 | `CentralizedTranslator.instance.translate('Natural')` | B | `welcomeVoiceNatural` | Anti-pattern call, no ARB equivalent |
| 376 | `CentralizedTranslator.instance.translate('Clear')` | B | `welcomeVoiceClear` | Anti-pattern call, no ARB equivalent |
| 382 | tooltip `'Preview in English and Tamil'` | B | `welcomePreviewVoiceTooltip` | |
| 408 | `"You can change this anytime in settings."` | B | `welcomeChangeAnytimeNote` | |
| 469 | `"Let's Begin"` | B | `welcomeLetsBegin` | |

## 3. `lib/screens/companion_mode/companion_voice_agent_launcher.dart`

| Line(s) | String / description | Category | ARB key / proposed key | Notes |
|---|---|---|---|---|
| 24 | `barrierLabel: 'Talk to Saarthi'` | B | `companionDialogBarrierLabel` | Accessibility-only label announced for the modal barrier |

## 4. `lib/widgets/voice_assistant_overlay.dart`

(Shared by both regular and companion surfaces; fully in scope per task file list. `_isCompanion` notes where a
string is companion-specific vs. shared/regular-only.)

| Line(s) | String / description | Category | ARB key / proposed key | Notes |
|---|---|---|---|---|
| 167 | `'English'` (`_languageBadgeLabel`) | C | — | Self-referential language name |
| 164 / 169 | `'தமிழ்'` / `'Auto'` | C / B | — / `voiceLanguageAuto` | `'தமிழ்'` is self-referential (C); `'Auto'` has no natural-language meaning tied to a specific language, proposed as B |
| 173 | `_presentInTamil ? 'பேசுகிறது...' : 'Speaking...'` | B | `voiceStatusSpeaking` (placeholder-free, both locales literal) | Inline bilingual ternary anti-pattern; Tamil text already authored in code, reused verbatim as the proposed `ta` value |
| 174 | `'கேட்கிறது...' : 'Listening...'` | B | `voiceStatusListening` | Same pattern |
| 176 | `'செயலாக்குகிறது...' : 'Processing...'` | B | `voiceStatusProcessing` | Same pattern |
| 180 | `'புரிந்துகொள்கிறது...' : 'Understanding...'` | B | `voiceStatusUnderstanding` | Same pattern |
| 182 | `'ஒரு கேள்வி' : 'One question'` | B | `voiceStatusOneQuestion` | Same pattern |
| 184 | `'திட்டங்கள் கிடைத்தன' : 'Matches found'` | B | `voiceStatusMatchesFound` | Same pattern |
| 186 | `'மேலும் தகவல் தேவை' : 'Needs more detail'` | B | `voiceStatusNeedsMoreDetail` | Same pattern |
| 188 | `'Finding...'` | B | `voiceStatusFinding` | English-only fallback, no Tamil branch exists yet |
| 189 | `'Found ${_legacyMatches.length}'` | B | `voiceStatusFoundCount` (`"Found {count}"`) | Placeholder |
| 190 | `'தயார்' : 'Ready'` | B | `voiceStatusReadyLegacy` | Same ternary pattern (distinct from `companionReadyShort`/`companionReadyToHelp` in the home screen, kept separate per-surface) |
| 375 | `'Recommended by Saarthi from the verified catalog'` | B | `voiceRecommendedBySaarthiReason` | Synthetic `reasons` entry for cloud scheme results |
| 570 | `'Voice recognition is not available on this device.'` | B | `voiceRecognitionUnavailable` | |
| 603 | `'Voice recognition could not start. Please try again.'` | B | `voiceRecognitionStartFailed` | |
| 679 | `'I could not search right now. Please try again.'` | B | `voiceSearchFailed` | |
| 846-869 | Tanglish switch (duplicate of saarthi_home_screen.dart 841-858) | **C — PROTECTED (by analogy)** | — | Byte-identical to the flagged, reviewed Tanglish block; treated with the same protection even though the task's explicit line-range callout named only `saarthi_home_screen.dart`. **Not modified.** |
| 936 | `CentralizedTranslator.instance.translate('Cancel')` | **A** | `dialogCancel` (`"Cancel"`) | **Wired.** `context.l10n.dialogCancel` |
| 947 | `CentralizedTranslator.instance.translate('Use value')` | B | `voiceUseValue` | Fact-edit dialog action |
| 984 | `'Review profile updates'` | B | `voiceReviewProfileUpdates` | Dialog title |
| 1012-1013 | `'Keep session only'` (ternary of translator call vs literal) | B | `voiceKeepSessionOnly` | |
| 1025-1026 | `'Save confirmed'` (same pattern) | B | `voiceSaveConfirmed` | |
| 1037 | `'Confirmed details saved to your profile.'` | B | `voiceProfileSavedMessage` | |
| 1206 | `'Live audio is processed securely. This app does not save audio or raw transcripts.'` | B | `voiceCloudDisclosure` | |
| 1270 | `'No confident scheme match yet. Tell me a little more about your situation.'` (+ Tamil ternary at 1269) | B | `voiceNoConfidentMatch` | Ternary anti-pattern, Tamil already authored |
| 1320 | Semantics `'IN AI assistant'` | C | — | Regular-surface-only (`Ask IN AI` branding), out of companion's product surface but included per file scope |
| 1339 / 1844 | `_isCompanion ? 'Talk to Saarthi' : 'Ask IN AI'` | B (companion half) / C (regular half) | `voiceHeaderTalkToSaarthi` | Only the companion-branch literal is this workstream's concern; `'Ask IN AI'` is regular-mode branding, category C for this task |
| 1379 | tooltip `_voiceAgentController!.state.isMuted ? 'Unmute' : 'Mute'` | B | `voiceUnmute` / `voiceMute` | |
| 1392 | tooltip `'Cancel assistant'` | B | `voiceCancelAssistantTooltip` | |
| 1412-1416 | `_presentInTamil ? '...' : 'Tell me your situation naturally...'` | B | `voiceTellMeNaturally` | Ternary anti-pattern, Tamil already authored |
| 1438-1440 | `'Business loans'` / `'College scholarship'` / `'Farmer subsidy'` | B | `voiceSuggestionBusinessLoans` / `voiceSuggestionCollegeScholarship` / `voiceSuggestionFarmerSubsidy` | Suggestion chips |
| 1453 | tooltip `'Type instead'` | C | — | Regular-surface-only (`!_isCompanion` branch) |
| 1476 | Semantics `_isListening ? 'Stop listening' : 'Start listening'` | B | `voiceStopListeningSemantic` / `voiceStartListeningSemantic` | |
| 1520-1521 | `_isCompanion ? 'Type to Saarthi...' : 'Type instead...'` | B (companion half) / C (regular half) | `voiceTypeToSaarthiHint` | |
| 1535 | tooltip `'Send message'` | B | `voiceSendMessageTooltip` | |
| 1566 | Semantics `'Voice language $_languageBadgeLabel'` | B | `voiceLanguageSemantic` (`"Voice language {language}"`) | Placeholder |
| 1635 | `_presentInTamil ? 'நான் புரிந்துகொண்டது' : 'What I understood'` | B | `voiceWhatIUnderstood` | Ternary anti-pattern, Tamil already authored |
| 1721 | tooltip `'Repeat question'` | B | `voiceRepeatQuestionTooltip` | |
| 1766 | `'Speech output is unavailable; tap the microphone to answer.'` | B | `voiceSpeechOutputUnavailable` | |
| 1789-1792 | `_presentInTamil ? '...' : 'Schemes suited to your situation'` | B | `voiceSchemesSuitedToSituation` | Ternary anti-pattern, Tamil already authored |
| 1803 | `CentralizedTranslator.instance.translate('View all')` | B | `voiceViewAllResults` | Not byte-exact to `viewAll` ("View All"); kept separate since this is a scheme-results-scoped "view all", proposed distinctly to avoid guessing intent |
| 1817 | `CentralizedTranslator.instance.translate('Review and save confirmed details')` | B | `voiceReviewAndSaveDetails` | |
| 1877 | `reply.sourceLabel.isEmpty ? 'Open official source' : ...` | B | `voiceOpenOfficialSource` | |
| 1897 | `'Checking official sources…'` | B | `voiceGroundingChecking` | |
| 1899 | `'Grounded online · ${...} official ${... 'source' : 'sources'}'` | B | `voiceGroundingFoundSources` (`"Grounded online · {count} official {sources}"`) | Placeholder; plural word chosen in Dart, passed as `{sources}` |
| 1901 | `'Offline · using private on-device knowledge'` | B | `voiceGroundingUnavailable` | |
| 1903 | `'Official page unavailable · using the verified local catalog'` | B | `voiceGroundingNoSources` | |
| 2018 | `'Only the topic and official links are checked. Your statement and profile stay on this device.'` | B | `voiceGroundingPrivacyNote` | |
| 2037 | `'Could not open the official source.'` | B | `voiceCouldNotOpenSource` | |
| 2044-2048 | `'Strong match'` / `'Likely match'` / `'Needs confirmation'` / `'Not suitable'` / `'No confident match'` | B | `voiceMatchStrong` / `voiceMatchLikely` / `voiceMatchNeedsConfirmation` / `voiceMatchNotSuitable` / `voiceMatchNoConfident` | Recommendation badge labels |
| 2112 | `'Why this fits: ${reasons}'` | B | `voiceWhyThisFits` (`"Why this fits: {reasons}"`) | Placeholder |
| 2118 | `'Still confirm: ${requirements}'` | B | `voiceStillConfirm` (`"Still confirm: {requirements}"`) | Placeholder |
| 2126-2127 | `'Current official source verified'` / `'Uncertain or historical — verify before applying'` | B | `voiceSourceVerified` / `voiceSourceUnverified` | |
| 2170 | `_presentInTamil ? '...' : 'Best matching schemes'` | B | `voiceBestMatchingSchemes` | Ternary anti-pattern, Tamil already authored |
| 2215 (now) | `EligibilityFactKey.age => 'Age'` | **A** | `labelAge` (`"Age"`) | **Wired** via `_factLabel(context, key)` |
| — | `EligibilityFactKey.state => 'State'` | B | `voiceFactLabelState` | **Not** wired to `filterState` — ARB's `filterState` Tamil (`மாநில அரசு` = "State Government") is the wrong sense for a geographic "which state do you live in" fact; proposing a correctly-scoped Tamil (`மாநிலம்`) instead |
| — | `EligibilityFactKey.district => 'District'` | **A** | `filterDistrict` (`"District"`) | **Wired** |
| — | `EligibilityFactKey.annualIncome => 'Annual income'` | **A** (case-normalized) | `labelAnnualIncome` (`"Annual Income"`) | **Wired**; confirmed same concept via `profile_screen.dart`/`filter_panel.dart` usage |
| — | `EligibilityFactKey.gender => 'Gender'` | **A** | `labelGender` (`"Gender"`) | **Wired** |
| — | `EligibilityFactKey.community => 'Community'` | **A** | `labelCommunity` (`"Community"`) | **Wired** |
| — | `EligibilityFactKey.occupation => 'Situation'` | B | `voiceFactLabelSituation` | Text is "Situation", not "Occupation" — despite the enum name, does not match `labelOccupation` |
| — | `EligibilityFactKey.education => 'Education'` | **A** | `labelEducation` (`"Education"`) | **Wired**; distinct from `labelEducationLevel` ("Education Level") which does not match |
| — | `EligibilityFactKey.disability => 'Disability'` | **A** | `labelDisability` (`"Disability"`) | **Wired**; distinct from `labelDifferentlyAbled` ("Differently Abled") which does not match |
| — | `EligibilityFactKey.maritalStatus => 'Marital status'` | B | `voiceFactLabelMaritalStatus` | |
| — | `EligibilityFactKey.studentStatus => 'Student'` | **A** | `empStudent` (`"Student"`) | **Wired**; confirmed via `profile_screen.dart:49` using this key to display "Student" |
| — | `EligibilityFactKey.businessStage => 'Business stage'` | **A** (case-normalized) | `labelBusinessStage` (`"Business Stage"`) | **Wired**; confirmed via `profile_screen.dart:924` |
| — | `EligibilityFactKey.businessSector => 'Sector'` | B | `voiceFactLabelSector` | `labelIndustry` ("Industry") is a different word/concept |
| — | `EligibilityFactKey.fundingNeed => 'Funding need'` | B | `voiceFactLabelFundingNeed` | `labelFundingRequired` ("Funding Required") is worded differently |
| — | `EligibilityFactKey.landholding => 'Landholding'` | B | `voiceFactLabelLandholding` | |
| 2248 | `'${fact.value} (profile: ${fact.conflictingValue})'` | C | — | Composed from dynamic values; only the parenthetical "profile:" word is static — folded into `voiceFactConflictFormat` proposal below for completeness |
| — | `'profile:'` prefix inside `_displayFactValue` | B | `voiceFactConflictFormat` (`"{value} (profile: {conflictingValue})"`) | Placeholder-based |

---

## Summary counts

| Category | Count |
|---|---|
| A (wired to existing ARB key) | 10 |
| B (proposed new key) | 124 |
| C (excluded) | ~24 |

See `companion_mode_new_arb_keys_proposal.json` for every category-B entry with authored English/Tamil text.
