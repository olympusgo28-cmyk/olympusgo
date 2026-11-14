# Review of the last week's work, by role (11 Nov 2026)

Covers the four commits of 9 Nov (account deletion, sign-in redesign, UAT checklist, type roles with Settings and the 10-year audit rule) and the uncommitted Sport Passport, Lessons tab and Account Centre removal. Read-only: nothing in the app or database was changed. Security and unbuilt features are in `docs/audits/2026-11-10/REPORT.md`; this file adds the design and legal reviews and a role-by-role summary.

"Verified" means re-checked after the review by reading the file or running the check. "Reviewer" means one reviewer reported it with file and line.

## QA: what was run today

| Check | Result |
| --- | --- |
| `dart format` on app, tests, theme package, admin | Clean |
| `flutter analyze` on app, theme package, admin | No issues |
| `flutter test` | 397 pass, 59 skipped (the local-stack tests), 0 fail |
| `supabase test db` (56 files) | 2,468 of 2,469 pass. The one failure, file 34 "no reconciliation in a day raises an alert", depends on the local stack's own 02:30 reconciliation run; it passes on a fresh database |
| CI on PR #1 at 29be8c4 | secrets, flutter, database, functions, integration: all green |

Not run: the app on Android, any real device, any hosted project. The uncommitted work has not been through CI.

## Architect: how the work was done

