# Type audit: text styles in the mobile app (Part A, steps 1 and 2)

9 Nov 2026. This was the audit before any change. The owner's decisions and the result are at the end. Scope is `lib/` (the phone app), including the shared widgets in `lib/core/widgets`. The admin web app and the theme package `packages/og_design` are left out.

## How it was found

A script read every Dart file in `lib/` and recorded each `OgText` call (the app's only type helper), any `.copyWith(...)` after it, every raw `TextStyle(`, and every `fontSize:` and `fontWeight:`. For each it records the file, the screen (the enclosing widget class), the line, the text it styles, and the effective size, weight and colour, then proposes a role. The shared widgets (headers, rows, buttons, tabs, chips, fields, avatars) were mapped by hand, because most screens get their text from them. The script's guesses for headings and numbers are marked in the Note column where a person should look.

- **Text styles found:** 1580, in 96 files.
- **Raw `fontSize:`, `fontWeight:` and `TextStyle(` outside a type helper:** 152, listed at the end.
- **Weights today:** Bold (700 and up) 5, Semibold (600) 881, Medium (500) 2, Regular (400) 692.
- **Size set by a variable:** 27, mostly shared widgets that take a size parameter.

## Before and after, by kind of text

| Kind of text | Before: size | Before: weight | After: role | After: size / weight / colour | Count |
| --- | --- | --- | --- | --- | --- |
| Numbers: prices, ratings, counts | 22 to 44 | 600 | **score** | 32 / 600 / primary | 31 |
| Large counters and timers (48 and up) | 54 to 96 | 600 | **score** | 32 / 600 / primary | 4 |
| Large headings and dialog titles (22 to 33) | 22 to 32 | 600 | **title** | 20 / 600 / primary | 85 |
| Hero headlines (34 and up) | 34 to 64 | 600 | **title** | 20 / 600 / primary | 16 |
| Screen and app bar titles | 34, some variable | 600 | **title** | 20 / 600 / primary | 6 |
| Card and section headings | 14 to 22, some variable | 600, 700 | **section** | 17 / 600 / primary | 261 |
| Emphasised text, weight dropped | 14 to 18, some variable | 600, 700 | **body** | 15 / 400 / primary | 292 |
| Main text | 14 to 21, some variable | 400 | **body** | 15 / 400 / primary | 73 |
| Row labels | 15 to 18, some variable | 400, 600 | **body** | 15 / 400 / primary | 8 |
| Error and status text | 14 | 400 | **body** | 15 / 400 / primary | 5 |
| Typed text in fields | 18 | 400 | **body** | 15 / 400 / primary | 4 |
| Orange accent text (prices, eyebrows), not links | 14 | 600 | **body** | 15 / 400 / primary | 2 |
| Grey text (14 to 17) | 14 to 17, some variable | 400, 500, 600 | **secondary** | 15 / 400 / secondary | 267 |
| Row values | 15 to 16 | 600 | **secondary** | 15 / 400 / secondary | 2 |
| Small grey text | 11 to 15 | 400, 500, 600, 700 | **caption** | 13 / 400 / secondary | 356 |
| Small text (13 and under), turns grey | 9 to 13 | 400, 600, 700 | **caption** | 13 / 400 / secondary | 118 |
| Orange accent text (prices, eyebrows), not links | 11 to 13 | 400, 600 | **caption** | 13 / 400 / secondary | 11 |
| Field labels | 14 to 15 | 600 | **caption** | 13 / 400 / secondary | 5 |
| Section labels and breadcrumbs | 13, some variable | 600 | **caption** | 13 / 400 / secondary | 3 |
| Count badges | variable | 600 | **caption** | 13 / 400 / secondary | 1 |
| Links | 13 to 17, some variable | 600 | **button** | 15 / 400 / per button | 10 |
| Buttons | 15 to 18, some variable | 600 | **button** | 15 / 400 / per button | 4 |
| Chips and tags | variable | 600 | **button** | 15 / 400 / per button | 3 |
| Tabs | 15, some variable | 600 | **button** | 15 / 400 / per button | 3 |
| Initials on avatars and logos | 40 to 92, some variable | 600 | **monogram** | no role fits | 10 |

| Role | Styles after |
| --- | --- |
| score | 35 |
| title | 107 |
| section | 261 |
| body | 384 |
| secondary | 269 |
| caption | 494 |
| button | 20 |
| monogram | 10 |

## Decisions needed before any edits

1. **Futura on iPhone has no Regular or Semibold.** iOS ships Futura in Medium (500) and Bold (700) only. Today "Regular" body text draws as Medium and every Semibold heading draws as Bold, which is most of why the app looks heavy. Under the new roles, score, title and section would still draw Bold on iPhone, against "no Bold anywhere". Options:
   - **Jost everywhere (recommended).** It is the free, near-identical Futura match already used on Android and the web, with a true Regular 400 and Semibold 600. This reverses Q250 for iPhone.
   - **Buy a Futura licence** (Futura PT Book 400 and Demi 600) and bundle it, so every platform gets the real weights.
   - **Keep system Futura** and draw score, title and section in Medium. Hierarchy then comes from size and colour only, and body text stays Medium.
2. **Buttons at 15 Regular fail contrast on orange.** White on the brand orange `#E8590C` is 3.6:1. It passes today only because 20px Semibold counts as large text. At 15 Regular a label needs 4.5:1. Options: fill buttons with the darker orange `#C94A00` (4.7:1), or keep button labels at 18 and up. Dark mode (charcoal on lime, 12.9:1) passes either way.
3. **There is no tertiary text colour.** The theme has primary (`#1C1F23`) and secondary (`#5A5F66`, 6.4:1 on white) only. Tertiary, for disabled text and placeholders, needs a value in both themes. Disabled text is exempt from contrast rules, but placeholders should stay readable.
4. **Text that fits no role:**
   - **Initials on avatars and logos** (10): they scale with the circle or square they sit in. Proposal: a `monogram` style in the theme extension, sized from the container.
   - **Large counters and timers** (4): the workout rest timer, the challenge countdown and the rep counter at 54 to 96. As score they would drop to 32. Proposal: a `counter` style in the extension, or accept 32.
   - **Hero headlines** (16): for example "Find a game. Join a Meet." (36), "You're in." (38), and the Academy, Venue and club heroes (44 to 50). As title they become 20. Proposal: a `display` style (28 / 600) in the extension, for at most one hero per screen, or accept 20.
   - **Orange accent text that is not a link** (13): prices like "From S$12", card eyebrows, "Week 3 of 10". Mapped to body or caption, keeping the orange. Confirm they should not use the link (button) role.
5. **Screen titles shrink from 34 to 20.** `OgHeading` (every onboarding and flow screen) and the onboarding name field use 34 to 36 today. That is what the title role asks for, but it is the biggest visible change.
6. **Card titles at 24 to 33** (club name on its page, event titles on cards, dialog titles) are mapped to title. Some may read better as section (17). They are marked "Large headings and dialog titles" above.
7. **Typed text in fields goes from 18 to 15**, and field labels become caption (13, grey).
8. **Rows swap emphasis.** Key-value rows show a grey label and a bold value today. Under the roles the label is body (primary) and the value is secondary (grey, Regular). Row titles in settings lists (`NavRow`, 17 Semibold) become body (15 Regular).
9. **Widget parameters that carry a font size** (for example `OgSelectField.fontSize`, `KitTag.fontSize`, `KitButton.size`, `Avatar.fontSize`) have to become role choices, or step 5's "no `fontSize:` outside the theme" cannot pass. That changes those widgets' constructors, not the layout.
10. **Design docs.** `docs/DESIGN_SYSTEM.md`, Q15 and Q250 describe the old scale (screen titles 34, buttons 20 bold). After approval I would update them and record the new roles as your decision.

## Every text style, by screen

"Before" is the helper, size, weight and colour class. "Text" is the string or expression the style is for.

### `lib/core/widgets/avatar.dart`

**Avatar**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 81 | `initials` | display (var size) / 600 / other | monogram | avatar initials: no role fits |

### `lib/core/widgets/cupertino_sheets.dart`

**top level**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 40 | `Cancel` | body 17 / 400 / secondary | secondary |  |
| 47 | `title` | body 17 / 600 / primary | section |  |
| 58 | `Done` | body 17 / 600 / link | button | link |
| 74 | `` | body 21 / 400 / primary | body |  |
| 75 | `` | body 21 / 400 / primary | body |  |

### `lib/core/widgets/og_buttons.dart`

**OgButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 68 | `label` | display (var size) / 600 / other | button |  |

**OgMethodButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 134 | `label` | display 18 / 600 / primary | button |  |

**OgTextLink**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 174 | `label` | body 15 / 600 / other | button | link |

### `lib/core/widgets/og_fields.dart`

**top level**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 25 | `label` | input 18 / 400 / secondary | body | typed text in fields; 18 → 15 |
| 34 | `label` | body 16 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 37 | `hint` | input 18 / 400 / secondary | body | typed text in fields; 18 → 15 |
| 54 | `` | body 14 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |

**OgInput**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 174 | `` | input 18 / 400 / primary | body | typed text in fields; 18 → 15 |

**OgSelectField**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 252 | `` | body (var size) / 600 / primary | body | size set by a variable: check; emphasis dropped (body is Regular); weight switches: bold ? FontWeight.w600 : FontWeight.w400 |
| 280 | `value` | body (var size) / 600 / secondary | secondary | size set by a variable: check; grey and bold: weight dropped; weight switches: bold ? FontWeight.w600 : FontWeight.w400 |

**OgCodeField**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 356 | `` | body 22 / 600 / primary | section |  |

### `lib/core/widgets/og_kit.dart`

**KitHeader**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 85 | `title` | display (var size) / 600 / primary | title | app bar title |
| 93 | `subtitle!` | body 13 / 400 / secondary | caption |  |

**KitBack**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 172 | `prev` | body 15 / 600 / other | button | back label |

**KitTrail**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 246 | `cr.title` | body 13 / 600 / link | caption | breadcrumb |
| 260 | `current` | body 13 / 600 / secondary | caption | breadcrumb |

**KitButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 528 | `label` | body (var size) / 600 / other | button |  |

**KitLink**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 590 | `label` | body (var size) / 600 / other | button | link |

**KitChip**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 660 | `label` | body (var size) / 600 / other | button | chip |

**KitTag**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 707 | `label` | body (var size) / 600 / primary | button | tag pill: chip role |

**KitCountBadge**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 738 | `$count` | body (var size) / 600 / on-fill | caption | count badge; keeps its colour |

**KitNote**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 781 | `` | body 14 / 400 / other | body | keeps its colour |

**KitSection**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 806 | `title` | heading (var size) / 600 / primary | section |  |

**KitTitle**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 832 | `title` | heading (var size) / 600 / primary | section |  |
| 836 | `lead!` | body 15 / 400 / secondary | secondary |  |

**KitCheckList**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 873 | `item` | body 15 / 400 / primary | body |  |

**KitKeyValue**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 927 | `label` | body 15 / 400 / secondary | body | row label (was grey) |
| 933 | `value` | body 15 / 600 / primary | secondary | row value (was bold) |

**KitChoiceRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1040 | `title` | body 15 / 600 / primary | body | row label |
| 1050 | `subtitle!` | body 13 / 400 / secondary | caption |  |
| 1060 | `tag!` | body 13 / 600 / secondary | caption |  |

**KitConfirmBox**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1115 | `label` | body 15 / 600 / primary | body |  |

**KitUnderlineTabs**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1178 | `labels[i]` | body 15 / 600 / secondary | button | tab |

**KitSegments**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1281 | `labels[i]` | body (var size) / 600 / secondary | button | segmented tab |

**SolidAvatar**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1367 | `initials` | body (var size) / 600 / other | monogram | avatar initials scale with the avatar: no role fits |

**ClubLogo**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1413 | `initials` | heading (var size) / 600 / other | monogram | logo initials scale with the logo: no role fits |

**KitNavTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1541 | `title` | body 16 / 600 / other | body | row label |
| 1551 | `subtitle!` | body 13 / 400 / secondary | caption |  |

**KitMuted**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1579 | `text` | body (var size) / 400 / secondary | secondary | size set by a variable: check |

**KitInput**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1619 | `label` | body 15 / 600 | caption | field label |
| 1643 | `${value.text.length}/$maxLength` | body 13 / 400 / secondary | caption |  |

**KitTextArea**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1685 | `text: label` | body 15 / 600 | caption | field label |
| 1690 | `(optional)` | body 15 / 500 / secondary | caption |  |

**KitField**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1766 | `` | body (var size) / 400 / primary | body | size set by a variable: check |
| 1770 | `hint` | body (var size) / 400 / secondary | secondary | size set by a variable: check |

**KitSearchField**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1842 | `` | body (var size) / 400 / primary | body | size set by a variable: check |
| 1846 | `hint` | body (var size) / 400 / secondary | secondary | size set by a variable: check |

**KitDoneBanner**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 2098 | `title` | heading 50 / 600 / on-fill | title | hero text 50 → 20; may want its own role |

**KitQty**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 2149 | `$value` | heading 18 / 600 | body | quantity |

### `lib/core/widgets/og_rows.dart`

**SectionLabel**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 26 | `text.toUpperCase()` | body (var size) / 600 / secondary | caption | section label |

**NavRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 127 | `title` | body 17 / 600 / primary | body | row label |
| 135 | `subtitle` | body 14 / 400 / secondary | secondary |  |

**SwitchRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 191 | `title` | body (var size) / 600 / primary | body | row label |
| 196 | `title` | display 18 / 600 / primary | body | row label |
| 200 | `subtitle` | body 14 / 400 / secondary | secondary |  |

**OgSearchField**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 264 | `` | body 16 / 400 / primary | body |  |
| 269 | `hint` | body 16 / 400 / secondary | secondary |  |

**PillTabs**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 330 | `labels[i]` | display (var size) / 600 / on-fill | button | tab |

**ListRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 386 | `title` | body 16 / 600 / primary | body | row label |
| 397 | `subtitle!` | body 14 / 400 / secondary | secondary |  |

**OgChip**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 460 | `label` | body (var size) / 600 / on-fill | button | chip |

**RadioRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 523 | `label` | body 16 / 400 / primary | body |  |

**KeyValueRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 551 | `label` | body 16 / 400 / secondary | body | row label (was grey) |
| 557 | `value` | body 16 / 600 / primary | secondary | row value (was bold) |

**OgTextArea**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 596 | `` | body 16 / 400 / primary | body |  |

**FollowButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 642 | `label` | display 15 / 600 / on-fill | button |  |

### `lib/core/widgets/og_screen.dart`

**OgFlowScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 76 | `lead` | body 15 / 400 / secondary | secondary |  |

**OgHeading**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 150 | `title` | h1 34 / 600 / primary | title | screen title 34 → 20 |
| 173 | `lead!` | lead 16 / 400 / secondary | secondary | intro paragraph |

**OgErrorText**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 235 | `message` | body 14 / 600 / status | body | keeps error colour |

### `lib/core/widgets/og_toast.dart`

**Toast**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 102 | `widget.message` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

### `lib/core/widgets/pay_sheet.dart`

**PaySheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 115 | `Confirm it’s you` | heading 30 / 600 | title |  |
| 120 | `Pay $_total to ${widget.payee}.\nUse Fac` | body 15 / 400 / other | body | keeps its colour |
| 151 | `widget.kicker.toUpperCase()` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 159 | `widget.title` | heading 28 / 600 | title |  |
| 163 | `widget.subtitle` | body 14 / 400 / secondary | secondary |  |
| 196 | `label` | body 15 / 400 / other | body | keeps its colour |
| 201 | `value` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 213 | `Total` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 216 | `_total` | heading 36 / 600 | score |  |
| 228 | `Pay with` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 255 | `n` | body 13 / 400 / other | caption |  |

### `lib/core/widgets/phone_field.dart`

**PhoneField**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 57 | `widget.country.dialCode` | input 18 / 600 / primary | body | typed text in fields; 18 → 15 |
| 190 | `country.name` | body 16 / 600 / primary | body | emphasis dropped (body is Regular); weight switches: selected ? FontWeight.w600 : FontWeight. |
| 199 | `country.dialCode` | body 16 / 400 / secondary | secondary |  |

### `lib/core/widgets/place_code.dart`

**PlaceCode**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 56 | `widget.title` | heading 24 / 600 | title |  |

### `lib/core/widgets/resend_timer.dart`

**ResendTimer**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 61 | `Send a new code in ${resendClock(_left)}` | body 15 / 400 / secondary | secondary |  |

### `lib/features/academy/presentation/academy_admin_screens.dart`

**AcademyClassEditScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 218 | `Level` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 236 | `Days` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 267 | `Length` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 334 | `Coach` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 357 | `Monthly and term fees are paid to the ac` | body 13 / 400 / secondary | caption |  |

**AcademyCoachesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 444 | `k.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 448 | `Head coach` | body 13 / 400 / secondary | caption |  |
| 464 | `Invited` | heading 20 / 600 | section |  |
| 468 | `$e · can join once they have an account` | body 14 / 400 / secondary | secondary |  |
| 476 | `${k.name} · hasn’t answered yet` | body 14 / 400 / secondary | secondary |  |
| 488 | `Add a coach` | heading 20 / 600 | section |  |
| 502 | `Coaches can take attendance, write notes` | body 13 / 400 / secondary | caption |  |
| 516 | `Remove ${k.name}?` | heading 22 / 600 | section |  |
| 520 | `Their classes are left without a coach u` | body 15 / 400 / secondary | secondary |  |
| 558 | `Billing and make-ups` | heading 22 / 600 | section |  |
| 569 | `Make-up classes each month` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 581 | `Parents pay the academy directly for now` | body 13 / 400 / secondary | caption |  |

### `lib/features/academy/presentation/academy_more_screens.dart`

**AcademySettingsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 104 | `a.name` | heading 22 / 600 | section |  |
| 120 | `${plural(a.coaches.length,` | body 13 / 400 / secondary | caption |  |

**AcademyMessagesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 300 | `Nothing matches. Check the spelling or c` | body 14 / 400 / secondary | secondary |  |
| 332 | `m.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 342 | `when(m.at)` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 350 | `m.last` | body 13 / 400 / secondary | caption |  |
| 367 | `To message a whole class at once, open t` | body 13 / 400 / secondary | caption |  |

**AcademyCloseScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 445 | `What happens` | heading 20 / 600 | section |  |

**ChangeClassScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 562 | `Sent to $n parents as an app notificatio` | body 15 / 400 / secondary | secondary |  |
| 600 | `MON` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 606 | `${at.day}` | heading 20 / 600 | section |  |
| 615 | `x.name` | heading 18 / 600 | section |  |
| 618 | `${Fmt.timeRange(at, x.endOf(at))}${x.cou` | body 13 / 400 / secondary | caption |  |
| 625 | `What changes?` | heading 20 / 600 | section |  |
| 662 | `Same time and court. The cover coach get` | body 13 / 400 / secondary | caption |  |
| 665 | `New date` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 694 | `Parents confirm if their child can come.` | body 13 / 400 / secondary | caption |  |
| 703 | `Notice to parents · ${x.enrolled} parent` | heading 20 / 600 | section |  |
| 713 | `Sent as an app notification. Parents who` | body 13 / 400 / secondary | caption |  |

**CoachPayScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 751 | `big` | heading 20 / 600 | section |  |
| 752 | `small` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 771 | `${p.month.toUpperCase()} PAY` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 780 | `cash(p.totalCents)` | heading 44 / 600 / other | score |  |
| 784 | `Paid on ${Fmt.day(p.paidOn)} to your pay` | body 14 / 400 / other | body | keeps its colour |
| 798 | `This month` | heading 20 / 600 | section |  |
| 807 | `Your rate is set by the academy owner. T` | body 13 / 400 / secondary | caption |  |
| 819 | `Past months` | heading 20 / 600 | section |  |

**CurriculumScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 864 | `Shared by all coaches` | body 14 / 400 / secondary | secondary |  |
| 881 | `Where each class is` | heading 20 / 600 | section |  |
| 902 | `p.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 906 | `p.sub` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 925 | `Level $_level · ${weeks?.length ?? 10} w` | heading 20 / 600 | section |  |
| 954 | `${w.week}` | body 13 / 600 / on-fill | caption | weight dropped |
| 968 | `w.topic` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 975 | `w.skills` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1001 | `No drills planned yet.` | body 13 / 400 / secondary | caption |  |
| 1014 | `d.name` | body 13 / 400 | caption | caption turns grey |
| 1019 | `${d.minutes} min` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 1030 | `w.version` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1052 | `When you edit a week, every coach teachi` | body 13 / 400 / secondary | caption |  |

**LessonPlanEditScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1139 | `Level ${widget.level}, Week ${w.week} · ` | heading 20 / 600 | section |  |
| 1144 | `Drills` | heading 20 / 600 | section |  |
| 1147 | `$total min` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |
| 1168 | `d.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 1213 | `The plan is longer than the 90-minute cl` | body 13 / 400 / status | caption |  |

**DrillPicker**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1245 | `Drill videos` | heading 22 / 600 | section |  |
| 1278 | `d.video` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |

**InviteStudentsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1372 | `Class` | heading 20 / 600 | section |  |
| 1395 | `Invite link for ${cls.name}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1399 | `${link.replaceFirst(` | body 13 / 400 / secondary | caption |  |
| 1435 | `Or send to a parent’s mobile` | heading 20 / 600 | section |  |
| 1460 | `Waiting for an answer` | heading 20 / 600 | section |  |

**AttendanceHistoryScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1502 | `$n` | heading 22 / 600 | score |  |
| 1503 | `label` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 1532 | `This term` | heading 20 / 600 | section |  |
| 1546 | `Fmt.day(l.at)` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1550 | `l.lesson` | body 13 / 400 / secondary | caption |  |
| 1575 | `Miss a class with 24 hours’ notice and y` | body 13 / 400 / secondary | caption |  |

**ParentNoteScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1653 | `s.name` | heading 20 / 600 | section |  |
| 1656 | `Today’s skills` | heading 20 / 600 | section |  |
| 1661 | `k.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1677 | `Add a line` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1705 | `${s.firstName}’s parent sees this in the` | body 13 / 400 / secondary | caption |  |

**FilmingConsentScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1811 | `${s.name}${s.age == null ?` | heading 20 / 600 | section |  |
| 1821 | `What you are agreeing to` | heading 20 / 600 | section |  |
| 1836 | `${i + 1}` | body 12 / 600 / on-fill | caption | was 12; caption is 13; weight dropped |
| 1850 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1854 | `text` | body 13 / 400 / secondary | caption |  |
| 1861 | `Your choice` | heading 20 / 600 | section |  |
| 1875 | `Change or withdraw any time in Settings ` | body 13 / 400 / secondary | caption |  |
| 1880 | `Signed by you, parent · ${Fmt.dayTimeCom` | body 13 / 600 / status | caption | weight dropped |

### `lib/features/academy/presentation/academy_screens.dart`

**AcademiesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 142 | `Academy` | heading 44 / 600 / on-fill | title | hero text 44 → 20; may want its own role |
| 225 | `Run an academy?` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 230 | `Business licence, NROC coaches` | body 13 / 400 / secondary | caption |  |
| 256 | `Academies near you` | heading 22 / 600 | section |  |
| 283 | `No academy matches` | heading 24 / 600 | title |  |
| 288 | `Check the spelling or try an area name.` | body 14 / 400 / secondary | secondary |  |

**AcademyRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 345 | `a.name` | body 17 / 600 | section |  |
| 361 | `sub` | body 13 / 400 / secondary | caption |  |
| 366 | `From S\$${money(from, decimals: false)} ` | body 13 / 600 / link | caption | orange accent text, not a link: keeps its colour |

**AcademyPageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 439 | `label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 441 | `sub` | body 13 / 400 / secondary | caption |  |
| 479 | `a.name` | heading 28 / 600 | title |  |
| 484 | `,` | body 13 / 400 / secondary | caption |  |
| 492 | `${a.rating!.toStringAsFixed(1)} (${a.rat` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 610 | `a.blurb` | body 15 / 400 | body |  |
| 615 | `Classes` | heading 22 / 600 | section |  |
| 636 | `x.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 656 | `·` | body 13 / 400 / secondary | caption |  |
| 670 | `classFee(a` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 679 | `Full, join the waitlist` | body 12 / 600 / link | caption | orange accent text, not a link: keeps its colour |
| 695 | `Coaches` | heading 22 / 600 | section |  |
| 721 | `co.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 728 | `${co.role}${co.nroc ?` | body 13 / 400 / secondary | caption |  |

**AcademyEnrolScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 853 | `For ${who?.name}, ${cls!.name}.` | body 15 / 400 / secondary | secondary |  |
| 880 | `Student` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 891 | `Class` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**PlayerChoices**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 933 | `Can’t load this right now. Check your co` | body 14 / 400 / secondary | secondary |  |
| 953 | `A parent needs to do this for you.` | body 14 / 400 / secondary | secondary |  |

**TrialClassScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1102 | `${s.className}, ${Fmt.dayTimeComma(s.at)` | heading 24 / 600 | title |  |
| 1107 | `${s.coach} is expecting ${who?.name}.` | body 15 / 400 / secondary | secondary |  |
| 1138 | `Who is it for?` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1152 | `Pick a class` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1159 | `No class is open in the next two weeks.` | body 14 / 400 / secondary | secondary |  |

### `lib/features/academy/presentation/assessment_screens.dart`

**AssessmentTemplatesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 64 | `No templates yet. Make one for what your` | body 14 / 400 / secondary | secondary |  |
| 70 | `t.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 73 | `${t.criteria.map((c) => c.$2).join(` | body 13 / 400 / secondary | caption |  |

**AssessStudentScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 302 | `Your head coach needs to make a template` | body 14 / 400 / secondary | secondary |  |
| 319 | `label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 341 | `Academy level (optional)` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**ScoreSparkline**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 394 | `line.label` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 397 | `$last / ${line.max}` | body 14 / 400 | body |  |
| 412 | `words` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**AssessmentHistoryScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 494 | `No assessments yet. They show up here on` | body 14 / 400 / secondary | secondary |  |
| 497 | `g.last.template` | heading 20 / 600 | section |  |
| 505 | `${Fmt.day(a.on)} · ${a.coach}` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 513 | `Academy level ${a.level}` | body 13 / 400 / secondary | caption |  |
| 516 | `a.note` | body 14 / 400 | body |  |

### `lib/features/academy/presentation/coach_screens.dart`

**AcademyTodayScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 80 | `a.name` | heading 24 / 600 | title |  |
| 87 | `·` | body 13 / 400 / secondary | caption |  |
| 91 | `${plural(a.students,` | body 13 / 400 / secondary | caption |  |
| 152 | `Needs you` | heading 22 / 600 | section |  |
| 180 | `al.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 185 | `al.body` | body 13 / 400 / other | caption |  |
| 221 | `Today's classes` | heading 22 / 600 | section |  |
| 224 | `Fmt.day(day)` | body 13 / 400 / secondary | caption |  |
| 232 | `No classes yet. Add classes from All cla` | body 14 / 400 / secondary | secondary |  |
| 253 | `Fmt.clock(x.hour` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 262 | `${x.name}${x.levelName.isEmpty ?` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 271 | `${x.enrolled} of ${plural(x.capacity,` | body 13 / 400 / secondary | caption |  |
| 276 | `Week ${x.week} of ${x.termWeeks} · ${x.l` | body 13 / 400 / link | caption | orange accent text, not a link: keeps its colour |

**AcademyClassesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 343 | `${plural(a.classes.length,` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |
| 349 | `e.key` | heading 20 / 600 | section |  |
| 365 | `Fmt.clock(x.hour` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 375 | `x.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 379 | `${x.coach}, ${plural(x.enrolled,` | body 13 / 400 / secondary | caption |  |

**ClassSessionScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 496 | `Each parent got one summary: attendance,` | body 15 / 400 / secondary | secondary |  |
| 535 | `WEEK ${x.week} OF ${x.termWeeks}` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 545 | `No lesson plan yet` | heading 26 / 600 / on-fill | title |  |
| 550 | `Same plan for all Level ${x.level} class` | body 13 / 400 / other | caption |  |
| 557 | `Students` | heading 22 / 600 | section |  |
| 560 | `$present of ${roster.length} present` | body 13 / 400 / secondary | caption |  |
| 567 | `Tap $focusName to update it for each stu` | body 13 / 400 / secondary | caption |  |
| 599 | `s.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 604 | `s.flag` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 643 | `Each parent gets one summary: attendance` | body 13 / 400 / secondary | caption |  |

**ClassRosterScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 723 | `s.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 730 | `Age ${s.age}` | body 13 / 400 / secondary | caption |  |
| 733 | `s.flag` | body 12 / 400 / link | caption | orange accent text, not a link: keeps its colour |
| 742 | `${s.attendancePct}%` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 746 | `attended` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**EnrolRequestsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 821 | `${r.student}, age ${r.age}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 830 | `Adult` | body 13 / 400 / secondary | caption |  |
| 841 | `“${r.note}”` | body 14 / 400 / other | body | keeps its colour |
| 877 | `Accepted. The first invoice was sent.` | body 14 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |

### `lib/features/academy/presentation/create_academy_screens.dart`

**Header**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 67 | `text` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**NewAcademyScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 109 | `Add ${gaps.join(` | body 13 / 400 / secondary | caption |  |
| 162 | `v` | body 15 / 400 | body |  |

**NewAcademyLevelsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 233 | `One sport per academy. Add another sport` | body 13 / 400 / secondary | caption |  |
| 239 | `Every coach teaches from the same plan. ` | body 13 / 400 / secondary | caption |  |
| 263 | `name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 265 | `meta` | body 13 / 400 / secondary | caption |  |

**NewAcademyPoliciesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 319 | `Platform fee: 10%, minimum S\$2 per paym` | body 13 / 400 / secondary | caption |  |
| 328 | `Make-ups a month` | body 15 / 400 | body |  |
| 331 | `For classes missed with notice` | body 13 / 400 / secondary | caption |  |
| 349 | `${d.makeups}` | heading 22 / 600 | score |  |

**NewAcademyVerifyScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 417 | `${i + 1}` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 427 | `_docs[i].$2` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 431 | `_docs[i].$3` | body 13 / 400 / secondary | caption |  |

**NewAcademyCoachesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 511 | `e` | body 15 / 400 | body |  |
| 514 | `Coach · invite on create` | body 13 / 400 / secondary | caption |  |

**Role**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 569 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 570 | `body` | body 13 / 400 / secondary | caption |  |

### `lib/features/academy/presentation/lesson_screens.dart`

**top level**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 127 | `text` | body 14 / 400 / secondary | secondary |  |

**OneToOneScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 200 | `Who is it for?` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 214 | `Pick a time` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**LessonDetailScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 548 | `Cancel by ${Fmt.dayTimeComma(b.freeCance` | body 13 / 400 / secondary | caption |  |

**LessonSlotsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 648 | `Fmt.dayTimeComma(s.startsAt)` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 656 | `${Money(s.priceCents)}` | body 13 / 400 / secondary | caption |  |

### `lib/features/academy/presentation/parent_screens.dart`

**StudentHome**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 147 | `s.name` | body 17 / 600 | section |  |
| 159 | `CLASS MOVED · SENT BY ${cls.coach.toUppe` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 169 | `s.notice!` | body 15 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 179 | `Can ${s.firstName} make it?` | body 14 / 400 / other | body | keeps its colour |
| 209 | `Got it. ${cls.coach} knows ${s.firstName` | body 14 / 400 / other | body | keeps its colour |
| 227 | `Next class` | body 13 / 600 / other | caption | weight dropped |
| 250 | `${Fmt.day(next)}, ${Fmt.timeRange(next, ` | heading 22 / 600 / on-fill | section |  |
| 259 | `·` | body 13 / 400 / other | caption |  |
| 264 | `WEEK ${cls.week}` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 273 | `${cls.lesson}. Bring a water bottle and ` | body 14 / 400 / on-fill | body | keeps its colour |
| 289 | `${s.makeupCredits} make-up ${s.makeupCre` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 294 | `Use by ${Fmt.day(s.creditUseBy!)} · book` | body 13 / 400 / secondary | caption |  |
| 329 | `From ${note.coach}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 333 | `After ${Fmt.day(note.at)} · ${note.lesso` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 369 | `note.text` | body 14 / 400 | body |  |

**StudentClassScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 444 | `big` | heading 24 / 600 | title |  |
| 448 | `small` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 488 | `This term` | heading 22 / 600 | section |  |
| 502 | `${w.week}` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |
| 512 | `w.title` | body 15 / 600 | body | emphasis dropped (body is Regular); weight switches: w.week == cls.week ? FontWeight.w600 : F |

**StudentFeesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 629 | `${due.title} for ${s.firstName}, due ${F` | body 14 / 400 / secondary | secondary |  |
| 631 | `S\$${money(due.totalCents)}` | heading 44 / 600 | score |  |
| 664 | `Past invoices` | heading 22 / 600 | section |  |
| 667 | `None yet.` | body 14 / 400 / secondary | secondary |  |

**BookMakeupScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 736 | `${s.firstName} joins ${sl.className} on ` | body 15 / 400 / secondary | secondary |  |
| 760 | `${s.makeupCredits} ${s.makeupCredits == ` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |
| 768 | `Level ${cls.level} classes with space` | heading 22 / 600 | section |  |
| 797 | `_dow(sl.at)` | body 11 / 600 / link | caption | orange accent text, not a link: keeps its colour |
| 803 | `${sl.at.day}` | heading 26 / 600 | score |  |
| 814 | `${Fmt.time(sl.at)} · ${sl.className}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 818 | `${sl.coach} · ${sl.lesson}` | body 13 / 400 / secondary | caption |  |

**StudentProgressScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 878 | `label` | body 11 / 600 / secondary | caption | was 11; caption is 13; grey and bold: weight dropped |
| 885 | `big` | heading 24 / 600 | title |  |
| 886 | `small` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 934 | `s.name` | heading 24 / 600 | title |  |
| 941 | `Age ${s.age}` | body 13 / 400 / secondary | caption |  |
| 959 | `Level ${cls.level}${cls.levelName.isEmpt` | body 13 / 400 / other | caption |  |
| 963 | `${s.skillsGot} of ${s.skills.length} ski` | heading 30 / 600 / on-fill | title |  |
| 982 | `Ready for Level ${cls.level + 1}` | body 13 / 400 / on-fill | caption |  |
| 1006 | `g.key` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1021 | `k.name` | body 15 / 400 | body |  |
| 1025 | `k.week` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1046 | `Coach notes` | heading 22 / 600 | section |  |
| 1061 | `${n.coach} · ${Fmt.day(n.at)}` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 1064 | `n.text` | body 14 / 400 | body |  |

### `lib/features/academy/presentation/verification_screens.dart`

**CoachPageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 448 | `p.bio` | body 15 / 400 / secondary | secondary |  |

### `lib/features/analysis/presentation/analysis_screens.dart`

**MyClipsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 109 | `Film a singles game from a tripod. You g` | body 16 / 400 / secondary | secondary |  |

**ChildClipsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 170 | `No clips yet.` | body 16 / 400 / secondary | secondary |  |

**AddClipScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 360 | `Only you can see this. We never show the` | body 14 / 400 / secondary | secondary |  |

**Plain**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 500 | `title` | body 20 / 700 / primary | section | BOLD |
| 502 | `body` | body 16 / 400 / secondary | secondary |  |

**CourtScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 690 | `Drag each dot onto a corner of the court` | body 16 / 400 / secondary | secondary |  |
| 733 | `We measure only the player on that side,` | body 14 / 400 / secondary | secondary |  |

**ReportScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 951 | `_keptLine(clip)` | body 14 / 400 / secondary | secondary |  |

### `lib/features/auth/presentation/log_in_account_screen.dart`

**LogInAccountScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 164 | `or` | body 14 / 400 / secondary | secondary |  |

### `lib/features/auth/presentation/log_in_screen.dart`

**LegalLine**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 93 | `Use another profile` | body 13 / 600 / link | button | link |
| 115 | `.` | body 13 / 400 / secondary | caption |  |

### `lib/features/auth/presentation/saved_accounts.dart`

**AccountTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 81 | `account.displayName` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |
| 90 | `account.maskedIdentifier` | body 13 / 400 / secondary | caption |  |

### `lib/features/auth/presentation/splash_screen.dart`

**SplashScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 83 | `GO` | display 48 / 600 / on-fill | monogram | initials or logo letters at 48: no role fits |

### `lib/features/auth/presentation/welcome_screen.dart`

**WelcomeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 49 | `Find a game.\nJoin a Meet.` | display 36 / 600 / primary | title | hero text 36 → 20; may want its own role |
| 58 | `Play with people near you, keep your Pas` | lead 16 / 400 / secondary | secondary | intro paragraph |

### `lib/features/clubs/presentation/club_admin_screens.dart`

**WithClub**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 78 | `count` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |

**ClubSettingsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 103 | `Settings` | heading 20 / 600 | section |  |
| 142 | `User management` | heading 20 / 600 | section |  |

**ClubMembersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 293 | `Nobody matches. Check the spelling or cl` | body 14 / 400 / secondary | secondary |  |
| 314 | `k.toUpperCase()` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 324 | `${groups[k]!.length}` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 354 | `m.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 363 | `${m.band!.code} ${m.rating!.toStringAsFi` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |

**ClubMemberScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 498 | `big` | heading 22 / 600 | section |  |
| 499 | `small` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 520 | `m.player.displayName` | heading 24 / 600 | title |  |
| 527 | `${m.band!.code} ${m.rating!.toStringAsFi` | body 14 / 400 / secondary | secondary |  |
| 544 | `Role` | heading 20 / 600 | section |  |
| 567 | `Saved` | body 13 / 600 / status | caption | weight dropped |
| 603 | `Role changes save right away and are wri` | body 13 / 400 / secondary | caption |  |

**Confirm**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 628 | `title` | heading 24 / 600 | title |  |
| 632 | `body` | body 15 / 400 / secondary | secondary |  |

**BanSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 667 | `Ban ${widget.name}?` | heading 24 / 600 | title |  |
| 672 | `They are removed, refunded for upcoming ` | body 15 / 400 / secondary | secondary |  |
| 677 | `Reason, shown to other Admins` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**JoinRequestsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 758 | `No one is waiting` | heading 20 / 600 | section |  |
| 763 | `New requests show here. Members are told` | body 14 / 400 / secondary | secondary |  |
| 792 | `r.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 802 | `Rating ${r.rating!.toStringAsFixed(1)}` | body 13 / 400 / secondary | caption |  |
| 833 | `“${r.message}”` | body 14 / 400 | body |  |

**AuditLogScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 922 | `Nothing here yet.` | body 14 / 400 / secondary | secondary |  |
| 947 | `${e.action}` | body 15 / 400 | body |  |
| 952 | `e.detail` | body 13 / 400 / secondary | caption |  |
| 956 | `${e.category.label} · ${Fmt.dayTimeComma` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**ClubBansScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1022 | `Nobody is banned.` | body 14 / 400 / secondary | secondary |  |
| 1050 | `b.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1057 | `Banned by ${b.bannedBy} · ${Fmt.day(b.at` | body 13 / 400 / secondary | caption |  |
| 1080 | `Unbanned. They can ask to join again.` | body 13 / 400 / status | caption |  |
| 1086 | `Reason: ${b.reason}` | body 13 / 400 / secondary | caption |  |

**ClubInviteScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1181 | `Invite link` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1186 | `https://` | body 14 / 400 / secondary | secondary |  |
| 1222 | `People you play with` | heading 20 / 600 | section |  |
| 1232 | `Nobody matches. Check the spelling or cl` | body 14 / 400 / secondary | secondary |  |

**ClubTransferScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1360 | `After they accept, you become an Admin. ` | body 13 / 400 / secondary | caption |  |

**ClubLeaveScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1432 | `You keep` | heading 20 / 600 | section |  |
| 1438 | `You lose` | heading 20 / 600 | section |  |
| 1465 | `You are ${club.myRoleName} here. Your ro` | body 14 / 400 / secondary | secondary |  |

**ClubDeleteScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1558 | `What is removed` | heading 20 / 600 | section |  |

### `lib/features/clubs/presentation/club_info_screens.dart`

**ClubAboutScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 116 | `club.name` | display 20 / 600 / primary | section |  |
| 125 | `·` | body 14 / 400 / secondary | secondary |  |
| 151 | `The organizers have not written about th` | body 15 / 400 / other | body | keeps its colour |
| 163 | `No club rules yet.` | body 15 / 400 / secondary | secondary |  |
| 177 | `${i + 1}.` | body 15 / 400 / other | body | keeps its colour |
| 187 | `club.rules[i]` | body 15 / 400 / other | body | keeps its colour |

**Panel**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 234 | `title!` | display 16 / 600 / primary | section |  |

**Details**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 269 | `e.$1` | body 13 / 400 / secondary | caption |  |
| 271 | `e.$2` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**Rating**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 311 | `Rate ${club.name}` | heading 22 / 600 | section |  |

**RatingPanel**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 405 | `club.rating!.toStringAsFixed(1)` | display 40 / 600 / primary | score |  |
| 432 | `${club.ratingCount} Meet reviews · last ` | body 14 / 400 / secondary | secondary |  |
| 448 | `$star★` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 471 | `${club.ratingSpread[5 - star]}` | body 13 / 400 / secondary | caption |  |
| 480 | `Only players who checked in to a Meet ca` | body 14 / 400 / secondary | secondary |  |

**Board**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 624 | `e.player.displayName` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 627 | `e.score` | display 16 / 600 / primary | section |  |
| 641 | `${i + 1}` | display 22 / 600 / other | score |  |
| 662 | `title` | display 17 / 600 / primary | section |  |
| 664 | `Rating` | body 13 / 400 / secondary | caption |  |
| 696 | `${i + 1}` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 712 | `rows[i].player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 717 | `rows[i].sub` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 727 | `rows[i].score` | display 17 / 600 / primary | section |  |
| 731 | `move(rows[i].move).$1` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 749 | `Only confirmed matches count, with at le` | body 13 / 400 / secondary | caption |  |

**MeBar**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 782 | `–` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 799 | `You` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 808 | `note` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 813 | `me.score` | display 18 / 600 / on-fill | section |  |

### `lib/features/clubs/presentation/club_overview_screen.dart`

**ClubOverviewScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 187 | `Club type` | heading 20 / 600 | section |  |
| 208 | `Changes are saved when you tap Save.` | body 13 / 400 / secondary | caption |  |
| 224 | `Default play rules` | heading 20 / 600 | section |  |
| 228 | `Added to every new session of that type.` | body 13 / 400 / secondary | caption |  |
| 241 | `Sports` | heading 20 / 600 | section |  |
| 244 | `${d.sports.length} of 5` | body 13 / 400 / secondary | caption |  |
| 269 | `Skill level range` | heading 20 / 600 | section |  |
| 282 | `s.sport.label` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 318 | `New sessions start with these ranges. Th` | body 13 / 400 / secondary | caption |  |
| 334 | `Only the owner sees this tab.` | body 13 / 400 / secondary | caption |  |
| 354 | `You` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 360 | `Owner` | body 13 / 400 / secondary | caption |  |

### `lib/features/clubs/presentation/club_page_screen.dart`

**MemberClubPage**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 251 | `Play sessions` | heading 26 / 600 / primary | title |  |
| 257 | `${shown.length} in ${_sport?.label ??` | body 13 / 400 / secondary | caption |  |
| 364 | `Play` | body 15 / 600 / primary | body | emphasis dropped (body is Regular) |
| 372 | `Ranks` | body 15 / 600 / secondary | secondary | grey and bold: weight dropped |
| 383 | `Chat` | body 15 / 600 / secondary | secondary | grey and bold: weight dropped |
| 468 | `s.range.label` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |

**ClubCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 556 | `label` | body 15 / 600 / primary | body | emphasis dropped (body is Regular) |
| 600 | `club.name` | heading 28 / 600 / primary | title |  |
| 608 | `,` | body 13 / 400 / secondary | caption |  |
| 616 | `${club.rating!.toStringAsFixed(1)} (${cl` | body 13 / 600 / primary | caption | caption turns grey; weight dropped |

**PublicClubPage**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 759 | `club.initials` | heading 52 / 600 / other | monogram | initials or logo letters at 52: no role fits |
| 769 | `club.name` | heading 32 / 600 / primary | title |  |
| 773 | `${club.sportLabels} · ${club.area} · ${c` | body 13 / 400 / secondary | caption |  |
| 795 | `club.description` | body 15 / 400 | body |  |
| 818 | `s.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 826 | `${Fmt.dayTimeComma(s.startsAt)} · ${band` | body 13 / 400 / secondary | caption |  |
| 833 | `Free` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 873 | `m.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 884 | `${m.band!.code} ${m.rating!.toStringAsFi` | body 13 / 400 / secondary | caption |  |

**PrivateClubPage**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1000 | `Request sent` | display 19 / 600 / primary | section |  |
| 1006 | `You'll get a notification when an admin ` | body 15 / 400 / secondary | secondary |  |
| 1030 | `An owner or admin reviews each request.` | body 13 / 400 / secondary | caption |  |
| 1046 | `Cancel request` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 1145 | `club.name` | display 22 / 600 / primary | title |  |
| 1163 | `${club.primarySport?.label ??` | body 14 / 400 / secondary | secondary |  |
| 1189 | `club.visibility.label` | body 12 / 600 / on-fill | caption | was 12; caption is 13; weight dropped |
| 1219 | `${club.memberCount} members` | body 15 / 600 | body | emphasis dropped (body is Regular) |

### `lib/features/clubs/presentation/club_role_screens.dart`

**MemberPicker**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 115 | `Nobody matches.` | body 14 / 400 / secondary | secondary |  |

**ManageRolesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 205 | `r.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 212 | `All permissions · can’t be changed` | body 13 / 400 / secondary | caption |  |
| 249 | `${r.memberCount}` | body 13 / 400 / secondary | caption |  |
| 286 | `Everyone` | heading 22 / 600 | section |  |
| 311 | `Roles – ${list.length}` | heading 20 / 600 | section |  |
| 336 | `The Owner role can’t be changed. Members` | body 13 / 400 / secondary | caption |  |

**CreateRoleScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 481 | `Role colour` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 488 | `Members show the colour of their highest` | body 13 / 400 / secondary | caption |  |
| 510 | `_level.title` | heading 22 / 600 | section |  |
| 514 | `card.$1` | body 14 / 400 / other | body | keeps its colour |
| 520 | `card.$2` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 527 | `card.$4` | body 13 / 400 / other | caption |  |

**RoleEditScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 598 | `Role` | heading 20 / 600 | section |  |
| 611 | `Role colour · ${_colourName(role.color)}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 654 | `Changes save right away and are written ` | body 13 / 400 / secondary | caption |  |

**RolePermissionsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 751 | `Start from a preset` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 768 | `Everyone can already join Meets, invite ` | body 13 / 400 / secondary | caption |  |
| 774 | `title` | heading 20 / 600 | section |  |

**RoleMembersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 862 | `Nobody has this role yet.` | body 14 / 400 / secondary | secondary |  |
| 888 | `m.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 892 | `m.player.handle` | body 13 / 400 / secondary | caption |  |

**AddMembersSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 943 | `Add to ${widget.roleName}` | heading 22 / 600 | section |  |
| 951 | `Select up to 30 · ${_picked.length} sele` | body 13 / 400 / secondary | caption |  |

**RoleDeleteScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1040 | `What happens` | heading 20 / 600 | section |  |
| 1051 | `Meets they already created stay as they ` | body 14 / 400 / secondary | secondary |  |

### `lib/features/clubs/presentation/club_widgets.dart`

**BandTag**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 116 | `label` | body (var size) / 600 / other | body | size set by a variable: check; emphasis dropped (body is Regular); keeps its colour |

**FilterSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 176 | `Filters` | heading 26 / 600 / primary | title |  |
| 201 | `g.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |

### `lib/features/clubs/presentation/clubs_home_screen.dart`

**ClubsHomeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 180 | `Picked for your skill level range` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 236 | `Group` | heading 30 / 600 / on-fill | title |  |
| 255 | `Start a club or a team` | heading 32 / 600 / on-fill | title |  |
| 260 | `Bring your regulars together` | body 13 / 600 / on-fill | caption | weight dropped |
| 277 | `Create` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 319 | `` | body 16 / 400 / primary | body |  |
| 323 | `Search clubs and teams` | body 16 / 400 / secondary | secondary |  |
| 409 | `No club or team matches` | heading 24 / 600 / primary | title |  |
| 417 | `Check the spelling or try an area name.` | body 14 / 400 / secondary | secondary |  |

**ClubRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 462 | `club.name` | body 17 / 600 / primary | section |  |
| 482 | `${club.memberCount} members, ${club.area` | body 13 / 400 / secondary | caption |  |
| 488 | `item.note` | body 13 / 600 / link | caption | orange accent text, not a link: keeps its colour |

**TeamRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 533 | `team.name` | body 17 / 600 / primary | section |  |
| 540 | `item.meta` | body 13 / 400 / secondary | caption |  |
| 545 | `item.note` | body 13 / 600 / link | caption | orange accent text, not a link: keeps its colour |

### `lib/features/clubs/presentation/create_group_screens.dart`

**Group**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 88 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 102 | `missing` | body 13 / 400 / secondary | caption |  |

**CreateGroupTypeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 156 | `title` | heading 28 / 600 | title |  |
| 157 | `sub` | body 14 / 400 / secondary | secondary |  |
| 177 | `p` | body 14 / 400 | body |  |
| 189 | `What are you starting?` | heading 30 / 600 | title |  |
| 223 | `You can run both. Meets, tournaments and` | body 13 / 400 / secondary | caption |  |

**NewClubScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 301 | `` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 305 | `Area: ${d.area}` | body 13 / 400 / secondary | caption |  |
| 320 | `Players nearby find your club by area, a` | body 13 / 400 / secondary | caption |  |
| 380 | `Request to join. Private clubs always ne` | body 14 / 400 / other | body | keeps its colour |

**NewClubSportsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 419 | `${d.sports.length}/3 selected` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 452 | `Each sport gets its own ratings and lead` | body 13 / 400 / secondary | caption |  |

**SportCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 531 | `sport.label` | body 16 / 600 | body | emphasis dropped (body is Regular) |

**NewClubLevelsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 585 | `s.label` | body 17 / 600 | section |  |
| 635 | `New Meets start with this range. Organiz` | body 13 / 400 / secondary | caption |  |

**NewClubInviteScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 709 | `Players you've played with` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 712 | `$n selected` | body 13 / 400 / secondary | caption |  |
| 725 | `No one yet. Share your invite link from ` | body 14 / 400 / secondary | secondary |  |
| 747 | `After you create the club, share its inv` | body 13 / 400 / secondary | caption |  |

**PersonRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 797 | `p.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 799 | `meta` | body 13 / 400 / secondary | caption |  |

**NewTeamScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 859 | `Optional. Split the team by age group. E` | body 13 / 400 / secondary | caption |  |
| 870 | `name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 872 | `rule` | body 13 / 400 / secondary | caption |  |

**NewTeamMembersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1000 | `Staff` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1004 | `You: head coach · team owner. Add coache` | body 14 / 400 / secondary | secondary |  |
| 1011 | `Players` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1014 | `$n selected` | body 13 / 400 / secondary | caption |  |
| 1025 | `Nobody matches. Check the spelling or cl` | body 14 / 400 / secondary | secondary |  |
| 1046 | `Players get an invite and join once they` | body 13 / 400 / secondary | caption |  |

### `lib/features/clubs/presentation/group_chat_screens.dart`

**GroupChatScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 110 | `Share a Meet` | heading 26 / 600 | title |  |
| 211 | `Club chat` | display 17 / 600 / primary | section |  |
| 216 | `${club.memberCount} members` | body 13 / 400 / secondary | caption |  |
| 258 | `Team chat` | display 17 / 600 / primary | section |  |
| 262 | `Team chat · $players players, $staff sta` | body 13 / 400 / secondary | caption |  |
| 312 | `` | body 15 / 400 / primary | body |  |
| 316 | `Message ${name ??` | body 15 / 400 / secondary | secondary |  |

**Pinned**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 365 | `This chat is only for the team. Staff ca` | body 13 / 400 / other | caption |  |
| 372 | `Pinned:` | body 13 / 600 / primary | caption | caption turns grey; weight dropped |
| 383 | `Your organizer marks attendance at each ` | body 13 / 400 / other | caption |  |

**Thread**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 423 | `day` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 447 | `m.body` | body 13 / 400 / other | caption |  |

**Theirs**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 495 | `m.sender.displayName` | body 14 / 600 / primary | body | emphasis dropped (body is Regular) |
| 517 | `m.roleName!` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 528 | `_clock(m.at)` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 549 | `Removed by an organizer` | body 14 / 400 / secondary | secondary |  |
| 560 | `m.body` | body 15 / 400 | body |  |

**Mine**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 610 | `Removed by an organizer` | body 14 / 400 / secondary | secondary |  |
| 633 | `m.body` | body 15 / 400 / on-fill | body | keeps its colour |
| 639 | `_clock(m.at)` | body 12 / 400 / other | caption | was 12; caption is 13 |

**MeetBubble**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 707 | `dows[meet.startsAt.weekday - 1]` | body 10 / 600 / other | caption | was 10; caption is 13; weight dropped |
| 715 | `${meet.startsAt.day}` | display 18 / 600 / on-fill | section |  |
| 731 | `meet.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 736 | `meet.detail` | body 13 / 400 / secondary | caption |  |

**LineupBubble**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 801 | `Lineup · vs ${fixture.opponent}` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 809 | `${Fmt.day(fixture.startsAt)} · $singles ` | body 13 / 400 / secondary | caption |  |
| 814 | `View lineup` | body 14 / 600 / link | button | link |

**ChatModerationScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 887 | `m.sender.displayName` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 896 | `_clock(m.at)` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 927 | `` | body 14 / 400 / secondary | secondary |  |
| 931 | `` | body 15 / 400 | body |  |

**AnnouncementCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1070 | `${a.author}, ${a.authorRole}` | body 15 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 1081 | `when` | body 13 / 400 / secondary | caption |  |
| 1087 | `a.title` | body 17 / 600 / other | section |  |
| 1097 | `a.body` | body 15 / 400 / other | body | keeps its colour |

**ReportContentScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1447 | `eyebrow.toUpperCase()` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 1455 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1461 | `sub` | body 13 / 400 / secondary | caption |  |

### `lib/features/clubs/presentation/group_rank_screen.dart`

**GroupRankScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 25 | `Ranked on games with 6 or more players c` | lead 16 / 400 / secondary | secondary | intro paragraph |
| 44 | `No groups are ranked yet.` | lead 16 / 400 / secondary | secondary | intro paragraph |

### `lib/features/clubs/presentation/team_screens.dart`

**TeamPageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 146 | `team.name` | heading 24 / 600 | title |  |
| 150 | `Represents ${team.represents}` | body 14 / 400 / secondary | secondary |  |
| 169 | `${team.playerCount} players · ${team.res` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 176 | `Picks players from ${team.linkedClubs.le` | body 13 / 400 / secondary | caption |  |
| 214 | `NEXT FIXTURE` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 225 | `Lineup locks ${Fmt.dayTimeComma(fixture.` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 235 | `${fixture.competition.isEmpty ?` | heading 22 / 600 / other | section |  |
| 239 | `${Fmt.dayTimeComma(fixture.startsAt)}${f` | body 14 / 400 / other | body | keeps its colour |
| 245 | `You're in · $myLine` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 256 | `Are you available?` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 300 | `You said: ${fixture.myAvailability.label` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 334 | `Schedule` | heading 20 / 600 | section |  |
| 370 | `MON` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 378 | `${s.startsAt.day}` | heading 18 / 600 | section |  |
| 390 | `s.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 397 | `${Fmt.time(s.startsAt)}${s.venue.isEmpty` | body 13 / 400 / secondary | caption |  |
| 415 | `Results` | heading 20 / 600 | section |  |
| 438 | `vs ${r.opponent}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 445 | `·` | body 13 / 400 / secondary | caption |  |
| 450 | `r.score` | heading 18 / 600 | section |  |

**TeamSettingsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 491 | `team.name` | heading 20 / 600 | section |  |
| 494 | `${team.sport.label} · ${team.playerCount` | body 13 / 400 / secondary | caption |  |

**TeamOverviewScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 663 | `Sub-teams` | heading 20 / 600 | section |  |
| 684 | `Linked clubs` | heading 20 / 600 | section |  |
| 701 | `club.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 705 | `You can add players from this club` | body 13 / 400 / secondary | caption |  |

**TeamRosterScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 778 | `m.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 793 | `sub` | body 13 / 400 / secondary | caption |  |
| 846 | `vs ${fixture.opponent} · ${Fmt.day(fixtu` | heading 18 / 600 | section |  |
| 851 | `Locks ${Fmt.dayTimeComma(fixture.lineupL` | body 13 / 400 / secondary | caption |  |
| 883 | `s.label.toUpperCase()` | body 11 / 600 / secondary | caption | was 11; caption is 13; grey and bold: weight dropped |
| 898 | `Open` | body 15 / 600 / secondary | secondary | grey and bold: weight dropped |
| 912 | `Reserves` | heading 18 / 600 | section |  |
| 930 | `${players.length} players${fixture == nu` | body 14 / 600 | body | emphasis dropped (body is Regular) |

**TeamAddPlayersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1058 | `Send this link to players who are not in` | body 14 / 400 / secondary | secondary |  |
| 1068 | `https://` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1109 | `Anyone with the link sends a request. Yo` | body 13 / 400 / secondary | caption |  |
| 1118 | `Players from linked clubs. They get a re` | body 13 / 400 / secondary | caption |  |
| 1125 | `Nothing matches. Check the spelling or c` | body 14 / 400 / secondary | secondary |  |

**TeamFixtureScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1216 | `f.competition.toUpperCase()` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 1225 | `${f.teamName}\nvs ${f.opponent}` | heading 26 / 600 | title |  |
| 1229 | `${Fmt.dayTimeComma(f.startsAt)}${f.venue` | body 14 / 400 / secondary | secondary |  |
| 1231 | `Can you play?` | heading 20 / 600 | section |  |
| 1246 | `Lineup` | heading 20 / 600 | section |  |
| 1266 | `s.label` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 1276 | `who(f.lineup[s.key] ?? const [])` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1285 | `Before the day` | heading 20 / 600 | section |  |
| 1293 | `${f.setBy} set the lineup. Tell them in ` | body 13 / 400 / secondary | caption |  |

**EditLineupScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1384 | `Pick reserve` | heading 22 / 600 | section |  |
| 1391 | `Reserves can’t also be in the lineup.` | body 13 / 400 / secondary | caption |  |
| 1470 | `Locks ${Fmt.dayTimeComma(f.lineupLocksAt` | body 14 / 400 / secondary | secondary |  |
| 1480 | `s.label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1513 | `` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1530 | `Players are told and it is posted in the` | body 13 / 400 / secondary | caption |  |

**TeamLeaveScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1599 | `You keep` | heading 20 / 600 | section |  |
| 1604 | `You lose` | heading 20 / 600 | section |  |

**TeamDeleteScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1697 | `What is removed` | heading 20 / 600 | section |  |

**NewFixtureScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1819 | `Players are told and asked if they can p` | body 14 / 400 / secondary | secondary |  |
| 1845 | `Match time` | body 13 / 400 / secondary | caption |  |
| 1849 | `Choose a date and time` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 1897 | `Result vs ${f.opponent}` | heading 22 / 600 | section |  |

### `lib/features/discover/discover_screen.dart`

**DiscoverScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 181 | `near you` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |

**Hero**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 322 | `Discover` | heading 32 / 600 / on-fill | title |  |
| 382 | `Find your next game` | heading 26 / 600 / on-fill | title |  |
| 389 | `Entries close ${Fmt.day(closes)}` | body 13 / 600 / on-fill | caption | weight dropped |

### `lib/features/discover/presentation/coming_screens.dart`

**EmptyCategoryScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 26 | `message` | lead 16 / 400 / secondary | secondary | intro paragraph |

### `lib/features/discover/presentation/find_screen.dart`

**FindScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 189 | `No Meets match. Try another day, or clea` | lead 16 / 400 / secondary | secondary | intro paragraph |
| 210 | `${s.km!.toStringAsFixed(1)} km away` | body 13 / 400 / secondary | caption |  |

**DateStrip**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 279 | `_names[day.weekday - 1]` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 286 | `${day.day}` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

### `lib/features/earnings/presentation/earnings_screens.dart`

**BalanceCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 63 | `label.toUpperCase()` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 73 | `value` | heading 44 / 600 / other | score |  |
| 78 | `note` | body 14 / 400 / other | body | keeps its colour |

**MoneyRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 118 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 119 | `sub` | body 13 / 400 / secondary | caption |  |
| 126 | `amount` | body 15 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |

**PointsWalletScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 198 | `text: p.pendingNote)` | body 14 / 400 | body |  |
| 201 | `How points work` | heading 20 / 600 | section |  |
| 220 | `${i + 1}` | body 13 / 600 / on-fill | caption | weight dropped |
| 234 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 238 | `text` | body 13 / 400 / secondary | caption |  |
| 256 | `Use points` | heading 20 / 600 | section |  |
| 280 | `1 point takes S\$0.10 off. Each item has` | body 13 / 400 / secondary | caption |  |
| 283 | `Activity` | heading 20 / 600 | section |  |

**ReceiptsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 320 | `RECEIPT` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 327 | `r.title` | heading 24 / 600 | title |  |
| 330 | `${r.kind} · ${Fmt.day(r.at)} · ${r.no}` | body 14 / 400 / secondary | secondary |  |
| 391 | `No receipts here yet. Try another filter` | body 14 / 400 / secondary | secondary |  |
| 398 | `${shown.length} ${shown.length == 1 ?` | body 13 / 400 / secondary | caption |  |
| 415 | `Receipts stay here for 5 years, also aft` | body 13 / 400 / secondary | caption |  |

**EarningsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 447 | `big` | heading 20 / 600 | section |  |
| 451 | `small` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 483 | `Where it came from` | heading 20 / 600 | section |  |
| 487 | `Nothing yet. Paid Meets, tournaments and` | body 14 / 400 / secondary | secondary |  |

**EarningsDetailScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 591 | `How it adds up` | heading 20 / 600 | section |  |
| 596 | `Players` | heading 20 / 600 | section |  |
| 607 | `Absent players are not refunded, so you ` | body 13 / 400 / secondary | caption |  |

**PayoutAccountScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 723 | `Automatic payout` | heading 20 / 600 | section |  |
| 742 | `For a club or academy, the owner sets th` | body 13 / 400 / secondary | caption |  |

### `lib/features/feed/presentation/feed_screens.dart`

**FeedScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 100 | `No videos here yet. Public posts in your` | body 16 / 400 / secondary | secondary |  |
| 108 | `That’s everything for now.` | body 14 / 400 / secondary | secondary |  |

**PostCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 275 | `post.author` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 288 | `post.caption` | body 15 / 400 | body |  |
| 307 | `${post.likes}` | body 14 / 400 / secondary | secondary |  |

**PostPlayer**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 483 | `Can’t play this. Tap to try again.` | body 14 / 400 / secondary | secondary |  |

**AddPostScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 647 | `Video chosen` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 689 | `A person checks your first posts, so the` | body 14 / 400 / secondary | secondary |  |

**MyPostsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 780 | `No posts yet.` | body 16 / 400 / secondary | secondary |  |
| 800 | `No caption` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 802 | `line` | body 14 / 400 / secondary | secondary |  |
| 806 | `detail` | body 14 / 400 / secondary | secondary |  |

### `lib/features/fitness/presentation/ai_plan_screen.dart`

**AiPlanScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 204 | `Writing your plan. This can take a minut` | body 14 / 400 / secondary | secondary |  |
| 218 | `Your plan is ready.` | body 14 / 400 / secondary | secondary |  |

### `lib/features/fitness/presentation/fitness_screens.dart`

**ExerciseTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 61 | `mark` | heading 18 / 600 / primary | section |  |

**ExerciseRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 107 | `title` | body 15 / 700 / primary | body | emphasis dropped (body is Regular); BOLD |
| 114 | `line` | body 13 / 400 / secondary | caption |  |

**Stat**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 145 | `value` | heading 28 / 600 / primary | score |  |
| 149 | `label` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |

**FitnessHomeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 334 | `Your workouts are private to you. Practi` | body 14 / 400 / secondary | secondary |  |

**Hero**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 370 | `eyebrow` | body 13 / 700 / accent | caption | weight dropped; BOLD |
| 373 | `title` | heading 34 / 600 / on-fill | title | hero text 34 → 20; may want its own role |
| 375 | `line` | body 15 / 400 / secondary | secondary |  |

**ExerciseCatalogScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 436 | `No exercise matches` | heading 24 / 600 / primary | title |  |

**ExerciseDetailScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 493 | `e.name` | heading 30 / 600 / primary | title |  |
| 506 | `${i + 1}. $step` | body 15 / 400 / primary | body |  |

**WorkoutLogScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 627 | `No workouts yet. Start one from My worko` | body 14 / 400 / secondary | secondary |  |
| 638 | `Bodyweight` | body 14 / 600 / primary | body | emphasis dropped (body is Regular) |

**CalculatorsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 711 | `label` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 717 | `value` | heading 54 / 600 / accent | score | counter at 54 → 32; may want its own role |
| 721 | `line` | body 13 / 400 / secondary | caption |  |

### `lib/features/fitness/presentation/program_screens.dart`

**ProgramsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 53 | `No programs yet. Build your own or start` | body 14 / 400 / secondary | secondary |  |

### `lib/features/fitness/presentation/train_screen.dart`

**TrainScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 178 | `value` | heading 34 / 600 / primary | score |  |
| 179 | `label` | body 13 / 400 / secondary | caption |  |
| 241 | `EXERCISE ${w.item + 1} OF ${w.plan.lengt` | body 13 / 700 / secondary | caption | grey and bold: weight dropped; BOLD |
| 243 | `item.exercise` | heading 34 / 600 / primary | title | hero text 34 → 20; may want its own role |
| 278 | `REST` | body 13 / 700 / accent | caption | weight dropped; BOLD |
| 286 | `_resting)` | heading 54 / 600 / on-fill | score | counter at 54 → 32; may want its own role |
| 290 | `Next: set ${setsDoneHere + 1} of ${item.` | body 14 / 400 / secondary | secondary |  |
| 310 | `Set $s` | body 15 / 400 / primary | body |  |
| 317 | `Done` | body 13 / 400 / secondary | caption |  |

### `lib/features/game/presentation/creator_screens.dart`

**CreatorProfileScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 42 | `big` | heading 20 / 600 | section |  |
| 43 | `small` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 64 | `cr.name` | heading 24 / 600 | title |  |
| 67 | `${cr.handle} · ${cr.line}` | body 13 / 400 / secondary | caption |  |
| 131 | `Running now` | heading 20 / 600 | section |  |
| 134 | `Videos` | heading 20 / 600 | section |  |
| 163 | `compact(v)` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 176 | `Gear he uses` | heading 20 / 600 | section |  |
| 190 | `Train with him` | heading 20 / 600 | section |  |

**CreatorEarningsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 246 | `big` | heading 20 / 600 | section |  |
| 250 | `small` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 281 | `READY TO PAY OUT` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 290 | `cash(e.readyCents)` | heading 44 / 600 / other | score |  |
| 294 | `From gear you tagged, challenges and you` | body 14 / 400 / other | body | keeps its colour |
| 308 | `Where it came from` | heading 20 / 600 | section |  |
| 315 | `Best videos` | heading 20 / 600 | section |  |
| 324 | `You earn 5% when someone buys an item wi` | body 13 / 400 / secondary | caption |  |

**CreatorChallengesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 378 | `Challenges unlock at ${s.threshold} foll` | body 15 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 389 | `Keep posting clips and playing. Follower` | body 13 / 400 / other | caption |  |
| 394 | `${s.followers} of ${s.threshold} followe` | body 13 / 600 / other | caption | weight dropped |
| 414 | `${s.graceEnds!.difference(DateTime.now()` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 420 | `Your challenges` | heading 20 / 600 | section |  |
| 427 | `No challenges yet. Set a goal for your f` | body 14 / 400 / secondary | secondary |  |

**NewChallengeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 524 | `Sport` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 531 | `Duration` | body 15 / 600 | body | emphasis dropped (body is Regular) |

### `lib/features/game/presentation/game_screens.dart`

**StandingRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 44 | `${s.rank}` | heading 17 / 600 | section |  |
| 59 | `You` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 65 | `s.sub` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 70 | `s.score` | heading 18 / 600 | section |  |

**CampaignCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 113 | `c.reward` | body 13 / 600 / other | caption | weight dropped |
| 119 | `c.title` | heading 24 / 600 / other | title |  |
| 123 | `c.task` | body 14 / 400 / other | body | keeps its colour |
| 128 | `c.meta` | body 13 / 400 / other | caption |  |

**GameHomeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 233 | `Nothing here yet` | heading 20 / 600 | section |  |
| 237 | `New campaigns show up here when they sta` | body 14 / 400 / secondary | secondary |  |

**CampaignScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 379 | `eyebrow` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 387 | `x.title` | heading 28 / 600 / other | title |  |
| 392 | `x.about` | body 14 / 400 / other | body | keeps its colour |
| 417 | `Your count` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 422 | `${x.progress} / ${x.target}` | heading 22 / 600 | score |  |
| 440 | `x.progressNote` | body 13 / 400 / secondary | caption |  |
| 448 | `Your Meets` | heading 20 / 600 | section |  |
| 472 | `The set, in this order` | heading 20 / 600 | section |  |
| 486 | `${i + 1}. ${e.name}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 490 | `e.form` | body 13 / 400 / secondary | caption |  |
| 497 | `${e.reps} reps` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 525 | `big` | heading 22 / 600 | section |  |
| 526 | `small` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 538 | `Fastest times` | heading 20 / 600 | section |  |
| 545 | `Prize` | heading 20 / 600 | section |  |
| 556 | `How it works` | heading 20 / 600 | section |  |
| 563 | `Paid partnership with ${x.sponsor}` | body 13 / 400 / secondary | caption |  |
| 567 | `${_n(x.players)} ${x.players == 1 ?` | body 13 / 400 / secondary | caption |  |

**CameraSetupScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 630 | `Set up your camera` | heading 22 / 600 | section |  |
| 643 | `The attempt is recorded so top times can` | body 13 / 400 / secondary | caption |  |

**AttemptScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 764 | `$_countdown` | heading 72 / 600 / on-fill | score | counter at 72 → 32; may want its own role |
| 770 | `${_exercise + 1} OF ${x.exercises.length` | body 13 / 600 / other | caption | weight dropped |
| 781 | `$_reps` | heading 96 / 600 / other | score | counter at 96 → 32; may want its own role |
| 787 | `of ${ex.reps} ${ex.name.toLowerCase()}` | body 16 / 400 / on-fill | body | keeps its colour |
| 801 | `Paused at ${clock(_seconds)}. Your reps ` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 807 | `Preview: reps are simulated in this buil` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 833 | `clock(r.seconds)` | heading 64 / 600 | title | hero text 64 → 20; may want its own role |
| 851 | `big` | heading 20 / 600 | section |  |
| 852 | `small` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 860 | `Split by exercise` | heading 20 / 600 | section |  |
| 874 | `name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 876 | `sub` | body 13 / 400 / secondary | caption |  |
| 880 | `time` | heading 17 / 600 | section |  |

**AttemptReviewScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 945 | `We’ll check your video. You get a messag` | body 15 / 400 / secondary | secondary |  |
| 973 | `What went wrong?` | heading 20 / 600 | section |  |
| 992 | `A reviewed time can earn the finisher re` | body 13 / 400 / secondary | caption |  |

**LeaderboardsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1058 | `s.name` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 1060 | `s.score` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1074 | `${i + 1}` | heading 24 / 600 / other | score |  |
| 1110 | `$area · $month` | heading 22 / 600 | section |  |
| 1116 | `Skill rating from confirmed matches in $` | body 13 / 400 / secondary | caption |  |
| 1123 | `No ranked players yet.` | body 14 / 400 / secondary | secondary |  |
| 1148 | `#12` | heading 20 / 600 / status | section |  |
| 1153 | `You · 6 confirmed matches this month` | body 14 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |
| 1160 | `5.4` | heading 18 / 600 / status | section |  |
| 1168 | `Local ranks by skill rating. Only player` | body 13 / 400 / secondary | caption |  |
| 1172 | `Rank itself never earns points or money.` | body 13 / 400 / secondary | caption |  |
| 1179 | `Report a result that looks wrong` | body 14 / 600 / link | button | link |

### `lib/features/game/presentation/gear_screens.dart`

**MyGearScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 47 | `Others can see it on your player profile` | body 14 / 400 / secondary | secondary |  |
| 57 | `Add your racquet, shoes and strings to t` | body 14 / 400 / secondary | secondary |  |

**GearItemScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 135 | `g.name` | heading 26 / 600 | title |  |
| 137 | `cash(g.priceCents!)` | heading 20 / 600 | section |  |
| 140 | `String setup` | heading 20 / 600 | section |  |

**GearEditScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 273 | `Add what you play with. Others can see i` | body 14 / 400 / secondary | secondary |  |
| 275 | `Gear type` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 291 | `String setup` | heading 20 / 600 | section |  |
| 294 | `Strings and tension for your racquet.` | body 13 / 400 / secondary | caption |  |
| 328 | `Size` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 341 | `Fit` | body 15 / 600 | body | emphasis dropped (body is Regular) |

### `lib/features/game/presentation/reward_screens.dart`

**WalletScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 57 | `No vouchers yet. You earn them from coun` | body 14 / 400 / secondary | secondary |  |

**VoucherCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 101 | `v.name` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 104 | `${Money(v.amountCents)} off` | body 14 / 400 | body |  |
| 113 | `$p at ${v.where}` | body 13 / 400 / secondary | caption |  |
| 122 | `v.code` | body 14 / 400 | body |  |

**OrganizerRewardsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 179 | `Your Meets show up here once their money` | body 14 / 400 / secondary | secondary |  |
| 193 | `g.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 200 | `Game ${g.gameNo}` | body 13 / 400 / secondary | caption |  |

### `lib/features/guardian/presentation/parent_link_screens.dart`

**RestrictedHomeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 34 | `OlympusGO` | h1 34 / 600 / primary | title |  |
| 50 | `You can read our rules and contact help,` | lead 16 / 400 / secondary | secondary | intro paragraph |

**ParentCodeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 110 | `Show this to your parent or guardian. Th` | lead 16 / 400 / secondary | secondary | intro paragraph |
| 136 | `code.code` | heading 36 / 600 / primary | title | hero text 36 → 20; may want its own role |
| 145 | `It works for 24 hours, and only once.` | body 14 / 400 / secondary | secondary |  |

**EnterChildCodeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 225 | `You're linking ${pending.childName}'s ac` | lead 16 / 400 / secondary | secondary | intro paragraph |
| 245 | `Enter the 8-character code from your chi` | lead 16 / 400 / secondary | secondary | intro paragraph |

**MyChildrenScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 283 | `No linked accounts yet. Ask your child f` | lead 16 / 400 / secondary | secondary | intro paragraph |

**ChildDetailScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 383 | `group.name` | body 16 / 400 / primary | body |  |
| 385 | `group.area` | body 13 / 400 / secondary | caption |  |
| 413 | `Nothing posted yet.` | body 16 / 400 / secondary | secondary |  |
| 423 | `post.kindLabel` | body 13 / 400 / secondary | caption |  |
| 426 | `post.body` | body 16 / 400 / primary | body |  |

### `lib/features/home/edit_categories_screen.dart`

**EditCategoriesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 111 | `h.label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 115 | `h.sub` | body 13 / 400 / secondary | caption |  |

### `lib/features/home/home_rows.dart`

**SearchPill**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 186 | `Search Meets, clubs, players, shops` | body 16 / 400 / secondary | secondary |  |

**HomeSection**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 233 | `title` | display 26 / 600 / primary | title |  |

**ClubTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 408 | `mark` | heading 44 / 600 / other | monogram | initials or logo letters at 44: no role fits |
| 435 | `name` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 442 | `No sessions this week` | body 13 / 600 / link | caption | orange accent text, not a link: keeps its colour |
| 478 | `$count members` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |

**PlayerTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 577 | `p.level!.toStringAsFixed(1)` | body 11 / 600 / accent | caption | was 11; caption is 13; weight dropped |
| 591 | `p.player.displayName` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 597 | `p.note` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 630 | `Following` | body 13 / 600 / on-fill | caption | weight dropped |

**MallShelf**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 682 | `m.initials` | heading 44 / 600 / other | monogram | initials or logo letters at 44: no role fits |
| 690 | `m.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 701 | `m.blurb` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**ProductShelf**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 767 | `p.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 776 | `p.mallName` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 783 | `S\$${money(p.priceCents, decimals: p.pri` | body 15 / 600 | body | emphasis dropped (body is Regular) |

### `lib/features/home/home_screen.dart`

**Hero**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 129 | `CR` | heading 92 / 600 / other | monogram | initials or logo letters at 92: no role fits |
| 150 | `date` | body 13 / 600 / on-fill | caption | weight dropped |
| 158 | `Hi there` | heading 32 / 600 / on-fill | title |  |
| 211 | `Coach Ravi's 30-day smash challenge` | heading 26 / 600 / on-fill | title |  |
| 216 | `412 players joined` | body 13 / 600 / on-fill | caption | weight dropped |

**Categories**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 281 | `label` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |

**Balances**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 391 | `label` | body 13 / 600 / other | caption | weight dropped |
| 402 | `value` | heading 34 / 600 / other | score |  |
| 406 | `note` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |

**YourGroups**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 459 | `Your groups` | section 22 / 600 | section |  |

### `lib/features/inbox/presentation/inbox_screen.dart`

**InboxScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 94 | `Inbox` | heading 24 / 600 | title |  |

**Section**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 203 | `title` | display 18 / 600 / primary | section |  |

**Empty**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 249 | `text` | body 14 / 400 / secondary | secondary |  |

**Mark**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 281 | `mark` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |

**ChatRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 326 | `chat.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 333 | `No messages yet` | body 13 / 600 / secondary | caption | grey and bold: weight dropped; weight switches: unread ? FontWeight.w600 : FontWeight.w4 |
| 349 | `inboxStamp(chat.at!)` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**UpdateRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 409 | `u.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 415 | `u.body` | body 13 / 400 / secondary | caption |  |
| 427 | `inboxStamp(u.at)` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

### `lib/features/onboarding/presentation/account_screens.dart`

**UsernameScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 130 | `Checking…` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |
| 156 | `$name is available` | body 14 / 600 / primary | body | emphasis dropped (body is Regular) |

**ReadyScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 412 | `You're in.` | display 38 / 600 / on-fill | title | hero text 38 → 20; may want its own role |
| 421 | `Your Passport is ready. Next, check your` | body 17 / 400 / other | body | keeps its colour |
| 452 | `initials` | display 18 / 600 / other | section |  |
| 465 | `${first.sport.label} · ${first.level.toS` | display 19 / 600 / on-fill | section |  |
| 473 | `Starting level. Adjusts after a few matc` | body 14 / 400 / other | body | keeps its colour |

### `lib/features/onboarding/presentation/name_birthday_screens.dart`

**FullNameScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 72 | `` | display 36 / 600 / primary | title | hero text 36 → 20; may want its own role |
| 77 | `Full name` | display 36 / 600 / other | title | hero text 36 → 20; may want its own role |

**BirthdayScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 268 | `Sets your currency, emergency number and` | body 14 / 400 / secondary | secondary |  |

### `lib/features/onboarding/presentation/sports_screens.dart`

**SportTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 123 | `sport.label` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |

**SkillLevelScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 227 | `sport.label` | display 20 / 600 / primary | section |  |
| 232 | `draft.skillFor(sport).summary` | body 15 / 400 / secondary | secondary |  |
| 259 | `Set a level for each sport to continue.` | body 14 / 400 / secondary | secondary |  |

**SportSkillScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 317 | `label` | body 14 / 400 / secondary | secondary |  |
| 320 | `value.toStringAsFixed(1)` | display 24 / 600 / primary | score |  |
| 324 | `value.toStringAsFixed(1)` | body 14 / 400 / secondary | secondary |  |
| 346 | `Play with levels` | label 14 / 600 | caption | field label |
| 400 | `SkillScale.nameWithShort(_skill.playMin)` | body 15 / 600 / primary | body | emphasis dropped (body is Regular) |
| 408 | `SkillScale.nameWithShort(_skill.playMax)` | body 15 / 600 / primary | body | emphasis dropped (body is Regular) |

### `lib/features/play/presentation/create_competition_screens.dart`

**BannerPicker**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 49 | `${noun[0].toUpperCase()}${noun.substring` | heading 20 / 600 | section |  |
| 54 | `Shown on the $noun card and page.${requi` | body 13 / 400 / secondary | caption |  |
| 72 | `Banner title` | heading 30 / 600 / primary | title |  |

**Money**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 141 | `k` | body 14 / 600 | body | emphasis dropped (body is Regular); weight switches: bold ? FontWeight.w600 : FontWeight.w400 |
| 149 | `v` | body 14 / 600 | body | emphasis dropped (body is Regular) |

**NewEventScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 389 | `Attendees who cancel by the day before g` | body 13 / 400 / secondary | caption |  |
| 399 | `Link to another event · Show it on this ` | body 13 / 400 / secondary | caption |  |

**NewTournamentScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 586 | `Tier` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 595 | `` | body 13 / 400 / secondary | caption |  |
| 645 | `Courts are used to build the match sched` | body 13 / 400 / secondary | caption |  |
| 672 | `Teams enter with a roster. Each tie is a` | body 13 / 400 / secondary | caption |  |
| 706 | `The list comes from the sport: ${d.sport` | body 13 / 400 / secondary | caption |  |
| 772 | `Show level on the card as` | body 13 / 400 / secondary | caption |  |
| 816 | `Date of birth is checked privately. Only` | body 13 / 400 / secondary | caption |  |
| 875 | `Counted in $unit. If an event has fewer ` | body 13 / 400 / secondary | caption |  |
| 908 | `Platform fee: 10%, minimum S\$2. Doubles` | body 13 / 400 / secondary | caption |  |
| 926 | `If they withdraw before registration clo` | body 13 / 400 / secondary | caption |  |
| 969 | `Link to an event · Show this tournament ` | body 13 / 400 / secondary | caption |  |
| 1006 | `Results update ratings. Tournament leade` | body 13 / 400 / secondary | caption |  |

### `lib/features/play/presentation/create_meet_screens.dart`

**CreateSection**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 107 | `title` | heading 20 / 600 | section |  |

**CreatePickRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 157 | `$label · $hint` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 164 | `value` | body 16 / 600 | body | emphasis dropped (body is Regular) |

**CreateStepper**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 205 | `sign` | heading 20 / 600 / secondary | section | section heading in grey |
| 221 | `label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 229 | `value` | heading 18 / 600 | section |  |

**NewMeetDetailsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 590 | `Repeats on · Pick one or more days` | body 13 / 400 / secondary | caption |  |
| 664 | `Game type` | body 13 / 400 / secondary | caption |  |
| 688 | `Players` | body 13 / 400 / secondary | caption |  |
| 734 | `${type.label} needs at least $min. Extra` | body 13 / 400 / secondary | caption |  |
| 736 | `Who it\'s for` | body 13 / 400 / secondary | caption |  |
| 793 | `Show level on the Meet card as` | body 13 / 400 / secondary | caption |  |
| 847 | `k` | body 14 / 600 | body | emphasis dropped (body is Regular); weight switches: bold ? FontWeight.w600 : FontWeight.w400 |
| 855 | `v` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 897 | `/ person` | body 14 / 400 / secondary | secondary |  |
| 921 | `Who pays the S\$2 platform fee?` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 963 | `Platform fee: 10%, minimum S\$2.` | body 13 / 400 / secondary | caption |  |
| 977 | `You mark attendance at the Meet. Present` | body 14 / 400 / secondary | secondary |  |

**PartPill**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1066 | `$n` | body 12 / 600 / status | caption | was 12; caption is 13; weight dropped |
| 1080 | `label` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

**DayDot**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1126 | `letter` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

**TypeCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1171 | `label` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 1179 | `sub` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

### `lib/features/play/presentation/create_screens.dart`

**CreateMenu**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 140 | `k.label` | body 17 / 600 | section |  |
| 145 | `sub` | body 14 / 400 / secondary | secondary |  |
| 171 | `Create` | heading 22 / 600 | section |  |
| 175 | `Hosted by ${host.name}` | body 14 / 400 / secondary | secondary |  |
| 198 | `Start a group first` | body 17 / 600 | section |  |
| 205 | `Meets, tournaments and events are hosted` | body 14 / 400 / secondary | secondary |  |
| 259 | `You only see what your role allows. Meet` | body 13 / 400 / secondary | caption |  |

**Step**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 297 | `lead!` | body 15 / 400 / secondary | secondary |  |

**PickTimeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 508 | `Lasts` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 530 | `${Fmt.clock(_hour, _minute)} to` | body 14 / 400 / secondary | secondary |  |

**PickVenueScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 594 | `Nothing matches. Check the spelling or c` | body 15 / 400 / secondary | secondary |  |
| 615 | `Courts to book` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 632 | `Court fees are set by the venue and paid` | body 13 / 400 / secondary | caption |  |

### `lib/features/play/presentation/event_screens.dart`

**EventPageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 194 | `About this event` | display 17 / 600 / primary | section |  |
| 198 | `e.about` | body 15 / 400 / other | body | keeps its colour |
| 209 | `Up next` | heading 20 / 600 | section |  |
| 212 | `e.programmeDay` | body 13 / 400 / secondary | caption |  |
| 226 | `What the finalists use` | heading 20 / 600 | section |  |
| 241 | `Players and creators earn a share when y` | body 13 / 400 / secondary | caption |  |
| 247 | `Host` | heading 20 / 600 | section |  |
| 273 | `cl.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |

**IdentityCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 327 | `main` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 330 | `sub` | body 13 / 400 / secondary | caption |  |
| 377 | `a.title` | heading 24 / 600 | title |  |
| 384 | `${info.clubs.first.name} · with ${info.c` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 412 | `${(rest / 1000).toStringAsFixed(1)}k` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 427 | `${_thousands(a.watching)} watching · ${a` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |

**LiveCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 496 | `names` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 509 | `$g` | heading 20 / 600 / on-fill | section |  |
| 528 | `Cheer · ${_thousands(n)}` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 559 | `LIVE · ${l.label}` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |

**ProgrammeRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 634 | `it.time` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 641 | `it.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 642 | `it.sub` | body 13 / 400 / secondary | caption |  |

**GearCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 711 | `Used by ${g.player}` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 717 | `g.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 721 | `S\$${money(g.priceCents, decimals: false` | body 13 / 400 / secondary | caption |  |

**BottomBar**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 761 | `Your ticket · ${info.tickets} ${info.tic` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 767 | `Free entry · release it if you can’t com` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 787 | `Free` | heading 20 / 600 | section |  |
| 793 | `per person · nothing to pay` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**TicketSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 913 | `NOTHING TO PAY` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 921 | `a.title` | heading 24 / 600 | title |  |
| 924 | `${Fmt.dayTimeComma(a.startsAt)} · ${a.ve` | body 14 / 400 / secondary | secondary |  |
| 941 | `People` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 945 | `Up to 6 per order` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 979 | `Entry is free. The organizer covers the ` | body 13 / 400 / secondary | caption |  |

**EventTicketScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1050 | `tk.title` | heading 22 / 600 / on-fill | section |  |
| 1055 | `Fmt.dayTimeRange(tk.startsAt` | body 14 / 400 / other | body | keeps its colour |
| 1076 | `tk.code` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 1103 | `Show this code at the entrance.` | body 13 / 400 / secondary | caption |  |

**EventReleaseScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1170 | `$n ${n == 1 ?` | body 15 / 400 / secondary | secondary |  |
| 1232 | `Released tickets go to the next person w` | body 13 / 400 / secondary | caption |  |

**EventManageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1264 | `a.title` | heading 26 / 600 | title |  |
| 1269 | `${Fmt.day(a.startsAt)} · ${a.online ?` | body 14 / 400 / secondary | secondary |  |

**EventCancelScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1385 | `What happens` | heading 20 / 600 | section |  |

**ScanTicketScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1515 | `Valid ticket` | heading 28 / 600 / status | title |  |
| 1522 | `${r.qty} ${r.qty == 1 ?` | heading 20 / 600 / status | section |  |
| 1542 | `A ticket works once. If it is scanned ag` | body 13 / 400 / secondary | caption |  |

**MyTicketsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1588 | `No tickets yet. Events you get tickets f` | body 14 / 400 / secondary | secondary |  |

**CheckTicketsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1637 | `You are not running any events. Tickets ` | body 14 / 400 / secondary | secondary |  |

### `lib/features/play/presentation/meet_action_screens.dart`

**GuestScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 158 | `Their level` | heading 20 / 600 | section |  |
| 172 | `You are not on this Meet yet, so you pay` | body 14 / 400 / secondary | secondary |  |

**WaitlistScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 242 | `On the waitlist for ${a.title}` | heading 22 / 600 | section |  |
| 248 | `We message you the moment a spot opens. ` | body 15 / 400 / secondary | secondary |  |
| 290 | `If a spot opens, pay with` | heading 20 / 600 | section |  |

**ScheduleScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 363 | `title` | heading 20 / 600 | section |  |
| 366 | `${items.length} ${items.length == 1 ?` | body 13 / 400 / secondary | caption |  |
| 419 | `Nothing on ${Fmt.day(_day!)}.` | body 15 / 400 / secondary | secondary |  |

**DayTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 481 | `_names[day.weekday - 1]` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 488 | `${day.day}` | heading 18 / 600 / other | section |  |

**ScheduleRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 547 | `days[a.startsAt.weekday - 1]` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 553 | `${a.startsAt.day}` | heading 18 / 600 | section |  |
| 566 | `a.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 573 | `line` | body 13 / 400 / secondary | caption |  |

**Empty**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 603 | `Nothing hosted yet` | heading 20 / 600 | section |  |
| 611 | `Meets, tournaments and events you run sh` | body 14 / 400 / secondary | secondary |  |

### `lib/features/play/presentation/meet_detail_screen.dart`

**MeetPage**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 306 | `a.kind.label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 331 | `a.title` | heading 24 / 600 | title |  |
| 373 | `+$rest` | body 13 / 600 / other | caption | weight dropped |
| 385 | `count` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 516 | `About this $_noun` | display 17 / 600 / primary | section |  |
| 521 | `a.description!` | body 15 / 400 / other | body | keeps its colour |

**Caps**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 636 | `text` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |

**HostLine**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 691 | `Hosted by $host` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |

**InfoRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 736 | `main` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 741 | `sub!` | body 13 / 400 / secondary | caption |  |

**RankedCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 783 | `Ranked game` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 795 | `Results update your rating and leaderboa` | body 14 / 400 / other | body | keeps its colour |
| 818 | `Enter a score` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |

**Players**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 868 | `noun` | display 18 / 600 / primary | section |  |
| 873 | `${a.spotsTaken} going · waitlist ${a.wai` | body 13 / 400 / secondary | caption |  |
| 885 | `No one yet. Be the first to join.` | body 14 / 400 / secondary | secondary |  |
| 903 | `See all ${a.spotsTaken} ${noun.toLowerCa` | body 14 / 600 | body | emphasis dropped (body is Regular) |

**PlayerRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 958 | `player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 964 | `meta` | body 13 / 400 / secondary | caption |  |
| 969 | `rating!` | heading 17 / 600 | section |  |

**HostCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1066 | `You are playing too` | display 17 / 600 / primary | section |  |
| 1078 | `` | body 14 / 400 / other | body | keeps its colour |

**BottomBar**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1153 | `label` | body 15 / 600 / primary | body | emphasis dropped (body is Regular) |
| 1206 | `You're going` | body 16 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |
| 1247 | `Waiting for the host to accept you` | body 15 / 600 / secondary | secondary | grey and bold: weight dropped |
| 1259 | `You're #${a.myWaitlistPosition} on the w` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 1276 | `Free` | heading 20 / 600 | section |  |
| 1284 | `Free entry` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**DoneSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1468 | `title` | heading 26 / 600 | title |  |
| 1471 | `body` | body 15 / 400 / secondary | secondary |  |

**LeaveSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1581 | `YOUR SPOT` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 1591 | `Give up your spot?` | heading 26 / 600 | title |  |
| 1596 | `${a.title}, ${meetWhen(a).split(` | body 15 / 400 / secondary | secondary |  |
| 1613 | `head` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1616 | `S\$${money(_amount)}` | heading 20 / 600 | section |  |
| 1620 | `sub` | body 13 / 400 / other | caption |  |
| 1630 | `Your spot opens for the next player. You` | body 14 / 400 / secondary | secondary |  |

### `lib/features/play/presentation/meet_host_screens.dart`

**MeetPlayersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 130 | `${a.men}` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 135 | `${a.women}` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 156 | `Nobody is going yet` | heading 20 / 600 | section |  |
| 165 | `Players who join show up here.` | body 14 / 400 / secondary | secondary |  |

**MeetWalkInScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 277 | `Everyone who has played with you is alre` | body 14 / 400 / secondary | secondary |  |
| 302 | `How did they pay?` | heading 20 / 600 | section |  |

**MeetAttendanceScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 431 | `label` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 456 | `_short(a)` | body 14 / 400 / secondary | secondary |  |
| 460 | `$present` | heading 44 / 600 | score |  |
| 470 | `of ${going.length} present` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 476 | `Everyone is marked` | body 13 / 400 / secondary | caption |  |
| 519 | `You have not been detected at ${a.venue.` | body 15 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |
| 539 | `` | body 13 / 400 / status | caption |  |
| 623 | `Scan a player` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 641 | `Add a walk-in member` | body 14 / 600 | body | emphasis dropped (body is Regular) |

**MeetRecapScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 756 | `Show on the card` | heading 20 / 600 | section |  |
| 793 | `label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 797 | `hint` | body 13 / 400 / secondary | caption |  |

**RecapCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 883 | `a.eyebrow.toUpperCase()` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 891 | `a.title` | heading 28 / 600 / on-fill | title |  |
| 895 | `·` | body 14 / 400 / secondary | secondary |  |
| 917 | `big` | heading 24 / 600 / on-fill | title |  |
| 924 | `small` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 943 | `RATING` | body 11 / 600 / secondary | caption | was 11; caption is 13; grey and bold: weight dropped |
| 952 | `${r.ratingBefore!.toStringAsFixed(1)} → ` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 991 | `· ${r.partnerWins} ${r.partnerWins == 1 ` | body 14 / 400 / secondary | secondary |  |
| 1001 | `$playerName · session ${r.session}` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 1008 | `Play with us: ${r.clubLink}` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**MeetCancelScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1098 | `Which Meets?` | heading 20 / 600 | section |  |
| 1119 | `Refunds` | heading 20 / 600 | section |  |
| 1137 | `Money goes back to the card or PayNow ea` | body 13 / 400 / secondary | caption |  |

### `lib/features/play/presentation/meet_rounds_screen.dart`

**MeetRoundsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 232 | `No rounds yet.` | body 16 / 400 / secondary | secondary |  |
| 242 | `Court ${m.court}` | body 13 / 400 / secondary | caption |  |
| 246 | `${side(m.sideA)} vs ${side(m.sideB)}` | body 16 / 400 / primary | body |  |
| 253 | `Sitting out: ${side(r.byes)}` | body 13 / 400 / secondary | caption |  |

**Count**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 283 | `label` | body 16 / 400 / primary | body |  |

### `lib/features/play/presentation/pay_flow.dart`

**PaymentWaitingScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 332 | `${Money(widget.hold.totalCents)} to Olym` | heading 24 / 600 | title |  |
| 344 | `` | body 14 / 400 / secondary | secondary |  |

### `lib/features/play/presentation/play_card.dart`

**PlayCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 133 | `a.coverTitle ?? a.title` | heading 30 / 600 / other | title |  |
| 172 | `a.kind.label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 202 | `a.title` | body 19 / 600 / primary | section |  |
| 231 | `people` | body 13 / 600 | caption | caption turns grey; weight dropped |

**GenderChip**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 275 | `$men` | body 12 / 600 | caption | was 12; caption is 13; caption turns grey; weight dropped |
| 279 | `$women` | body 12 / 600 | caption | was 12; caption is 13; caption turns grey; weight dropped |

**Line**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 314 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 321 | `` | body 13 / 400 / secondary | caption |  |

**Proof**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 355 | `text: proof.name` | body 13 / 600 / primary | caption | caption turns grey; weight dropped |
| 366 | `${proof.text}` | body 13 / 400 / other | caption |  |

### `lib/features/play/presentation/play_screen.dart`

**Hero**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 192 | `Play` | heading 30 / 600 / on-fill | title |  |
| 210 | `Host your own session` | heading 28 / 600 / on-fill | title |  |
| 215 | `Meet, tournament, event` | body 13 / 600 / on-fill | caption | weight dropped |
| 233 | `Create` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

**FilterBar**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 304 | `bar[i].title` | body 12 / 600 | caption | was 12; caption is 13; caption turns grey; weight dropped |
| 311 | `bar[i])` | body 14 / 500 / secondary | secondary |  |

**SportPill**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 434 | `•` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 444 | `text` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

**AddSportChip**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 499 | `Add sport` | body 14 / 600 / link | button | link |

**NextSession**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 538 | `days[next.startsAt.weekday - 1]` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 546 | `${next.startsAt.day}` | heading 30 / 600 / on-fill | score |  |
| 560 | `My next session` | body 13 / 600 / other | caption | weight dropped |
| 579 | `next.title` | body 17 / 600 / on-fill | section |  |
| 588 | `$when, ${next.venue.name}` | body 13 / 400 / other | caption |  |

**Empty**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 627 | `No $what match these filters` | body 17 / 600 | section |  |
| 633 | `Try another day or sport, or host your o` | body 14 / 400 / secondary | secondary |  |

**HubFiltersSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 695 | `Filters` | heading 26 / 600 / primary | title |  |
| 720 | `g.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 777 | `note` | body 13 / 400 / secondary | caption |  |

**SportOptionsSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 960 | `widget.sport.label` | heading 26 / 600 | title |  |
| 1016 | `Every skill level is shown.` | body 13 / 400 / secondary | caption |  |

**Options**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1069 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**BandRangePicker**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1164 | `Min` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 1172 | `bands[lo].label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1182 | `Max` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 1190 | `bands[hi].label` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1266 | `bands[k].code` | body 12 / 600 / primary | caption | was 12; caption is 13; caption turns grey; weight dropped |
| 1287 | `Drag either end, or tap a level.` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**PlayAddSportScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1337 | `Pick a sport, then set its ${tab.hasGame` | body 13 / 400 / secondary | caption |  |
| 1345 | `No sport matches. Check the spelling or ` | body 15 / 400 / secondary | secondary |  |
| 1404 | `s.label` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 1409 | `sub` | body 13 / 400 / secondary | caption |  |

### `lib/features/play/presentation/play_widgets.dart`

**ActivityCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 55 | `text` | body 14 / 400 / secondary | secondary |  |
| 81 | `eyebrow ?? a.eyebrow` | body 13 / 600 / link | caption | orange accent text, not a link: keeps its colour |
| 100 | `pill.label` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 114 | `a.title` | body 18 / 600 / primary | section |  |

**ChipChoice**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 155 | `label` | body (var size) / 600 / primary | body | size set by a variable: check; emphasis dropped (body is Regular) |

**LabeledSelect**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 206 | `label` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |

**PickerRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 309 | `label` | body 16 / 400 / secondary | secondary |  |
| 315 | `value` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |

**OptionRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 382 | `title` | body (var size) / 600 / primary | body | size set by a variable: check; emphasis dropped (body is Regular) |
| 391 | `subtitle!` | body 14 / 400 / secondary | secondary |  |

**MonthCalendar**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 509 | `${Fmt.monthsLong[_month.month - 1]} ${_m` | body 18 / 600 / primary | section |  |
| 524 | `d` | body 13 / 400 / secondary | caption |  |
| 578 | `$n` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

### `lib/features/play/presentation/score_screens.dart`

**ScoreEntryScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 190 | `Waiting for ${s.sideB.map((p) => p.displ` | heading 22 / 600 | section |  |
| 197 | `${s.sideB.length > 1 ?` | body 15 / 400 / secondary | secondary |  |
| 308 | `Game ${g + 1}` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 339 | `head` | heading 22 / 600 | section |  |
| 343 | `hint` | body 14 / 400 / secondary | secondary |  |

**TournamentUmpireScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 599 | `The draw is updated and both sides can s` | body 15 / 400 / secondary | secondary |  |
| 665 | `Game ${g + 1}` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 693 | `head` | heading 22 / 600 | section |  |
| 695 | `hint` | body 14 / 400 / secondary | secondary |  |

**TeamLine**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 722 | `name` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 731 | `$wins ${wins == 1 ?` | body 14 / 600 / secondary | secondary | grey and bold: weight dropped |

**ScoreBox**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 774 | `–` | heading 36 / 600 / on-fill | title | hero text 36 → 20; may want its own role |

**Keypad**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 816 | `label` | heading 22 / 600 | section |  |
| 836 | `Next` | body 16 / 600 | body | emphasis dropped (body is Regular) |

**SidesPicker**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 901 | `Your partner` | heading 20 / 600 | section |  |
| 918 | `You played` | heading 20 / 600 | section |  |

**ScoreConfirmScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1071 | `_side(side` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 1079 | `$wins ${wins == 1 ?` | body 13 / 400 / secondary | caption |  |
| 1090 | `${isTop ? g.$1 : g.$2}` | heading 26 / 600 / accent | score |  |
| 1110 | `Game ${i + 1}` | body 11 / 400 / secondary | caption | was 11; caption is 13 |
| 1128 | `,` | body 14 / 400 / secondary | secondary |  |
| 1137 | `Confirmed` | heading 26 / 600 | title |  |
| 1144 | `s.ratingBefore!.toStringAsFixed(1)` | heading 40 / 600 / secondary | score |  |
| 1148 | `to` | body 15 / 400 / secondary | secondary |  |
| 1152 | `s.ratingAfter!.toStringAsFixed(1)` | heading 40 / 600 | score |  |
| 1161 | `It counts toward ratings and the leaderb` | body 15 / 400 / secondary | secondary |  |
| 1178 | `This score was corrected` | heading 26 / 600 | title |  |
| 1181 | `A newer result replaced it.` | body 15 / 400 / secondary | secondary |  |
| 1188 | `Set the final score` | heading 26 / 600 | title |  |
| 1191 | `Both sides are told what you decide. Rat` | body 15 / 400 / secondary | secondary |  |
| 1210 | `The OlympusGO team decides` | heading 26 / 600 | title |  |
| 1214 | `You played in this match, so someone els` | body 15 / 400 / secondary | secondary |  |
| 1221 | `Sent to $org` | heading 26 / 600 | title |  |
| 1225 | `You and $entered are told when they set ` | body 15 / 400 / secondary | secondary |  |
| 1240 | `Waiting for ${s.sideB.map((p) => p.displ` | heading 26 / 600 | title |  |
| 1245 | `You sent this ${_ago(s.enteredAt)}. If n` | body 15 / 400 / secondary | secondary |  |
| 1252 | `What is wrong?` | heading 26 / 600 | title |  |
| 1287 | `Is this score right?` | heading 26 / 600 | title |  |
| 1291 | `$entered entered it ${_ago(s.enteredAt)}` | body 15 / 400 / secondary | secondary |  |

### `lib/features/play/presentation/tournament_host_screens.dart`

**TournamentManageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 93 | `a.title` | heading 26 / 600 | title |  |
| 98 | `${tournamentDates(a)} · ${t.entries} ent` | body 14 / 400 / secondary | secondary |  |

**TournamentEntriesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 255 | `${d.entries} of ${d.capacity} entries` | heading 22 / 600 | section |  |
| 276 | `` | heading 17 / 600 | section |  |
| 285 | `e.names` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 293 | `rating ${e.rating!.toStringAsFixed(1)}` | body 13 / 400 / secondary | caption |  |
| 318 | `Seeding follows each player’s main ratin` | body 13 / 400 / secondary | caption |  |

**TournamentCheckInScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 393 | `$count` | heading 44 / 600 | score |  |
| 399 | `of ${entries.length} $unit here` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 440 | `e.names` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 445 | `e.firstMatch!` | body 13 / 400 / secondary | caption |  |
| 481 | `${d.doubles ?` | body 13 / 400 / secondary | caption |  |

**TournamentMessageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 575 | `_text.text.trim()` | body 15 / 400 / secondary | secondary |  |
| 596 | `Who gets it` | heading 20 / 600 | section |  |
| 609 | `Message` | heading 20 / 600 | section |  |
| 627 | `Sent as a notification from ${t.activity` | body 13 / 400 / secondary | caption |  |

**TournamentCancelScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 716 | `Refunds` | heading 20 / 600 | section |  |
| 730 | `Also cancelled` | heading 20 / 600 | section |  |
| 756 | `Entrants are told straight away.` | body 13 / 400 / secondary | caption |  |

**TournamentRunScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 793 | `Make the draw again?` | heading 22 / 600 | section |  |
| 802 | `${again ?` | body 15 / 400 / secondary | secondary |  |
| 854 | `${m.a} vs ${m.b}` | heading 22 / 600 | section |  |
| 862 | `Court ${m.court}` | body 14 / 400 / secondary | secondary |  |
| 868 | `m.games)` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 955 | `${d.entries} $unit entered` | heading 22 / 600 | section |  |
| 970 | `` | body 15 / 400 / secondary | secondary |  |
| 996 | `${played.length}` | heading 44 / 600 | score |  |
| 1002 | `of ${ms.length} matches played` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1008 | `Up next` | heading 20 / 600 | section |  |
| 1015 | `$waiting ${waiting == 1 ?` | body 14 / 400 / secondary | secondary |  |
| 1020 | `Played` | heading 20 / 600 | section |  |

**RunMatchRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1050 | `` | body 15 / 600 / secondary | secondary | grey and bold: weight dropped; weight switches: win == false ? FontWeight.w500 : FontWei |
| 1069 | `–` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 1073 | `` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1094 | `stage` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1102 | `W/O` | body 15 / 600 | body | emphasis dropped (body is Regular) |

### `lib/features/play/presentation/tournament_screens.dart`

**CompetitionBanner**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 97 | `a.coverTitle ?? a.title` | heading 34 / 600 / other | title | hero text 34 → 20; may want its own role |

**TournamentPageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 307 | `You're in` | body 16 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |
| 331 | `Free` | heading 20 / 600 | section |  |
| 337 | `No entry fee` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 386 | `Closes ${Fmt.day(closes)}` | body 13 / 400 / secondary | caption |  |
| 395 | `Free to enter` | heading 22 / 600 | section |  |
| 402 | `${t.fromCents == 0 ?` | body 14 / 400 / secondary | secondary |  |
| 430 | `You're in` | body 13 / 600 / status | caption | weight dropped |
| 441 | `${mine.divisionName} with ${mine.partner` | heading 20 / 600 / status | section |  |
| 449 | `First match ${Fmt.dayTimeComma(mine.firs` | body 14 / 400 / status | body | keeps status colour |
| 460 | `You get the draw and your first match ti` | body 14 / 400 / status | body | keeps status colour |
| 479 | `Events` | heading 20 / 600 | section |  |
| 483 | `Format and rules` | heading 20 / 600 | section |  |
| 511 | `Contact` | body 14 / 600 / link | button | link |

**IdentityCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 578 | `a.title` | heading 24 / 600 | title |  |
| 582 | `Hosted by ${info.host}` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |

**Line**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 625 | `text` | body 14 / 600 / link | body | orange accent text, not a link: keeps its colour; weight switches: link ? FontWeight.w600 : FontWeight.w500 |

**InviteCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 700 | `${inv.from.displayName} asked you to par` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 704 | `inv.divisionName` | body 13 / 400 / secondary | caption |  |

**DivisionRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 757 | `d.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 770 | `${d.entries} of ${d.capacity} entries · ` | body 13 / 400 / secondary | caption |  |

**DrawTab**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 845 | `The draw is not out yet` | heading 20 / 600 | section |  |
| 850 | `It is made the day after registration cl` | body 14 / 400 / secondary | secondary |  |
| 883 | `COURT` | body 9 / 600 / other | caption | was 9; caption is 13; weight dropped |
| 891 | `Court` | heading 20 / 600 / other | section |  |
| 903 | `Your next match · ${Fmt.dayTimeComma(nex` | body 12 / 400 / other | caption | was 12; caption is 13 |
| 910 | `You${info.mine?.partner == null ?` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 936 | `Swipe to see the final` | body 13 / 400 / secondary | caption |  |
| 951 | `r.name` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 971 | `Scores show as soon as the umpire enters` | body 13 / 400 / secondary | caption |  |

**GroupTable**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 990 | `` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 1007 | `group.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1012 | `Top 2 go through` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1059 | `${r.pos}` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 1073 | `r.names` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 1090 | `Seed ${r.seed} · avg ${r.rating.toString` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1100 | `${r.wins}–${r.losses}` | body 14 / 400 | body |  |
| 1108 | `${r.points}` | body 14 / 600 | body | emphasis dropped (body is Regular) |

**KoCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1141 | `name` | body 13 / 600 / secondary | caption | grey and bold: weight dropped; weight switches: win ? FontWeight.w600 : FontWeight.w500 |
| 1150 | `` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 1174 | `m.when` | body 11 / 400 / secondary | caption | was 11; caption is 13 |

**MatchesTab**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1207 | `·` | body 13 / 600 / secondary | caption | grey and bold: weight dropped |
| 1217 | `You` | heading 22 / 600 | section |  |
| 1240 | `NEXT MATCH · CALLED TO COURT` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 1250 | `${next.court}, ${Fmt.time(next.at)}` | heading 26 / 600 / on-fill | title |  |
| 1254 | `vs ${next.opponent} · best of 3 games to` | body 14 / 400 / other | body | keeps its colour |
| 1288 | `The umpire enters each score and it is f` | body 13 / 400 / secondary | caption |  |

**MatchRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1341 | `vs ${m.opponent}` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1347 | `${const [` | body 13 / 400 / secondary | caption |  |
| 1353 | `m.score!` | body 14 / 600 | body | emphasis dropped (body is Regular) |

**TournamentRegisterScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1443 | `${_partner!.player.displayName} has been` | body 15 / 400 / secondary | secondary |  |
| 1484 | `Choose events` | heading 20 / 600 | section |  |
| 1488 | `${picked.length} of ${info.maxEvents}` | body 13 / 400 / secondary | caption |  |
| 1518 | `Doubles partner` | heading 20 / 600 | section |  |
| 1542 | `_partner!.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1546 | `Invite sent when you pay${closes == null` | body 13 / 400 / secondary | caption |  |
| 1561 | `Suggested · players you've played with i` | body 13 / 400 / secondary | caption |  |
| 1569 | `No suggestions yet. Ask your partner to ` | body 14 / 400 / secondary | secondary |  |
| 1590 | `p.player.displayName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1594 | `p.meta` | body 13 / 400 / secondary | caption |  |
| 1617 | `Eligibility` | heading 20 / 600 | section |  |
| 1657 | `Total` | heading 18 / 600 | section |  |
| 1661 | `S\$${money(entry + fee)}` | heading 18 / 600 | section |  |
| 1677 | `Free to enter. Withdraw any time before ` | body 13 / 400 / secondary | caption |  |

**TournamentWithdrawScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1748 | `S\$${money(back)} refunded` | heading 24 / 600 | title |  |
| 1756 | `It goes back to how you paid.` | body 15 / 400 / secondary | secondary |  |
| 1807 | `Why are you withdrawing?` | heading 20 / 600 | section |  |
| 1835 | `injury` | body 14 / 400 / secondary | secondary |  |
| 1849 | `${mine.partner!.displayName.split(` | body 14 / 400 / secondary | secondary |  |

**TournamentResultsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1890 | `result.podium[place - 1]` | body 13 / 600 | caption | caption turns grey; weight dropped |
| 1904 | `$place` | heading 28 / 600 | score |  |
| 1938 | `You finished ${result.place < ord.length` | heading 22 / 600 / status | section |  |
| 1945 | `${result.wins} ${result.wins == 1 ?` | body 14 / 400 / status | body | keeps status colour |
| 1950 | `Your matches` | heading 20 / 600 | section |  |

### `lib/features/profile/presentation/passport_history_screen.dart`

**PassportHistoryScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 77 | `${sport.label} rating` | body 12 / 600 / accent | caption | was 12; caption is 13; weight dropped |
| 93 | `—` | display 48 / 600 / on-fill | title | hero text 48 → 20; may want its own role |
| 101 | `SkillBand.forLevel(level).label` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 115 | `Your level settles after 5 confirmed mat` | body 13 / 400 / on-fill | caption |  |
| 166 | `value` | heading 22 / 600 | score |  |
| 167 | `label` | body 13 / 400 / secondary | caption |  |
| 189 | `No ${sport.label.toLowerCase()} sessions` | body 14 / 400 / secondary | secondary |  |

### `lib/features/profile/presentation/passport_screen.dart`

**PassportScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 186 | `text` | display 20 / 600 / primary | section |  |
| 190 | `trailing` | body 14 / 400 / secondary | secondary |  |
| 241 | `label` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 242 | `value` | display 20 / 600 / primary | section |  |
| 271 | `W` | display 17 / 600 / on-fill | section |  |
| 305 | `Play your first ranked match to start yo` | body 15 / 400 / secondary | secondary |  |
| 347 | `${level.playMin.toStringAsFixed(1)} to $` | body 14 / 400 / secondary | secondary |  |
| 373 | `NEXT UP · TUE 13 OCT · 7:30 PM` | body 12 / 600 / accent | caption | was 12; caption is 13; weight dropped |
| 383 | `DemoPassport.upcoming.first.title` | body 17 / 600 / on-fill | section |  |
| 391 | `DemoPassport.upcoming.first.place` | body 14 / 400 / secondary | secondary |  |
| 432 | `card.label` | body 13 / 400 / secondary | caption |  |
| 436 | `card.value` | display 26 / 600 / primary | score |  |
| 444 | `card.note` | body 13 / 400 / secondary | caption |  |
| 474 | `label` | body 15 / 600 / primary | body | emphasis dropped (body is Regular) |
| 481 | `$pct%` | display 18 / 600 / primary | section |  |
| 519 | `Your ${sport.label.toLowerCase()} gear` | display 20 / 600 / primary | section |  |
| 523 | `Tap an item for details.` | body 14 / 400 / secondary | secondary |  |
| 544 | `Add your racquet, shoes and strings to t` | body 15 / 400 / secondary | secondary |  |
| 584 | `g.name` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |
| 593 | `g.type` | body 13 / 400 / secondary | caption |  |
| 613 | `t` | body 12 / 600 / primary | caption | was 12; caption is 13; caption turns grey; weight dropped |
| 644 | `g.price!` | display 20 / 600 / primary | section |  |
| 672 | `No games coming up. Join a Meet and it s` | body 15 / 400 / secondary | secondary |  |
| 694 | `g.when` | body 13 / 600 / link | caption | orange accent text, not a link: keeps its colour |
| 702 | `g.title` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |
| 708 | `g.place` | body 14 / 400 / secondary | secondary |  |
| 726 | `Waitlist` | body 13 / 600 / on-fill | caption | weight dropped |
| 766 | `Challenges are for creators` | display 22 / 600 / primary | title |  |
| 771 | `Reach 1,000 followers to set challenges ` | body 15 / 400 / secondary | secondary |  |
| 792 | `$followers followers` | body 14 / 600 / primary | body | emphasis dropped (body is Regular) |
| 801 | `1,000 to unlock` | body 14 / 400 / secondary | secondary |  |

**Hero**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 929 | `first` | display 54 / 600 / on-fill | title | hero text 54 → 20; may want its own role |
| 946 | `DOUBLES · LEVEL ${level!.toStringAsFixed` | body 13 / 600 / other | caption | weight dropped |

**InfoCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1035 | `` | display 24 / 600 / primary | title |  |
| 1044 | `country` | body 15 / 400 / secondary | secondary |  |
| 1070 | `label` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1073 | `value` | display 19 / 600 / primary | section |  |

**NavHeader**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1174 | `s.label` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 1226 | `t` | body 15 / 600 / secondary | secondary | grey and bold: weight dropped |

**LevelPainter**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1301 | `` | display 14 / 600 / primary | section |  |
| 1308 | `` | body 11 / 400 / secondary | caption | was 11; caption is 13 |
| 1314 | `` | body 11 / 400 / secondary | caption | was 11; caption is 13 |

**WinRatePainter**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1413 | `` | body 11 / 400 / secondary | caption | was 11; caption is 13 |
| 1483 | `` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped; weight switches: i == selected ? FontWeight.w600 : FontWe |
| 1515 | `` | body 13 / 600 / primary | caption | caption turns grey; weight dropped |
| 1535 | `text: a` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1539 | `text: b` | body 12 / 600 / primary | caption | was 12; caption is 13; caption turns grey; weight dropped |

### `lib/features/profile/presentation/profile_screen.dart`

**ProfileScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 110 | `` | heading 24 / 600 | title |  |
| 116 | `handle` | body 14 / 400 / secondary | secondary |  |
| 163 | `wallet.minor)} points'` | body 16 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 175 | `Earn points by playing` | body 13 / 400 / other | caption |  |
| 185 | `Use points` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |
| 200 | `${summary.badgeCount} earned` | body 13 / 400 / secondary | caption |  |

**Section**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 385 | `title` | display 18 / 600 / primary | section |  |

**ListRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 433 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 435 | `subtitle` | body 13 / 400 / secondary | caption |  |
| 443 | `value!` | body 14 / 600 / other | body | emphasis dropped (body is Regular); keeps its colour |

**PassportCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 495 | `big` | heading 20 / 600 / on-fill | section |  |
| 497 | `small` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 520 | `PASSPORT · ${label.toUpperCase()}` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |
| 539 | `MAIN SPORT` | body 11 / 600 / other | caption | was 11; caption is 13; weight dropped |
| 555 | `sport.level.toStringAsFixed(1)` | heading 44 / 600 / on-fill | score |  |
| 561 | `${band.label} · ${band.code}` | body 16 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 598 | `See leaderboards` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

**BadgeTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 646 | `badge.name` | body 12 / 600 | caption | was 12; caption is 13; caption turns grey; weight dropped |

### `lib/features/safety/presentation/legal_screens.dart`

**Under18ProtectionScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 269 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 270 | `sub` | body 13 / 400 / secondary | caption |  |

**LegalNoticeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 582 | `I am` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 602 | `Country` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 620 | `What is it?` | heading 24 / 600 | title |  |
| 646 | `We use these details only to handle this` | body 13 / 400 / secondary | caption |  |

### `lib/features/safety/presentation/safety_screens.dart`

**MyReportsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 123 | `Nothing reported yet. Use Report on a me` | body 14 / 400 / secondary | secondary |  |

**ReportStatusScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 249 | `r.heading` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 251 | `r.detail` | body 13 / 400 / secondary | caption |  |
| 255 | `Reported for: ${r.reason.toLowerCase()}` | body 13 / 400 / secondary | caption |  |
| 287 | `r.result!` | body 15 / 400 | body |  |

**Step**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 339 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 340 | `line` | body 13 / 400 / secondary | caption |  |

**RemovalNoticeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 439 | `We removed a message you posted. Nobody ` | body 14 / 400 / status | body | keeps status colour |
| 452 | `n.why` | body 15 / 400 | body |  |

### `lib/features/scan/host_scan_screen.dart`

**HostScanScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 89 | `$_present here so far. Point the camera ` | body 15 / 400 / secondary | secondary |  |

### `lib/features/scan/scan_player_screen.dart`

**ScanPlayerScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 81 | `detail.player.displayName` | display 26 / 600 / primary | title |  |
| 85 | `detail.player.handle` | body 15 / 400 / secondary | secondary |  |
| 105 | `${Sport.fromId(s.sport).label} ${s.level` | body 14 / 600 / primary | body | emphasis dropped (body is Regular) |

### `lib/features/scan/scan_screen.dart`

**ScanScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 178 | `Scan` | display 19 / 600 / on-fill | section |  |

**ModeSwitch**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 259 | `label` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

**Scanner**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 358 | `Point at an Olympus QR code` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 368 | `Demo: tap a row below to see a result` | body 13 / 400 / secondary | caption |  |
| 414 | `${i + 1}` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |
| 429 | `uses[i].$1` | body 14 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 438 | `uses[i].$2` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**ParentScansIfNeeded**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 469 | `Ask a parent to scan for you. Hosts can ` | body 15 / 400 / secondary | secondary |  |

**MyCode**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 524 | `profile?.fullName ?? username` | heading 19 / 600 / other | section |  |
| 529 | `@$username` | body 13 / 400 / other | caption |  |
| 541 | `Show this at an event door, to an organi` | body 14 / 400 / secondary | secondary |  |
| 560 | `My tickets · $tickets` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |

### `lib/features/services/presentation/services_screen.dart`

**ServicesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 48 | `None are open yet.` | body 14 / 400 / secondary | secondary |  |

**PartnerCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 117 | `p.name` | body 16 / 600 | body | emphasis dropped (body is Regular) |
| 119 | `p.area` | body 13 / 400 / secondary | caption |  |
| 122 | `p.blurb` | body 14 / 400 | body |  |

### `lib/features/settings/presentation/account_screens.dart`

**AccountHubScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 88 | `value` | body 13 / 400 / secondary | caption |  |
| 104 | `title` | heading 20 / 600 | section |  |
| 115 | `Opened with Face ID. You are asked again` | body 14 / 400 / secondary | secondary |  |

**ProfileSportsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 293 | `Level for ${Sport.fromId(s.sport).label}` | heading 22 / 600 | section |  |
| 345 | `No sports yet. Add one below.` | body 14 / 400 / secondary | secondary |  |
| 364 | `Add a sport` | heading 20 / 600 | section |  |
| 389 | `You choose your own level. Your rating i` | body 13 / 400 / secondary | caption |  |

**LanguageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 448 | `More languages are being translated.` | body 13 / 400 / secondary | caption |  |

**DeleteAccountScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 477 | `Delete your account?` | heading 24 / 600 | title |  |
| 483 | `Your upcoming Meets and lessons are refu` | body 15 / 400 / secondary | secondary |  |
| 555 | `You can still change your mind` | heading 22 / 600 | section |  |
| 561 | `Log in before ${Fmt.day(closingUntil)} t` | body 15 / 400 / secondary | secondary |  |
| 583 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 585 | `body` | body 13 / 400 / other | caption |  |
| 629 | `What happens` | heading 20 / 600 | section |  |
| 637 | `Why are you leaving? (optional)` | heading 20 / 600 | section |  |

**AccountClosingScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 698 | `OlympusGO` | h1 34 / 600 / primary | title |  |
| 707 | `It is erased soon unless you keep it. Un` | lead 16 / 400 / secondary | secondary | intro paragraph |

**IdentityCheckScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 752 | `Your identity is checked. You can run pa` | body 14 / 400 / status | body | keeps status colour |

### `lib/features/settings/presentation/settings_screens.dart`

**SettingsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 129 | `Log out` | body 16 / 600 / link | button | link |

**DetailRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 489 | `label` | body 13 / 400 / secondary | caption |  |
| 502 | `` | body 16 / 600 / secondary | secondary | grey and bold: weight dropped; weight switches: empty ? FontWeight.w400 : FontWeight.w60 |

**AccountInfoScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 653 | `` | body 14 / 400 / secondary | secondary |  |

**ReadOnlyField**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 766 | `value` | input 18 / 400 / secondary | body | typed text in fields; 18 → 15 |

**NotificationsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 846 | `Changes save as you go.` | body 14 / 400 / secondary | secondary |  |

**PrivacyScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 879 | `Who can see my profile` | label 14 / 600 | caption | field label |
| 960 | `Changes save as you go.` | body 14 / 400 / secondary | secondary |  |

**BlockedPlayersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 990 | `You haven't blocked anyone.` | body 16 / 400 / secondary | secondary |  |

**HelpScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1134 | `_faqs[i].$1` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |
| 1164 | `_faqs[i].$2` | body 15 / 400 / secondary | secondary |  |
| 1181 | `No answers match. Contact support below.` | body 15 / 400 / secondary | secondary |  |

**SupportSheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1248 | `Contact support` | section 22 / 600 / primary | section |  |

**LogOutScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1314 | `Log out?` | h1 34 / 600 / primary | title |  |
| 1321 | `You can log back in with your email, mob` | lead 16 / 400 / secondary | secondary | intro paragraph |

### `lib/features/shell/main_shell.dart`

**TabButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 183 | `9+` | body 10 / 600 / on-fill | caption | was 10; caption is 13; weight dropped |
| 197 | `label` | body 12 / 600 / other | caption | was 12; caption is 13; weight dropped |

**ScanButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 263 | `Scan` | body 12 / 600 / secondary | caption | was 12; caption is 13; grey and bold: weight dropped |

### `lib/features/shell/tab_page.dart`

**TabTitle**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 74 | `text` | h1 34 / 600 / primary | title |  |

**SectionTitle**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 91 | `text` | section 22 / 600 / primary | section |  |

### `lib/features/shell/tab_widgets.dart`

**MeetCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 46 | `when` | body 13 / 600 / link | caption | orange accent text, not a link: keeps its colour |
| 51 | `name` | body 17 / 600 / primary | section |  |
| 59 | `venue` | body 14 / 400 / secondary | secondary |  |
| 64 | `spots` | body 14 / 600 / primary | body | emphasis dropped (body is Regular) |

**CategoryRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 130 | `title` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |
| 136 | `subtitle` | body 14 / 400 / secondary | secondary |  |

**SmallPillButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 186 | `label` | display 15 / 600 / on-fill | section |  |

### `lib/features/shop/presentation/order_screens.dart`

**CartScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 66 | `Your cart is empty` | heading 20 / 600 | section |  |
| 70 | `Items you add from a product page wait h` | body 14 / 400 / secondary | secondary |  |
| 88 | `e.value.first.product.mallName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 110 | `l.product.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 115 | `l.variant` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 119 | `cash(l.product.priceCents)` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 145 | `Set an item to 0 to remove it. Each shop` | body 13 / 400 / secondary | caption |  |

**CheckoutScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 359 | `${cash(o.totalCents)} paid. ${o.mallName` | body 15 / 400 / secondary | secondary |  |
| 414 | `cash(q.totalCents)` | heading 22 / 600 | score |  |
| 417 | `Final price` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 451 | `Collect from $mallName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 455 | `q.collectAddress` | body 13 / 400 / secondary | caption |  |
| 490 | `Use a voucher` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 494 | `One discount per item: a voucher or poin` | body 13 / 400 / secondary | caption |  |
| 535 | `q.refundRule` | body 13 / 400 / secondary | caption |  |

**OrdersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 597 | `Nothing here. Orders in this step show u` | body 14 / 400 / secondary | secondary |  |

**OrderCard**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 645 | `o.mallName` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 656 | `o.summary` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 664 | `Drop off ${Fmt.dayTimeComma(o.slotAt!)}` | body 13 / 400 / secondary | caption |  |
| 667 | `cash(amount ?? o.totalCents)` | heading 18 / 600 | section |  |

**OrderDetailScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 712 | `Got everything?` | heading 24 / 600 | title |  |
| 717 | `OlympusGO pays the shop now, and sports ` | body 15 / 400 / secondary | secondary |  |
| 896 | `o.mallName` | heading 20 / 600 | section |  |
| 954 | `Your payment goes to the shop when you t` | body 13 / 400 / secondary | caption |  |

**OrderCancelScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1106 | `` | body 15 / 400 / secondary | secondary |  |
| 1141 | `Why are you cancelling?` | heading 20 / 600 | section |  |
| 1160 | `You can cancel free until you collect. T` | body 13 / 400 / secondary | caption |  |

**MoneyLine**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1189 | `title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1190 | `sub` | body 13 / 400 / secondary | caption |  |
| 1194 | `amount` | heading 18 / 600 | section |  |

**RefundStatusScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1268 | `${i + 1}` | body 12 / 600 / on-fill | caption | was 12; caption is 13; weight dropped |
| 1282 | `title` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 1287 | `sub` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 1310 | `Card and PayNow refunds depend on your b` | body 13 / 400 / secondary | caption |  |

**ReportListingScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1393 | `Thank you. We review every report within` | body 15 / 400 / secondary | secondary |  |
| 1412 | `What is wrong with it?` | heading 20 / 600 | section |  |
| 1415 | `Reports are private. The shop is not tol` | body 13 / 400 / secondary | caption |  |

**WriteReviewScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1522 | `Thanks. Reviews from players at your lev` | body 15 / 400 / secondary | secondary |  |
| 1563 | `o.summary` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 1567 | `o.mallName` | body 13 / 400 / secondary | caption |  |
| 1594 | `_words[_stars]` | heading 24 / 600 | title |  |
| 1597 | `What stood out?` | heading 20 / 600 | section |  |

### `lib/features/shop/presentation/owner_screens.dart`

**OwnerOrdersScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 69 | `Nothing here. New orders show up as soon` | body 14 / 400 / secondary | secondary |  |

**OwnerOrderScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 125 | `Cancel this order?` | heading 24 / 600 | title |  |
| 130 | `The buyer gets everything back, and the ` | body 15 / 400 / secondary | secondary |  |
| 246 | `Points a buyer uses never change what yo` | body 13 / 400 / secondary | caption |  |

### `lib/features/shop/presentation/shop_screens.dart`

**ProductTile**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 170 | `p.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 175 | `cash(p.priceCents)` | heading 16 / 600 | section |  |
| 182 | `cash(p.oldPriceCents!)` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 192 | `p.soldLine` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**BuySheet**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 318 | `cash(price * _qty)` | heading 22 / 600 | score |  |
| 321 | `p.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 326 | `_variant` | body 13 / 400 / secondary | caption |  |
| 335 | `g.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 356 | `Quantity` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**ShopHomeScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 442 | `Nothing matches. Try a product type, a b` | body 14 / 400 / secondary | secondary |  |
| 458 | `Flash deals` | heading 20 / 600 | section |  |
| 473 | `For you` | heading 20 / 600 | section |  |
| 531 | `m.name` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 538 | `m.blurb` | body 13 / 400 / secondary | caption |  |

**MallPageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 592 | `big` | heading 18 / 600 | section |  |
| 593 | `small` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 615 | `m.name` | heading 22 / 600 | section |  |
| 629 | `d.about` | body 13 / 400 / secondary | caption |  |

**ProductPageScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 787 | `cash(p.priceCents)` | heading 30 / 600 | score |  |
| 792 | `cash(p.oldPriceCents!)` | body 15 / 400 / secondary | secondary |  |
| 807 | `value.headline` | heading 20 / 600 | section |  |
| 814 | `New in the Shop` | body 14 / 400 / secondary | secondary |  |
| 830 | `points)}.'` | body 14 / 600 / status | body | emphasis dropped (body is Regular); keeps status colour |
| 840 | `value.collectLine` | body 14 / 400 / secondary | secondary |  |
| 855 | `About this item` | heading 20 / 600 | section |  |
| 859 | `Reviews` | heading 20 / 600 | section |  |
| 862 | `All ${compact(value.ratings)}` | body 13 / 400 / secondary | caption |  |
| 883 | `r.name` | body 14 / 600 | body | emphasis dropped (body is Regular) |
| 885 | `r.meta` | body 12 / 400 / secondary | caption | was 12; caption is 13 |
| 887 | `r.text` | body 14 / 400 | body |  |
| 904 | `Goes well with` | heading 20 / 600 | section |  |

**ServiceBookScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 997 | `p.name` | heading 20 / 600 | section |  |
| 1000 | `${p.mallName} · ${p.rating.toStringAsFix` | body 13 / 400 / secondary | caption |  |
| 1007 | `String tension` | heading 18 / 600 | section |  |
| 1020 | `Drop-off day` | heading 18 / 600 | section |  |
| 1033 | `Drop-off time` | heading 18 / 600 | section |  |
| 1054 | `Pay now. OlympusGO holds your payment un` | body 13 / 400 / secondary | caption |  |

**ShopEmpty**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1070 | `text` | body 14 / 400 / secondary | secondary |  |

### `lib/features/social/presentation/chat_screen.dart`

**ChatScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 181 | `` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |
| 189 | `` | body 13 / 400 / secondary | caption |  |
| 219 | `Say hi to ${partner?.displayName ??` | body 15 / 400 / secondary | secondary |  |
| 251 | `_dayLabel(m.createdAt)` | body 13 / 400 / secondary | caption |  |
| 268 | `Can't load messages.` | body 15 / 400 / secondary | secondary |  |
| 285 | `` | body 16 / 400 / primary | body |  |
| 289 | `Message` | body 16 / 400 / secondary | secondary |  |

**PendingBubble**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 397 | `Not sent. Tap to try again.` | body 13 / 400 / status | caption |  |

**Bubble**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 438 | `message.body` | body 16 / 400 / on-fill | body | keeps its colour |

### `lib/features/social/presentation/connections_screens.dart`

**ConnectionsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 106 | `Follow players to see their games and Pa` | body 16 / 400 / secondary | secondary |  |

**ShareProfileScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 164 | `` | display 26 / 600 / primary | title |  |
| 167 | `@$username` | body 15 / 400 / secondary | secondary |  |
| 190 | `Profile link` | label 14 / 600 | caption | field label |
| 213 | `link` | body 16 / 400 / primary | body |  |

**SavedScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 330 | `text` | body 16 / 400 / secondary | secondary |  |

### `lib/features/social/presentation/other_profile_screens.dart`

**OtherProfileScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 36 | `value` | display 22 / 600 / primary | score |  |
| 37 | `label` | body 13 / 400 / secondary | caption |  |
| 66 | `This profile isn't available.` | lead 16 / 400 / secondary | secondary | intro paragraph |
| 108 | `p.displayName` | display 28 / 600 / primary | title |  |
| 114 | `·` | body 15 / 400 / secondary | secondary |  |
| 158 | `d.bio!` | body 15 / 400 / primary | body |  |
| 173 | `Sport.fromId(s.sport).label` | body 16 / 600 / primary | body | emphasis dropped (body is Regular) |
| 184 | `Level ${s.level.toStringAsFixed(1)}` | body 16 / 400 / secondary | secondary |  |

### `lib/features/social/presentation/search_screens.dart`

**SearchResultsScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 238 | `No players match "$_query".` | body 15 / 400 / secondary | secondary |  |
| 289 | `No Meets match "$_query".` | body 15 / 400 / secondary | secondary |  |
| 322 | `Club search arrives with Clubs.` | body 15 / 400 / secondary | secondary |  |

**OpenChatScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 378 | `_error!` | lead 16 / 400 / secondary | secondary | intro paragraph |

### `lib/features/venues/presentation/venue_screens.dart`

**VenuesScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 178 | `Venue` | heading 44 / 600 / on-fill | title | hero text 44 → 20; may want its own role |
| 268 | `No venues match` | heading 24 / 600 | title |  |
| 272 | `Check the spelling or try an area name.` | body 14 / 400 / secondary | secondary |  |

**VenueRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 338 | `v.mark` | heading 40 / 600 / other | monogram | initials or logo letters at 40: no role fits |
| 363 | `v.name` | body 17 / 600 | section |  |
| 371 | `·` | body 13 / 400 / secondary | caption |  |
| 380 | `From ${_price(from)} / hour` | body 14 / 600 / link | body | orange accent text, not a link: keeps its colour |

**VenuePage**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 437 | `text` | heading 22 / 600 | section |  |
| 463 | `v.mark` | heading 56 / 600 / other | monogram | initials or logo letters at 56: no role fits |
| 478 | `v.name` | heading 32 / 600 | title |  |
| 487 | `Open ${_hour(v.opensHour)} to ${_hour(v.` | body 13 / 400 / secondary | caption |  |

**OnHereRow**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 598 | `a.title` | body 15 / 600 | body | emphasis dropped (body is Regular) |
| 603 | `·` | body 13 / 400 / secondary | caption |  |
| 609 | `trailing` | body 15 / 600 | body | emphasis dropped (body is Regular) |

**BookCourt**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 756 | `${done.sport.label}, ${done.court}` | heading 26 / 600 | title |  |
| 762 | `${_dayLabel(_day)}, ${Fmt.timeRange(done` | body 15 / 400 / secondary | secondary |  |
| 777 | `text` | heading 22 / 600 | section |  |
| 856 | `Nothing left to book on this day. Try an` | body 14 / 400 / secondary | secondary |  |

**SlotButton**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 947 | `time` | body 15 / 600 / on-fill | body | emphasis dropped (body is Regular); keeps its colour |
| 957 | `sub` | body 12 / 400 / secondary | caption | was 12; caption is 13 |

**CourtBookingScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1049 | `` | heading 64 / 600 | title | hero text 64 → 20; may want its own role |
| 1059 | `Door code for ${b.court}, works from 10 ` | body 13 / 400 / secondary | caption |  |
| 1065 | `b.venueName` | heading 24 / 600 | title |  |
| 1071 | `${Fmt.day(b.start)}, ${Fmt.timeRange(b.s` | body 13 / 400 / secondary | caption |  |

**CancelCourtBookingScreen**

| Line | Text | Before | After | Note |
| --- | --- | --- | --- | --- |
| 1167 | `S\$${money(refunded)} refunded` | heading 26 / 600 | title |  |
| 1176 | `It was inside 24 hours, so the venue kee` | body 15 / 400 / secondary | secondary |  |
| 1229 | `The S\$${money(b.feeCents)} platform fee` | body 14 / 400 / secondary | secondary |  |

## Raw sizes, weights and `TextStyle(` outside a type helper

These must go for step 5 to pass. Most pass a size into a shared widget.

| File | Screen | Line | Code |
| --- | --- | --- | --- |
| `lib/core/widgets/og_fields.dart` | top level | 53 | `TextStyle(` |
| `lib/core/widgets/og_fields.dart` | top level | 53 | `fontSize: 0` |
| `lib/core/widgets/og_kit.dart` | KitTextArea | 1707 | `fontSize: 15` |
| `lib/core/widgets/phone_field.dart` | PhoneField | 58 | `fontWeight: FontWeight.w600` |
| `lib/features/academy/presentation/academy_admin_screens.dart` | AcademyCoachesScreen | 435 | `fontSize: 14` |
| `lib/features/academy/presentation/academy_more_screens.dart` | AcademySettingsScreen | 111 | `fontSize: 11` |
| `lib/features/academy/presentation/academy_more_screens.dart` | AcademyMessagesScreen | 320 | `fontSize: 15` |
| `lib/features/academy/presentation/academy_more_screens.dart` | ChangeClassScreen | 645 | `fontSize: 14` |
| `lib/features/academy/presentation/academy_more_screens.dart` | CurriculumScreen | 893 | `fontSize: 12` |
| `lib/features/academy/presentation/academy_more_screens.dart` | CurriculumScreen | 914 | `fontSize: 10` |
| `lib/features/academy/presentation/academy_more_screens.dart` | CurriculumScreen | 984 | `fontSize: 11` |
| `lib/features/academy/presentation/academy_more_screens.dart` | ParentNoteScreen | 1650 | `fontSize: 16` |
| `lib/features/academy/presentation/academy_more_screens.dart` | ParentNoteScreen | 1670 | `fontSize: 13` |
| `lib/features/academy/presentation/academy_more_screens.dart` | FilmingConsentScreen | 1805 | `fontSize: 16` |
| `lib/features/academy/presentation/academy_screens.dart` | AcademiesScreen | 239 | `fontSize: 15` |
| `lib/features/academy/presentation/academy_screens.dart` | AcademyRow | 353 | `fontSize: 11` |
| `lib/features/academy/presentation/academy_screens.dart` | AcademyPageScreen | 500 | `fontSize: 11` |
| `lib/features/academy/presentation/academy_screens.dart` | AcademyPageScreen | 646 | `fontSize: 11` |
| `lib/features/academy/presentation/academy_screens.dart` | AcademyPageScreen | 711 | `fontSize: 14` |
| `lib/features/academy/presentation/academy_screens.dart` | AcademyPageScreen | 740 | `fontSize: 11` |
| `lib/features/academy/presentation/coach_screens.dart` | AcademyClassesScreen | 388 | `fontSize: 11` |
| `lib/features/academy/presentation/coach_screens.dart` | ClassSessionScreen | 590 | `fontSize: 13` |
| `lib/features/academy/presentation/coach_screens.dart` | ClassSessionScreen | 618 | `fontSize: 12` |
| `lib/features/academy/presentation/coach_screens.dart` | ClassSessionScreen | 627 | `fontSize: 13` |
| `lib/features/academy/presentation/coach_screens.dart` | ClassRosterScreen | 714 | `fontSize: 14` |
| `lib/features/academy/presentation/coach_screens.dart` | EnrolRequestsScreen | 810 | `fontSize: 14` |
| `lib/features/academy/presentation/coach_screens.dart` | EnrolRequestsScreen | 852 | `fontSize: 15` |
| `lib/features/academy/presentation/coach_screens.dart` | EnrolRequestsScreen | 862 | `fontSize: 15` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 144 | `fontSize: 15` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 188 | `fontSize: 14` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 198 | `fontSize: 14` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 241 | `fontSize: 11` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 303 | `fontSize: 15` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 320 | `fontSize: 12` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 348 | `fontSize: 11` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 354 | `fontSize: 11` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentHome | 362 | `fontSize: 11` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentClassScreen | 524 | `fontSize: 11` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentClassScreen | 532 | `fontSize: 11` |
| `lib/features/academy/presentation/parent_screens.dart` | BookMakeupScreen | 826 | `fontSize: 11` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentProgressScreen | 927 | `fontSize: 18` |
| `lib/features/academy/presentation/parent_screens.dart` | StudentProgressScreen | 1033 | `fontSize: 12` |
| `lib/features/auth/presentation/splash_screen.dart` | SplashScreen | 79 | `TextStyle(` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | ClubMembersScreen | 348 | `fontSize: 14` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | ClubMemberScreen | 513 | `fontSize: 22` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | JoinRequestsScreen | 783 | `fontSize: 15` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | AuditLogScreen | 940 | `TextStyle(` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | AuditLogScreen | 941 | `fontWeight: FontWeight.w600` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | ClubBansScreen | 1041 | `fontSize: 14` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | ClubBansScreen | 1069 | `fontSize: 14` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | ClubInviteScreen | 1243 | `fontSize: 14` |
| `lib/features/clubs/presentation/club_admin_screens.dart` | ClubTransferScreen | 1348 | `fontSize: 14` |
| `lib/features/clubs/presentation/club_info_screens.dart` | ClubAboutScreen | 108 | `fontSize: 24` |
| `lib/features/clubs/presentation/club_overview_screen.dart` | ClubOverviewScreen | 167 | `fontSize: 13` |
| `lib/features/clubs/presentation/club_overview_screen.dart` | ClubOverviewScreen | 345 | `fontSize: 15` |
| `lib/features/clubs/presentation/club_page_screen.dart` | MemberClubPage | 404 | `fontSize: 15` |
| `lib/features/clubs/presentation/club_page_screen.dart` | ClubCard | 592 | `fontSize: 32` |
| `lib/features/clubs/presentation/club_page_screen.dart` | PrivateClubPage | 1137 | `fontSize: 30` |
| `lib/features/clubs/presentation/club_role_screens.dart` | MemberPicker | 123 | `fontSize: 14` |
| `lib/features/clubs/presentation/club_role_screens.dart` | RoleMembersScreen | 879 | `fontSize: 14` |
| `lib/features/clubs/presentation/club_widgets.dart` | ClubMark | 53 | `fontSize: fontSize` |
| `lib/features/clubs/presentation/club_widgets.dart` | TeamMark | 80 | `fontSize: fontSize` |
| `lib/features/clubs/presentation/clubs_home_screen.dart` | ClubRow | 449 | `fontSize: 22` |
| `lib/features/clubs/presentation/clubs_home_screen.dart` | ClubRow | 474 | `fontSize: 11` |
| `lib/features/clubs/presentation/clubs_home_screen.dart` | TeamRow | 525 | `fontSize: 22` |
| `lib/features/clubs/presentation/create_group_screens.dart` | SportCard | 520 | `fontSize: 11` |
| `lib/features/clubs/presentation/create_group_screens.dart` | PersonRow | 788 | `fontSize: 14` |
| `lib/features/clubs/presentation/group_chat_screens.dart` | GroupChatScreen | 200 | `fontSize: 15` |
| `lib/features/clubs/presentation/group_chat_screens.dart` | GroupChatScreen | 249 | `fontSize: 18` |
| `lib/features/clubs/presentation/group_chat_screens.dart` | MeetBubble | 748 | `fontSize: 14` |
| `lib/features/clubs/presentation/group_chat_screens.dart` | ReportContentScreen | 1506 | `fontSize: 14` |
| `lib/features/clubs/presentation/team_screens.dart` | TeamOverviewScreen | 649 | `fontSize: 14` |
| `lib/features/clubs/presentation/team_screens.dart` | TeamRosterScreen | 766 | `fontSize: 14` |
| `lib/features/clubs/presentation/team_screens.dart` | TeamRosterScreen | 786 | `fontSize: 10` |
| `lib/features/clubs/presentation/team_screens.dart` | TeamAddPlayersScreen | 1051 | `fontSize: 13` |
| `lib/features/clubs/presentation/team_screens.dart` | TeamAddPlayersScreen | 1136 | `fontSize: 14` |
| `lib/features/clubs/presentation/team_screens.dart` | EditLineupScreen | 1407 | `fontSize: 14` |
| `lib/features/earnings/presentation/earnings_screens.dart` | PointsWalletScreen | 193 | `TextStyle(` |
| `lib/features/earnings/presentation/earnings_screens.dart` | PointsWalletScreen | 193 | `fontWeight: FontWeight.w600` |
| `lib/features/game/presentation/creator_screens.dart` | CreatorProfileScreen | 57 | `fontSize: 24` |
| `lib/features/game/presentation/game_screens.dart` | StandingRow | 50 | `fontSize: 13` |
| `lib/features/game/presentation/game_screens.dart` | LeaderboardsScreen | 1051 | `fontSize: i` |
| `lib/features/home/home_rows.dart` | ClubTile | 417 | `fontSize: 11` |
| `lib/features/home/home_rows.dart` | ClubTile | 468 | `fontSize: 8` |
| `lib/features/home/home_rows.dart` | PlayerTile | 561 | `fontSize: 18` |
| `lib/features/home/home_rows.dart` | MallShelf | 708 | `fontSize: 11` |
| `lib/features/home/home_rows.dart` | ProductShelf | 790 | `fontSize: 11` |
| `lib/features/home/home_screen.dart` | Hero | 198 | `fontSize: 12` |
| `lib/features/inbox/presentation/inbox_screen.dart` | InboxScreen | 103 | `fontSize: 14` |
| `lib/features/play/presentation/create_competition_screens.dart` | NewTournamentScreen | 778 | `fontSize: 13` |
| `lib/features/play/presentation/create_meet_screens.dart` | NewMeetDetailsScreen | 564 | `fontSize: 14` |
| `lib/features/play/presentation/create_meet_screens.dart` | NewMeetDetailsScreen | 799 | `fontSize: 13` |
| `lib/features/play/presentation/event_screens.dart` | EventPageScreen | 268 | `fontSize: 11` |
| `lib/features/play/presentation/event_screens.dart` | IdentityCard | 395 | `fontSize: 13` |
| `lib/features/play/presentation/event_screens.dart` | ProgrammeRow | 652 | `fontSize: 12` |
| `lib/features/play/presentation/meet_detail_screen.dart` | MeetPage | 358 | `fontSize: 13` |
| `lib/features/play/presentation/meet_detail_screen.dart` | HostLine | 678 | `fontSize: 10` |
| `lib/features/play/presentation/meet_detail_screen.dart` | HostLine | 685 | `fontSize: 10` |
| `lib/features/play/presentation/meet_detail_screen.dart` | PlayerRow | 947 | `fontSize: 14` |
| `lib/features/play/presentation/meet_host_screens.dart` | MeetWalkInScreen | 288 | `fontSize: 14` |
| `lib/features/play/presentation/meet_host_screens.dart` | MeetAttendanceScreen | 573 | `fontSize: 13` |
| `lib/features/play/presentation/meet_host_screens.dart` | RecapCard | 966 | `fontSize: 14` |
| `lib/features/play/presentation/meet_host_screens.dart` | RecapCard | 980 | `TextStyle(` |
| `lib/features/play/presentation/meet_host_screens.dart` | RecapCard | 982 | `fontWeight: FontWeight.w600` |
| `lib/features/play/presentation/meet_rounds_screen.dart` | MeetRoundsScreen | 168 | `fontSize: 13` |
| `lib/features/play/presentation/play_card.dart` | PlayCard | 178 | `fontSize: 11` |
| `lib/features/play/presentation/play_card.dart` | Proof | 346 | `fontSize: 10` |
| `lib/features/play/presentation/play_screen.dart` | NextSession | 570 | `fontSize: 11` |
| `lib/features/play/presentation/play_screen.dart` | Empty | 640 | `fontSize: 15` |
| `lib/features/play/presentation/play_widgets.dart` | LabeledSelect | 217 | `fontSize: 17` |
| `lib/features/play/presentation/score_screens.dart` | SidesPicker | 880 | `fontSize: 14` |
| `lib/features/play/presentation/tournament_host_screens.dart` | TournamentCheckInScreen | 431 | `fontSize: 14` |
| `lib/features/play/presentation/tournament_host_screens.dart` | TournamentCheckInScreen | 457 | `fontSize: 14` |
| `lib/features/play/presentation/tournament_host_screens.dart` | TournamentCheckInScreen | 467 | `fontSize: 14` |
| `lib/features/play/presentation/tournament_screens.dart` | InviteCard | 691 | `fontSize: 15` |
| `lib/features/play/presentation/tournament_screens.dart` | GroupTable | 1081 | `fontSize: 10` |
| `lib/features/play/presentation/tournament_screens.dart` | TournamentRegisterScreen | 1533 | `fontSize: 14` |
| `lib/features/play/presentation/tournament_screens.dart` | TournamentRegisterScreen | 1581 | `fontSize: 14` |
| `lib/features/play/presentation/tournament_screens.dart` | TournamentRegisterScreen | 1604 | `fontSize: 14` |
| `lib/features/profile/presentation/passport_history_screen.dart` | PassportHistoryScreen | 178 | `fontSize: 13` |
| `lib/features/profile/presentation/passport_screen.dart` | PassportScreen | 340 | `TextStyle(` |
| `lib/features/profile/presentation/passport_screen.dart` | PassportScreen | 342 | `fontWeight: FontWeight.w600` |
| `lib/features/profile/presentation/passport_screen.dart` | PassportScreen | 532 | `fontSize: 15` |
| `lib/features/profile/presentation/passport_screen.dart` | PassportScreen | 651 | `fontSize: 16` |
| `lib/features/profile/presentation/passport_screen.dart` | PassportScreen | 812 | `fontSize: 18` |
| `lib/features/profile/presentation/passport_screen.dart` | InfoCard | 1026 | `fontSize: 22` |
| `lib/features/profile/presentation/profile_screen.dart` | ProfileScreen | 99 | `fontSize: 26` |
| `lib/features/profile/presentation/profile_screen.dart` | PassportCard | 605 | `TextStyle(` |
| `lib/features/profile/presentation/profile_screen.dart` | BadgeTile | 640 | `fontSize: 14` |
| `lib/features/scan/scan_player_screen.dart` | ScanPlayerScreen | 76 | `fontSize: 34` |
| `lib/features/scan/scan_player_screen.dart` | ScanPlayerScreen | 133 | `fontSize: 18` |
| `lib/features/scan/scan_player_screen.dart` | ScanPlayerScreen | 140 | `fontSize: 18` |
| `lib/features/settings/presentation/account_screens.dart` | AccountHubScreen | 95 | `fontSize: 11` |
| `lib/features/settings/presentation/settings_screens.dart` | EditProfileScreen | 302 | `fontSize: 28` |
| `lib/features/settings/presentation/settings_screens.dart` | BlockedPlayersScreen | 1007 | `fontSize: 15` |
| `lib/features/settings/presentation/settings_screens.dart` | HelpScreen | 1198 | `fontSize: 18` |
| `lib/features/settings/presentation/settings_screens.dart` | LogOutScreen | 1330 | `fontSize: 18` |
| `lib/features/shop/presentation/shop_screens.dart` | ProductTile | 146 | `fontSize: 11` |
| `lib/features/shop/presentation/shop_screens.dart` | ProductTile | 158 | `fontSize: 11` |
| `lib/features/shop/presentation/shop_screens.dart` | ProductTile | 199 | `fontSize: 11` |
| `lib/features/shop/presentation/shop_screens.dart` | MallPageScreen | 621 | `fontSize: 11` |
| `lib/features/shop/presentation/shop_screens.dart` | ProductPageScreen | 874 | `fontSize: 13` |
| `lib/features/social/presentation/chat_screen.dart` | ChatScreen | 172 | `fontSize: 15` |
| `lib/features/social/presentation/connections_screens.dart` | ShareProfileScreen | 159 | `fontSize: 36` |
| `lib/features/social/presentation/connections_screens.dart` | ShareProfileScreen | 225 | `fontSize: 17` |
| `lib/features/social/presentation/connections_screens.dart` | SavedScreen | 269 | `fontSize: 16` |
| `lib/features/social/presentation/other_profile_screens.dart` | OtherProfileScreen | 99 | `fontSize: 38` |
| `lib/features/social/presentation/other_profile_screens.dart` | OtherProfileScreen | 135 | `fontSize: 18` |
| `lib/features/social/presentation/other_profile_screens.dart` | OtherProfileScreen | 141 | `fontSize: 18` |
| `lib/features/social/presentation/other_profile_screens.dart` | OtherProfileScreen | 150 | `fontSize: 18` |
| `lib/features/social/presentation/other_profile_screens.dart` | ReportBlockScreen | 304 | `fontSize: 18` |
| `lib/main.dart` | top level | 35 | `fontWeight: FontWeight.w600` |

## Decisions and result (9 Nov 2026)

The owner chose: Jost everywhere, with Medium (not Semibold) for score, display, title and section; filled buttons in the darker orange `#C94A00`; a `display` role at 28; a new tertiary grey; screen titles at 20; key-value labels in primary and values in grey; avatar initials sized by the avatar; counters folded into score; Emil Kowalski's design skill added, Stageshow not. Recorded as Q257.

One change from the table above: status tags ("Verified", "Not yet") use caption in their own colour, not the button role, because at 15 they would not fit their 22 px pills. Real chips and filters keep the button role.

Result: every `OgText` call in `lib/` was replaced by a role from `context.type`. There is no `FontWeight.bold`, `w700`, `w800` or `w900`, no `fontSize:` and no `TextStyle(` outside the theme folder. Shared widgets lost their font-size parameters. Where weight carried meaning (a total line, who did something, a chosen month), it now comes from colour.
