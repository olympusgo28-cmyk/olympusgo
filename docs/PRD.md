# OlympusGO PRD

Oct 9, 2026 · @Olympus

## Summary

OlympusGO is a sports community app where players, clubs, academies and creators meet, play, learn and shop. Each player's identity is a Passport, which holds their rating, sessions and badges. The design is a clickable prototype of about 300 screens and has been walked through in tests, but no working app exists yet. This PRD is what developers build from.

**The problem.** Amateur sport in Singapore runs on group chats, spreadsheets and bank transfers:

- Organizers chase payments and attendance by hand.
- Players have no shared record of what they have played or how good they are.
- Academies juggle schedules, make-up classes and parent messages across several tools.
- Creators and small brands have no sports-specific place to reach active players.

**The product.** One app built on four pillars, plus web tools:

| Pillar | What it covers |
| --- | --- |
| Play | Meets (one-day club games), tournaments, races and events, with check-in, scores and ratings |
| Learn | Academies with classes, coaches, parents and progress tracking; camera analysis in phase 2 |
| Shop | Shoppable videos, live selling, creator gear, points that give discounts |
| Services | Recovery, equipment and media services, plus venues and court booking |

There are also two web apps: the admin web app for the Olympus team, and an academy web space for academy owners.

**Markets.** Singapore first, then Malaysia and New Zealand. Badminton is the expected launch sport (not yet confirmed), followed by pickleball and other racquet sports, and running.

**Where it stands (9 Oct 2026).**

- **Design:** the canvas is at Version 134. About 100 of 135 workflows are designed, and 304 of 307 test steps pass.
- **Code:** nothing has been built.
- **Architecture:** 18 architecture change requests were approved on 24 Sep. They assume Flutter for the app and Supabase for the server.
- **Legal and payments:** nothing has been checked by a lawyer, and no payment company is signed up.

## Goals and success measures

Launch has to prove one loop: a player finds a Meet, joins and pays, checks in, plays, and the result lands on their Passport. Everything else builds on that loop. Targets marked \[to set\] have not been agreed yet.

| Goal | How we measure it | Target |
| --- | --- | --- |
| Players come back to play | Players with 2 or more checked-in sessions in a month | \[to set\] |
| Organizers run Meets here instead of in chat groups | Meets created per active club per month; share of paid spots that end with attendance marked | \[to set\] |
| Ratings are trusted | Share of match results confirmed by the other side or an umpire; disputes per 100 matches | \[to set\] |
| Money moves cleanly | Payment success rate; refunds resolved without support | \[to set\] |
| Points and shops create sales | Points redeemed; partner shop sales from points | \[to set\] |
| Athletes and creators stay involved | Hours an athlete spends per week | Under 1 hour (strategy doc) |

**The first test is a pilot.** It runs for 4 weeks with 5 to 10 athletes in badminton and pickleball and 3 to 5 small brands as discount partners, after written federation approval. It measures:

- how many people take part
- points redeemed
- brand sales
- athlete time

**Not in the first releases (Foundation and Core Sports Beta):** paid gifting, wearables, the trainer and brand-research marketplaces, and anything that needs the camera features. The architecture doc places these later, in the full public release.

## Users and roles

One account can hold several roles. A person reaches every role they hold from My schedule (Joined and Hosting tabs), never through a separate app.

| Role | Who | Main jobs | Where they work |
| --- | --- | --- | --- |
| Player | Anyone 13 or older with an account | Find and join Meets, tournaments and events; pay; check in; record scores; build a Passport | Phone app |
| Organizer | A club member with the Create Meets permission | Create and run Meets; mark attendance; get paid | Phone app |
| Club owner or admin | Whoever created the club, or holds an admin role | Members, roles, join requests, bans, club settings, club reward | Phone app |
| Team staff | Head coach, coach, manager or teacher on a team | Roster, lineups, fixtures, team chat | Phone app |
| Coach and academy owner | A verified academy and its NROC-licensed coaches | Classes, attendance, progress, parents, fees, coach pay | Phone app and academy web space |
| Parent or guardian | An adult linked to children under 18 | Approve a teen's account, manage a child's settings, pay fees, book make-ups | Phone app |
| Creator | A coach, athlete or influencer with a creator profile | Videos, challenges, gear, earnings | Phone app |
| Seller | A shop selling on Olympus | Products, orders, live selling, videos | Phone app; a merchant web space is planned |
| Venue owner | A court operator | Courts, prices, bookings | Not designed yet |
| Olympus staff | The trust and safety, payments and partnerships team | Reports, legal notices, refunds, payouts, checks, campaigns | Admin web app |

**Age rules.**

- **18 and over:** their own account.
- **13 to 17:** their own account, approved by a parent.
- **Under 13:** joins inside a parent's account.
- **Everyone under 18:** paid gifting is off, filming needs a parent's consent, adults cannot message them privately, and Public is not offered for their sessions.

## Release plan

The approved architecture splits delivery into stages, so real users test the core loop before the costly features arrive.

&#91;embedded content: release plan · 4 stages, 3 gates (ACR-001, ACR-018)\]

Each stage ships only after the gate before it passes. The phases inside each stage are fixed up to the camera work. After the beta, messaging, payments, tournaments and academy can reorder, as long as their dependencies are met. Paid Meets arrive with payments in the public launch; the beta runs on free play.

## Requirements: accounts, sign-in and onboarding

The requirement tables from here on share three columns. **ID** is for referring to a requirement. **Release** is the stage it first ships in, from the release plan above: Foundation, Beta, Launch or Later. **Screens** names the canvas boards that show it.

