# Business rules

Every rule a developer needs as a number or a condition, in one place, with an id you can name in tests and commits. Where a rule comes from the PRD, its requirement id is given.

**Status of each rule**

| Tag | Meaning | What you do |
| --- | --- | --- |
| Decided | The owner decided it, or the PRD states it as a requirement | Build it as written |
| Designed | Shown on the design canvas, not separately confirmed | Build it, and keep the value in config so it can change |
| Assumed | Listed as an assumption to confirm | Build it with the value in config; it is in `OPEN_QUESTIONS.md` |
| Open | No decision yet | Never invent a value. Build with the suggested default from `OPEN_QUESTIONS.md`, held in configuration, or leave the dependent part out |

**Rule of thumb.** Any number below that is not Decided lives in configuration (`country_config`, `fee_rules`, `app_settings`, `feature_flags`), never in code.

---

## 1. Money basics

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-MON-1 | Amounts are stored as integer minor units (cents) with an ISO 4217 currency: `amount_minor bigint`, `currency char(3)`. | Decided | Architecture 7.10 |
| R-MON-2 | Launch currency is SGD. MYR and NZD come before those countries open, each with its own payment set-up. Money never moves between regions. | Decided | PAY-9, Architecture 13.7 |
| R-MON-3 | Prices are shown as `S$8.00` (two decimals, currency prefix). Ringgit as `RM 14.00`, NZ dollars as `NZ$ 4.00`. | Designed | Canvas |
| R-MON-4 | Rounding: when a percentage gives a fraction of a cent, round half up to the cent. | Assumed | — |
| R-MON-5 | Every movement of money is a ledger entry (double-entry, append-only). Balances are sums of entries. | Decided | Architecture 13.2 |

## 2. Platform fee

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-FEE-1 | Platform fee = 10% of the price, with a minimum of S$2.00, added on top. The payer pays it. The organizer keeps the full price. | Decided | PRD "Platform fee" |
| R-FEE-2 | Minimum fee in MYR and NZD. | Open | Q11 |
| R-FEE-3 | Free Meet where the organizer pays (the default free mode): the player pays nothing; the organizer is charged S$2.00 per player when that player joins. | Decided | PRD fee table, EVT-2 |
| R-FEE-3b | Free Meet where players pay the fee: the player pays S$2.00, the organizer receives nothing. | Designed | Architecture 7.3 (`free_players_pay`), CreateMeetFee |
| R-FEE-4 | Free event ticket: the guest pays nothing; the organizer pays S$2.00 per ticket taken (Decided, EVT-2). When a ticket is released, the organizer's S$2.00 for it is returned (Designed, EventTicketRelease). | Decided / Designed | EVT-2, EventTicketRelease |
| R-FEE-5 | The organizer who plays in her own Meet pays only the S$2.00 platform fee, no session fee. | Decided | MET-7 |
| R-FEE-6 | Shop: the buyer pays no platform fee. Each shop pays a 10% commission (`shop_commission` in `fee_rules`), taken out of its price by default. A switch per shop adds it on top instead, for new orders only. Creators earn nothing on the Shop until 4d decides that. | Decided (owner, 1 Nov, Q31) | Checklist P4b-02 |
| R-FEE-7 | Court booking: 10% platform fee on top, minimum S$2.00. | Assumed | PRD assumed rules |
| R-FEE-8 | **Superseded by owner decision, 30 Oct (Q45): no Wallet.** | Decided | Q45 |

**Fee examples (use as test cases)**

| Case | Price | Fee | Payer pays | Organizer receives |
| --- | --- | --- | --- | --- |
| Paid Meet | S$6.00 | S$2.00 | S$8.00 | S$6.00 |
| Tournament entry, singles | S$15.00 | S$2.00 | S$17.00 | S$15.00 |
| Tournament entry, mixed doubles pair (one payment for the pair by the player who registers) | S$30.00 | S$3.00 | S$33.00 | S$30.00 |
| Team entry | S$60.00 | S$6.00 | S$66.00 | S$60.00 |
| Paid event ticket | S$30.00 | S$3.00 | S$33.00 | S$30.00 |
| Court, 2 hours at S$22.00 | S$44.00 | S$4.40 | S$48.40 | S$44.00 |
| Free Meet, organizer pays | S$0.00 | S$2.00 charged to the organizer | S$0.00 | S$0.00 |

