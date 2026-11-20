# FINAL_QA_RELEASE_CHECKLIST

## Firestore Rules automated coverage
- Run `npm --prefix rules-tests install --no-audit --no-fund`.
- Run `npm --prefix rules-tests test`; this starts the local Firestore Emulator and executes allow/deny tests against the checked-in `firestore.rules`.
- Emulator tests cover owner isolation and unauthenticated denial for onboarding, syllabus progress, study plans, notes and quiz attempts (document reads, collection queries and attempted cross-owner writes), plus bounded Study Memory writes, chat/message ownership and immutability, legacy history write restrictions, read-only catalog access and catch-all denial.
- These tests validate the local Rules file only. They do not publish Rules to Firebase and do not prove production Rules are deployed.
- Keep final manual Rules review and explicit owner approval before any production publication.

# OM STUDY AI — Final QA, Security & Release Checklist

## Latest automation audit — 18 November 2026

- PR #21 remains Open/Draft/Unmerged and targets `main`; its head branch is `feature/ai-chat-sessions-and-voice` at `08e11a4ea15eba25545a5dd8b24e0bed88a2beb5`.
- PR #22 remains Open/Draft/Unmerged and targets PR #21's feature branch; its head branch is `feature/ai-chat-sessions` at `a3ee641b52793d219c4de48e4125b1ffb27fc390`. The feature-branch head matches Build #209.
- Latest Build APK workflow is Build #209, run ID `44005306464`, for commit `a3ee641b52793d219c4de48e4125b1ffb27fc390`; it completed successfully on 17 November 2026.
- Build #209 artifact is `om-study-ai-apk` (artifact ID `14294531852`), not expired; ZIP size 26,013,700 bytes; ZIP SHA-256 `610fecf4cf2cbf455a3978b06597f0e514bece52ef4b7e1ed6bb4bc604b5bed1`; expiry 15 February 2027 02:45:30 UTC. The downloaded ZIP digest matches GitHub's artifact digest.
- Extracted Build #209 APK is 54,005,750 bytes; SHA-256 `3d962e1890737c09d1e87db679512527eae78f23a22c53279dd961684e7558c7`. It is a CI candidate, not physical-device acceptance.
- Build #209 completed all 18 reported job/cleanup steps. Worker JavaScript tests: 27/27; Flutter Analyze: no issues; Flutter tests: 85 passed; Firestore Rules Emulator tests: 5/5 passed; release APK build and artifact upload succeeded.
- Build #209's Emulator suite covers owner-only document reads, collection queries and cross-owner writes for onboarding, syllabus progress, study plans, notes and quiz attempts. It also verifies bounded Study Memory writes, chat/message ownership and immutability, legacy history restrictions, read-only catalog access and catch-all denial.
- This follow-up adds explicit cross-account and anonymous collection-query denial tests for AI Study Memory, AI chat sessions/messages and legacy AI Teacher history. It also verifies owner-only memory edits, rejects owner deletion (the UI clears by saving bounded empty fields), and keeps the memory document reusable. Build #210 will validate these additional cases.
- The AI Study Memory remains a fixed `users/{uid}/ai_study_memory/profile` document with bounded summary/topics/style fields and server timestamps. The app reads and writes only beneath the authenticated user's UID; production Rules publication remains pending.
- Adaptive quiz context uses the same student's Study Setup, profile goals/language, editable AI Study Memory, recent quiz attempts, recent chat questions and legacy student-authored prompts. Malformed answer indexes/options, impossible scores and oversized context are rejected or bounded.
- AI Teacher receives the student's recent quiz scores, repeated weak topics and incorrect question prompts, plus bounded cross-chat history and legacy chat context. Student context is sent as untrusted user data, separate from system instructions.
- No Firebase Rules, Cloudflare Worker, secrets, billing settings or repository visibility changes were made.

**Purpose:** This is the release gate for the complete app. A green APK build is not proof that the app works on a real Android phone. Mark an item PASS only after recording the date, build/commit, test account, device, and evidence. Use NOT TESTED, BLOCKED, or FAIL honestly.

**Release policy**
- Keep the Firebase project on Spark/free tier and all external services within explicitly free quotas. Never enable billing or a paid API.
- Never put Gemini/API secrets in Flutter code, APK, GitHub source, screenshots, or logs.
- Do not publish Firestore Rules, merge PRs, deploy production changes, delete data, or change Firebase settings without the owner's explicit approval.
- Use two disposable test accounts (A and B). Never use real student data for destructive tests.
- Back up test data before migration/deletion tests.

## 1. Release status snapshot