You sign up with email, and a mobile number is required as the second check. There is no password.

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| ACC-1 | Sign up with country, email, name and date of birth. A 6-digit code is emailed and works for 3 minutes (Q248; sign-up is now by mobile, Q247). | Foundation | SignUp, SignUpVerify |
| ACC-2 | Always answer “We sent you a code”, whether or not the email exists, so no one can test emails to find users. | Foundation | SignUpVerify, LogIn |
| ACC-3 | A mobile number is required during onboarding and confirmed by a text code, with WhatsApp as the backup channel. Resend is allowed after 3 minutes (Q248). After 5 wrong codes, the person waits 15 minutes. | Foundation | SignUpMobile |
| ACC-4 | If the mobile is already on another account, never dead-end. Offer “Sign in to that account”, or let a new owner claim a recycled number. Claiming removes it from the old account and tells that account by email. One account per verified mobile. | Foundation | SignUpMobile |
| ACC-5 | Age path from date of birth. 18 and over: own account. 13 to 17: a parent approves. Under 13: joins inside a parent's account. Thresholds can be set per country. | Foundation | SignUp, SignUpParent, SignUpUnder13, ParentApprove |
| ACC-6 | Onboarding: pick sports, set a starting level per sport (marked provisional), then allow notifications and location. | Foundation | OnboardSports, OnboardLevel, OnboardPermissions |
| ACC-7 | Log in with email, then a mobile code. On a phone used before, Face ID or fingerprint replaces the code. A username can be used instead of the email. | Foundation | LogIn |
| ACC-8 | Account Centre holds private details and opens only after Face ID, fingerprint or the device passcode. It stays unlocked for a few minutes. | Foundation | AccountCentre |
| ACC-9 | To change email or mobile, confirm with the other one and with Face ID. The old contact gets an alert. | Foundation | ChangeEmail, ChangeMobile |
| ACC-10 | Get back in when both email and mobile are lost: find the account, send an ID photo and selfie video, then give a new email and mobile. Review takes up to 3 working days. A 7-day wait follows, and the old contacts are warned during it. | Beta | AccountRecovery |
| ACC-11 | Delete account: shows what happens to the Wallet balance, bookings, linked children and points. Confirm with Face ID. 30 days to undo, then data is erased. Match results stay as “Former player”, and receipts are kept as the law requires. | Foundation | DeleteAccount |
| ACC-12 | Country setting sets currency, emergency number, minimum age and local rules (Singapore, Malaysia, New Zealand). | Foundation | CountrySettings |
| ACC-13 | Language, help, terms, log out. | Foundation | Language, HelpCentre, Legal, LogOut |

Apple requires delete account inside the app, so ACC-11 cannot slip.

## Requirements: profile, Passport, ratings, leaderboards and privacy

Each player has one main rating per sport, and it shows the same everywhere. Ratings move only from confirmed results.

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| PAS-1 | The Passport on Profile shows rating and level for the main sport, session count, club rank, badges, points and next sessions. | Foundation | Profile |
| PAS-2 | A session counts only after check-in: the organizer marks the player Present, or the venue QR code plus location confirms it. | Beta | MeetAttendance, Scan |
| PAS-3 | Levels are bands on the rating: LB 1.0, MB 2.0, HB 3.0, LI 4.0, MI 5.0, HI 6.0, AD 7.0, PRO 8.0 and above. Players can choose AD at most for themselves; PRO needs verification. | Foundation | OnboardLevel, ProfileSports |
| PAS-4 | The starting level is provisional until about 5 confirmed matches. Ratings use Glicko-2 or Elo. A result counts only once the other side or an umpire confirms it. | Launch | ScoreEntry, ScoreConfirm |
| PAS-5 | Sessions and rating history: past Meets, tournaments and classes, with each rating change. | Beta | PassportHistory |
| PAS-6 | Local leaderboard: skill rating by area (neighbourhood, region, country). Players need at least 4 confirmed matches that month to appear. It resets monthly; the rating does not. | Launch | Leaderboards |
| PAS-7 | Tournament leaderboard: ranking points from placings, weighted by tier (Club, Regional, National). Points count only from verified organizers with 16 or more entries. It resets each January; titles stay as badges. | Launch | Leaderboards |
| PAS-8 | Club leaderboard: this month, by sport, with an optional team cut-off set by club admins. Time-based sports rank by verified times. | Beta | FullLeaderboard |
| PAS-9 | Rank earns badges only, never points or money. The top 10 at the end of a season get a badge. | Launch | Leaderboards |
| PAS-10 | Who sees your sessions: a default of Public, Circle (recommended) or Private, a choice per session, and circles you make from players you have played with. Public shows the area, never the exact court or time. Public is not offered under 18. | Foundation | SessionPrivacy |
| PAS-11 | Another player's profile, follow, followers and following, block and report. | Foundation | PlayerProfile, FollowList, ReportUser, BlockedUsers |
| PAS-12 | Meet recap card: games, wins, rating change and best partner. The player chooses what to show, then shares it to Instagram or TikTok, saves it, or copies the link. | Beta | MeetRecap |
| PAS-13 | Testimonials and badges that players give each other after a Meet. | Later | Not designed |

**Anti-gaming rules.**

- Repeated matches against the same opponent earn less each time.
- Graded events cap entry by rating, and sudden rating drops are flagged.
- Groups of accounts that only play each other are flagged.
- New accounts earn no points until the mobile is verified and the player has about 5 confirmed matches.
- Flagged accounts lose points and badges, and repeat offenders are suspended.

## Requirements: clubs, roles and teams

