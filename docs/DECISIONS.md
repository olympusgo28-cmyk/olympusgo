# OlympusGO: Owner decisions on the open questions (7 Nov 2026)

Instructions for an AI coding agent working in the OlympusGO repo (Flutter + Supabase, Riverpod, Freezed).
This file closes most of the 229 questions in `docs/OPEN_QUESTIONS.md`. Treat every rule here as an owner
decision that outranks a "Now:" default in that file. Where this file is silent, the existing default stands.

## How to use this file

1. Read "Precedence" and "Global rules" first. They change behaviour across the app.
2. Work through "Launch blockers" before any new feature. Each has an acceptance test.
3. For each area, apply the rules, set the config values, then mark the listed question numbers
   as **Decided (owner, 6–7 Nov 2026)** in `docs/OPEN_QUESTIONS.md`, copying the decision text.
4. Do not build anything under "Off at launch" or "Awaiting lawyer" beyond keeping the flag off.
   Do not remove that code either.
5. New rules go in `RULES.md` with an R-xxx id; tunable numbers go in config, never hard-coded.
6. If a rule here conflicts with the code in a way that needs a migration or breaks data, stop and
   write the conflict into `docs/OPEN_QUESTIONS.md` as a new question rather than guessing.

## Precedence (Q27, Q173)

`DEVELOPER_CHECKLIST.md` is the final word. Then this file. Then `RULES.md`. Then the rest of `docs/`.
The four missing tie-breaker files (`MASTER_BUILD_PLAN.md`, `SPORTS_AND_FORMATS.md`,
`SCREENS_UPDATE_30OCT.md`, `BUILD_GUIDE.md`) are retired; do not wait for them. If the checklist is
silent, follow this file. The checklist's P5-xx ids stand.

Other project-wide decisions: Riverpod with code generation, record an ADR (Q3). Teams are an
organisation type `org_type = team` with `team_ext`, record an ACR (Q4). Hosting in Singapore; publish the
sub-processor list before Foundation (Q8). Brand form "OlympusGO" (Q10). Design System colours and
fonts (Baloo 2, Nunito Sans, bundled before release; weight 600 max; link `#A83B00`) (Q15, Q32–34).
Build the `field_registry` in its own ticket (Q100).

## Global rules

### G1. Guardian and age rule (replaces Q2, Q7, Q29, Q35, Q43 and the per-feature minor questions)

Build one rule with pluggable verifiers. Never tie the product to Singpass; it is one adapter.

- **Ages.** Singapore: sign-up at 13, adult at 18. Other countries: in `country_config`, closed until
  legal review (Q7, Q39). Launch is Singapore only.
- **Accounts.** 13–17: own account, must link a guardian before anything beyond browsing and free Meets.
  Under-13: own restricted account, no chat, parent books everything; **path built, flag off** until Apple
  and Google rules are confirmed (Q29).
- **Two assurance levels**, declared per feature:
  - `none`: stated birthday. Enough for browsing, Discover, joining free Meets.
  - `strong`: government ID or digital identity. Required before money (paid joins, Shop, lessons, trials),
    chat, hosting, and anything public.
  - Table `guardian_verifications(user_id, method, level, provider_ref, verified_at, expires_at)`.
    Never store an ID number or document.
- **Verifier interface** `IdentityVerifier` behind a seam like the existing `PaymentGateway`. Adapters:
  `singpass_myinfo` (Singapore, scope = date of birth only), `document_review` (support views an ID photo
  and selfie, confirms, then both files are deleted), `manual` (support decision). Allowed adapters and the
  minimum level per feature live in `country_config`. Country comes from the account, not the verifier.
- **Links.** One linked parent is enough. A second parent may link; one withdrawing just unlinks.
  If the linked parent's account is deleted or suspended, the child's account **freezes** (read-only) until
  another verified adult links. Deleting a parent must never cascade to the child's records (fix Q139).
- **Expiry.** The parent's own verification does not expire. The parent can set the child's access to
  lapse on a date (`guardian_links.access_until`); setting or clearing it requires the parent's biometric
  (same gate as Account Centre, Q19/Q38).
- **Parental visibility.** Up to age 17 the linked parent can see everything on the child's account:
  bookings, money, assessments, chat, workout logs (supersedes Q170), clips and reports.
