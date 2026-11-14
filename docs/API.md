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
| `resolve-login` `step_up_send` / `step_up_verify` (built) | Edge, signed in | `changing` (`mobile` or `email`); then `code` | `{sent: true, via}` naming the kind of contact the code went to, never the contact; then `{confirmed: true}`, which records a proof for this session for `auth.step_up_minutes` | R-ACC-9, Q268 |
| `resolve-login` `contact_send` / `contact_verify` (built) | Edge, signed in | `identifier` (new mobile or email); then `code` | 403 `{error: "step_up"}` until the session holds a proof; then `{sent: true}` and `{saved: true}`. The proof is used once and the old contact is alerted | R-ACC-9, Q268 |
| `identity.complete_signup` | RPC | display name, username, country, date of birth | Profile with `audience_class` set by the server | R-ACC-1, R-AGE-1, R-AGE-2 |
| `identity.request_guardian_approval` | RPC | guardian email or mobile | `{requested: true}` | R-AGE-1 (Q2) |
| `identity.approve_child` | RPC (guardian) | child id, scopes | Guardian link active | SAF-7 |
| `identity.add_child_profile` | RPC (guardian) | name, birth year | Child profile | R-AGE-1 |
| `identity.update_profile` | RPC | safe fields only | Profile | — |
| `identity.set_session_visibility` | RPC | `public`, `circle`, `private` | Setting; `public` refused for minors | R-PRV-1, R-AGE-3 |
| `identity.block_user` / `unblock_user` | RPC | user id | `{blocked: true}`; emits `user.blocked` | R-PRV-4 |
| `moderation.create_report` | RPC | target type and id, reason, note | Report with `due_at` | SAF-1, R-MOD-1 |
| `moderation.request_second_look` | RPC | report id | Report status `second_look` | SAF-3 |
| Reports as built: insert into `content_reports` or `player_reports`, or `shop_report` | Table insert (RLS) or RPC | `target_kind`, `target_id`, `reason`, `note` | A before-insert check refuses with `P0001` "This can't be reported." when the reporter can't see the target (a missing or hidden one reads the same), and with `P0001` "You've sent a lot of reports. Try again in an hour." past `moderation.reports_per_hour`. Player reports are always accepted | R-MOD-6, Q269 |
| `submit_legal_notice` | Edge (no account) | notice form | Reference number | SAF-5 |
| `account_delete_request(p_reason)` / `account_delete_cancel()` | RPC (after Face ID) | optional reason | `{erase_after}`; refuses with a plain message while the caller owns a club, team, open academy or active shop, is staff, or has earnings owed (R-ACC-15). `my_restrictions` returns `closing_until` while closing | R-ACC-11, R-REF-18 |
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

## Academy, lessons, assessments and services, as built in Phase 4c

All in `public`, authenticated only, unless it says staff. Migrations `20261106090000` to `20261106120000`.

| Function | What it does |
| --- | --- |
| `academy_coach_answer(academy, accept)`, `academy_my_coach_invites()` | A coach says yes or no. Nobody coaches without it |
| `coach_profile_save`, `coach_profile_get(user)` | A coach's page. Only an adult with a current licence at a verified academy is listed |
| `coach_licence_submit(number, expires, path)`, `coach_licence_my()` | The coach's own licence. No file path comes back |
| `academy_submit_business(academy, uen, path)`, `academy_verification(academy)` | The owner's submission, and the checklist for the head coach |
| `academy_my_players()`, `academy_request(class, player, note, trial_at)` | Who can be enrolled: yourself or a linked child. Replaces the typed name |
| `lesson_quote(kind, ref, at)` | Server price, fee, total, refund rule and whether paying is open. `kind` is `trial`, `class` or `one_to_one`. `ref` is a class or slot |
| `lesson_reserve(kind, ref, at, student, key, expected_minor)` | Holds the place for `lesson.hold_minutes` and returns the payment. Idempotent on the key. A wrong total raises `price_changed`. Then the usual `payment_begin` and webhook |
| `lesson_cancel(booking, reason)` | The payer. In time gives the price back, late gives nothing |
| `lesson_academy_cancel(booking, reason)` | The coach or head. Everything back, with the card fee on the owner |
| `lesson_mark_attendance(booking, present)` | After the start. Saves and releases |
| `lesson_report(booking, note)` | The payer, after the start and before release. Held for staff |
| `lesson_my()`, `lesson_get(booking)`, `lesson_academy_list(academy)` | Reads |
| `lesson_slot_add`, `lesson_slot_withdraw`, `lesson_slots_open(academy)`, `lesson_slots_mine(academy)` | One-to-one times |
| `assessment_template_list`, `assessment_template_save`, `assessment_template_archive` | Head coach writes. Criteria freeze once used |
| `assessment_save(p)`, `assessment_list(player)` | The coach writes or corrects. The list returns only what the caller may read, oldest first |
| `service_partner_list()`, `service_referral_make(partner)` | Live partners, and the link to open. 18 and over |
| `staff_verification_list`, `staff_academy_decide`, `staff_licence_decide`, `staff_doc_removed` | Staff, role `content` |
| `staff_lesson_list`, `staff_lesson_decide(booking, refund, reason)` | Staff, role `payments`. The only way to refund a lesson |
| `staff_service_list`, `staff_service_save` | Staff, role `content`. Counts per partner, never who |