Every Meet belongs to a club. Teams are separate, selected squads for competition. Both live under the Group tab: a search bar on top, then a Clubs / Teams switch.

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| GRP-1 | The Group tab has search with filters, a Clubs / Teams switch, and My, Recommended and New tabs. Recommended rows show why they fit, for example “Your level fits: MI 5.4”. | Beta | Main |
| GRP-2 | Club types. Public: found in search; join at once, or by request if the owner turns that on. Private: found in search, but outsiders see only the floating card and must request to join. Hidden: not in search, joined by invite link only. | Beta | ClubPublic, ClubPrivate, ClubPage |
| GRP-3 | Create a club in 4 steps: (1) photo, name up to 50 characters, description, home venue (required, sets the area), visibility and join rule; (2) up to 3 sports, one primary; (3) a level range per sport; (4) invite link valid 7 days, QR code and recent partners. | Beta | CreateClub, CreateClubSports, CreateClubLevels, CreateClubInvite |
| GRP-4 | Club page: floating card (info, members, join requests, invite), then Play, Leaderboard and Club chat. A Create button offers Meet, Tournament or Event, depending on the viewer's permissions. Filters by schedule, play style and gender. Up to 5 sports. | Beta | ClubPage |
| GRP-5 | Club info and overview: About, Rules (club rules plus default Meet, tournament and event rules), Sports (primary or secondary, level range each), and Ownership (owner only: transfer, delete). | Beta | ClubAbout, ClubOverview, ClubOverviewRules, ClubOverviewSports, ClubOverviewOwner |
| GRP-6 | Join requests show rating, level, sessions, mutual members and a message, with warnings such as “provisional” or “below the club's range”. Approve or decline with undo. A declined player can reapply after 30 days. | Beta | JoinRequests |
| GRP-7 | Custom roles in 3 steps: name and colour, permission level (Label, Member, Organizer or Admin), then up to 30 members at a time. The Owner role cannot be changed or deleted. Every club keeps at least one owner. Only the owner grants money permissions. | Beta | CreateRole, ManageRoles, RoleEdit, RolePermissions, RoleMembers, RoleDelete |
| GRP-8 | Permissions: create Meets, make Meets public, manage check-ins, run tournaments, create events, approve join requests, manage members, manage roles, edit club info, view audit log, manage fees and payouts. | Beta | RolePermissions |
| GRP-9 | Members: change a member's role, remove or ban them (bans listed separately). A removed or banned member's upcoming paid Meet is refunded in full. | Beta | ClubMembers, ClubMember, ClubBans |
| GRP-10 | Audit log of changes, grouped by day, kept 90 days, shown to holders of View audit log. | Beta | AuditLog |
| GRP-11 | Club chat with pinned messages, role colours and shareable Meet cards. Organizers can delete a message for everyone. Announcements by admins. | Beta | ClubChat, ClubChatOrganizer, ClubAnnouncements, ClubAnnounceNew |
| GRP-12 | Club reward: a Meet counts when 6 or more players paid and were marked Present. For example, 4 counted Meets unlock shuttles at S$40 instead of S$49. The owner or an admin redeems it. | Launch | ClubReward |
| GRP-13 | Leave a club; transfer ownership; delete a club. | Beta | ClubLeave, ClubTransfer, ClubDelete |
| GRP-14 | Create a team in 3 steps: details (with optional sub-teams by age group), exactly one sport, then players from linked clubs plus staff. Players accept an invite; for under-18 teams a parent confirms too. | Launch | CreateGroupType, CreateTeam, CreateTeamSport, CreateTeamMembers |
| GRP-15 | Team page: next fixture with the player's slot, lineup lock time and an availability reply; schedule; results. Roster tabs: Lineup, Squad (captain, vice-captain, source club, availability) and Staff. | Launch | TeamPage, TeamRoster, TeamFixture |
| GRP-16 | Staff edit lineups: only available players can be picked, the organizer's lineup rules are enforced, and lineups lock 24 hours before. Publishing notifies players. | Launch | EditLineup |
| GRP-17 | Under-18 teams: staff are in every team chat, adults cannot message players privately, and parents can see the roster and schedule. | Launch | TeamChat |
| GRP-18 | Team settings, add players, leave and delete a team. Players can see Leave team. | Launch | TeamSettings, TeamAddPlayers, TeamLeave, TeamDelete |
| GRP-19 | Sub-team pages. | Later | Not designed |

## Requirements: Meets, tournaments, races and events

A Meet is a one-day game hosted by a club. Tournaments and races are competitions. An event is anything people attend or watch, offline, online or both. All three use one shared activity card.