## 3. Holding and releasing money

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-HOLD-1 | The player pays Olympus. Olympus holds the price until the activity's money is released. The fee goes to Olympus at payment. | Decided | PAY intro |
| R-HOLD-2 | Release happens at the first of: the organizer saves attendance, or 24 hours after the activity ends. | Decided | MET-8, PAY intro |
| R-HOLD-3 | Absent players are not refunded, so their price is still released to the organizer. | Designed | EarningsDetail |
| R-HOLD-4 | A report about an activity filed before release keeps that activity's money held until staff decide. | Designed | RefundRules |
| R-HOLD-5 | Walk-ins who pay the organizer in cash are recorded for attendance only; no money goes through Olympus. | Designed | EarningsDetail |
| R-HOLD-7 | The payment company can hold money for at most 90 days, so a held report must be decided before then. | Decided | Architecture 13.1 |
| R-HOLD-6 | The legal basis for holding customer money must be confirmed by a lawyer before any payment code is written. | Open | Q1 |

## 4. Refunds

**Who cancels decides the rule.**

| Id | Who cancels | What the player gets back | Where it goes | Status | Source |
| --- | --- | --- | --- | --- | --- |
| R-REF-1 | Organizer, venue or shop | Everything paid, fee included | The card or PayNow used (Q45) | Decided | PAY-2 |
| R-REF-2 | Player, in time | The price without the fee | The card or PayNow used (Q45) | Decided | PAY-3, MET-6 |
| R-REF-3 | Player, late, or does not come | Nothing | — | Decided | RefundRules |
| R-REF-4 | Shop orders | Everything (there is no buyer fee), back to how they paid | Original method | Decided (No Wallet) | Checklist P4b-03 |

**"In time" means**

| Id | Activity | Cut-off | Status | Source |
| --- | --- | --- | --- | --- |
| R-REF-5 | Meet (and a guest spot) | Before the Meet starts | Decided | PAY-3 |
| R-REF-6 | Paid event ticket | Until 24 hours before the start | Decided | PAY-3, EVT-3 |
| R-REF-7 | Tournament entry | Until registration closes | Decided | PAY-3, TRN-5 |
| R-REF-8 | Court booking | More than 24 hours before | Assumed | PRD assumed rules |
| R-REF-9 | Shop order | Until collected, or until a service is started. Sports equipment is final once collected, pending the lawyer's check at Gate D | Decided (owner, 1 Nov) | Checklist P4b-04 |
| R-REF-10 | Trial class, single class or one-to-one | At least 24 hours before it starts. The price comes back, without the fee (R-REF-2). If the academy cancels, everything comes back (R-REF-1). | Designed | TrialClass, owner 1 Nov |

**Special cases**

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-REF-11 | When the organizer cancels, the card company's fee on each refunded card payment is charged to the organizer's earnings. Example: 5 card payments of S$8.00 refunded, S$0.77 kept by the card company on each, S$3.85 taken from the organizer. Use the real fee from the payment company, not a formula. | Decided | PAY-2, MeetCancel |
| R-REF-12 | If the organizer's balance cannot cover R-REF-11, the shortfall is taken from later earnings. | Open | Q12 |
| R-REF-13 | A member removed or banned from a club gets everything back for upcoming paid Meets of that club. | Decided | GRP-9 |
| R-REF-14 | Tournament: if a doubles partner declines, the pair's payment comes back in full. | Designed | TournamentPay, PartnerSearch |
| R-REF-15 | Tournament: withdrawal for injury or illness with a medical note gets everything back at any time. | Designed | TournamentWithdraw |
| R-REF-16 | Tournament: an event below its minimum entries when registration closes is cancelled and refunded in full. | Decided | TRN-5 |
| R-REF-17 | Tournament: when the organizer changes dates, venue or fees, entrants may withdraw for a full refund within 48 hours of the change. | Designed | TournamentManage |
| R-REF-18 | Deleting an account refunds upcoming bookings in full, fee included. | Decided | Architecture 9.3, DeleteAccount |
| R-REF-19 | Shop: a problem reported before collecting, or before the payout is released, holds the money until staff decide by line and quantity. Nothing is refundable by the buyer after that. An order collected by mistake or never collected goes to staff (Q89, Q93). | Decided, details Open | Checklist P4b-04 |
| R-REF-20 | Refund rules are shown on the payment sheet before paying, and on the Refund rules page. A rule not shown before payment does not apply. | Decided | PAY-1, PAY-4 |