- **Turning 18.** On the 18th birthday the link drops automatically. The player keeps bookings, results,
  assessments, money history, clips and reports (replaces the deletion in Q206), and must accept the adult
  terms on next sign-in.
- **Minors, always:** never on public leaderboards; never publicly listed as a Meet host (Q36); cannot
  publish organizer-pays Meets (Q74); phone numbers and links blocked in all chat (Q48); no autoplay
  (Q215); cannot post to the feed (Q180); one-to-one lessons only when a parent books (Q111, Q112; flag
  for safeguarding review before launch).
- Consent records: `consents(user_id, subject_user_id, purpose, wording_version, method, level, given_at,
  withdrawn_at)`. Every parent consent (video, AI, data) writes a row.

### G2. Money rules

- **No Wallet, ever** (Q45, Q18). Refunds go to the original card or PayNow through Stripe, or to points.
  OlympusGO never holds a withdrawable balance. Do not build any balance a user can cash out.
- **Charge model:** Stripe Connect, separate charges and transfers, manual payouts (Q63). Nothing goes live
  until the lawyer signs off Gate C (Q1, Q46). Test keys only.
- **Chargebacks** (Q72, Q83, Q99): a lost card chargeback is netted against the organizer's or shop's later
  payouts, the same mechanism as Q12. OlympusGO carries it only if that seller never earns again. A refund
  plus a chargeback on one payment is OlympusGO's loss, never the shop's.
- **Second approval** on any payout above `money.payout_dual_approval_sgd = 500` (Q9).
- **Small bank-card orders** (Q96): cap points spend per order so OlympusGO's retained commission is never
  below the card fee: `points_cap = min(commission / 2, commission - card_fee_estimate)`, where
  `card_fee_estimate = amount * 0.034 + 0.50`. Config `shop.card_fee_pct`, `shop.card_fee_fixed`.
- **Leaving a fee-paid free Meet in time** (Q68): the player chooses at leave time. Default: 20 points
  (the points the fee earned), granted immediately, same expiry as earned points. On request: S$2.00 Stripe
  refund to the original method (5–10 working days), OlympusGO absorbs the processing fee. Choice is final.
  Linked teens always get the Stripe refund (they cannot spend points, Q88). Hosts keep the cash refund.
- Accept as built: Q12, Q22, Q23, Q64–67, Q69–71, Q73, Q75–78, Q80–82, Q102, Q103. Q79 is decided with test
  keys.

## Launch blockers (fix before any real user)

| Id | Fix | Acceptance test |
| --- | --- | --- |
| Q40 | Confirm which Supabase project is real; remove the other from `env.dart` or README | One project id in the repo; CI points at it |
| Q41 | Own OTP issue/verify function; direct `/auth/v1/otp` and `/auth/v1/verify` disabled | Calling Supabase Auth directly returns 403; lockout cannot be skipped |
| Q227 | Support inbox in the admin app for `support_requests` | Staff see new help and deletion requests within the admin app; alert on new row |
| Q228 | In-app account deletion: user taps delete, account closes, 30-day undo, then P1-14 deletes | Apple review guideline 5.1.1(v) satisfied; undo works on day 29 |
| Q139, Q208 | Deletion cascade fixed: child survives parent deletion (frozen); voucher FKs no longer block; video rows deleted not anonymised | Deleting a parent with a linked child leaves the child frozen with records intact |
| Q97, Q138 | Staff path for a voided refund on a cancelled or expired order, like `staff_lesson_decide` | Money held with no order can be released or refunded by staff with audit |
| Q105 | Hide `shop_minor` (shop share) from buyer reads via RLS or a view | Buyer's refund query returns no shop-share column |
| Q134 | Scheduled job deletes uploads never submitted after `storage.unsubmitted_days = 7` | Orphan file older than 7 days is gone after the sweep |
| Q226 | Strip location metadata (re-encode) before any video post goes public | Downloaded post carries no GPS tags |
| Q49 | Moderation word list reviewed by native speakers of English, Malay, Mandarin, Tamil | Signed-off list in `config/moderation/` |
| Q112 | Safeguarding review of one-to-one lessons with minors | Written review attached to the ticket |

