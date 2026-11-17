# Screens

Where every screen is drawn, and which requirements it serves. Build screens from these boards: copy the wording, the order of elements and the behaviour. Take colours and fonts from `DESIGN_SYSTEM.md`, not from older boards.

## The two canvases

| Canvas | Boards | Use it for | Link |
| --- | --- | --- | --- |
| Club Screen Mockup | 324 | Every flow and its behaviour: phone app, admin web app, academy web space. Older boards use the earlier style | https://claude.ai/artifact/N9p6MU1A4ycPqANUidw8q5 |
| OlympusGO Screens | 196 | The final look, in the OlympusGO Design System, for the main phone flows | https://claude.ai/artifact/5c2yNDrEDnF974X3uCNUvG |

Both canvases are private to the owner. Ask the owner to share them with each developer. Each board is a clickable prototype: tapping a link opens the next board, and sheets and choices work. A board file name (for example `MeetPage`) is the name the PRD uses in its Screens column.

**Reading a board as code.** Each board is an HTML file (`<Name>.dc.html`) with the markup inside `<x-dc>` and its behaviour in a small script at the end (`renderVals()`). Placeholders such as `[Venue]`, `[last 4]` and `[Bank name]` are deliberate: never ship them. People, prices and dates on boards are fake examples (see "People in the prototype" below).

**Boards that are copies.** Screens in a prototype do not share data, so some boards are the same screen in another state, for example `MeetPay` (sheet open), `MeetPaid` (receipt) and `MeetLeave` (give-up sheet) are all the Meet page. Build one screen with states, not one per board.

**What the prototype cannot show.** Back goes to a fixed board; in the app it returns to the previous screen. A choice on one board is not carried to the next. Share, photos and maps show a short notice instead of the phone's own sheet.

## Club Screen Mockup, board by board

Requirement ids come from the Screens column of the PRDs. A board with no id is still in scope; it supports a flow named in the row title.

### Colour theme

`ThemeTokens`: the earlier colour theme. Superseded by `DESIGN_SYSTEM.md`.

### Main screens

**Bottom bar tabs**

| Board | Title | Requirements |
| --- | --- | --- |
| `HomeV2` | Home | TRN-13 |
| `Discover` | Discover |  |
| `Scan` | Scan (scan / my code) | PAS-2 |
| `Inbox` | Inbox | CHT-1 |
| `Profile` | Profile and Passport | PAS-1, PAS-14, PAS-26 |
| `Leaderboards` | Leaderboards · Local and Tournament | PAS-6, PAS-7, PAS-9 |
| `SessionPrivacy` | Who sees your sessions · Circles | PAS-10, PAS-24 |

**From the main tabs: search, scan results, saved, categories, profile, messages**

| Board | Title | Requirements |
| --- | --- | --- |
| `SavedList` | Saved |  |
| `EditCategories` | Home · edit categories |  |
| `ProfileSports` | Profile · sports and levels | PAS-3 |
| `AccountCentre` | Account Centre | ACC-8 |
| `DMThread` | Direct message | CHT-1, CHT-3 |
| `Search` | Search · before typing |  |
| `SearchTyped` | Search · results |  |
| `SearchDiscover` | Search from Discover |  |
| `ScanCheckedIn` | Scan result · checked in |  |
| `ScanPlayer` | Scan result · player |  |
| `ScanTicket` | Scan result · ticket (organizer) |  |
| `ProfileEdit` | Edit profile | PAS-15 |
| `PassportHistory` | Sessions and rating history | PAS-5, PAS-20 |
| `NotificationSettings` | Notification settings | NOT-1, TRN-12 |

**Start: welcome, sign up by age (adult, 13 to 17, under 13), onboarding, log in**

| Board | Title | Requirements |
| --- | --- | --- |
| `Welcome` | Welcome |  |
| `SignUp` | Sign up · 1 country, email, date of birth | ACC-1, ACC-5 |
| `SignUpParent` | Sign up · age 13 to 17, ask a parent | ACC-5 |
| `SignUpUnder13` | Sign up · under 13, join with a parent | ACC-5 |
| `ParentApprove` | Parent approves an under-18 account | ACC-5, SAF-7 |
| `AgeCheck` | Age check (kept for countries that require it) |  |
| `OnboardSports` | Onboarding · sports | ACC-6 |
| `OnboardLevel` | Onboarding · Passport level | ACC-6, PAS-3 |
| `OnboardPermissions` | Onboarding · notifications and location | ACC-6 |
| `LogIn` | Log in · email, then mobile code | ACC-2, ACC-7 |
| `SignUpVerify` | Sign up · 2 verify email | ACC-1, ACC-2 |
| `SignUpMobile` | Sign up · 3 mobile as second check | ACC-3, ACC-4 |

**People and safety: other players, follow, report, block, help, settings**