Historical snapshot (15 November 2026; superseded by the latest automation audit above):
- PR #21 remains open, Draft and unmerged; it targets `main` from `feature/ai-chat-sessions-and-voice` at `08e11a4ea15eba25545a5dd8b24e0bed88a2beb5`.
- PR #22 remains open, Draft and unmerged; it targets PR #21's feature branch and continues on `feature/ai-chat-sessions`.
- Latest successful Build APK workflow is Build #206 (run ID `43550224901`) for commit `7ca2cdc83975315b2870d88bf3358c41d89b991e`. Its single build job completed all 18 reported execution/cleanup steps successfully.
- Build #206 artifact is `om-study-ai-apk` (artifact ID `14095916949`), not expired: 26,005,227 bytes; ZIP SHA-256 `ebf6462e3de4d491264442d68411e322f76fef4447a521aefe6bba8fc9e206f8`; expires 12 February 2027 at 03:10:29 UTC. The downloaded ZIP digest matches GitHub's artifact digest.
- Extracted Build #206 APK is 53,940,214 bytes; SHA-256 `66d880a54a5888aff401e426a8e79309a47f4db5aa1fddfea03ed21b2b58f9c7`. This is a CI candidate, not physical-device acceptance.
- Build #206 passed Worker JavaScript tests 27/27, Flutter Analyze with no issues, all 81 Flutter tests, Firestore Rules Emulator tests 5/5, release APK build and artifact upload.
- Build #202 (run ID `43146017853`; commit `222116c2de0faf44e48b19a4c84229a6a7c6df5a`) failed in Worker JavaScript tests before Flutter setup. The normalized duplicate-question validator used an over-escaped Unicode-property regex, and the prior valid-schema fixture reused one question three times. Build #203 corrected both; its 26 Worker tests passed.
- Build #204 (run ID `43357657971`; commit `725d0c922b86aae144b6f6159a57665b85b84f5f`) failed at `node --check index.js`: the operator-preserving character-class regex was over-escaped and produced `Range out of order in character class`; all later steps were skipped and no artifact was produced. Build #205 replaces the character-class approach with Unicode/operator tokenization, corrects the regression fixture and passed the complete APK workflow.
- Adaptive quiz context uses the same student's Study Setup, profile goals/language, editable AI Study Memory, recent quiz attempts, recent chat questions and legacy student-authored prompts. Malformed answer indexes/options, impossible scores and oversized context are rejected or bounded.
- AI Teacher receives the student's recent quiz scores, repeated incorrect topics and incorrect question prompts, plus bounded cross-chat history and legacy chat context. Student context is sent as untrusted user data, separate from system instructions.
- The account-lifecycle preservation patch, editable private AI Study Memory, bounded adaptive context, locale resolution and student-only legacy chat prompt extraction remain source- and CI-verified; production Rules publication and phone isolation tests remain pending.
- Required Study Setup completion now validates each visible answer against its question: non-empty unique allowed goals/options, optional skips only on optional questions, and non-blank text bounded to 200 characters. Invalid persisted values route back to the relevant question instead of releasing the dashboard; Build #207 will validate the new regression tests.
- Profile loading treats the profile and editable AI Study Memory as independent reads. A Memory permission/network failure no longer hides profile data or Study Setup editing; Memory fields remain read-only until retry succeeds, preventing accidental blank overwrites.
- Voice locale follows the editable profile language first, then Study Setup; English maps to `en-US`, Hindi/Hinglish to `hi-IN`. Voice permission/error guidance has automated coverage, but real-device settings recovery remains pending.
- Image-generation source is included: explicit user action, Firebase-token-authenticated Worker endpoint, separate UID rate limit, Llama Guard moderation, FLUX.1 schnell (4 steps), bounded JPEG validation, in-memory display only, no image storage and no paid fallback. The Worker is not deployed.
- Build #206 validates the image screen's HTTPS Worker URL gate: blank/malformed/non-HTTPS URLs, embedded credentials, query strings, fragments and surrounding whitespace are rejected; the Generate button remains disabled until a valid endpoint is compiled in. This UI guard does not prove that the Worker is deployed or reachable.
- The quiz uniqueness validator rejects repeated questions/options after Unicode, case, punctuation and whitespace normalization while preserving mathematical/programming operators. The corrected tokenization keeps `C` distinct from `C++`, addition distinct from subtraction, and still treats operator-spacing variants as duplicates; Build #205 passed the Worker regression suite.
- Worker deployment, live Firestore Rules publication, final main-branch APK and complete physical-device acceptance remain release gates.

## 1A. Latest focused audit findings (7 November 2026)

