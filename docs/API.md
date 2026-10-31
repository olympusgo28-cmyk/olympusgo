# Server API

The calls the apps make, for the first phases and for money. Clients read tables directly only where RLS allows it, and change data only through these calls. `ARCHITECTURE.md` section 6 says which runtime each kind of work belongs in.

Keep this file in step with the code: when you add or change a call, update its row.

## Conventions

- **RPCs** are Postgres functions called through PostgREST: `supabase.rpc('join_meet', {...})` maps to an exposed wrapper of `activities.join_meet`. They run the rule in one transaction.
- **Edge Functions** handle secrets and outside services (codes, Stripe, uploads). They call narrowly granted RPCs to write data.
- Every call that changes something consequential takes `p_idempotency_key text`. Repeating a call with the same key returns the first result and changes nothing.
- Every RPC: `security definer`, `set search_path = ''`, `revoke execute ... from public, anon`, explicit `grant` to the roles that need it, and a pgTAP test.
- Calls that change an aggregate write a domain event in the same transaction (event names in `ARCHITECTURE.md` section 14).

## Errors

Raise errors with a stable code in `detail` so apps can show the right sentence. Never put personal data in an error.

| Code | Meaning | App shows |
| --- | --- | --- |
| `not_found` | The thing does not exist **or** the caller may not see it (blocked, private, minor) | "We can't find that." |
| `forbidden_action` | Caller is signed in and may see it, but lacks the permission | The screen's own explanation |
| `invalid_input` | A field failed validation; `hint` names the field | Field-level error |
| `conflict_full` | Activity is full; caller can join the waitlist | "This Meet is full." with Join the waitlist |
| `conflict_state` | The thing is in a state that does not allow this (cancelled, started, closed) | The state, in words |
| `too_late` | A cut-off has passed (refund, attendance, correction) | The rule and the cut-off time |
| `rate_limited` | Too many attempts; `retry_after_seconds` given | "Try again in 0:30" |
| `locked` | Code attempts locked out | "Too many tries. Try again in 15 minutes." |
| `payment_failed` | The payment company declined | The failed-payment state inside the flow (PAY-8) |
| `needs_guardian` | A minor needs a parent's approval for this | Parent approval message |

## Phase 1: identity and safety

| Call | Runtime | Input | Result | Rules |
| --- | --- | --- | --- | --- |
| `request_code` | Edge | `identifier` (email or username), `purpose` (`signup`, `login`, `change_email`) | Always `{sent: true}` after a padded delay | R-ACC-2, R-ACC-4 |
| `verify_email_code` | Supabase Auth | email, code | Session (AAL1) | R-ACC-2, R-ACC-3 |
| `send_mobile_code` | Edge | `mobile_e164`, `channel` (`sms`, `whatsapp`) | `{sent: true, resend_after_seconds: 30}` | R-ACC-3, R-ACC-5 |
| `verify_mobile_code` | Edge → RPC `identity.confirm_mobile` | code | `{verified: true}` or `{duplicate: true}` with the two options | R-ACC-5, R-ACC-6 |
| `claim_mobile` | Edge → RPC | code, `idempotency_key` | `{claimed: true}`; old account emailed | R-ACC-6 |
| `identity.complete_signup` | RPC | display name, username, country, date of birth | Profile with `audience_class` set by the server | R-ACC-1, R-AGE-1, R-AGE-2 |
| `identity.request_guardian_approval` | RPC | guardian email or mobile | `{requested: true}` | R-AGE-1 (Q2) |
| `identity.approve_child` | RPC (guardian) | child id, scopes | Guardian link active | SAF-7 |
| `identity.add_child_profile` | RPC (guardian) | name, birth year | Child profile | R-AGE-1 |
| `identity.update_profile` | RPC | safe fields only | Profile | — |
| `identity.set_session_visibility` | RPC | `public`, `circle`, `private` | Setting; `public` refused for minors | R-PRV-1, R-AGE-3 |
| `identity.block_user` / `unblock_user` | RPC | user id | `{blocked: true}`; emits `user.blocked` | R-PRV-4 |
| `moderation.create_report` | RPC | target type and id, reason, note | Report with `due_at` | SAF-1, R-MOD-1 |
| `moderation.request_second_look` | RPC | report id | Report status `second_look` | SAF-3 |
| `submit_legal_notice` | Edge (no account) | notice form | Reference number | SAF-5 |
| `identity.request_deletion` / `cancel_deletion` | RPC (after step-up) | — | `erase_after` date | R-ACC-11, R-REF-18 |
| `identity.request_recovery` | Edge | contact details, evidence upload ids | Case reference | R-ACC-13 |
| `step_up` | Edge | device biometric result token | Short-lived step-up flag on the session | R-ACC-8 |
| Staff: `moderation.decide` | RPC (staff) | report id, rule, outcome, message | Decision; bans need `moderation.approve_decision` by a second staff member | R-MOD-3, R-MOD-4 |

