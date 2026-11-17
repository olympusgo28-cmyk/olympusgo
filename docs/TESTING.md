# Testing

What to test, how, and the end-to-end journeys the design was already checked against. The architecture doc (section 22) lists the tools; this file lists the cases.

## Layers

| Layer | What must be proven | Tool | When |
| --- | --- | --- | --- |
| Database | RLS for owner, member, outsider, blocked user, minor, suspended user, anonymous; grants; allowed state transitions; append-only tables | pgTAP | Every migration |
| Races | 50 parallel joins on the last spot give one `joined`; a webhook delivered twice changes money once; a repeated idempotency key returns the first result | pgTAP plus a parallel script | Joining, payments, refunds |
| Money | Every row of the fee and refund example tables in `RULES.md`; every transaction balances; release timing; card fees on organizer cancellation; points | Unit tests in SQL, Dart and TypeScript, plus Stripe test mode | Phase 9 |
| Events | Duplicate delivery processed once; corrections processed in version order; dead-letter replay | Worker tests | Every consumer |
| Sign-in | Same response and similar timing for unknown accounts; send limits per target; lockout after 5 wrong codes | Edge Function tests | Phase 1 |
| Screens | Each screen renders loading, empty, offline and error; 44 px targets; semantics labels; golden images in light and dark | Flutter widget and golden tests | Every screen |
| Journeys | The 47 journeys below, run against a local Supabase with seed data | Flutter integration tests | Before each release |
| Devices | Small and old phones, slow network, iOS and Android, 200% text | Device lab or cloud devices | Before each release |
| Load | A popular Meet opening (burst joins); a live stream with many viewers | k6 or similar | Before Beta and Launch |
| Security | Outside penetration test | Provider | Before the Beta gate |

## Money test cases

Write one test per row of the **Fee examples** and **Refund examples** tables in `RULES.md`. Add these edge cases:

- A fee of 10% that is not a whole cent rounds half up (R-MON-4).
- A player who leaves after the start gets nothing; the spot is still released to the organizer when attendance is saved.
- An organizer who cancels after some players paid by Wallet and some by card: card fees are charged only for the card payments.
- Attendance never saved: money is released 24 hours after the end, not before.
- A report filed before release keeps the money held (R-HOLD-4).
- A Wallet that does not cover the total cannot be chosen (R-WAL-4).
- Points: awarded only for payers marked Present; none for new accounts below the threshold (R-PTS-6); expired points cannot be spent.

## Seed data

Use only the fake people in `SCREENS.md` ("People in the prototype"). Never seed a real person, email or phone number. Phone numbers use a reserved test range; emails use `@example.com`.

## End-to-end journeys

These 47 journeys (307 steps) were walked through on the design prototype on 9 Oct 2026; 304 steps passed. The 3 that failed (A02, A04, C02) failed only because prototype screens do not share data; in the real app they must pass. Rebuild each journey as a Flutter integration test with the same name and id.

### P01 · Player · Find a Meet with a sport filter, join and pay

Covers: PLY-1, PLY-2, MET-3, PAY-1, PLY-4

1. Open Home
2. Tap the Play category
3. Switch to the Meet tab
4. Tap Add sport, the sport list opens
5. Pick Pickleball, the options dialog opens
6. Choose Doubles and Custom range
7. Confirm Add sport, pill shows on Play
8. Open the first Meet card
9. Tap Join, the payment sheet opens with the fee line and methods
10. Choose PayNow and tap Pay, the confirm step shows
11. Confirm, the receipt shows amount and method
12. Go to My schedule and find the Meet

### P02 · Player · Give up a spot

Covers: MET-6, PAY-3

1. Open the Meet as a joined player
2. Tap Can't go, the sheet shows the refund to Wallet
3. Give up the spot, the refund is confirmed

### P03 · Player · Enter a score and get it confirmed

Covers: MET-10, PAS-6

1. From the Meet, tap Enter a score
2. Type game 2 as 17 to 21
3. Type game 3 as 21 to 19, winner is worked out
4. Send for confirmation
5. Back to the Meet
6. Open Inbox and find the score to confirm
7. Open it and confirm
8. See the leaderboard

### P04 · Player · Search from Home

Covers: PLY-1

1. Tap the Home search bar
2. Type smash, grouped results appear
3. Filter to the Shop tab
4. Type nonsense, the empty state explains what to do
5. Clear and open a club from results

### P05 · Player · Scan to check in

Covers: PAS-2

1. Open Scan from the bottom bar
2. Scan a Meet code (demo tap)
3. Open the Meet from the result
4. Show my own code

### P06 · Player · Register for a tournament with a partner

Covers: TRN-2