- **Kept to the process:** plans before the deletion, audit-retention and Account Centre changes; an independent review of each, which found real problems every time (other players' attendance records, the Lessons count, private values on Settings); tests with each change.
- **Not kept:** the Sport Passport and Account Centre work is uncommitted and unpushed; PR #1 has no human review, and the money and deletion changes need two; branch protection is off.
- **Doc drift:** `phase-1-status.md`, `BUILD_PLAN.md` and `AGENTS.md` describe things that are no longer true (see the 10 Nov report). `docs/DESIGN_SYSTEM.md:118` says group headers sit on the grey page and the link colour is #C94A00; the code has headers on white and #A83B00.
- **Decision trail:** Q257 to Q265 record this week's choices; Q258 to Q263 and the keep-lists in Q264 and Q265 still wait for the owner.

## Security reviewer

Unchanged from 10 Nov and **not fixed**: one critical (profile photos leak session tokens), three high (contact change needs only the session; three accounts can hide any content; the seed's staff password), and the mediums listed there.

One interaction to plan for: fixing "Face ID accepts the passcode" (S7) by requiring biometrics would lock a phone with no face or fingerprint out of Payment methods, Identity check and Delete account, which now sit behind `FaceIdLock`.

## UI and motion designer: the new screens

| # | Finding | Size | How sure |
| --- | --- | --- | --- |
| D1 | **Errors look like empty content on money and delete screens.** Payment methods says "No card saved" while loading and when the load fails (`earnings_screens.dart:784`). Delete account drops its refund, children and points warnings if their loads fail. A failed schedule load shows "Nothing joined yet". | Larger | Payment methods Verified; rest Reviewer |
| D2 | **Endless spinners with no retry** on Identity check, Earnings, Receipts, Payout account, Sports and levels. | Quick each | Reviewer |
| D3 | **Face ID lock gives no reason.** While asking, only a title and spinner show. Cancel, no biometrics and a mismatch all read "Face ID didn't match". A failed check in the delete sheet closes it silently. Payout account has its own copy with different words. | Larger | Reviewer |
| D4 | **Profile header squeezes the name.** Three 44 px buttons and the avatar leave about 105 px for the name at 375 wide, so it wraps to two or three lines. | Quick | Reviewer |
| D5 | **Large text breaks the older parts.** The header title, the 54 px buttons, the week strip and schedule rows are fixed-height, one line. | Larger | Reviewer |
| D6 | **Row labels differ from the screens they open:** Bookings → My schedule; Account privacy → Privacy and safety; Guardian controls → My children; Blocked accounts → Blocked players; Earnings and receipts → Earnings; My QR code → Share profile; Time management → a dead end. | Quick | Reviewer |
| D7 | **Receipts and Payout account are buried** at the bottom of Earnings, and Settings search can't find "lessons", "club", "points", "Face ID" or "email". | Quick | Reviewer |
| D8 | **Contrast and tap targets.** Search placeholder 3.4:1 on white (needs 4.5); "Learn more" is one text line tall; today's tile on the week strip 3.6:1. | Quick | Reviewer |
| D9 | **Two looks side by side.** Settings rows tint on press, older rows dim and shrink; 56 px rows with bare icons against 64 px rows with tinted tiles; breadcrumbs only from the third level. | Larger | Reviewer |
| D10 | **Reduced motion is honoured on 12 routes of about 250.** The rest use the plain iOS slide (`app_router.dart:179-180`), including Delete account and Payment methods. | Quick | Verified (238 `page(` against 12 `motionPage(`) |
| D11 | **Icons reused:** the namecard is both Sport Passport and Account information; three shields in Settings; two trophies and two racquets in Sport Passport. | Quick | Reviewer |
| D12 | **Feedback that misleads.** Every toast lasts 2 seconds whatever its length. "Email me a copy" says "Sent to your email" and sends nothing. The closing screen shows a success tick. | Quick | Reviewer |

**Worth keeping:** `SettingsRow` (stacks at large text, skeleton, semantics, focus ring), `MotionPage`, skeletons with Try again on Edit profile and Account information, the live username check, no raw colours or sizes in any of the new files.

## Legal analyst: promises against practice

Not legal advice; a brief for a qualified lawyer. No law is stated here as fact.

**Public terms and privacy pages** (`share_site/terms/index.html`, `share_site/privacy/index.html`, dated 25 Oct) are out of date:

| Promise | Practice | How sure |
| --- | --- | --- |
| A Wallet you can withdraw to your bank (terms :42, :48) | "No Wallet, ever" (DECISIONS G2) | Verified |
| "Download or delete your account" in Account Centre (privacy :72; terms :26) | No data export exists; the Account Centre was removed this week | Verified |
| "Crash reports and basic usage" are collected (privacy :29) | No crash or analytics tool is installed | Verified |
| Providers listed: Supabase, Twilio, payments | Code also uses Resend, Google (push, fonts), Anthropic, OpenStreetMap, Netlify | Reviewer |
| Shop: cancel until shipped, 7-day returns, 14-day delivery | App and server: collect-only, final once collected | Reviewer |
| Reports and notices answered in 24 hours | A notice only inserts a row; no timer and no staff inbox (Q227) | Reviewer |
| "After 30 days your data is erased" (delete screen) | Money records, reports, consents and the saved card record are kept; audit for 10 years | Card record Verified; rest Reviewer |

**Not told to users anywhere:** the 10-year audit retention; staff viewing coach licence files; the session staying valid after log-out with a saved tile; a parent being able to read a child's chat.

**Usual legal build items, and their state:**

| Item | State |
| --- | --- |
| Acceptance of terms recorded with version and time | Missing: a text line at sign-in only |
| Re-acceptance when terms change | Missing |
| Parental consent proof | Partly: link ids, status and time; no wording version or adult check (G1 not built) |
| Data export | Missing, and promised |
| Named operator, address, governing law, privacy contact | Missing from both pages |
| Breach process | Missing |
| Cross-border transfer disclosure | Partly: only on the AI consent screen; no hosted region chosen (Q40) |
| Apple privacy manifest, store privacy labels, age rating | Not in the repo |
| Saved card record (`payment_customers`) on erase | Not erased; the Stripe customer is not deleted |
| Refund rule shown before paying | Exists, stored with the payment |
| In-app account deletion | Exists |

**Questions for the lawyer, most blocking first:** holding money (Q1, Q63); who the seller is for Meets, lessons and shop; whether a self-declared birthday and unverified parent link are enough for children (Q112, Q123); retention periods (Q14, Q264); overseas transfers and the provider list (Q188, Q189, Q40); whether "by continuing" counts as acceptance; filming and reports (Q198, Q211, Q213); marketing and service texts; Malaysia and New Zealand (Q7); access, correction and breach duties.

## What each role would do next

1. **Security:** fix the photo token leak, then the contact-change step-up, before anything else ships.
2. **Flutter and QA:** commit and push the Sport Passport work so CI covers it.
3. **Design:** D1 and D2 (false "empty" states and endless spinners), then D6 and D10, which are quick.
4. **Legal:** take down or correct the Wallet, data-download and Account Centre lines on the public pages; start `docs/legal/` with a data map.
5. **Owner:** answer Q258 to Q265; get two human reviewers on PR #1; choose the hosted project (Q40).