### Play tab and finding activities

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| PLY-1 | Play tab: search with filters, a next-session card that opens My schedule, and tabs for All, Meet, Tournament and Event. | Foundation | ActivityHub |
| PLY-2 | Filters: add a sport first, then for each sport a game type and a level range (from your Passport, all levels, or a custom range). Also schedule, play style (casual or ranked) and gender. | Foundation | PlayFilters, PlaySport, PlaySportDialog |
| PLY-3 | One activity card for Meets, tournaments and events: tag, ranked or tier, joined players with rating badges, open spots, price including the fee, date, venue and a line of activity. There is no Join button on the card. | Foundation | ActivityCards |
| PLY-4 | My schedule: Joined (including a child's class) and Hosting (opens the organizer or coach tools). This is how a person reaches every role they hold. | Beta | MySchedule, MyScheduleHosting |

### Meets

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| MET-1 | Create a Meet: sport, then title, date, time and venue, with repeats (weekly or every 2 weeks, chosen days, a count). Game type: Singles (minimum 2 players), Doubles (minimum 4) or Social (minimum 5). Minimum and maximum players, an optional level range, Ranked on or off, Paid or Free, invite-only, and Public (needs permission). The Publish button stays visible. | Beta | CreateMeetSport, CreateMeet, CreateMeetGame, CreateMeetFee, PickDateMeet, PickTimeMeet, PickVenueMeet |
| MET-2 | Meets are visible to club members by default. Only the owner, an admin or the organizer can make one public. | Beta | CreateMeetFee |
| MET-3 | Meet page: players with ratings, “8/12 playing · 4 spots left · min 4 to play”, date and repeat, venue and courts, level, price with the fee and the refund rule. Bottom bar: Join (pay with Face ID), then “You're going” with Chat and Can't go. | Beta | MeetPage |
| MET-4 | Join the waitlist when full. Waitlist spots are charged only if a spot opens. | Beta | MeetWaitlist, StateMeetFull |
| MET-5 | Bring a guest when joining. | Beta | MeetGuest |
| MET-6 | Give up a spot. Any time before the start, the player chooses a refund of everything to the Wallet (instant) or the price without the platform fee to the card. | Launch | MeetLeave |
| MET-7 | The organizer can organize only, or play too by paying only the S$2 platform fee. Giving up that spot refunds it, and she stays the organizer. | Launch | MeetOrganizer, MeetHostPay |
| MET-8 | Attendance: players are marked Present automatically when their phone reaches the venue. If the venue is not detected, the organizer taps Check in. Attendance opens 30 minutes before the start and closes at 11:59 PM that day. Walk-ins can be added. Saving attendance releases the money to the organizer. | Beta | MeetAttendance, MeetAttendanceCheckIn, MeetWalkIn |
| MET-9 | If fewer than the minimum have joined 24 hours before, the organizer chooses to cancel or play anyway. Cancelling refunds everyone in full, fee included; the card fees for those refunds come off the organizer's earnings. | Launch | MeetCancel |
| MET-10 | Enter a score; the other side confirms. An unconfirmed score goes to the organizer after 24 hours, and so does a disputed one. A confirmed ranked result updates ratings. | Launch | ScoreEntry, ScoreConfirm |
| MET-11 | Full player list, Meet chat, share and save. | Beta | MeetPlayers |
| MET-12 | Match generator: pick singles or doubles and a pairing method, and rounds are laid out across courts. | Not decided | Not designed |
| MET-13 | Manage a repeating series; rate a Meet afterwards (this feeds the club rating). | Later | Not designed |

### Tournaments and races

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| TRN-1 | Create a tournament in 4 steps (needs Run tournaments): (1) sport, which sets the format (racquet sports are Bracket, running is Race); (2) title, dates, daily start, venue and courts; (3) who enters, events, draw, scoring, seeding, level range and age divisions; (4) entry limits, registration close, fee, verified players only, check-in, waitlist, public, and link to an event. The tier is Club, Regional or National. | Launch | CreateTournamentSport, CreateTournament, CreateTournament3, CreateTournament4 |
| TRN-2 | Register solo or with a partner, pay, find a doubles partner, and see your group and first match. | Launch | TournamentPage, TournamentRegister, TournamentPay, PartnerSearch, TournamentPageIn |
| TRN-3 | Draw seeded by main rating: round-robin groups, then knockout. Matches are assigned to courts automatically, with a call to the court. | Launch | TournamentDraw, TournamentMyMatches |
| TRN-4 | Every tournament match is ranked. Scores are confirmed by both sides or an umpire until camera scoring arrives. Results feed ratings, Tournament points and Passport badges (Champion, Finalist). | Launch | ScoreUmpire, TournamentResults |
| TRN-5 | Withdraw before registration closes for a refund to the Wallet or card. An event below its minimum entries at close is cancelled and refunded. | Launch | TournamentWithdraw |
| TRN-6 | Organizer tools: entries, check-in, manage, message entrants, cancel. | Launch | TournamentManage, TournamentEntries, TournamentCheckIn, TournamentMessage, TournamentCancel |
| TRN-7 | Team entries with lineup rules, for example 3 singles plus 2 doubles with 2 reserves. Reserves cannot also play. Lineups lock 24 hours before each tie. | Launch | CreateTournament3, EditLineup |
| TRN-8 | Races: a race page, finish times and age-category ranking (such as M35–39, never the birth date). The create form already handles distances. | Later | CreateTournament |

### Events and cheering

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| EVT-1 | Create an event (needs Create events): sports, banner, name, description, date, and where it happens (offline, online or both). Tickets are Free or Paid, with a capacity. It can be linked to a tournament or race. | Launch | CreateEventSport, CreateEvent, PickDateEvent, PickVenueEvent |
| EVT-2 | A free ticket costs the guest nothing; the organizer pays the S$2 fee per ticket taken. A paid ticket is the price plus the fee. | Launch | EventTicketFree, EventTicketPaid |
| EVT-3 | Event page: details, schedule with Remind me, clubs taking part, and up to 6 tickets in one purchase. Ticket holders see their ticket, the refund deadline and a QR code. Paid tickets refund until 24 hours before. | Launch | EventPage, EventTicket |
| EVT-4 | A linked event shows “Part of” with draws, results and a live match card with a free cheer meter. | Launch | EventPageLive |
| EVT-5 | Release tickets you cannot use; manage and cancel an event. | Launch | EventTicketRelease, EventManage, EventCancel |
| EVT-6 | Paid gifts during live streams. Parked until there are live streams and legal sign-off on coins. | Later | Not designed |

## Requirements: payments, Wallet, fees, refunds, earnings and points

The player pays Olympus. Olympus holds the money until the organizer marks attendance, or until 24 hours after the end if attendance is not marked. Then it moves to the organizer's earnings. Every paid flow uses one payment sheet.

**Platform fee.** 10% of the price, with a S$2 minimum, added on top so the organizer keeps the full price.

| What | Price | Fee | Payer pays | Organizer receives |
| --- | --- | --- | --- | --- |
| Paid Meet | S$6 | S$2.00 | S$8.00 | S$6 |
| Free Meet, organizer pays (default) | S$0 | S$2.00 per player, charged to the organizer | S$0 | S$0 |
| Tournament entry | S$15 | S$2.00 | S$17.00 | S$15 |
| Team entry | S$60 | S$6.00 | S$66.00 | S$60 |
| Paid event ticket | S$30 | S$3.00 | S$33.00 | S$30 |
| Free event ticket | S$0 | S$2.00, paid by the organizer | S$0 | S$0 |

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| PAY-1 | One payment sheet for Meets, tournaments, tickets, academy fees, courts, services and shop checkout. It has three steps: review (lines, fee, total, pay with), confirm with Face ID or fingerprint, then receipt. The refund rule and “Olympus holds your payment” show before paying. Apple Pay and Google Pay use their own check, with no second prompt. | Launch | MeetPay, MeetConfirm, MeetPaid, TournamentPay, CheckoutPay, FeesPay |
| PAY-2 | Refunds when the organizer, venue or shop cancels: everything back, fee included, to the Wallet (instant) or the card (3 to 5 working days). The card fees for those refunds come off the organizer's earnings. | Launch | MeetCancel, EventCancel, TournamentCancel |
| PAY-3 | Refunds when the player cancels in time: all of it to the Wallet, or the price without the fee to the card. In time means: Meets, before the start; paid tickets, until 24 hours before; tournaments, until registration closes; courts and shop orders, by their own rules. | Launch | MeetLeave, TournamentWithdraw, VenueBookingCancel, OrderCancel |
| PAY-4 | A refund rules page, reachable from Wallet, Help and Terms. | Launch | RefundRules |
| PAY-5 | Wallet: balance and history, holding refunds and rewards. Spend it on Olympus or withdraw to a bank for free. There is no top-up at launch, pending legal advice on a payments licence. | Launch | Wallet, WalletWithdraw (WalletTopUp is parked) |
| PAY-6 | Payment methods: saved cards with a default, add or remove with Face ID, Apple Pay or Google Pay, PayNow. Card details are kept by the payment company; Olympus sees only the last 4 digits. | Launch | PaymentMethods |
| PAY-7 | Receipts by type, each with its lines, emailed or saved as a PDF. Kept for as long as the law requires, even after an account is deleted. | Launch | Receipts |
| PAY-8 | Failed payment shown inside each paid flow, not only as a separate state screen. | Launch | StatePaymentFailed (pattern only) |
| PAY-9 | Ringgit and New Zealand dollars, and local payment methods, before launching in Malaysia and New Zealand. | Launch in those countries | Not designed |
| PAY-10 | Earnings for organizers, clubs and academies: ready, held until attendance, and history; a per-Meet breakdown; payout to a bank or PayNow; a payout account. Coach pay and creator earnings use the same model. | Launch | Earnings, EarningsDetail, Payout, PayoutAccount, CoachPayout, CreatorEarnings |
| PAY-11 | Points: earned at twice the platform fee paid (a S$2 fee earns 4 points), only after the payer is marked Present. 1 point is S$1 off at partner shops. Points used on an item cannot exceed Olympus's commission on it. There is a weekly earning cap, expiry after 12 months, and no cash-out or transfer. | Launch | PointsWallet, CheckoutPay |

Coins for paid gifting are out of scope until live streams exist and a lawyer has signed off.

## Requirements: Academy app and academy web space

Academies run classes for children and adults. Coaches work in the app. The owner also has a web space for the timetable, fees and staff. A change saved on the web shows in the app.

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| ACD-1 | Find an academy by sport, age group, distance and fee. Its public page shows verification, coaches, levels and prices. | Launch | AcademyCategory, AcademyPublic |
| ACD-2 | Book a trial class; ask to enrol a child. The academy accepts or declines. | Launch | TrialClass, AcademyEnrol, EnrolRequests |
| ACD-3 | Create an academy in 5 steps: (1) details and age groups (under-18 groups turn on safeguarding); (2) one sport with levels from a template; (3) billing per term, month or class, plus make-up rules; (4) verification: business licence (ACRA, UEN), an NROC licence for every coach, and a payout account, reviewed in 1 to 3 working days for a Verified badge; (5) invite coaches. | Launch | CreateAcademy, CreateAcademyLevels, CreateAcademyPolicies, CreateAcademyVerify, CreateAcademyCoaches |
| ACD-4 | Coach's Today view, all classes, and the class session. During a session the coach marks attendance and each skill as Not yet, Practising or Got it, and sees the week's plan. | Launch | AcademyHome, AcademyClasses, ClassSession, ClassRoster |
| ACD-5 | One shared curriculum per level, week by week, with drills and timings. The head coach sees which classes are behind, and edits reach all coaches with a “what changed” note. A drill video library. | Launch | Curriculum, LessonPlanEdit, DrillVideos |
| ACD-6 | Change a class (new coach, time, court or cancellation): one notice goes to every parent by app, then SMS if unread after 2 hours. The head coach sees who confirmed. | Launch | ChangeClass, PickDateClass, PickTimeClass, PickCourtClass |
| ACD-7 | Make-ups: a parent who taps Can't make it gets a credit automatically, and a cancelled class gives everyone one. Credits last 30 days and book any class of the same level with space, at least 24 hours ahead. | Launch | ParentClass, BookMakeup |
| ACD-8 | After class, each parent gets one summary: attendance, the lesson, their child's skill update and the coach's note. Parents can reply. | Launch | ParentNote, AcademyMessages |
| ACD-9 | Parent home, child progress, attendance history, fees and invoices, and paying the fee with the payment sheet. | Launch | ParentHome, StudentProgressParent, AttendanceHistory, ParentFees, FeesPay |
| ACD-10 | Academy roles are customizable like club roles. Default templates: Head Coach, Coach, Assistant, Admin, Student and Parent/Guardian. Coaches cannot get classes until their NROC licence is verified. | Launch | AcademySettings |
| ACD-11 | Coach pay; invite students; close an academy. | Launch | CoachPayout, InviteStudents, AcademyDelete |
| ACD-12 | Academy web space: today, timetable, students and parents, enrolments and trials, fees and invoices, coaches and cover, locations, staff and access. A location saved once updates the app, and parents get a notice. | Launch | AcwHome, AcwTimetable, AcwStudents, AcwEnrol, AcwFees, AcwCoaches, AcwLocations, AcwStaff, AcademyMoveNotice |
| ACD-13 | Filming consent for under-18s: the parent sees what is recorded, why, who sees it and for how long, and makes two separate choices. Declining does not affect the child's place. Proposed: clips kept 90 days and deleted within 7 days of withdrawal. | Later (camera) | FilmingConsent |
| ACD-14 | The level-up moment; workshops, masterclasses and booking a coach one-to-one or in a group. | Later / not decided | Not designed |

Passing an academy level never changes a rating. Ratings come only from ranked games.

## Requirements: Shop, sellers, services, venues, creators and campaigns

The Shop works like TikTok Shop: creators post videos with products tagged in them, sellers go live, and points give discounts. Services are a tab inside the Shop.

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| SHP-1 | Shop home: shoppable videos, live selling, shops and services, with filters. | Launch | ShopHome |
| SHP-2 | Shoppable video and live shopping with a buy sheet. Every sponsored post carries a “Paid partnership” label. | Launch | ShopVideo, ShopLive |
| SHP-3 | Product page, shop page with seller details, cart, and checkout on the payment sheet with points. | Launch | ProductPage, MallPage, Cart, Checkout, CheckoutPay |
| SHP-4 | Addresses; my orders; order tracking; cancel an order; refund tracking; return an item; write a review. | Launch | ShopAddresses, ShopAddressNew, Orders, OrderDetail, OrderCancel, RefundStatus, ReturnRequest, WriteReview |
| SHP-5 | Seller tools: products, add or edit a product, orders, pack and ship, go live, post a video with the paid-partnership switch. | Launch | SellerHome, SellerProducts, SellerProductEdit, SellerOrders, SellerOrderDetail, SellerGoLive, SellerUploadVideo |
| SHP-6 | A merchant web space for sellers. | Launch | Not designed |
| SHP-7 | Services, booked by time slot: recovery (physio clinics, sports massage, rehab), equipment (stringing, repairs) and media (photo, video). “Clinic” is used only for recovery. | Launch | ServiceBook |
| SHP-8 | Voucher wallet, product questions, size guide. | Later | Not designed |
| VEN-1 | Find a venue: facilities, courts, and activities at the venue filtered by Meet, tournament or event. | Foundation | VenueCategory, VenuePage |
| VEN-2 | Book a court in the app with the payment sheet; my booking with its door code; cancel with a refund to the Wallet or card. | Launch | VenueBook, VenueBooking, VenueBookingCancel |
| VEN-3 | Venue owner's side: courts, prices, bookings. Needed if courts are booked in the app at launch. | Launch | Not designed |
| CRT-1 | Creator profile: videos, the gear they use, a running challenge, “Train with them” links, follow and message. | Launch | CreatorProfile |
| CRT-2 | A creator challenge with progress, rank and prize. | Launch | ChallengePage |
| CRT-3 | Creator earnings from affiliate sales and campaigns. | Launch | CreatorEarnings |
| GAM-1 | Game tab: campaigns list and campaign page. A campaign is a goal such as “Play 8 sessions in October”, tracked from Passport check-ins, rewarding badges, leaderboard spots or discount codes. Campaigns are created in the admin web app. | Launch | GameCategory, GameCampaign |
| GAM-2 | Workout challenges with camera rep counting, plus my workouts: exercise catalog, program builder, workout and rest timer, log and calculators. | Later (camera) / not decided | CvSetup, CvAttempt, CvResult, WorkoutCampaign, TrainerHome, ExerciseCatalog, ProgramBuilder, TrainMode, TrainRest, WorkoutLog, TrainerCalc |

The spec's original idea was that “Book court” links out to the venue's own site. The design now books in the app, which is why VEN-3 is needed.

## Requirements: chat, notifications, safety, under-18 protection and the admin web app

Olympus hosts content from users and holds children's data, so reporting, moderation and youth safeguards ship with the first release, not after it.

| ID | Requirement | Release | Screens |
| --- | --- | --- | --- |
| CHT-1 | Inbox combining chats and updates. Direct messages with send, plus attaching a Meet, photo or file. | Foundation | Inbox, DMThread |
| CHT-2 | Club and team chat; report a message. | Beta | ClubChat, TeamChat, ReportMessage |
| CHT-3 | Separate threads for a shop, support and parents (the prototype uses one sample thread for all of them). | Launch | DMThread |
| NOT-1 | Notification settings: turn each channel on or off (app, email, WhatsApp, SMS, Telegram), and tap any message type to choose its channels. SMS is only for urgent changes (a Meet changes, your match is called, a class changes). Sign-in codes and receipts are always on. Quiet hours run 10 PM to 7 AM; only Meet changes get through. | Beta | NotificationSettings |
| SAF-1 | Report a user, message, video or live stream, listing or review, club or event. Send stays blocked until a reason is picked, and urgent reasons are marked. | Foundation | ReportUser, ReportMessage, ReportVideo, ReportListing, ReportClub |
| SAF-2 | Block players. | Foundation | BlockedUsers |
| SAF-3 | My reports: progress, result, and asking for a second look. | Foundation | MyReports, ReportDetail |
| SAF-4 | Notice that your content was removed, with a review request. A complaint about your post with 48 hours to reply (New Zealand). | Foundation | ContentRemoved, ComplaintReply |
| SAF-5 | Community rules, and a legal notice form that needs no account. | Foundation | CommunityRules, LegalNotice |
| SAF-6 | Under-18 protection: no private messages from adults, no paid gifting, filming needs a parent's consent, Public is never offered, and the video feed shows following only, with no autoplay, and ends. | Foundation | Under18Safety, VideoFeedTeen |
| SAF-7 | Linked children: who sees a child's sessions, a monthly spending limit, filming, the protections that stay on, approving a teen, and adding a child. At 18 the link ends and both are told 30 days before. | Foundation | LinkedChildren, ParentApprove |
| ADM-1 | Admin web app: today; reports queue; one case with its decision; notices and orders; decision log. Reports are answered within 24 hours. | Foundation | AdminHome, AdminReports, AdminCase, AdminLegal, AdminLog |
| ADM-2 | Refunds and disputes; the payout run, including money held until attendance. | Launch | AdminRefunds, AdminPayouts |
| ADM-3 | Identity, business and coach checks. | Launch | AdminVerify |
| ADM-4 | Campaigns: list, create, and edit a live campaign. | Launch | AdminCampaigns, AdminCampaignNew (editing a live campaign not designed) |
| ADM-5 | Staff sign-in and roles; a second approver for bans and payouts; finding a player. | Foundation | Not designed |

ADM-5 is a Foundation item even though it is not drawn yet. Without staff sign-in, nobody can work the reports queue safely.

## Non-functional requirements

These come from the approved architecture change requests and the design tests. Developers confirm the technology in their first week.

| ID | Area | Requirement |
| --- | --- | --- |
| NFR-1 | Platforms | iOS and Android phone app from one codebase (Flutter assumed). The admin web app and academy web space are desktop web. |
| NFR-2 | Backend | Supabase assumed: Postgres with row-level security on every table, a security lint and database tests in CI, and sensitive actions run only on the server (ACR-004, ACR-005). Agents and developers use development projects only, with no production credentials. |
| NFR-3 | Data | Private identity is kept apart from the public profile. Age status and guardian links live at the identity level. Every field is classified by sensitivity, and the class sets where it may flow (ACR-002, ACR-003). |
| NFR-4 | Events | Domain events through a transactional outbox feed notifications, search and records, for example a confirmed result or a blocked user (ACR-006). |
| NFR-5 | Sign-in safety | Sign-in never reveals whether an email or username exists. Code attempts are rate-limited (ACR-014). Biometrics stay on the phone; the app gets only pass or fail. |
| NFR-6 | Location | Public views show the area, never the exact court or time. Location is used for check-in only with permission (ACR-015). |
| NFR-7 | Hosting and privacy | Hosted in the Singapore region, with the sub-processor list published before the first release. PDPA review, and a data protection officer appointed before the beta. |
| NFR-8 | Media | Photos in object storage and video on a streaming service, not in the database, to keep costs predictable. Cloudflare R2 and Stream were looked at. |
| NFR-9 | Payments | Card data never touches Olympus servers; only the last 4 digits are stored. The payments model (merchant of record or connected accounts) is decided with a lawyer before payment work starts. |
| NFR-10 | Accessibility | Tap targets at least 44 px, text at least 12 px, contrast 4.5:1, screen-reader labels on icon buttons, and reduced motion respected. |
| NFR-11 | States | Every screen handles loading, empty, offline, full and failed payment. Back returns to the previous screen. |
| NFR-12 | Look | One visual style on every screen, with light and dark colours defined (dark screens come later). |
| NFR-13 | Quality gates | Each release stage passes its gate: auth, row-level security and enumeration tests for Foundation; an external penetration test, a staffed moderation runbook, a breach-response plan and a PDPA review for the beta. |
| NFR-14 | Reviews | Changes are reviewed by type: security and architecture for database work; privacy for auth and youth; accessibility and UX for new screens (ACR-017). |

The design still misses NFR-10 to NFR-12 in places: 71 screens use the earlier look, there are 268 small tap targets and 144 low-contrast texts.

## Dependencies before launch

None of these has been started. Rows 3 to 6 need a lawyer in Singapore, and later in Malaysia and New Zealand.

| # | Dependency | Why Olympus needs it |
| --- | --- | --- |
| 1 | Developers, a technology decision, and a cost and time estimate | Nothing is built; the canvas is a picture of the app |
| 2 | A payment company for cards and PayNow, with refunds and payouts | Organizers, sellers, coaches and creators receive money, and the company checks who they are |
| 3 | A legal check on the Wallet and the money flow | Olympus holds customer money until attendance. MAS licenses payment services such as e-money issuance and domestic money transfer |
| 4 | A legal check on points | Retail loyalty programmes may fall outside payment-services rules; this needs confirming |
| 5 | Rules for children's data | PDPC treats anyone under 18 as a child and needs a parent's consent under 13. Academies hold children's data |
| 6 | Terms of use, refund policy, seller and organizer agreements, and the refund wording | The app takes money and hosts other people's activities and shops |
| 7 | App Store and Google Play rules | Real-world goods and services pay outside in-app purchase; digital content, such as a paid live stream, may need it. Delete account, reporting and blocking are required |
| 8 | Providers for email codes, text and WhatsApp codes, push messages, video and live streaming | Sign-up, shop videos and live selling depend on them |
| 9 | A team and runbook to review reported content within 24 hours | Videos, live streams and chats come from users |
| 10 | The badminton camera feasibility test | It decides whether camera scoring ships at all, and whether it is built or bought |
| 11 | Tests with about five real people per role, and a security test | No real person has used the prototype yet |
| 12 | A decision on OpenGym | Its GPL-3.0 licence could require Olympus to publish its own code; the design uses none of it |

## Open decisions and assumed rules

Where the design needed an answer to draw a screen, it assumed one. Each row below is either an open question or an assumption you need to confirm or change before developers build that part.

### Product decisions still open

| Decision | What the design assumes today |
| --- | --- |
| Launch sport | Badminton first |
| Can creators host events and academy sessions without a club? | Not decided |
| Shop: link out to brand stores, or check out in the app? | Checkout in the app |
| Business model beyond the platform fee (affiliate commission, creator subscriptions, gifting share) | Platform fee plus seller and creator commission |
| First camera version: a phone after the match, or court cameras? | Not decided; camera features are phase 2 |
| Paid gift split between player, organizer and platform | Parked with gifting |
| Team selection for timed sports: best time or average of recent runs | Best verified time |
| Join request alerts: one per request, or a daily summary | Not decided; approvers see a badge with the count |
| Match generator and workshops: needed for launch? | Not decided |

### Rules assumed while drawing, to confirm

| Area | Assumed rule |
| --- | --- |
| Meets | Waitlist offers a spot when one opens; a guest can join with a player; free practice sessions allowed |
| Venues and academy | A court booking fee applies; the trial class has a set price; the academy fee is S$180 a month plus the 10% fee, paid by the parent |
| Money | Seller and creator commission rates; payout timing; no buyer fee in the Shop; points capped per item |
| Events | The Finals Day ticket is S$10 plus the S$2 fee |
| Campaigns and challenges | Campaign rewards; number of challenge attempts |
| Under-18 | How a parent approves; a typed code can replace a link |
| Accounts (9 Oct) | 30 days to undo a deletion; linked children's accounts close with the parent's unless another parent takes over; receipts kept for \[number\] years |
| Recovery (9 Oct) | A 7-day wait after approval, with warnings sent to the old email and mobile |
| Codes (9 Oct) | WhatsApp as the backup for text codes; a 15-minute lockout after 5 wrong codes |
| Children (9 Oct) | Monthly spending limit choices of S$0, S$20 or S$50 |
| Notifications (9 Oct) | SMS only for urgent changes |
| Leaderboards (9 Oct) | At least 4 confirmed matches a month to appear on Local; the top 10 per season get a badge |
| Circles (9 Oct) | People are not told when they are added or removed |

### Architecture questions (17 in the architecture doc)

The main ones are below. The full list is in the architecture change requests doc.

- the minimum sign-up age and how guardians are verified
- where camera analysis runs, and the policy for bystanders on camera
- whether Discover needs a login
- the payments model
- the hosting region and sub-processors
- when to appoint a data protection officer
- the brand form, “OlympusGO” or “OLYMPUS GO”

The 9 Oct money flow, where Olympus holds payments until attendance, sits close to the payments-model question. Confirm it with a lawyer before payment work starts.

## Out of scope for launch

- **Camera and AI:** camera scoring, workout rep counting and AI coaching tips. These wait for the badminton feasibility test.
- **Gifting and coins:** paid gifting, coins and live-stream gifts.
- **Wallet top-up:** waits for legal advice.
- **Later releases:** wearables, the trainer marketplace and brand research.
- **International leaderboard:** dropped on purpose.
- **Smaller features:** dark mode screens, sub-team pages, voucher wallet, product questions, size guide, the academy level-up moment, testimonials, and rating a Meet afterwards.

## Sources

This PRD consolidates the following. Where they disagree, the canvas and the 9 Oct decisions win; the product spec of 1 Oct is out of date.

- [Club Screen Mockup](https://claude.ai/code/artifact/ab4ae238-8685-4eb5-9222-bdb6aa4dd670): the design canvas, Version 134
- [OlympusGO checklist](https://claude.ai/code/artifact/b63e72cf-eb5f-42be-8ef2-4e476898ee4c): what is done and not done
- [Olympus Sports Platform — UAT Report](https://claude.ai/code/artifact/970b18e2-eaaa-4955-bda6-194ac6df980e): test results and the go-live list
- [Sport Creator Platform — Product Spec](https://claude.ai/code/artifact/a47ab9c5-dd7d-47dd-9754-8ad81d8f791a)
- [OlympusGO v1.3 — Architecture Change Requests](https://claude.ai/code/artifact/0aede144-0923-443f-9fd4-0c1c7f28ac8d)
- [Olympus Sports Platform — Business Strategy](https://claude.ai/code/artifact/eb65f510-6eeb-4fce-b685-2112a6081ff4)