- [x] Chat pagination uses a newest-first query ordered by `createdAt` plus document ID, cursor-based older-page loading, and ID deduplication. Unit tests cover ordering, overlap, live-copy preference and deterministic timestamp ties.
- [x] Chat history remains scoped below the authenticated user's `users/{uid}` document. Firestore Emulator tests verify owner-only chat and message reads/writes, reject cross-account access, and prohibit message mutation/deletion.
- [x] Voice initialization is lazy (only after the microphone action); lifecycle helpers permit voice start only in `resumed` and stop capture/output when the app becomes inactive, hidden, paused or detached. Automated lifecycle tests exist.
- [ ] Real-device voice acceptance is still required: first-time permission prompt, deny once, permanently deny/settings recovery, no speech after backgrounding, and microphone unavailable/error behavior.
- [x] Build #198 passed five automated voice error-guidance tests for transient permission denial, permanent permission denial, unavailable speech service and other permanent errors; real-device settings recovery remains required.
- [x] AI Worker checks authenticated Firebase UID against separate Cloudflare Rate Limiting bindings: tutor/explanation 20 calls per 60 seconds and quiz generation 5 calls per 60 seconds. Missing/failed bindings fail closed. Limits are approximate and independent per Cloudflare edge location, not a strict global quota; do not describe them as a hard billing cap. Bindings are configured in `workers/wrangler.toml`; this source change does NOT deploy the Worker.
- [x] Worker unit tests cover rate-limit allow/deny/fail-closed behavior, UID keying, request-size and malformed JSON handling, and quiz schema rejection (count, duplicate options, blank title, invalid answer index). Existing provider error classification tests remain. End-to-end signed Firebase token tests and deployed binding smoke tests remain release gates.
- [x] Build #177 validates that onboarding, editable memory, quiz history and prior-chat context are sent as a separate untrusted user-role JSON message rather than system instructions. Tests verify role separation, JSON preservation, language selection, quiz request details and explanation fields.
- [x] AI Teacher consumes a bounded recent quiz summary (scores, repeated weak topics and explicitly incorrect questions) from the same authenticated user's `quiz_attempts`; Build #188 passed all 56 Flutter tests.
- [x] Adaptive quiz and AI Teacher learning signals reject negative/out-of-range answer indexes, malformed option arrays, fractional/impossible scores, and normalize/bound question/topic text before context assembly; Build #192 passed the 63 Flutter tests and static analysis.
- [x] FLUX image payloads are base64-decoded and checked for bounded JPEG SOI/EOI markers in the Worker before the client receives them; the Flutter decoder also rejects non-JPEG and oversized bytes. Build #193 passed 24 Worker tests; the success-path fixture is being replaced with a complete 1×1 JPEG sample.
- [x] Legacy profile-only goals are restored when Study Setup answers are absent; explicit setup goals take precedence. Adaptive quiz context reads legacy chat prompts only from student `role=user` messages, restores chronological order and deduplicates/bounds prompts. Build #189 passed the new regression tests.
- [x] Builds #178 and #179 failures were diagnosed from logs and corrected: #178 had an over-escaped schema literal; #179 had one stale test phrase. Build #180 now passes the full Worker, Flutter, Firestore Emulator and APK workflow.
- [x] Build #180 confirms the exact quiz JSON envelope, requested question count, option uniqueness and field limits through Worker tests.
- [x] Worker quiz generation constructs its exact JSON response envelope with `JSON.stringify` and matches the title/questions/options/answerIndex and field bounds enforced by `isValidQuizResponse`; Build #180 passed the regression suite.
- [x] Worker chat history is aligned to the app's eight-message recent context: accept up to eight valid `user`/`model` rows, reject a ninth or malformed/overlong row. Build #182 passed all 23 Worker tests, including this boundary.

## 2. Build, source and dependency checks

- [ ] Confirm PR #21 and #22 are reviewed; confirm base/head branches and dependency order.
- [ ] Run Flutter formatting and static analysis; resolve all errors and review warnings.
- [ ] Run all Flutter unit/widget tests; add tests for onboarding state, chat ordering/pagination, quiz validation and language selection.
- [ ] Run Worker checks and `node --test workers/index.test.js`; add tests for auth failures, malformed requests, provider failures, rate limits and quiz JSON validation.
- [ ] Verify release build uses the intended Firebase project ID and Android package `com.omstudy.om_study_ai`.
- [ ] Verify microphone permission is present and no unrelated dangerous permissions were introduced.
- [ ] Inspect dependency changes and lockfile; ensure packages are maintained and license-compatible.
- [ ] Scan repository, build logs and APK contents for API keys, service-account files, debug secrets and private data.
- [ ] Confirm release build is non-debuggable and does not expose verbose sensitive logs.
- [ ] Build a fresh release APK from the final main commit; record commit SHA, workflow run ID, artifact name, size and checksum.
- [ ] Install that exact APK on a real Android phone and record Android version/device model.

## 3. Authentication, account lifecycle and onboarding

