# Design, UX writing and motion for a Flutter app

Read this when building or reviewing a screen, the theme, copy or animation. A screen is built only after its logic and tests pass.

This file covers what applies on both platforms. For a review against Apple's Human Interface Guidelines, with page lookups and a report format, read `apple-hig-review.md`.

## Contents

1. Stance
2. The brief
3. Tokens
4. Numbers to hold
5. Every state
6. The generic look, and its Flutter spellings
7. Words
8. Motion
9. Accessibility
10. Platform and size
11. Hardening
12. Critique
13. Technical audit
14. Polish
15. Checking the result

## 1. Stance

- The user's brief and the existing design system win over any taste expressed here.
- An app people operate every day is not a landing page. Clarity, consistency and platform convention beat expression. The brand lives in the colour scheme, one type choice, the feel of motion and the words.
- Know whether the job is refinement (keep the identity, fix what is off) or redesign (replace it). Do not split the difference.
- A missing design document does not mean a blank slate. Look at what the app already does before proposing anything.
- Restraint is the default: one accent, flat surfaces, few type sizes. Spend boldness once, on one moment that matters, not everywhere.
- Before adding something, try removing something.

## 2. The brief

For a new screen or flow, ask in at most two rounds of two or three questions, then write a brief and get a yes before any code.

- Round one: what is this for, who uses it and in what situation, what is the one thing they must do or understand here.
- Round two: real content ranges (shortest, longest, none, thousands), which states exist, what must not change.

The brief has seven short parts: job and audience, outcome, direction, scope, states and ranges, interaction intent, constraints.

For a larger visual direction, propose two or three options with their trade-offs and wait for a choice.

## 3. Tokens

Screens never contain raw colours, font sizes, radii or durations. They read tokens.

- **Colour roles** in `ColorScheme` and a `ThemeExtension` for the app's own roles: canvas and raised surface, primary and secondary text, action, focus, border, and success, warning, danger and info each with a fill and an on-fill colour.
- **Type roles** in `TextTheme`. Few sizes, and adjacent steps clearly different (a ratio of about 1.25 or more).
- **Spacing, radii, elevation, durations and curves** in a `ThemeExtension` or constants.
- Three layers keep this manageable: raw palette values, then semantic roles, then per-component choices. Screens touch only the last two.
- Dark mode is designed, not inverted: desaturated tones, checked on its own.
- Extract a shared component when the same thing appears three times. Before that, duplication is cheaper than the wrong abstraction.
- Fonts ship inside the app. No fetching fonts or images from third-party hosts at run time unless the plan and the privacy policy say so.

Record house rules by name in the design document so they can be cited in review.

## 4. Numbers to hold

| Thing | Value |
|---|---|
| Text contrast | at least 4.5 to 1; 3 to 1 for large text and for meaningful icons and lines |
| Touch target | at least 48 logical pixels, with 8 between neighbours. Extend the hit area beyond a small icon. |
| Spacing scale | a 4-point base: 4, 8, 12, 16, 24, 32, 48, 64 |
| Body text | 16 logical pixels as the base; nothing people must read below 12 |
| Line height | about 1.5 for body |
| Line length | 35 to 60 characters on a phone; cap it on tablets |
| Bottom navigation | 3 to 5 destinations, each with icon and label |
| Primary actions | one per screen |
| Choices shown at once | about 4 before grouping or disclosing progressively |
| Press feedback | visible within about 100 ms |
| Skeletons | for waits longer than about a second |
| Toasts | 3 to 5 seconds, never the only place an error appears |
| Disabled | visibly different from read-only |

Hierarchy comes from size, space and contrast before weight. Put more space above a heading than below it. Tight gaps inside a group and generous gaps between groups do more than borders and boxes.

## 5. Every state

Each screen designs all five: loading, empty, content, error, offline. The empty and error states are where an app feels cheap.

Empty is not one state. Distinguish first use, no results, filtered to nothing, not permitted, and failed to load. A first-use empty state says what will appear here, why it matters and how to start.

