# Fitness: four training upgrades (design)

Status: slices 1 (the workout screen), 2 (the body map) and 3 (progression suggestions) are built and tested, 17 Nov 2026; none has been checked on a phone. Slices 4 and 5 are design only. The owner chose these four on 17 Nov 2026 (`docs/OPEN_QUESTIONS.md` Q277). Open points are numbered there as Q277 (a) to (p).

## Where this comes from

The owner asked for features like those in the openGym project. openGym's code, exercise text and media are **not** used (Q277: its code is AGPL, its media is licensed to it alone). This design was written from OlympusGO's own Fitness code and openGym's public feature list only. Nobody building these should read openGym's source.

## What Fitness has today

- About 40 exercises, each with a muscle group and a list of muscles (14 muscle names in all).
- Programs, templates, a workout screen with a rest timer, a log, personal bests and calculators.
- `exercise_history` already returns, for one exercise, the player's best set and their last 30 sets with dates.
- Known gaps from `phase-5a-status.md`: the rest timer starts again from nothing if the player leaves the screen, and it makes no sound when the app is closed.

## Rules that apply to all four (`docs/RULES.md`, 11c)

- R-FIT-1, Q170: a player's log is private to them; a linked parent can see a child's log up to age 17 (Q170 is the later decision and wins).
- R-FIT-2: under-18s see and save only exercises marked suitable.
- R-FIT-3: no calorie or medical claims. Nothing here says a muscle is "recovering", "neglected" or "overtrained".
- R-FIT-4: nothing earns points, vouchers, badges or rating. A new best is a plain line of text.
- R-FIT-5: weight is whole grams.
- R-FIT-7: one-rep max stays hidden from under-18s. None of these four shows one.
- R-FIT-9, R-FIT-10: nothing new goes into an AI request.
- No personal data in logs or analytics (AGENTS rule 8).

---

## 1. Workout screen: a timer that keeps its place, last time, new best

**What the player sees** on the workout screen (`TrainScreen`):

- Under the exercise name, a caption: "Last time: 70 kg × 5, 5, 4 · 12 Nov". The first time: "First time doing this."
- A weighted exercise with no weight planned starts at last time's weight, not "—". A weight the program already plans is never replaced.
- While resting: the countdown, "Skip rest" (as today) and "Add 30 seconds".
- Leaving the screen, or the app, and coming back shows the time that is really left, or goes straight to the next set if the rest is over.
- After a set that beats the player's best for that exercise: a plain line on the rest view, "New best: 72.5 kg × 5". The finish summary lists them: "2 new bests". No badge, no animation beyond the usual, no points.

**How it works**

- The time the rest ends is kept with the workout on the phone (`ActiveWorkout.restUntil`), next to `lastSetAt`, so the countdown is worked out from the clock, not from a counter. It is not sent to the server.
- "Last time" and "new best" come from `exercise_history`, which exists. A best is compared the way the database already orders it: weight, then reps, then seconds.
- No migration.

**States:** history still loading (the caption is a grey bar); offline or failed (the caption is left out, the workout carries on); first time; rest already over on return.

**As built**

- `lib/features/fitness/domain/workout_progress.dart`: last time's sets and text, the weight to start from, and what counts as a new best. `ActiveWorkout` carries `restUntil` and `restFor`.
- A new best must beat the saved best and every earlier set of that exercise in the same workout. A first time is never one, and nothing is claimed when the history can't be read.
- A weight is taken from last time once per exercise, before its first set. The workout on the phone remembers that the weight was set (`ActiveWorkout.weightSet`), so a weight the player then clears stays cleared, even after leaving the screen. The weight taken is the last set's from last time, Q277 (o).
- A rest can't be stretched past an hour, the longest time the database takes for anything timed.
- If the phone's clock is moved back so a rest seems to have more left than its own length, the rest is treated as over, so the countdown can't stick.
- The weight from last time is applied by the workout session itself, which checks again when its turn comes: it never overwrites a weight or reps the player entered in the meantime, and never applies after a set is done. A set is logged from the workout as it stands, not from what the screen last drew.
- 0 kg and no weight are the same: a typed 0 is kept as no weight, and 0 kg never counts as beating a set done without weight.
- The phone buzzes only when a rest runs out by itself, not when it is skipped or the workout is discarded.
- "Last time" is read again when a different account signs in.
- The rest line under a new best names the exercise ("New best: Back squat, 72.5 kg × 5"), because after an exercise's last set the screen has already moved to the next one.
- Demo mode now keeps a real history, so "last time" works there too.