Test each flow on a clean install and on an existing account:
- [ ] New signup with valid email/password succeeds and creates only that user's profile.
- [ ] Invalid email, weak password, duplicate email and network failure show understandable errors.
- [ ] Email verification behavior is clear (if enabled); password reset email arrives and reset link works.
- [ ] Login, logout, app restart and session persistence work.
- [ ] Wrong password and unknown account do not crash or reveal sensitive account details.
- [x] Build #207 passed strict Study Setup answer validation for empty/unknown/duplicate options, optional skips and bounded text; real-device onboarding/resume/Back acceptance remains pending.
- [ ] Real-device: a new account cannot reach the dashboard before every visible, valid Study Setup answer is saved; force-close/resume and Android Back remain blocked until completion.
- [ ] Required questions cannot be bypassed by Back/navigation or app restart.
- [ ] Setup resumes at the correct unanswered question after force-close/reopen.
- [ ] Text answer, selected options, skipped optional question and language preference save correctly.
- [ ] Completing setup removes the required-setup gate; existing users are not forced through it unexpectedly.
- [ ] Profile/setup can be edited later without corrupting existing answers.
- [ ] Logout followed by login as account B shows no A profile, answers, goals or progress.
- [ ] Account deletion/export behavior is clearly disclosed and implemented before public launch; if not implemented, mark BLOCKED and do not claim full account lifecycle support.

## 4. Student profile, study context and AI memory

- [ ] Confirm context reads only the signed-in user's onboarding and quiz records.
- [ ] Confirm supported fields (language, level, class/board/stream, exam/trade, goals, daily study time) match actual stored field names and types.
- [ ] Missing or malformed optional profile fields do not prevent asking a question.
- [ ] Context has a strict size limit and excludes passwords, email credentials, tokens and unrelated personal data.
- [ ] English, Hindi and Hinglish each produce the expected AI response language.
- [ ] AI response uses the student's level and goals appropriately without treating profile text as system instructions.
- [ ] Quiz history includes only a small, relevant, recent sample; verify wrong-answer extraction and avoid duplicate/noisy entries.
- [ ] Account B cannot read or influence account A's study context.
- [ ] Clearly distinguish contextual personalization from persistent editable AI memory. Do not label it “full AI memory” until memory storage, view/edit/clear controls and rules are implemented and tested.
- [ ] Test clearing curated memory and ensure its summary, strengths, weak topics and preferred style are absent from the next request; confirm prior chats and quiz history remain separate context sources.

## 5. AI Teacher, chat sessions and history

- [ ] Ask simple and advanced questions in Hindi, English and Hinglish; check correctness, clarity and level.
- [ ] Ask follow-up questions; only the intended current chat's recent history is sent.
- [ ] Create multiple chats; titles, timestamps and last-message previews are correct.
- [ ] Switch between chats; each chat displays its own messages and context.
- [ ] Close/reopen app and verify messages persist.
- [ ] Verify old legacy flat messages are presented safely and are not silently duplicated or rewritten.
- [ ] Test empty chat, long text, rapid taps, duplicate send, slow network, timeout, server error and retry.
- [ ] Test message ordering when two messages have the same/near-identical timestamps.
- [ ] Test loading older history with at least 120 messages: no gaps, duplicates, reversed ordering, lost latest messages or jumpy scroll.
- [ ] Prefer cursor pagination using a stable ordered field plus document ID tie-breaker; verify older-page loading does not replace the live newest-message stream.
- [ ] Verify chat list limit behavior and what happens beyond 100 chats.
- [ ] Test chat deletion/retention policy; if deletion is not implemented, disclose it and do not imply users can delete chats.
- [ ] Account B cannot read A's chat documents or message subcollections.
- [ ] AI errors never appear as successful assistant messages; loading indicator always clears.

## 6. AI Q&A and learning-plan behavior

- [ ] Ask a question from each supported learning category (school subject, government exam, ITI/electrician/solar where applicable).
- [ ] Confirm explanations include steps/examples where useful and ask a clarifying question when the prompt is ambiguous.
- [ ] Confirm AI distinguishes verified official syllabus/PYQ material from AI-generated suggestions.
- [ ] AI does not invent official source links, exam dates, syllabus claims or PYQ provenance.
- [ ] Study-plan recommendations reflect the user's goals, available daily time and progress.
- [ ] Missed tasks and changed available time can be handled without deleting completed history.
- [ ] Generated plan is editable and persists across restart.
- [ ] If automatic plan adaptation is not implemented, mark it as a future feature rather than claiming it is adaptive.

## 7. AI-generated quiz, answer checking and mistakes