**Refund examples (use as test cases)**

| Case | Paid | Destination | Refund | Organizer effect |
| --- | --- | --- | --- | --- |
| Player gives up Meet spot before start | S$8.00 (S$6 + S$2) | Card or PayNow | S$6.00 | Nothing released for this spot |
| Organizer gives up their own playing spot | S$2.00 fee | Card or PayNow | S$2.00 (owner, 31 Oct) | No card fee charged to them |
| Organizer cancels Meet, player paid by card | S$8.00 | Card | S$8.00 | Card fee on that payment taken from earnings |
| Organizer cancels Meet, player paid by PayNow | S$8.00 | PayNow | S$8.00 | No card fee (Q70) |
| Withdraw from tournament before registration closes | S$33.00 (S$30 + S$3) | Card | S$30.00 | — |
| Withdraw from tournament, injury with medical note | S$33.00 | Card | S$33.00 | — |
| Cancel court more than 24 hours before | S$48.40 (S$44 + S$4.40) | Card or PayNow | S$44.00 | — |
| Cancel court inside 24 hours | S$48.40 | — | S$0.00 | Venue keeps the price |
| Cancel shop order before shipping | S$42.50 | Card | S$42.50 | — |
| Paid ticket refund asked 6 hours before | S$12.00 | — | S$0.00 (organizer may agree) | — |

## 5. Wallet, payouts and points

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-WAL-1 | **Superseded by owner decision, 30 Oct (Q45): no Wallet. Refunds go to the original PayNow or card.** Formerly: the Wallet holds refunds and rewards. | Superseded | Q45 |
| R-WAL-2 | **Superseded by owner decision, 30 Oct (Q45).** Formerly: No top-up at launch. The top-up screen exists but nothing links to it; it sits behind the `wallet.topup` flag, off. | Decided | PAY-5 |
| R-WAL-3 | **Superseded by owner decision, 30 Oct (Q45).** Formerly: Withdrawals are free: to a bank in 1 to 2 working days, or PayNow within minutes. | Designed | WalletWithdraw |
| R-WAL-4 | **Superseded by owner decision, 30 Oct (Q45).** Formerly: The Wallet can pay only when the balance covers the whole total. Splitting a payment between Wallet and card is not designed. | Assumed | Payment sheet, Q18 |
| R-PAY-1 | Organizer payouts run every Monday (the organizer can choose monthly, or off and pay out by hand). Free to a bank; instant PayNow costs S$0.50. | Assumed | PAY-10, PayoutAccount |
| R-PAY-2 | Each payout run is approved by staff. A second staff member approves runs above a threshold. | Designed / threshold Open | ADM-2, Q9 |
| R-PAY-3 | Only the owner of a club or academy can set or change its payout account. Admins and coaches can see earnings. | Designed | PayoutAccount |
| R-PAY-4 | People who get paid (organizers, sellers, coaches, creators) complete the payment company's identity and business checks first. | Decided | PRD dependencies |
| R-PAY-5 | The payment sheet: review (lines, fee, total, pay with), then Face ID or fingerprint, then a receipt. Apple Pay and Google Pay use their own check, with no second prompt. The refund rule and "Olympus holds your payment" show before paying. | Decided | PAY-1 |
| R-PAY-6 | Card details never touch Olympus servers; only the last 4 digits are stored. | Decided | PAY-6, NFR-9 |
| R-PTS-1 | Points earned = 2 × the platform fee paid (a S$2.00 fee earns 40 points), credited to whoever paid the fee, only after the payer is marked Present or their ticket is scanned. Earning stays off until the owner sets R-PTS-5. | Decided (owner, 1 Nov, Q31, Q13) | PAY-11 |
| R-PTS-2 | Points are stored as whole cents of value, in an append-only ledger, and shown as cents ÷ 10. A fee of S$3.30 earns 66 points. | Decided (owner, 1 Nov) | Checklist P4b-05 |
| R-PTS-3 | 1 point = S$0.10 off at partner shops. Points on one item can't exceed half of OlympusGO's commission on it, rounded down, so a S$100.00 item takes up to 50 points. Points come out of OlympusGO's commission, never the shop's money. | Decided (owner, 1 Nov, Q31) | Checklist P4b-05 |
| R-PTS-4 | Points expire 12 months after they are earned. No cash-out, no transfer, lost on account deletion. | Decided | PAY-11, ACC-11 |
| R-PTS-5 | Weekly earning cap (`points.weekly_cap_minor`), and a minimum account age before redeeming (`points.redeem_min_account_days`). No value means no earning and no redeeming. | Open (values) | Q13 |
| R-PTS-6 | New accounts earn no points until the mobile is verified and the player has about 5 confirmed matches. Flagged accounts lose points and badges. | Decided | PRD anti-gaming |
| R-PTS-7 | Points are a separate ledger from money. | Decided | Architecture 13.6 |

