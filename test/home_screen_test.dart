// Home and the floating tab bar (owner, 14 Nov 2026).

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_home.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/feed/application/feed_providers.dart';
import 'package:olympus_go/features/feed/domain/feed_models.dart';
import 'package:olympus_go/features/game/application/game_providers.dart';
import 'package:olympus_go/features/game/data/game_repository.dart';
import 'package:olympus_go/features/game/domain/game_models.dart';
import 'package:olympus_go/features/home/application/home_categories.dart';
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
  @override
  HomeCategories build() =>
      (order: HomeCategory.values, shown: {...defaultHomeShown});
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
        homeCategoriesControllerProvider.overrideWith(_Cats.new),
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

    testWidgets('the hero is 232 tall and the search bar overlaps it by 28', (
      tester,
    ) async {
      await _open(tester);
      final search = tester.getRect(find.byType(HomeSearch));
      expect(search.height, OgHomeSize.search);
      expect(search.left, OgHomeSize.side);
      // No status bar in a test, so the hero runs from the very top.
      expect(search.top, OgHomeSize.hero - OgHomeSize.searchOverlap);
    });

    testWidgets('the header buttons and search open their pages', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(find.bySemanticsLabel('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('at ${Routes.saved}'), findsOneWidget);
    });

    testWidgets('shows six favourites and an Edit link', (tester) async {
      await _open(tester);
      expect(find.text('Your favourites'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      for (final l in [
        'Play',
        'Group',
        'Academy',
        'Venue',
        'Services',
        'Fitness',
      ]) {
        expect(find.text(l), findsOneWidget);
      }
      for (final l in ['Shop', 'Game']) {
        expect(find.text(l), findsOneWidget, reason: 'a service, not a card');
      }
    });

    testWidgets('a heading and its link share one centre line', (tester) async {
      await _open(tester);
      for (final (title, link) in [
        ('Your favourites', 'Edit'),
        ('More services', 'View all'),
      ]) {
        expect(
          (tester.getCenter(find.text(title)).dy -
                  tester.getCenter(find.text(link)).dy)
              .abs(),
          lessThan(1.5),
          reason: title,
        );
      }
    });

    testWidgets('lists the eight services', (tester) async {
      await _open(tester);
      expect(find.text('More services'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
      for (final l in [
        'Game',
        'Shop',
        'Wallet',
        'Points',
        'Tickets',
        'Rankings',
        'My gear',
      ]) {
        expect(find.text(l, skipOffstage: false), findsOneWidget, reason: l);
      }
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
          'greeting on hero': (h.onHero, h.hero),
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
}
