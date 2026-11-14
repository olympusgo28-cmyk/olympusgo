# OlympusGO whole-app audit — 5 November 2026

OlympusGO has broad working local functionality, but it is not yet demonstrated to be launch-ready. Core workflows and server protections have substantial passing coverage. The largest immediate issues are large-text accessibility, a direct-route crash, misleading deletion UX, and unfinished real-service integrations.

This is an audit, not a claim that every possible bug has been found. Application behavior was not changed. All service actions used the local development stack; no hosted project or real payment/provider was used.

## What was actually run

- iPhone 17 simulator: compiled and launched the real app in signed-in demo mode; visually confirmed Home. Native automation did not reliably activate app controls, so do not read this as a complete manual phone walkthrough.
- Staff web app: launched against localhost and visually confirmed login. No fresh authenticated staff-browser walkthrough was completed.
- Flutter analysis: no issues. Base tests: 245 passed, 55 initially skipped. Those 55 local API tests were then run sequentially with local functions and all passed.
- Admin plus money/match packages: 49 tests passed. Deno: 115 tests passed; format and lint passed across 35 files.
- Local database: 2,330 pgTAP assertions across 54 files passed against the existing local database. No destructive database reset was performed, so clean-install migration replay was not re-proven.
- SQL lint: eight reported diagnostics, all in pgTAP extension functions in this run. No public/private application function error was reported. This is not a clean all-schema lint result.
- Analysis worker: 74 tests passed in a freshly executed test container; two nonfatal pytest cache-permission warnings. Host Python lacked OpenCV, so the documented container was used.
- Screen sweep: 251 existing route cases plus 16 additional newer-feature cases at 402×874 logical pixels. Combined: 242 OK, 20 redirected, 5 error rows. Four error rows were missing native-plugin test implementations/delayed errors; one was the phone-verification crash. OK means opened without a recorded exception, not that every button or data state works.
- Accessibility stress: 320×568 with 200% text. The screenshot-enabled final run recorded overflow in 220 of 251 route visits. Shared components account for many repeats; this is not 220 unique bugs. Examples are saved below.

Font caveat: early screenshots used Flutter test placeholder glyphs and produced false overflow findings. Those were discarded. Re-running with actual cached Baloo/Nunito fonts cleared all normal-size overflow rows. A less-used medium font weight was absent from the cache and can still appear as boxes in some test screenshots; do not treat those boxes as a product bug. Native camera/keychain errors are test-harness limitations, not proven device failures.

Not completed: physical devices, Android, every role/state/button, VoiceOver/TalkBack interaction, every dark screen, clean migration replay, standalone race scripts, hosted staging/CI history, real SMS/push/Stripe/AI/video providers, full manual staff actions, and production performance/load. The private design boards were not accessed. Local API tests include their own concurrency/replay cases but do not replace all standalone race scripts.

## Suggested order

1. Fix A01–A04 and make the screen audit fail on real regressions (A07–A09).
2. Complete one reliable player journey: discover → join → pay → check in → score → receipt/refund, including network interruption and assistive technology.
3. Complete real provider integration and the required human reviews. Keep AI/video/payment flags closed until their gates pass.
4. Improve navigation, lifecycle recovery, reconciliation clarity and owner/admin operations in small tickets.

Priorities below are proposed audit priorities, not new product rules. Deferred features such as court booking, leagues and children's posts are not mislabeled as regressions. Existing open questions are referenced rather than inventing answers.

## Feature inventory

### Account and onboarding — Implemented; local tests

Built: Phone/email/username login, codes, saved accounts, biometric vault, recovery request, name, birthday, sports, levels and username.

Limits: Real SMS/email delivery and real-device biometric recovery remain unproven.

Source: `lib/features/auth; lib/features/onboarding; docs/features/phase-1-status.md`

### Parents and minors — Implemented; local tests

Built: Restricted mode, parent codes, linked children, consent and server age restrictions.