## Phases 2 and 3: activities

| Call | Runtime | Input | Result | Rules |
| --- | --- | --- | --- | --- |
| `search` | RPC | query, filters (sport, game type, level range, date, play style, gender, kind), cursor | Page of activity cards and venues; blocks and minors applied | PLY-1, PLY-2, ACR-012 |
| `activities.create_meet` | RPC (`create_meets` permission) | org, sport, title, start, end, venue, repeats, game type, min and max players, level range, ranked, fee mode, price, visibility | Activity ids (one per repeat) | MET-1, MET-2, R-MET-1 |
| `activities.join_meet` | RPC | activity id, guest (optional), `idempotency_key` | Free Meet: `joined`. Paid Meet: `reserved` with `reserved_until`. Full: `conflict_full` | R-MET-4, R-MET-5, R-MET-9 |
| `activities.join_waitlist` | RPC | activity id, `idempotency_key` | Position | R-MET-6 |
| `activities.respond_offer` | RPC | participation id, accept or decline, `idempotency_key` | `reserved` or `left` | R-MET-6 |
| `activities.leave_meet` | RPC | activity id, `refund_to` (`wallet`, `original_method`), `idempotency_key` | Refund quote applied; spot offered to the waitlist | MET-6, R-REF-2, R-REF-5 |
| `activities.cancel_activity` | RPC (organizer) | activity id, scope (`this`, `this_and_later`), message, `idempotency_key` | Everyone refunded per R-REF-1; card fees recorded | MET-9, R-REF-1, R-REF-11 |
| `activities.check_in` | Edge → RPC | activity id, and a signed location assertion, or a venue QR token plus location | `present` | R-ATT-1, R-ATT-2, R-ATT-3 |
| `activities.mark_attendance` | RPC (organizer) | activity id, list of user id and present or absent, walk-ins | Attendance saved; emits `attendance.recorded` | R-ATT-3, R-ATT-5 |
| `my_schedule` | RPC | tab (`joined`, `hosting`), cursor | Rows, including a child's classes | PLY-4 |

## Phase 5: matches

| Call | Runtime | Input | Result | Rules |
| --- | --- | --- | --- | --- |
| `matches.submit_result` | RPC | match id, game scores, `idempotency_key` | Submission; other side notified | R-SCO-1, R-SCO-2 |
| `matches.confirm_result` | RPC | submission id, confirm or dispute | Confirmed result (emits `match.result_confirmed`) or dispute | R-SCO-2 |
| `matches.decide_dispute` | RPC (organizer) | match id, result | Confirmed result | R-SCO-2 |
| `matches.correct_result` | RPC (organizer, 24 h) | match id, new scores, reason | New result superseding the old; emits `match.result_corrected` | R-SCO-3 |

## Phase 9: money (only after Q1)

All amounts are integer minor units with a currency.

