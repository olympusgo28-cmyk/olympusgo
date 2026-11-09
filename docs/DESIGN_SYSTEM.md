# Design system

The OlympusGO Design System is the visual standard for every screen (see `OPEN_QUESTIONS.md` Q15). It was published on 12 Oct 2026 as a design-system artifact; this file restates its tokens and rules for Flutter.

**Two canvases, one standard.**

- *OlympusGO Screens* (196 boards) is drawn in this design system. Use it for look and feel.
- *Club Screen Mockup* (324 boards) covers every flow, including academy, admin, venue and payments. Most of its boards use an earlier style (tangerine `#F28500`, Barlow fonts). Use it for layout, copy and behaviour, and render it with the tokens below.

## Tokens

Put these in `packages/ui/lib/tokens.dart` (generated from a `tokens.json` copy, so the design team can update one file). Widgets never use a raw hex value.

### Colour

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `primary` | `#E8590C` | `#C6F432` | The one main action on a screen: button fill, selected chip, progress, active step |
| `onPrimary` | `#FFFFFF` | `#1C1F23` | Label and icon on primary |
| `primaryPressed` | `#C94A00` | `#A9D11A` | Primary while pressed |
| `accent` | `#C6F432` | `#FF7A1A` | Highlights, badges, checks |
| `onAccent` | `#1C1F23` | `#1C1F23` | Text on accent, always charcoal |
| `bg` | `#FFFFFF` | `#14171A` | Screen background |
| `surface` | `#F7F7F4` | `#1C1F23` | Grouped areas and cards on `bg` |
| `surfaceRaised` | `#FFFFFF` | `#262A2F` | Inputs, sheets, cards on `surface` |
| `groupedBg` | `#F3F2EC` | `#14171A` | The page and header behind a grouped settings list (owner, 9 Nov) |
| `groupedSurface` | `#FFFFFF` | `#1C1F23` | Settings groups and the search bar on `groupedBg` |
| `border` | `#D9D9D2` | `#3A4047` | Decorative hairlines only |
| `borderControl` | `#7A8088` | `#7C838B` | Edges of inputs, unselected chips, option rows (at least 3:1) |
| `text` | `#1C1F23` | `#F4F5F2` | Headlines and body |
| `textMuted` | `#5A5F66` | `#A9AFB6` | Helper text, captions, timers |
| `link` | `#C94A00` | `#C6F432` | Text links and small orange text, underlined |
| `focusRing` | `#1C1F23` | `#C6F432` | 3 px outline on focused controls |
| `success` | `#1A7F4B` | `#5AD68F` | Confirmed, approved; always with an icon or word |
| `error` | `#C42B1C` | `#FF8A7A` | Wrong code, failed payment; always with an icon and a sentence |
| `warning` | `#8F4E00` | `#FFC14D` | Needs attention; always with an icon or word |

Brand constants: `orange500 #E8590C`, `orange700 #C94A00`, `orange300 #FF7A1A`, `lime400 #C6F432`, `charcoal900 #1C1F23`, `charcoal950 #14171A`, `white #FFFFFF`.

### Type

Font: **Jost** everywhere, Regular (400) and Medium (500) only (owner, 9 Nov 2026, Q257). There is no Bold and no Semibold. Hierarchy comes from size and colour first, weight last. The roles live once in the theme (`OgType` in `packages/og_design/lib/og_type.dart`); screens use `context.type.<role>` and never set a size or weight.

| Role | Size | Weight | Colour | Use |
| --- | --- | --- | --- | --- |
| `score` | 32 | Medium | primary | Scores, ratings, prices, counters |
| `display` | 28 | Medium | primary | At most one hero headline a screen |
| `title` | 20 | Medium | primary | Screen and app bar titles |
| `section` | 17 | Medium | primary | Card and section headings |
| `groupLabel` | 15 | Medium | secondary | Headers over settings groups ("How you use OlympusGO"). Asked for as Semibold; Medium per Q257 |
| `body` | 15 | Regular | primary | Main text, row labels, list items, typed text |
| `secondary` | 15 | Regular | secondary | Values, meta info |
| `caption` | 13 | Regular | secondary | Helper text, timestamps, section and field labels, status tags |
| `button` | 15 | Regular | per button | Buttons, tabs, chips, links |
| `tertiary` | 15 | Regular | tertiary | Placeholders and disabled text |

Rules:

1. Secondary information goes grey, never bold. At most one emphasised element per row or card, and it stands out by colour.
2. Buttons stand out by fill and shape. Filled buttons use `primarySmall` (`orange700` in light, 4.7:1 with white), because a 15 Regular label does not count as large text.
3. Initials on avatars and logos take the role nearest 40 % of the avatar's size (`OgType.initials`).
4. Text colours: primary `text`, secondary `textMuted`, tertiary `textTertiary` (`#868B92` light, `#737980` dark).

### Spacing, radius, shadow

| Token | Value | Use |
| --- | --- | --- |
| `space1` | 4 | Icon to text |
| `space2` | 8 | Label to field, chip gaps |
| `space3` | 12 | Stacked buttons, list rows |
| `space4` | 16 | Card padding |
| `space6` | 24 | Screen side padding |
| `space8` | 32 | Title block to form |
| `space12` | 48 | Splash and celebration gaps |
| `radiusSm` | 8 | Small tags |
| `radiusMd` | 16 | Inputs, option rows |
| `radiusLg` | 20 | Cards |
| `radiusPill` | 999 | Buttons and chips |
| `shadowCard` | light `0 4 16 rgba(28,31,35,0.08)`, dark `0 4 16 rgba(0,0,0,0.4)` | Floating cards and sheets only; flat screens use borders |