**Not in this slice:** a sound or notification when the rest ends while the app is closed. That needs a notifications package and a permission prompt, Q277 (a).

**Open:** (a) the alert when the app is closed; (b) "Add 30 seconds" is a product number.

---

## 2. Progression: a suggested next weight or reps

**What the player sees:** under "Last time", one more caption with a reason, and a small "Use" button:

- "Try 72.5 kg. You hit 5 reps on every set last time."
- "Stay at 70 kg. You missed reps on a set last time."
- "Try 62.5 kg. Three sessions without hitting your reps." 
- Unweighted: "Try 11 reps. You hit 10 on every set last time."
- Timed: "Try 35 seconds. You held 30 on every set last time."

"Use" changes the rest of this workout only (the screen's existing "change" path). It never changes the saved program, and nothing is applied without the tap. With no history there is no suggestion.

**The rule (the owner confirmed these numbers on 17 Nov 2026; R-FIT-11):**

| Case, from the last session of this exercise | Suggestion | Proposed number | Config key |
| --- | --- | --- | --- |
| Weighted, every set reached the planned reps | Add weight | 2.5 kg | `fitness.progress_step_g` = 2500 |
| Weighted, any set missed reps | Same weight | | |
| Weighted, reps missed in several sessions in a row | Less weight, rounded to the step | 3 sessions, 10% less | `fitness.progress_stall_sessions` = 3, `fitness.progress_deload_pct` = 10 |
| Unweighted, every set reached the planned reps | One more rep, up to a limit | +1, limit 20 | `fitness.progress_rep_step` = 1, `fitness.progress_rep_cap` = 20 |
| Timed, every set reached the planned time | More time, up to a limit | +5 s, limit 120 s | `fitness.progress_seconds_step` = 5, `fitness.progress_seconds_cap` = 120 |

**How it works**

- A pure function in `lib/features/fitness/domain/` over `exercise_history.recent`, grouped by workout date. One unit test per row of the table above, plus the edges (no history, one set, a session with mixed weights).
- The numbers must come from config, not from the app (AGENTS rule 7). The app has no reader for `app_settings`, so the smallest honest way is for `exercise_history` to return them beside the history. That is a small migration with its pgTAP test. Q277 (e).

**Under 18:** no suggestions at all (owner, 17 Nov 2026, Q277 d). Their exercises carry no weight (Q168), and telling a growing player to do more each session is a call for a coach. `exercise_history` sends an under-18 no numbers, so the app shows them no suggestion. The numbers are config and not secret; this decides what the app shows, it does not hide anything.

**Wording:** a suggestion, never an instruction or a health claim. No "you should", no "safe", no "optimal".

**As built**

- Migration `20261118100000_fitness_progression.sql`: seven `app_settings` rows and `exercise_history` returning them as `progress`, for adults only. A missing or unreadable number gives no numbers and never a failed history.
- `lib/features/fitness/domain/progression.dart`: the rule, as a pure function of the planned exercise and the history.
- How "reached the planned reps" is judged: the history holds what was done, not what was planned, so the last session is measured against this workout's plan. It must have at least as many sets as planned now, all at one weight, and that weight must be the one planned now. Otherwise there is no suggestion: one set before an abandoned workout never earns "add weight".
- The 3 missed sessions must be the last three in a row, all at that weight. The oldest session in a full history (30 sets) may be cut short, so it is never judged.
- A suggestion is refused when a step is zero or the result would pass the database's limits.
- Shown only before the exercise's first set. "Use" goes through the workout session, which checks again when its turn comes and changes only the suggested number.
- A missed set on an exercise with no weight, or a timed one, gives no line at all.
- The history does not store what was planned at the time. A session where no set reached today's reps may have been done to a lower target, so it is not counted as a miss: no "Stay at", and it never counts towards "less weight" (Q277 r).
- A timed exercise that also carries weight (the farmer carry) gets no suggestion until the owner decides whether it goes up in time or in load (Q277 s).
- The server sends no numbers when one is missing, is not a whole number, or is outside what a set can hold. A limit below 1 means no suggestion.
- Also the builder's choices, for the owner to confirm (Q277 t): a weighted exercise done with no weight is judged on reps; sets beyond the planned number must also reach the reps; demo mode carries its own copy of the seven numbers.

**Open:** (f) whether to offer "update the program too" after a workout (not in this slice).

---

## 3. Muscle body map

**What the player sees:** a front and a back body outline with the worked muscles filled in the brand colour, the rest pale grey, and the muscle names as text beside it.

- **3a. Exercise detail:** the muscles that exercise works.
- **3a. Program day and the workout hero on My workouts:** the muscles that day works, small (56 points high on a program day, 72 on the workout card), so "Leg day" reads as legs at a glance.
- **3b. My workouts, "This week":** the muscles trained in the last 7 days. One tone only: trained or not.

There is no "recovering", "untrained" or "balance" view: those read as health advice (R-FIT-3).

**Muscles to regions:** the catalogue's 14 names map to regions on the outline.

| Front | Back |
| --- | --- |
| Shoulders, Chest, Biceps, Triceps, Forearms, Core, Obliques, Quads, Inner thighs, Calves | Shoulders, Back, Triceps, Forearms, Lower back, Glutes, Inner thighs, Hamstrings, Calves |

A test fails if the catalogue gains a muscle name with no region.

**The outline:** the owner chose MuscleMap on 17 Nov 2026, Q277 (g). The two options were:

- Proposed: the path data from the **MuscleMap** project by Melih Colpan, which is MIT-licensed (checked at its own repository, `github.com/melihcolpan/MuscleMap`, 17 Nov 2026). Taken from that repository, not from openGym's converted copy, converted to Dart path constants, with its MIT notice added to the app's licences page and a `NOTICE` file.
- Or: our own simpler outline drawn for OlympusGO. No notice needed, but it is design work.

**How it works**

- A `BodyMap` widget taking a set of muscle names, drawn as an SVG with `flutter_svg`. Tokens only for colour.
- 3a needs no migration: exercises already carry their muscles.
- 3b needs the muscles of the last 7 days' sets. `workout_summary` gains a `muscles_week` field (muscle name to number of sets). A small migration with its pgTAP test.

**As built (3a)**

- `lib/features/fitness/domain/muscle_regions.dart`: the 14 muscle names and their parts of the outline, the muscles of a list of exercises (most-used first), and the phrase "Quads, glutes and core".
- `lib/features/fitness/presentation/body_map_paths.dart`: the outline's path data, front and back, from MuscleMap's male front and back files. Its sub-group shapes are left out.
- `lib/features/fitness/presentation/body_map.dart`: `BodyMap` (the picture) and `WorkedMuscles` (the picture with "Works quads, glutes and core"), drawn with `flutter_svg`, which the app already uses. No new package.
- Where it shows: the exercise page, under its muscle tags; each day in the program builder; and the dark workout card on My workouts, with the words "Works quads, calves and glutes" under the card's line. With text larger than 130% the card keeps the words and drops the picture.
- The picture is left out while the exercise list can't be read, and when none of the muscles is known.
- Where the artwork comes from: MuscleMap, at a pinned commit. Comparing files showed that most of its paths are the artwork of an older MIT project, react-native-body-highlighter by ELABBASSI Hicham (89 front and 70 back paths identical), which MuscleMap's repository does not mention. Both copyright notices are carried.
- Our copy was checked against MuscleMap's files by script: 175 paths, the same content in the same order, and the same viewBoxes.
- The notices: `NOTICE.md` at the repository root, the header of the path data file, and `registerBodyMapLicence()`, called at start. The app has no licences page a player can open yet, Q277 (g).
- The outline is the male figure for every player. MuscleMap also has a female figure; which to show, or whether to offer a choice, is Q277 (q).
- Parts not worked are the border grey on a page, and a step lighter than the card on the dark card. Pictures are kept once built.

**Accessibility:** the picture is hidden from screen readers; the text list beside it says the same thing, so colour is never the only carrier. On a program day the words sit beside the picture and wrap there.

**States:** nothing trained this week ("No workouts in the last 7 days", outline all pale); loading (pale outline); error (the card is left out).

**Under 18:** the same as adults.

**Open:** (g) which outline; (h) one tone, or a second tone for "more than once this week".

---

## 4. Import from Strong, Hevy and FitNotes

**What the player sees**

1. My workouts, a row: "Import workouts".
2. Pick the app: Strong, Hevy or FitNotes. A short line says how to export a file from that app.
3. Pick the file from the phone.
4. A review screen before anything is saved: "42 workouts and 1,310 sets found. 31 exercises matched. 12 are not in our list and will be left out." Two lists: matched (their name, our name) and left out. A workout with no matched sets is left out and counted.
5. "Import 38 workouts". Then a result: "38 workouts imported." Importing the same file again adds nothing.
6. Settings for Fitness, a row: "Remove imported workouts", with a confirmation.

**The hard limit:** a saved set must point at one of our ~40 exercises. Import is therefore name matching, and the player is told plainly what was left out. Letting players add their own exercises is a different feature (and collides with R-FIT-2), so it is not part of this.

**How it works**

- The file is read and parsed on the phone. It is never uploaded. Only matched sets go to our server, where workout logs already live (Q177).
- Dropped and never stored: notes and any free text, body weight, effort ratings, distance, heart rate.
- Pounds are converted to whole grams (R-FIT-5). Reps, seconds and weight outside the database's limits (1 to 200 reps, 1 to 3,600 seconds, 0 to 500 kg) are left out and counted.
- Matching: a table of other apps' exercise names to ours, written by us, checked case-insensitively. A manual "Match to…" for a left-out exercise, using the existing exercise picker, is a possible second step, Q277 (k).
- A new RPC, `workout_import`. `workout_save` cannot be reused: it allows only a few workouts a day (`fitness.daily_workouts`), and a history is hundreds. The new RPC keeps every other check of `workout_save` (name length, 1 to 300 sets, at most 12 hours, not in the future, exercise exists), takes a batch, has its own limits from config, and marks rows with `workouts.source = 'import'`.
- Each workout's key is derived from the app, its start time and its name, so a second import of the same file saves nothing new (AGENTS rule 4).
- Imported workouts count in totals, bests, the week streak (for the weeks they fall in) and the body map.
- This slice adds an RPC and a column: plan mode, pgTAP tests for each role, `field_registry`, and an independent security review before it is called done.

**File formats: blocked.** The three apps' export layouts must be read from real export files, not from memory and not from openGym's importer. The owner is asked for one sample export from each app, Q277 (i).

**Under 18:** proposed: import is hidden for under-18s. Most imported lifting is weighted, which they cannot save (R-FIT-2), so almost everything would be left out. Q277 (j).

**Parents:** a linked parent can see a child's log (Q170). If under-18s cannot import, nothing imported is ever in a child's log.

**States:** wrong or unreadable file ("That file isn't a Strong export. Check the steps and try again."); nothing matched; partly imported after a lost connection (running it again finishes the job); over the limit.

**Open:** (i) sample files; (j) under-18s; (k) manual matching; (l) the limits (proposed: 500 workouts per file, `fitness.import_max_workouts`; one import a day, `fitness.import_daily`); (m) whether imported workouts should count in the week streak; (n) the privacy policy must say imported workout history is stored on our server.

---

## Build order

Each slice ships alone, with its tests, and can be switched on with the rest of Fitness (`fitness.enabled`).

| # | Slice | Migration | Blocked on |
| --- | --- | --- | --- |
| 1 | Workout screen: timer, last time, new best | No | Nothing. (b) uses the proposed number until confirmed |
| 2 | Body map 3a: exercise, program day, workout hero | No | (g) which outline |
| 3 | Progression suggestions | Small (numbers in `exercise_history`) | (c), (d) |
| 4 | Body map 3b: this week | Small (`workout_summary`) | Slice 2 |
| 5 | Import | Yes: RPC and a column | (i) sample files, (j), (l) |

## Testing

- Slice 1: unit tests for the timer's remaining time (left, returned, over, clock moved back) and for "new best"; widget tests for each state.
- Slice 3: one unit test per rule row; widget tests for "Use" and for no suggestion; a test that an under-18 sees none.
- Slices 2 and 4: a test that every catalogue muscle has a region; widget tests for the three places and the empty state; pgTAP for `muscles_week`.
- Slice 5: parser tests against the sample files; a second import adds nothing; left-out counts are right; pgTAP for `workout_import` per role (owner, outsider, minor, suspended, anonymous), limits and idempotency.
- A rule check on every new screen: no calorie, point, badge or rank text.
