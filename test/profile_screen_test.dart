// Profile (owner, 16 Nov 2026): a header row of three plain icon buttons, and
// the Passport card moved to the sport profile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/core/widgets/pressable.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/play/domain/activity.dart';
import 'package:olympus_go/features/profile/application/past_sessions.dart';
import 'package:olympus_go/features/auth/presentation/saved_accounts.dart';
import 'package:olympus_go/features/auth/domain/saved_account.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/widgets/avatar.dart';
import 'package:olympus_go/core/widgets/og_icon.dart';
import 'package:olympus_go/core/widgets/og_rows.dart';
import 'package:olympus_go/features/clubs/application/club_providers.dart';
import 'package:olympus_go/features/clubs/data/club_repository.dart';
import 'package:olympus_go/features/earnings/application/earnings_providers.dart';
import 'package:olympus_go/features/earnings/data/earnings_repository.dart';
import 'package:olympus_go/features/play/application/play_providers.dart';
import 'package:olympus_go/features/profile/domain/profile.dart';
import 'package:olympus_go/features/profile/presentation/passport_card.dart';
import 'package:olympus_go/features/profile/presentation/passport_screen.dart';
import 'package:olympus_go/features/profile/presentation/profile_screen.dart';
import 'package:olympus_go/features/settings/application/settings_providers.dart';
import 'package:olympus_go/features/settings/domain/settings_models.dart';
import 'package:olympus_go/features/social/application/social_providers.dart';
import 'package:olympus_go/features/social/domain/social_models.dart';

class _Me extends SessionProfile {
  @override
  Future<Profile?> build() async =>
      const Profile(id: 'u1', username: 'nicholas28', fullName: 'Nicholas Ong');
}

class _MeWithBio extends SessionProfile {
  @override
  Future<Profile?> build() async => const Profile(
    id: 'u1',
    username: 'nicholas28',
    fullName: 'Nicholas Ong',
    bio: 'Doubles on weeknights.',
    links: ['olympusgo.example/nicholas'],
  );
}

/// Records which account was opened.
class _Auth implements AuthRepository {
  String? unlocked;

