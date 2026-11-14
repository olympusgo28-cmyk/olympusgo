# Status against DEVELOPER_CHECKLIST.md: Phase 5a (1 Nov 2026)

"Proven" means a test or a real run shows it. `fitness.enabled` stays off, so the Fitness tile shows today's empty page until it's switched on.

| Ticket | State |
| --- | --- |
| P5-04 Fitness | Proven at the database, through the real API and in widget tests. Exercises, programs, templates, workouts with a rest timer, log, personal bests and calculators. |

## Not built

- Form checks. These start as a spike, later.
- Camera challenges and "My challenges", which stay demo only.
- Exercise videos. The detail screen uses written steps and a plain tile.
- An admin screen for the catalogue (Q172).
- Sharing workouts.

## Differences from the documents

- Fitness has its own Home tile, as the checklist says. The PRD puts workouts under Game.
- Workout logs live on our server, not the phone (Q177).
- About 40 exercises, not the board's 240 (Q169).
- Medical wording is changed (Q174).
- One-rep max and body mass index are hidden from under-18s (Q175).
- A workout can be discarded, and a log entry deleted. The boards don't draw these.

## Known gaps

- A coach hasn't reviewed the exercises, the under-18 list or the templates (Q168, Q169).
- The log lists the latest 100 workouts in a range. The totals still count all of them.
- Deleting an account is still done by support. Fitness data goes when that deletes the login, and a test proves it. The support procedure must name these tables (Q182).
- There's no export of a player's data yet, so workouts aren't in one.
- A workout refused by the server, for example after an exercise stops being suitable, can only be discarded.
- The rest timer counts from the clock while the app is open. It doesn't sound or notify if the app is closed, and it restarts from nothing if the player leaves the screen.
- A workout left open for over 12 hours ends at its last set. If the phone's clock moved backwards it ends at its start.
- A phone with a clock over 5 minutes fast can't save until real time catches up. The workout waits on the phone.
- A finished workout that couldn't save waits for the player to tap save. Nothing retries by itself.
- Times in the streak use the player's country. Someone travelling may see a week boundary move.

## Walkthrough

On an iPhone 17 Pro simulator against the local stack, 1 Nov:

- An adult built a program from a template, set 72.5 kg, started it, and the rest timer counted down.
- A finished workout appeared in the totals, with 72.5 kg × 5 shown as 363 kg lifted.
- Closing the app with a set logged kept the workout, and it reopened as in progress. This was repeated on the final code.
- With the API down, Finish showed "Not saved yet" and kept the workout. Once the API was back, the retry saved it once.
- As a linked teen, the same program showed 1 exercise instead of 4, the list was bodyweight and bench work only, and Calculators offered Plates only. The earlier log stayed.

The teen run was before the last round of fixes, which didn't touch the age rules. The database tests prove those on the final code.
