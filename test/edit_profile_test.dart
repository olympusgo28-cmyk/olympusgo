// Edit profile on the shared outlined sections, and its edit screens.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/motion_page.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/theme/og_layout.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_icon.dart';
import 'package:olympus_go/core/widgets/settings_list.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/profile/data/profile_repository.dart';
import 'package:olympus_go/features/profile/domain/profile.dart';
import 'package:olympus_go/features/settings/data/settings_repository.dart';
import 'package:olympus_go/features/settings/domain/my_profile.dart';
import 'package:olympus_go/features/settings/domain/settings_models.dart';
import 'package:olympus_go/features/settings/presentation/edit_profile_screens.dart';

const _details = AccountDetails(
  fullName: 'Nicholas Ong',
  username: 'nicholasong',
  bio: 'Badminton on weekday nights.\nPickleball on Sundays.',
  gender: Gender.male,
);

const _sports = [
  PlayerSport(sport: 'badminton', level: 2, playMin: 1, playMax: 3),
  PlayerSport(sport: 'pickleball', level: 3, playMin: 2, playMax: 4),
];

class _Settings implements SettingsRepository {
  _Settings([this.answers = const [_details]]);

  /// One answer per load: details, an error to throw, or a future.
  final List<Object> answers;
  var loads = 0;

  /// Each save, as the columns it wrote.
  final saved = <Map<String, Object>>[];
  var removed = 0;
  AuthFailure? refuseSave;
  AuthFailure? refuseRemove;