Limits: Human privacy/security review and complete device journeys remain necessary.

Source: `lib/features/guardian; test/supabase_safety_local_test.dart`

### Home and navigation — Implemented; rendered

Built: Five tabs, eight category tiles, search, saved items, schedule shortcuts and category editing.

Limits: Demo promotes creator challenges that are not a live release feature.

Source: `lib/features/home; lib/features/shell`

### Discover and search — Implemented; rendered

Built: Player/activity discovery, filters, map, coarse location and search results.

Limits: Production map service and denied-location/offline device walkthroughs remain.

Source: `lib/features/discover; docs/features/phase-2-status.md`

### Profile and Passport — Implemented; partial scope

Built: Profile editing, sports, rating, sessions, history chart, badges, gear, follows, QR sharing and leaderboards.

Limits: Detailed point-by-point sport statistics are not built.

Source: `lib/features/profile; lib/features/social; docs/features/phase-3-status.md`

### Meets — Implemented; local journeys

Built: Create, discover, join, leave, waitlist, guests, repeat sessions, host roster, check-in, attendance and recap.

Limits: Paid flows use a local payment stand-in; paid guest additions have limits.

Source: `lib/features/play; test/supabase_play_local_test.dart`

### Scoring and ratings — Implemented; local tests

Built: Round generation, presets, score submission/confirmation/disputes, ratings and history.

Limits: No point-by-point scoring; identical rematches have documented limits.

Source: `packages/match_engine; test/score_rules_test.dart; docs/features/phase-3-status.md`

### Tournaments and events — Implemented; partial scope

Built: Tournament creation, entries/partners, draws, groups/knockout, scoring/results; events, tickets, door checks and cancellations.

Limits: Paid tournament entry remains closed.

Source: `test/supabase_tournament_local_test.dart; docs/features/phase-4a-status.md`

### Clubs and teams — Implemented; local journeys

Built: Creation, membership requests, roles/permissions, bans, audit, ownership, announcements, chats, rosters, fixtures and lineups.

Limits: Leagues are not defined/built; group chat does not have all DM retry behavior.

Source: `lib/features/clubs; test/supabase_clubs_local_test.dart; docs/features/phase-2-status.md`

### Inbox and messaging — Implemented; partial delivery

Built: Direct messages, optimistic send/retry/delete, group messages, reporting and blocking.

Limits: Push queue/settings exist, but documented phone delivery is not connected.

Source: `lib/features/inbox; supabase/functions/send-push; docs/features/phase-2-status.md`

### Payments and earnings — Built behind stand-in

Built: Quotes, holds, webhook confirmation, balanced ledger, refunds, releases, payouts, reconciliation and receipts.

Limits: Hosted app cannot collect; Stripe UI, onboarding and real test-mode validation incomplete.

Source: `lib/features/play/data/payment_gateway.dart; docs/features/phase-4a-status.md`

### Shop — Implemented; checkout gated

Built: Partner catalogue, products, per-shop carts, quotes, stock, checkout, cancel, collect, report and owner mark-ready.

Limits: No player marketplace/delivery/returns/live shopping; real payments unavailable.

Source: `lib/features/shop; test/supabase_shop_local_test.dart; docs/features/phase-4b-status.md`

### Points and vouchers — Implemented; gated

Built: Points lots/expiry/redemption, voucher wallet, single discount per item, campaign progress and organizer milestones.

Limits: Earning flags/config and partner funding unresolved; court voucher redemption deferred.

Source: `lib/features/game; test/supabase_voucher_local_test.dart; docs/features/phase-4d-status.md`

### Academies and lessons — Implemented; local journeys

Built: Academy setup, verification, coaches/invitations, students, classes, trials, single lessons, one-to-one, attendance, make-ups and assessments.

Limits: Monthly/term billing and coach pay remain direct; paid lessons use stand-in.

Source: `lib/features/academy; test/supabase_lesson_local_test.dart; docs/features/phase-4c-status.md`

