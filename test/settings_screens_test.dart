// Settings and activity, its shared rows and sections, and the Profile menu
// button that opens it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/motion_page.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/theme/og_layout.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/theme/og_type.dart';
import 'package:olympus_go/core/widgets/og_icon.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/core/widgets/settings_list.dart';
import 'package:olympus_go/features/clubs/application/club_providers.dart';
import 'package:olympus_go/features/clubs/data/club_repository.dart';
import 'package:olympus_go/features/earnings/application/earnings_providers.dart';
import 'package:olympus_go/features/earnings/data/earnings_repository.dart';
import 'package:olympus_go/features/guardian/application/guardian_providers.dart';
import 'package:olympus_go/features/guardian/domain/guardian_models.dart';
import 'package:olympus_go/features/play/application/play_providers.dart';
import 'package:olympus_go/features/profile/domain/profile.dart';
import 'package:olympus_go/features/profile/presentation/profile_screen.dart';
import 'package:olympus_go/features/settings/data/settings_repository.dart';
import 'package:olympus_go/features/settings/domain/settings_models.dart';
import 'package:olympus_go/features/settings/presentation/settings_menu_screen.dart';
import 'package:olympus_go/features/shop/application/shop_providers.dart';
import 'package:olympus_go/features/social/application/social_providers.dart';
import 'package:olympus_go/features/social/domain/social_models.dart';