| Board | Title | Requirements |
| --- | --- | --- |
| `PlayerProfile` | Another player’s profile | PAS-11, PAS-14 |
| `FollowList` | Followers and following | PAS-11 |
| `ReportUser` | Report or block | PAS-11, SAF-1 |
| `BlockedUsers` | Blocked players | PAS-11, SAF-2 |
| `HelpCentre` | Help | ACC-13 |
| `Legal` | Terms and privacy | ACC-13 |
| `Language` | Language | ACC-13 |
| `LogOut` | Log out | ACC-13 |
| `ChangeEmail` | Change email (confirm with mobile) | ACC-9 |
| `ChangeMobile` | Change mobile (confirm with email) | ACC-9 |
| `PaymentMethods` | Payment methods | PAY-6 |
| `Receipts` | Receipts | PAY-7 |
| `LinkedChildren` | Linked children | SAF-7 |
| `DeleteAccount` | Delete account | ACC-11 |
| `AccountRecovery` | Get back in · email and mobile both lost | ACC-10 |

**Safety and law: report content, what happens next, rules, legal notice, under-18, country**

| Board | Title | Requirements |
| --- | --- | --- |
| `ReportMessage` | Report a message | CHT-2, SAF-1 |
| `ReportVideo` | Report a video or live | SAF-1 |
| `ReportListing` | Report a listing, shop or review | SAF-1 |
| `ReportClub` | Report a club or event | SAF-1 |
| `MyReports` | My reports | PAS-25, SAF-3 |
| `ReportDetail` | Report · progress, result, second look | SAF-3 |
| `ContentRemoved` | Notice · your content was removed, ask for a review | SAF-4 |
| `ComplaintReply` | Notice · complaint, 48 hours to reply (New Zealand) | SAF-4 |
| `CommunityRules` | Community rules | SAF-5 |
| `LegalNotice` | Legal notice (no account needed) | SAF-5 |
| `Under18Safety` | Under-18 protection | SAF-6 |
| `CountrySettings` | Country · currency, emergency number, local rules | ACC-12 |
| `ClubChatOrganizer` | Club chat · organizer deletes a message | GRP-11 |
| `VideoFeedTeen` | Videos · under-18 view, following only | SAF-6 |

**Wallet: refunds land here, withdraw to a bank, refund rules. Top-up waits for legal advice**

| Board | Title | Requirements |
| --- | --- | --- |
| `Wallet` | Wallet | PAY-5 |
| `WalletWithdraw` | Wallet · withdraw to my bank | PAY-5 |
| `RefundRules` | Refund rules (Wallet, Help, Terms) | PAY-4 |
| `WalletTopUp` | Wallet · top up (later, not at launch) |  |

**States to reuse: failed payment, full, empty, offline, loading**

| Board | Title | Requirements |
| --- | --- | --- |
| `StatePaymentFailed` | State · payment failed | PAY-8 |
| `StateMeetFull` | State · Meet filled up | MET-4 |
| `StateEmpty` | State · no results |  |
| `StateOffline` | State · offline |  |
| `StateLoading` | State · loading |  |

**Creator: profile, challenge, earnings**

| Board | Title | Requirements |
| --- | --- | --- |
| `CreatorProfile` | Creator profile | CRT-1 |
| `ChallengePage` | Challenge | CRT-2 |
| `CreatorEarnings` | Creator earnings | CRT-3, PAY-10 |

### Club

**Flow: find a club, join, then use it**

| Board | Title | Requirements |
| --- | --- | --- |
| `Main` | Group (category main) | GRP-1 |
| `ClubPrivate` | Private club (outsider view) | GRP-2 |
| `ClubPage` | Club page | GRP-2, GRP-4 |
| `ClubAbout` | Club info | GRP-5 |
| `FullLeaderboard` | Leaderboard | PAS-8 |
| `ClubChat` | Club chat | CHT-2, GRP-11 |
| `ClubMembers` | Club members | GRP-9 |
| `ClubMember` | Club member · role, remove, ban | GRP-9 |
| `JoinRequests` | Join requests | GRP-6 |
| `ManageRoles` | Club roles | GRP-7 |
| `RoleMembers` | Role members + add sheet | GRP-7 |
| `AuditLog` | Audit log | GRP-10 |
| `TeamPage` | Team page | GRP-15 |
| `TeamRoster` | Team roster | GRP-15 |
| `TeamChat` | Team chat | CHT-2, GRP-17 |
| `ClubPublic` | Club page for non-members | GRP-2 |
| `ClubAnnouncements` | Club announcements | GRP-11 |
| `ClubAnnounceNew` | New announcement (admin) | GRP-11 |
| `TeamFixture` | Team fixture | GRP-15 |

**Create: club, role, team**

| Board | Title | Requirements |
| --- | --- | --- |
| `CreateGroupType` | Create · club or team | GRP-14 |
| `CreateClub` | Create club · Step 1 details | GRP-3 |
| `CreateClubSports` | Create club · Step 2 sport interest | GRP-3 |
| `CreateClubLevels` | Create club · Step 3 skill level | GRP-3 |
| `CreateClubInvite` | Create club · Step 4 invite | GRP-3 |
| `CreateTeam` | Create team · Step 1 details | GRP-14 |
| `CreateTeamSport` | Create team · Step 2 sport | GRP-14 |
| `CreateTeamMembers` | Create team · Step 3 players and staff | GRP-14 |
| `CreateRole` | Create role (3 steps) | GRP-7 |