### Services — Implemented; local tests

Built: Partner list and confirmed referral to external partner pages.

Limits: Partner coverage/operations must be completed; no medical workflow inferred.

Source: `lib/features/services; docs/features/phase-4c-status.md`

### Venues — Browse implemented; booking deferred

Built: Venue list/detail and directions; prototype booking routes exist.

Limits: Court booking is explicitly deferred by Q25, not a regression.

Source: `lib/features/venues; docs/features/phase-4b-status.md`

### Fitness — Implemented; flag off by default

Built: Exercise catalogue, programs/templates, workout sets/rest timer, persistent draft, log, personal bests and calculators.

Limits: Coach review, videos, background timer and stronger retry recovery remain.

Source: `lib/features/fitness; test/supabase_fitness_local_test.dart; docs/features/phase-5a-status.md`

### AI plans — Built behind stand-in

Built: Adult consent, plan request, validation, editable program and withdrawal.

Limits: Real model/schema/quality/cost and provider privacy terms are unproven.

Source: `supabase/functions/ai-plan; docs/features/phase-5b-status.md`

### Video analysis — Built; accuracy unproven

Built: Private upload, parent consent, corner marking, job/report, heatmap, keep/delete and purge.

Limits: Singles only; no real-match accuracy proof, doubles or rally report; flags remain off.

Source: `lib/features/analysis; workers/analysis; docs/features/phase-5c-status.md`

### Video feed — Built behind stand-ins

Built: Adult upload, audience/caption, checks/review states, feed, reactions, report, retry and delete.

Limits: No real checker/video host; metadata stripping and child-in-adult-post policy unresolved.

Source: `lib/features/feed; test/supabase_feed_local_test.dart; docs/features/phase-5d-status.md`

### Settings and safety — Implemented; deletion incomplete

Built: Notifications/privacy, blocked users, reports/cases, help/legal, country and account changes.

Limits: Deletion is a support-only message after a deletion-style confirmation; language options mostly coming soon.

Source: `lib/features/settings; lib/features/safety`

### Staff admin — Implemented; tests + login rendered

Built: Roles/MFA; reports, first posts, users, scores, sports/rules, catalogue, verification, services, campaigns, analysis, payments, orders, lessons and audit.

Limits: Only login was manually rendered this session; authenticated actions covered by tests/source, not a fresh full browser walkthrough.

Source: `admin/lib/main.dart; admin/test`

### Public web and partner tools — Partial

Built: Static share landing, deep-link fallback, privacy and terms pages in share_site. Owner tools largely reside in mobile.

Limits: No separate Next.js public app or dedicated academy/partner web application was found in this checkout.

Source: `share_site; README.md; docs/ARCHITECTURE.md`


## Prioritized findings and improvements

Confirmed bugs, code findings, documented gaps and subjective recommendations are explicitly distinguished. Validate documented gaps against the deployment before treating them as live incidents.

### A01 · P1 · Shared headers and layouts fail at 200% text

**Confirmed bug · Accessibility**

At 320×568 logical pixels and 200% text, 220 of 251 route visits recorded RenderFlex overflow. Many share the same header defect; these are not 220 independent bugs. Account Centre visibly breaks labels into individual letters.

**Improve:** Make headers, rows and bottom controls grow/wrap; avoid fixed heights for text. Recheck at 320/375/402 widths with 100/150/200% text.

Evidence: `lib/core/widgets/og_kit.dart:112; evidence/olympus-audit-large-text.tsv; evidence/accountHub-large-text.png`

### A02 · P1 · Phone verification crashes without navigation payload

**Confirmed bug · Navigation**

Opening /settings/personal/verify directly produces a null-check exception. Router casts s.extra! to String.

**Improve:** Guard missing/invalid extra; return to contact-change start with a recovery message. Add direct-link and restoration tests.

Evidence: `lib/core/router/app_router.dart:417; evidence/olympus-audit-final-routes.tsv`