## Area rules

### Scores, ratings, tournaments

- Rating engine Elo, K 32 for the first 30 matches then 20 (Q30). **Ratings never reset.**
- `rating.points_per_level = 100`, level 4.0 at 1500, repeat matches within 30 days count 75% (Q52).
- Everyone starts level at launch; old test results are not replayed (Q57). Set `ranked = false` on them.
- Only verified organizers' tournaments move ratings. A walk-in must accept (tap) before a match involving
  them is rated (Q58).
- **Umpire rule** (Q53, Q62): in a tournament the umpire's result is final and needs no player
  confirmation. The umpire may correct score or winner until the next match in that bracket starts; after
  that only staff may, and a staff winner change rebuilds later rounds (`staff_result_correct` must support
  this; admin screen needed).
- In Meets, a doubles score needs confirmation from **both** players on the losing side (Q62).
- PRO level is granted by staff by hand on proof of a national ranking or a named special tournament; stays
  capped below PRO otherwise (Q59).
- **Leaderboards** (Q54): public sport board lists adults by default with opt-out, never under-18s.
  Club boards (including school clubs) are members-only and may list under-18s; the parent can switch the
  child off. Season: `leaderboard.season = quarterly`, resets at the end of each calendar quarter. Optional
  "last 12 months" view on the profile.
- Accept as built: Q6, Q16 (phase 12), Q21, Q26, Q55, Q56 (flags after launch), Q60, Q61. Q20 decided.

### Meets, groups, chat, moderation

- **Waitlist** (Q5): when a spot opens, notify everyone on the waitlist at once; first to tap and pay takes
  it. No queue order, no auto-join, no auto-charge. Remove the 24-hour rule.
- **Attendance** (Q44, Q157): taken at the start. Normal path: the player scans the Meet's QR code; this is a
  request the organizer confirms. Fallback: the organizer taps the player Present on the list. The
  organizer's decision wins. A player may change their own tap until the organizer confirms. The list
  **locks when the session's end time passes**. Money releases then (not before the start, Q65). After lock,
  staff may change attendance only as part of a refund or dispute action.
- Phone numbers and outside links blocked in all chat for everyone (Q48).
- Linked teens may host Meets but never publicly listed (Q36).
- Leagues not built until described (Q50). Q47, Q51 as built. Jobs monitor owned by content staff (Q202).

### Academy and lessons

- Monthly and term fees are paid to the academy directly; the app charges only trials and one-off lessons
  (Q107). Trial fee credit is honoured by the academy itself (Q108).
- **Wrong Present** (Q114): single-session lesson payouts wait `academy.present_hold_hours = 48` after the
  coach marks Present, so the payer can report.
- **Late cancellation is an academy setting** (Q113), shown to the parent before booking:
  `late_cancel_policy = none | credit_back | refund_if_refilled`. The platform enforces the chosen one.
- **Substitute coach is an academy setting** (Q115): `allow_substitute_coach`. When on, the academy may
  offer another licensed coach for a one-to-one; the parent accepts or takes a full refund. When off,
  cancel with full refund.
- **Assessments** (Q121, Q122): readable by every licensed coach at the academy, the parent and the child.
  Only the author edits, shows as edited (Q120). Assessments stay with the academy when a coach leaves.
- One trial per academy per child (Q116).
- Only the payout-account owner can close an academy (Q127).
- Invites by link, QR code or academy ID. **Never by phone number**; drop `academy_invites.mobile` (Q133).
- Accept as built: Q109, Q110, Q111, Q117–Q119, Q124, Q125, Q132, Q135–Q137, Q200.

#### New feature: term credits (NEW-9, phase 2 academy)

- Academy sets `sessions_per_month` on a term product. Paying a term grants that many credits for the month.
- The parent picks any class at that academy with space, one credit per session. Only classes whose level
  matches the student's level are offered. The student's level is set and updated by the academy's coaches.
- Credits expire at month end; the academy can grant extra credits by hand. A default class is set at
  enrolment; the parent swaps when needed. Credits are per academy, never transferable, never cash.

### Shop, points, vouchers, Game (modelled on TikTok Shop)