## 6. Accounts, sign-in and ages

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-ACC-1 | Sign-up is by email; no password. Country, email, name and date of birth are asked. | Decided | ACC-1 |
| R-ACC-2 | Codes are 6 digits, valid 10 minutes, single use. Sending a new code cancels the old one. | Decided | ACC-1, Architecture 9.1 |
| R-ACC-3 | Resend allowed after 30 seconds (Decided). After 5 wrong codes, a 15-minute lockout (Assumed). | Decided / Assumed | ACC-3, PRD assumed rules |
| R-ACC-4 | Code requests always answer "We sent you a code", whether or not the account exists, with padded timing. Limits apply per target account, per IP and per device, with a CAPTCHA after a threshold. | Decided | ACC-2, NFR-5 |
| R-ACC-5 | A mobile number is required in onboarding and confirmed by text (Decided). WhatsApp is the backup channel (Assumed). One account per verified mobile (Decided). | Decided / Assumed | ACC-3, ACC-4 |
| R-ACC-6 | If the mobile is on another account: offer "Sign in to that account", or a claim. A claim verifies the number, removes it from the old account and emails that account. | Decided | ACC-4 |
| R-ACC-7 | Log in with email or username, then a mobile code. On a phone used before, Face ID or fingerprint replaces the code. | Decided | ACC-7 |
| R-ACC-8 | Account Centre opens only after Face ID, fingerprint or the device passcode, and stays unlocked for a few minutes (set 5 minutes). | Decided / 5 min Assumed | ACC-8 |
| R-ACC-9 | Changing email or mobile needs a code to the other one plus Face ID; the old contact is alerted. | Decided | ACC-9 |
| R-ACC-10 | The email is never shown back, masked or logged. | Decided | Design system, Architecture 9.1 |
| R-AGE-1 | 18 and over: own account. 13 to 17: own account, inactive until a parent approves. Under 13: a child profile inside a parent's account, no login. | Decided | ACC-5 |
| R-AGE-2 | Age thresholds come from `country_config`. Singapore: 13 and 18. Malaysia and New Zealand: to confirm. | Decided / MY NZ Open | ACC-5, Q7 |
| R-AGE-3 | Under 18: Public visibility is never offered, adults cannot message them privately, no paid gifting, filming needs a parent's consent, the video feed shows following only, no autoplay, and it ends. | Decided | SAF-6 |
| R-AGE-6 | Minors are left out of public Discover and public leaderboards unless a guardian opts in. Nothing about a minor is shared publicly without a guardian's approval. A minor's username is not public. | Decided | Architecture 9.2, 19 |
| R-AGE-7 | Under-18 statistics are visible only to their Circle and guardians. Tournament leaders show a minor by first name and initial. No profile card for under-18s. Following an under-18 player needs the Circle rule. | Decided | PAS-24, PAS-26, TRN-12, TRN-20 |
| R-AGE-4 | The parent link ends at 18; both are told 30 days before. | Decided | SAF-7 |
| R-AGE-5 | Parent's monthly spending limit for a child: S$0, S$20 or S$50. | Assumed | SAF-7 |
| R-ACC-14 | Deleting an account is confirmed with Face ID, fingerprint or the device passcode. | Decided | ACC-11 |
| R-ACC-11 | Delete account: 30 days to undo, then data is erased. Match results stay as "Former player". Receipts are kept for the period the law requires (number of years to confirm). | Decided / years Open | ACC-11, Q14 |
| R-ACC-12 | Deleting a parent's account closes linked children's accounts too, unless another parent takes them over. | Assumed | PRD assumed rules |
| R-ACC-13 | Recovery when both email and mobile are lost: ID photo and selfie video, staff review within 3 working days, then a 7-day wait with warnings to the old email and mobile, then the new contacts replace the old and every session is signed out. | Decided / 7 days Assumed | ACC-10 |

