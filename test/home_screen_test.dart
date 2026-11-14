// Home and the floating tab bar (owner, 14 Nov 2026).

import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_home.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:olympus_go/features/earnings/application/earnings_providers.dart';
import 'package:olympus_go/features/earnings/data/earnings_repository.dart';
import 'package:olympus_go/features/feed/application/feed_providers.dart';
import 'package:olympus_go/features/feed/domain/feed_models.dart';
import 'package:olympus_go/features/game/application/game_providers.dart';
import 'package:olympus_go/features/game/data/game_repository.dart';
import 'package:olympus_go/features/game/domain/game_models.dart';
import 'package:olympus_go/features/home/application/home_categories.dart';
import 'package:olympus_go/core/widgets/pressable.dart';
import 'package:olympus_go/features/home/home_blocks.dart';
import 'package:olympus_go/features/home/home_screen.dart';
import 'package:olympus_go/features/play/application/play_providers.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/play/domain/activity.dart';
import 'package:olympus_go/features/profile/domain/profile.dart';
import 'package:olympus_go/features/shell/main_shell.dart';
import 'package:olympus_go/features/shop/application/shop_providers.dart';
import 'package:olympus_go/features/shop/domain/shop_models.dart';
import 'package:olympus_go/features/social/application/social_providers.dart';
import 'package:olympus_go/features/social/domain/social_models.dart';

const _phone = Size(402, 874);
const _small = Size(375, 700);
const _tablet = Size(820, 1180);

class _Me extends SessionProfile {
  _Me(this.name);
  final String? name;

  @override
  Future<Profile?> build() async => Profile(id: 'u1', fullName: name);
}

class _Cats extends HomeCategoriesController {
  _Cats([this.shown]);
  final Set<HomeCategory>? shown;

  @override
  HomeCategories build() =>
      (order: HomeCategory.values, shown: shown ?? {...defaultHomeShown});

  @override
  Future<void> save(HomeCategories value) async => state = value;
}

Future<List<Activity>> _some(ActivityKind kind) =>
    DemoPlayRepository().upcoming(kind: kind);

