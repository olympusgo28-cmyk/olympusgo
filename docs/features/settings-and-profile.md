# Settings and activity, Edit profile, Account information (9 Nov 2026)

Owner's request of 9 Nov 2026: an Instagram-style Settings screen opened from a menu button on Profile, the Profile account list moved into it, Edit profile rebuilt, and Account information on the same rows. Layout reference only; OlympusGO's theme, type roles and icons.

## Shared parts (`lib/core/widgets/settings_list.dart`)

- `SettingsRow`, `SettingsSection` (`menu` and `outlined`), `SettingsList`, `SettingsSearchBar`, `SkeletonBlock`, `SettingsLoadError`, `ReadableWidth`. They replace `InfoRow` and `InfoCard` from earlier the same day.
- New type role `groupLabel` (15 Medium, secondary colour). New tokens in `og_layout.dart`: row 72 with a subtitle, icon 24, dot 8, group gap 8, search bar 44, large avatar 96, debounce 400 ms.
- New icons: `menu` and `copy`, drawn in the app's own outline set.

## Profile

- A menu button beside the QR button opens Settings and activity.
- The Account list is gone from Profile; every row moved into Settings (Q261).

## Settings and activity (`settings_menu_screen.dart`)

A light grey page (`groupedBg`, header included) with a white search bar, then white groups (`groupedSurface`) with 8 px grey bands between them (owner, 9 Nov). Dark mode keeps charcoal groups on the darker page:

| Group | Rows (opens) |
| --- | --- |
| Your account | Account Centre (Account Centre), Edit profile, Account information. Helper "Manage your account settings. Learn more" (Help) |
| How you use OlympusGO | Saved, Bookings (My schedule, with the count), Notifications, Time management (placeholder) |
| Your activity | Sessions and rating, Sports and levels, My lessons, My clubs and teams, Challenges, My gear, Followers and following, Share profile |
| Payments and orders | Earnings and receipts, My orders, My shop (shop owners) |
| Family | Guardian controls (Children, with "N linked") |
| Who can see your content | Account privacy (Privacy and safety, with the visibility), Blocked accounts |
| Support | Help, About (Terms and privacy) |
| (last) | Log out |

A player waiting on a parent link sees only the rows they can open (the `/settings`, `/legal` and `/parent-link` screens); the others, and groups left empty, are hidden. Rows can be reached by keyboard and Switch Control and show the 3 px focus outline.

## Edit profile (`edit_profile_screens.dart`)

- Data: freezed `MyProfile` and `myProfileProvider` (an AsyncNotifier with no automatic retry, so a failed load shows Try again). It loads the details and the sports itself, so Try again recovers from either. Each save writes only its own column (`updateProfile`), so an edit on one phone never undoes a change made on another; `saveAccount` is gone.
- Name (at most 80 characters, as the database allows), Username, Bio: own screens, each with Save; back on Edit profile with "Saved". Gender: picker, saves at once. Sports: the existing Sports and levels screen. Level: read only (Q262).
- Username: rules in the lead, live check 400 ms after typing stops, using `username_available`.
- Profile link: `Links.player` shown without "https://"; copy icon; "Link copied".
- Photo: Take photo, Choose from library, Remove photo (only with a photo). Upload shows a spinner on the photo; a failure keeps the old photo and shows an error. Remove deletes the player's own `avatar.jpeg` and `avatar.png` first, checks none is left (storage reports nothing when a delete is refused), and only then clears `avatar_url`, so a removed photo is never left readable. If it fails the photo stays and the player is told.
- The optional notice block was not built: nothing needs saying yet.

## Account information

Outlined sections, no icons; otherwise as before (masking, read-only birthday and region, Add, Face ID card, Q258 to Q260).

## Motion and layout

Every screen here opens with `MotionPage`: the iOS slide, or a 200 ms fade in place with reduced motion, and edge swipe-back either way. From 600 wide, content is a centred 560 column.

## Tests

`test/settings_screens_test.dart`, `test/edit_profile_test.dart`, `test/account_info_test.dart`; goldens for all three screens at phone and tablet, light and dark.