- [ ] Generate quizzes for different topics and allowed question counts (3, 5, 10, 15).
- [ ] Validate every question has exactly four options, a valid answer index, explanation and topic.
- [ ] Reject malformed, empty, overlong or unsafe model output without crashing.
- [ ] Check correct/incorrect answer flow, no-answer validation, next/previous behavior and final score.
- [ ] Verify score denominator uses actual generated question count.
- [ ] Verify quiz attempt saves once only; rapid tapping/retry must not create duplicate attempts.
- [ ] Verify each attempt stores enough data for mistake review without leaking another user's data.
- [ ] Wrong-answer notebook shows selected answer, correct answer and explanation; correct answers are excluded.
- [ ] Recent quiz context uses only the intended user's last few attempts.
- [ ] Clearly label generated questions as AI-generated; never present them as official PYQs unless source-verified.
- [ ] Test quota/rate-limit/provider error during quiz generation and show a useful retry message.
- [ ] Verify topic/weakness adaptation against recorded mistakes. If no robust weak-topic model exists, do not claim the quiz is fully adaptive.
- [ ] For each AI-generated quiz response, persist the generated topic with the selected/correct answer indexes.
- [ ] In the next quiz context, count only incorrect answers with known topics, rank repeated weak topics, include a bounded recent score summary, and keep the total context at or below 3,000 characters.
- [ ] Confirm legacy attempts without a topic remain readable and do not falsely create a weak-topic label.

## 8. Voice input and answer listening

- [ ] Android microphone permission prompt appears only when voice input is requested.
- [x] Speech recognition initialization is lazy: it is not initialized during screen startup; it is initialized only after the student taps the microphone control. Verify permission prompt timing on a physical Android phone.
- [x] Automated lifecycle helper allows voice start only in `resumed`; unit coverage denies inactive, hidden, paused and detached states.
- [x] Voice locale follows the editable profile language first, then the Study Setup language for older accounts; `en` maps to `en-US`, while `hi`/`hinglish` map to `hi-IN`. Helper tests are included in Build #197; physical recognition/TTS checks remain pending.
- [ ] Verify microphone denial, permanent denial and settings recovery on a physical Android phone; automated tests cannot replace this device check.
- [ ] Denied permission, permanently denied permission and device without speech support show clear recovery guidance.
- [ ] Hindi and English recognition are tested on-device; Hinglish limitations are documented.
- [ ] Speech recognition fills the text field and does not auto-send without user action.
- [ ] User can stop listening; timeout/pause ends recognition safely.
- [ ] TTS reads only when the listen button is tapped; stop button interrupts speech.
- [ ] Test long answers, punctuation, empty recognition, backgrounding, phone call interruption and screen navigation.
- [ ] TTS/speech resources stop on pause, route change and dispose; no microphone remains active unexpectedly.
- [ ] Test with wired/Bluetooth headset and muted/media-volume settings where available.

## 9. Image generation (only when explicitly requested)

- [x] Source implementation adds a dedicated dashboard screen; image generation occurs only after an explicit Generate tap and never from ordinary text chat.
- [x] Worker authenticates the Firebase ID token, applies a separate UID-keyed limit of one request per minute, and fails closed if the rate-limit binding is missing. Cloudflare limits are approximate per edge location, not a strict global/daily quota.
- [x] Llama Guard 3 must explicitly classify the prompt as safe; unsafe, malformed or unavailable moderation blocks generation.
- [x] FLUX.1 [schnell] runs at four steps. The app displays returned image bytes in memory only; no Firestore, public bucket or R2 storage is used.
- [x] Image generation has no Gemini, third-party or paid fallback. On Workers Free, Workers AI has a shared 10,000 Neurons/day allocation; further operations fail after the allowance is exceeded. If the account is on Workers Paid, overage may be billed; do not upgrade or enable billing.
- [x] Build #187 passed Worker JavaScript checks (23/23), Flutter Analyze, all 55 Flutter tests, Firestore Rules Emulator tests (5/5), release APK build and artifact upload.
- [x] Worker moderation tests require the entire trimmed Llama Guard response to equal `safe`; actual newline/category suffixes and literal escaped suffixes are rejected.
- [x] Client-side image payload validation requires `mimeType: image/jpeg`, valid bounded base64, JPEG SOI and EOI markers before rendering. The truncated-image regression test is included in commit `e29851a8c33241b455722503adb22638aa717f9f`; Build #201 passed the Worker checks and Build #203 passed 26/26 Worker tests.
- [ ] Do not deploy the Worker until the owner explicitly approves. No Cloudflare setting, secret or deployment was changed by this source patch.
- [x] Build #206 passed the client-side Worker URL gate tests for blank/malformed/non-HTTPS endpoints, embedded credentials, query strings, fragments and surrounding whitespace. This UI guard does not prove that the Worker is deployed or reachable.
- [x] Build #201's successful Worker test run (24/24) and later Build #203 validation include the client-side JPEG end-marker check and truncated-payload regression coverage; physical image-generation tests remain pending.
- [ ] Real-device acceptance remains required: prompt validation, moderation blocks, rate limit, quota exhaustion, image display, slow network and leaving the screen clears the temporary image.
- [ ] Verify the model's current license and usage terms before public release. Never store generated images publicly by default.
 