Staff writes go through `admin-action`.

## Game, as built in Phase 4d

Authenticated only. Migrations `20261107090000` and `20261107100000`.

| Function | What it does |
| --- | --- |
| `campaign_list()`, `campaign_get(campaign)`, `campaign_join(campaign)` | Live campaigns, with the caller's progress. Joining is for adults |
| `voucher_my()` | The caller's wallet. The only place a code is returned |
| `badge_my()` | The caller's badges |
| `organizer_rewards_my()` | Counted games, next milestone, why a game didn't count, plus `min_present` and `fee_minor` from the server's settings |
| `shop_quote(mall, only, points, voucher)` | Adds `voucher_minor`, `voucher_id` and the `vouchers` that fit this cart. Each one's `amount_minor` is what it will really take off |
| `shop_reserve(..., slot, voucher)` | Spends the voucher in the same transaction as stock and points |
| `staff_campaign_list`, `staff_campaign_save`, `staff_campaign_status`, `staff_badge_save`, `staff_voucher_type_save`, `staff_organizer_games`, `staff_redemptions` | Staff. Campaigns and badges take role `content`, voucher types take `payments`, and both can read the list, games and redemptions. Writes through `admin-action` |

## Fitness, as built in Phase 5a

All are for signed-in players, and refuse restricted and suspended accounts. They need `fitness.enabled`. Clients have no table access.

| Function | Does | Limit an hour |
| --- | --- | --- |
| `exercise_list()` | Live exercises, only suitable ones for under-18s | 300 |
| `program_list()` | The caller's programs, then the templates that suit them | 300 |
| `program_save(p_program jsonb)` | Creates or replaces a program. The phone makes the id, so a retry reaches the same row | 60 |
| `program_delete(p_program uuid)` | Deletes the caller's program. Past workouts stay | 60 |
| `workout_save(p_client_key text, p_workout jsonb)` | Saves a finished workout once per key. 20 a day, in `fitness.daily_workouts` | 60 |
| `workout_delete(p_workout uuid)` | Deletes the caller's workout | 60 |
| `workout_summary(p_days int default 30)` | Totals, streak, recent workouts and personal bests. Null means all time. Lists at most 100 workouts | 300 |
| `exercise_history(p_exercise uuid)` | The caller's best set, times done and last 30 sets | 300 |

### AI plans, as built in Phase 5b

The phone calls the `ai-plan` Edge Function with `client_key`, `goal` and `days`, and gets `program_id` back. It needs a signed-in player. A 409, 429 or 503 may still end in a plan, so keep the key. A 400 or 502 is final, so make a new key.

| Function | Does | Who |
| --- | --- | --- |
| `ai_plan_status()` | Whether it's open to the caller, whether they've agreed, and how many are left today | Player, 300 an hour |
| `consent_set('ai_plans', true)` | Records the agreement. Refuses under-18s | Player |
| `ai_plan_withdraw()` | Withdraws it. Open to suspended and restricted players too | Player |
| `ai_plan_begin(p_client_key, p_goal, p_days)` | Checks everything and returns the summary and catalogue. A key that ran gives its result, and spends nothing | Player, through the function, 20 an hour |
| `ai_plan_svc_finish(p_request, p_plan, p_model, p_input_tokens, p_output_tokens)` | Checks the plan again and saves a draft program | Service role |
| `ai_plan_svc_allowed(p_request)` | Whether the player's data may still be sent, asked before a second try | Service role |
| `ai_plan_svc_fail(p_request, p_model, p_input_tokens, p_output_tokens)` | Marks a request failed | Service role |

