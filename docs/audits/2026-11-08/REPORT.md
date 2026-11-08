# Account deletion UAT — 8 November 2026

Scope: the in-app account deletion change on branch `checklist-phase-0-1` (migration `20261112090000_account_deletion.sql`, `DeleteAccountScreen`, `AccountClosingScreen`, the router's closing redirect). Everything ran against the local Supabase stack and the iPhone 17 Pro simulator. No hosted project, no real payment provider, no production data. Application code was not changed.

## Verdict

The main journey works: request, immediate hiding and refunds, the closing gate, the 30-day undo, the erase and its "Former player" tombstone. The automated suite passes in full. The UAT still found **two defects that must be fixed before this ships** (the earnings refusal is inverted; a kept account can still be erased by the job), five medium gaps, and a set of low findings and product questions listed below.

## What was run

| Check | Result |
| --- | --- |
| `supabase test db` | 55 files, 2416 assertions, all pass (files 52 and 54 included) |
| `flutter analyze` | No issues |
| `dart format --set-exit-if-changed` (changed Dart) | 20 files, 0 changed |
| `flutter test test/account_deletion_test.dart test/audit_fixes_test.dart` | 12 pass |
| `flutter test test/supabase_deletion_local_test.dart` (real API) | 1 pass, not skipped |
| `supabase/tests/races/deletion_races.sh` | 25 rounds ok; see finding 18 about its control |
| `supabase db lint` | Warnings only, none in the deletion functions |
| API probes with minted user tokens | 40 calls, listed below |
| Simulator walkthrough (iPhone 17 Pro) | Hannah full loop, Aaron refusal, Face ID cancel/no-match, offline |
| Independent code review (subagent, read-only) | 15 findings, folded in below with my confirmation status |

Fixtures were built with the pgTAP helpers loaded into the local database (schema `t`): a club owned by Aaron; Meet M1 hosted by Aaron with Hannah paid S$8.00 (+S$2.00 fee); Meet M2 hosted by Hannah with "other Test" paid S$6.00; 500 points for Hannah; a guardian link from "leaver Test" to the restricted child `…00a1`; a shop owned by "other Test" with a paid order by "leaver Test".

## Cases that passed

| # | Case | Evidence |
| --- | --- | --- |
| A1 | Club owner request refused, nothing written | 400 "Hand your club to another member, or delete it, first."; no `account_deletions` row; not hidden |
| A2 | Staff request refused | 400 "Staff accounts are closed by the OlympusGO team…" |
| A4 | Anonymous request | 401 |
| A5 | Request while an open shop order exists is allowed | 200 (the erase waits instead) |
| B1 | Request hides at once, 30 days out | `hidden_at` set; `erase_after` = now + 30 d; `hidden_before` = false |
| B2 | Asking twice returns the same date | identical `erase_after` |
| B5 | Joined Meet refunded in full with fee | refund `account_deleted`, 800 + 200 = 1000, key `account_deleted:<payment>`; participant `cancelled`, `refund_cents` 1000 |
| B7 | Hosted Meet cancelled, its player refunded | M2 `cancelled` "The organizer closed their OlympusGO account."; refund `organizer_cancelled` 800 to the player; player notified |
| B9 | Inbox note written | "Your account is closing — Log in before 08 Dec 2026 to keep it." |
| B10 | Points untouched while closing | balance 500 |
| C1 C2 C7 | Closing account refused elsewhere | GET `/activities`, POST `activity_reserve`, GET `/notifications` → "This account is closing." |
| C3 C4 C8 | Allowed paths work | `my_restrictions` has `closing_until`; own `/profiles` and `/account_private` readable |
| C6 | Protected column holds while closing | PATCH `hidden_at = null` returns 200 but the value stays (trigger) |
| D1 | Others cannot see a closing player | Aaron's read of Hannah's profile → `[]` |
| E2 E3 E4 | Erase blocked by an open order, alert after 7 days, once | `blocked_reason = shop_order`; one `money_alerts` row after 8 days; a second run adds none |
| E5–E9 | Erase after the money settles | `Former player`, username/bio/avatar null, `visibility only_me`, contacts and birthday null, guardian link `ended`, child still restricted, auth user banned, `erased_at` set |
| E10 E11 | Erased account on the API | every path → "This account was deleted."; payments and orders kept; notifications gone |
| E12 | Others see the tombstone | `private.public_name` → "Former player"; profile read → `[]` |
| E13 | Job idempotent | second run returns 0 |
| F1–F4 F6 F7 | Keep | `cancelled_at` set, `hidden_at` cleared, API open again, visible to Aaron, `closing_until` null; second Keep is a no-op |
| A3 (fresh player) | Earnings refusal fires for a positive ledger sum | see finding 1: it fires for the wrong sign |
| A3b | Reason trimmed and capped | 250-char reason stored as 200 chars, outer spaces removed |
| A6 | Keep with no request | 204, nothing changes |
| S1 | Simulator: full loop as Hannah | Account Centre → Delete → Face ID → Closing (Tue 8 Dec) → Done logs out → tile → closing gate → Keep → Home; Inbox note present |
| S2 | Simulator: Face ID no-match / cancel | system retry dialog; Cancel closes the sheet; no request made |
| S3 | Simulator: refusal as club owner | toast "Hand your club to another member, or delete it, first." |
| S4 | Simulator: gateway down | toast "Can't reach OlympusGO. Check your connection and try again." |

## Findings

Severity: **High** blocks shipping; **Medium** should be fixed in this ticket or the next; **Low** is a follow-up or a wording change. "Reproduced" means I made it happen on the local stack; "code" means confirmed by reading only.

1. **High — The earnings refusal (R-ACC-15) tests the wrong sign.** `account_delete_request` refuses when the sum of the caller's `ledger_accounts` entries is `> 0`. The ledger is positive debit / negative credit (`money_ledger.sql`: "positive debit, negative credit"); release posts `-v_net` to the organizer account and `payouts_prepare` reads `-ledger_balance('organizer', …)`. So an organizer who is owed money has a negative sum and is **not** refused, while someone carrying an organizer-fee debt (positive) is refused with "You still have earnings to be paid out". Reproduced: a fresh player with a +1500 (debit) entry was refused; a real owed balance would pass. The sum also ignores currency. pgTAP has no test for this rule. Fix: compare `< 0` per currency (or call the payouts helper), and add the test. **Fixed 8 Nov 2026:** the check now groups the caller's organizer-kind accounts by currency and refuses when `private.organizer_net` (what the payout run pays) is positive in any of them. A fee debt is no longer refused (Q245). Tested in `54_account_deletion_test.sql`: a released S$6.00 Meet refuses, a S$0.77 debt goes through.

2. **High — A "Keep my account" that lands while the job runs is erased anyway.** `private.account_erase_due` snapshots up to 200 due rows, then `private.account_erase` takes the per-user lock but never re-checks `cancelled_at`, and its final update does not filter on it. Reproduced directly: cancel, then `account_erase` → profile tombstoned, row both `cancelled_at` and `erased_at`. In production the window is the job's loop on day 30. Fix: inside `account_erase`, after the lock, return when `cancelled_at is not null or erased_at is not null`. **Fixed 8 Nov 2026:** `account_erase` re-reads the row under the per-user lock (the same one the undo takes) and returns when it is cancelled, erased or missing; the final update filters on the same. Tested: cancel after the day has passed, then both the job and a direct erase leave the account whole; a second erase keeps the first erase time; an id that never asked is untouched.

3. **Medium — Restricted and suspended accounts cannot delete, and a suspended closing account cannot keep itself.** Neither `/rpc/account_delete_request` nor `/rpc/account_delete_cancel` is in `private.restricted_allow` or `private.suspended_allow`, and the gate runs those checks after the closing check. Reproduced: the restricted child `…00a1` gets "Ask a parent to link your account first." Apple 5.1.1(v) expects deletion for every account. Raised as Q243.

4. **Medium — `payment_customers` survives the erase.** The Stripe customer id, card brand and last four stay linked to the tombstone forever, and the Stripe customer is never deleted. Code.

5. **Medium — Money still in `held` for a Meet the leaver hosted is not considered.** The refusal looks only at the organizer ledger (and is inverted, finding 1); `account_money_open` looks only at payments where the leaver is the payer. A host who runs a Meet on day 0, requests on day 1 and is released on day 3 is erased on day 31 with a balance on the ledger; `payouts_prepare` does not check `erased_at`. Code. The review of the fix for finding 1 (8 Nov 2026) adds: the request's refusal now matches the payout run exactly, but `held` money for a Meet that has started and is not yet released still passes it, as does a payout approved but not yet sent (`payouts_pending` has no owner; a failed transfer would credit a closed account). The erase never touches `vendors`, so a verified vendor's "Former player" would be paid; an unverified one raises `vendor_unverified` alerts forever. Options: refuse while a hosted paid Meet has started but is unreleased, or make `account_money_open` return `'earnings'`/`'held'` so the erase waits. Raised as Q246.

6. **Medium — A refund in `manual` status blocks the erase for ever.** `account_money_open` treats `manual` as "still moving", but `refund_transitions` has no transition out of `manual` (it is staff recording a bank transfer). One alert after 7 days, then nothing. Code.

7. **Medium — A tournament entry is refunded but never withdrawn.** `account_leave` refunds `purpose = 'tournament'` and cancels the participant row, but `tournament_entries.status` stays `entered` and the waitlist is not promoted (`tournament_withdraw` does both). Code.

8. **Low — The closing gate allows every HTTP method on its allowed table paths.** Reproduced: a closing Hannah PATCHed her own `full_name` on `/profiles` (200, value changed). `hidden_at` is protected by the trigger, `account_private` is not updatable at all, so this is outside the spec rather than a privilege gain. Fix: allow `GET`/`HEAD` only on the table paths, as the restricted branch does.

9. **Low — The erase date can show a different day on the client and in the Inbox note.** The client parses `erase_after` without `.toLocal()` and formats the UTC day; the server note hard-codes `Asia/Singapore` regardless of country. A request between 00:00 and 08:00 SGT shows one day on screen and the next in the Inbox. Code (my run was at 10:01 SGT, so both said 8 Dec).

10. **Low — A moderation hide applied during the 30 days is undone by Keep.** `hidden_before` is captured at request time; `hidden_at` is one column, so a later moderation hide is indistinguishable and is cleared on Keep. Plausible, depends on how moderation writes `hidden_at`.

11. **Low — The undo instructions go to an Inbox the player cannot open.** Reproduced: `/notifications` is refused while closing, so "Log in before … to keep it" is only readable after keeping. The closing screen carries the same text, so no one is stranded.

12. **Low — When the erase is blocked past day 30, the closing screen quotes a past date.** Reproduced: `my_restrictions` returned `closing_until` in the past for the blocked leaver, so the screen would read "It is erased on Sun 8 Nov unless you keep it" on 9 Nov.

13. **Low — Router and closing screen states.** The closing redirect reads `restrictionsProvider.value?.closing ?? false` with no "wait while loading" branch, so a cold start can route Home for a moment and fail every Home request with "This account is closing" until restrictions arrive; `AccountClosingScreen` has no error or offline state, and a failed restrictions load reads as not closing. Code; not observed in the walkthrough.

14. **Low — Two ungated paths.** The `save-card` Edge Function verifies the JWT and acts with the service role without a gated RPC, and avatar uploads are not gated, so a closing account can still save a card or upload. Code.

15. **Low — Auth clean-up is all-or-nothing and `auth.users.phone` is not cleared.** One `exception when insufficient_privilege` block wraps the ban and three deletes; a later failure rolls back the ban. The gate and the empty contacts still stop sign-in. Code.

16. **Low (UX) — Refusals and the offline error are three-second toasts** that cover the Delete button and vanish (reproduced, S3 and S4). After a Face ID prompt the player can miss them. An inline message under the buttons would hold.

17. **Low (product) — Keep does not bring back what was refunded.** Reproduced: after Keep, Hannah's joined Meet stays `cancelled` and the Meet she hosted stays cancelled, as R-REF-18 intends. Nothing on the closing screen says so. Raised as Q244.

18. **Tests.** pgTAP does not cover: the earnings or team-owner refusals; cancel racing the erase; the `held`, `refund`, `dispute` and `lesson` blocked reasons; the job running twice over the same rows; `storage_deletions` rows for avatars, chat photos and licences; `academy_students.parent_id` nulled by the erase (only by the hard delete); PATCH through the closing gate; a restricted or suspended caller; `payment_customers`; a pending payment becoming `cancel_requested`. The race script's own negative control reports that `refund_issue` alone already blocks a double refund, so the script does not prove the request's lock and key. The Definition of Done item "columns registered in `field_registry`" cannot be met: no such table exists in any migration.

### Checked and fine

Every function is `security definer` with `search_path = ''` and qualified names; `private.*` helpers revoke execute from `public`; the two RPCs grant only `authenticated`. Both RPCs use `auth.uid()`. `account_deletions` has RLS on and all writes revoked from `authenticated`. The profile guard stops client writes to `hidden_at`/`erased_at`. Refunds go through `refund_issue` with the `account_deleted:<payment>` key and the unique constraint; amounts are integer minor units; a repeat request returns early. Points are forfeited as append-only entries; ledger, payments, refunds, orders, results, reports and audit rows survive the erase. The guardian logic leaves a child with a second parent unrestricted and a sole child restricted with records intact. Face ID failure, platform error and sheet dismissal all return before any call. Refusal wording is plain and says nothing about other accounts.

### Observations that are not defects

- A saved tile disappears when its refresh token is dead (the tile's `setSession` fails and the vault forgets it). This is by design; the toast "That sign-in has expired" is what the player sees.
- The participant row of a Meet cancelled by its host stays `joined` with no refund fields while the refund row exists. That is `cancel_activity`'s existing behaviour, not this change.
- Aaron's Passport showed "0 clubs" while owning the fixture club because the fixture had no `club_members` row.

## Environment notes

- Colima stopped when the disk filled during a Flutter build; after `colima start`, the Supabase containers came back but `supabase_edge_runtime_olympusGO` stayed exited until started by hand, which made "Send code" fail with "Something went wrong. Try again." in the app.
- With Colima down, `supabase status` returns an empty anon key and the app silently launches in demo mode.
- Fixtures left behind on the local database: two cancelled Meets, a shop and a collected order, test ledger entries for "other Test" (append-only, could not be removed) and the fresh player `aa000000-…e001`, "leaver Test" and that fresh player erased, Hannah's cancelled request and Inbox note, the `t` helper schema. Aaron is clean (the fixture club was deleted) and `payments.enabled` / `shop.checkout` are back to false. Run `supabase db reset` before the next test session.

## Suggested order

1. ~~Fix findings 1 and 2 with pgTAP tests for each~~ Done 8 Nov 2026, same branch.
2. Decide Q243 and add the two RPC paths to the restricted and suspended allow-lists; restrict the closing allow-list to `GET`/`HEAD` on table paths (finding 8).
3. Erase `payment_customers` and delete the Stripe customer (finding 4); treat `manual` refunds as settled (finding 6); withdraw tournament entries in `account_leave` (finding 7); decide how held organizer money is handled at request time (finding 5).
4. Date handling (finding 9), the closing screen's past date and error state (12, 13), inline refusal messages (16), the Keep copy (Q244).
5. Fill the test gaps in finding 18 and give the race script a control that actually isolates the request lock, plus a round that races `account_delete_cancel` against `account_erase_due` (the fix for finding 2 is proved by single-session pgTAP and by reasoning about the lock, not by a concurrent run).
