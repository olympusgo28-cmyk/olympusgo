# Design review against Apple's Human Interface Guidelines

Read this when asked to review, audit or improve a design for iPhone, iPad or Mac (including a Flutter app running there), when the user shares screenshots, mockups or UI code and wants feedback, and for focused checks: accessibility, dark mode, navigation, an app icon, onboarding, forms, glass and blur, or AI features.

`design.md` holds the rules that apply on every platform. This file adds the Apple lens. It folds in the method of the project's `apple-design` skill.

## Contents

1. Two reviewers at once
2. Where the guideline pages are
3. Which pages to open
4. Apple's eight principles as a first filter
5. The review, step by step
6. The five lenses
7. The report
8. Focused reviews
9. Improving a design
10. Working rules

## 1. Two reviewers at once

Hold two roles together. The first knows the platform's guidelines thoroughly and keeps the design honest against them. The second leads a small studio whose clients pay for a point of view, and keeps the design from looking like every other app. Every review carries both.

The guidelines are written for native Apple apps. For Flutter and other frameworks they apply as principles: translate the vocabulary into the framework's own terms and never water the principle down.

## 2. Where the guideline pages are

Apple's guideline text is not copied into this skill. It belongs to Apple and is already in the repository once, inside the `apple-design` skill that sits beside this one:

| Path, relative to this skill's folder | What it is |
|---|---|
| `../apple-design/references/hig-lookup.md` | an index of every page by Apple's sections, with a one-line summary and the date Apple last changed it |
| `../apple-design/references/hig/<page>.md` | one file per guideline page, in Apple's wording |
| `../apple-design/references/hig/liquid-glass.md` | a guide to the glass material with a checklist and framework translations |
| `../apple-design/references/cross-platform.md` | Apple's terms in Flutter, React Native, Tauri and Electron words, and the conventions to check in each |

If that folder is not present, read the page on Apple's developer site instead, as `research.md` describes, and say that you did.

How to use the pages:

- **Read before you cite.** Open the file and take the guideline from it. Do not review from memory: Apple revises these pages, and the index shows when each last changed.
- **Open about 8 to 12 pages per review**, never the whole folder: the always-open set, then three to six for what is on screen.
- **Cite the file and heading** for every guideline, for example `buttons.md › Style`. If no page covers a point, say it is your own judgement.

## 3. Which pages to open

**Always:** `accessibility.md`, `layout.md`, `typography.md`, `color.md`, and `designing-for-ios.md` or `designing-for-macos.md` (or both) for the platform in front of you. For Flutter, also `cross-platform.md`.

**By what the design shows:**

| On screen | Open |
|---|---|
| Tabs, sidebar, split view, back navigation | `tab-bars.md`, `sidebars.md`, `split-views.md`, `toolbars.md` |
| Buttons, menus, actions | `buttons.md`, `menus.md`, `context-menus.md`, `pop-up-buttons.md`, `pull-down-buttons.md` |
| Sheets, dialogs, popovers, alerts | `modality.md`, `sheets.md`, `alerts.md`, `action-sheets.md`, `popovers.md` |
| Forms, text entry, pickers | `entering-data.md`, `text-fields.md`, `pickers.md`, `toggles.md`, `virtual-keyboards.md` |
| Lists, tables, collections, cards | `lists-and-tables.md`, `collections.md`, `labels.md`, `scroll-views.md` |
| Search | `searching.md`, `search-fields.md` |
| Glass, blur, translucent bars | `liquid-glass.md`, `materials.md` |
| Dark appearance | `dark-mode.md` |
| Icons, symbols, the app icon | `icons.md`, `sf-symbols.md`, `app-icons.md` |
| Motion, transitions, haptics | `motion.md`, `playing-haptics.md` |
| Loading, progress, errors, empty states | `loading.md`, `feedback.md`, `progress-indicators.md`, `writing.md` |
| First run, sign-in, permissions | `onboarding.md`, `launching.md`, `managing-accounts.md`, `privacy.md`, `sign-in-with-apple.md` |
| Settings | `settings.md` |
| Windows, menu bar, keyboard, pointer (desktop) | `windows.md`, `the-menu-bar.md`, `keyboards.md`, `pointing-devices.md`, `focus-and-selection.md` |
| Two displays or a fold | `designing-for-iphone-duo.md`, `split-views.md`, `toolbars.md`, `tab-bars.md` |
| Notifications, widgets, live activities | `notifications.md`, `managing-notifications.md`, `widgets.md`, `live-activities.md` |
| Charts | `charting-data.md`, `charts.md` |
| AI features | `generative-ai.md`, `machine-learning.md` |
| Brand expression | `branding.md`, `design-principles.md` |

