# Security and unbuilt-features audit, 10 Nov 2026

Branch `checklist-phase-0-1` at 29be8c4 plus the uncommitted Sport Passport and Settings work. Read-only: nothing in the app or database was changed. Three independent reviews (unbuilt features; backend; apps, admin and CI), then the top findings were re-checked by hand and with read-only catalogue queries on the local database.

**How sure each finding is.** "Verified" means re-checked after the review, by reading the code path or by a query or rolled-back test on the local database. "Reviewer" means one reviewer reported it with file and line and it was not re-checked. Nothing was tested against a hosted project or a real device.

## Part 1. Security findings, most severe first

| # | Severity | Finding | How sure |
| --- | --- | --- | --- |
| S1 | **Critical**, **fixed 11 Nov (Q267)** | **Profile photos leak session tokens, leading to account takeover.** Fixed on both sides: the database accepts only the owner's own file path with no host (`20261115090000_avatar_own_file_only.sql`), and the app builds the address from its own project URL and fetches nothing else (`lib/core/avatar_address.dart`). Original finding: The app attaches the viewer's session token to every profile-photo request, whatever host the address points to (`lib/core/widgets/avatar.dart:44-50, 86-89`). The server lets a player set `profiles.avatar_url` to any text (update policy in `20261013120000_phase1_accounts.sql:119`; `authenticated` holds UPDATE on the column; no check or trigger). A player who points their photo at their own server receives the token of everyone whose app shows it (search, chat, connections, scan), minors included. | Verified: code read, and a rolled-back update as a signed-in player was accepted with `https://attacker.example/x.png` |
| S2 | **High**, **fixed 11 Nov (Q268)** | **Changing the login mobile or email needs only the current session.** Fixed: a change now needs a code to the other contact first (`20261116090000_contact_step_up.sql`, `resolve-login` `step_up_send` / `step_up_verify`), the old contact is alerted, a trigger on `auth.users` refuses any change to a player's Auth email, password or phone, and Auth's send-email hook refuses every send. Two further routes were proven and closed on the way: a password set through Supabase Auth directly, and guessing Auth's own email code for the internal address. Original finding: `resolve-login` `contact_verify` (`supabase/functions/resolve-login/index.ts:183-203`) takes the caller's token and a code sent to the *new* contact. No code to the existing contact, no recent sign-in, no Face ID on the screens. With S1, or a briefly unlocked phone, a takeover becomes permanent. A session can also set a password or email on its own Auth user directly. | Verified (function read); the direct-Auth part is Reviewer |
| S3 | **High** | **Three accounts can hide any content.** Report insert policies check only `reporter_id = auth.uid()`; `private.report_to_case` hides the target once `moderation.auto_hide_reports` (3) distinct accounts report it, without checking the reporters can see it. Message ids are sequential, and a bulk insert counts as one request against the rate limit. Three accounts could hide profiles, Meets, clubs, listings and private messages across the platform and flood the staff queue. | Verified: policies, setting and function body read from the local database |
| S4 | **High if it ever reaches a hosted project** | **The seed creates a top-level staff account with a password written in the file** (`supabase/seed.sql:34-49`), who enrols their own authenticator on first sign-in. Running the seed against a hosted project would hand out full admin. More generally, a staff password alone is enough until the real person enrols. | Verified (seed read) |
| S5 | Medium | **Text-message abuse and targeted lock-out in sign-in.** A code can be sent to any number worldwide (5 per number and 20 per IP per 15 minutes; no country allow-list, no spend cap, no bot check). Six wrong codes lock any mobile, email or username for 15 minutes, repeatably, with no per-IP limit on verify. The hash pepper falls back to an empty string (`index.ts:23`). | Reviewer |
| S6 | Medium | **The adult-to-minor message rule is checked only when a chat is opened** (`open_direct_conversation`), not on each message, so a chat continues after one side turns 18 or a parent link ends. `club_invite` can push a notification with any club name to any user, including minors and people who blocked the sender. `tournament_register`'s partner has no minor check. | Reviewer |
| S7 | Medium | **"Face ID" accepts the phone passcode.** `BiometricVault.authenticate` (`biometric_vault.dart:186`) does not pass `biometricOnly`, though the comment above says a passcode must not count. On Android the saved-account token has no biometric binding at all. Anyone who knows the PIN can open a saved account, payment methods, payouts and Delete account. | Verified (no `biometricOnly` in the call) |
| S8 | Medium | **Sessions never end.** Log-out with a saved tile does not end the server session; `supabase/config.toml` sets no session time limit or inactivity limit; a ban or suspension does not revoke sessions. A lost phone's tile stays valid indefinitely. | Verified for the config; rest Reviewer |
| S9 | Medium | **Chat photos can be any outside web address** (`group_messages.photo_url` is unchecked; the app loads anything starting with `http`). A member can post unmoderated outside images into club chats, including ones with children, and collect viewers' IP addresses. | Reviewer |
| S10 | Medium | **The request gate and rate limits have gaps.** The gate covers the database API only, so a suspended or closing account can still upload to Storage and call `save-card`. `/messages`, `/group_messages`, `/follows` and `club_for_code` have no rate rule; rules match POST only. On a hosted project GraphQL is on by default and would bypass path rules (it is not installed locally). | Reviewer; GraphQL absence locally Verified |
| S11 | Medium | **Android release builds are signed with the debug key** (`android/app/build.gradle.kts:36`), and `allowBackup` is left at its default (on). | Verified |
| S12 | Medium | **Supply-chain and CI checks are thin.** The CI secrets check greps four folders (not `admin/`, `packages/`, `workers/`, `test/`) for a few patterns; third-party actions are pinned by tag, not commit; `flutter pub get` does not enforce the lockfile; server functions import `supabase-js@2` by major version with no lockfile; the deletion race script is not run in CI. | Verified for the grep and imports; rest Reviewer |
| S13 | Low | No file-type allow-list on the `avatars` and `chat-photos` buckets (Verified: `mime=any`). `app_settings` is readable without signing in, including the payout second-approval threshold (Verified). `.env`, `.env.local` and `supabase/functions/.env` are not git-ignored, though CLAUDE.md says so (Verified; none exist). Release builds print server error text. `env.dart` defaults to a hosted project URL, and a build with no key ships a working demo app. Admin web keeps its session in browser storage with no idle limit or CSP. Share links use a `netlify.app` name that could lapse. `send-push` compares its key without constant time. The analysis worker image floats on `python:3.12-slim`. 81 helper functions in the `private` schema are executable by signed-out callers; the schema is not exposed through the API, so this is defence in depth only (Verified). | Mixed, as marked |