  @override
  Future<AccountDetails> account() async {
    final a = answers[loads < answers.length ? loads : answers.length - 1];
    loads++;
    if (a is Future<AccountDetails>) return a;
    if (a is AuthFailure) throw a;
    return a as AccountDetails;
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    Gender? gender,
  }) async {
    if (refuseSave != null) throw refuseSave!;
    saved.add({
      'full_name': ?fullName,
      'username': ?username,
      'bio': ?bio,
      'gender': ?gender,
    });
  }

  @override
  Future<void> removeAvatar() async {
    if (refuseRemove != null) throw refuseRemove!;
    removed++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements ProfileRepository {
  _Profiles({this.failSports = 0});

  final taken = {'hannah'};
  final asked = <String>[];

  /// How many sports loads fail before one works.
  int failSports;

  @override
  Future<List<PlayerSport>> sports(String userId) async {
    if (failSports > 0) {
      failSports--;
      throw const AuthFailure('offline');
    }
    return _sports;
  }

  @override
  Future<bool> usernameAvailable(String username) async {
    asked.add(username);
    return !taken.contains(username);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Me extends SessionProfile {
  @override
  Future<Profile?> build() async => const Profile(id: 'u1');

  @override
  Future<void> reload() async {}
}

const _phone = Size(402, 874);
const _tablet = Size(820, 1180);

Future<GoRouter> _open(
  WidgetTester tester, {
  _Settings? settings,
  _Profiles? profiles,
  ThemeData? theme,
  Size size = _phone,
  bool onboarding = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  GoRoute route(String path, Widget child) => GoRoute(
    path: path,
    pageBuilder: (_, s) => MotionPage<void>(key: s.pageKey, child: child),
  );
  final router = GoRouter(
    initialLocation: Routes.editProfile,
    routes: [
      route(Routes.editProfile, EditProfileScreen(onboarding: onboarding)),
      route(
        Routes.editName,
        const ProfileFieldScreen(field: ProfileField.name),
      ),
      route(Routes.editBio, const ProfileFieldScreen(field: ProfileField.bio)),
      route(Routes.editUsername, const ChangeUsernameScreen()),
      GoRoute(path: '/:rest(.*)', builder: (_, s) => Text('at ${s.uri}')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings ?? _Settings()),
        profileRepositoryProvider.overrideWithValue(profiles ?? _Profiles()),
        currentUserIdProvider.overrideWith((_) => Stream.value('u1')),
        sessionProfileProvider.overrideWith(_Me.new),
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

Finder _row(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(SettingsRow));

/// Lets a toast finish so no timer is left at the end of a test.
Future<void> _toastGone(WidgetTester tester) async {
  // Fade in, wait, fade out: the wait only starts once the fade-in ends.
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('MyProfile', () {
    test('rows read the details', () {
      final p = MyProfile.from(_details, _sports);
      expect(p.bioFirstLine, 'Badminton on weekday nights.');
      expect(p.sportsText, 'Badminton, Pickleball');
      expect(p.levelsText, contains('Badminton'));
      expect(p.linkText, isNot(startsWith('http')));
      expect(p.linkText, endsWith('/nicholasong'));
      expect(p.initials, 'NO');
      expect(p.toString(), isNot(contains('Nicholas')));
    });
  });

  group('Edit profile', () {
    testWidgets('header, values on the right, Level read-only', (tester) async {
      await _open(tester);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Change photo'), findsOneWidget);
      expect(find.text('Nicholas Ong'), findsNWidgets(2));
      expect(find.text('@nicholasong'), findsOneWidget);
      expect(find.text('nicholasong'), findsOneWidget);
      expect(find.text('Badminton on weekday nights.'), findsOneWidget);
      expect(find.text('Badminton, Pickleball'), findsOneWidget);
      expect(find.text('About you'), findsOneWidget);

      // The value sits at the right end of its row.
      final row = tester.getRect(_row('Username'));
      final value = tester.getRect(find.text('nicholasong'));
      expect(value.center.dx, greaterThan(row.center.dx));

      // Level has no chevron; the rest do, and Profile link has a copy icon.
      Finder icons(String label) =>
          find.descendant(of: _row(label), matching: find.byType(OgIcon));
      expect(icons('Level'), findsNothing);
      expect(icons('Bio'), findsOneWidget);
      expect(
        find.descendant(
          of: _row('Profile link'),
          matching: find.byWidgetPredicate(
            (w) => w is OgIcon && w.markup == OgIcons.copy,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('long values end in an ellipsis', (tester) async {
      await _open(
        tester,
        settings: _Settings([
          _details.copyWith(
            bio:
                'Badminton every weekday night at Tampines and pickleball '
                'on Sunday mornings with anyone who wants a game',
          ),
        ]),
      );
      final bio = tester.widget<Text>(
        find.descendant(of: _row('Bio'), matching: find.byType(Text)).last,
      );
      expect(bio.maxLines, 1);
      expect(bio.overflow, TextOverflow.ellipsis);
    });

    testWidgets('an empty bio shows Add in the link colour', (tester) async {
      await _open(tester, settings: _Settings([_details.copyWith(bio: '')]));
      final add = tester.widget<Text>(
        find.descendant(of: _row('Bio'), matching: find.text('Add')),
      );
      expect(add.style?.color, OgColors.light.link);
    });

    testWidgets('the copy icon copies the link and says so', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Profile link'));
      await tester.pump();
      expect(copied, startsWith('https://'));
      expect(copied, endsWith('/nicholasong'));
      expect(find.text('Link copied'), findsOneWidget);
      await _toastGone(tester);
    });

    testWidgets('a name edit saves, comes back with it and says Saved', (
      tester,
    ) async {
      final settings = _Settings();
      await _open(tester, settings: settings);
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileFieldScreen), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Nick Ong');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Only the name is written, so nothing else can be undone.
      expect(settings.saved.single, {'full_name': 'Nick Ong'});
      expect(find.byType(ProfileFieldScreen), findsNothing);
      expect(find.text('Nick Ong'), findsNWidgets(2));
      expect(find.text('Saved'), findsOneWidget);
      await _toastGone(tester);
    });

    testWidgets('an empty name is refused on its screen', (tester) async {
      final settings = _Settings();
      await _open(tester, settings: settings);
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your name.'), findsWidgets);
      expect(settings.saved, isEmpty);
    });

    testWidgets('a bio and a gender save on their own', (tester) async {
      final settings = _Settings();
      await _open(tester, settings: settings);
      await tester.tap(find.text('Bio'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Doubles, any level.');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(settings.saved.single, {'bio': 'Doubles, any level.'});
      expect(find.text('Doubles, any level.'), findsOneWidget);
      await _toastGone(tester);

      await tester.tap(find.text('Gender'));
      await tester.pumpAndSettle();
      // The wheel starts on Male; one row up is Female.
      await tester.drag(find.text('Male').last, const Offset(0, -40));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(settings.saved.last, {'gender': Gender.female});
      expect(find.text('Female'), findsOneWidget);
      await _toastGone(tester);
    });

    testWidgets('a refused save says why and stays on the screen', (
      tester,
    ) async {
      final settings = _Settings()
        ..refuseSave = const AuthFailure(
          'That username is taken. Try another one.',
        );
      await _open(tester, settings: settings);
      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'nick_ong');
      await tester.pump(OgMotion.debounce);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('That username is taken. Try another one.'),
        findsOneWidget,
      );
      expect(find.byType(ChangeUsernameScreen), findsOneWidget);
    });

    testWidgets(
      'right after onboarding, Continue goes to Account information',
      (tester) async {
        await _open(tester, onboarding: true);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('at ${Routes.setupPersonal}'), findsOneWidget);
      },
    );

    testWidgets('loading shows skeletons, then the details', (tester) async {
      final later = Completer<AccountDetails>();
      await _open(tester, settings: _Settings([later.future]));
      expect(find.byType(SkeletonBlock), findsWidgets);
      expect(find.text('Name'), findsOneWidget);
      later.complete(_details);
      await tester.pumpAndSettle();
      expect(find.text('@nicholasong'), findsOneWidget);
    });

    testWidgets('sports that fail to load offer Try again at once', (
      tester,
    ) async {
      await _open(tester, profiles: _Profiles(failSports: 1));
      expect(find.textContaining("couldn't load your profile"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Badminton, Pickleball'), findsOneWidget);
    });

    testWidgets('an error offers Try again, which loads it', (tester) async {
      await _open(
        tester,
        settings: _Settings([const AuthFailure('offline'), _details]),
      );
      expect(find.textContaining("couldn't load your profile"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('@nicholasong'), findsOneWidget);
    });

    testWidgets('on a tablet the column centres at 560 wide', (tester) async {
      await _open(tester, size: _tablet);
      final group = find.byType(SettingsSection).first;
      expect(tester.getSize(group).width, OgSize.readableWidth);
      expect(tester.getCenter(group).dx, _tablet.width / 2);
    });
  });

  group('Username', () {
    testWidgets('shows the rules and checks a new name after a pause', (
      tester,
    ) async {
      final profiles = _Profiles();
      final settings = _Settings();
      await _open(tester, settings: settings, profiles: profiles);
      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 to 30 letters'), findsOneWidget);
      expect(find.text('This is your username.'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'hannah');
      await tester.pump();
      expect(find.text('Checking…'), findsOneWidget);
      expect(profiles.asked, isEmpty, reason: 'waits for typing to stop');
      await tester.pump(OgMotion.debounce);
      await tester.pump();
      expect(profiles.asked, ['hannah']);
      expect(
        find.text('That username is taken. Try another one.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(EditableText), 'nick_ong');
      await tester.pump(OgMotion.debounce);
      await tester.pump();
      expect(find.text('nick_ong is available'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(settings.saved.single, {'username': 'nick_ong'});
      expect(find.text('nick_ong'), findsOneWidget);
      await _toastGone(tester);
    });

    testWidgets('a short name is refused before any check', (tester) async {
      final profiles = _Profiles();
      await _open(tester, profiles: profiles);
      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'ab');
      await tester.pump(OgMotion.debounce);
      await tester.pump();
      expect(find.text('Use at least 3 characters.'), findsOneWidget);
      expect(profiles.asked, isEmpty);
    });
  });

  group('photo', () {
    testWidgets('Remove photo is offered only when there is a photo', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from library'), findsOneWidget);
      expect(find.text('Remove photo'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final settings = _Settings([
        _details.copyWith(
          avatarUrl: '/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png',
        ),
      ]);
      await _open(tester, settings: settings);
      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(settings.removed, 1);
      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      expect(find.text('Remove photo'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('a photo that cannot be removed stays, with the reason', (
      tester,
    ) async {
      final settings =
          _Settings([
              _details.copyWith(
                avatarUrl: '/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png',
              ),
            ])
            ..refuseRemove = const AuthFailure(
              "Your photo wasn't removed. Try again.",
            );
      await _open(tester, settings: settings);
      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(
        find.text("Your photo wasn't removed. Try again."),
        findsOneWidget,
      );
      await _toastGone(tester);
      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      expect(find.text('Remove photo'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });

  group('goldens', () {
    for (final (name, theme) in [
      ('light', OgTheme.light()),
      ('dark', OgTheme.dark()),
    ]) {
      for (final (device, size) in [('phone', _phone), ('tablet', _tablet)]) {
        testWidgets('Edit profile, $device, $name', (tester) async {
          await _open(tester, theme: theme, size: size);
          await expectLater(
            find.byType(EditProfileScreen),
            matchesGoldenFile('goldens/edit_profile_${device}_$name.png'),
          );
        });
      }
    }
  });
}