1. Play, Tournament tab, open Tampines Open
2. Tap Register
3. Continue is locked until a partner is chosen
4. Pick a suggested partner
5. Continue to pay, the same payment sheet opens
6. Pay and confirm, the receipt shows
7. Done returns to the registered state
8. Search for another partner instead

### P07 · Player · Get an event ticket

Covers: EVT-2, EVT-3

1. Open the event
2. Tap Get ticket, the sheet says there is nothing to pay
3. Add a third person and get the tickets, no payment step
4. Show the ticket code
5. A paid event uses the same payment sheet

### P08 · Player · Shop: video to cart to checkout to review

Covers: SHP-2, SHP-3, SHP-4

1. Home, Shop category
2. Open a shoppable video
3. Like, then go to the next video
4. Tap Buy, options sheet opens
5. Set quantity 2 and add to cart
6. View cart
7. Untick an item, total updates
8. Tick it again and check out
9. Choose Express, total updates
10. Continue to pay, the same sheet opens with points on
11. Turn points off, total updates; Wallet is locked because the balance is too low
12. Pay and confirm, the order is placed
13. Track the order
14. My orders: confirm received, then review
15. Rate 4 stars and post
16. Return an item

### P09 · Player · Shop: live selling and product page

Covers: SHP-2, SHP-3

1. Open the live from Shop
2. Ask a question
3. Open all products, view one
4. Change options on the product page
5. Buy now goes to checkout
6. Open the shop page and claim a voucher
7. Search inside the shop

### P10 · Player · Join a private club

Covers: GRP-2

1. Group, Recommended, open a private club
2. Request to join
3. Search the Group list in place

### P11 · Player · Profile and settings

Covers: PAS-1, ACC-13

1. Open Profile from the bottom bar
2. Edit profile and save
3. Open sessions and rating history
4. Change my Badminton level
5. Turn a notification off
6. Open my orders from Profile
7. Saved list from Home

### P12 · Player · Schedule shows what I joined and what I host

Covers: PLY-4

1. Open My schedule from Home, Joined tab is shown
2. Switch to Hosting
3. An organizer sees what she runs; Hosting opens the Meet organizer view
4. Hosting reaches tournament, event and class tools
5. One person, one name: the player is never listed twice
6. Create from the Hosting tab

### P13 · Player · Camera scoring: switch to manual when tracking fails

Covers: MET-10 (camera, phase 2)

1. Camera mode shows live scores and no number pad
2. The switch at the top goes to Manual and back
3. When tracking is lost, a warning explains what was kept
4. Switch to manual keeps the camera scores
5. Type the final score of game 2 and send

### P14 · Player · Small fixes: Follow, search tab, sport bar

Covers: PAS-11, PLY-1

1. Follow on Home toggles to Following and back
2. Follow on Discover toggles
3. A new search goes back to the All tab
4. With two sports added, Add sport stays on screen

### A01 · Club admin · Create a club

Covers: GRP-3

1. Group, Create, choose Club
2. Next is blocked until the club has a name
3. Type a name and pick a home venue, Next becomes available
4. Step 2: pick sports
5. Step 3: levels, then Step 4: invite
6. Create the club and land on its page

### A02 · Club admin · Manage a member: role, ban, unban

Covers: GRP-9

1. Club page, members
2. Open a member
3. Give the Court Captain role
4. Ban needs a reason first
5. Ban, land on the Bans list
6. Unban someone and undo
7. The member I just banned appears in the list

### A03 · Club admin · Join requests, roles, settings

Covers: GRP-6, GRP-7, GRP-12

1. Approve and decline join requests
2. Club settings to club reward
3. Overview tabs and save
4. Create a role
5. Leave club needs the tick box
6. Delete club and transfer ownership

### A04 · Organizer · Create a Meet

Covers: MET-1

1. Club page, Create, Meet
2. Pick the sport, Next
3. Open the date picker, pick a day, Done
4. The chosen date shows on the form

### A05 · Organizer · Publish a Meet, then run it

Covers: MET-1, MET-8

1. The form is in three short parts with the button always on screen
2. Next to Game, then to Fee
3. Back works, and tapping a part jumps to it
4. Publish from the last part
5. The new Meet opens in organizer view

### A06 · Organizer · Run a Meet as organizer

Covers: MET-8, MET-9

1. Open the Meet as organizer
2. Mark attendance
3. Save attendance
4. Add a walk-in
5. Cancel the Meet

### A08 · Organizer · Organize only, or play too by paying the platform fee

Covers: MET-7

1. Organizer view shows she is playing and holds a spot
2. Give up the spot: S$2.00 refund, still the organizer
3. Now organizing only, and not counted as a player
4. Play too opens the payment sheet with the platform fee only
5. Pay S$2.00, she counts as a player again
6. Create Meet explains the rule on the Fee part