### Checked and found sound

- **Catalogue (Verified on the local database):** all 162 public tables have RLS on; all 592 security-definer functions pin `search_path`; no table is writable by a signed-out caller; no write policy uses a literal `true`; the one public view uses `security_invoker`; all five storage buckets are private.
- **Secrets (Verified):** no key files tracked; no live keys, private keys or JWTs anywhere in git history; no package advisories for the app or admin app.
- **Reviewer:** about 80 sampled RPCs across money, shop, lessons, clubs, tournaments, academy and guardians check ownership or role. Every `staff_*` function needs a staff row and a second factor. The Stripe webhook verifies its signature and dedupes events. Amounts are computed on the server with idempotency keys. The local stand-ins (`stripe-local`, `feed-local`, `analysis-local`, the fixed sign-in code) are inert on a hosted Supabase project. Sign-in answers the same for known and unknown accounts. `SKIP_FACE_ID`, `DEMO_*` and `localStandIn` cannot be active in a release build against a hosted backend. No URL schemes or web views; no cleartext traffic.

### Not checked

Hosted project settings (Auth, Storage, GraphQL, headers); real devices and Android at run time; the 116 functions patched at migrate time were not read in their final form; money logic beyond the sample; dependency CVEs beyond the pub advisory check; cross-account cache after switching saved accounts.

## Part 2. Not built, partly built, or stand-in only

From the features review, checked against the code by that reviewer (file references are theirs; not re-checked item by item).