Anything else: find it in `hig-lookup.md`.

## 4. Apple's eight principles as a first filter

A screen that breaks a principle has a bigger problem than any single guideline it breaks. Read `design-principles.md` for Apple's own wording. The question each one puts to a screen:

| Principle | Ask |
|---|---|
| Purpose | What is this screen for, and does the design serve that? |
| Agency | Can people explore, skip, and recover from a mistake? |
| Responsibility | Are permissions, data use and intent transparent? |
| Familiarity | Do the patterns match the platform and stay consistent? |
| Flexibility | Does it work across sizes, inputs, text sizes and abilities? |
| Simplicity | Has every element earned its place? |
| Craft | Spacing, alignment, wording, animation: is it finished? |
| Delight | Is there a feeling here, and is it the right one? Delight is not decoration. |

## 5. The review, step by step

**Step 1: establish context.** Before judging anything, pin down:

- the platform and the framework
- the kind of app and who uses it
- what you were given (screenshots, mockups, wireframes, code, a description), and what can and cannot be verified from it
- the design's thesis: in one sentence, the single job of this screen and the most characteristic thing about it. If the design gives no answer, that is a craft note. If the material cannot show it, that is a limit, not a finding.
- what the user wants: a full audit, one specific worry, or a direction for improvement

Infer what you can. Ask only if the answer changes the review.

Limits to state plainly:

- A web app or an Android-only app gets the principles and the foundations (accessibility, colour, type, layout, writing), not Apple's platform conventions. Say which parts apply.
- Screenshots support layout, hierarchy and copy review. Contrast and sizes need real values. Estimate only when you can sample the colours, and label estimates as estimates.

**Step 2: open the pages** from section 3 and read them. Take the principle behind each Apple-specific sentence and translate the vocabulary.

**Step 3: audit through the five lenses**, in order (section 6).

**Step 4: write the report** (section 7).

## 6. The five lenses

Cite only pages you actually opened.

**Lens 1: accessibility. A failure here is critical.** From `accessibility.md`, `typography.md`, `color.md`.