### Video analysis, as built in Phase 5c

| Function | Does | Who |
| --- | --- | --- |
| `analysis_status()` | Whether analysis is open to the caller, and the limits | Player |
| `clip_create(p_clip, p_subject, p_ext, p_seconds, p_bytes, p_everyone_agreed, p_consent_version)` | Starts a clip. The phone makes the id. A clip of a child writes its consent row | Adult or linked parent |
| `clip_uploaded(p_clip)` | The file is in, so queue the court job | Owner |
| `clip_confirm_court(p_clip, p_corners, p_side)` | Checks the daily caps and queues the analysis | Owner |
| `clip_list()`, `child_clip_list(p_child)`, `clip_get(p_clip)` | Clips and reports | Owner or linked parent |
| `clip_delete(p_clip)`, `clip_extend(p_clip)` | Deletes a clip and its report, or extends it once | Owner or linked parent |
| `consent_withdraw(p_clip)` | Stops all work on a child's clip, and the file goes at the next sweep | Owner or linked parent |
| `analysis_svc_claim()`, `analysis_svc_result(...)`, `analysis_svc_may_continue(...)`, `analysis_svc_frame_path(...)`, `analysis_svc_sweep()`, `analysis_svc_orphans()`, `analysis_svc_removed(p_ids)` | The worker's side | Service role |
| `staff_analysis_overview()`, `staff_analysis_retry(p_job, p_reason)` | The jobs monitor | Content staff |

The worker calls the `analysis-worker` Edge Function with `x-worker-secret`. `{"action": "claim"}` gives `{"job": ...}` with a token and a signed clip URL. `{"action": "continue", ...}` says whether to carry on, and a worker asks between stages. `{"action": "result", ...}` sends the outcome, with a court job's frame as base64. A worker can't write to Storage. Set `ANALYSIS_WORKER_SECRET`, and `ANALYSIS_PUBLIC_URL` if the worker reaches Storage on a different address. The money worker runs the sweep with `{"task": "clips"}`.

### Video feed, as built in Phase 5d

| Function | What it does | Who |
| --- | --- | --- |
| `feed_status()` | Whether the feed is open to the caller, whether they can post or see Discover, and the limits | Player |
| `feed_following()`, `feed_discover()` | Lists that end, with no cursor. Discover refuses under-18s | Player |
| `post_create(p_post, p_ext, p_seconds, p_bytes, p_caption, p_sport, p_audience, p_no_minors)` | Starts a post. The phone makes the id, so a retry reaches the same post. A used id with a case or match is refused | Adult |
| `post_upload_target(p_post)`, `post_uploaded(p_post)` | The file's place, and queues its checks | Author |
| `post_retry(p_post)` | Runs failed checks again | Author |
| `post_delete(p_post)`, `post_mine()` | Open whatever the account's state. A blocked post reads as rejected | Author |
| `post_like(p_post)`, `post_unlike(p_post)` | Like a post the caller may see | Player |
| `post_play(p_post)`, `post_posters(p_posts)` | What `feed-media` signs, for this viewer | Player |
| `feed_svc_claim()`, `feed_svc_job(...)`, `feed_svc_result(...)`, `feed_svc_sweep()` | The worker's side | Service only |
| `staff_post_queue()`, `staff_post_decide(p_post, p_outcome, p_reason)`, `staff_post_play(p_post)` | First posts. Every look and decision is audited | Moderators |

Reports are `content_reports` rows with `target_kind` `video`, on a post that has passed its hash match. `feed-media` runs as the signed-in person: `{"action": "upload", "post": id}`, `{"action": "play", "post": id}`, `{"action": "posters", "posts": [...]}`, or `staff_play`. Links last `feed.url_seconds`. A worker calls `feed-worker` with `x-worker-secret`: `{"action": "claim"}`, then `{"action": "check", "job_id", "token", "ok", "frames", "code", "worker_seconds"}`. That function calls the providers, so the worker holds no key. `feed-local` plays the worker on a local stack, and takes `hash`, `frames` and `fail` to script a verdict. It needs `feed.fake_checks` on, and answers 404 anywhere else.

These functions aren't marked `stable`. The API runs a stable function in a read-only transaction, where the request gate can't record a rate-limit hit.