## 10. Syllabus, notes, resources and official content

- [ ] Syllabus catalog is populated only from traceable official sources and includes source URL, authority, version/date and verification status.
- [ ] AI-extracted syllabus is visibly marked unverified until a human/admin verifies it.
- [ ] Test PDF upload/import for text PDFs, scanned PDFs, large files and malformed files; show limitations clearly.
- [ ] Verify syllabus progress saves per user and survives restart.
- [ ] Notes create/read/edit/delete, empty-field validation and offline/network error behavior work.
- [ ] Video/resource links are checked and open the expected destination; broken/unverified links are not presented as verified.
- [ ] Distinguish official previous-year questions from generated practice questions.
- [ ] If verified syllabus, PDF import, video discovery or PYQ bank is not yet implemented, mark it NOT IMPLEMENTED; do not invent content to pass this section.

## 11. Reminders, notifications and Android lifecycle

- [ ] Request notification permission at an appropriate time and explain why it is needed.
- [ ] Schedule, edit, cancel and reschedule reminders; test timezone and daylight/time changes.
- [ ] Verify reminders after app restart and device reboot if reboot persistence is claimed.
- [ ] Test Android 12+ exact-alarm permission behavior and Android battery restrictions.
- [ ] Verify no duplicate reminders after editing or reinstall/restore.
- [ ] Confirm notification tap opens the correct lesson/task.
- [ ] If alarms/reminders are not implemented, mark NOT IMPLEMENTED.

## 12. Offline behavior and synchronization

- [ ] Identify exactly which screens/data are available offline; do not claim whole-app offline support if only cached content exists.
- [ ] Open cached notes/progress with network disabled.
- [ ] Attempt edits offline; show pending/saved-local status accurately.
- [ ] Reconnect and verify sync completes without duplicate or lost writes.
- [ ] Test simultaneous updates from two devices and document conflict policy.
- [ ] AI, image generation and remote syllabus discovery should show an honest offline-unavailable state.
- [ ] Verify no false “saved to cloud” confirmation while offline.

## 13. Firestore Rules and privacy/security

Perform only after final schema and code are stable. First review the complete consolidated `firestore.rules`; publish only with explicit owner approval.
- [ ] Unauthenticated reads/writes to private user data are denied.
- [ ] Account A cannot get/list/create/update/delete account B profile, onboarding, plan, notes, quiz attempts, chats, messages or memory.
- [ ] Client cannot grant itself admin role or edit protected profile fields.
- [ ] Chat/message fields, role, length and timestamps are validated; clients cannot modify immutable messages.
- [x] Checked-in Study Memory rules allow only the signed-in owner to write the fixed `profile` document with bounded fields and a server timestamp; production publication and phone isolation tests remain pending.
- [ ] Public catalog is read-only to ordinary users; admin writes are server/admin controlled.
- [ ] Catch-all deny remains in place.
- [ ] Rules Playground tests cover allow and deny cases for every collection/subcollection.
- [ ] Run Firebase Emulator Rules tests if available; save results.
- [ ] Check logs and analytics for accidental message text, prompts, tokens or personal data.
- [ ] Document data retention, export and deletion; test user deletion across all subcollections and external storage.
- [ ] Verify Worker Firebase ID-token validation, audience/project checks and expiry handling.
- [ ] Test rate limiting under repeated requests and ensure it cannot be trivially bypassed by creating chats.
- [ ] Evaluate Firebase App Check before public release; if not enforced, document abuse risk and keep rollout restricted.

## 14. Cloudflare Worker and free-tier resilience

- [ ] Confirm production Worker URL is correct and reachable from the release APK.
- [ ] Confirm Firebase ID token is required and invalid/expired tokens are rejected.
- [ ] Confirm Gemini secret exists only as a Cloudflare Worker secret; never print its value.
- [ ] Test Gemini success, quota 429, 5xx, timeout, malformed response and invalid-key handling.
- [ ] Verify fallback is also free-tier, bounded and does not conceal quota exhaustion.
- [ ] Confirm fallback model availability and response format; test fallback in live staging.
- [ ] Add/verify server-side request size, input validation, timeout and per-user rate/quota controls.
- [ ] Check Cloudflare Workers AI daily neuron limits and Gemini free quota; expose friendly “try later” behavior.
- [ ] No automatic billing upgrade or paid provider fallback.
- [ ] Ensure logs redact Authorization headers, tokens, API keys, prompts containing sensitive information and provider raw error bodies.
- [ ] Verify CORS is restricted appropriately for the app's request pattern; do not treat CORS as authentication.
- [ ] Record deployed Worker version/date and test it from the exact release APK.

