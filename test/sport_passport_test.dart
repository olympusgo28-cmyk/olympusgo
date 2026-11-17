// The Sport Passport (owner, 9 Nov 2026): the player's sports, each opening
// its Passport, and the sport profile rows that left Settings.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/motion_page.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/settings_list.dart';
import 'package:olympus_go/features/clubs/domain/club_sport.dart';
import 'package:olympus_go/features/guardian/application/guardian_providers.dart';
import 'package:olympus_go/features/guardian/domain/guardian_models.dart';
import 'package:olympus_go/features/profile/domain/profile.dart';
import 'package:olympus_go/features/profile/presentation/sport_passport_screen.dart';

const _phone = Size(402, 874);
const _tablet = Size(820, 1180);

const _badminton = PlayerSport(
  sport: 'badminton',
  level: 2,
  playMin: 1,
  playMax: 3,
);
const _pickleball = PlayerSport(
  sport: 'pickleball',
  level: 4.2,
  playMin: 3,
  playMax: 5,
);

Future<GoRouter> _open(
  WidgetTester tester, {
  Future<List<PlayerSport>> Function()? sports,
  bool restricted = false,
  ThemeData? theme,
  Size size = _phone,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: Routes.sportPassport,
    routes: [
      GoRoute(
        path: Routes.sportPassport,
        pageBuilder: (_, s) => MotionPage<void>(
          key: s.pageKey,
          child: const SportPassportScreen(),
        ),
      ),
      GoRoute(path: '/:rest(.*)', builder: (_, s) => Text('at ${s.uri}')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      // No automatic retry, so a failed load shows its error.
      retry: (_, _) => null,
      overrides: [
        mySportsProvider.overrideWith(
          (_) => (sports ?? () async => const [_badminton, _pickleball])(),
        ),
        mySummaryProvider.overrideWith(
          (_) async => const ProfileSummary(sessions: 12),
        ),
        restrictionsProvider.overrideWith(
          (_) async => Restrictions(restricted: restricted),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: theme ?? OgTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('lists your sports with their levels, then the sport profile', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Sport Passport'), findsOneWidget);
    expect(find.text('Your sports'), findsOneWidget);
    expect(find.text('Badminton'), findsOneWidget);
    expect(find.text(SkillBand.forLevel(2).code), findsOneWidget);
    expect(find.text('Pickleball'), findsOneWidget);
    expect(find.text(SkillBand.forLevel(4.2).code), findsOneWidget);
    expect(find.text('Sports and levels'), findsOneWidget);
    expect(find.text('Sport profile'), findsOneWidget);
    for (final row in [
      'Sessions and rating',
      'Challenges',
      'My gear',
      'Share profile',
    ]) {
      expect(find.text(row, skipOffstage: false), findsOneWidget, reason: row);
    }
    expect(find.text('12'), findsOneWidget);
    // Lessons are in the schedule, clubs on Home, followers in Settings.
    for (final gone in [
      'My lessons',
      'My clubs and teams',
      'Followers and following',
    ]) {
      expect(find.text(gone, skipOffstage: false), findsNothing, reason: gone);
    }
  });

  testWidgets('a level reads as its name to a screen reader', (tester) async {
    await _open(tester);
    final row = tester.getSemantics(
      find
          .ancestor(
            of: find.text('Badminton'),
            matching: find.byType(SettingsRow),
          )
          .first,
    );
    expect(row.value, SkillBand.forLevel(2).label);
  });

  testWidgets('a sport opens its Passport; Sports and levels the editor', (
    tester,
  ) async {
    final router = await _open(tester);
    await tester.tap(find.text('Pickleball'));
    await tester.pumpAndSettle();
    expect(find.text('at ${Routes.passportFor('pickleball')}'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sports and levels'));
    await tester.pumpAndSettle();
    expect(find.text('at ${Routes.profileSports}'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessions and rating'));
    await tester.pumpAndSettle();
    expect(find.text('at ${Routes.passport}'), findsOneWidget);
  });

  testWidgets('with no sports, Sports and levels says Add', (tester) async {
    await _open(tester, sports: () async => const []);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Badminton'), findsNothing);
  });

  testWidgets('while the sports load, their row waits in grey', (tester) async {
    final never = Completer<List<PlayerSport>>();
    await _open(tester, sports: () => never.future);
    expect(find.byType(SkeletonBlock), findsOneWidget);
    expect(find.text('Sessions and rating'), findsOneWidget);
  });

  testWidgets('a failed load says so, and Try again reloads', (tester) async {
    var calls = 0;
    await _open(
      tester,
      sports: () async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return const [_badminton];
      },
    );
    expect(find.textContaining("couldn't load your sports"), findsOneWidget);
    expect(find.text('Sessions and rating'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't load your sports"), findsNothing);
    expect(find.text('Badminton'), findsOneWidget);
  });

  testWidgets('groups are white on the grey page', (tester) async {
    await _open(tester);
    const c = OgColors.light;
    final page = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(page.backgroundColor, c.groupedBg);
  });

  group('goldens', () {
    for (final (name, theme) in [
      ('light', OgTheme.light()),
      ('dark', OgTheme.dark()),
    ]) {
      for (final (device, size) in [('phone', _phone), ('tablet', _tablet)]) {
        testWidgets('Sport Passport, $device, $name', (tester) async {
          await _open(tester, theme: theme, size: size);
          await expectLater(
            find.byType(SportPassportScreen),
            matchesGoldenFile('goldens/sport_passport_${device}_$name.png'),
          );
        });
      }
    }
  });
}