### A03 · P1 · Deletion asks for confirmation before admitting it is unavailable

**Code-confirmed UX defect · Account**

The action asks for Delete with Face ID, then a real backend only shows a toast directing the user to Help. No deletion request is submitted there.

**Improve:** Immediately label this as Request account deletion and open the real support path, or implement the approved deletion lifecycle before offering Delete.

Evidence: `lib/features/settings/presentation/account_screens.dart:480; lib/features/settings/presentation/account_screens.dart:501`

### A04 · P1 · Font failure can prevent first app frame

**Code-confirmed risk · Startup**

main awaits GoogleFonts.pendingFonts before runApp, with a timeout handler but no error handler. A fast network/font failure can propagate. Fresh offline startup was not reproduced on a wiped device.

**Improve:** Bundle all used fonts; let startup render a fallback on any font error. Test fresh-install airplane mode.

Evidence: `lib/main.dart:34; pubspec.yaml; docs/OPEN_QUESTIONS.md Q34`

### A05 · P2 · Venue times are displayed in device timezone

**Code-confirmed defect · Dates**

Activity and competition repositories call toLocal(); this differs from the venue-time requirement and misleads travelers.

**Improve:** Use venue/activity timezone consistently and show the zone when helpful. Test Singapore activity viewed in New Zealand and across DST.

Evidence: `lib/features/play/data/play_repository.dart:178; lib/features/play/data/competition_repository.dart:200; AGENTS.md`

### A06 · P2 · Some shared controls/text are below the design minimum

**Code-confirmed defect · Accessibility**

Follow control has height 40; verified tag uses 11 px text; Passport includes 11 px labels. Design minimum is 44 px targets and 12 px text.

**Improve:** Increase hit areas without necessarily enlarging visual pills; raise small type and run semantics/tap-target tests.

Evidence: `lib/core/widgets/og_rows.dart:647; lib/features/settings/presentation/account_screens.dart:92; lib/features/profile/presentation/passport_screen.dart:1308`

### A07 · P1 · Screen sweep can report success despite recorded screen errors

**Test gap · Quality**

The audit replaces FlutterError.onError and writes ERROR rows but never asserts that the error set is empty. The large-text run without screenshots passed despite hundreds of recorded overflows.

**Improve:** Fail on unexpected route errors/overflows; explicitly allow expected redirects and mock native plugins.

Evidence: `test/route_audit_test.dart:112; evidence/olympus-audit-large-text.tsv`

### A08 · P2 · Route sweep misses newer features and depends on external fonts

**Test gap · Quality**

Existing list omits fitness, AI, analysis, videos and match rounds. Without valid font files the sweep used placeholder glyphs and falsely reported 22 overflow routes. Some medium-weight glyphs were still absent in screenshot mode.

**Improve:** Bundle fonts, validate their presence, generate/verify route coverage, and isolate each route to prevent delayed plugin errors being attributed to the next screen.

Evidence: `test/route_audit_routes.dart; test/route_audit_test.dart; evidence/olympus-audit-new-routes.tsv`

### A09 · P1 · Feed API and race suites are absent from explicit CI lists

**Test gap · CI**

CI runs clips but does not list supabase_feed_local_test.dart or feed_races.sh. Default flutter test skips API tests without local variables.

**Improve:** Add feed API tests and the feed race script to required CI jobs, and assert expected integration-test counts.

Evidence: `.github/workflows/ci.yml:73; .github/workflows/ci.yml:125`

### A10 · P2 · Database lint failures are blanket-advisory

**Test gap · CI**

CI uses continue-on-error for all db lint errors. This run reported eight errors inside pgTAP extension helpers, not application-schema errors.

**Improve:** Limit/allowlist known extension or temporary-table diagnostics and fail new public/private function errors.

Evidence: `.github/workflows/ci.yml:77; evidence/olympus-audit-dblint.log`

### A11 · P1 · Real payment collection is not implemented end to end