## 15. Admin, content operations and audit

- [ ] Admin privileges are assigned only through trusted server-side configuration, never client writes.
- [ ] Non-admin users cannot open admin screens or call admin operations.
- [ ] Admin content changes record actor, timestamp and before/after or version information.
- [ ] Verify syllabus corrections and announcements are auditable.
- [ ] API health/usage display never reveals secrets or another user's prompts.
- [ ] If admin panel, audit logs or API manager are not implemented, mark NOT IMPLEMENTED.

## 16. Phone acceptance matrix

Use at least one real Android phone; use a second device if available.
- [ ] Fresh install, first launch, signup and required onboarding.
- [ ] Existing-user upgrade/install-over behavior and data preservation.
- [ ] Login/logout and account switching.
- [ ] Dashboard navigation and back button.
- [ ] AI chat, chat switching, long history and network failure.
- [ ] AI quiz, scoring, mistakes and progress.
- [ ] Voice recognition and TTS with permissions.
- [ ] Notes/study plan persistence.
- [ ] Notifications/reminders if implemented.
- [ ] Offline/reconnect behavior if claimed.
- [ ] Screen rotation, app background/foreground, force-stop and reboot.
- [ ] Low storage, slow network, airplane mode and intermittent connectivity.
- [ ] Accessibility: readable font sizes, labels, contrast and touch target sizes.
- [ ] Battery and memory use during a 20–30 minute session.
- [ ] No crash, ANR, stuck spinner, duplicate send or silent data loss.

## 17. Final release decision

Release is **NOT READY** if any of the following is true:
- Any P0 security/privacy test fails or is untested.
- A required feature is represented as complete but is only a stub or unverified.
- Final main-branch release build is missing or does not install.
- The exact APK has not passed the phone acceptance matrix.
- Firestore Rules do not match the final data schema.
- Worker production test fails or secret exposure is found.
- Any required test is still BLOCKED/NOT TESTED without an explicit owner-approved limitation.

Before calling it FINAL, attach:
1. Final main commit SHA and PR merge references.
2. Successful release workflow URL and APK artifact details/checksum.
3. Final Firestore Rules file and rules-test evidence (not published without approval).
4. Worker deployed version and live smoke-test evidence.
5. Completed test report with device/Android version and PASS/FAIL/BLOCKED for every section.
6. Known limitations, free-tier quotas and any features intentionally disabled.
7. Phone installation and first-login guide.

## 18. Test report template

| Field | Value |
|---|---|
| Test date/time | |
| App version / commit SHA | |
| APK workflow run / artifact | |
| Device model / Android version | |
| Firebase project | |
| Worker version | |
| Test account A/B (test-only IDs) | |
| Tester | |

For each checklist item record: **PASS / FAIL / BLOCKED / NOT TESTED**, steps performed, expected result, actual result, evidence link/screenshot, and issue/commit reference. Never mark a section PASS based only on a source-code review or CI build.


## Automation checkpoint — 19 November 2026

- PR #21 is Open/Draft/Unmerged, targets `main`, and remains at head `08e11a4ea15eba25545a5dd8b24e0bed88a2beb5`.
- PR #22 is Open/Draft/Unmerged, targets PR #21's feature branch, and remains at head `00dada936c1c23c6d195c21116a54824405a379b` before this follow-up.
- Current feature branch: `feature/ai-chat-sessions`; pre-change head: `00dada936c1c23c6d195c21116a54824405a379b`.
- Latest Build APK workflow: Build #210, run ID `44225271950`, commit `00dada936c1c23c6d195c21116a54824405a379b`; conclusion SUCCESS on 18 November 2026.
- Build #210 artifact: `om-study-ai-apk`, artifact ID `14393071105`, ZIP size 26,013,701 bytes, expiry 16 February 2027 02:42:57 UTC, GitHub SHA-256 `ddea5f78c679ecbd850e0037b25fb01b034478a93f6047be08305493592ddead`. The downloaded ZIP SHA-256 matches the GitHub digest.
- Extracted Build #210 APK: 54,005,750 bytes; SHA-256 `43d5a487b00eb99d4fd0eba00fb32c800903b6cdd39c465d4f8a4d78c9aed254`. ZIP integrity passed and the file was identified as an Android APK.
- Build #210 completed all 18 reported job/cleanup steps. Worker JavaScript tests: 27 passed, 0 failed; Flutter Analyze: no issues; Flutter tests: 85 passed; Firestore Rules Emulator: 6 passed, 0 failed; release APK build and artifact upload succeeded.
- Source review found that the editable AI Study Memory controls already existed inside ProfileScreen, but the dashboard's separate “मेरी AI मेमोरी” tile was still marked Coming Soon. This follow-up exposes that tile as ready and routes it directly to ProfileScreen. A regression test checks the module is available. Build #211 will validate the change.
- Worker dry-run validation in CI is not a production deployment. No Cloudflare Worker was deployed and no Firebase Rules were published.
- Physical-device acceptance, live Firestore Rules publication, Worker deployment approval, and final main-branch release remain outstanding. CI success is not device acceptance.