## 6b. Events

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-EVT-1 | Up to 6 tickets in one purchase. Ticket holders see their ticket, the refund deadline and a QR code. | Decided | EVT-3 |

## 7. Meets

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-MET-1 | Game types and minimum players: Singles 2, Doubles 4, Social 5. The organizer sets min and max players. | Decided | MET-1 |
| R-MET-2 | Meets are visible to club members by default. Only the owner, an admin or the organizer (with the permission) can make one public. | Decided | MET-2 |
| R-MET-3 | Repeats: weekly or every 2 weeks, chosen days, a count. | Decided | MET-1 |
| R-MET-4 | Capacity and waitlist position are checked inside the join RPC with a row lock on the activity, never from a count read by the app. | Decided | Architecture 7.3 |
| R-MET-5 | A spot is reserved for 10 minutes while payment completes; an expired reservation frees the spot. | Assumed | Architecture 11.1 |
| R-MET-6 | Waitlist: no charge until a spot opens. The next person gets an offer valid 30 minutes. | Assumed | MET-4 |
| R-MET-7 | Inside 24 hours of the start, an open spot goes to the next person automatically and they are charged. | Open | Q5 |
| R-MET-8 | 24 hours before the start, if fewer than the minimum have joined, the organizer chooses to cancel (everyone refunded per R-REF-1) or play anyway. | Decided | MET-9 |
| R-MET-9 | A guest joins with a player. The host pays full price; the guest earns no points or Passport credit. | Assumed | MET-5 |

## 8. Attendance and check-in

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-ATT-1 | Attendance opens 30 minutes before the start and closes at 23:59 local time that day. | Decided | MET-8 |
| R-ATT-2 | A player is marked Present automatically when their phone reaches the venue during that window. Location is used once and not kept as history. | Decided | MET-8, NFR-6 |
| R-ATT-3 | If the venue is not detected, the organizer taps Check in. A venue QR scan plus location also works. Walk-ins can be added. | Decided | MET-8, PAS-2 |
| R-ATT-4 | A session counts on the Passport only after check-in. | Decided | PAS-2 |
| R-ATT-5 | Saving attendance releases the money (R-HOLD-2) and awards points (R-PTS-1). | Decided | MET-8 |

## 9. Scores, ratings and leaderboards

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-SCO-1 | Badminton game: won at 21 with a 2-point lead, or at 30 (whoever reaches 30 first wins). | Decided | Handoff |
| R-SCO-2 | A player enters a score; the other side confirms. Unconfirmed after 24 hours, or disputed, it goes to the organizer. An umpire's entry is final. | Decided | MET-10, TRN-4 |
| R-SCO-3 | A confirmed result is immutable. A correction adds a new result that supersedes it. The organizer may correct a tournament result within 24 hours, with a reason; later corrections go through staff. | Decided | Architecture 7.4, TRN-22 |
| R-RAT-1 | Ratings move only from confirmed results in ranked contexts. Every tournament match is ranked. | Decided | PAS-4, TRN-4 |
| R-RAT-2 | Rating engine: Glicko-2 (Elo is the alternative). | Assumed | PAS-4 |
| R-RAT-3 | Level bands: LB 1.0, MB 2.0, HB 3.0, LI 4.0, MI 5.0, HI 6.0, AD 7.0, PRO 8.0 and above. A player may choose up to AD for themselves; PRO needs verification. | Decided | PAS-3 |
| R-RAT-4 | The starting level is provisional until about 5 confirmed matches. | Decided | PAS-4 |
| R-RAT-5 | Repeated matches against the same opponent count less each time. Sudden drops, sudden jumps and closed groups are flagged. | Decided | PRD anti-gaming |
| R-RAT-6 | An academy level never changes a rating. | Decided | PRD Academy |
| R-LDR-1 | Local leaderboard: by area, monthly. A player needs at least 4 confirmed matches that month to appear. Listing is opt-in. | Decided / 4 Assumed | PAS-6 |
| R-LDR-2 | Tournament leaderboard: ranking points by placing and tier (Club, Regional, National), only from verified organizers with 16 or more entries. Resets each January. | Decided | PAS-7 |
| R-LDR-3 | Rank earns badges only, never points or money. The top 10 at the end of a season get a badge. | Decided | PAS-9 |
| R-LDR-4 | Leaderboards are built as snapshots by scheduled jobs, not live queries. | Decided | Architecture 12 |
| R-STA-1 | A statistic shows only when the match was scored at the level it needs (1 game scores, 2 point by point, 2+ tagged points, 3 camera). | Decided | Tournaments PRD |
| R-STA-2 | A percentage shows only after 5 matches at its level; before that the tile shows progress ("3 of 5 matches"). | Decided | Tournaments PRD |
| R-STA-3 | Walkover: counts for the draw, not for ratings, and only as "matches played" in statistics. Retirement: score so far kept; counts for ratings only if at least one game was completed. | Decided | Tournaments PRD |
| R-STA-4 | A season is a calendar year. | Decided | PAS-23 |