**Update: club settings, overview, reward, bans, roles, team settings**

| Board | Title | Requirements |
| --- | --- | --- |
| `ClubSettings` | Club settings |  |
| `ClubOverview` | Overview · About | GRP-5 |
| `ClubOverviewRules` | Overview · Rules | GRP-5 |
| `ClubOverviewSports` | Overview · Sports | GRP-5 |
| `ClubOverviewOwner` | Overview · Ownership (owner only) | GRP-5 |
| `ClubReward` | Club reward | GRP-12 |
| `ClubBans` | Bans | GRP-9 |
| `ClubTransfer` | Transfer ownership | GRP-13 |
| `RoleEdit` | Role detail | GRP-7 |
| `RolePermissions` | Role permissions | GRP-7, GRP-8 |
| `EditLineup` | Edit lineup (staff) | GRP-16, TRN-7 |
| `TeamSettings` | Team settings | GRP-18 |
| `TeamOverview` | Team overview |  |
| `TeamAddPlayers` | Add players to team | GRP-18 |

**Delete: leave or delete a club, delete a role, leave or delete a team**

| Board | Title | Requirements |
| --- | --- | --- |
| `ClubLeave` | Leave club | GRP-13 |
| `ClubDelete` | Delete club | GRP-13 |
| `RoleDelete` | Delete role | GRP-7 |
| `TeamLeave` | Leave team | GRP-18 |
| `TeamDelete` | Delete team | GRP-18 |

### Play

**Main: browse, filter, schedule**

| Board | Title | Requirements |
| --- | --- | --- |
| `ActivityHub` | Play (category main) | PLY-1 |
| `PlayFilters` | Play · Meet filters (sport added) | PLY-2 |
| `PlayFiltersTournament` | Play · Tournament filters (sport added) |  |
| `PlayFiltersEvent` | Play · Event filters open |  |
| `PlaySport` | Play · Add sport screen | PLY-2 |
| `PlaySportDialog` | Play · Sport options dialog (game type, skill level range) | PLY-2 |
| `MySchedule` | My schedule · player (Aaron) | PLY-4 |
| `MyScheduleHosting` | My schedule · organizer (Hannah), Hosting tab | PLY-4 |
| `ActivityCards` | Play cards (Meet, tournament, event) | PLY-3 |

**Browse · Meet: join and pay, players, attendance, scores, recap**

| Board | Title | Requirements |
| --- | --- | --- |
| `MeetPage` | Meet detail (member / organizer) | MET-3 |
| `MeetPay` | Payment sheet · review and pay (the same in every paid flow) | PAY-1 |
| `MeetConfirm` | Payment sheet · confirm it is you | PAY-1 |
| `MeetPaid` | Payment sheet · receipt | PAY-1 |
| `MeetLeave` | Meet · give up a spot, refund to Wallet or card | MET-6, PAY-3 |
| `MeetWaitlist` | Meet · join the waitlist | MET-4 |
| `MeetGuest` | Meet · bring a guest | MET-5 |
| `MeetOrganizer` | Meet detail (organizer view) | MET-7 |
| `MeetHostPay` | Meet · organizer takes a spot (platform fee only) | MET-7 |
| `MeetPlayers` | Meet · full player list | MET-11 |
| `MeetWalkIn` | Add a walk-in (organizer) | MET-8 |
| `MeetAttendance` | Mark attendance (organizer, auto-marked on arrival) | MET-8, PAS-2 |
| `MeetAttendanceCheckIn` | Attendance · venue not detected, organizer taps Check in | MET-8 |
| `MeetRecap` | Meet recap · shareable stats card | PAS-12, PAS-26 |
| `ScoreEntry` | Enter a score (player) | MET-10, PAS-4 |
| `ScoreCamera` | Score · camera tracking, with Camera / Manual switch (Phase 2) |  |
| `ScoreCameraLost` | Score · camera lost tracking, switch to manual (Phase 2) |  |
| `ScoreConfirm` | Confirm a score, then rating change | MET-10, PAS-4 |

**Browse · Event: free ticket (organizer pays the fee) and paid ticket**

| Board | Title | Requirements |
| --- | --- | --- |
| `EventPage` | Event detail · festival | EVT-3 |
| `EventPageLive` | Event detail · linked to a tournament | EVT-4 |
| `EventTicketFree` | Event · free ticket, nothing to pay | EVT-2 |
| `EventTicketPaid` | Event · paid ticket, payment sheet | EVT-2 |
| `EventTicket` | Event ticket code | EVT-3 |
| `EventTicketRelease` | Event · release tickets | EVT-5 |

**Browse · Tournament**

| Board | Title | Requirements |
| --- | --- | --- |
| `TournamentPage` | Tournament page | TRN-2, TRN-9, TRN-13, TRN-19 |
| `TournamentPageIn` | Tournament page (registered) | TRN-2 |
| `TournamentRegister` | Register | TRN-2 |
| `TournamentPay` | Tournament · payment sheet | PAY-1, TRN-2 |
| `PartnerSearch` | Find a doubles partner | TRN-2 |
| `TournamentDraw` | Draw · groups and knockout | TRN-3 |
| `TournamentMyMatches` | Tournament · my matches | TRN-3, TRN-11 |
| `TournamentResults` | Tournament · results | TRN-4, TRN-19 |
| `TournamentWithdraw` | Tournament · withdraw | PAY-3, TRN-5 |