class _Settings implements SettingsRepository {
  @override
  Future<PrivacyPrefs> privacy() async =>
      const PrivacyPrefs(visibility: ProfileVisibility.onlyMe);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Me extends SessionProfile {
  @override
  Future<Profile?> build() async =>
      const Profile(id: 'u1', username: 'nicholas28', fullName: 'Nicholas Ong');
}

final List<Override> _data = [
  settingsRepositoryProvider.overrideWithValue(_Settings()),
  mySummaryProvider.overrideWith(
    (_) async => const ProfileSummary(sessions: 12),
  ),
  mySportsProvider.overrideWith(
    (_) async => const [
      PlayerSport(sport: 'badminton', level: 2, playMin: 1, playMax: 3),
    ],
  ),
  mySocialProvider.overrideWith(
    (_) async => const PlayerSocial(followers: 3, following: 5),
  ),
  myScheduleProvider.overrideWith((_) async => const []),
  clubListProvider(ClubTab.mine).overrideWith((_) async => const []),
  teamListProvider(ClubTab.mine).overrideWith((_) async => const []),
  myShopProvider.overrideWith((_) async => null),
  myChildrenProvider.overrideWith(
    (_) async => const [
      GuardianLink(linkId: 'l1', name: 'Kai', status: LinkStatus.approved),
    ],
  ),
];

const _phone = Size(402, 874);
const _tablet = Size(820, 1180);

Future<GoRouter> _openSettings(
  WidgetTester tester, {
  ThemeData? theme,
  Size size = _phone,
  bool restricted = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: Routes.settings,
    routes: [
      GoRoute(
        path: Routes.settings,
        pageBuilder: (_, s) =>
            MotionPage<void>(key: s.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: Routes.timeManagement,
        builder: (_, _) => const ComingSoonScreen(title: 'Time management'),
      ),
      GoRoute(path: '/:rest(.*)', builder: (_, s) => Text('at ${s.uri}')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._data,
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

/// One row on its own, in a phone-wide box.
Future<void> _row(WidgetTester tester, SettingsRow row) async {
  await tester.binding.setSurfaceSize(_phone);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: OgTheme.light(),
      home: Scaffold(body: SettingsSection(rows: [row])),
    ),
  );
}

/// The page's own scroller, not the search field's.
final _page = find
    .descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Finder _rowOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(SettingsRow));

Finder _chevron(String label) => find.descendant(
  of: _rowOf(label),
  matching: find.byWidgetPredicate(
    (w) => w is OgIcon && w.markup == OgIcons.chevronRight,
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SettingsRow', () {
    testWidgets('subtitle and value render; it reads label, subtitle, value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _row(
        tester,
        SettingsRow(
          icon: OgIcons.bell,
          label: 'Notifications',
          subtitle: 'Meets and messages',
          value: 'On',
          onTap: () {},
        ),
      );
      expect(find.text('Meets and messages'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      expect(
        tester.getSize(_rowOf('Notifications')).height,
        greaterThanOrEqualTo(OgSize.rowWithSubtitle),
      );
      expect(
        tester.getSemantics(_rowOf('Notifications')),
        matchesSemantics(
          label: 'Notifications, Meets and messages',
          value: 'On',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a read-only row has no chevron and is not a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _row(tester, const SettingsRow(label: 'Level', value: 'MB'));
      expect(_chevron('Level'), findsNothing);
      expect(
        tester.getSemantics(_rowOf('Level')),
        matchesSemantics(label: 'Level', value: 'MB'),
      );
      handle.dispose();
    });

    testWidgets('the dot shows only when asked, and is announced as New', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Finder dot() => find.descendant(
        of: _rowOf('Saved'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      await _row(tester, SettingsRow(label: 'Saved', onTap: () {}));
      expect(dot(), findsNothing);
      await _row(
        tester,
        SettingsRow(label: 'Saved', showDot: true, onTap: () {}),
      );
      expect(dot(), findsOneWidget);
      expect(tester.getSize(dot()), const Size.square(OgSize.dot));
      expect(
        tester.getSemantics(_rowOf('Saved')),
        matchesSemantics(
          label: 'Saved, New',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets(
      'a long value ends in an ellipsis at 60 % and the label stays',
      (tester) async {
        const long =
            'A very long value that cannot possibly fit on one line here';
        await _row(
          tester,
          SettingsRow(label: 'Bio', value: long, onTap: () {}),
        );
        final value = tester.widget<Text>(find.text(long));
        expect(value.maxLines, 1);
        expect(value.overflow, TextOverflow.ellipsis);
        final row = tester.getSize(_rowOf('Bio')).width;
        expect(
          tester.getSize(find.text(long)).width,
          lessThanOrEqualTo((row - 2 * OgSpace.s4) * 0.6),
        );
        final label = tester.widget<Text>(find.text('Bio'));
        expect(label.maxLines, isNull);
        expect(label.overflow, isNull);
      },
    );

    testWidgets('an empty value shows its empty text in the link colour', (
      tester,
    ) async {
      await _row(
        tester,
        SettingsRow(label: 'Bio', emptyText: 'Add', onTap: () {}),
      );
      final add = tester.widget<Text>(find.text('Add'));
      expect(add.style?.color, OgColors.light.link);
      expect(add.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('a trailing icon replaces the chevron', (tester) async {
      await _row(
        tester,
        SettingsRow(
          label: 'Profile link',
          value: 'olympusgo.com/nicholas28',
          trailingIcon: OgIcons.copy,
          onTap: () {},
        ),
      );
      expect(_chevron('Profile link'), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is OgIcon && w.markup == OgIcons.copy),
        findsOneWidget,
      );
    });

    testWidgets('a row without a subtitle is at least 56 tall', (tester) async {
      await _row(tester, SettingsRow(label: 'Help', onTap: () {}));
      expect(
        tester.getSize(_rowOf('Help')).height,
        greaterThanOrEqualTo(OgSize.row),
      );
    });
  });

  group('SettingsList search', () {
    final sections = [
      SettingsSection(
        label: 'Your account',
        rows: [
          SettingsRow(
            label: 'Account Centre',
            subtitle: 'Sign-in, security, personal details',
            onTap: () {},
          ),
          SettingsRow(label: 'Edit profile', onTap: () {}),
        ],
      ),
      SettingsSection(
        label: 'Support',
        rows: [SettingsRow(label: 'Help', onTap: () {})],
      ),
    ];

    Future<void> list(WidgetTester tester, String query) => tester.pumpWidget(
      MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: SettingsList(sections: sections, query: query),
        ),
      ),
    );

    testWidgets('finds rows by label and hides empty groups', (tester) async {
      await list(tester, 'edit');
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Account Centre'), findsNothing);
      expect(find.text('Your account'), findsOneWidget);
      expect(find.text('Support'), findsNothing);
      expect(find.text('Help'), findsNothing);
    });

    testWidgets('finds rows by subtitle', (tester) async {
      await list(tester, 'SECURITY');
      expect(find.text('Account Centre'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
    });

    testWidgets('says No results when nothing matches', (tester) async {
      await list(tester, 'zzz');
      expect(find.text('No results'), findsOneWidget);
      expect(find.byType(SettingsSection), findsNothing);
    });

    testWidgets('groups sit 8 apart on the background', (tester) async {
      await list(tester, '');
      final first = tester.getBottomLeft(find.byType(SettingsSection).first);
      final second = tester.getTopLeft(find.byType(SettingsSection).last);
      expect(second.dy - first.dy, OgSize.groupGap);
    });
  });

  group('Settings and activity', () {
    testWidgets('groups and the search bar are white on a light grey page', (
      tester,
    ) async {
      await _openSettings(tester);
      const c = OgColors.light;
      expect(c.groupedSurface, isNot(c.groupedBg));
      final page = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(page.backgroundColor, c.groupedBg);
      final bar = find.descendant(
        of: find.byType(KitHeader),
        matching: find.byType(Container),
      );
      expect(
        (tester.widget<Container>(bar.first).decoration! as BoxDecoration)
            .color,
        c.groupedBg,
      );
      final group = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.text('Your account'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(group.color, c.groupedSurface);
      final search = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((search.decoration! as BoxDecoration).color, c.groupedSurface);
    });

    test('dark mode keeps its page and group colours', () {
      expect(OgColors.dark.groupedBg, OgColors.dark.bg);
      expect(OgColors.dark.groupedSurface, OgColors.dark.surface);
    });

    testWidgets('has the groups, with values, and a centred title', (
      tester,
    ) async {
      await _openSettings(tester);
      expect(find.text('Settings and activity'), findsOneWidget);
      for (final group in [
        'Your account',
        'How you use OlympusGO',
        'Your activity',
        'Family',
        'Who can see your content',
        'Support',
      ]) {
        await tester.scrollUntilVisible(
          find.text(group),
          200,
          scrollable: _page,
        );
        expect(find.text(group), findsOneWidget);
      }
      expect(find.text('Only me'), findsOneWidget);
      expect(find.text('1 linked'), findsOneWidget);
      final title = tester.widget<Text>(find.text('Settings and activity'));
      expect(
        title.style?.fontSize,
        OgTheme.light().extension<OgType>()!.title.fontSize,
      );
    });

    testWidgets('holds what was the Profile account list', (tester) async {
      await _openSettings(tester);
      for (final row in [
        'Edit profile',
        'Sessions and rating',
        'Earnings and receipts',
        'Followers and following',
        'My orders',
        'My lessons',
        'Sports and levels',
        'My clubs and teams',
        'Account Centre',
        'My gear',
        'Challenges',
        'Share profile',
        'Saved',
        'Help',
      ]) {
        await tester.scrollUntilVisible(find.text(row), 200, scrollable: _page);
        expect(find.text(row), findsOneWidget, reason: row);
      }
    });

    testWidgets('search filters every group; empty groups hide', (
      tester,
    ) async {
      await _openSettings(tester);
      await tester.enterText(find.byType(TextField), 'priv');
      await tester.pumpAndSettle();
      expect(find.text('Account privacy'), findsOneWidget);
      expect(find.text('Who can see your content'), findsOneWidget);
      expect(find.text('Blocked accounts'), findsNothing);
      expect(find.text('Your account'), findsNothing);
      expect(find.text('Help'), findsNothing);

      await tester.enterText(find.byType(TextField), 'nothing like this');
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('rows open their screens; Time management is a placeholder', (
      tester,
    ) async {
      await _openSettings(tester);
      await tester.tap(find.text('Time management'));
      await tester.pumpAndSettle();
      expect(find.byType(ComingSoonScreen), findsOneWidget);
    });

    testWidgets('a player waiting on a parent sees only what they can open', (
      tester,
    ) async {
      await _openSettings(tester, restricted: true);
      for (final shown in [
        'Edit profile',
        'Notifications',
        'Guardian controls',
      ]) {
        await tester.scrollUntilVisible(
          find.text(shown),
          200,
          scrollable: _page,
        );
        expect(find.text(shown), findsOneWidget);
      }
      for (final hidden in [
        'Saved',
        'Bookings',
        'Sessions and rating',
        'My orders',
        'Payments and orders',
      ]) {
        expect(find.text(hidden, skipOffstage: false), findsNothing);
      }
    });

    testWidgets('a row opens from the keyboard and shows a focus ring', (
      tester,
    ) async {
      await _openSettings(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final ringed = find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            w.foregroundDecoration is BoxDecoration &&
            ((w.foregroundDecoration! as BoxDecoration).border as Border?)
                    ?.top
                    .width ==
                OgSize.focusRing,
      );
      expect(ringed, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('on a tablet the list centres at 560 wide', (tester) async {
      await _openSettings(tester, size: _tablet);
      final group = find.byType(SettingsSection).first;
      expect(tester.getSize(group).width, OgSize.readableWidth);
      expect(tester.getCenter(group).dx, _tablet.width / 2);
    });
  });

  group('Profile', () {
    testWidgets('the menu button beside the QR button opens Settings', (
      tester,
    ) async {
      // Wide, so the test font's square letters fit Profile's other rows.
      await tester.binding.setSurfaceSize(_tablet);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: Routes.settings,
            builder: (_, _) => const Text('at settings'),
          ),
          GoRoute(path: '/:rest(.*)', builder: (_, s) => Text('at ${s.uri}')),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._data,
            sessionProfileProvider.overrideWith(_Me.new),
            pointsSummaryProvider.overrideWith(
              (_) async => const PointsSummary(),
            ),
          ],
          child: MaterialApp.router(
            theme: OgTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('My QR code'), findsOneWidget);
      expect(find.text('Sessions and rating'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Settings and activity'));
      await tester.pumpAndSettle();
      expect(find.text('at settings'), findsOneWidget);
    });
  });

  group('goldens', () {
    for (final (name, theme) in [
      ('light', OgTheme.light()),
      ('dark', OgTheme.dark()),
    ]) {
      for (final (device, size) in [('phone', _phone), ('tablet', _tablet)]) {
        testWidgets('Settings and activity, $device, $name', (tester) async {
          await _openSettings(tester, theme: theme, size: size);
          await expectLater(
            find.byType(SettingsScreen),
            matchesGoldenFile('goldens/settings_${device}_$name.png'),
          );
        });
      }
    }
  });
}
