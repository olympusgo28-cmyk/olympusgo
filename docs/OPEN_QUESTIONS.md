# Open questions

Decisions an agent must not make. Each row says what it blocks and the default to build with until the owner answers. When the owner decides, change **Status** to Decided, write the answer and the date, and update `RULES.md`.

**How agents use this file**

- If your ticket depends on a row marked Open, build only what does not depend on it, or build with the suggested default **in configuration** (never hard-coded) and say so in your summary.
- If you find a new question, add a row at the bottom with the next number. Do not delete rows.
- Never mark a row Decided yourself.

| # | Question | Blocks | Suggested default | Status |
| --- | --- | --- | --- | --- |
| Q1 | Payments model: may Olympus hold customer money until attendance and keep a refund Wallet without a payments licence (MAS in Singapore)? Merchant of record, or connected accounts? | All payment work (phase 9) | Stripe Connect, player pays the platform, manual payouts. Do not write payment code until a lawyer confirms | Open |
| Q2 | Under-18 sign-up in Foundation: build `guardian_links` and parent approval in phase 1, or block under-18 sign-up until the guardian model ships? | Phase 1 sign-up | Build guardian links in phase 1, since the design has the 13 to 17 and under-13 paths | Open |
| Q3 | Riverpod with code generation, or manual providers? | Phase 0 | Decide in week 1 and record an ADR | Open |
| Q4 | Are teams an organisation type (`org_type = team` with `team_ext`)? | Phase 4 | Yes, recorded by a new ACR | Open |
| Q5 | Waitlist inside 24 hours of the start: offer with expiry, or auto-join and charge? | Waitlist (phase 3) | Offer with a 30-minute expiry more than 24 hours out; auto-join inside 24 hours | Open |
| Q6 | Does Discover need a login? Can a spectator follow a tournament without an account? | Phase 2, tournaments | Venues, public activities and tournament schedules and scores open by link; players and statistics need sign-in | Open |
| Q7 | Minimum sign-up age and how guardians are verified, per country (Malaysia, New Zealand) | Phase 1 for those countries | Singapore 13 and 18; others in `country_config` after legal review | Open |
| Q8 | Hosting region and the published sub-processor list | Phase 0 | Singapore; publish the list before Foundation | Open |
| Q9 | Payout amount above which a second staff member must approve | Payouts (phase 9) | Set with finance | Open |
| Q10 | Brand form shown in the UI: "OlympusGO" or "OLYMPUS GO" | Phase 0 copy | "OlympusGO", as the design system writes it | Open |
| Q11 | Platform fee minimum in ringgit and NZ dollars | Malaysia and New Zealand launch | Store per currency in `fee_rules`; no default | Open |
| Q12 | If an organizer's balance cannot cover card fees from a cancellation, is the shortfall taken from later earnings? | Refunds (phase 9) | Yes, netted against later payouts; flag to staff if unpaid after 30 days | Open |
| Q13 | Points: weekly earning cap and minimum account age before redeeming | Points (phase 9) | Config values, no default; points earning off until set | **Partly decided (owner, 1 Nov).** Points are built, with earning off until the owner sets both values and switches it on. The values are still open |
| Q14 | Years receipts and payment records are kept after an account is deleted | Deletion, retention job | Lawyer to confirm; keep everything until then | Open |
| Q15 | Which visual style is final? The OlympusGO Design System (orange `#E8590C`, Baloo 2 and Nunito Sans) or the style on most Club Screen Mockup boards (tangerine `#F28500`, Barlow) | All UI | The OlympusGO Design System. Canvas boards give layout, copy and behaviour only | Open |
| Q16 | Where Shop, sellers, creators and campaigns sit in the build order. The PRD puts them in public launch; the ACR phases don't name them | Estimates | Agree before quotes; default phase 12 | Open |
| Q17 | Confirm or change the rules assumed while drawing (PRD "Rules assumed while drawing" and the 13 in the handoff): waitlist, guests, court fee, trial class, commissions, payout timing, under-18 approval, campaign rewards, free practice, challenge attempts, typed codes, Finals Day ticket, academy fee, deletion undo, children's accounts, receipts, recovery wait, code lockout, spending limits, SMS rule, leaderboard minimum, Circles | Each feature | Build as in `RULES.md` with values in config | Open |
| Q18 | Can a payment be split between the Wallet and a card? | Payment sheet | No; the Wallet pays only when it covers the total | Open |
| Q19 | How long Account Centre stays unlocked after Face ID | Phase 1 | 5 minutes | Open |
| Q20 | Launch sport | Seed data, scoring rules | Badminton, then pickleball | Open |
| Q21 | Tournament and sport profile decisions: who may score point by point; are casual matches in win rate; which five tiles lead the badminton Overview; is point-by-point scoring in launch; is tennis a sport | Tournaments PRD items | Umpires only; ranked only; win rate, points won %, deciding-game record, average margin, streak; point-by-point after launch; tennis later | Open |
| Q22 | Rounding of percentage fees to the cent | Fee calculation | Round half up | Open |
| Q23 | How long a Meet spot is held while payment completes | Joining paid Meets | 10 minutes | Open |
| Q24 | Is the badminton camera feasibility test passed? | Phase 7 camera work | Camera features stay off (`camera.scoring` flag) | Open |
| Q25 | Venue owner's side: are courts booked in the app at launch? If yes, the owner's screens must be designed first | VEN-2, VEN-3 | Court booking off at launch until designed | **Decided (owner, 1 Nov).** No: courts aren't booked in the app at launch. 4b builds Shop first, and P4b-01 stays off |
| Q26 | Is "Wyse Active" the academy to use in examples and seed data instead of "Smash Academy"? | Seed data only | Keep "Smash Academy" as fake data | Open |
| Q27 | **Which document wins?** `DEVELOPER_CHECKLIST.md` (30 Oct) names `MASTER_BUILD_PLAN.md` as the tie-breaker, but that file, `SPORTS_AND_FORMATS.md`, `SCREENS_UPDATE_30OCT.md` and `BUILD_GUIDE.md` were not provided. The dev kit in `docs/` is older (12 Oct) | Every conflict below | Built so far with: checklist first, then `RULES.md`, then the rest. Send the missing files to confirm | Open |
| Q28 | Sign-up: checklist says mobile first with email optional; `RULES.md` R-ACC-1 says email | Sign-up | Mobile first, as the checklist says | Open |
| Q29 | Under 13: checklist says their own restricted account; `RULES.md` R-AGE-1 says a profile inside a parent's account with no login | Accounts for children | Own restricted account, as the checklist says | Open |
| Q30 | Rating engine: checklist says Elo; `RULES.md` R-RAT-2 says Glicko-2. Owner decided on 31 Oct: Elo as the checklist says, K 32 for the first 30 matches then 20 (open decision 19), junior badminton 15 points cap 21 with the 11-point variant off (open decision 20) | Phase 3 | Elo, in `app_settings` | Decided (owner, 31 Oct) |
| Q31 | Points value and shop commission: checklist says 1 point = S$0.10 and 10%; `RULES.md` says 1 point = S$1.00 and 8%; the earlier build used 8% | Phase 4 | Not built yet. Checklist numbers, in configuration, when it is | **Decided (owner, 1 Nov).** Checklist numbers, in config: 1 point = S$0.10, spend up to half the commission on an item, flat 10% commission, a S$2.00 fee earns 40 points |
| Q32 | Font weight: checklist says nothing above 600; `DESIGN_SYSTEM.md` uses 700 and 800 | All text | 600 maximum, as the checklist says | Open |
| Q33 | Link colour: checklist says `#A83B00`; `DESIGN_SYSTEM.md` says `#C94A00` | Links | `#A83B00`, as the checklist says | Open |
| Q34 | Fonts: the checklist is silent. `DESIGN_SYSTEM.md` says Baloo 2 and Nunito Sans; the earlier build used Archivo and Figtree | All text | Baloo 2 and Nunito Sans. Both are fetched at run time for now and should be bundled before release | Open |
| Q35 | Should a restricted player (under 18, no parent yet) be able to join or host Meets? The checklist lists what they cannot see but does not mention these | Restricted mode | They cannot join or host. Safer to open up later than to close down | Open |
| Q36 | Can a linked teen host a Meet? Open decision 9 only covers vouchers | Hosting | Yes, but never publicly listed | Open |
| Q37 | Sports on the earlier build's Passports (basketball, football, running, swimming, cycling, hyrox) are not in the checklist's lists | Catalogue | Kept as drafts: on Passports, no new Meets | Open |
| Q38 | Face ID with a passcode fallback cannot be combined with "a fresh code is needed if biometrics change": on iOS a passcode would still unlock the token after a new face is enrolled | Saved accounts | Biometrics only for tiles; no biometrics means a code | Open |
| Q39 | Countries: the earlier build offered Indonesia and Thailand; the checklist says Malaysia and New Zealand | Sign-up | All closed except Singapore until ages are confirmed | Open |
| Q40 | The app and README name two different hosted Supabase projects (`iikojvrmiadzemqqixhz` in `env.dart`, `sfkylxlwbjculhuxoimd` in the README). Which is real? | Deployment | Neither was touched | Open |
| Q41 | **Sign-in can be sidestepped by calling Supabase Auth directly.** `/auth/v1/otp` reveals whether a mobile is registered, and `/auth/v1/verify` skips the 5-code lockout. `resolve-login` protects the app's own path only. Closing this means issuing and checking codes in our own function and turning off direct OTP, which changes how sessions are created | **Gate A** (enumeration tests) | Fixed on 31 Oct, and fixed again after review found the internal address could be derived from a public user id. `resolve-login` issues and checks every code, Supabase Auth holds no real mobile or email, and each internal address is random and private. Live senders not yet run against the real services | Decided (owner, 30 Oct: fix it first) |
| Q42 | Should logging out keep the session alive for the saved tile? Today it does, held behind Face ID, until the tile is removed. Removing a tile on a signed-out phone cannot end that session on the server | Saved accounts | Keep. Add "log out of all devices" to Account Centre | Open |
| Q43 | A child with their own second phone number can still lie about their birthday and become their own "parent". The checklist asks for 18 or over only | Parent links | Accepted for now. Decide whether a parent needs an identity check before the closed pilot | Open |
| Q44 | R-ATT-1 closes attendance at 23:59 on the day. A Meet starting at 23:30 would close after 29 minutes, and one crossing midnight could not be marked afterwards. Should attendance close at the end of the day the Meet ends instead? | Late Meets | Built as R-ATT-1 says | Open |
| Q45 | **Wallet.** Owner decided on 30 Oct: no Wallet. Refunds go to the original PayNow or card, as the checklist says. R-REF-1, R-REF-2, R-WAL-1 to 4, Q18 and the Wallet screens are superseded and removed in Phase 4 | Phase 4 | No Wallet | Decided (owner, 30 Oct) |
| Q46 | Phase 4 test-mode payment code: the checklist allows it now, but R-HOLD-6 and Q1 say no payment code until a lawyer confirms. Owner to confirm the checklist wins before Phase 4 starts | Phase 4 | Stripe test mode only, once confirmed | **Decided (owner, 31 Oct).** Yes, test mode only. The checklist wins over R-HOLD-6 for test-mode code. Nothing goes live until the lawyer signs off (Q1, Gate C) |
| Q47 | Reporters: the checklist says a neutral acknowledgement only; the PRD (SAF-3) shows the result and offers a second look. Built as the checklist says, so the second-look screen no longer appears | Moderation | Neutral only | Open |
| Q48 | What should a message containing a phone number or outside link do: blocked, as built, or sent and flagged? Should it apply to adults too? | Chat | Blocked for everyone, as built | Open |
| Q49 | The moderation word list is a small starter set. It needs review by native speakers of English, Malay, Mandarin and Tamil before the pilot | Moderation | Starter list | Open |
| Q50 | Leagues (P2-03): the checklist lists clubs, teams, leagues, but no document says what a league is or how it differs from a tournament or a team. Not built | Groups | Not built until described | Open |
| Q51 | Group chat still restores the text on a failed send, rather than the optimistic send and retry that direct messages now have. Is that acceptable for now? | Chat | As built | Open |
| Q52 | Rating numbers no document gives: how many rating points equal one level, and how much a repeat match counts. Used 100 points per level with level 4.0 at 1500, and each repeat within 30 days counting 75% of the last | Ratings | `rating.points_per_level`, `rating.repeat_factor_pct`, `rating.repeat_window_days` | Open |
| Q53 | Staff corrections (R-SCO-3) refuse to change the winner of a tournament match, because later matches would need rewriting. Should they be able to, and what happens to the later rounds? There is also no admin screen for it yet, only the `staff_result_correct` action | Corrections | Winner stays; score and ratings can change | Open |
| Q54 | Leaderboards: R-LDR-1 says listing is opt-in, and asks for a monthly area board with 4 matches. R-LDR-2 limits ranking points to verified organizers with 16 entries, by tier, resetting each January. The checklist asks only for a board by sport and country. Built as the checklist says: adults are listed by default, and points use the existing placing table with no tier, entry or season limit | Leaderboards | As the checklist says | Open |
| Q55 | An organizer who is also a player can't decide a disputed score in their own match, and a tournament host's own match is recorded for the draw but not rated. Staff decide those. Is that the right rule, or should a second organizer exist? | Scores | Refused, staff decide | Open |
| Q56 | R-RAT-5 also says sudden rating drops, jumps and closed groups are flagged. Repeat matches count less, but nothing flags these yet, and no document says what counts as sudden or who sees the flag | Ratings | Not built | Open |
| Q57 | Existing confirmed scores become results with `ranked = false`, so they don't change anyone's rating. Should old results be replayed through the rating engine before launch? | Ratings | Not replayed | Open |
| Q58 | Anyone can create a tournament, and its host's score is final, so two friends can farm ratings through a tournament they run. R-RAT-1 says every tournament match is ranked. Meets have the same gap: a host can add any adult as a walk-in, and a second account can enter a win against them that the host then decides. Should only verified organizers' tournaments move ratings, as R-LDR-2 says for points, and should a walk-in have to agree before being rated? | Ratings | Any tournament that has started, except the host's own matches | Open |
| Q59 | R-RAT-3 says PRO needs verification, but nothing verifies it yet, so ratings stop at 7.9 and chosen levels stop at 7.0. How is PRO verified? | Ratings | Capped below PRO | Open |
| Q60 | If attendance goes from Present to Absent the rating is taken back, unless the organizer played in that match. If it then goes back to Present the result stays unrated. A result also waits unrated until everyone is marked Present, so an organizer who played can hold back their own loss by not marking attendance. What should happen when attendance closes with a confirmed result still waiting? | Attendance | As built | Open |
| Q61 | How long does a dispute wait for its organizer before staff see it? No document says. Used 72 hours | Scores | `score.staff_after_hours` | Open |
| Q62 | On a doubles match, one player on the other side confirming counts for both, as R-SCO-2 says "the other side". A partner could confirm a loss the other player disputes. Should both have to confirm? | Scores | One confirmation | Open |
| Q63 | Charge model. Phase 4a uses separate charges and transfers: money stays in the platform balance and is transferred only at payout, so debts net in the ledger. This refines ARCHITECTURE 13.1, which says funds are attributed to the connected account at payment. Does it fit the legal basis in Q1? | Payments (Gate C) | Separate charges and transfers | Open |
| Q64 | PayNow QR codes last 1 hour but a spot is held 10 minutes, so money can arrive after the hold ended. What happens then? | Paid join | Seat them if the Meet is open, a seat is free and nobody is queued. Otherwise a full refund with the fee, and Olympus absorbs the processor fee. `meet.reservation_minutes` | Open |
| Q65 | Attendance can be saved 30 minutes before the start, and R-HOLD-2 releases money on that save. A host could then cancel after release | Hold and release | Release no earlier than the start | Open |
| Q66 | R-HOLD-7 limits holds to 90 days. What happens at day 90 if staff haven't decided a held report, and how far ahead can a paid booking end? | Hold and release | Staff decide, nothing automatic. Alert at `money.hold_alert_days` 75. Paid booking must end within `money.max_advance_days` 75 | Open |
| Q67 | With no Wallet, a PayNow refund that fails, or is past Stripe's 90-day window, has nowhere to go. Stripe says to refund by another method | Refunds | Staff record a manual bank transfer, and the refund stays pending until then | Open |
| Q68 | Players-pay-fee free Meet: a player who leaves in time gets S$0, since their whole payment is the fee, while a host who gives up a spot gets S$2.00 back. Is that intended? | Refunds | As written | Open |
| Q69 | Is the fee per seat or per order, for guests and several tickets? Three S$10 tickets give S$6.00 per seat, or S$3.00 on the order | Quotes | Per unit, so one seat can be refunded alone | Open |
| Q70 | R-REF-11 charges an organizer's cancellation card fee to them. Does that include the PayNow processor fee? | Refunds | No. Olympus absorbs the PayNow fee | Open |
| Q71 | When an organizer cancels, are the S$2.00 fees they paid for a free Meet refunded to them? | Refunds | Yes, as everything paid | Open |
| Q72 | Who bears a lost card chargeback? | Disputes | Olympus until decided. PayNow has no chargebacks | Open |
| Q73 | R-HOLD-4 keeps money held on a report. If any user can report, anyone can freeze an organizer's money | Hold and release | Only a participant's report opens a hold | Open |
| Q74 | Linked teen hosts can't hold a card. Can they run an organizer-pays free Meet? | Organizer pays | No. Under-18s can't publish organizer-pays Meets | Open |
| Q75 | A paid Meet's date moves later: no rule exists outside tournaments | Refunds | Full refund within 48 hours, as R-REF-17 | Open |
| Q76 | `allow_refunds` is stored on activities but no rule uses it | Refunds | Ignored, and the option is hidden | Open |
| Q77 | A vendor never completes identity checks, so their earnings can't be paid | Payouts | Publishing stays allowed, payout is blocked, alert at `money.vendor_alert_days` 60 | Open |
| Q78 | Paid Meets that need host approval: no step moves a player from requested to joined, so nothing would charge them | Paid join | Refused until an approval step exists | Open |
| Q79 | Stripe lists PayNow as unsupported for in-app payments, and on a phone the customer saves a QR image and uploads it to their bank app. Does the real PayNow flow open a hosted Stripe page instead of an in-app sheet? | Stripe test keys | Decide with test keys. The app's `PaymentGateway` hides this choice | Open |
| Q80 | A player already on a paid Meet can't add a guest yet, because a guest needs a second held seat on the same place. Should that be built? | Paid join | Refused with a clear message. Add a guest when you join | Open |
| Q81 | Walk-ins added by a host on a free Meet where the organizer pays: is the S$2.00 owed for them? R-HOLD-5 says cash walk-ins are attendance only | Organizer pays | No fee on walk-ins | Open |
| Q82 | Releasing some, not all, free tickets when the organizer's fee is still being charged or failed and became a debt: it isn't reduced per ticket until all of them are released | Organizer pays | Reversed in full on full release only | Open |
| Q83 | A lost chargeback stays in `disputes_open` and the organizer is still paid, so Olympus carries the loss (Q72). How should staff write that off? | Disputes | Stays open on the books until finance decides | Open |
| Q84 | Several shops in one cart mean several payments, and a buyer scans a PayNow code for each. Is that acceptable? | Checkout | Yes: one order, one shop, one payment | Open |
| Q85 | Money that lands after a Shop hold has ended never takes the item, unlike a Meet, because the stock or points may be gone | Checkout | Full refund | Open |
| Q86 | Shop rounding, and whether points reduce the base the commission is charged on | Checkout | Commission half up per unit, the points cap rounds down, and points don't reduce the base | Open |
| Q87 | Points returned after their own expiry has passed | Points | Keep the original expiry, so they lapse | Open |
| Q88 | Can teens buy in Shop and use points? What about linked under-13s? | Checkout | Teens as with paid joins. Under-13s refused | Open |
| Q89 | A buyer never collects a ready order | Handover | Released to the shop, as the checklist says, and the goods stay there | Open |
| Q90 | A shop never marks an order ready, and the buyer never taps | Handover | No automatic release: an alert, and staff decide | Open |
| Q91 | A buyer takes the goods, doesn't tap, then cancels for a full refund before release | Handover | The shop hands over only once Collected shows on its screen. There is no shop-side handed-over tap | Open |
| Q92 | Who bears the card fee when a buyer cancels before collecting? | Refunds | OlympusGO | Open |
| Q93 | Can staff refund after release, given no refunds after the buyer leaves? | Refunds | Staff only, audited, split between the shop and the commission | Open |
| Q94 | Partial refunds by amount, not just by line and quantity | Refunds | Line and quantity only | Open |
| Q95 | Points on fees the organizer paid, and the full fee when a player pays for a guest or several tickets | Points | None on organizer-paid fees. The full fee earns for whoever paid it | Open |
| Q96 | Cheap card orders with full points can lose money: on a S$10.00 item OlympusGO keeps S$0.50 against about S$0.82 in card fees. Should there be a minimum order, or a lower cap on points? | Shop economics | Neither, for now | Open |
| Q97 | A refund fails and staff void it on a cancelled order. The money stays in `held` with no order to release it to | Shop refunds | Stays held, raises `hold_aging`, staff decide. Stock and points already returned aren't taken back | Open |
| Q98 | A buyer abroad books a service in their phone's time. `AGENTS.md` says show the venue's zone | Shop services | Device time, since launch is Singapore only | Open |
| Q99 | A refund and a lost chargeback on one payment pay the buyer twice. Who bears it | Disputes | OlympusGO, never the shop | Open |
| Q100 | `field_registry` exists only in `DATA_MODEL.md`, so new columns (`orders.report_note`, `points_blocks.reason`, `refunds.order_lines`) can't be registered as `AGENTS.md` asks | Privacy | Build the registry in its own ticket | Open |
| Q101 | A suspended owner's open orders. The shop stops selling, the owner can't mark ready, and a buyer's collect still earns them money that waits on their payout | Shop | Payouts wait, as in 4a. Staff decide stale orders | Open |
| Q102 | A dispute for part of a payment, or on a part-refunded one | Disputes | Closes nothing by itself. Raises `dispute_partial`, staff can still refund by item, and the buyer can't cancel. Owed refunds still go out, so a buyer could be paid twice for the part the bank returned until staff check | Open |
| Q103 | `charge.dispute.created` debits clearing for an inquiry too, though no funds moved | Disputes | Reversed when it closes, so reconciliation can differ while one is open | Open |
| Q104 | A shop can tap Start work on a service days before the slot, which ends the buyer's right to cancel | Shop services | Allowed. The buyer can still report a problem | Open |
| Q105 | A buyer can read `shop_minor` on their own refund rows, so a shop's share is visible through a direct read | Privacy | Accepted: commercial data, not personal | Open |
| Q106 | A shop marks an order ready late. Should the buyer get a full `shop.release_hours` from then | Shop | Yes: payout waits for the later of `release_at` and ready plus 48 hours | Open |
| Q107 | Monthly and term fees: when does the money reach the academy, and what does a mid-term withdrawal get back? | Academy fees (ACD-9) | Paid to the academy directly, not in the app. Owner, 1 Nov: trials and one-off lessons only for now | Open |
| Q108 | A trial fee is "taken off the first month" (R-ACD-4), but months are now paid directly | Trials | The academy honours it itself, and the app says to ask them | Open |
| Q109 | Trial and lesson prices. R-ACD-4's S$15.00 is Assumed | Lessons | Set per class or slot by the academy. Nothing is offered until a price is set | Open |
| Q110 | Does a paid trial still need the academy to accept it? (ACD-2) | Trials | No, it's instant, and a decline is an academy cancel with a full refund | Open |
| Q111 | Can an under-18 book their own lesson? | Lessons, minors | No, a linked parent books | Open |
| Q112 | An under-18 alone with a coach on a one-to-one | Minors | Allowed if a parent books. No chat is added. Worth a safeguarding view before launch | Open |
| Q113 | A place given up late: can it be sold again? | Lessons | No, it stays taken | Open |
| Q114 | A coach marks Present and it's found later the lesson didn't happen. Attendance releases at once, so the payer may have no time to report | Lessons | Staff can refund after release, as Q93, and it comes from the owner's earnings | Open |
| Q115 | A substitute coach on a one-to-one | Lessons | Not supported. The academy cancels with a full refund | Open |
| Q116 | Limit on trials per student | Lessons | None | Open |
| Q117 | A one-to-one slot that overlaps the coach's weekly class | Lessons | Allowed. The database stops overlapping slots only | Open |
| Q118 | A weekly class moves in `time` mode after someone has paid for that date. R-REF-17 gives a full refund on an organizer change | Lessons | Payers are told. `academy_save_class` refuses a move, but a one-off notice doesn't refund | Open |
| Q119 | Who can make assessment templates? | Assessments | The head coach | Open |
| Q120 | Can a coach correct an assessment? | Assessments | Yes, only the coach who wrote it, and it shows as edited | Open |
| Q121 | Assessments after the assigning coach leaves | Assessments | The coach loses access, and the player and parent keep it. A new coach can't see the history | Open |
| Q122 | The head coach can't read an assessment they didn't assign. Is that what you want? | Assessments | Yes, as the checklist says | Open |
| Q123 | How long a child's assessments are kept once they leave an academy | Children's data | Until the account is deleted. The lawyer's children's data review should set this | Open |
| Q124 | Licence expiry | Coaches | Stops new classes and slots, and existing classes stay. Staff enter nothing: the coach states the date and staff check it | Open |
| Q125 | Which staff role reviews business and coach documents? | Verification | `content` | Open |
| Q126 | Must every coach hold an NROC licence, for every sport? R-ACD-1 says so, but NROC is Singapore only | Malaysia, New Zealand | Yes, Singapore only for now | Open |
| Q127 | Who can close an academy that has an owner and a different head coach? | Academy | The head coach, as before. The owner of the payout account isn't asked | Open |
| Q128 | Can a minor tap a physio referral? | Services | 18 and over only | Open |
| Q129 | How the reference code reaches the partner | Services | A `ref` link parameter, one code per partner, so no person is identified | Open |
| Q130 | Does a partner pay for referrals, and how long are referrals kept? | Services | No fee recorded. Kept until the account is deleted | Open |
| Q131 | Shop services list recovery (SHP-7), while the checklist makes physio a referral only | Shop, Services | Physio goes through referrals, not the Shop. Other Shop services are unchanged | Open |
| Q132 | A block made after enrolment. A coach who is blocked by a parent still sees the child on the roster, and their name still shows on the academy page (R-PRV-4) | Blocks, academy | The coach keeps the roster so the class can run. A block stops assessments, enrolling and new bookings | Open |
| Q133 | `academy_invites` keeps raw mobile numbers indefinitely, readable by any licensed coach at the academy | Privacy | Kept for now. Set a retention period with the lawyer's data review | Open |
| Q134 | A file uploaded but never submitted, or uploaded after a check, stays in the bucket. SQL can't delete from storage | Privacy | One file per person per purpose, so it can't grow. A scheduled clean-up is needed before launch | Open |
| Q135 | A taught lesson the coach never marked, then a full chargeback across the release time: the academy gets nothing, where a marked one is paid and OlympusGO carries it (Q83) | Lessons, disputes | Treated as not delivered | Open |
| Q136 | Past lessons at an academy staff have rejected: does the held money still go to the owner? | Lessons | Yes, what was taught is still paid. Upcoming lessons are refunded in full | Open |
| Q137 | A coach's licence expires after a lesson is booked | Lessons | The booking stands. A refused licence ends it, an expired one doesn't | Open |
| Q138 | A voided refund on an expired Shop order has no way out, as on a lesson before this fix | Shop | Unfixed in the Shop, and only an alert shows it. It needs a staff path like `staff_lesson_decide` | Open |
| Q139 | Account deletion: `academies.owner_id` and `academy_students.parent_id` cascade, which would take a child's records, `assessments.coach_name` outlives the coach, and `vouchers.owner_id` cascades while `voucher_redemptions.voucher_id` and `orders.voucher_id` block it, so deleting someone who used a voucher fails | Account deletion | No deletion flow exists yet. Must be settled before one is built | Open |
| Q140 | Voucher A's amount and which shop funds it (decision 17) | Organizer rewards | Set per voucher type in admin. Nothing is issued until a type exists, and a shop must agree in writing | Open |
| Q141 | The same few friends meeting 6 times to farm vouchers | Organizer rewards | No extra limit at launch. Staff can see every game and flag the account | Open |
| Q142 | Attendance corrected after a game has counted | Organizer rewards | The count stands and no voucher is taken back | Open |
| Q143 | A voucher already used when a game is found to be wrong | Vouchers | It stays used, and staff handle it | Open |
| Q144 | Partial refund of the item a voucher was used on | Vouchers | Refund what was paid. The voucher comes back only if the whole order is cancelled | Open |
| Q145 | A shop stops being a partner while its vouchers are live | Vouchers | They stay in the wallet and can't be used. Staff switch the voucher type off, or the shop goes inactive. Nothing tells the holder yet | Open |
| Q146 | An organizer's own QR check-in | Organizer rewards | Not required when they took a paid spot | Open |
| Q147 | Quest rewards in points | Campaigns | None, as points come only from playing (R-PTS) | Open |
| Q148 | Under-18s on the Game tab | Campaigns | They see campaigns and can't join (decision 10) | Open |
| Q149 | Voucher B's expiry when court booking opens | Vouchers | Expiry days start that day | Open |
| Q150 | Do sessions before joining a campaign count? | Campaigns | No, only from the day you join | Open |
| Q151 | Difference between play and attend sessions in quests | Campaigns | Play is Meets and tournaments. Attend is any activity | Open |
| Q152 | A voucher's terms when staff edit its type | Vouchers | Only the name, active and reward switch can change. Issued vouchers keep their amount | Open |
| Q153 | Voucher B when courts aren't booked in the app | Organizer rewards | Issued and held, redeemed once court booking exists | **Decided (owner, 1 Nov).** Issue it, redeem later |
| Q154 | Who earns the rewards, and must they pay? | Organizer rewards | The organizer | **Decided (owner, 1 Nov).** The organizer earns them. They needn't pay the S$2.00 unless they want to count towards the 6 Present. Participants must pay the platform fee |
| Q155 | The reward ladder after game 24 | Organizer rewards | Carries on | **Decided (owner, 1 Nov).** Every 4th game gives 3 Voucher A, and every 8th also gives 1 Voucher B |
| Q156 | The old Club reward (R-CLB-7) | Clubs | Removed | **Decided (owner, 1 Nov).** Removed, replaced by organizer rewards |
| Q157 | What proves a player attended, for quests and counted games? | Campaigns | For quests, a session they kept their spot in, with attendance closed for the day, where the organizer scanned them or saved them on the list. For a counted game, the organizer's scan (the checklist's "the host scans players in"). A player's own check-in proves nothing alone, because the server can't tell they scanned anything, but it doesn't stop the organizer confirming them | Open |
| Q158 | Games played before payments open | Organizer rewards | They still rank the group. They get no game number and earn nothing, because nobody could pay the platform fee | Open |
| Q159 | Vouchers held by a flagged account | Vouchers | They can't be spent or earned while flagged, and work again if the flag is lifted. Quest progress catches up at their next session. Badges are hidden the same way, rather than deleted | Open |
| Q160 | A game that counted, then a dispute or refund undoes a payment | Organizer rewards | The count stands and no voucher is taken back, as Q142. Staff can flag the account | Open |
| Q161 | A staff refund of a whole order that used a voucher | Vouchers | The voucher stays spent, as written in Q144. Only a cancelled order returns it. A shop that goes quiet leaves the buyer refunded but without the voucher. **The owner should choose** | Open |
| Q162 | A voucher type switched off | Vouchers | Issued vouchers can't be used while it's off. A quest with that reward waits and pays out when it's back on | Open |
| Q163 | Which item takes the voucher | Vouchers | The dearest item it fits. The buyer doesn't choose | Open |
| Q164 | Who sets voucher amounts | Admin | Payments staff, as with commission. Content staff run campaigns, and both can read games and redemptions. The plan said content staff, and a review moved it because the amount comes out of a shop's money | Open |
| Q165 | Changing a live campaign's end date | Campaigns | It can run longer but not end sooner. To stop it early, staff end it | Open |
| Q166 | Staff end a campaign while sessions are being played | Campaigns | Ending stops quests at once. A session not yet closed doesn't count | Open |
| Q167 | When a quest's voucher arrives | Campaigns | Within minutes of attendance closing, at midnight after the session, so a correction that evening can't leave a voucher behind | Open |
| Q168 | Which exercises suit under-18s | Fitness | Bodyweight and band work only, plus bench and box moves that carry no load. A coach must review the list | Open |
| Q169 | Catalogue size. The board promises 240 | Fitness | About 40 written for launch, until a coach writes more. A coach must review them | Open |
| Q170 | Parents seeing a child's workout log | Fitness | No. Logs are private to the player | Open |
| Q171 | Keeping logs when a player stops using Fitness | Fitness | Until they delete them or the account. Set a period with the lawyer's data review | Open |
| Q172 | Who edits the catalogue | Fitness | Staff, by migration, until an admin screen is needed | Open |
| Q173 | `BUILD_PLAN.md` uses P5-xx for matches, and the checklist uses it for video and Fitness | Docs | The checklist is newer, so its ids stand | Open |
| Q174 | Medical wording on the Fitness boards | Fitness | Changed, since the checklist says no medical claims. Body mass index shows the number with no verdict. "Injury prevention" is "Mobility and balance". The "faster recovery" line is reworded | Open |
| Q175 | One-rep max and body mass index for under-18s | Fitness | Hidden. Adult figures don't suit growing players. The plates calculator stays | Open |
| Q176 | Limits on Fitness | Fitness | 50 programs, 7 days each (the screen offers 1 to 5), 30 exercises a day, 300 sets a workout, 12 hours a workout. One-rep max stops at 12 reps | Open |
| Q177 | Where workout logs live | Fitness | On our server, private to the player. The "stay on this phone" line on My workouts is replaced (owner, 1 Nov) | Decided |
| Q178 | Ultralytics YOLO licence (decision 13) | Video analysis | No Ultralytics. The report covers movement, speed, distance and heatmaps, with no shuttle trajectory until a permissive detector is found (owner, 1 Nov) | Decided |
| Q179 | Licence of the RTMPose model weights, trained on outside image datasets with their own terms | Video analysis | Check before Gate F | Open |
| Q180 | Who can post to the video feed | Video feed | Adults post. Teens only watch people they follow, with no autoplay and a feed that ends. Minors can't post until the lawyer answers decision 14 (owner, 1 Nov) | Decided |
| Q181 | Who can use AI plans | AI plans | Adults only, so no minor's data goes to an LLM (owner, 1 Nov) | Decided |
| Q182 | When an account is deleted, must Fitness data go too? R-ACC-11 gives 30 days to undo, and support does this by hand today | Fitness, privacy | Yes. The support procedure must name `workouts` and `programs`, and removing the login clears them | Open |
| Q183 | Workouts one player can save a day | Fitness | 20 in 24 hours, in `fitness.daily_workouts`. It protects the database, and no one should reach it | Open |
| Q184 | AI plans one player can make a day | AI plans | 3 in 24 hours, in `ai_plans.daily_per_player`. A failed plan counts, because it still cost money | Open |
| Q185 | AI plans across the app a day, to cap cost | AI plans | 200 in 24 hours, in `ai_plans.daily_total` | Open |
| Q186 | Should an AI plan suggest weights? | AI plans | No. The player sets the weight, so the model never prescribes a load | Open |
| Q187 | Goals offered | AI plans | Move faster on court, Get stronger, Keep mobile, All-round fitness. No weight-loss goal | Open |
| Q188 | Workout logs going to an overseas AI provider (PDPA) | AI plans, privacy | Asked once, recorded, withdrawable. The lawyer must check the consent wording and the transfer | Open |
| Q189 | Does the provider keep requests, and for how long? | AI plans, privacy | Check Anthropic's terms for this account before launch, and say so in the policy | Open |
| Q190 | There is no board for AI plan screens | AI plans | Built from the kit, and needs a UX review | Open |
| Q191 | Consent to AI plans | AI plans | Asked once, recorded in `consents`, withdrawable in Privacy and safety. Nothing is sent without it (owner, 1 Nov) | Decided |
| Q192 | Which model writes AI plans | AI plans | `claude-opus-5-5` to start, in `ai_plans.model`, so it can change without a release (owner, 1 Nov) | Decided |
| Q193 | Clip length and size | Video analysis | 3 minutes and 200 MB, in `video.max_seconds` and `video.max_mb`. The worker's own measure of length is what counts | Open |
| Q194 | Job timeout | Video analysis | 15 minutes, in `analysis.job_timeout_seconds`, with 1 retry | Open |
| Q195 | Daily caps on analysis | Video analysis | 10 minutes of clip per player and 10 hours across the app, in 24 hours | Open |
| Q196 | How far a parent can extend a clip | Video analysis | Once, by 90 days. The checklist says they can extend, with no number | Open |
| Q197 | Keeping adults' clips | Video analysis | 90 days, as for children | Open |
| Q198 | People in a clip who didn't agree | Video analysis | A tick box that everyone agreed, the clip is private to the uploader, and no opponent's numbers are stored. The lawyer should check this (PRD open item) | Open |
| Q199 | Rallies in the report | Video analysis | Left out. Good-Badminton counts rallies from broadcast cuts, which a tripod never has. Add as beta only if a movement-based count passes on real clips | Open |
| Q200 | "Use clips to improve the camera system" on the filming screen | Academy | Removed. It was collected and dropped, and nothing trains on clips | Open |
| Q201 | Moderating uploaded analysis clips | Video analysis | None, as they're private to the uploader. Abuse-image matching comes with the feed in 5d | Open |
| Q202 | Which staff role owns the jobs monitor | Admin | Content staff, and it shows no clip, frame or player | Open |
| Q203 | Doubles clips | Video analysis | Singles only, your own side only, and only that side's numbers are stored (owner, 2 Nov) | Decided |
| Q204 | Who adds a clip of an under-18 | Video analysis | A linked parent, with one consent row per video. Teens can't upload. Off until Gate F (owner, 2 Nov) | Decided |
| Q205 | Should a child see their own report? | Video analysis | No, only the parent who added it, for now | Open |
| Q206 | A parent link ends, or a child turns 18 | Video analysis | The clip and its report are deleted at the next sweep, because the parent who added it no longer has a claim. That holds even if another parent is still linked, and the child can't get them either | Open |
| Q207 | Does withdrawing consent remove the report? | Video analysis | No. The clip goes, and the numbers stay, as the filming screen says. A parent can delete the report too | Open |
| Q208 | The account deletion job (P1-14), when it's built | Privacy | It must delete `video_clips`, not anonymise them, or the files are left behind. The sweep's check for files with no clip is the safety net | Open |