**Release gap · Payments**

Hosted canCollect is false. Successful local money journeys use a stand-in, not Stripe test mode.

**Improve:** Complete approved card/hosted payment UX, Connect onboarding and saved-method flows; validate webhook replay, late success, refunds and reconciliation against the real test provider.

Evidence: `lib/features/play/data/payment_gateway.dart:110; docs/features/phase-4a-status.md`

### A12 · P1 · Push delivery and real code delivery are not proven

**Release gap · Messaging**

Status docs state no push reaches a phone without Firebase; SMS/email real senders remain unproven.

**Improve:** Connect development providers and test foreground/background delivery, deep links, opt-outs, quiet hours, token refresh and resend failures on devices.

Evidence: `docs/features/phase-1-status.md; docs/features/phase-2-status.md; supabase/functions/send-push`

### A13 · P1 · Real moderation and video hosting are missing

**Release gap · Video feed**

Hosted posts cannot go live successfully without selected providers. Matching accuracy/outages are unmeasured.

**Improve:** Keep flag off; implement real adapters, failure/retry monitoring and operational review before release.

Evidence: `docs/features/phase-5d-status.md; docs/OPEN_QUESTIONS.md Q213–Q214`

### A14 · P1 · Uploaded video location metadata is not removed

**Documented privacy gap · Video feed**

Existing status and Q226 say viewers receive the original file, which may include filming location. No fresh metadata attack was performed.

**Improve:** Strip metadata or re-encode before public delivery; verify with a tagged iPhone sample and inspect the delivered file.

Evidence: `docs/features/phase-5d-status.md; docs/OPEN_QUESTIONS.md Q226`

### A15 · P1 · Child appearance in adult posts has no reliable control

**Decision needed · Video feed**

After first-post reviews, the documented controls are uploader attestation and reports, not automatic age detection.

**Improve:** Resolve Q212 with the owner and safety/legal reviewers before enabling public feed; specify moderation escalation and response ownership.

Evidence: `docs/OPEN_QUESTIONS.md Q212; docs/features/phase-5d-status.md`

### A16 · P1 · Movement reports are not validated on real matches

**Release gap · Video analysis**

Worker tests pass but real-match accuracy is unproven; changing ends may cause tracking of the opponent.

**Improve:** Validate a labeled real-clip set, detect/refuse end changes, expose confidence/limitations, and keep the feature gated until accuracy is acceptable.

Evidence: `docs/features/phase-5c-status.md; workers/analysis/olympus_worker/metrics.py`

### A17 · P2 · Long videos are rejected after uploading; uploads need app open

**Documented UX gap · Uploads**

Client length is a maximum placeholder and worker validates later. Closing the app interrupts upload.

**Improve:** Measure duration/format before upload, show size/time expectations, support resumable uploads or clearly communicate foreground requirement.

Evidence: `docs/features/phase-5c-status.md; docs/features/phase-5d-status.md`

### A18 · P1 · Court corners cannot be adjusted with a screen reader

**Accessibility gap · Video analysis**

Documented corner dots are readable but drag-only for moving.

**Improve:** Offer selected-corner nudge controls or numeric adjustment with spoken feedback; verify using VoiceOver/TalkBack.

Evidence: `docs/features/phase-5c-status.md; lib/features/analysis/presentation`

### A19 · P1 · Real model response and data-transfer terms unvalidated

**Release gap · AI plans**

Adapter is tested with a fake server; schema, quality, latency, token cost and account terms have not met the real provider.

**Improve:** Run consented development test cases, validate schema/caps and quality, then obtain required review before enabling.

Evidence: `docs/features/phase-5b-status.md; docs/OPEN_QUESTIONS.md Q188–Q190`

### A20 · P2 · In-progress plan does not survive app closure

**Documented UX gap · AI plans**

Returning within a session works, but app closure loses the pending request and a retry can consume another daily plan.

