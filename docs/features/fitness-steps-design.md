# Fitness: step tracking (design)

Status: built, 17 Nov 2026, and tested against a fake health store. Not yet checked on a phone (see Testing). Decisions are the owner's, from the same day; open points are in `docs/OPEN_QUESTIONS.md` Q276.

## What it is

Fitness shows how many steps the player has taken today, against a daily goal, and a week or month of steps. The count comes from the phone's health store. It stays on the phone.

## Decisions (owner, 17 Nov 2026)

1. **Source:** Apple Health on iPhone and Health Connect on Android. This gives history and counts steps from a watch.
2. **Storage:** on the phone only. Nothing goes to the server. A new phone starts from what the health store restores.
3. **Under 18:** allowed, the same as adults.

## Rules that apply (`docs/RULES.md`, 11c)

- R-FIT-1 and R-FIT-6: Fitness data is private and stays on the phone. Steps follow this.
- R-FIT-3: no calorie or medical claims. The screen shows steps only: no calories, no "burned", no health advice.
- R-FIT-4: nothing in Fitness earns points, vouchers, badges or rating. There is no step streak badge, no reward and no leaderboard.
- R-FIT-9: nothing about steps goes into an AI request.
- Logs, events and analytics carry no step counts (AGENTS rule 8).
- Under-18s: R-FIT-7 hides some calculators for them; steps are allowed by the owner's decision, so they are not hidden. Q276 records this so it is not mistaken for an oversight.

## Screens

### 1. A Steps card on "My workouts" (`FitnessHomeScreen`)

Between the workout hero and the three stat tiles. Tapping it opens Steps.

- Box: white, 20-point corners, a 1.5-point orange edge when connected, 14 points of padding.
- Left: a progress ring, 76 points, orange on a pale track, with the percentage inside (Inter 13 Medium).
- Middle: "Steps today" (caption, Inter 13 Regular, muted); the count ("6,420", Inter 28 Medium, no role: use `score` 32 if the role is kept); "Goal 10,000" (caption).
- Right: a chevron.
- Under the row: seven small bars for the last seven days, today in orange, 12 points under the row.
- Over 100%: the ring is full and the line reads "Goal reached" in place of "Goal 10,000". No badge.

### 2. The Steps screen

Header "Steps" with a back button (Inter 20 Medium).

- A ring 170 points across: the count (Inter 32 Medium, `score`), "of 10,000 steps" (caption), and "Updated 2:41 PM" under it (caption).
- Pill tabs Day, Week, Month (`PillTabs`, Week by default).
- Bars: one per day for the last 7 days (Week) or the last 30 days (Month); Day shows the 24 hours of today. Today's bar is orange, the others grey, with a dashed goal line and "Goal" at its right. Day letters under the bars (Inter 11 Regular is below the type scale, so use caption 13).
- Two number tiles (`_Stat` style, soft grey, 18-point corners): "daily average" and "best day, Sat" (number Inter 28 Medium, label caption).
- A "Daily goal" row (`KitNavTile`): the goal as its subtitle, opens a goal picker sheet.
- A note, caption: "Steps come from this phone and stay on it. Nobody else can see them."

### 3. The goal sheet

A bottom sheet (`showKitSheet`) with a stepper: 1,000 to 50,000 in steps of 500. The default is **10,000**. It is a constant in `domain/steps.dart` for now, because the app has no reader for `app_settings` yet; it moves to config (`fitness.step_goal_default`) when one exists. This is a product number the owner has not confirmed (Q276). The player's own goal is stored on the phone, in secure storage.

## States

- **Not connected:** the card on Fitness reads "Count your steps" with a short line and an "Allow step counting" button; the Steps screen shows the same prompt. Tapping asks for permission.
- **Permission refused:** "Steps are off. Turn them on in Settings." with a button that opens the phone's settings. The card stays but is quiet (no orange edge).
- **No data yet:** the ring is empty and the line reads "No steps yet today". Week and Month show empty bars, not zeros that look like data.
- **Loading:** the numbers show a grey bar the size of the text; the ring is empty.
- **Error:** "Can't read your steps right now." and "Try again". Never a raw error.
- **Offline:** unaffected; steps are on the phone.
- **Simulator or no health store:** the card is hidden, so a phone with no step source shows no empty promise.

## Entities and code

- `lib/features/fitness/domain/steps.dart`: `StepsDay`, `StepsSummary` (today, percent, average, best day, ranges), `StepsAccess` (not asked, allowed, denied, unavailable), the `StepSource` interface and the goal limits.
- `lib/features/fitness/data/step_source.dart`: `FakeStepSource` (demo mode and tests) and the goal store.
- `lib/features/fitness/data/health_step_source.dart`: `HealthStepSource`, which reads through a `HealthGateway`. The real gateway uses the `health` package (HealthKit and Health Connect), and counts steps once across every app and device that writes them.
- `lib/features/fitness/application/steps_providers.dart`: access, goal, 30 days of steps, hours of a day.
- `lib/features/fitness/presentation/steps_screen.dart`: `StepsCard`, `StepsScreen`, ring, bars and the goal sheet; route `Routes.fitnessSteps`.
- Demo mode (no Supabase) shows made-up steps from `FakeStepSource.demo()`; a build against a real backend reads the phone.
- Nothing is sent or logged: the reader has no network code and no logging.

## What the store listings need

- **iPhone (done in the project):** the HealthKit capability (`Runner.entitlements`; the App ID must have HealthKit switched on in the Apple developer account), `NSHealthShareUsageDescription` in `Info.plist` ("OlympusGO reads your step count to show it on your Fitness page. It stays on your phone."), and a Health data answer in App Store privacy. Apple does not allow health data for advertising; we do none.
- **Android (done in the manifest):** the `READ_STEPS` permission, the permissions rationale intent and the usage-link alias; minimum Android 8. Still to do: the Health Connect declaration in Play Console.
- The privacy policy must say steps are read from the health store, kept on the phone and not shared (`legal-counsel` to draft the wording).

## Testing

- Unit tests for the summary maths (average, best day, goal percentage, over-goal) with a fake source.
- Widget tests for the card and the screen in each state above, and for the goal sheet's limits.
- The iOS simulator has no step sensor; HealthKit data can be added by hand in the simulator's Health app, but real counting needs a phone. A device test is a manual step in the UAT checklist.
- A rule check: no calorie, point, badge or rank text on either screen.

## Build order (steps 1 to 3 are done; 4 is outside the code)

1. Domain models, `StepSource` interface and fake, summary maths and their tests.
2. `StepsCard` and `StepsScreen` on the fake, with every state, and tests.
3. The real source for iPhone and Android, platform settings, and a device check.
4. Privacy policy wording and store declarations (outside the code).