| Call | Runtime | Input | Result | Rules |
| --- | --- | --- | --- | --- |
| `money.quote` | RPC (pure, no writes) | purpose, activity or item, quantity | Lines, fee, total, refund rule text, methods available (Wallet only if it covers the total) | R-FEE-1 to R-FEE-8, R-WAL-4, PAY-1 |
| `create_payment` | Edge | reservation or cart id, method, `idempotency_key` | Stripe client secret (card, PayNow) or immediate success (Wallet) | PAY-1 |
| `stripe_webhook` | Edge | Stripe event | 200 after recording in `money.stripe_events`; duplicate events ignored | Golden rule 4 |
| `money.capture_succeeded` | RPC (webhook only) | Stripe event id | Order `paid`, ledger entries, hold, participation `joined` | R-HOLD-1 |
| `money.refund_quote` | RPC (pure) | order id, reason, destination, at time | Refund amount, card fee to organizer, destination, cut-off | R-REF-1 to R-REF-19 |
| `money.refund` | RPC + Edge | order id, reason, destination, `idempotency_key` | Refund record; Wallet instantly, card through Stripe | R-REF-* |
| `money.release_funds` | Scheduled job | — | Moves held money for activities whose attendance is saved or that ended 24 h ago | R-HOLD-2, R-HOLD-4 |
| `wallet.withdraw` | RPC + Edge | amount, destination (`bank`, `paynow`), `idempotency_key` | Withdrawal; no fee | R-WAL-3 |
| `payouts.prepare_run` | Scheduled job | — | Draft run per country for staff | R-PAY-1 |
| `payouts.approve_run` | RPC (staff) | run id | Approved; second approver if over threshold | R-PAY-2 |
| `points.award` | Event consumer on `attendance.recorded` | — | Points entries for payers marked Present | R-PTS-1 to R-PTS-6 |

`money.quote` and `money.refund_quote` are pure functions. Write them first, test them against every row of the example tables in `RULES.md`, and use them everywhere an amount is shown or charged, so the app and the server can never disagree.

## Scores and ratings (checklist phase 3)

| Name | Who | What it does |
| --- | --- | --- |
| `submit_score(activity, partners, opponents, games, client_key)` | Player on the Meet | Enters a score. A repeat `client_key` returns the same score |
| `answer_score(score, ok, why)` | Other side | Confirms or disputes, under a row lock |
| `organiser_decide_score(p_score, p_games, p_reason)` | Organizer | Decides a disputed score, or one left unanswered for 24 hours. Not a match they played in |
| `tournament_score(p_match, p_games, p_reason, p_retired)` | Organizer | Final score. A correction needs a reason, within 24 hours |
| `staff_result_correct(p_score, p_games, p_reason)` | Staff, moderator | Later correction or a dispute an organizer can't decide, through `admin-action`. The winner of a tournament match can't change (Q53) |
| `staff_scores(p_score)` | Staff, moderator | Disputes in an organizer's own match, or one score by id |
| `activity_preset_set(p_activity, p_preset)` | Organizer | Picks scoring until the first score |
| `activity_scoring(p_activity)` | Signed in | The rules a score is checked with |
| `meet_rounds_save(p_activity, p_from, p_rounds)`, `meet_rounds(p_activity)` | Organizer, players | Saves and reads rounds |
| `my_rating(p_sport)`, `my_rating_change(p_activity, p_score)` | Signed in | Own rating and how it moved |
| `leaderboard_rating(p_sport, p_areas)`, `leaderboard_points(p_sport)` | Signed in | Read the snapshots |
| `guardian_leaderboard_set(p_child, p_on)` | Linked parent | Opts a child in or out |
| `leaderboards_refresh()` | Service role only | Rebuilds snapshots |
| `staff_preset_save(...)`, `staff_level_save(...)` | Staff, content | A-05, through `admin-action` |
| `score_view(p_score)`, `my_meet_results(p_activity)`, `meet_disputes(p_activity)` | Players in the match, organizer | The only client reads of scores and results. Ids match what the roster shows that viewer |

## Money, as built in Phase 4a

These replace the `money.*`, `payouts.*` and `wallet.*` rows above. There is no Wallet (Q45). Every amount is integer minor units.