## 10. Clubs and teams

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-CLB-1 | Club name up to 50 characters. Home venue required (sets the area). Up to 3 sports, one primary. | Decided | GRP-3 |
| R-CLB-2 | Visibility: Public (in search, join at once or by request), Private (in search, outsiders see only the floating card, request to join), Hidden (not in search, invite link only). | Decided | GRP-2 |
| R-CLB-3 | Invite links last 7 days. | Decided | GRP-3 |
| R-CLB-4 | A declined join request can reapply after 30 days. | Decided | GRP-6 |
| R-CLB-5 | The Owner role cannot be changed or deleted. Every club keeps at least one owner. Only an owner grants money permissions. Roles are assigned to up to 30 members at a time. | Decided | GRP-7 |
| R-CLB-6 | The audit log keeps 90 days and is shown to holders of View audit log. | Decided | GRP-10 |
| R-CLB-7 | **Replaced by organizer rewards (owner, 1 Nov; Q156).** | Decided | Q156 |
| R-TEM-1 | A team has exactly one sport and picks players only from linked clubs of that sport. Under-18 invites need a parent's confirmation. | Decided | GRP-14 |
| R-TEM-2 | Lineups lock 24 hours before each fixture or tie. Only available players can be picked. | Decided | GRP-16, TRN-7 |

## 11. Academy

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-ACD-1 | Verification: business licence (UEN), an NROC licence for every coach, and a payout account; reviewed in 1 to 3 working days. Coaches get no classes until their licence is verified. An academy isn't listed until it's verified, and a coach joins only by accepting, with no access to children before their licence is verified. | Decided | ACD-3, ACD-10 |
| R-ACD-2 | A class change notifies every parent by app, then by SMS if unread after 2 hours. | Decided | ACD-6 |
| R-ACD-3 | Make-up credits: a parent who taps Can't make it gets one; a cancelled class gives everyone one. Credits last 30 days and book any class of the same level with space, at least 24 hours ahead. | Decided | ACD-7 |
| R-ACD-4 | Trial class: S$15.00 plus the S$2.00 fee, taken off the first month if the child enrols within 7 days. The price is set per class, and the academy applies the discount itself while months are paid directly (Q108, Q109). | Assumed | PRD assumed rules |
| R-ACD-5 | Academy fee example: S$180 a month plus the 10% fee, paid by the parent. Monthly and term fees are paid to the academy directly for now (owner, 1 Nov; Q107). | Assumed | PRD assumed rules |
| R-ACD-6 | Trials, single classes and one-to-ones are paid in the app and work like a Meet: 10% fee with a S$2.00 minimum on top, held until attendance is saved or 24 hours after the end, and paid to the academy's owner. | Decided | Owner, 1 Nov |
| R-ACD-7 | A student is the account holder, or a child linked by parent code. A minor never enrols or books themself. | Decided | Owner, 1 Nov |
| R-ACD-8 | Assessments are readable by the player, a minor's parent and the assigning coach, and writable only by that coach. | Decided | P4c-02 |
| R-ACD-9 | A referral records that it was made and the partner's reference code, and nothing about a condition. Booking happens on the partner's own site. | Decided | P4c-03 |