**Create · start here**

| Board | Title | Requirements |
| --- | --- | --- |
| `CreateMenu` | Create menu |  |

**Create · Meet**

| Board | Title | Requirements |
| --- | --- | --- |
| `CreateMeetSport` | New Meet · Step 1 sport | MET-1 |
| `CreateMeet` | New Meet · Step 2, part 1 Basics | MET-1 |
| `CreateMeetGame` | New Meet · Step 2, part 2 Game | MET-1 |
| `CreateMeetFee` | New Meet · Step 2, part 3 Fee | MET-1, MET-2 |
| `PickDateMeet` | New Meet · date picker | MET-1 |
| `PickTimeMeet` | New Meet · time picker | MET-1 |
| `PickVenueMeet` | New Meet · venue picker | MET-1 |

**Create · Event**

| Board | Title | Requirements |
| --- | --- | --- |
| `CreateEventSport` | New event · Step 1 sports | EVT-1 |
| `CreateEvent` | New event · Step 2 details | EVT-1 |
| `PickDateEvent` | New event · date and time | EVT-1 |
| `PickVenueEvent` | New event · venue | EVT-1 |

**Create · Tournament**

| Board | Title | Requirements |
| --- | --- | --- |
| `CreateTournamentSport` | New tournament · Step 1 sport | TRN-1 |
| `CreateTournament` | New tournament · Step 2 details | TRN-1, TRN-8 |
| `CreateTournament3` | New tournament · Step 3 game setup | TRN-1, TRN-7 |
| `CreateTournament4` | New tournament · Step 4 entry | TRN-1 |
| `PickDateTournament` | New tournament · dates |  |
| `PickTimeTournament` | New tournament · daily start |  |
| `PickVenueTournament` | New tournament · venue |  |
| `PickCloseTournament` | New tournament · registration closes |  |

**Update: organizer manage screens (editing reuses the create forms)**

| Board | Title | Requirements |
| --- | --- | --- |
| `TournamentManage` | Manage tournament (organizer) | TRN-6, TRN-17, TRN-21, TRN-22 |
| `TournamentEntries` | Tournament entries (organizer) | TRN-6 |
| `TournamentCheckIn` | Tournament check-in (organizer) | TRN-6 |
| `ScoreUmpire` | Enter a score (umpire, final) | TRN-4, TRN-15, TRN-16 |
| `TournamentMessage` | Message entrants (organizer) | TRN-6 |
| `EventManage` | Manage event (organizer) | EVT-5 |

**Delete: cancel a Meet, tournament or event**

| Board | Title | Requirements |
| --- | --- | --- |
| `MeetCancel` | Cancel Meet | MET-9, PAY-2 |
| `TournamentCancel` | Cancel tournament | PAY-2, TRN-6 |
| `EventCancel` | Cancel event | EVT-5, PAY-2 |

**Earnings and payouts: organizer, club, academy**

| Board | Title | Requirements |
| --- | --- | --- |
| `Earnings` | Earnings (organizer) | PAY-10 |
| `EarningsDetail` | Earnings · one Meet | PAY-10 |
| `Payout` | Pay out | PAY-10 |
| `PayoutAccount` | Payout account | PAY-10 |

### Academy

**Flow: find an academy, coach view, parent view**

| Board | Title | Requirements |
| --- | --- | --- |
| `AcademyCategory` | Academy (category main) | ACD-1 |
| `AcademyPublic` | Academy public page | ACD-1 |
| `AcademyEnrol` | Ask to enrol | ACD-2 |
| `AcademyHome` | Academy · Today (head coach) | ACD-4 |
| `AcademyClasses` | All classes (coach) | ACD-4 |
| `ClassSession` | Class session (coach) | ACD-4 |
| `ClassRoster` | Class roster (coach) | ACD-4 |
| `Curriculum` | Curriculum (shared by coaches) | ACD-5 |
| `StudentProgress` | Student progress (coach / parent) |  |
| `ParentNote` | Note for parents (coach) | ACD-8 |
| `ParentHome` | Parent home | ACD-9 |
| `StudentProgressParent` | Student progress (parent view) | ACD-9 |
| `ParentClass` | Class details (parent) | ACD-7 |
| `ParentFees` | Fees and invoices (parent) | ACD-9 |
| `FeesPay` | Academy fee · payment sheet | ACD-9, PAY-1 |
| `BookMakeup` | Book a make-up (parent) | ACD-7 |
| `FilmingConsent` | Filming consent (parent) · Phase 2 | ACD-13 |
| `EnrolRequests` | Enrolment requests (coach) | ACD-2 |
| `AcademyMessages` | Academy messages | ACD-8 |
| `TrialClass` | Trial class | ACD-2 |
| `AttendanceHistory` | Attendance history (parent) | ACD-9 |
| `CoachPayout` | Coach pay | ACD-11, PAY-10 |