### A09 · Organizer · Organizer attendance: automatic on arrival, Check in as fallback

Covers: MET-8

1. Attendance shows the organizer Present automatically
2. All present does not change her own row
3. When the venue is not detected, her row offers Check in
4. Tap Check in, she is marked Present

### A07 · Organizer · Tournament tools

Covers: TRN-1, TRN-6, EVT-1

1. Tournament page, manage
2. Entries by event
3. Check players in
4. Message entrants
5. Enter an umpire score
6. Cancel needs the tick box
7. Create a tournament: sport, details
8. Create an event

### T01 · Team · Team page, lineup, add players

Covers: GRP-15, GRP-16

1. Group, Teams, open my team
2. Say I am available
3. Roster tabs
4. Edit the lineup from team settings
5. Team settings, add players
6. Create a team
7. A player can leave the team from the team page

### C01 · Coach · Run a class

Covers: ACD-4

1. Academy category, open an academy
2. Open the coach home
3. All classes, open today’s class
4. Mark a student absent and update a skill
5. Send the summary to parents
6. Roster to a student, add a note

### C02 · Coach · Plan, enrol and change a class

Covers: ACD-5, ACD-6

1. Curriculum, edit this week’s plan
2. Add time to a drill, total updates
3. Add drills from the library
4. The added drill shows in the plan

### C03 · Coach · Enrolment, messages, change a class

Covers: ACD-2, ACD-6, ACD-8

1. Accept and decline enrolment requests
2. Messages to a parent thread
3. Change a class: new time, pick a slot, send
4. Invite students
5. Create an academy: 5 steps

### R01 · Parent · Enrol a child

Covers: ACD-2

1. Open an academy and ask to enrol
2. A confirmation tells me the request was sent

### R02 · Parent · Day-to-day as a parent

Covers: ACD-7, ACD-9

1. Open Parent home from Inbox
2. Answer the class change
3. Book a make-up class
4. Class details
5. Pay the monthly fee with the same payment sheet
6. Give filming consent
7. Find a way back to the main app from Parent home

### N01 · New user · Sign up and onboarding

Covers: ACC-1, ACC-3, ACC-6, ACC-7, ACC-9

1. Welcome, create an account
2. Email first, then verify it with the emailed code
3. Mobile is the second check
4. Pick sports, then level
5. Switches, then start
6. Log in path
7. Change email needs a code from the mobile; change mobile needs one from the email

### N02 · Player · Wallet, guest, waitlist

Covers: PAY-5, MET-4, MET-5

1. Profile to Wallet, withdraw to the bank
2. Bring a guest and pay with the shared sheet
3. Join the waitlist

### N03 · Player · Ticket release and tournament

Covers: EVT-5, TRN-2, TRN-5, PAY-10, CRT-2

1. Release one ticket
2. My matches from schedule, then results
3. Withdraw with a reason

### N04 · Player · Other players and safety

Covers: PAS-11, SAF-1, SAF-2

1. Open a player from the Meet list
2. Followers list
3. Report and block
4. Account: help, language, log out

### N05 · Organizer · Earnings and payout

Covers: PAY-10

1. Hosting to earnings
2. One Meet’s breakdown
3. Pay out by PayNow

### N06 · Seller · Run a shop

Covers: SHP-4, SHP-5

1. Profile to My shop
2. Add a product
3. Ship an order
4. Go live and post a video
5. Buyer: cancel an order and track the refund

### N07 · Player · Venue: find, book, cancel

Covers: VEN-1, VEN-2

1. Home to Venue
2. Search and filter
3. Open a venue and book
4. See the booking, then cancel

### N08 · Mixed · Group, Academy and Creator additions

Covers: GRP-11, GRP-15, CRT-1

1. Club announcements and a new post
2. Public club page, join
3. Team fixture
4. Trial class with payment
5. Attendance history and coach pay
6. Creator, challenge, earnings

### N09 · Player · Screens that had no way in

Covers: Navigation

1. Home Wallet tile opens Wallet
2. Live shopping leads to the creator and the challenge
3. Discover leads to a creator
4. A recommended club opens its public page
5. Team fixture from the team page
6. Checkout address opens the address book
7. Cancel an order from My orders
8. A join request opens the player

### N10 · Player · Game campaigns and Shop services

Covers: GAM-1, SHP-7

1. Home has no Services tile; Game opens campaigns
2. Tabs: Upcoming and Ended
3. Open a campaign and join
4. A creator challenge is listed in Game too
5. Shop has a Services tab
6. Book a service and pay with the shared sheet

### N11 · Player · Trainer: exercises, program, workout, log