- Points: 1 point = S$0.10, spend up to half the commission on an item (subject to G2 card-fee cap), flat 10%
  commission, S$2.00 fee earns 40 points (Q31). Earning stays off until the owner sets the weekly cap and
  minimum account age (Q13).
- **Shop never marks ready** (Q90): warn the shop at `shop.ready_warn_days = 5`; auto-cancel with full refund
  at `shop.ready_cancel_days = 7`; show the shop's cancellation rate on its admin page.
- **Staff refund of a whole order that used a voucher** returns the voucher to the buyer (Q161).
- **Voucher farming** (Q141): cap voucher-earning games per account at `game.max_counted_per_week`
  (default 3); staff flagging stays.
- **Which item takes the voucher**: the buyer picks at checkout (Q163).
- **Partner leaves** (Q145): notify the holder; move the voucher to another partner of the same type; if
  none fits, convert to points.
- **Teens in Shop** (Q88): a linked teen's Shop order, points or cash, needs a parent tap before it is placed.
  Under-13s refused.
- **Start work** on a service is allowed only within 24 hours of the slot (Q104).
- **Returnless refunds** (NEW-10): on a reported problem with an item under `shop.returnless_max_sgd = 20`,
  refund without requiring return; cap `shop.returnless_per_month = 2` per account.
- Courts are not booked in the app at launch (Q25). Physio is a referral only, 18+ (Q128, Q131).
- Accept as built: Q84–Q87, Q89, Q91–Q95, Q98, Q101, Q106, Q129, Q130, Q140, Q142–Q144, Q146–Q160, Q162,
  Q164–Q167. Q153–Q156 decided.

### Accounts, sign-in, privacy

- Mobile-first sign-up (Q28). Face ID unlock window 5 minutes (Q19). Biometrics only for tiles (Q38).
- Session stays alive behind Face ID after logout; add "Log out of all devices" to Account Centre (Q42).
- Repeat deletion requests accepted as built until P1-14 (Q229).

## Off at launch (keep the flag off, do not extend)

- `camera.scoring` off (Q24). Video analysis: Q179, Q193–Q199, Q201, Q203–Q205, Q207, Q209, Q210 as built,
  behind `video.analysis_minors` and the Gate F checklist.
- `video.feed` off until the lawyer answers Q213: Q212, Q214–Q225 as built.
- Fitness and AI plans as built (Q168, Q169, Q172, Q174–Q178, Q181–Q187, Q190–Q192), flag off until the
  lawyer answers Q188 and Q189.
- Other countries: Q11 per-currency fee rules, Q126 NROC Singapore only.

## Awaiting lawyer (do not change behaviour; keep the question open)

Q1, Q7 (non-Singapore ages), Q14, Q63, Q123, Q171, Q179, Q188, Q189, Q198, Q211, Q213, Q228 (turnaround).
The lawyer brief lists these by number. When an answer arrives, apply it and close the question.

## Config keys introduced by this file

```
country_config.<cc>.min_age, adult_age, allowed_verifiers[], min_level_per_feature{}
guardian.access_until_requires_biometric = true
money.payout_dual_approval_sgd = 500
shop.card_fee_pct = 0.034, shop.card_fee_fixed = 0.50
shop.ready_warn_days = 5, shop.ready_cancel_days = 7
shop.returnless_max_sgd = 20, shop.returnless_per_month = 2
game.max_counted_per_week = 3
leaderboard.season = quarterly
academy.present_hold_hours = 48
academy.<id>.late_cancel_policy, academy.<id>.allow_substitute_coach, academy.<id>.sessions_per_month
storage.unsubmitted_days = 7
```

## Questions closed by this file

Decided: Q2–Q5, Q7–Q10, Q13, Q15–Q17, Q19–Q23, Q25–Q39, Q41–Q48, Q52–Q55, Q57–Q59, Q61–Q79, Q81–Q96,
Q98, Q99, Q101–Q104, Q106–Q111, Q113–Q122, Q124–Q133, Q135–Q137, Q140–Q167, Q170, Q173, Q200, Q202, Q206,
Q229, and NEW-1 to NEW-11 (the guardian rule, term credits, returnless refunds, leaderboard season).