In code these are `OgSpace` (`s1` to `s12`), `OgRadius` (`sm`, `md`, `lg`, `pill`), `OgSize` (row height 56, or 72 with a subtitle; tap target 48; row icon 24; new-item dot 8; 8 px band between settings groups; search bar 44; Edit profile photo 96; readable width 560 from 600 wide) and `OgMotion` (press 150 ms, reduced-motion fade 200 ms, ease-out, 400 ms debounce before a live check) in `packages/og_design/lib/og_layout.dart`. New components take every number from there.

## Rules

1. Orange fills carry only white text. White on `orange300` is not allowed.
2. Lime fills carry only charcoal text.
3. Orange text, and white text on an orange fill, smaller than 24 px Regular uses `link` or `orange700`, never `orange500`.
4. Control edges use `borderControl`, not `border`.
5. State is never colour alone: errors and success come with an icon and a sentence.
6. Focus is a 3 px `focusRing` outline.
7. Tap targets at least 44 × 44. Buttons are 56 tall.
8. Smallest text 12 px. Contrast 4.5:1 for text (3:1 for 24 px and larger, and for control edges).
9. Respect the system's reduced-motion and text-size settings. Layouts must survive 200% text.
10. Icons: rounded line icons, 24 px, 2 to 2.5 px stroke, `currentColor`. A check mark is 3 px. No emoji, no filled glossy icons.
11. Dark mode tokens exist from day one; dark screens ship later.

## Writing

- Plain, warm, second person. Short sentences. Say what happens next ("We'll send a 6-digit code").
- Buttons are verbs: Send code, Find a Meet, Give up my spot. One main action per screen.
- Sentence case everywhere. The product is written OlympusGO.
- Never show an email address back to the person. Say what is private ("Other players never see it").
- No emoji. No exclamation marks except a short celebration ("You're in.").
- Prices as `S$8.00`. Dates as `Fri 2 Oct`, times as `8:00 PM`.

## Shared components to build first

Build these in `packages/ui` before feature screens. Each has a widget test and a golden test in light and dark.

| Component | Notes | Canvas reference |
| --- | --- | --- |
| `OgButton` (primary, secondary, danger, text) | 56 tall, pill, `button` style, loading and disabled states | Every screen footer |
| `OgChip` (filter, choice) | 40 tall, `aria-pressed` equivalent (`Semantics(selected:)`) | Play filters |
| `OgField` | Label, helper, error with icon and sentence | Sign-up, create forms |
| `OgOptionRow` | Radio or checkbox row, 64 tall | Refund choice, reasons |
| `OgSwitchRow` | Title, subtitle, switch, 60 tall | Notification settings |
| `SettingsRow` (`lib/core/widgets/settings_list.dart`) | Optional 24 px outline icon, label in `body` with an optional `secondary` subtitle under it, value in `secondary` on the right (one line, ellipsis, at most 60 % of the row; the label wraps but never shortens), optional 8 px "new" dot, then a chevron only when it opens something (or a trailing icon such as copy). No value shows its empty text ("Add") in `link`, because orange text under 24 px cannot be `accent`. 56 tall, 72 with a subtitle. Pressing changes the background for 150 ms instead of a ripple, instantly with reduced motion. A screen reader hears "label, subtitle, value, button"; a keyboard or Switch Control can focus it and it shows the 3 px `focusRing`. `isLoading` shows a grey bar at the same height. At large text a value that won't fit moves under the label | Settings, Account information, Edit profile |
| `SettingsSection` | `menu` (default): rows edge to edge on `groupedSurface` (white), no dividers, groups 8 px apart on a `groupedBg` page (light grey), with the header on `groupedBg` too. `outlined`: a `radiusLg` card with a `border` hairline, no fill, hairlines between rows, 16 px side margins. Optional `groupLabel` header and `caption` helper text with an optional `link` at its end | Settings; Account information and Edit profile (outlined) |
| `SettingsList` and `SettingsSearchBar` | The search bar is a 44 px rounded field in `groupedSurface` with "Search". The list filters every group's rows by label and subtitle, hides empty groups and shows "No results" | Settings |
| `OgSheet` | Bottom sheet with handle and close button | Payment sheet, give up a spot |
| `PaymentSheet` | Review, then Face ID, then receipt (PAY-1). One widget for every paid flow | MeetPay, MeetConfirm, MeetPaid |
| `ActivityCard` | One card for Meets, tournaments and events; no Join button on the card (PLY-3) | ActivityCards |
| `StateView` | Loading, empty, offline, full, failed payment (NFR-11) | StateLoading, StateEmpty, StateOffline, StateMeetFull, StatePaymentFailed |
| `PhoneActionNotice` | Share, photos, maps: the system sheet in the real app | Several |
| `BottomNav` | Home, Discover, Scan, Inbox, Profile; active tab with an orange background, Scan without | OlympusGO Screens · Main navigation |
| `MoneyText` | Formats `Money` per currency (R-MON-3) | Everywhere |