**Improve:** Persist job/request id, recover status on launch and show quota usage before retry.

Evidence: `docs/features/phase-5b-status.md`

### A21 · P2 · Rest timer and save recovery are incomplete

**Documented UX gap · Fitness**

Timer resets on leaving screen and does not notify while closed; finished unsaved workouts need manual retry; server-rejected workouts may only be discarded.

**Improve:** Persist timer deadline, clarify notification behavior, retain editable rejected drafts and provide safe automatic retry/status.

Evidence: `docs/features/phase-5a-status.md`

### A22 · P1 · Exercise guidance needs qualified review

**Release gap · Fitness**

Catalogue, minor suitability and templates have not been coach-reviewed.

**Improve:** Review and version exercise guidance, suitability and templates; do not describe current templates as validated.

Evidence: `docs/features/phase-5a-status.md`

### A23 · P2 · Shop totals and earnings detail rows do not reconcile visually

**Documented UX gap · Earnings**

Shop amounts are included in totals but activity-only rows omit shop sales.

**Improve:** Add shop/lesson source rows and filters; every total should reconcile to visible/exportable entries.

Evidence: `docs/features/phase-4b-status.md; lib/features/earnings`

### A24 · P2 · Discount changes the Items line when commission is on top

**Documented UX gap · Vouchers**

Total is documented as correct, but item subtotal shifts because commission follows discounted price.

**Improve:** Display item price, discount, commission and final total separately with consistent receipts.

Evidence: `docs/features/phase-4d-status.md`

### A25 · P2 · Promotional hero competes with the main player task

**UX recommendation · Home**

Home screenshot devotes much of the first screen to a creator campaign before categories; Play also starts with hosting promotion. This is a design judgement, not a functional failure.

**Improve:** Prioritize next session and Find a game; make hosting secondary for non-hosts and label demo-only offers. Test completion time with new players.

Evidence: `evidence/home.png; lib/features/play/presentation/play_screen.dart`

### A26 · P2 · Broad information architecture needs clearer entry points

**UX recommendation · Navigation**

Play, Game, Fitness, Profile and Account Centre divide related sessions, rewards, progress and settings.

**Improve:** Use task-oriented labels and consistent shortcuts for My sessions, My progress and Manage; test whether players can find each without instruction.

Evidence: `lib/core/router/routes.dart; evidence/home.png; evidence/profile.png`

### A27 · P2 · Make empty and disabled states explain the next action

**UX recommendation · Discovery**

Several categories are gated; demo visibility is richer than connected-app availability.

**Improve:** For each flag-off/empty/permission/offline state say why and offer a useful alternative; do not imply a transaction can be completed.

Evidence: `lib/features/discover/presentation/coming_screens.dart; docs/features/*status.md`

### A28 · P2 · Long creation flows need explicit recovery testing

**UX recommendation · Forms**

Multiple-step Meet, tournament, club and academy forms exist; process-death recovery for all drafts was not verified.

**Improve:** Test keyboard overlap, validation, back navigation, destructive exit confirmation and draft restoration; retain entered values on recoverable failure.

Evidence: `lib/features/play/presentation/create_meet_screens.dart; lib/features/academy/presentation`

### A29 · P2 · Raw colors bypass centralized design tokens

**Design debt · Theme**

Raw Color literals remain in profile, shop, group chat and other screens even though design tests cover shared tokens.

**Improve:** Move semantic colors into shared tokens, then compare full screens in both themes and with high text scale.

Evidence: `lib/features/profile/presentation/profile_screen.dart:27; lib/features/shop/presentation/shop_screens.dart:87`

### A30 · P2 · Map hosting is still the public OpenStreetMap tile endpoint

**Release gap · Maps**

Find screen requests tile.openstreetmap.org; status docs explicitly flag production suitability.

**Improve:** Choose and configure the approved production tile provider, attribution, caching and quota/failure handling.

Evidence: `lib/features/discover/presentation/find_screen.dart:325; docs/features/phase-2-status.md`