Also design: partial data, the very long name, the single item, the thousandth item, the pressed and disabled controls, and the form with an error in it.

## 6. The generic look, and its Flutter spellings

These are the marks of an interface nobody decided on. Each needs a reason to stay.

| Pattern | Usually appears in Flutter as |
|---|---|
| A card inside a card | nested `Card` or bordered `Container` |
| A coloured stripe down one side of a card | `Border(left: BorderSide(width: 3...))` |
| A glow | a `BoxShadow` with a colour and no offset |
| Decorative frosted glass | `BackdropFilter` that is not signalling a dismissed background |
| Gradient text | `ShaderMask` over a `Text` |
| A grid of identical icon, heading, text cards as the page structure | repeated tiles in a `GridView` |
| A tiny capitalised label above every heading | a small `Text` with wide letter spacing |
| Section numbers on things that are not a sequence | "01", "02", "03" |
| A big number with a small label as decoration | hero metrics with no decision attached |
| Bounce and overshoot | `Curves.elasticOut`, `Curves.bounceOut` |
| A pulsing dot with nothing live behind it | a looping `AnimationController` |
| Emoji used as icons | emoji in `Text` where an icon belongs |
| The same spacing value everywhere | one `EdgeInsets.all(16)` on every element |
| Purple gradients, or cyan on near-black, chosen by reflex | hard-coded gradient colours |
| A dialog where no interruption is needed | `showDialog` for information |
| Raw values in screens | `Color(0x...)`, `Colors.`, literal sizes outside the theme files |

A quick search for the right-hand column outside the theme and widget kit finds most drift.

## 7. Words

- Say each idea once. Each state needs the one fact that matters now, the next action, and only the context that changes the decision.
- Buttons are a verb and its object: "Join session", "Send code". Never "OK", "Yes", "Submit". One action keeps one name through the whole flow.
- Errors say what happened and what to do next. No internal codes. No blame. No jokes near money, privacy or loss.
- A destructive confirmation names the thing and the consequence. Prefer undo to a confirmation.
- Labels stay visible. A placeholder is not a label.
- Loading text names what is really happening. Never fake progress.
- Sentence case. Plain words. Short sentences. Follow the repo's voice rules where they exist.
- Nothing invented: no made-up reviews, counts, names or claims. Mark placeholder content as placeholder.
- Strings are whole sentences that can be translated, not fragments joined in code. Allow about a third more room for other languages.
- Avoid filler that marks text as machine-written: "seamless", "unlock", "elevate", "empower", "in today's world", and the "not X, but Y" construction used repeatedly.

## 8. Motion

Motion explains what just happened. It does not decorate. Write one sentence saying what the motion on this screen is for before adding any.

| Use | Duration |
|---|---|
| Press and toggle feedback | 100 to 150 ms |
| Routine transitions | 150 to 300 ms |
| Sheets, overlays, layout shifts | 300 to 500 ms |

- Exits are faster than entrances, roughly two thirds.
- Decelerating curves (`Curves.easeOutCubic` or similar). No overshoot. A spring is fine when it settles without bouncing.
- Move, scale and fade. Do not animate layout sizes inside lists.
- Small distances. One or two animated things per view. Stagger list items by 30 to 50 ms at most.
- Interruptible: a new tap never waits for an animation.
- Content is visible in its resting state. Nothing depends on an animation having played.
- Start with Flutter's implicit animations and page transitions. Add a package only when it earns its place.
- When the system asks for reduced motion (`MediaQuery.disableAnimationsOf`), use fewer and gentler movements, such as a crossfade. Feedback that confirms an action stays.
- Durations and curves are theme tokens, shared across the app.
- Light haptics on key actions, not on every tap.

## 9. Accessibility

