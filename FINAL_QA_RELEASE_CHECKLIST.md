# FINAL_QA_RELEASE_CHECKLIST

## Firestore Rules automated coverage
- Run `npm --prefix rules-tests install --no-audit --no-fund`.
- Run `npm --prefix rules-tests test`; this starts the local Firestore Emulator and executes allow/deny tests against the checked-in `firestore.rules`.
- Emulator tests cover owner isolation, unauthenticated denial, bounded Study Memory writes, chat/message ownership and immutability, legacy history write restrictions, read-only catalog access and catch-all denial.
- These tests validate the local Rules file only. They do not publish Rules to Firebase and do not prove production Rules are deployed.
- Keep final manual Rules review and explicit owner approval before any production publication.

# OM STUDY AI — Final QA, Security & Release Checklist

**Purpose:** This is the release gate for the complete app. A green APK build is not proof that the app works on a real Android phone. Mark an item PASS only after recording the date, build/commit, test account, device, and evidence. Use NOT TESTED, BLOCKED, or FAIL honestly.

**Release policy**
- Keep the Firebase project on Spark/free tier and all external services within explicitly free quotas. Never enable billing or a paid API.
- Never put Gemini/API secrets in Flutter code, APK, GitHub source, screenshots, or logs.
- Do not publish Firestore Rules, merge PRs, deploy production changes, delete data, or change Firebase settings without the owner's explicit approval.
- Use two disposable test accounts (A and B). Never use real student data for destructive tests.
- Back up test data before migration/deletion tests.

## 1. Release status snapshot

Latest reviewed source snapshot (4 November 2026; update after each candidate build):
- PR #21 and PR #22 remain open Draft; PR #22 is stacked on PR #21. Do not merge either PR as part of this workflow.
- Build #133 succeeded for commit `e7a8fc2bcc72d52d07f8b58a90ee62546659a792`; the non-expired `om-study-ai-apk` artifact (25.92 MB) was confirmed. SHA-256: `4ce6bdd85d98911b59b15bc5549014018b6eacd260eafe44020a95080a6def41`. This is CI evidence, not physical-device acceptance.
- Adaptive quiz context and weak-topic ranking are implemented; automated coverage exists in `test/adaptive_study_context_test.dart`. Device behavior remains NOT TESTED.
- Editable AI Study Memory is implemented in Profile and loaded into AI Teacher context at `users/{uid}/ai_study_memory/profile`. Pure validator tests and field-validated owner-only Rules source are included in Build #134. Rules are source-only and NOT published or emulator-tested.
- Build #134 succeeded for commit `66e68575d5ffedf9f7cada755371104c3337e05a`; artifact `om-study-ai-apk` (25,923,555 bytes), SHA-256 `8a04479e971a3bb58047095c9d311fd0cb2aee491143a30a3bc9923907823d2e`, expires 2 February 2027. Workflow: `https://github.com/PrajapatiJi-hub/om-study-ai/actions/runs/41777091993`.
- The next candidate adds automated tests for the explicit Study Setup gate and goal-dependent question flow, and applies one strict malformed-quiz-response predicate to both adaptive ranking and AI Teacher recent-mistake context.
- Signup setup gating is wired through Dashboard's `_setupRequired` marker; test fresh signup, resume after force-close, and existing-account preservation on a physical device.
- Worker deployment, live Firestore Rules publication, final main-branch APK, and complete physical-device acceptance remain release gates.

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
- [ ] New account is forced through the required Study Setup before accessing the normal dashboard.
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
- [ ] Clearly distinguish contextual personalization from persistent editable AI memory. Do not label it “full AI memory” until memory storage, view/edit/delete controls and rules are implemented and tested.
- [ ] Test memory reset/deletion and ensure deleted context is not sent on the next request.

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
- [ ] Denied permission, permanently denied permission and device without speech support show clear recovery guidance.
- [ ] Hindi and English recognition are tested on-device; Hinglish limitations are documented.
- [ ] Speech recognition fills the text field and does not auto-send without user action.
- [ ] User can stop listening; timeout/pause ends recognition safely.
- [ ] TTS reads only when the listen button is tapped; stop button interrupts speech.
- [ ] Test long answers, punctuation, empty recognition, backgrounding, phone call interruption and screen navigation.
- [ ] TTS/speech resources stop on pause, route change and dispose; no microphone remains active unexpectedly.
- [ ] Test with wired/Bluetooth headset and muted/media-volume settings where available.

## 9. Image generation (only when explicitly requested)

- [ ] Implement only after selecting a model/API that is genuinely usable on the free tier and documenting its quota, licensing and safety constraints.
- [ ] Text chat never generates an image unless the user explicitly asks.
- [ ] Validate prompt length, image dimensions, step count and request rate on the server.
- [ ] Authenticate every request and enforce per-user quota; client-side-only limits are not sufficient.
- [ ] Handle provider quota exhaustion and service errors without charging or switching to a paid provider.
- [ ] Do not store generated images in a public bucket by default; define private storage, retention and deletion behavior first.
- [ ] Test prompt safety, disallowed content handling, image response integrity, slow network and retry.
- [ ] If reliable quota enforcement/storage/safety cannot be delivered within free constraints, leave feature disabled and mark BLOCKED rather than shipping an unsafe stub.

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
- [ ] Study-memory writes remain denied until a validated write schema/editor is implemented.
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