## Automation checkpoint — 20 November 2026

- Repository: `Prajapatiji-hub/om-study-ai`; feature branch: `feature/ai-chat-sessions`.
- PR #21: Open, Draft, Unmerged; head `08e11a4ea15eba25545a5dd8b24e0bed88a2beb5`, target `main`.
- PR #22: Open, Draft, Unmerged; head `bca5b4e727b905d957e9519c281da917f185449e`, target `feature/ai-chat-sessions-and-voice`.
- Latest Build APK: Build #211, run ID `44445793323`, commit `bca5b4e727b905d957e9519c281da917f185449e`; conclusion SUCCESS on 19 November 2026.
- Build #211 artifact: `om-study-ai-apk`, artifact ID `14493950420`, ZIP size 26,007,538 bytes, expiry 17 February 2027 02:38:29 UTC, GitHub SHA-256 `a9583a9fd92c0f1a2a7656867ae02f04188510b7399248cab0f6db5454a0b984`. Downloaded ZIP checksum matches the GitHub digest.
- Extracted Build #211 APK: 54,005,750 bytes; SHA-256 `07d503bc95370251689ace6c80d4050ccdcffae9528dbaa5e56649401c2c9b10`. ZIP integrity passed; entry is `app-release.apk` and was identified as an Android package.
- Build #211 completed all 18 reported job/cleanup steps. Worker JavaScript: 27 passed, 0 failed; Flutter Analyze: no issues; Flutter tests: 86 passed; Firestore Rules Emulator: 6 passed, 0 failed; release APK build and artifact upload succeeded.
- The dashboard's editable AI Study Memory shortcut is enabled and routes to ProfileScreen; its regression test passed in Build #211.
- Follow-up performance review found that AI Teacher loaded profile, curated memory, onboarding, quiz history, recent chats and legacy history serially, then loaded each recent chat's messages serially. The next code checkpoint starts independent owner-scoped reads together and fetches recent chat message pages concurrently while preserving recency order, per-chat chronology, bounds and per-read failure isolation.
- Profile and AI Study Memory reads in ProfileScreen's data loader will also start concurrently; neither optional read failure blocks the other.
- Added pure tests for recent-chat ordering, malformed-row filtering, message/text bounds and concurrent profile/memory reads. Build #212 (triggered by the follow-up commit) must validate these changes.
- No production Firestore Rules were published and no Cloudflare Worker was deployed. CI Worker dry-run is not a deployment. Physical-device acceptance and final owner approvals remain outstanding.

## Build #212 verification and follow-up correction — 20 November 2026

- Build #212: run ID `44662918096`, commit `41f8eeb33269f94280895e08cd80c4edd342b187`, conclusion SUCCESS on 20 November 2026.
- Artifact: `om-study-ai-apk`, artifact ID `14597480064`, ZIP size 26,011,200 bytes, expiry 18 February 2027 02:44:25 UTC, GitHub SHA-256 `adf504bc17cc0d5a4688552fff03c9b8b01209421de790c645d9719f4a4ec383`; downloaded ZIP checksum matched.
- Extracted APK: 54,005,750 bytes; SHA-256 `2222452f6ce823ea2a0be51bf6d2c6705222799c646718d1ae7d35a59bd58c30`. ZIP integrity passed and the archive contains `app-release.apk`.
- Build #212 completed all 18 reported job/cleanup steps. Worker JavaScript: 27 passed, 0 failed; Flutter Analyze: no issues; Flutter tests: 90 passed; Firestore Rules Emulator: 6 passed, 0 failed; release APK build and artifact upload succeeded.
- Post-build source review caught two escaped-string regressions in the new AI learning-context optimization: whitespace normalization used a literal backslash sequence, and context sections were joined using a literal backslash-n rather than newline. The existing tests did not exercise these exact formatting cases, so Build #212 passing does not validate those two behaviors.
- The follow-up correction restores whitespace normalization, extracts a bounded newline-joining helper, and adds regression tests for whitespace, real section separators and the 3,000-character context ceiling. The corrected source must be validated by the next Build APK workflow before it is treated as verified.
- No production Firestore Rules were published and no Cloudflare Worker was deployed. Real-device acceptance and owner approvals remain outstanding.