## 11b. Game

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-GAM-1 | A Meet counts when 6 or more players are Present, every participant paid the platform fee themselves, and every participant was scanned in by QR. Organizer-pays Meets don't count. | Decided | Checklist P4d-02, Q154 |
| R-GAM-2 | The organizer earns the rewards, from 18. They needn't pay or play. To count towards the 6 they take a spot for the S$2.00 fee, and they needn't scan themself. | Decided | Q154 |
| R-GAM-3 | Reward ladder, lifetime and never reset: game 2 and 4 give 1 Voucher A, 8 gives 2 A and 1 B, 12 gives 2 A, 16 gives 3 A and 1 B, then every 4th game gives 3 A and every 8th also 1 B. | Decided | Checklist, Q155 |
| R-GAM-4 | A voucher is tied to one account, redeemed only in the app, and expires (default 90 days). One discount per item: a voucher or points. | Decided | P4d-03 |
| R-GAM-5 | The shop funds Voucher A: commission is on the price after the voucher. Voucher B is held until court booking exists. | Decided | Decisions 6 and 7, Q153 |
| R-GAM-6 | Campaigns and quests never change a rating, and are for adults. | Decided | P4d-01, decision 10 |
| R-GAM-7 | A game is judged once attendance has closed for the day and its money has released. A session counts towards a quest once it's over, if the player kept their spot and was scanned or marked by the organizer. | Open | Q157 |
| R-GAM-8 | Games before payments open rank their group and earn nothing. | Open | Q158 |

## 12. Notifications and messages

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-NOT-1 | Each member turns channels on or off (app, email, WhatsApp, SMS, Telegram) and chooses channels per message kind. | Decided | NOT-1 |
| R-NOT-2 | SMS only for urgent kinds: a Meet changes, your match is called, a class changes. | Decided | NOT-1 |
| R-NOT-3 | Sign-in codes and receipts are always on. | Decided | NOT-1 |
| R-NOT-4 | Quiet hours 22:00 to 07:00 local; only Meet changes get through. | Decided | NOT-1 |
| R-NOT-5 | Olympus pays for every SMS and WhatsApp message; prefer push and email. | Decided | Architecture 15 |
| R-MSG-1 | Adults cannot open direct conversations with under-18s. Staff are members of every team and class conversation. | Decided | SAF-6, GRP-17 |
| R-MSG-2 | Organizers can delete a message for everyone. Every message can be reported. | Decided | GRP-11, CHT-2 |

## 13. Privacy, safety and moderation

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-PRV-1 | Who sees a player's sessions: Public, Circle (recommended default) or Private, with a per-session choice. Public shows the area, never the exact court or time. | Decided | PAS-10 |
| R-PRV-2 | Statistics visibility is set per sport, default Circle. An opponent always sees the result of a match they played in. Organizers always see rating and level for seeding. | Decided | PAS-24 |
| R-PRV-3 | People are not told when they are added to or removed from a Circle. | Assumed | PRD assumed rules |
| R-PRV-4 | A blocked player sees "not found", never "forbidden". Blocks are checked in every read path, both ways. | Decided | Architecture 8 |
| R-MOD-1 | Reports are answered within 24 hours. | Decided | ADM-1 |
| R-MOD-2 | New Zealand: the poster of reported content has 48 hours to reply to a complaint. | Decided | SAF-4 |
| R-MOD-3 | Staff decisions are kept 3 years with who decided, when, the rule and who was told. | Decided | Architecture 18 |
| R-MOD-4 | Bans need a second staff approver. Payout runs need one above a threshold (R-PAY-2). | Decided | ADM-5, Architecture 13.5, 18 |
| R-MOD-5 | A suspension takes effect at once (RLS checks moderation status), not when the session token expires. | Decided | Architecture 8 |

## 14. Time

| Id | Rule | Status | Source |
| --- | --- | --- | --- |
| R-TIM-1 | Store every time in UTC (`timestamptz`). Show it in the activity's or venue's time zone. | Decided | Architecture 7.10 |
| R-TIM-2 | Singapore and Malaysia are UTC+8 all year. New Zealand is UTC+12, or UTC+13 during daylight saving. Never hard-code an offset; use the zone name (`Asia/Singapore`, `Asia/Kuala_Lumpur`, `Pacific/Auckland`). | Decided | — |
| R-TIM-3 | "24 hours before" and "24 hours after" are exact durations from the stored UTC time. "23:59 that day" uses the venue's local date. | Decided | — |