- Every control has a name: `Semantics`, `tooltip`, or a visible label. Decorative images are excluded. Related text is merged so it reads as one thing.
- Reading order follows visual order.
- Layouts survive text scaled to 1.3 and 2.0. No fixed heights around text. Wrap before truncating.
- Colour is never the only signal. Pair it with an icon, text or shape.
- Every drag has a tap alternative. No action is reachable by gesture alone.
- Sign-in works with password managers, paste and autofill. Code fields accept a pasted code.
- Changed counts and results are announced.
- Focus is visible and never hidden behind a fixed bar.
- Test with VoiceOver and TalkBack, not only the checklist.

## 10. Platform and size

- Respect safe areas and the keyboard. Content is never trapped under a fixed bar.
- Keep the system back gesture working on both platforms. Never trap the user.
- Use each platform's idioms instead of transplanting one onto the other: navigation, sheets, pickers, switches.
- Restructure for larger screens rather than scaling up: a bottom bar becomes a rail, a list and its detail sit side by side. Decide by available width, not device model.
- Preserve state and scroll position when the user leaves and returns, and when the app is interrupted.
- The right keyboard type and autofill hints on every field.

## 11. Hardening

Try each before calling a screen finished, and say what evidence produced each result:

- Text: very long, empty, emoji, right-to-left.
- Lists: zero, one, thousands.
- Network: offline, slow, timed out, each kind of server refusal.
- Hands: double submit, back mid-request, a second finger, leaving and returning.
- Permission: denied, revoked later, not yet asked.
- Session: expired while the screen is open.

Input the user typed survives an error. A second submit while the first is running does nothing.

## 12. Critique

A design critique answers "is this good for the person using it". Do the judgement pass before looking at any tool output, so the evidence does not anchor it.

1. **Specificity.** Could another product ship this screen unchanged? If yes, say what would make it this product's.
2. **Ten usability heuristics, scored 0 to 4 each:** visibility of status; match to the real world; user control and freedom; consistency; error prevention; recognition over recall; flexibility; minimal design; error recovery; help. Most real screens land between 20 and 32 of 40. A 4 means excellent, not adequate.
3. **Mental load.** Check: a single focus, chunks of four or fewer, clear grouping, clear hierarchy, one decision at a time, few visible options, little to hold in memory, detail disclosed progressively. Four or more failures is a heavy screen.
4. **People.** Walk it as two or three of: the expert who wants speed, the first-timer who knows no jargon, someone using a screen reader or large text, someone trying to break it, someone on a phone with one hand and half their attention.
5. **Three to five priority issues**, each with a severity and a fix:
   - P0 blocks the task
   - P1 major: the person would contact support
   - P2 minor
   - P3 polish
6. Questions for the user come last.

## 13. Technical audit

Separate from critique: does the build meet the bar. Score five areas 0 to 4 and list findings with location, impact, the standard broken and the fix. Report only; fix in a later pass.

1. Accessibility
2. Performance
3. Theming (tokens used, both themes sound)
4. Platform conformance
5. Adaptivity (sizes, orientation, text scale)

Note patterns that repeat across screens as one systemic finding, not twenty.

## 14. Polish

In this order, because the top items matter most:

1. broken, blocked or misleading states
2. missing states
3. flow and hierarchy problems, and drift from the design system
4. visual and motion inconsistency
5. code tidy-up

Classify each drift before fixing it: a missing token, a one-off that should stay, a mismatch of concept, or a local defect. Finish by reading the diff and removing changes that were not needed.

## 15. Checking the result

Look at the running screen, not only the code.

- Capture it on a small and a large phone, in light and dark, at normal and largest text, with reduced motion on.
- Say whether the evidence came from a simulator or a real device.

**Fix every one of these:** content out of bounds, text overflow, overlapping text, contrast below the floor, text on a busy image with no scrim, colliding elements, a broken image, a missing key element.

**Fix these only when clearly bad:** uneven spacing between peers, alignment that drifts by a few pixels, dead space, competing accents, the most prominent element not being the most important one.

**Do not touch without asking:** brand tokens, structure, content. If a brand colour fails contrast everywhere, record it for the user rather than patching each use.

Leaving a small imperfection is better than oscillating between two fixes.