**Create: academy**

| Board | Title | Requirements |
| --- | --- | --- |
| `CreateAcademy` | Create academy · Step 1 details | ACD-3 |
| `CreateAcademyLevels` | Step 2 sport and levels | ACD-3 |
| `CreateAcademyPolicies` | Step 3 billing and make-ups | ACD-3 |
| `CreateAcademyVerify` | Step 4 verification | ACD-3 |
| `CreateAcademyCoaches` | Step 5 invite coaches | ACD-3 |
| `InviteStudents` | Invite students (coach) | ACD-11 |

**Update: change a class, lesson plans, academy settings**

| Board | Title | Requirements |
| --- | --- | --- |
| `ChangeClass` | Change a class · notify parents | ACD-6 |
| `LessonPlanEdit` | Edit lesson plan (coach) | ACD-5 |
| `DrillVideos` | Drill video library (coach) | ACD-5 |
| `AcademySettings` | Academy settings | ACD-10 |
| `PickDateClass` | Change class · new date | ACD-6 |
| `PickTimeClass` | Change class · new time | ACD-6 |
| `PickCourtClass` | Change class · court | ACD-6 |

**Delete: close academy**

| Board | Title | Requirements |
| --- | --- | --- |
| `AcademyDelete` | Close academy | ACD-11 |

### Game

**Campaigns are created on the web app and appear here**

| Board | Title | Requirements |
| --- | --- | --- |
| `GameCategory` | Game (category main) · campaigns | GAM-1 |
| `GameCampaign` | Campaign page | GAM-1 |

**Workout challenges (camera, Phase 2): challenge, setup, attempt, result; then practice: my workouts, exercises, programs, log**

| Board | Title | Requirements |
| --- | --- | --- |
| `CvSetup` | Challenge · camera setup | GAM-2 |
| `CvAttempt` | Challenge · attempt, rep counted | GAM-2 |
| `CvNoRep` | Challenge · rep not counted (wrong form) |  |
| `CvLost` | Challenge · camera lost tracking, clock paused |  |
| `CvResult` | Challenge · result and rank | GAM-2 |
| `CvReview` | Challenge · send video for review |  |
| `WorkoutCampaign` | Workout challenge · fastest time, camera counted | GAM-2 |
| `TrainerHome` | My workouts | GAM-2 |
| `ExerciseCatalog` | Workouts · exercise catalog | GAM-2 |
| `ExerciseDetail` | Workouts · exercise |  |
| `ProgramBuilder` | Workouts · program builder | GAM-2 |
| `TrainMode` | Workout · set in progress | GAM-2 |
| `TrainRest` | Workout · rest timer | GAM-2 |
| `WorkoutLog` | Workouts · log | GAM-2 |
| `TrainerCalc` | Workouts · calculators | GAM-2 |

### Venue

**Flow: find a venue, book a court, manage the booking**

| Board | Title | Requirements |
| --- | --- | --- |
| `VenueCategory` | Venue (category main) | VEN-1 |
| `VenuePage` | Venue page | VEN-1 |
| `VenueBook` | Book a court | VEN-2 |
| `VenueBooking` | My court booking | VEN-2 |
| `VenueBookingCancel` | Cancel a court booking | PAY-3, VEN-2 |

### Shop

**Flow: browse, watch, product, shop page**

| Board | Title | Requirements |
| --- | --- | --- |
| `ShopHome` | Shop (category main) | SHP-1 |
| `ShopVideo` | Shoppable video | SHP-2 |
| `ShopLive` | Live shopping | SHP-2 |
| `ProductPage` | Product page | SHP-3 |
| `MallPage` | Shop page (mall) | SHP-3 |

**Buy: cart, checkout, points**

| Board | Title | Requirements |
| --- | --- | --- |
| `PointsWallet` | Points wallet | PAY-11 |
| `ShopAddresses` | Shop · addresses | SHP-4 |
| `ShopAddressNew` | Shop · new address | SHP-4 |
| `ServiceBook` | Shop · book a service | SHP-7 |
| `Cart` | Cart | SHP-3 |
| `Checkout` | Checkout, then order placed | SHP-3 |
| `CheckoutPay` | Shop · payment sheet with points | PAY-1, PAY-11, SHP-3 |

**After buying: orders, tracking, return, review**

| Board | Title | Requirements |
| --- | --- | --- |
| `OrderCancel` | Shop · cancel an order | PAY-3, SHP-4 |
| `RefundStatus` | Shop · refund tracking | SHP-4 |
| `Orders` | My orders | SHP-4 |
| `OrderDetail` | Order tracking | SHP-4 |
| `ReturnRequest` | Return an item | SHP-4 |
| `WriteReview` | Write a review | SHP-4 |

**Sell: shop tools, products, orders, live and video**

| Board | Title | Requirements |
| --- | --- | --- |
| `SellerHome` | My shop (seller) | SHP-5 |
| `SellerProducts` | Seller · products | SHP-5 |
| `SellerProductEdit` | Seller · add or edit a product | SHP-5 |
| `SellerOrders` | Seller · orders | SHP-5 |
| `SellerOrderDetail` | Seller · pack and ship | SHP-5 |
| `SellerGoLive` | Seller · go live | SHP-5 |
| `SellerUploadVideo` | Seller · post a video | SHP-5 |