| Area | Not built or stand-in | Launch blocker in the docs? |
| --- | --- | --- |
| Sign-in | Real SMS and email delivery: codes are the fixed `123456` on a local stack and the Twilio/Resend senders have never run. No WhatsApp fallback, recycled-number claim, bot check, "log out of all devices" or data export. Account recovery only flips a status. | Gates A/B |
| Minors | Strong guardian verification (G1): no verifier, access window, freeze or spending limit. Minors still appear on public leaderboards with guardian opt-in (Q54). A parent cannot delete a child's account (Q240). | G1, Q233 |
| Payments | No real collection: no Stripe SDK, save-card refuses off a local stack, Connect onboarding untested; lawyer sign-off (Q1) open. Payout second approval is still S$5,000 in code, not the decided S$500 (Q9). No receipts PDF or email, Apple or Google Pay. | Gate C |
| Notifications | Push cannot reach a phone: no Firebase dependency, the app never saves a device token, nothing schedules `send-push`. No email, WhatsApp or Telegram channels. | Gate B |
| Tournaments | Paid entries refused outright (`payments.tournament` is read by nothing). Follow, live card, point-by-point, stats, order of play, court board, ranking points and team entries (TRN-7, TRN-9 to 23, PAS-7) not built. Verified-organizer gate on ratings (Q58) not built. | Gate C for paid entries |
| Play | Geofence check-in (MET-8). The 7 Nov decisions on waitlist notify-all, attendance lock and release, and both losers confirming are not in code. Sport profile statistics are demo-only on a real backend. | No |
| Academy | Fee invoices, paying an invoice, coach pay and academy messages are demo-only. Term credits, the 48-hour Present hold, late-cancel and substitute settings not built. | No |
| Shop and venues | Never-ready auto-cancel, returnless refunds, card-fee points cap, teen parent tap. Staff path for a voided refund on a dead order (Q97/Q138) and hiding `shop_minor` (Q105). Court booking always refuses. | Q97, Q138, Q105 |
| Video and AI | Feed hosting and moderation providers are stand-ins (hosted posts throw). GPS is not stripped from posts (Q226); no orphan-upload sweep (Q134). Analysis accuracy and the real AI call are unproven. | Q226, Q134, Gate F |
| Game | Workout, creator and camera challenges and creator earnings are demo-only. | No |
| Admin web | No support inbox (Q227): help requests land where nobody reads them. No venue codes, fitness catalogue, AI cost or Today page. | Q227 |
| Platform | No hosted project chosen (Q40); no Android build; no crash reporting or log scrubber (P1-13); no `field_registry`, outbox or queue; no `integration_test/` folder; no partner web app; the public site is a static page. Branch protection is off. Time management is a placeholder and Language has no translations. | Q40, Q49, Q112, Gate A |

**Feature flags, all off by default:** `payments.enabled`, `payments.tournament` (unused), `shop.checkout`, `lessons.checkout`, `points.earning`, `game.campaigns`, `game.organizer_rewards`, `campaign.require_paid`, `fitness.enabled`, `fitness.ai_plans`, `video.analysis`, `video.analysis_minors`, `video.feed`, `feed.fake_checks`. Only fitness is purely a switch; the rest wait on a provider, the lawyer or an owner decision.

**The 59 skipped Flutter tests** are the `test/supabase_*_local_test.dart` files, which need a local stack and environment variables. CI's integration job runs them.

### The ten gaps that most block a real launch

1. Real payments (Stripe sheet, test keys, Q1).
2. Real code delivery by SMS and email.
3. A hosted backend (Q40); migrations have never been applied to one.
4. Strong guardian verification (G1).
5. A support inbox for staff (Q227).
6. Push notifications reaching a phone.
7. Shop and money blockers Q97, Q138, Q105.
8. Privacy blockers Q134 and Q226.
9. Outside review, pen test, crash reporting, Android and store builds.
10. The 7 Nov decisions not yet in code.

### Where the docs and the code disagree

- `phase-1-status.md` and `BUILD_PLAN.md` say CI has never run and nothing is pushed; PR #1 has green runs.
- Q233 is marked "built with the default" but no guardian verifier exists.
- `phase-1-status.md` and `phase-5a-status.md` say account deletion is not started or support-only; it is built.
- `UAT_CHECKLIST.md:41` treats `payments.tournament` as a working switch; nothing reads it.
- `AGENTS.md` promises `field_registry`, an outbox and queue, `integration_test/`, a Next.js site and a partner web app; none exist.
- CLAUDE.md says `.env.local` is git-ignored; it is not.