| Name | Kind | Input | Result | Rule |
| --- | --- | --- | --- | --- |
| `money_quote` | RPC, pure | purpose, price, qty, currency | Price, fee, total, per unit | R-FEE-1 to R-FEE-7 |
| `money_refund_quote` | RPC, pure | reason, price, fee, method | Refund, and whether the organizer bears the card fee | R-REF-1 to R-REF-18 |
| `activity_quote` | RPC | activity, qty | The quote plus the refund rule text | R-REF-20 |
| `activity_reserve` | RPC | activity, key, qty, guest | A hold and a pending payment, or `waitlist` | PAY-1, R-MET |
| `payment_begin` | RPC | payment, method | Called by `create-payment-intent` as the player | PAY-1 |
| `payment_status`, `payment_abandon` | RPC | payment | Progress, or give it up | PAY-1 |
| `create-payment-intent` | Edge | payment, method | Client secret. The amount comes from the database | PAY-1 |
| `stripe-webhook` | Edge | Stripe event | The only thing that confirms a payment. Idempotent on event id | Golden rule 4 |
| `stripe-local` | Edge | test action | 404 anywhere but a local stack | P4a-03 |
| `money-worker` | Edge | timer, secret header | Makes the Stripe calls the database asked for | P4a-06 |
| `save-card` | Edge | none | Starts saving a card | R-FEE-3 |
| `vendor-onboard` | Edge | none | Starts Stripe's checks | R-PAY-4 |
| `leave_activity` | RPC | activity | Refund in minor units. No Wallet choice | R-REF-2, R-REF-5 |
| `organizer_debt_reserve` | RPC | key | A payment for organizer fees owed | Owner, 31 Oct |
| `money_my_payments`, `money_my_earnings`, `money_my_card` | RPC | none | The caller's own records | PAY |
| `resolve_qr` | RPC | token | `player`, `group`, `venue` or `vendor`. Refused for under-18s | P4a-09 |
| `staff_money_overview`, `staff_payment_list`, `staff_payment_get`, `staff_refund_list`, `staff_held_list`, `staff_payout_list`, `staff_dispute_list`, `staff_alert_list` | RPC, payments staff | | A-06 reads | A-06 |
| `staff_refund_issue`, `staff_refund_retry`, `staff_refund_void`, `staff_refund_manual`, `staff_hold_decide`, `staff_payout_approve`, `staff_alert_close` | admin-action, payments staff | with a reason | A-06 writes, audited | A-06 |

`money_svc_*` functions are for Edge Functions with the service key, and closed to every client role.

## The Shop, as built in Phase 4b

These replace `shop_open`, `shop_checkout`, `shop_cancel`, `shop_confirm_received`, `shop_mark_shipped`, `shop_return_*`, `shop_address_save`, `shop_book_service` and `shop_save_product`, which are gone. One order is one shop and one payment. Orders are paid through the 4a payment flow (`create-payment-intent`, the webhook, `refund_issue`, `money-worker`).

| Name | Kind | Input | Output | Covers |
| --- | --- | --- | --- | --- |
| `shop_quote` | RPC | mall, `p_only` (`{product, variant, qty}` or null for the cart), points in cents | Lines, `total_minor`, `points_cap_minor`, `points_left_minor`, collection address, balance, `can_redeem`, refund rule, `can_pay` | P4b-03 |
| `shop_reserve` | RPC | mall, `p_key`, `p_expected_minor`, points, `p_only`, `p_slot` | The payment, plus `order_id`. Raises `price_changed` rather than charge another price. An unpaid order at the shop at another price raises too | P4b-03 |
| `shop_order_cancel` | RPC | order, reason | The refund in cents. Buyer only, on `pending`, `paid` or `ready`, before `release_at` | R-REF-4, R-REF-9 |
| `shop_collected` | RPC | order | "Yes, I got it all". Buyer only. Repeating it does nothing | P4b-04 |
| `shop_report_problem` | RPC | order, note | Holds the payment for staff. Refused after `release_at` | P4b-04 |
| `shop_mark_started`, `shop_mark_ready`, `shop_owner_cancel`, `shop_owner_orders` | RPC | order | The owner's side. Started stops the buyer cancelling a service. A shop's cancel refunds in full and the shop bears the card fee | P4b-04 |
| `shop_my_mall` | RPC | none | The caller's shop, open or not | P4b-04 |
| `shop_report` | RPC | product, reason, note | Reports a listing by id, so moderation can hide it | Fixes a bug |
| `points_my` | RPC | none | Balance in cents, `can_redeem`, `earning`, next expiry, history | P4b-05 |
| `staff_shop_list` | RPC, staff | none | Every shop. Content or payments | A-07 |
| `staff_shop_save`, `staff_product_list`, `staff_product_save`, `staff_product_stock` | RPC or `admin-action`, content | as named | Stock moves by an amount, so an edit can't wipe stock held for someone paying | A-07 |
| `staff_order_list`, `staff_order_get`, `staff_order_decide`, `staff_shop_commission_set`, `staff_shop_link_owner`, `staff_points_block` | RPC or `admin-action`, payments | as named | `staff_order_decide` takes `[{line, qty}]` and a `p_key`, so a repeat does nothing. An empty list releases to the shop, only once it's reported or past its date. Refunding part of an order still waiting leaves the rest waiting | A-07 |