### Admin web app (desktop, for the Olympus team)

**Safety: today, reports, one case, notices and orders, decision log**

| Board | Title | Requirements |
| --- | --- | --- |
| `AdminHome` | Admin · today | ADM-1 |
| `AdminReports` | Admin · reports queue | ADM-1 |
| `AdminCase` | Admin · one case, decision | ADM-1, TRN-22 |
| `AdminLegal` | Admin · notices and orders | ADM-1 |
| `AdminLog` | Admin · decision log | ADM-1 |

**Money and checks: refunds and disputes, payouts, checks**

| Board | Title | Requirements |
| --- | --- | --- |
| `AdminRefunds` | Admin · refunds and disputes | ADM-2 |
| `AdminPayouts` | Admin · payout run | ADM-2 |
| `AdminVerify` | Admin · identity, business and coach checks | ADM-3 |

**Game: campaigns made here appear in the app**

| Board | Title | Requirements |
| --- | --- | --- |
| `AdminCampaigns` | Admin · campaigns | ADM-4 |
| `AdminCampaignNew` | Admin · new campaign | ADM-4 |

### Academy space of the web app (owner: Coach Ravi)

**Run the academy: today, timetable, students, enrolments, fees**

| Board | Title | Requirements |
| --- | --- | --- |
| `AcwHome` | Academy web · today | ACD-12 |
| `AcwTimetable` | Academy web · timetable | ACD-12 |
| `AcwStudents` | Academy web · students and parents | ACD-12 |
| `AcwEnrol` | Academy web · enrolments and trials | ACD-12 |
| `AcwFees` | Academy web · fees and invoices | ACD-12 |

**People and places: coaches, locations, staff. A change here shows in the app**

| Board | Title | Requirements |
| --- | --- | --- |
| `AcwCoaches` | Academy web · coaches and cover | ACD-12 |
| `AcwLocations` | Academy web · move a location (updates the app) | ACD-12 |
| `AcwStaff` | Academy web · staff and access | ACD-12 |
| `AcademyMoveNotice` | App · parent sees the academy move (saved once on the web) | ACD-12 |

### OlympusGO: new screens (not in the set above)

| Board | Title | Requirements |
| --- | --- | --- |
| `OG_AddGear` | Add gear · badminton racquet |  |
| `OG_GearPaddle` | Gear · paddle |  |
| `OG_LoginPhone` | Log in · phone |  |
| `OG_Ready` | All set |  |
| `OG_AddGearTennis` | Add gear · tennis racquet |  |
| `OG_LoginUsername` | Log in · username |  |
| `OG_OnboardingAccountCentre` | Onboarding account centre |  |
| `OG_OrderConfirmed` | Order placed |  |
| `OG_AddGearTableTennis` | Add gear · table tennis bat |  |
| `OG_CreateChallenge` | New challenge · creators |  |
| `OG_LoginEmailCode` | Login code · email |  |
| `OG_OnboardingPersonalInfo` | Onboarding personal information screen |  |
| `OG_AddGearPickleball` | Add gear · pickleball paddle |  |
| `OG_CreatorChallenges` | Challenges · grace period (900 followers) |  |
| `OG_FullName` | Name |  |
| `OG_Settings` | Settings |  |
| `OG_AddGearShoes` | Add gear · shoes |  |
| `OG_Notifications` | Notifications |  |
| `OG_SkillBadminton` | Badminton · level and preference |  |
| `OG_GearRacquet` | Gear · racquet |  |
| `OG_PrivacySafety` | Privacy and safety |  |
| `OG_SkillPickleball` | Pickleball · level and preference |  |
| `OG_GearShoes` | Gear · shoes |  |
| `OG_ShareProfile` | Share profile |  |
| `OG_Username` | Username |  |

## Named in the PRDs but not on the canvas

**New screens still to draw** (marked "New" in the tournaments PRD):

| Screen | Requirements |
| --- | --- |
| Add match | TRN-17 |
| Court board | TRN-23 |
| Live match card | TRN-13 |
| Match page | TRN-12, TRN-14, TRN-18 |
| Match schedule | TRN-10, TRN-11, TRN-9 |
| Order of play | TRN-21 |
| Profile card | PAS-26 |
| Sport profile | PAS-14, PAS-15, PAS-16, PAS-17, PAS-18, PAS-19, PAS-20, PAS-21, PAS-22, PAS-23, PAS-24, PAS-25 |
| Tournament leaders | TRN-20 |

Every other screen name in the PRDs matches a board on Club Screen Mockup.

## OlympusGO Screens (final look)

Same flows in the design system. Where a screen exists in both canvases, build the layout from this one.

