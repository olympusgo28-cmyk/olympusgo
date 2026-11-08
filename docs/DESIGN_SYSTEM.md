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

Fonts: **Futura** for everything (owner, 8 Nov 2026, Q250): Bold for display (titles, button labels), Medium for the rest. iPhones include Futura; Android, the web and the admin web use **Jost**, the closest free match (Open Font License), until a Futura licence is bought. This replaces Baloo 2 and Nunito Sans (Q15).

| Style | Family | Size / line | Weight | Use |
| --- | --- | --- | --- | --- |
| `display` | Futura | 48 / 52 | 800 | Splash and celebration only |
| `h1` | Futura | 34 / 38 | 800 | Screen titles |
| `h2` | Futura | 24 / 28 | 800 | Section titles |
| `h3` | Futura | 20 / 24 | 700 | Card titles |
| `button` | Futura | 20 / 24 | 800 | Button labels (20 px bold counts as large text) |
| `bodyLg` | Futura | 18 / 26 | 400 | Input text |
| `body` | Futura | 16 / 24 | 400 | Body copy |
| `bodyBold` | Futura | 16 / 24 | 700 | Selected options, emphasis |
| `label` | Futura | 14 / 20 | 700 | Field labels |
| `small` | Futura | 14 / 20 | 400 | Helper text |
| `caption` | Futura | 12 / 16 | 600 | The smallest text allowed |

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

## Rules

1. Orange fills carry only white text. White on `orange300` is not allowed.
2. Lime fills carry only charcoal text.
3. Orange text smaller than 18.66 px bold uses `link` or `orange700`, never `orange500`.
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
| `OgSheet` | Bottom sheet with handle and close button | Payment sheet, give up a spot |
| `PaymentSheet` | Review, then Face ID, then receipt (PAY-1). One widget for every paid flow | MeetPay, MeetConfirm, MeetPaid |
| `ActivityCard` | One card for Meets, tournaments and events; no Join button on the card (PLY-3) | ActivityCards |
| `StateView` | Loading, empty, offline, full, failed payment (NFR-11) | StateLoading, StateEmpty, StateOffline, StateMeetFull, StatePaymentFailed |
| `PhoneActionNotice` | Share, photos, maps: the system sheet in the real app | Several |
| `BottomNav` | Home, Discover, Scan, Inbox, Profile; active tab with an orange background, Scan without | OlympusGO Screens · Main navigation |
| `MoneyText` | Formats `Money` per currency (R-MON-3) | Everywhere |