  @override
  Future<void> unlockAccount(String userId) async => unlocked = userId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _twoSports = [
  PlayerSport(sport: 'badminton', level: 2, playMin: 1, playMax: 3),
  PlayerSport(sport: 'tennis', level: 3, playMin: 2, playMax: 4),
];

class _MeFull extends SessionProfile {
  @override
  Future<Profile?> build() async => const Profile(
    id: 'u1',
    username: 'nicholas28',
    fullName: 'Nicholas Ong',
    heightCm: 178,
    birthplace: 'Singapore',
  );
}

final List<Override> _data = [
  myPastSessionsProvider.overrideWith(
    (_) async => [
      HistoryItem(
        id: 'h1',
        kind: 'meet',
        title: 'Doubles Social',
        at: DateTime(2026, 11, 14, 19, 30),
        played: 5,
        won: 3,
      ),
      HistoryItem(
        id: 'h2',
        kind: 'class',
        title: 'Adult Improvers',
        at: DateTime(2026, 11, 12, 19, 30),
      ),
      HistoryItem(
        id: 'h3',
        kind: 'meet',
        title: 'Morning Singles',
        at: DateTime(2026, 11, 8, 8),
      ),
      HistoryItem(
        id: 'h4',
        kind: 'tournament',
        title: 'Bedok Open',
        at: DateTime(2026, 10, 25, 9),
        played: 4,
        won: 3,
      ),
    ],
  ),
  mySocialProvider.overrideWith(
    (_) async => const PlayerSocial(followers: 3, following: 5),
  ),
  clubListProvider(ClubTab.mine).overrideWith((_) async => const []),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Override> extra = const [],
  SessionProfile Function()? me,
  ProfileSummary summary = const ProfileSummary(
    sessions: 12,
    clubRank: 3,
    localRank: 8,
  ),
  PointsSummary wallet = const PointsSummary(),
  List<Activity> schedule = const [],
  List<PlayerSport> sports = _twoSports,
  PrivateInfo info = const PrivateInfo(),
}) async {
  // Tall and wide, so the test font's square letters fit.
  await tester.binding.setSurfaceSize(const Size(820, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._data,
        sessionProfileProvider.overrideWith(me ?? _Me.new),
        mySummaryProvider.overrideWith((_) async => summary),
        pointsSummaryProvider.overrideWith((_) async => wallet),
        myScheduleProvider.overrideWith((_) async => schedule),
        mySportsProvider.overrideWith((_) async => sports),
        privateInfoProvider.overrideWith((_) async => info),
        ...extra,
      ],
      child: MaterialApp.router(
        theme: OgTheme.light(),
        routerConfig: GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => screen)],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Header row', () {
    testWidgets('switch account at the left, the three icons at the right', (
      tester,
    ) async {
      await _pump(tester, const ProfileScreen());
      final switcher = find.bySemanticsLabel(
        RegExp('^Switch account, nicholas28'),
      );
      expect(switcher, findsOneWidget);
      final qr = find.bySemanticsLabel('My QR code');
      final card = find.bySemanticsLabel('Sport Passport');
      final menu = find.bySemanticsLabel('Settings and activity');
      final xs = [
        tester.getCenter(switcher).dx,
        tester.getCenter(qr).dx,
        tester.getCenter(card).dx,
        tester.getCenter(menu).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      // The control reads: lock icon, username, dropdown icon.
      final icons = tester
          .widgetList<OgIcon>(
            find.descendant(of: switcher, matching: find.byType(OgIcon)),
          )
          .map((i) => i.markup)
          .toList();
      expect(icons, [OgIcons.lock, OgIcons.chevronDown]);
      expect(
        find.descendant(of: switcher, matching: find.text('nicholas28')),
        findsOneWidget,
      );
    });

    testWidgets('the three icon buttons have no circle', (tester) async {
      await _pump(tester, const ProfileScreen());
      final buttons = tester.widgetList<KitIconButton>(
        find.byType(KitIconButton),
      );
      expect(buttons.map((b) => b.label), [
        'My QR code',
        'Sport Passport',
        'Settings and activity',
      ]);
      for (final b in buttons) {
        expect(b.border, isFalse, reason: b.label);
        expect(b.background, isNull, reason: b.label);
      }
    });

    testWidgets('the switcher opens a sheet; another account can be opened', (
      tester,
    ) async {
      final auth = _Auth();
      await _pump(
        tester,
        const ProfileScreen(),
        extra: [
          authRepositoryProvider.overrideWithValue(auth),
          savedAccountsProvider.overrideWith(
            (_) async => const [
              SavedAccount(
                userId: 'u1',
                displayName: 'Nicholas Ong',
                maskedIdentifier: '@nicholas28',
              ),
              SavedAccount(
                userId: 'u2',
                displayName: 'Mei Wong',
                maskedIdentifier: '•••• 0002',
              ),
            ],
          ),
        ],
      );
      await tester.tap(
        find.bySemanticsLabel(RegExp('^Switch account, nicholas28')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Switch account'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Nicholas Ong, current account')),
        findsOneWidget,
      );
      expect(find.text('Mei Wong'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^Switch to Mei Wong')));
      await tester.pumpAndSettle();
      expect(auth.unlocked, 'u2');
      expect(find.text('Switch account'), findsNothing, reason: 'sheet closed');
    });

    testWidgets('with no other account the sheet says so', (tester) async {
      await _pump(
        tester,
        const ProfileScreen(),
        extra: [savedAccountsProvider.overrideWith((_) async => const [])],
      );
      await tester.tap(
        find.bySemanticsLabel(RegExp('^Switch account, nicholas28')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No other accounts'), findsOneWidget);
      // The open account is still listed.
      expect(find.text('Nicholas Ong'), findsWidgets);
    });
  });

  group('Profile row', () {
    testWidgets('avatar with an orange add button at its bottom right', (
      tester,
    ) async {
      await _pump(tester, const ProfileScreen());
      final avatar = tester.getRect(find.byType(Avatar));
      expect(avatar.size, const Size(80, 80));
      final ctx = tester.element(find.byType(ProfileScreen));
      final plus = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == ctx.og.primary &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      expect(plus, findsOneWidget);
      final badge = tester.getRect(plus);
      expect(badge.size, const Size(28, 28));
      expect(badge.center.dx, greaterThan(avatar.center.dx));
      expect(badge.center.dy, greaterThan(avatar.center.dy));
      expect(
        tester
            .widgetList<OgIcon>(find.byType(OgIcon))
            .any((i) => i.markup == OgIcons.plus),
        isTrue,
      );
    });

    testWidgets('the display name, then Following, Followers and Play', (
      tester,
    ) async {
      await _pump(tester, const ProfileScreen());
      final name = find.text('Nicholas Ong');
      expect(name, findsOneWidget);
      final style = tester.widget<Text>(name).style!;
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w500);
      // Number over label.
      for (final (n, label) in [
        ('5', 'Following'),
        ('3', 'Followers'),
        ('12', 'Play'),
      ]) {
        expect(find.bySemanticsLabel(RegExp('^$n $label')), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(n).first).dy,
          lessThan(tester.getTopLeft(find.text(label)).dy),
        );
      }
      // Beside the avatar, name above the counts.
      expect(
        tester.getTopLeft(name).dy,
        lessThan(tester.getTopLeft(find.text('Following')).dy),
      );
      expect(
        tester.getTopLeft(name).dx,
        greaterThan(tester.getRect(find.byType(Avatar)).right),
      );
    });
  });

  group('Bio and links rows', () {
    testWidgets('the bio shows under the profile row', (tester) async {
      await _pump(tester, const ProfileScreen(), me: _MeWithBio.new);
      final bio = find.text('Doubles on weeknights.');
      expect(bio, findsOneWidget);
      expect(
        tester.getTopLeft(bio).dy,
        greaterThan(tester.getBottomLeft(find.text('Following')).dy),
      );
      expect(find.text('Add a bio'), findsNothing);
    });

    testWidgets('with no bio there is an Add a bio prompt', (tester) async {
      await _pump(tester, const ProfileScreen());
      expect(find.text('Add a bio'), findsOneWidget);
    });

    testWidgets('links show under the bio', (tester) async {
      await _pump(tester, const ProfileScreen(), me: _MeWithBio.new);
      final link = find.text('olympusgo.example/nicholas');
      expect(link, findsOneWidget);
      expect(
        tester.getTopLeft(link).dy,
        greaterThan(
          tester.getBottomLeft(find.text('Doubles on weeknights.')).dy,
        ),
      );
    });

    testWidgets('with no links there is no links row', (tester) async {
      await _pump(tester, const ProfileScreen());
      expect(
        find.byWidgetPredicate((w) => w is OgIcon && w.markup == OgIcons.link),
        findsNothing,
      );
    });
  });

  group('Body row', () {
    testWidgets('past sessions, in Meet, Event and Tournament pill tabs', (
      tester,
    ) async {
      await _pump(tester, const ProfileScreen());
      final tabs = tester.widget<PillTabs>(find.byType(PillTabs));
      expect(tabs.labels, ['Meet', 'Event', 'Tournament']);
      expect(tabs.index, 0);
      // Meets first, newest first.
      expect(find.text('Doubles Social'), findsOneWidget);
      expect(find.text('Morning Singles'), findsOneWidget);
      expect(find.text('Bedok Open'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Doubles Social')).dy,
        lessThan(tester.getTopLeft(find.text('Morning Singles')).dy),
      );
      expect(find.textContaining('Won 3 of 5 games'), findsOneWidget);
    });

    testWidgets('a tab shows only its kind; an empty one says so', (
      tester,
    ) async {
      await _pump(tester, const ProfileScreen());
      await tester.tap(find.bySemanticsLabel('Tournament'));
      await tester.pumpAndSettle();
      expect(find.text('Bedok Open'), findsOneWidget);
      expect(find.text('Doubles Social'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Event'));
      await tester.pumpAndSettle();
      expect(find.text('No past Events yet'), findsOneWidget);
    });

    testWidgets('classes are not listed', (tester) async {
      await _pump(tester, const ProfileScreen());
      expect(find.text('Adult Improvers'), findsNothing);
    });
  });

  group('Points, badges and next sessions', () {
    const badges = [
      ProfileBadge(mark: 'T', name: 'First tournament'),
      ProfileBadge(mark: 'S', name: 'Ten sessions'),
    ];

    testWidgets('they sit above the past sessions', (tester) async {
      await _pump(
        tester,
        const ProfileScreen(),
        summary: const ProfileSummary(
          sessions: 12,
          badges: badges,
          badgeCount: 5,
        ),
        wallet: const PointsSummary(minor: 2120),
      );
      final ys = [
        tester.getTopLeft(find.text('Following')).dy,
        tester.getTopLeft(find.textContaining('points').first).dy,
        tester.getTopLeft(find.text('Badges')).dy,
        tester.getTopLeft(find.text('Next sessions')).dy,
        tester.getTopLeft(find.byType(PillTabs)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
    });

    testWidgets('the points banner: amount, a line under it, Use points', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        wallet: const PointsSummary(minor: 2120, pendingMinor: 500),
      );
      expect(find.text('212 points'), findsOneWidget);
      expect(find.text('50 more pending'), findsOneWidget);
      expect(find.text('Use points'), findsOneWidget);
    });

    testWidgets('no points banner when there is nothing to show', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        wallet: const PointsSummary(earning: false),
      );
      expect(find.textContaining('points'), findsNothing);
    });

    testWidgets('badges: the latest few, and how many are earned', (
      tester,
    ) async {
      await _pump(
        tester,
        const ProfileScreen(),
        summary: const ProfileSummary(badges: badges, badgeCount: 5),
      );
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('5 earned'), findsOneWidget);
      expect(find.text('First tournament'), findsOneWidget);
      expect(find.text('Ten sessions'), findsOneWidget);
    });

    testWidgets('with no badges there is no Badges section', (tester) async {
      await _pump(tester, const ProfileScreen());
      expect(find.text('Badges'), findsNothing);
    });

    testWidgets('next sessions: nothing booked, and who sees them', (
      tester,
    ) async {
      await _pump(tester, const ProfileScreen());
      expect(find.text('Next sessions'), findsOneWidget);
      expect(find.text('Nothing booked'), findsOneWidget);
      expect(find.text('Shown to: Followers · Change'), findsOneWidget);
    });

    testWidgets('next sessions lists what is booked, three at most', (
      tester,
    ) async {
      // The demo repository waits on a timer, so run it outside the fake clock.
      final meets = (await tester.runAsync(
        () => DemoPlayRepository().upcoming(kind: ActivityKind.meet),
      ))!;
      final booked = [
        for (final (i, m) in meets.take(4).indexed)
          m.copyWith(id: 'b$i', title: 'Booked $i', clubId: null),
      ];
      await _pump(tester, const ProfileScreen(), schedule: booked);
      expect(find.text('Nothing booked'), findsNothing);
      expect(find.text('Booked 0'), findsOneWidget);
      expect(find.text('Booked 2'), findsOneWidget);
      expect(find.text('Booked 3'), findsNothing, reason: 'three at most');
    });

    testWidgets('the Passport card is still not on Profile', (tester) async {
      await _pump(tester, const ProfileScreen());
      expect(find.textContaining('PASSPORT ·'), findsNothing);
      expect(find.text('MAIN SPORT'), findsNothing);
      expect(find.text('See leaderboards'), findsNothing);
    });
  });

  group('Sport profile', () {
    testWidgets('has the Passport card for the sport on show', (tester) async {
      await _pump(tester, const PassportScreen());
      expect(find.text('PASSPORT · BADMINTON'), findsOneWidget);
      expect(find.text('MAIN SPORT'), findsOneWidget);
      expect(find.text('12'), findsWidgets, reason: 'sessions');
      expect(find.text('#3'), findsOneWidget, reason: 'club rank');
      expect(find.textContaining('See leaderboards'), findsOneWidget);
    });

    testWidgets('another sport has the card without the MAIN SPORT pill', (
      tester,
    ) async {
      await _pump(tester, const PassportScreen(initialSport: 'tennis'));
      expect(find.text('PASSPORT · TENNIS'), findsOneWidget);
      expect(find.text('MAIN SPORT'), findsNothing);
    });

    testWidgets('the card itself is not a button; its link is', (tester) async {
      await _pump(tester, const PassportScreen());
      // The only tap target inside the card is "See leaderboards".
      expect(
        find.descendant(
          of: find.byType(PassportCard),
          matching: find.byType(Pressable),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the hero covers the width; back and share sit over it', (
      tester,
    ) async {
      await _pump(tester, const PassportScreen());
      final width = tester.getSize(find.byType(Scaffold)).width;
      final back = tester.getRect(find.bySemanticsLabel('Back'));
      final share = tester.getRect(find.bySemanticsLabel('Share'));
      // Close to the screen's edges, not inset like the page's content.
      expect(back.left, 12);
      expect(share.right, width - 12);
      expect(back.size, const Size(44, 44));
      expect(back.top, share.top);
      final hero = tester.getRect(
        find
            .byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).color ==
                      OgColors.charcoal900,
            )
            .first,
      );
      expect(hero.left, 0);
      expect(hero.right, width);
    });

    testWidgets(
      'the personal card: photo, name, flag, age, height, birthplace',
      (tester) async {
        await _pump(
          tester,
          const PassportScreen(),
          me: _MeFull.new,
          info: PrivateInfo(birthday: DateTime(2000, 1, 1)),
        );
        expect(find.byType(Avatar), findsOneWidget);
        expect(find.text('Nicholas Ong'), findsOneWidget);
        expect(
          find.text('Singapore'),
          findsNWidgets(2),
          reason: 'country, birthplace',
        );
        expect(find.text('178 cm'), findsOneWidget);
        final now = DateTime.now();
        final age = now.year - 2000 - (now.month == 1 && now.day < 1 ? 1 : 0);
        expect(find.text('$age'), findsOneWidget);
        for (final label in ['Age', 'Height', 'Birthplace', 'Ranking']) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        // Name above the boxes, hero above the card.
        expect(
          tester.getTopLeft(find.text('Nicholas Ong')).dy,
          lessThan(tester.getTopLeft(find.text('Age')).dy),
        );
      },
    );

    testWidgets('with no data the boxes show a dash', (tester) async {
      await _pump(
        tester,
        const PassportScreen(),
        summary: const ProfileSummary(),
      );
      expect(
        find.text('—'),
        findsNWidgets(4),
        reason: 'age, height, birthplace, ranking',
      );
    });

    testWidgets('ranking, and the best doubles ranking with the partner', (
      tester,
    ) async {
      await _pump(
        tester,
        const PassportScreen(),
        summary: const ProfileSummary(
          localRank: 8,
          area: 'Tampines',
          bestDoublesRank: 3,
          bestDoublesPartner: 'Mei Wong',
        ),
      );
      expect(find.text('#8'), findsOneWidget);
      expect(find.text('Tampines'), findsOneWidget);
      expect(find.text('Best doubles'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('with Mei Wong'), findsOneWidget);
    });

    testWidgets('no best doubles box when there is none', (tester) async {
      await _pump(
        tester,
        const PassportScreen(),
        summary: const ProfileSummary(localRank: 8),
      );
      expect(find.text('Best doubles'), findsNothing);
    });

    testWidgets('the sport selector holds the main sports, five at most', (
      tester,
    ) async {
      const seven = [
        PlayerSport(sport: 'badminton', level: 2, playMin: 1, playMax: 3),
        PlayerSport(sport: 'tennis', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'squash', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'padel', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'cycling', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'football', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'hyrox', level: 3, playMin: 2, playMax: 4),
      ];
      await _pump(tester, const PassportScreen(), sports: seven);
      for (final s in ['Badminton', 'Tennis', 'Squash', 'Padel', 'Cycling']) {
        expect(find.bySemanticsLabel(s), findsOneWidget, reason: s);
      }
      expect(find.bySemanticsLabel('Football'), findsNothing);
      expect(find.bySemanticsLabel('Hyrox'), findsNothing);
    });

    testWidgets('a sport opened from the list takes the fifth place', (
      tester,
    ) async {
      const seven = [
        PlayerSport(sport: 'badminton', level: 2, playMin: 1, playMax: 3),
        PlayerSport(sport: 'tennis', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'squash', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'padel', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'cycling', level: 3, playMin: 2, playMax: 4),
        PlayerSport(sport: 'football', level: 3, playMin: 2, playMax: 4),
      ];
      await _pump(
        tester,
        const PassportScreen(initialSport: 'football'),
        sports: seven,
      );
      expect(find.text('PASSPORT · FOOTBALL'), findsOneWidget);
      expect(find.bySemanticsLabel('Cycling'), findsNothing);
    });

    testWidgets('selecting a sport shows its overview; the tabs stay', (
      tester,
    ) async {
      await _pump(tester, const PassportScreen());
      for (final t in ['Overview', 'Gear', 'Upcoming', 'Challenges']) {
        expect(find.bySemanticsLabel(t), findsOneWidget, reason: t);
      }
      await tester.tap(find.bySemanticsLabel('Tennis'));
      await tester.pumpAndSettle();
      expect(find.text('PASSPORT · TENNIS'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Gear'));
      await tester.pumpAndSettle();
      expect(find.text('Your tennis gear'), findsOneWidget);
    });
  });
}