| Section | Boards |
| --- | --- |
| Splash and welcome | Splash (`Main`); Welcome (`Welcome`) |
| Authentication | Sign up · email (`SignUp`); Sign-up code · email (`EmailCode`); Log in · email (`LogIn`); Log in · phone (`LoginPhone`); Log in · username (`LoginUsername`); Login code · email (`LoginEmailCode`); Login code · SMS (`SmsCode`); Get back your account (`Recovery`); Recovery email sent (`RecoverySent`) |
| Onboarding | Name (`FullName`); Date of birth (`Birthday`); Select sports (`Sports`); Set sport skill level (`SkillLevel`); Badminton · level and preference (`SkillBadminton`); Pickleball · level and preference (`SkillPickleball`) |
| Account details | Username (`Username`); Mobile number (`MobileNumber`); Verify mobile number (`VerifyMobile`); All set (`Ready`); Under 18 · parent approval (`ParentOK`) |
| Account setup | Onboarding account centre (`OnboardingAccountCentre`); Onboarding personal information screen (`OnboardingPersonalInfo`) |
| Profile and settings | Profile (`Profile`); Player profile (`PlayerProfile`); Settings (`Settings`); Account centre (`AccountCentre`); Personal information (`PersonalInfo`); Notifications (`Notifications`); Privacy and safety (`PrivacySafety`) |
| Followers, sharing and player stats | Following (`Following`); Followers (`Followers`); Share profile (`ShareProfile`) |
| Gear | Add gear · badminton racquet (`AddGear`); Add gear · tennis racquet (`AddGearTennis`); Add gear · table tennis bat (`AddGearTableTennis`); Add gear · pickleball paddle (`AddGearPickleball`); Add gear · shoes (`AddGearShoes`); Gear · racquet (`GearRacquet`); Gear · shoes (`GearShoes`); Gear · paddle (`GearPaddle`) |
| Cart and challenges | Order placed (`OrderConfirmed`); New challenge · creators (`CreateChallenge`); Challenges · grace period (900 followers) (`CreatorChallenges`) |
| Main navigation | Home (`Home`); Discover (`Discover`); Scan (`Scan`); Inbox (`Inbox`) |
| Search, saved and scan results | Search · before typing (`SearchStart`); Search · results (`SearchResults`); Saved (`Saved`); Scan result · player (`ScanPlayer`); Scan result · checked in (`ScanCheckedIn`) |
| Messages, other players and safety | Direct message (`DirectMessage`); Another player's profile (`OtherProfile`); Report or block (`ReportBlock`); Blocked players (`BlockedPlayers`); Help (`Help`); Log out (`LogOut`) |
| Play: browse, filters, schedule | Play · Meets (`Play`); Play · add sport (`PlayAddSport`); Play · Meet filters (`PlayMeets`); Play · sport options (`PlaySportOptions`); My schedule · player (`MySchedule`); Play · tournaments (`PlayTournaments`); My schedule · organizer (`MyScheduleHosting`); Play · tournament filters (`PlayTournamentFilters`); Play cards (`PlayCards`); Play · events (`PlayEvents`); Play · event filters (`PlayEventFilters`) |
| Play: Meet detail, pay, waitlist, guest | Meet detail (`MeetDetail`); Payment sheet · review and pay (`PaySheet`); Payment sheet · confirm it is you (`PayConfirm`); Payment sheet · receipt (`PayReceipt`); Meet · give up a spot (`MeetGiveUp`); Meet · join the waitlist (`MeetWaitlist`); Meet · bring a guest (`MeetGuest`) |
| Create: start and Meet | Create menu (`CreateMenu`); New Meet · step 1 sport (`NewMeet1`); New Meet · step 2, part 1 Basics (`NewMeet2a`); New Meet · step 2, part 2 Game (`NewMeet2b`); New Meet · step 2, part 3 Fee (`NewMeet2c`); New Meet · date picker (`NewMeetDate`); New Meet · time picker (`NewMeetTime`); New Meet · venue picker (`NewMeetVenue`) |
| Create: event | New event · step 1 sports (`NewEvent1`); New event · step 2 details (`NewEvent2`); New event · date and time (`NewEventDate`); New event · venue (`NewEventVenue`) |
| Create: tournament | New tournament · step 1 sport (`NewTourn1`); New tournament · step 2 details (`NewTourn2`); New tournament · step 3 game setup (`NewTourn3`); New tournament · step 4 entry (`NewTourn4`); New tournament · dates (`NewTournDates`); New tournament · daily start (`NewTournStart`); New tournament · venue (`NewTournVenue`); New tournament · registration closes (`NewTournClose`) |
| Club: find a club, join, then use it | Club member · role, remove, ban (`ClubMember`); Group (category main) (`ClubsHome`); Private club (outsider view) (`ClubPrivate`); Join requests (`JoinRequests`); Club page for non-members (`ClubPublic`); Club roles (`ManageRoles`); Club page (`ClubPage`); Role members + add sheet (`RoleMembers`); Audit log (`AuditLog`); Club info (`ClubAbout`); Leaderboard (`FullLeaderboard`); Team page (`TeamPage`); Club chat (`ClubChat`); Team roster (`TeamRoster`); Club announcements (`ClubAnnouncements`); Team chat (`TeamChat`); New announcement (admin) (`ClubAnnounceNew`); Team fixture (`TeamFixture`); Club members (`ClubMembers`) |
| Club: create a club, team or role | Create · club or team (`CreateGroupType`); Create club · Step 1 details (`CreateClub`); Create club · Step 2 sport interest (`CreateClubSports`); Create club · Step 3 skill level (`CreateClubLevels`); Create club · Step 4 invite (`CreateClubInvite`); Create team · Step 1 details (`CreateTeam`); Create team · Step 2 sport (`CreateTeamSport`); Create team · Step 3 players and staff (`CreateTeamMembers`); Create role (3 steps) (`CreateRole`) |
| Club: settings, overview, reward, bans, roles, team settings | Club settings (`ClubSettings`); Edit lineup (staff) (`EditLineup`); Overview · About (`ClubOverview`); Team settings (`TeamSettings`); Overview · Rules (`ClubOverviewRules`); Team overview (`TeamOverview`); Overview · Sports (`ClubOverviewSports`); Add players to team (`TeamAddPlayers`); Overview · Ownership (owner only) (`ClubOverviewOwner`); Club reward (`ClubReward`); Bans (`ClubBans`); Transfer ownership (`ClubTransfer`); Role detail (`RoleEdit`); Role permissions (`RolePermissions`) |
| Club: leave or delete, and chat safety | Leave club (`ClubLeave`); Delete club (`ClubDelete`); Delete role (`RoleDelete`); Leave team (`TeamLeave`); Delete team (`TeamDelete`); Club chat · organizer deletes a message (`ClubChatOrganizer`); Report a message (`ReportMessage`); Report a club or event (`ReportClub`) |
| Shop: browse, watch, product, shop page | Shop (category main) (`ShopHome`); Shoppable video (`ShopVideo`); Live shopping (`ShopLive`); Product page (`ProductPage`); Shop page (mall) (`MallPage`) |
| Shop: cart, checkout, points, services | Cart (`Cart`); Checkout, then order placed (`Checkout`); Shop · payment sheet with points (`CheckoutPay`); Points wallet (`PointsWallet`); Shop · addresses (`ShopAddresses`); Shop · new address (`ShopAddressNew`); Shop · book a service (`ServiceBook`) |
| Shop: orders, tracking, cancel, return, review | My orders (`Orders`); Order tracking (`OrderDetail`); Shop · cancel an order (`OrderCancel`); Shop · refund tracking (`RefundStatus`); Return an item (`ReturnRequest`); Write a review (`WriteReview`) |
| Shop: sell (seller tools, products, orders, live, video) | My shop (seller) (`SellerHome`); Seller · products (`SellerProducts`); Seller · add or edit a product (`SellerProductEdit`); Seller · orders (`SellerOrders`); Seller · pack and ship (`SellerOrderDetail`); Seller · go live (`SellerGoLive`); Seller · post a video (`SellerUploadVideo`) |
| Wallet: refunds land here, withdraw, refund rules (top-up later) | Wallet (`Wallet`); Wallet · withdraw to my bank (`WalletWithdraw`); Refund rules (Wallet, Help, Terms) (`RefundRules`); Wallet · top up (later, not at launch) (`WalletTopUp`) |
| Creator: profile, challenge, earnings | Creator profile (`CreatorProfile`); Challenge (`ChallengePage`); Creator earnings (`CreatorEarnings`) |
| Earnings and payouts: organizer, club, academy | Earnings (organizer) (`Earnings`); Earnings · one Meet (`EarningsDetail`); Pay out (`Payout`); Payout account (`PayoutAccount`) |
| Safety and law: report, what happens next, rules, legal, under-18, country | Report a video or live (`ReportVideo`); Report a listing, shop or review (`ReportListing`); My reports (`MyReports`); Report · progress, result, second look (`ReportDetail`); Notice · your content was removed, ask for a review (`ContentRemoved`); Notice · complaint, 48 hours to reply (New Zealand) (`ComplaintReply`); Community rules (`CommunityRules`); Legal notice (no account needed) (`LegalNotice`); Under-18 protection (`Under18Safety`); Country · currency, emergency number, local rules (`CountrySettings`) |
| Terms and teen view | Terms and privacy (`Legal`); Videos · under-18 view, following only (`VideoFeedTeen`) |

## People in the prototype

All are fake. Use them in seed data and tests; never use real people.

| Role | Person |
| --- | --- |
| Player (signed in) | Aaron Ng, parent of Ethan Ng (10, child profile) and Chloe Ng (14, own account Aaron approves) |
| Organizer and club owner | Hannah Goh, Tampines Smashers |
| Academy owner | Coach Ravi, Smash Academy (coaches Mei, Daniel, Farah; front desk Jasmine Lee) |
| Olympus staff | Nur Aisyah, trust and safety lead (colleagues Daniel Lim, Grace Tan) |
| Doubles partner | Priya Raman |
| Another player | Wei Ming Chua |
| "Today" in the prototype | Fri 2 Oct 2026 |

The Meet used everywhere: Doubles Social, Fri 2 Oct, 8:00 to 10:00 PM, S$6.00 plus the S$2.00 fee, 8 of 12 playing before Aaron joins.
