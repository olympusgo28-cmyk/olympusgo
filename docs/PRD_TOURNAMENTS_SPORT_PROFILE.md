# OlympusGO PRD: Tournaments and Sport Profile

Oct 10, 2026 · @Olympus

## Summary

This PRD adds a live tournament dashboard and a statistics-rich sport profile to OlympusGO, modelled on the four tennis reference screens you sent. It extends the main [OlympusGO PRD](https://claude.ai/code/artifact/fae1caa0-a0be-4725-9c4c-78670fc51cb8): tournament requirements continue from TRN-8 and Passport requirements from PAS-13.

**What the reference screens add that OlympusGO does not have yet**

| Reference screen | What it shows | New in OlympusGO |
| --- | --- | --- |
| Tennis dashboard | A live match card with the running score, and side-by-side match statistics | Live match card, match page, head-to-head statistics |
| Match schedule | Upcoming, Live and Completed tabs, a date range, a filter, matches grouped by day | A schedule of every match, for players and spectators, not only "my matches" |
| Player profile | Five headline numbers, tabs (Overview, Stats, Matches, Charts), tiles with a change against last season | Sport profile with tabs, statistic tiles and season comparison |
| Win rate over time | A line chart by month with a tooltip | Charts tab: win rate and rating over time |

**The one real difference from the reference.** The reference shows professional tennis, where every point is recorded by officials. OlympusGO players are amateurs in badminton and pickleball first, and most matches record only the final score of each game. So this PRD ties every statistic to how the match was scored, and never shows a number the app cannot stand behind.

**Not in this PRD:** registration, payment, the draw, withdrawal and refunds (already TRN-1 to TRN-7), leaderboards (PAS-6 to PAS-9), and camera scoring, which stays in Phase 2.

## Who it is for

Four people use these screens, and the spectator is new: today a tournament is only useful to someone who entered it.

| Person | What they want | Where they get it |
| --- | --- | --- |
| Player in the tournament | When and where the next match is, how the group stands, how they played | Schedule, live match, match statistics, own sport profile |
| Spectator (friend, parent, clubmate, scout) | Follow a match as it happens without being at the court | Schedule, live match card, another player's sport profile |
| Organizer | Run the day: courts, order of play, delays, results | Schedule in organizer mode, order of play, court board |
| Umpire or scorer | Record a match quickly, point by point when asked | Umpire scoring, with an optional point-by-point mode |

A player under 18 follows the main PRD's rules: their profile is never Public, and their statistics are visible only to their Circle and their guardians.

## What exists today and what is new

The canvas already covers entering and running a tournament. What is missing is everything a person watches or looks back on.

| Area | On the canvas today | Gap this PRD fills |
| --- | --- | --- |
| Tournament page | Info, Draw and My matches tabs; events; format and rules (TournamentPage) | No Schedule tab, no live match, no tournament statistics |
| Matches | My matches lists only your own, as Won, Next, Later (TournamentMyMatches) | No list of every match; no Upcoming, Live, Completed; no date or court filter |
| Scoring | Umpire types the final score of each game; camera mode is Phase 2 (ScoreUmpire) | No point-by-point entry, so no running score and no rally statistics |
| Draw | Groups and knockout; "scores update live once confirmed" (TournamentDraw) | Updates only when a match ends, not during it |
| Results | Podium, your placing, your matches, rating change (TournamentResults) | No per-match statistics, no tournament leaders |
| Own profile | Rating, level, 3 tiles, local rank, points, badges, next sessions (Profile) | No tabs, no statistics beyond 3 numbers, no charts |
| History | Rating, sessions, ranked games, games won %, list with rating change (PassportHistory) | No chart; no filter by season, partner or format |
| Other player | Sports and levels, sessions, followers, shared history, badges (PlayerProfile) | No statistics, no match list, no head-to-head record |

The organizer's "Add Match" button in the reference is deliberately not copied as is: in OlympusGO the draw creates the matches (TRN-3), so adding one by hand is limited to friendly or exhibition matches (TRN-17).

## Where the statistics come from

Every statistic belongs to one of three scoring levels, and a screen shows a statistic only when the match was scored at that level or above. This is the rule that keeps the profile honest.

| Level | How the match is scored | Exists today | Statistics it can produce |
| --- | --- | --- | --- |
| 1. Game scores | The final score of each game, confirmed by both sides or typed by an umpire | Yes (ScoreEntry, ScoreConfirm, ScoreUmpire) | Matches, wins, win rate, games won and lost, points won and lost, points won %, average margin, deciding-game record, streak, rating change, placing |
| 2. Point by point | A scorer taps the side that won each rally | No, new in this PRD | Everything in level 1, plus the running score, points won on serve and on return, longest run of points, game points saved and converted, biggest comeback, match duration |
| 2+. Tagged points | The scorer also tags how the rally ended (optional) | No, new in this PRD | Service winners, service faults, winners, errors |
| 3. Camera | The camera tracks the rally | Phase 2, after the feasibility test | Shot speed, rally length, court coverage |

**How the reference numbers translate.** The reference uses tennis terms. Each sport gets its own set, defined once in the Metric Definition Engine the architecture already names:

| Reference (tennis) | Badminton | Pickleball | Level needed |
| --- | --- | --- | --- |
| Win rate | Win rate | Win rate | 1 |
| Matches | Matches | Matches | 1 |
| 1st serve % | Points won on serve % | Points won on serve % | 2 |
| Aces per match | Service winners per match | Service winners per match | 2+ |
| Double faults | Service faults | Service faults | 2+ |
| Break points saved | Game points saved | Game points saved | 2 |
| Break points converted | Game points converted | Game points converted | 2 |
| Best serve (km/h) | Fastest smash | Not offered | 3 |

Tennis keeps the reference's own terms when it is added as a sport.

**Minimums.** A percentage shows only after 5 matches at the level it needs. Below that the tile reads "3 of 5 matches" with a progress bar, not a number.

## Tournament requirements

Fifteen new requirements, TRN-9 to TRN-23. **Release** uses the main PRD's stages; tournaments as a whole ship at Launch. **Screens** names the canvas screen to change, or "New" for one to draw.

### Match schedule

| ID | Requirement | Acceptance criteria | Release | Screens |
| --- | --- | --- | --- | --- |
| TRN-9 | The tournament page gets a Schedule tab listing every match, under Upcoming, Live and Completed. | Opens on Live when a match is live, otherwise Upcoming. Matches are grouped by day, each day with its match count and a collapse arrow. Each row shows time, court, both sides with seed or rating, round, format (for example best of 3 games to 21) and a status chip. Completed rows show the game scores with the winner in bold. | Launch | TournamentPage (new tab), New: Match schedule |
| TRN-10 | Filter the schedule by day or date range, event, round, court, "My matches" and "Players I follow". | The date control offers only the tournament's own days. Active filters show as chips with a count of matches found. "Clear all" resets them. Filters hold while the person stays in the tournament. | Launch | New: Match schedule |
| TRN-11 | Every match shows a true status and time. | Statuses are those in the Match states section. A match that starts late shows its new estimated time and "Running about 20 min late". Times are in the venue's time zone. A walkover or retirement is labelled, never shown as a normal score. | Launch | New: Match schedule, TournamentMyMatches |
| TRN-12 | Follow a match or a player to get alerts. | Alerts: called to court, started, finished with the score. At most 3 alerts per match. Following a player under 18 needs to pass the main PRD's Circle rule. Unfollow from the alert or the match page. | Launch | New: Match page, NotificationSettings |

### Live match

| ID | Requirement | Acceptance criteria | Release | Screens |
| --- | --- | --- | --- | --- |
| TRN-13 | A live match card: both sides, games won, the current game's points, a dot beside the server, the court and a Live chip. | Appears at the top of the tournament page, and on Home when you or a player you follow is playing. With point-by-point scoring the score changes within 5 seconds of the scorer's tap. With game scores only, the card shows games won and "In play", with no running points. If no update arrives for 3 minutes the chip changes to "Score paused". | Launch for game scores; after launch for running points | TournamentPage, HomeV2, New: Live match card |
| TRN-14 | A match page for every match, before, during and after. | Before: both sides, ratings, last 5 results, head-to-head record, court and time. During: the live card plus statistics so far. After: final score by game, duration, rating change for each player, statistics. Always: report link, share link, and the umpire's name when there is one. | Launch | New: Match page |
| TRN-15 | Point-by-point scoring for the umpire: one tap per rally on the side that won it. | The app works out the server, the end of each game and the end of the match from the event's scoring rules. Undo steps back one rally at a time to the start of the game. Works with no signal and sends the points when signal returns. A second scorer can take over with a code. The umpire can switch to typing game scores at any time, and everything recorded so far is kept. | After launch | ScoreUmpire (new mode) |
| TRN-16 | Optional tags on a rally: service winner, service fault, winner, error. | Off by default; the organizer turns it on per event. Tagging never blocks the next rally: an untagged rally still counts for the score. | After launch | ScoreUmpire (new mode) |
| TRN-17 | The organizer can add a match by hand, for a friendly, an exhibition or a play-off the draw does not create. | The match is unranked unless the organizer marks it ranked before it starts. It appears in the schedule with an "Added" label and is recorded in the organizer's audit log. | After launch | TournamentManage, New: Add match |

### Match and tournament statistics

| ID | Requirement | Acceptance criteria | Release | Screens |
| --- | --- | --- | --- | --- |
| TRN-18 | Side-by-side match statistics: one row per statistic, the name in the middle, each side's value and a bar on its own side. | Shows only statistics the match's scoring level supports. The better value on each row is emphasised by weight as well as colour. Doubles shows the pair, not each player. | Launch for level 1; after launch for level 2 | New: Match page |
| TRN-19 | Tournament statistics for one player or pair: totals across their matches in this tournament. | Reached from the tournament page ("Your tournament") and from any entrant's row. Shows matches, games, points won %, biggest win, closest game, rating change so far. | Launch | TournamentPage, TournamentResults |
| TRN-20 | Tournament leaders per event. | Top 5 for points won %, longest winning run of games, and fewest points conceded per game. Needs at least 3 completed matches to appear. Players under 18 appear by first name and initial only. | After launch | New: Tournament leaders |

### Organizer tools

| ID | Requirement | Acceptance criteria | Release | Screens |
| --- | --- | --- | --- | --- |
| TRN-21 | Order of play: the organizer sees every court's queue and can move a match, change its court or delay it. | A change tells both sides and their followers at once. A player is never placed in two matches that overlap; the app warns before saving. Each change is logged with who made it. | Launch | TournamentManage, New: Order of play |
| TRN-22 | Correct a result after it is final. | Allowed for 24 hours after the match, by the organizer only, with a reason. Ratings, the draw and statistics are recalculated, and both sides are told. Later corrections go through Olympus staff. | Launch | TournamentManage, AdminCase |
| TRN-23 | A court board for a screen at the venue: each court's current match and the next one. | A web page opened from a link, with no sign-in, that refreshes on its own. Shows names as the players chose to display them. | After launch | New: Court board (web) |

## Sport profile requirements

Thirteen new requirements, PAS-14 to PAS-26. The sport profile is the Passport grown up: one page per sport, the same layout for your own profile and for another player's, with the viewer's permissions deciding what shows.

### Layout

| ID | Requirement | Acceptance criteria | Release | Screens |
| --- | --- | --- | --- | --- |
| PAS-14 | One sport profile per sport, with a switch at the top. | Opens on the main sport. A sport with no confirmed match shows the empty state, not zeros. Your own profile and another player's use the same layout. | Launch | Profile, PlayerProfile, New: Sport profile |
| PAS-15 | Header: photo or initials, display name, area, playing hand, play style and a verified mark. | Hand and style are optional and chosen by the player from a fixed list per sport (for example "Doubles, front court"). The reference shows age; OlympusGO shows an age division only if the player turns it on, and never a birth date or exact age. | Launch | New: Sport profile, ProfileEdit |
| PAS-16 | A strip of five headline numbers under the header. | Badminton and pickleball: win rate, rating with level, matches, tournaments played, current streak. Each number follows the minimums rule; rating shows "Provisional" until 5 confirmed matches (PAS-4). | Launch | New: Sport profile |
| PAS-17 | Tabs: Overview, Stats, Matches, Charts, Badges. | The tab row scrolls sideways on a narrow phone. The app remembers the last tab per sport. Each tab has its own empty state. | Launch | New: Sport profile |

### Tabs

| ID | Requirement | Acceptance criteria | Release | Screens |
| --- | --- | --- | --- | --- |
| PAS-18 | Overview: five statistic tiles, three on the first row and two on the second, then the win-rate chart. | Each tile has a label, the value, and one line under it: an average per match, or the change against last season ("+4.2% vs last season"). The change shows only when both seasons meet the minimum. A rise is not always good: a rise in service faults is shown in the warning colour. Which five tiles show is set per sport in the metric definitions. | Launch | New: Sport profile |
| PAS-19 | Stats: every statistic for the sport, grouped as Results, Scoring, Serve and Pressure. | Filters: season, format (singles, doubles, mixed), ranked only, tournaments only, and partner. Each row can open a short explanation of how the number is worked out. A group the player has no data for is hidden, with one line saying which kind of scoring unlocks it. | Launch for Results and Scoring; after launch for Serve and Pressure | New: Sport profile |
| PAS-20 | Matches: every confirmed match, newest first. | Each row shows the date, event or Meet, opponent, score by game, Won or Lost, and the rating change. Tapping opens the match page (TRN-14). On another player's profile a line at the top gives your head-to-head record, for example "You and Priya: 3 wins, 2 losses". Loads 20 at a time. | Launch | New: Sport profile, replaces part of PassportHistory |
| PAS-21 | Charts: win rate over time, and rating over time. | A selector switches between Month, Season and Last 20 matches. Touching the line shows a tooltip with the period, win rate, matches played and points won %. A period with fewer than 3 matches is drawn as a hollow point. The chart never draws a forecast: the reference's dashed line into future months is left out. The win-rate axis always runs 0 to 100%. | Launch | New: Sport profile |
| PAS-22 | Partners, for doubles. | Lists each partner with matches together, record and win rate, best first. Needs 3 matches together to appear. A partner who has hidden their statistics shows as "A partner". | After launch | New: Sport profile |

### Rules around the profile

| ID | Requirement | Acceptance criteria | Release | Screens |
| --- | --- | --- | --- | --- |
| PAS-23 | A season is a calendar year. | Matches the Tournament leaderboard, which resets each January (PAS-7). "vs last season" compares the same statistic across the two years. All-time is always available. | Launch | New: Sport profile |
| PAS-24 | The player chooses who sees their statistics: Public, Circle or Private, set per sport. | The default is Circle. Public is not offered under 18. An opponent can always see the result of a match they played in. Rating and level stay visible to organizers for seeding whatever the setting. | Launch | SessionPrivacy, New: Sport profile |
| PAS-25 | Statistics stay correct. | A confirmed result reaches the profile within 1 minute. A disputed match counts for nothing until it is settled. A corrected result (TRN-22) recalculates every number it touched. Each screen has "Report a number that looks wrong". | Launch | New: Sport profile, MyReports |
| PAS-26 | Share a profile card. | An image with the headline strip and one chosen chart; the player picks what shows, as on the Meet recap (PAS-12). Not offered under 18. | After launch | MeetRecap pattern, New: Profile card |

## Match states

Every match is in exactly one of these states, and the schedule, the live card and the alerts all read from it.

&#91;embedded content: match states · 5 on the main path, 3 exceptions\]

A match with an umpire skips "To confirm". A final result can still be corrected by the organizer for 24 hours (TRN-22), which keeps it Final and recalculates everything built on it.

## Rules, edge cases and empty states

These are the cases a developer will otherwise have to guess.

| Case | What the app does |
| --- | --- |
| Walkover (one side absent) | Counts as a win and a loss for the draw. Does not change ratings and is left out of every statistic except matches played. |
| Retirement mid-match | The score so far is kept and shown with "Retired". Counts for the draw; counts for ratings only if at least one game was completed. |
| Doubles | Results and statistics go to both partners. Points won on serve is recorded for the pair, not the person serving. |
| Scoring switched mid-match | Level 2 statistics cover only the rallies recorded point by point, and the match page says "Point statistics cover game 1 only". |
| Scorer loses signal | The scorer's phone keeps the points. Viewers see "Score paused" after 3 minutes, then the score catches up in one step. |
| Two scorers on one match | Only one device scores at a time. The second needs the handover code, and the first is told. |
| Score disputed | The match is Final for the draw once the umpire saves it. Without an umpire it waits for the organizer, as in ScoreConfirm. |
| Casual, unranked matches | Count as sessions. They appear in Matches with a "Casual" label and are left out of win rate and rating unless the viewer turns the "Ranked only" filter off. |
| Player deletes their account | Their name becomes "Former player" in opponents' match lists. Opponents keep their own results and statistics. |
| Blocked players | Neither sees the other's profile. A shared match still appears in each one's list, with the other shown as "A player". |
| Tournament cancelled part-way | Completed matches keep their results, ratings and statistics. No placings or Tournament points are awarded. |

**Empty states**

- **New player, no matches:** "Play a ranked match to start your profile", with a button to find a Meet.
- **Fewer than 5 matches:** tiles show progress, "3 of 5 matches".
- **No point-by-point matches:** the Serve and Pressure groups are hidden, with "Shown after a match scored point by point".
- **Schedule before the draw:** "The schedule appears when registration closes on Sun 18 Oct".
- **No live match:** the Live tab reads "Nothing on court right now" with the next match time.
- **Statistics hidden by the player:** "Priya keeps her statistics private", with her rating and level still shown.

## Release stages, scope and success

Everything that works from game scores ships with tournaments at Launch; everything that needs a scorer tapping each rally follows in the first update after it.

| Stage | What ships | Requirements |
| --- | --- | --- |
| Launch | Match schedule, match page, live card with games won, level 1 statistics, order of play, result correction; sport profile with tabs, tiles, matches list, charts, privacy | TRN-9 to 14 (TRN-13 without running points), TRN-18 and 19, TRN-21 and 22; PAS-14 to 21, PAS-23 to 25 |
| First update after launch | Point-by-point scoring, running score, tags, level 2 statistics, tournament leaders, added matches, court board; partners and the profile card | TRN-13 running points, TRN-15 to 17, TRN-20, TRN-23; PAS-19 Serve and Pressure, PAS-22, PAS-26 |
| Phase 2 | Camera statistics: shot speed, rally length, court coverage | Not numbered here; waits for the badminton camera test |

**Out of scope**

- Live video of matches, and commentary or chat on a match.
- Betting, odds or predictions of any kind, including a forecast line on charts.
- The 3D stadium artwork at the top of the reference dashboard. A photo of the venue or the tournament's cover image takes that place.
- Statistics for races and other timed sports (TRN-8 is Later).
- Comparing two players who have never met, side by side.

**How we will know it works**

| Measure | Target | Measured from |
| --- | --- | --- |
| Entrants who open the schedule on a match day | 80% | App events |
| Spectators per tournament who are not entrants | At least 1 for every 2 entrants | Schedule and match page views |
| Matches with a confirmed score within 10 minutes of ending | 95% | Match records |
| Players who open their sport profile within a day of a tournament | 60% | App events |
| Reports of a wrong statistic | Under 1 per 500 matches | My reports |

The targets are starting points to confirm after the first two tournaments.

## Open decisions for you

Each of these changes what gets drawn or built. My suggestion is given with each.

- [ ] **Who may score point by point?** Only an umpire the organizer assigns, or the players themselves too. Suggested: umpires only, so the statistics can be trusted.
- [ ] **Can a spectator watch without an account?** Suggested: the schedule and scores are open through a shared link; profiles and statistics need sign-in. This ties to the architecture question of whether Discover needs a login.
- [ ] **Is the default for statistics Circle or Public?** Suggested: Circle for adults, matching session privacy (PAS-10). A Public default makes the app feel more alive but exposes people who did not choose it.
- [ ] **Which five tiles lead the Overview for badminton?** Suggested: win rate, points won %, deciding-game record, average margin, current streak, all available from game scores.
- [ ] **Do casual matches count in win rate?** Suggested: no, ranked only, with a filter to include them.
- [ ] **Is point-by-point scoring in the launch or the first update?** Suggested: first update. It needs its own testing with real umpires at a real tournament.
- [ ] **Is tennis added as a sport, with these exact tennis statistics?** It is in the sport list on ProfileSports but has no scoring rules defined yet.
- [ ] **Shall I draw these screens on the canvas?** Six are new: Match schedule, Match page, Live match card, Order of play, Sport profile with its five tabs, and the point-by-point scorer.

## Sources

- Reference screens you sent on 10 Oct 2026: "Tennis Dashboard App Design" by shohan.designs (Orbix Studio), four screens: dashboard, match schedule, tournament statistics, player profile.
- [OlympusGO PRD](https://claude.ai/code/artifact/fae1caa0-a0be-4725-9c4c-78670fc51cb8): TRN-1 to TRN-8 and PAS-1 to PAS-13, which this document extends.
- [Club Screen Mockup](https://claude.ai/code/artifact/ab4ae238-8685-4eb5-9222-bdb6aa4dd670), the design canvas, Version 134: the tournament, scoring, profile and Passport screens named in the tables.
- [OlympusGO checklist](https://claude.ai/code/artifact/b63e72cf-eb5f-42be-8ef2-4e476898ee4c): what is drawn and tested.