Launch blockers: Q40, Q41, Q49, Q97, Q105, Q112, Q134, Q138, Q139, Q208, Q226, Q227, Q228.

Off at launch or awaiting lawyer: everything else, as listed above.

## Clarifications (owner, 7 Nov 2026)

The agent asked 21 questions about this file on 7 Nov. The owner's answers below refine the rules above and
win where they differ. Where the owner gave no answer, the agent's stated reading stands and is recorded as
an open question so the owner can overturn it.

1. **Leaving a Meet earns no points (Q68).** The 20-point option above is withdrawn. A player who leaves a
   fee-paid free Meet in time gets the S$2.00 Stripe refund to the original method and nothing else; a
   player who leaves late gets nothing. Hosts keep the cash refund.
2. **Teens may spend points (Q88).** A linked teen's Shop order still needs the parent's tap. The parent
   sets a spending limit per child, in an amount they choose. The limit that applies before the parent sets
   one is open (Q230).
3. **Q63** stays as built (manual payouts) and stays on the lawyer list.
4. **Returnless refunds (NEW-10) apply before collection only**, for now. After collection an order is
   final, as Gate D says.
5. **NEW-1 to NEW-8 and NEW-11** are named in "Questions closed by this file" but no text defines them
   anywhere. Only NEW-9 (term credits) and NEW-10 (returnless refunds) exist. The others are not built
   (Q232).
6. **Who verifies at `strong`.** The owner: the ID check exists to know who is under 18 so they see the
   right content. Read as: the guardian verifies when linking a 13–17 child; the child's birthday is
   stated by the parent; an adult with no child link is not ID-checked. Owner to confirm (Q233).
   **Singpass is not integrated.** The adapters are `document_review` and `manual` only; the seam stays so
   a digital-identity adapter can be added later.
7. No answer; covered by 6.
8. ID photo and selfie from `document_review`: deleted on the decision, and at most 7 days after upload
   (Q236). On the lawyer list.
9. A parent reading the child's chat is fine. Chats that include an under-18 show a notice that a parent
   may read them (Q235, wording to confirm).
10. **Linked parent deleted or suspended.** Under-13: the account freezes read-only until another adult
    links. 13–17: the account keeps what an unlinked teen may do (browse, join free Meets, keep existing
    bookings) until another adult links (Q234).
11. **Organisation types are Club and Team.** `org_type = team` is confirmed, with the merge migration and
    an ACR.
12. **Vouchers.** Each voucher type sets its own expiry; an unused voucher expires and leaves the account
    automatically (as built: `voucher_types.expiry_days`, default `voucher.expiry_days`). A deleted
    account's vouchers go with it; its orders and redemptions keep their amounts and lose the link (Q139).
13. **Attendance.** A scan marks the player Present at once. The organizer can change any mark until the
    list locks. There is no separate confirmation step; "the organizer's decision wins" above means the
    organizer can overturn a scan before the lock.
14. **Release.** Money releases only when the list locks at the session's end time. R-HOLD-2's
    "24 hours after the activity ends" fallback is removed.
15. **Verified organizers are built later.** The rating check reads the organisation's verification mark;
    the staff screen that sets it comes later. Until it exists no tournament moves ratings. Walk-ins must
    accept before a match involving them is rated.
16. **Umpire** means the tournament organizer and anyone they name as crew.
17. **Term credits.** Term fees are paid to the academy directly, so the academy marks the term paid in
    the app; that grants the month's credits, one per training session.
18. **Deletion.** Refunds owed go out when the request is made, within 24 hours. The profile is hidden at
    once. The 30-day undo stands (Q237).
19. **Q40** waits for the owner to say which Supabase project is real.
20. **Q49 and Q112** are reviews the owner does, not features. The owner's note about genuine reviews and a
    verified badge for clubs, academies and shops is a new feature request, recorded as Q231 and not built.
21. **AGENTS.md** precedence is updated to this file's order.

Defaults the agent settles, unless the owner objects: in Q96 `amount` is the item price before the points
discount, and the cap is clamped at zero; in Q5 the offer stays open until the spot is taken or the Meet
starts; Q226 re-encodes in the analysis worker with ffmpeg; Q41 is rechecked against its 403 acceptance
test before any change.