### A31 · P1 · Required human reviews and device release checks remain unproven

**Release gap · Governance**

Status docs report agent reviews but no required human approvals. This audit did not verify app-store builds or hosted deployments.

**Improve:** Complete the repository-required security/privacy/architecture reviews and two human money reviews; run real iOS/Android camera, biometrics, notification and payment checks.

Evidence: `AGENTS.md; docs/features/phase-1-status.md; docs/features/phase-4a-status.md`

### A32 · P2 · README and operational instructions lag the implementation

**Documentation debt · Project**

README describes later phases as coming soon; current code reaches Phase 5d. It names a different hosted project than Env default.

**Improve:** Document actual feature flags, implemented scope and local commands; remove ambiguous hosted setup instructions and nominate the authoritative development project. Do not use either hosted project during this audit.

Evidence: `README.md; lib/core/config/env.dart; docs/features/phase-5d-status.md`

### A33 · P2 · Data export and automated account lifecycle are unfinished

**Documented gap · Privacy**

Status docs state support deletion and no player export; video deletion must coordinate with pending checks.

**Improve:** Implement the approved lifecycle across money, guardians, workouts, clips, posts and storage with export/download and deletion-status visibility.

Evidence: `docs/features/phase-5a-status.md; docs/OPEN_QUESTIONS.md Q208`

### A34 · P2 · Long histories need pagination and useful filters

**UX recommendation · Lists**

Workout log documents latest-100 limit; feed documents 50-post list without paging.

**Improve:** Add cursor pagination, clear date filters and count wording that distinguishes loaded rows from total records.

Evidence: `docs/features/phase-5a-status.md; docs/OPEN_QUESTIONS.md Q217`

### A35 · P2 · Campaign editor supports only one quest

**Documented gap · Admin**

Database and player app support multiple quests but staff editor creates one.

**Improve:** Support adding/reordering/removing quest definitions with validation and a player-view preview.

Evidence: `docs/features/phase-4d-status.md; admin/lib/features/game/campaigns_screen.dart`

### A36 · P2 · Error recovery and service health need a cross-feature review

**UX recommendation · Support**

Many individual failure-state tests exist, but this session did not exercise every offline/process-death/error combination on devices.

**Improve:** Standardize retry, saved/pending state and support references; run a device matrix for network loss during join/pay/save/upload without exposing personal data in logs.

Evidence: `docs/TESTING.md; test/pay_flow_test.dart; test/fitness_screens_test.dart`

## Evidence and reproduction

- [Normal-size route results](evidence/olympus-audit-final-routes.tsv)
- [Additional newer routes](evidence/olympus-audit-new-routes.tsv)
- [Large-text route results](evidence/olympus-audit-large-text.tsv)
- [Large-text Account Centre](evidence/accountHub-large-text.png)
- [Normal Account Centre](evidence/accountHub.png)
- [Large-text Scan](evidence/scan-large-text.png)
- [Local API results](evidence/olympus-audit-api.log)
- [Database results](evidence/olympus-audit-pgtap.log)
- [Worker results](evidence/olympus-audit-worker-run.log)

Reproduce A02 by navigating directly to `/settings/personal/verify` in an authenticated app without `extra`. Reproduce A01 by running the route audit at logical size 320×568 and wrapping MaterialApp content in a MediaQuery with `TextScaler.linear(2)`, with real fonts loaded. The temporary audit harnesses are retained in `evidence/` as `.dart.txt` files, outside test discovery. Copy beside the existing route test to run, and provide `AUDIT_FONTS`, `AUDIT_OUT` and optionally `AUDIT_SHOTS`. They reuse `route_audit_routes.dart`. These harnesses record errors; they are evidence collectors, not corrected pass/fail regression tests.

No production changes, product-rule changes, commits or feature fixes were made. The local simulator, development database and app services were started for this audit. The audit does not satisfy required independent human approvals.