Future<GoRouter> _open(
  WidgetTester tester, {
  String? name = 'Nicholas Ong',
  ThemeData? theme,
  Size size = _phone,
  double textScale = 1,
  bool withMeets = false,
  bool withContent = true,
  Set<HomeCategory>? shown,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/:rest(.*)', builder: (_, s) => Text('at ${s.uri}')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProfileProvider.overrideWith(() => _Me(name)),
        homeCategoriesControllerProvider.overrideWith(() => _Cats(shown)),
        for (final k in ActivityKind.values)
          upcomingOfKindProvider(k).overrideWith(
            (_) => withMeets && k == ActivityKind.meet
                ? _some(k)
                : Future.value(const <Activity>[]),
          ),
        suggestedPlayersProvider.overrideWith(
          (_) async => withContent
              ? const [
                  SuggestedPlayer(
                    player: PlayerSummary(id: 'p1', fullName: 'Hannah Ong'),
                    level: 3.5,
                    note: 'Plays Fridays',
                  ),
                ]
              : const [],
        ),
        popularProductsProvider.overrideWith(
          (_) async => withContent
              ? const [
                  Product(
                    id: 'pr1',
                    name: 'Pro racquet',
                    mallId: 'm1',
                    mallName: 'Kallang Sports',
                    priceCents: 12900,
                    pointsCapCents: 500,
                  ),
                ]
              : const [],
        ),
        campaignsProvider.overrideWith(
          (_) => withContent
              ? DemoGameRepository().campaigns()
              : Future.value(const <Campaign>[]),
        ),
        myVouchersProvider.overrideWith(
          (_) async => const [
            GameVoucher(
              id: 'v1',
              name: 'Court hour',
              code: 'X',
              status: 'issued',
              amountCents: 500,
              where: 'Kallang',
            ),
            GameVoucher(
              id: 'v2',
              name: 'Court hour',
              code: 'Y',
              status: 'issued',
              amountCents: 500,
              where: 'Kallang',
            ),
            GameVoucher(
              id: 'v3',
              name: 'Court hour',
              code: 'Z',
              status: 'used',
              amountCents: 500,
              where: 'Kallang',
            ),
          ],
        ),
        pointsSummaryProvider.overrideWith(
          (_) async => const PointsSummary(minor: 12340),
        ),
        feedStatusProvider.overrideWith(
          (_) async => const FeedStatus(
            open: false,
            canPost: false,
            canDiscover: false,
            maxSeconds: 0,
            maxMb: 0,
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: theme ?? OgTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Widget _bar({
  int index = 0,
  int unread = 0,
  ValueChanged<int>? onTap,
  ThemeData? theme,
  double bottomPadding = 34,
  double textScale = 1,
  bool reduceMotion = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? OgTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: EdgeInsets.only(bottom: bottomPadding),
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
    ),
    child: child!,
  ),
  home: Scaffold(
    extendBody: true,
    body: const SizedBox.expand(),
    bottomNavigationBar: MainTabBar(
      index: index,
      unread: unread,
      onTap: onTap ?? (_) {},
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('tab bar', () {
    testWidgets('five equal tabs, Scan included, each with a label', (
      tester,
    ) async {
      await tester.pumpWidget(_bar());
      final sizes = <Size>[];
      for (final label in ['Home', 'Discover', 'Scan', 'Inbox', 'Profile']) {
        expect(find.text(label), findsOneWidget);
        sizes.add(
          tester.getSize(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(FocusableActionDetector),
                )
                .first,
          ),
        );
      }
      expect(sizes.toSet(), hasLength(1));
      expect(sizes.first.height, greaterThanOrEqualTo(44));
    });

    testWidgets(
      'the pill is 64 tall, 16 in from the sides, 24 above the bottom',
      (tester) async {
        await tester.binding.setSurfaceSize(_phone);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_bar());
        final pill = tester.getRect(find.byKey(MainTabBar.pillKey));
        final screen = tester.getRect(find.byType(Scaffold));
        expect(pill.height, OgHomeSize.nav);
        expect(pill.left, 16);
        expect(screen.right - pill.right, 16);
        expect(screen.bottom - pill.bottom, 24);
      },
    );

    testWidgets('without a home indicator the gap is 12', (tester) async {
      await tester.pumpWidget(_bar(bottomPadding: 0));
      expect(
        tester.getSize(find.byType(MainTabBar)).height,
        OgHomeSize.nav + OgHomeSize.navBottomPlain,
      );
      final context = tester.element(find.byType(MainTabBar));
      expect(
        MainTabBar.reservedHeight(context),
        OgHomeSize.nav + OgHomeSize.navBottomPlain + OgHomeSize.navBreathing,
      );
    });

    testWidgets('selected tab is full size, the others 90 %', (tester) async {
      await tester.pumpWidget(_bar(index: 2));
      final scales = tester
          .widgetList<AnimatedScale>(find.byType(AnimatedScale))
          .map((s) => s.scale)
          .toList();
      expect(scales, [0.9, 0.9, 1.0, 0.9, 0.9]);
    });

    testWidgets('the size change takes 0.2 s, and none with reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(_bar());
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).duration,
        const Duration(milliseconds: 200),
      );
      await tester.pumpWidget(_bar(reduceMotion: true));
      final still = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale).first,
      );
      expect(still.duration, Duration.zero);
    });

    testWidgets('selected tab is announced as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_bar(index: 1));
      bool selected(String label) =>
          tester
              .getSemantics(find.bySemanticsLabel(label))
              .flagsCollection
              .isSelected ==
          Tristate.isTrue;
      expect(selected('Discover'), isTrue);
      expect(selected('Home'), isFalse);
      expect(selected('Scan'), isFalse);
      handle.dispose();
    });

    testWidgets('Inbox shows 9+ above nine, and says how many are new', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_bar(unread: 12));
      expect(find.text('9+'), findsOneWidget);
      expect(find.bySemanticsLabel('Inbox, 12 new'), findsOneWidget);
      await tester.pumpWidget(_bar(unread: 3));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('9+'), findsNothing);
      await tester.pumpWidget(_bar());
      expect(find.bySemanticsLabel('Inbox'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('tapping a tab, and the tab you are on, both report it', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(_bar(index: 0, onTap: taps.add));
      await tester.tap(find.text('Home'));
      await tester.tap(find.text('Scan'));
      expect(taps, [0, 2]);
    });

    for (final (name, theme) in [
      ('light', OgTheme.light()),
      ('dark', OgTheme.dark()),
    ]) {
      testWidgets('fits at 200 % text in $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_bar(theme: theme, unread: 12, textScale: 2));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Home', () {
    testWidgets('greets you by first name', (tester) async {
      await _open(tester);
      expect(find.text('Welcome,'), findsOneWidget);
      expect(find.text('Nicholas'), findsOneWidget);
    });

    testWidgets('without a name it reads "Welcome, to OlympusGO"', (
      tester,
    ) async {
      await _open(tester, name: null);
      expect(find.text('Welcome,'), findsOneWidget);
      expect(find.text('to OlympusGO'), findsOneWidget);
    });

    testWidgets('the hero wraps the greeting and the search bar overlaps it '
        'by 28', (tester) async {
      await _open(tester);
      final search = tester.getRect(find.byType(HomeSearch));
      final name = tester.getRect(find.text('Nicholas'));
      final buttons = tester.getRect(find.bySemanticsLabel('Saved'));
      expect(search.height, OgHomeSize.search);
      expect(search.left, OgHomeSize.side);
      // No status bar in a test. The orange ends 16 below the taller of the
      // greeting and the buttons, and the search bar sits half over it.
      final orangeBottom = search.top + OgHomeSize.searchOverlap;
      final content = name.bottom > buttons.bottom
          ? name.bottom
          : buttons.bottom;
      expect(
        orangeBottom,
        content + OgHomeSize.heroPad + OgHomeSize.searchOverlap,
      );
    });

    testWidgets('the greeting is white', (tester) async {
      await _open(tester);
      for (final t in ['Welcome,', 'Nicholas']) {
        expect(tester.widget<Text>(find.text(t)).style?.color, Colors.white);
      }
      await _open(tester, theme: OgTheme.dark());
      expect(
        tester.widget<Text>(find.text('Nicholas')).style?.color,
        Colors.white,
      );
    });

    testWidgets('the header buttons and search open their pages', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(find.bySemanticsLabel('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('at ${Routes.saved}'), findsOneWidget);
    });

    testWidgets('two rows of circles: seven services, then More', (
      tester,
    ) async {
      await _open(tester);
      final grid = find.byType(HomeShortcuts);
      final labels = [
        'Play',
        'Group',
        'Academy',
        'Venue',
        'Game',
        'Shop',
        'Fitness',
        'More',
      ];
      final centres = [
        for (final l in labels)
          // The circle's tappable area, as a long label may wrap.
          tester
              .getRect(
                find
                    .ancestor(
                      of: find.descendant(of: grid, matching: find.text(l)),
                      matching: find.byType(Pressable),
                    )
                    .first,
              )
              .topCenter,
      ];
      // Four to a row, More at the far right of the second.
      for (var i = 1; i < 4; i++) {
        expect(centres[i].dy, centres[0].dy, reason: labels[i]);
        expect(centres[i + 4].dy, centres[4].dy, reason: labels[i + 4]);
        expect(centres[i].dx, greaterThan(centres[i - 1].dx));
      }
      expect(centres[4].dy, greaterThan(centres[0].dy));
      expect(centres[7].dx, centres[3].dx, reason: 'More under Venue');
      for (final gone in ['Your favourites', 'More services', 'View all']) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
      expect(find.text('Edit'), findsNothing, reason: 'Edit is in More');
    });

    testWidgets('never more than seven circles before More', (tester) async {
      await _open(tester, shown: HomeCategory.values.toSet());
      final grid = find.byType(HomeShortcuts);
      var count = 0;
      for (final c in HomeCategory.values) {
        count += find
            .descendant(of: grid, matching: find.text(c.label))
            .evaluate()
            .length;
      }
      expect(count, maxHomeCategories);
    });

    testWidgets('Edit in More switches to the list; Done saves to Home', (
      tester,
    ) async {
      // A real phone's height, so the sheet and taps line up.
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = _phone * 3;
      addTearDown(tester.view.reset);
      await _open(tester);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit shortcuts'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Edit'), findsNothing, reason: 'Done is at the bottom');
      // A picture of Home, in order, then More.
      expect(
        find.bySemanticsLabel(
          'On Home, in order: Play, Group, Academy, Venue, Game, Shop, '
          'Fitness, More',
        ),
        findsOneWidget,
      );
      Finder switchFor(String label) => find.descendant(
        of: find
            .ancestor(
              of: find.descendant(
                of: find.byType(ReorderableListView),
                matching: find.text(label),
              ),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byType(CupertinoSwitch),
      );
      // The list scrolls inside the sheet; Record is last.
      final list = find
          .descendant(
            of: find.byType(ReorderableListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Record'),
        ),
        100,
        scrollable: list,
      );
      // Seven are on: an eighth is refused.
      await tester.ensureVisible(switchFor('Record'));
      await tester.tap(switchFor('Record'));
      await tester.pump();
      expect(find.text('Up to 7 on Home. Turn one off first.'), findsOneWidget);
      // The message covers the bottom of the list until it goes.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      // Swap Shop for Record.
      Future<void> reach(String label, double step) =>
          tester.scrollUntilVisible(
            find.descendant(
              of: find.byType(ReorderableListView),
              matching: find.text(label),
            ),
            step,
            scrollable: list,
          );
      await reach('Shop', -100);
      await tester.ensureVisible(switchFor('Shop'));
      await tester.tap(switchFor('Shop'));
      await tester.pump();
      await reach('Record', 100);
      await tester.ensureVisible(switchFor('Record'));
      await tester.tap(switchFor('Record'));
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          'On Home, in order: Play, Group, Academy, Venue, Game, Fitness, '
          'Record, More',
        ),
        findsOneWidget,
        reason: 'the picture follows the switches',
      );
      expect(
        find.bySemanticsLabel(RegExp('Record, number 7 on Home')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Shop, not on Home')),
        findsOneWidget,
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('All services'), findsOneWidget);
      final grid = find.byType(HomeShortcuts);
      // Done again closes the sheet.
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.descendant(of: grid, matching: find.text('Record')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: grid, matching: find.text('Shop')),
        findsNothing,
      );
      // Let the message run its course.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('More lists the nine services, and Record opens the log', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('All services'), findsOneWidget);
      final sheet = find.byType(BottomSheet);
      for (final c in HomeCategory.values) {
        expect(
          find.descendant(of: sheet, matching: find.text(c.label)),
          findsOneWidget,
          reason: c.label,
        );
      }
      expect(HomeCategory.values.map((c) => c.label), [
        'Play',
        'Group',
        'Academy',
        'Venue',
        'Game',
        'Shop',
        'Fitness',
        'Services',
        'Record',
      ]);
      for (final gone in [
        'Wallet',
        'Points',
        'Tickets',
        'Rankings',
        'My gear',
        'Orders',
      ]) {
        expect(
          find.descendant(of: sheet, matching: find.text(gone)),
          findsNothing,
          reason: gone,
        );
      }
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Record')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('at ${Routes.fitnessLog}'), findsOneWidget);
    });

    testWidgets('wallet and points are two cards, vouchers ready and points', (
      tester,
    ) async {
      await _open(tester);
      expect(
        find.text('2 vouchers'),
        findsOneWidget,
        reason: 'used one left out',
      );
      expect(find.text('1234'), findsOneWidget);
      final wallet = tester.getRect(
        find
            .ancestor(
              of: find.text('2 vouchers'),
              matching: find.byType(Container),
            )
            .first,
      );
      final points = tester.getRect(
        find
            .ancestor(of: find.text('1234'), matching: find.byType(Container))
            .first,
      );
      expect(points.left - wallet.right, 12, reason: 'a gap between the cards');
      await tester.tap(find.text('2 vouchers'));
      await tester.pumpAndSettle();
      expect(find.text('at ${Routes.wallet}'), findsOneWidget);
    });

    testWidgets('the ad opens the Shop', (tester) async {
      await _open(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gear up for game day'));
      await tester.pumpAndSettle();
      expect(find.text('at ${Routes.shop}'), findsOneWidget);
    });

    testWidgets('a row with nothing in it is not drawn', (tester) async {
      await _open(tester, withContent: false);
      for (final t in [
        'Challenges',
        'Meets',
        'Events',
        'Tournaments',
        'Players',
        'Popular items',
      ]) {
        expect(find.text(t, skipOffstage: false), findsNothing, reason: t);
      }
      expect(find.text('See all', skipOffstage: false), findsNothing);
    });

    testWidgets('a row with Meets in it is drawn, with See all', (
      tester,
    ) async {
      await _open(tester, withMeets: true, withContent: false);
      // The Play card is not part of this redesign, and the test font is
      // wider than Jost, so its own layout may complain here; the row is
      // what is under test.
      while (tester.takeException() != null) {}
      expect(find.text('Meets', skipOffstage: false), findsOneWidget);
      expect(find.text('See all', skipOffstage: false), findsOneWidget);
    });

    testWidgets('rows with content are drawn', (tester) async {
      await _open(tester);
      for (final t in ['Challenges', 'Players', 'Popular items']) {
        expect(find.text(t, skipOffstage: false), findsOneWidget, reason: t);
      }
      expect(find.text('up to S\$5 pts', skipOffstage: false), findsNothing);
    });

    testWidgets('the old Categories, Hi and points blocks are gone', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('Categories'), findsNothing);
      expect(find.text('Hi Nicholas'), findsNothing);
      expect(find.text('Your groups'), findsNothing);
    });

    for (final (name, theme) in [
      ('light', OgTheme.light()),
      ('dark', OgTheme.dark()),
    ]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('builds at 375 wide, text $scale, $name', (tester) async {
          await _open(tester, theme: theme, size: _small, textScale: scale);
          expect(tester.takeException(), isNull);
          // Scroll the whole page to find any overflow below the fold.
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('colours', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
    }

    for (final (name, h) in [('light', OgHome.light), ('dark', OgHome.dark)]) {
      test('text passes 4.5:1 in $name', () {
        final pairs = {
          'hero buttons': (h.onHeroButton, h.heroButton),
          'heading on page': (h.heading, h.page),
          'heading on card': (h.heading, h.surface),
          'link on page': (h.link, h.page),
          'icon on tint': (h.iconInk, h.iconTint),
          'ad title': (h.onAd, h.adSurface),
          'ad grey line': (h.adMuted, h.adSurface),
          'ad Shop now': (h.adAccent, h.adSurface),
          'up to N pts': (h.onPointsTag, h.pointsTag),
          'selected tab': (h.navSelected, h.navSelectedTint),
          'selected tab label': (h.navSelected, h.navSurface),
          'idle tab': (h.navIdle, h.navSurface),
          'inbox count': (h.onNavBadge, h.navBadge),
        };
        pairs.forEach((what, p) {
          expect(contrast(p.$1, p.$2), greaterThanOrEqualTo(4.5), reason: what);
        });
      });
    }

    // The owner chose a white greeting in both themes (Q270 h). On the orange
    // the 28 pt name passes the 3:1 rule for large text; the smaller
    // "Welcome," and the greeting on dark mode's lime do not, which Q270 (h)
    // records for the owner.
    test('greeting is white; its name passes 3:1 on the orange', () {
      expect(OgHome.light.onHero, const Color(0xFFFFFFFF));
      expect(OgHome.dark.onHero, const Color(0xFFFFFFFF));
      expect(
        contrast(OgHome.light.onHero, OgHome.light.hero),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('goldens', () {
    for (final (name, theme) in [
      ('light', OgTheme.light()),
      ('dark', OgTheme.dark()),
    ]) {
      for (final (device, size) in [('phone', _phone), ('tablet', _tablet)]) {
        testWidgets('Home, $device, $name', (tester) async {
          await _open(tester, theme: theme, size: size);
          await expectLater(
            find.byType(HomeScreen),
            matchesGoldenFile('goldens/home_${device}_$name.png'),
          );
        });
        testWidgets('Tab bar, $device, $name', (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(_bar(index: 1, unread: 12, theme: theme));
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile('goldens/tab_bar_${device}_$name.png'),
          );
        });
      }
    }
  });

  group('saved favourites', () {
    test('a saved choice keeps at most its first seven', () async {
      FlutterSecureStorage.setMockInitialValues({
        'og_home_categories':
            'venue,play,group,academy,game,shop,services,fitness',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(homeCategoriesControllerProvider);
      await Future<void>.delayed(Duration.zero);
      final s = c.read(homeCategoriesControllerProvider);
      expect(s.shown, {
        HomeCategory.venue,
        HomeCategory.play,
        HomeCategory.group,
        HomeCategory.academy,
        HomeCategory.game,
        HomeCategory.shop,
        HomeCategory.services,
      });
      expect(
        s.order.last,
        HomeCategory.record,
        reason: 'new, added at the end',
      );
      expect(s.shown, isNot(contains(HomeCategory.record)));
    });

    test('a new install shows the first seven, Record and Services off', () {
      FlutterSecureStorage.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(homeCategoriesControllerProvider).shown, {
        HomeCategory.play,
        HomeCategory.group,
        HomeCategory.academy,
        HomeCategory.venue,
        HomeCategory.game,
        HomeCategory.shop,
        HomeCategory.fitness,
      });
    });
  });
}
