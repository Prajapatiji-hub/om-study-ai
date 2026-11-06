# OM STUDY AI — Next Final Test Execution Plan

**Execution target:** `Prajapatiji-hub/om-study-ai`  
**Current integration branch:** `feature/ai-chat-sessions` (PR #22)  
**Base dependency:** PR #22 is stacked on `feature/ai-chat-sessions-and-voice` (PR #21), which targets `main`.  
**Firebase project constraint:** `prajapati-507d7`  
**Release policy:** Spark/free tier only; no paid API, no automatic billing upgrade, no destructive data operation, and no production Rules publish/deployment without explicit owner approval.

This document is an execution order that complements `FINAL_QA_RELEASE_CHECKLIST.md`. It is not evidence that a test has passed. Every result must be recorded as PASS, FAIL, BLOCKED, or NOT TESTED with evidence.

## A. Pre-test safety gate

- [ ] Confirm the latest `main` SHA and the exact PR #21/#22 head SHAs before testing.
- [ ] Confirm PR #21 remains the prerequisite for PR #22; do not merge PR #22 ahead of its dependency.
- [ ] Confirm the Firebase project selected by the app/build is exactly `prajapati-507d7`.
- [ ] Use two disposable Firebase Auth accounts (A and B); do not use real student accounts.
- [ ] Record test-only UIDs and device details in a private test report; never put tokens/passwords in the repository.
- [ ] Export/record the identifiers of the test documents needed for comparison. Do not delete or overwrite existing production data.
- [ ] Confirm Firebase is still on Spark/free tier and no paid billing or paid provider fallback is configured.
- [ ] Confirm no production Firestore Rules publish, Worker deploy, PR merge, or Firebase setting change is part of this test run.

**Stop condition:** If project identity, test accounts, or data-safety boundary is uncertain, stop before any write test.

### B1a. AI Study Memory validation and Rules review (P0)

- [ ] Run `test/study_memory_validator_test.dart`: trimming, blank removal, de-duplication, exact maximum lengths, over-limit rejection, and 12-topic boundary.
- [ ] Confirm Profile writes only `users/{uid}/ai_study_memory/profile` and AI Teacher reads only the signed-in user's document.
- [ ] Review the consolidated source Rules: fixed document ID, owner-only read/create/update, exact allowed fields, bounded summary/style/topic lists, server timestamp, no client delete, and catch-all deny.
- [ ] Run Firebase Emulator Rules tests before any production publication. Current source-only Rules changes are NOT live and NOT emulator-tested.
- [ ] Verify save/reload on two disposable accounts after owner-approved Rules publication; account B must not read account A memory.

## B. Ordered execution sequence

### B1. Source and build baseline (P0)

- [ ] Run formatter check and static analysis on the exact candidate commit.
- [ ] Run Flutter unit/widget tests and record test count, failures, and skipped tests.
- [ ] Run Worker syntax/unit tests, including `node --test workers/index.test.js` where configured.
- [ ] Run dependency and secret scans; inspect generated APK contents for credentials and debug artifacts.
- [ ] Run the Android release APK workflow from the candidate branch.
- [ ] Record workflow URL/run ID, commit SHA, artifact filename, file size, and SHA-256 checksum.
- [ ] Install that exact artifact on a physical Android device; do not substitute a locally rebuilt APK.

**Pass criteria:** all required checks complete successfully; release APK installs and opens. A green CI run alone is not a phone-test pass.

### B2. PR dependency and onboarding regression (P0)

Automated source tests cover the explicit `_setupRequired` gate, goal-specific question branches, multi-goal branching, and visible-question progress. These tests complement—not replace—the disposable-account and physical-device checks below.

Test PR #21 before PR #22:

- [ ] New account A signs up and is directed to required Study Setup.
- [ ] Force-close during setup; sign in again and verify setup resumes.
- [ ] Try Android Back and app navigation before setup completion; dashboard remains gated.
- [ ] Complete setup; dashboard becomes available and completion survives restart.
- [ ] Existing account B signs in and is not unexpectedly forced through new-account setup.
- [ ] Edit existing setup answers; unrelated profile fields, notes, quiz attempts, and progress remain unchanged.
- [ ] Sign out A and sign in B; no A-specific data remains on screen.

**Pass criteria:** only newly created profiles receive the required-setup flag; existing user records remain intact.

### B3. Chat session isolation and real pagination (P0)

Test PR #22 with a disposable account containing at least 120 messages distributed across multiple chats:

- [ ] Create at least three chats; add distinguishable messages to each.
- [ ] Switch rapidly between chats; verify no cross-chat message bleed.
- [ ] Close/reopen the app; verify the correct thread and messages load.
- [ ] Send two messages rapidly; verify one user action does not create duplicate writes.
- [ ] Create messages with equal or near-equal timestamps; verify deterministic order using the stable tie-breaker.
- [ ] Load older messages repeatedly until the oldest record; verify no gaps, duplicates, reverse ordering, or skipped boundary item.
- [ ] Confirm older-page requests use a real cursor (last document snapshot / stable cursor), not merely a larger query limit and full re-read.
- [ ] Confirm AI Teacher sends at most eight recent chronological messages and the Worker accepts exactly eight while rejecting nine, non-array history, invalid roles, blank text and overlong rows.
- [ ] Confirm the newest/live message stream remains active while older pages are appended.
- [ ] Confirm scrolling position does not jump to the bottom when older messages load.
- [ ] Test empty chat, slow network, offline, timeout, permission-denied, and retry.
- [ ] Verify failed AI requests are not stored/displayed as successful assistant answers.
- [ ] Confirm legacy `ai_teacher_messages` data remains readable as intended and is not migrated, duplicated, overwritten, or deleted.

**Pass criteria:** every chat is isolated; history is stable across restart; cursor pagination is demonstrated with evidence from a 120+ message test. If the implementation still increases query limits and re-reads history, mark this block FAIL/NOT READY and implement cursor pagination before release.

### B4. Quiz, score, mistakes and study context (P0)

- [ ] Generate 3, 5, 10, and 15-question quizzes for at least three different topics.
- [ ] Validate each returned question has exactly four non-empty options, one valid answer index, explanation, and topic.
- [ ] Feed malformed/empty/overlong quiz responses through the validation path; app must fail safely.
- [ ] Test unanswered question, previous/next, correct answer, wrong answer, final score, and restart behavior.
- [ ] Confirm score denominator equals actual quiz question count.
- [ ] Tap submit/retry rapidly; only one attempt is saved.
- [ ] Verify mistake review includes selected answer, correct answer, and explanation; correct answers are not added to the mistake list.
- [ ] Verify recent quiz context belongs only to the signed-in user and is bounded to a small recent sample.
- [ ] Verify AI-generated practice is never labelled official PYQ without source verification.
- [ ] Confirm onboarding language/level/goals influence the response appropriately; malformed optional context does not break chat.
- [ ] Verify wrong answers are persisted with their generated question topic; repeated mistakes rank weak topics by frequency in the next AI quiz context.
- [ ] Verify correct answers do not increase weak-topic counts, old records without a topic remain compatible, and the context is capped at 3,000 characters.

**Pass criteria:** schema validation, scoring, persistence, mistake review, and per-user context all match actual stored data.

### B5. Voice input and speech output (P1)

- [ ] Request microphone permission only after the user taps voice input.
- [ ] Test allow, deny, permanently deny, and device speech service unavailable.
- [ ] Test Hindi and English recognition on a physical device; document Hinglish limitations.
- [ ] Confirm recognized speech fills the composer and is not sent automatically.
- [ ] Stop listening, navigate away, background the app, and simulate interruption; microphone must stop.
- [ ] Test text-to-speech start/stop and long answers; speech must stop on route change/dispose.
- [ ] Test with media volume muted and, where available, Bluetooth/wired headset.

**Pass criteria:** no stuck microphone/session, no unintended send, and understandable permission recovery.

### B6. Worker/provider free-tier resilience (P0)

- [ ] Confirm the app sends a Firebase ID token; invalid, expired, wrong-project, or missing token is rejected.
- [ ] Confirm provider secrets remain only in Worker secret storage and never appear in APK, source, or logs.
- [ ] Exercise provider success, quota 429, 5xx, timeout, malformed JSON, invalid secret, and network failure.
- [ ] Confirm the free fallback is bounded and has no paid-provider or billing-upgrade path.
- [ ] Confirm server-side input size, prompt length, timeout, and per-user quota/rate limits.
- [ ] Verify logs contain safe error codes only; redact tokens, API keys, prompts, and raw provider error bodies.
- [ ] Verify the actual deployed Worker version separately from GitHub CI; CI does not deploy the Worker.

**Pass criteria:** authenticated success and safe failure paths work; exhausted free quota returns a clear retry-later response without a paid fallback.

### B7. Image generation decision and guarded test (P1; source integrated, production use still gated)

Current source contract:
- Prompt is limited to 500 characters in both Flutter and the Worker.
- Firebase ID token authentication is required; the Worker applies a separate UID-keyed limit of one request per minute (approximate per edge location).
- Llama Guard must return the complete trimmed verdict `safe`; malformed, unsafe or unavailable moderation blocks generation.
- FLUX.1 [schnell] is fixed at four steps; there is no Gemini, third-party or paid fallback.
- Worker validates a bounded base64 image response; Flutter requires `image/jpeg`, validates base64, checks the JPEG SOI signature, and decodes at most 6 MB. The image is held in memory on the generator screen and is not saved to Firestore or public storage.
- Workers AI free usage is shared across the account; quota exhaustion must return a clear retry-later error. Never upgrade or enable billing.

Tests before production use:
- [ ] Text chat alone never starts image generation; an explicit Generate tap is required.
- [ ] Missing/invalid Firebase token is rejected.
- [ ] Prompt lengths 1, 500 and 501 are tested; Worker-side validation must remain authoritative.
- [ ] Only the exact trimmed `safe` moderation verdict proceeds; unsafe, suffix, malformed and moderation-error cases block generation.
- [ ] Confirm the image model is called with four steps only after moderation succeeds.
- [ ] Test valid JPEG payload, wrong MIME type, malformed base64, non-JPEG bytes, oversized payload, quota exhaustion, timeout and retry.
- [ ] Confirm no paid provider fallback, automatic billing change or public image storage exists.
- [ ] Review model terms/licensing and data-retention terms before public release.
- [ ] Deploy the Worker only after explicit owner approval, then test the actual deployed version and rate-limit bindings.

**Pass criteria:** safety, free-quota, licensing and storage checks pass on the deployed Worker and physical device. Until then, keep production use gated and mark device/deployment checks BLOCKED or NOT TESTED.
 
### B8. Firestore schema and Rules verification (P0 security gate)

- [ ] Inventory every collection/subcollection actually read or written by the candidate code.
- [ ] Compare the complete consolidated `firestore.rules` against those exact paths and field names.
- [ ] Test unauthenticated access is denied for private user data.
- [ ] Test account B cannot get/list/create/update/delete account A profile, onboarding, plan, notes, quiz attempts, chat metadata, messages, or study memory.
- [ ] Test owner access works only for valid schema and permitted fields.
- [ ] Test role escalation, protected-field mutation, malformed message role/content, and immutable-field updates are denied.
- [ ] Verify public catalog reads and admin-only writes match the intended policy.
- [ ] Verify catch-all deny remains.
- [ ] Run Firebase Emulator/Rules unit tests or Rules Playground tests and save evidence.
- [ ] Confirm legacy chat collection behavior is compatible with the final Rules.
- [ ] Confirm no existing collection/document is deleted or migrated as a side effect.

**Important:** prepare and test the Rules file in source first. Do not publish Rules to the live Firebase project until the owner explicitly approves the exact reviewed ruleset and test evidence.

### B9. Final phone acceptance (P0)

On the exact release APK and at least one physical Android phone:

- [ ] Fresh install and first launch.
- [ ] Signup, required onboarding, restart, login, logout, account switch.
- [ ] Existing-user upgrade/install-over with data preservation.
- [ ] Dashboard, navigation, Android Back, screen rotation, background/foreground.
- [ ] AI chat, multiple sessions, 120+ message history, older-page loading.
- [ ] Quiz generation, answer validation, score, mistakes and progress.
- [ ] Voice permission, speech recognition, and TTS.
- [ ] Notes and study plan save/reload.
- [ ] Slow network, airplane mode, reconnect, timeout and retry.
- [ ] Force-stop/reopen and device reboot.
- [ ] Check crash, ANR, stuck loading, duplicate write, and silent data loss.

**Pass criteria:** no P0 crash, privacy leak, data loss, or false save success. Record Android version and device model.

## C. Firestore collections/data preservation ledger

Before any release operation, fill this ledger from the current schema/code. Do not assume collection names from UI labels.

| Data area | Actual path/schema confirmed | Read tested | Write tested | Account isolation tested | Existing data preserved |
|---|---|---|---|---|---|
| User profile | | | | | |
| Onboarding answers | | | | | |
| Study plan/progress | | | | | |
| Notes | | | | | |
| Quiz attempts/mistakes | | | | | |
| Legacy AI Teacher messages | | | | | |
| New AI chat metadata | | | | | |
| New AI chat messages | | | | | |
| Study memory | | | | | |
| Syllabus/resources/catalog | | | | | |
| Admin/content records | | | | | |

Any unknown path remains NOT TESTED. Do not create speculative Rules or migrations for an unverified collection.

## D. HTML prototype review note

The uploaded `OM_STUDY_AI_prototype.html` is a standalone browser prototype, not the Flutter Android application and not proof of Firebase/Worker integration. Before treating it as a release artifact, separately test/fix:
- `showTab()` relies on the implicit global `event`, which is not reliable across browser contexts.
- “One time (today)” alarms do not store a calendar date; a missed one-time alarm can remain and be considered again on a later day.
- Browser alarms only run while the page/timer is alive; they are not Android background alarms or notifications.
- Quiz UI cycles four arithmetic questions but does not calculate/display a final score or persist attempts.
- `localStorage` JSON parsing has no recovery path if stored values are corrupted.
- Checklist completion is stored by array index and is not date-scoped, so it does not automatically reset for a new day.
- Prototype data is browser-local and does not sync to Firebase.

Keep this HTML prototype separate from Flutter release acceptance unless it is intentionally being shipped as a separate web product.

## E. Final evidence/report template

| Field | Recorded value |
|---|---|
| Test date/time | |
| PR / candidate branch | |
| Candidate commit SHA | |
| CI workflow URL and run ID | |
| APK artifact / SHA-256 | |
| Device / Android version | |
| Firebase project ID | `prajapati-507d7` |
| Test account A/B (test-only UIDs) | |
| Worker version tested | |
| Firestore Rules revision tested (not necessarily published) | |
| Tester | |

For each failed/blocked item record: test ID, steps, expected result, actual result, screenshot/log evidence with secrets redacted, issue/PR reference, owner, and retest commit.

## F. Release decision

Release remains **NOT READY** until all P0 gates pass on the final candidate commit and exact APK. P1 features may remain disabled only when clearly disclosed. A CI green check is not a substitute for device acceptance, live Worker verification, or Firestore Rules tests.

Do not merge PRs, publish Firestore Rules, deploy the Worker, change Firebase settings, delete data, or enable image generation as part of this checklist without explicit owner approval.