Covers: GAM-2

1. Services no longer holds workouts; every service is a slot booking
2. Game lists a workout challenge; join it and start
3. Start an attempt: camera setup, then reps counted by camera
4. A rep with wrong form is not counted
5. Camera loses tracking: clock pauses, reps kept, resume or send for review
6. Finish: time, rank and what was not counted
7. Practice is separate from the challenge
8. Exercise catalog: filter and search
9. Open an exercise, add to a program
10. Start the workout: set done starts the rest timer
11. Finish the exercise and open the log
12. Calculators switch

### N12 · Mixed · Controls that used to do nothing

Covers: Controls

1. Share on a Meet says what the phone will do
2. Share on an event, a tournament, a club and a leaderboard
3. Recap: Instagram, TikTok and Save image respond
4. Club page: Announcements is a row, Chat can be opened
5. Club chat: plus opens choices, a Meet can be shared, settings open
6. Direct message: type and send, then share a Meet
7. Inbox: Mark all read clears the badges
8. Roles: reorder, and the Owner row is not a link
9. Role colour can be changed
10. New academy: add a venue, add a level, pick photos
11. Club invite: QR code, Messages, and the search filters the list
12. New team: sub-teams, own sub-team, staff and player search
13. Club overview: change cover, edit a rule, add a rule set, more sports

### N13 · Mixed · Search boxes, filter chips and the calendar

Covers: Search and filters

1. Members and role members can be searched
2. Partner search: chips change the list, search narrows it
3. Add players: linked club or invite link
4. Academy messages: unread and class chips, search
5. Walk-in, venue and help searches
6. Sport list search on Play
7. Calendar: next month, pick a day, back again
8. Tournament dates across a range in another month
9. Team overview switches, logo and my sports
10. Scan torch, call a parent, copy a coach invite

### N14 · Mixed · Safety, age and country

Covers: SAF-1 to SAF-7, ACC-5, ACC-12, CHT-2

1. Chat: the flag on a message opens the report form
2. Send is blocked until a reason is picked, then the report is sent
3. My reports shows the status and the progress
4. Inbox: removal notice, and a review can be asked for
5. Inbox: complaint with 48 hours to reply
6. Rules page leads to the legal notice, which needs the true box
7. Organizer deletes a message and can undo
8. Sign up: an adult birth date goes to email check
9. Sign up: age 14 is sent to parent approval
10. Parent approves after ticking the box
11. Sign up: age 10 is sent to join with a parent
12. Country: New Zealand shows 111 and NZ$
13. Under-18 protection: a parent switch moves
14. Video and live carry the label and a report button
15. Creator can switch the label on when posting
16. Shop page shows seller details, product page has report links

### N15 · Mixed · Fixes of 8 Oct, 1 PM

Covers: SAF-6, SAF-7

1. Sign up in New Zealand shows the age check
2. Country screen leads to the age check
3. Under-18: the video row opens the teen feed, which ends
4. Report links on the member club, event and tournament pages
5. Account Centre shows Chloe as waiting
6. Club chat: Aaron\'s message is on his side, with no report flag

### N16 · Admin · Admin web app: moderation, money, checks, campaigns

Covers: ADM-1 to ADM-4

1. Today: the country filter changes the numbers
2. Reports: urgent filter and search
3. Open a case and decide: remove, pause chat, save
4. Notices: pick the Netsafe one and hide it in New Zealand
5. Log: search and export
6. Refunds: decide the shoe dispute
7. Payouts: filter Malaysia, approve the run after the tick
8. Checks: approve the club in New Zealand
9. Campaigns: new campaign needs a name; preview follows it

### N17 · Academy owner · Academy web space and the app it updates

Covers: ACD-12

1. Today links to the timetable; picking a class shows its details
2. Students: filter a class and search a parent
3. Enrolments: accept, then undo
4. Fees: remind an overdue family, send November invoices
5. Coaches: Farah cannot cover juniors yet, Daniel can
6. Locations: the preview follows the address; saving tells the families
7. The parent finds the move in the Inbox
8. Staff: switch off front desk fees access

### N18 · Player and organizer · Payments, wallet and refunds

Covers: PAY-1 to PAY-5, PAY-10, ADM-2

1. The pay sheet shows the refund rule before paying
2. Give up a spot: Wallet gets S$8.00, card gets S$6.00
3. Tournament: withdraw to a card keeps the fee
4. Court: cancel to the Wallet gets all of it
5. Wallet has no top-up; it links to the refund rules
6. Help and Terms open the refund rules
7. Organizer cancels: card fees come off earnings
8. Earnings: held until attendance, released when marked
9. Admin: money held by Olympus, and the Siti refund case