- Text follows the system size setting, and layouts keep their hierarchy at the largest sizes.
- Type size: on mobile, 17 pt by default and never below 11 pt; on desktop, 13 pt by default and never below 10 pt. No light or thin weights for small text.
- Contrast: 4.5 to 1 for text up to 17 pt; 3 to 1 for text of 18 pt or more, or bold. Compute it from real values and show the numbers.
- Controls: on mobile, 44 by 44 pt by default and never below 28 by 28; on desktop, 28 by 28 by default and never below 20 by 20. Space between controls matters as much as size. (Flutter's own minimum is 48 logical pixels; use the larger where both apply.)
- Nothing is carried by colour alone. Every icon-only control has a label for screen readers. On desktop, everything works from the keyboard.
- Motion is optional and never the only carrier of meaning. Reduced motion, reduced transparency and increased contrast each have an answer.

**Lens 2: platform conventions. A failure is usually high.**

Mobile, from `designing-for-ios.md`, `tab-bars.md`, `toolbars.md`, `sheets.md`, `search-fields.md`, `gestures.md`, `layout.md`:

- Top-level navigation is a tab bar, which may become a sidebar on tablet. Tabs navigate; they do not perform actions. Few tabs, none hidden or disabled, short labels.
- Actions on the current view live in a toolbar. The key action gets the prominent style, and overflow goes into a More menu.
- Search that matters has a primary place.
- Sheets: one at a time, a grabber when resizable, swipe to dismiss, a way out besides Done.
- Content respects safe areas and one-handed reach, with important controls mid-screen or lower. Swipe-back and swipe actions on rows work.

Desktop, from `designing-for-macos.md`, `windows.md`, `the-menu-bar.md`, `sidebars.md`, `keyboards.md`, `settings.md`:

- Every command is reachable from the menu bar, including every toolbar item. Standard shortcuts are respected.
- Windows resize fluidly and use the system's controls. Nothing critical lives in a bottom bar.
- Sidebars show at most two levels and can be hidden.
- Settings live under the app menu.
- Everything interactive has pointer feedback and a comfortable hit region.

Both: light and dark appearance with no in-app switch, semantic colours, and glass or blur only on the floating functional layer, never in content.

**Lens 3: visual design and craft. Findings are high or medium.** From `color.md`, `typography.md`, `layout.md`, `icons.md`, `materials.md`, `motion.md`.

The rules:

- One colour means one thing. Colours work in light, dark and increased contrast. Nothing is hard-coded to a system colour's value.
- Few typefaces and a clear scale. Weight and size carry hierarchy.
- Alignment, grouping and indentation show hierarchy. Layout follows the space available, not the device or orientation, with the same functions at every size.
- Icons share one visual language and match the weight of the text beside them.
- Motion is purposeful, brief, cancellable, and rare on frequent interactions.

Then the craft questions:

- **Does it have a point of view?** Name the one thing this design would be remembered by. A deliberately quiet utility can be the right answer; when it is, say so.
- **Is it a template?** A palette, type pairing or layout that arrives with no reason rooted in the product is a default, not a choice. `design.md` lists the common marks.
- **Does the type carry personality?** System type is right for navigation and controls. Brand lives in display text, content and a few moments.
- **Does structure say something true?** Numbering, small labels and dividers should describe the content.
- **Is the boldness spent in one place?** One signature element, everything around it quiet.
- **Remove one accessory.** Ask what can go without loss. If nothing can, say the design is already lean.

"At home on the platform" and "could not be mistaken for anyone else" pull against each other. Resolve it as `branding.md` does: familiar components carry navigation and controls and keep their sizing, placement and behaviour even when restyled; identity lives in colour, type, imagery, tone of voice and a few defining moments.

**Lens 4: interaction. Usually medium.** From `feedback.md`, `loading.md`, `modality.md`, `alerts.md`, `undo-and-redo.md`, `entering-data.md`.

- Something appears at once while loading, people can keep working, and progress is measured where it can be.
- Feedback lives in the interface, not in alerts. Alerts are rare, never shown at launch, and never used for common actions that can be undone.
- Destructive, irreversible actions get a warning and a Cancel. Undo covers the rest.
- Modal views have an obvious way out and one short task.
- Data entry takes what the system already knows, offers choices over typing, validates as people go, and never pre-fills a password.

**Lens 5: content and writing. Usually medium.** From `writing.md`.

- Every label says what happens. An action keeps its name through the whole flow.
- Capitalisation follows the platform and is consistent. Mixed conventions on one screen are a finding. Where the repo has its own voice rules, those win.
- Errors say what went wrong and how to fix it. Empty screens invite the next action.
- Names come from what people control and recognise, not from how the system is built.

## 7. The report

```text
## Design review: <name>

### Summary
Two or three sentences and an overall rating: Excellent / Good / Needs work / Critical issues.
Name the design's thesis and the one thing it will be remembered by, or say it lacks one.

### Critical
Must fix: accessibility failures, and convention breaks that confuse people.
- What: the problem, with numbers where you have them
- Why: the principle, cited as file.md › Heading
- Fix: the concrete change, in the user's framework

### Improvements
Should fix. Same format, each tagged High, Medium or Low.

### Craft notes
Point of view, type, signature element, restraint.

### What works
Patterns to keep, named specifically so they survive the next iteration.

### Platform notes
Anything specific to mobile or desktop, or to the framework.
```

Include only sections that have content. The summary always appears. A design with nothing critical or high gets a short review.

Severity:

- **Critical:** accessibility failures, unusable on some devices or sizes, conventions broken in ways that confuse.
- **High:** real friction, poor contrast or readability, foreign on its platform, templated with no point of view.
- **Medium:** weaker patterns, a missed system component, small inconsistencies.
- **Low:** polish and edge cases.

The rating follows from the tags: Critical issues if any finding is critical; Needs work with several high findings; Good with nothing critical and at most a couple high; Excellent with nothing above medium and a clear point of view.

## 8. Focused reviews

| Review | Open | Check |
|---|---|---|
| App icon | `app-icons.md`, `icons.md` | layered composition, clear edges, centred content, no text unless essential, no copies of interface elements, dark and tinted variants |
| Accessibility audit | `accessibility.md`, `voiceover.md`, `typography.md`, `color.md`, `motion.md` | every item in lens 1, then reading order and labels, keyboard-only paths, captions, and a visual or haptic twin for every sound |
| Dark mode | `dark-mode.md`, `color.md`, `materials.md` | semantic colours, softened whites, both appearances tested, icons and images checked, no in-app toggle |
| Glass and blur | `liquid-glass.md`, `materials.md`, `color.md` | the checklist in the glass guide |
| Navigation | `tab-bars.md`, `sidebars.md`, `split-views.md`, `toolbars.md`, `searching.md`, `layout.md` | map the hierarchy, count tabs and levels, every section reachable, current location always visible, sensible conversion at tablet and desktop widths |
| Two displays or a fold | `designing-for-iphone-duo.md` and the navigation pages | each display, a partial fold and split view; fixed widths where size classes belong; nothing essential under a camera or across the fold. Custom-drawn bars and dialogs adapt only through your own code. |
| Onboarding and permissions | `onboarding.md`, `launching.md`, `managing-accounts.md`, `privacy.md` | launch at once, teach through use, delay sign-in, ask for permission in context with an honest reason |
| Forms | `entering-data.md`, `text-fields.md`, `pickers.md`, `toggles.md`, `virtual-keyboards.md` | the right keyboard, hints, validation as you go, sensible order, choices over typing |
| AI features | `generative-ai.md`, `machine-learning.md` | disclosure, expectations, control, refine and undo, permission before anything irreversible, a graceful experience when the feature is off |
| One component | that component's page | its best practices and platform sections |

## 9. Improving a design

When asked to improve, redesign, or make something less generic: review first, then work like a studio.

1. **Ground it in the subject.** Name the product, its audience and the screen's single job. Draw the visual world from the subject's own materials and vocabulary, and from what you know of the brand.
2. **Plan a compact token system before touching layout:**
   - colour: four to six named values with roles, each with light and dark variants and a contrast figure against its surface
   - type: a display face used with restraint, a body face, and a utility face for data if needed, with the scale shown
   - layout: one sentence and a small text wireframe of the key screen at compact and regular widths
   - signature: the single element the design will be remembered by, and why it belongs to this product
   - motion: one orchestrated moment if it serves the subject, otherwise none
3. **Critique the plan before proposing it.** Would you have produced the same plan for a similar brief about a different product? Then it is a default: revise it and say what changed. Check that navigation and controls still use system components and conventions.
4. **Propose concrete changes in the user's framework:** exact colours with contrast ratios, exact type styles, the named component that replaces a custom one, the property to set.
5. **Sequence the work:** accessibility, then conventions, then craft, then polish.
6. **Critique again.** Look for one thing to remove. Confirm the floor: works at the smallest supported width, visible keyboard focus on desktop, reduced motion and reduced transparency respected, the largest text size survivable.

In this project, new colours, type and spacing go into the theme tokens, never into screens.

## 10. Working rules

- **Numbers, not adjectives.** State the size, the colour values and the ratio, and the threshold it misses. If you cannot measure, say what you would need.
- **Cite it or label it as judgement.** Never invent a guideline.
- **Speak the framework.** Use the Flutter widget's name when the user writes Flutter.
- **Name the trade-off** when a guideline collides with a business need, then recommend.
- **Review the flow, not only the screen.** A fine screen can break the navigation around it.
- **Do not over-critique.** A strong design gets a short review and a clear statement of what makes it strong.
- **Do not flatten the personality.** Guidelines make apps usable, not identical. If your fixes would leave the design looking like a template, you have gone too far.
