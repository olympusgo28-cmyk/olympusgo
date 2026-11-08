// Owner's redesign of 8 Nov 2026 (Q247 to Q254): sign-in, code screens,
// skills, Edit profile and Account information.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/domain/country.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_buttons.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/core/widgets/resend_timer.dart';
import 'package:olympus_go/features/auth/application/pending_code.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:olympus_go/features/auth/domain/saved_account.dart';
import 'package:olympus_go/features/auth/presentation/code_copy.dart';
import 'package:olympus_go/features/auth/presentation/code_screen.dart';
import 'package:olympus_go/features/auth/presentation/log_in_account_screen.dart';
import 'package:olympus_go/features/auth/presentation/log_in_screen.dart';
import 'package:olympus_go/features/auth/presentation/welcome_screen.dart';
import 'package:olympus_go/features/onboarding/application/onboarding_controller.dart';
import 'package:olympus_go/features/onboarding/domain/onboarding_models.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';
import 'package:olympus_go/features/onboarding/presentation/sports_screens.dart';
import 'package:olympus_go/features/profile/domain/profile.dart';
import 'package:olympus_go/features/settings/application/settings_providers.dart';
import 'package:olympus_go/features/settings/data/settings_repository.dart';
import 'package:olympus_go/features/settings/domain/settings_models.dart';
import 'package:olympus_go/features/settings/presentation/settings_screens.dart';

class _Auth implements AuthRepository {
  _Auth({this.saved = const [], this.userId});

  List<SavedAccount> saved;
  final String? userId;
  final sent = <(String, bool)>[];

  @override
  String? get currentUserId => userId;
  @override
  Future<void> rememberAccount({
    required String displayName,
    String? avatarUrl,
    String? username,
  }) async {}
  @override
  Stream<String?> get userIdChanges => const Stream.empty();

  /// Answers later, like the Keychain does, so a screen must keep the list
  /// alive while it waits.
  @override
  Future<List<SavedAccount>> savedAccounts() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return saved;
  }

  @override
  Future<void> sendCode(String identifier, {bool signUp = false}) async =>
      sent.add((identifier, signUp));
  @override
  Future<void> verifyCode(String identifier, String code) async =>
      throw const AuthFailure("That code didn't work. Check it and try again.");
  @override
  Future<void> forgetAccount(String userId) async =>
      saved = [...saved.where((a) => a.userId != userId)];
  @override
  Future<bool> keepSessionForFaceId() async => keptSession;
  bool keptSession = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements SettingsRepository {
  final saved = <AccountDetails>[];

  @override
  Future<AccountDetails> account() async => const AccountDetails(
    fullName: 'Nicholas Ong',
    username: 'nicholas28',
    bio: 'Badminton on weekday nights, pickleball on Sundays.',
  );
  @override
  Future<void> saveAccount(AccountDetails details) async => saved.add(details);
  @override
  Future<PrivateInfo> privateInfo() async => PrivateInfo(
    phone: '+6580000003',
    birthday: DateTime(1996, 6, 8),
    country: Country.singapore,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SavedAccount _tile(int i) => SavedAccount(
  userId: 'u$i',
  displayName: 'Player $i',
  maskedIdentifier: '•••• 000$i',
);

/// Opens [start] in a small app with the screens under test and a labelled
/// placeholder for every other place they can go.
Future<GoRouter> _open(
  WidgetTester tester,
  String start, {
  _Auth? auth,
  _Settings? settings,
  List<Override> extra = const [],
  bool pushed = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  FlutterSecureStorage.setMockInitialValues({});
  Widget placeholder(String name) => Scaffold(body: Text('at $name'));
  final router = GoRouter(
    initialLocation: pushed ? '/start' : start,
    routes: [
      GoRoute(path: '/start', builder: (_, _) => placeholder('start')),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.logIn, builder: (_, _) => const LogInScreen()),
      GoRoute(
        path: Routes.logInMobile,
        builder: (_, _) => const LogInAccountScreen(method: LoginMethod.phone),
      ),
      GoRoute(path: Routes.logInCode, builder: (_, _) => const CodeScreen()),
      GoRoute(path: Routes.skills, builder: (_, _) => const SkillLevelScreen()),
      GoRoute(
        path: '${Routes.skills}/:sport',
        builder: (_, s) =>
            SportSkillScreen(sport: Sport.fromId(s.pathParameters['sport']!)),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.accountInfo,
        builder: (_, _) => const AccountInfoScreen(),
      ),
      for (final (name, path) in [
        ('legal', Routes.legal),
        ('recovery', Routes.recovery),
        ('username', Routes.username),
        ('settings', Routes.settings),
      ])
        GoRoute(path: path, builder: (_, _) => placeholder(name)),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth ?? _Auth()),
        settingsRepositoryProvider.overrideWithValue(settings ?? _Settings()),
        biometricVaultProvider.overrideWithValue(BiometricVault()),
        ...extra,
      ],
      child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  if (pushed) {
    router.push<void>(start).ignore();
    await tester.pumpAndSettle();
  }
  return router;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  group('Code wording (Q248)', () {
    test('the resend timer counts down from 3:00', () {
      expect(resendClock(180), '3:00');
      expect(resendClock(61), '1:01');
      expect(resendClock(9), '0:09');
    });

    test('each channel says where the code went and that it lasts 3 min', () {
      expect(codeTitle(CodeTarget.mobile), 'Check your messages');
      expect(codeTitle(CodeTarget.email), 'Check your email');
      expect(
        codeLead(CodeTarget.mobile, '+6580000003'),
        'We sent a 6-digit code to +65 8000 0003. It works for 3 minutes.',
      );
      expect(
        codeLead(CodeTarget.email, 'me@example.com'),
        contains('to me@example.com.'),
      );
    });

    test('a username never shows the contact behind it', () {
      final lead = codeLead(CodeTarget.username, 'nicholas28');
      expect(lead, contains('the email or mobile on @nicholas28'));
      expect(lead, isNot(contains('+65')));
      expect(lead, isNot(contains('.com')));
    });
  });

  group('Skill names (Q252)', () {
    test('long form with the short form', () {
      expect(SkillScale.nameWithShort(2.0), 'Mid Beginner (MB)');
      expect(SkillScale.nameWithShort(3.0), 'High Beginner (HB)');
      expect(SkillScale.nameWithShort(7.0), 'Advanced (ADV)');
      expect(SkillScale.nameWithShort(8.0), 'Expert (EXP)');
    });

    test('the summary gives the level and the play range', () {
      expect(
        const SportSkill(sport: Sport.badminton).summary,
        'Level 4.0 · Low Intermediate · Plays with 3.0 to 5.0',
      );
    });
  });

  group('Welcome and Log in (Q247)', () {
    testWidgets('Welcome has one way in and no Create account', (tester) async {
      await _open(tester, Routes.welcome);
      expect(find.text('Create account'), findsNothing);
      expect(find.textContaining('Terms of use'), findsNothing);
      await _tap(tester, find.text('Get started'));
      // No saved accounts: straight to log in by mobile.
      expect(find.text('Log in or sign up'), findsOneWidget);
    });

    testWidgets('with saved accounts, Get started shows them', (tester) async {
      await _open(tester, Routes.welcome, auth: _Auth(saved: [_tile(1)]));
      await _tap(tester, find.text('Get started'));
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Use another profile'), findsOneWidget);
      expect(find.textContaining('Terms of use'), findsOneWidget);
    });

    testWidgets('more than three tiles scroll inside the list', (tester) async {
      await _open(
        tester,
        Routes.logIn,
        auth: _Auth(saved: [for (var i = 1; i <= 5; i++) _tile(i)]),
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
    });

    testWidgets('three tiles or fewer do not scroll', (tester) async {
      await _open(
        tester,
        Routes.logIn,
        auth: _Auth(saved: [_tile(1), _tile(2), _tile(3)]),
      );
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('with no saved accounts, Log in opens log in by mobile', (
      tester,
    ) async {
      await _open(tester, Routes.logIn);
      expect(find.text('Log in or sign up'), findsOneWidget);
    });

    testWidgets('Use another profile, then the legal line opens the terms', (
      tester,
    ) async {
      await _open(tester, Routes.logIn, auth: _Auth(saved: [_tile(1)]));
      await _tap(tester, find.textContaining('Terms of use'));
      expect(find.text('at legal'), findsOneWidget);
    });
  });

  group('Log in by mobile (Q247)', () {
    testWidgets('no sign-up link, and the recovery link is reworded', (
      tester,
    ) async {
      await _open(tester, Routes.logInMobile);
      expect(find.textContaining('Create an account'), findsNothing);
      expect(find.textContaining('Lost both'), findsNothing);
      // A new phone skips the Log in screen, so the terms show here (Q255).
      expect(find.textContaining('Terms of use'), findsOneWidget);
      await _tap(
        tester,
        find.text('Trouble logging in? Get back into your account'),
      );
      expect(find.text('at recovery'), findsOneWidget);
    });

    testWidgets('a mobile asks for a sign-up code, so a new number can join', (
      tester,
    ) async {
      final auth = _Auth();
      await _open(tester, Routes.logInMobile, auth: auth);
      await tester.enterText(find.byType(TextField), '8000 0003');
      await _tap(tester, find.text('Send code'));
      expect(auth.sent, [('+6580000003', true)]);
      expect(find.text('Check your messages'), findsOneWidget);
    });

    testWidgets('back goes to Welcome when this phone has no tiles', (
      tester,
    ) async {
      final router = await _open(tester, Routes.logInMobile, pushed: false);
      await _tap(tester, find.byType(KitBack));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.welcome,
      );
    });
  });

  group('Code screen (Q248)', () {
    Future<void> openCode(WidgetTester tester, String phone) async {
      await _open(
        tester,
        Routes.logInCode,
        extra: [
          pendingCodeControllerProvider.overrideWith(
            () => _Pending(
              PendingCode(target: CodeTarget.mobile, destination: phone),
            ),
          ),
        ],
      );
    }

    testWidgets('one field, the number typed, 3 minutes, and Verify', (
      tester,
    ) async {
      await openCode(tester, '+6580000003');
      expect(find.text('Check your messages'), findsOneWidget);
      expect(find.textContaining('+65 8000 0003'), findsOneWidget);
      expect(find.textContaining('It works for 3 minutes'), findsOneWidget);
      expect(tester.widget<ResendTimer>(find.byType(ResendTimer)).seconds, 180);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('6-digit code'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Verify needs all six digits', (tester) async {
      await openCode(tester, '+6580000003');
      await tester.enterText(find.byType(TextField), '12345');
      await _tap(tester, find.text('Verify'));
      expect(find.text('Enter all 6 digits of the code.'), findsOneWidget);
    });

    testWidgets('a wrong code clears the field and says so', (tester) async {
      await openCode(tester, '+6580000003');
      await tester.enterText(find.byType(TextField), '999999');
      await tester.pumpAndSettle();
      expect(find.textContaining("didn't work"), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });
  });

  group('Skills (Q253)', () {
    testWidgets('no summary and no Continue until each sport has a level', (
      tester,
    ) async {
      await _open(tester, Routes.skills);
      expect(find.text('Set your skill'), findsOneWidget);
      expect(find.text('Badminton'), findsOneWidget);
      expect(find.textContaining('Level'), findsNothing);
      expect(
        find.text('Set a level for each sport to continue.'),
        findsOneWidget,
      );
      final button = tester.widget<OgButton>(
        find.widgetWithText(OgButton, 'Continue'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('the editor waits for a level, names both ends, and Done '
        'sets the summary', (tester) async {
      await _open(tester, Routes.skills);
      await _tap(tester, find.text('Badminton'));
      expect(
        find.text('We recommend Meets and partners inside this range.'),
        findsOneWidget,
      );
      expect(find.text('High Beginner (HB)'), findsOneWidget);
      expect(find.text('Mid Intermediate (MI)'), findsOneWidget);
      // Done does nothing before a level is chosen.
      await _tap(tester, find.text('Done'));
      expect(find.text('Your skill level'), findsOneWidget);

      // The picker opens on 4.0; its own Done confirms it.
      await _tap(tester, find.text('Your skill level'));
      await _tap(tester, find.text('Done').last);
      expect(find.text('4.0 · Low Intermediate'), findsOneWidget);
      await _tap(tester, find.text('Done'));
      expect(find.text('Set your skill'), findsOneWidget);
      expect(
        find.text('Level 4.0 · Low Intermediate · Plays with 3.0 to 5.0'),
        findsOneWidget,
      );
    });

    testWidgets('Continue opens the username step once every sport is set', (
      tester,
    ) async {
      await _open(
        tester,
        Routes.skills,
        extra: [
          onboardingControllerProvider.overrideWith(
            () => _Draft(
              OnboardingDraft(
                sports: const [Sport.badminton],
                skills: {
                  Sport.badminton: const SportSkill(sport: Sport.badminton),
                },
              ),
            ),
          ),
        ],
      );
      expect(
        find.text('Set a level for each sport to continue.'),
        findsNothing,
      );
      await _tap(tester, find.text('Continue'));
      expect(find.text('at username'), findsOneWidget);
    });
  });

  group('Edit profile', () {
    testWidgets('rows open their own editor, and Save writes the change', (
      tester,
    ) async {
      final settings = _Settings();
      await _open(tester, Routes.editProfile, settings: settings);
      expect(find.text('Edit profile'), findsWidgets);
      expect(find.text('Change photo'), findsOneWidget);
      expect(find.text('Personal information settings'), findsNothing);
      expect(find.text('@nicholas28'), findsOneWidget);
      expect(
        find.text('Badminton on weekday nights, pickleball on Sundays.'),
        findsOneWidget,
      );

      await _tap(tester, find.text('Nicholas Ong'));
      await tester.enterText(find.byType(TextField), 'Nick Ong');
      await _tap(tester, find.text('Done'));
      expect(find.text('Nick Ong'), findsOneWidget);
      expect(settings.saved, isEmpty, reason: 'nothing saved before Save');

      await _tap(tester, find.text('Save'));
      expect(settings.saved.single.fullName, 'Nick Ong');
      expect(settings.saved.single.username, 'nicholas28');
      expect(find.text('at start'), findsOneWidget);
      // Let the "Saved" message finish.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a username editor refuses a bad username', (tester) async {
      await _open(tester, Routes.editProfile);
      await _tap(tester, find.text('@nicholas28'));
      await tester.enterText(find.byType(TextField), 'no spaces');
      await _tap(tester, find.text('Done'));
      expect(
        find.text('Usernames use 3 to 30 letters, numbers or underscores.'),
        findsOneWidget,
      );
    });
  });

  group('Face ID switch (Q249)', () {
    Future<(ProviderContainer, _Vault)> make({
      bool biometrics = true,
      bool match = true,
      bool kept = true,
    }) async {
      FlutterSecureStorage.setMockInitialValues({});
      final vault = _Vault(biometrics: biometrics, match: match);
      final auth = _Auth(userId: 'u1')..keptSession = kept;
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          biometricVaultProvider.overrideWithValue(vault),
          sessionProfileProvider.overrideWith(_NoProfile.new),
        ],
      );
      addTearDown(c.dispose);
      return (c, vault);
    }

    test('a phone without Face ID or fingerprint stays off', () async {
      final (c, vault) = await make(biometrics: false);
      expect(await c.read(faceIdEnabledProvider.notifier).set(true), isFalse);
      expect(vault.asked, 0, reason: 'a passcode alone is not enough');
      expect(await vault.isEnabledFor('u1'), isFalse);
    });

    test('a failed check stays off', () async {
      final (c, vault) = await make(match: false);
      expect(await c.read(faceIdEnabledProvider.notifier).set(true), isFalse);
      expect(vault.asked, 1);
      expect(await vault.isEnabledFor('u1'), isFalse);
    });

    test('a passed check turns it on for this account only', () async {
      final (c, vault) = await make();
      expect(await c.read(faceIdEnabledProvider.notifier).set(true), isTrue);
      expect(await vault.isEnabledFor('u1'), isTrue);
      expect(await vault.isEnabledFor('u2'), isFalse);
      expect(c.read(faceIdEnabledProvider).value, isTrue);
    });

    test('if the session cannot be kept, it stays off', () async {
      final (c, vault) = await make(kept: false);
      expect(await c.read(faceIdEnabledProvider.notifier).set(true), isFalse);
      expect(await vault.isEnabledFor('u1'), isFalse);
    });

    test('switching off turns it off without asking', () async {
      final (c, vault) = await make();
      await c.read(faceIdEnabledProvider.notifier).set(true);
      expect(await c.read(faceIdEnabledProvider.notifier).set(false), isFalse);
      expect(vault.asked, 1);
      expect(await vault.isEnabledFor('u1'), isFalse);
    });
  });

  group('Account information (Q249, Q254)', () {
    testWidgets(
      'one card: email, merged mobile, birthday, region, Face ID off',
      (tester) async {
        await _open(tester, Routes.accountInfo);
        expect(find.text('Account information'), findsWidgets);
        expect(find.text('Only you can see these details.'), findsOneWidget);
        expect(find.text('+65'), findsOneWidget);
        expect(find.text('8000 0003'), findsOneWidget);
        expect(find.text('8 June 1996'), findsOneWidget);
        expect(
          find.text("Your date of birth can't be changed."),
          findsOneWidget,
        );
        expect(find.text('Account region'), findsOneWidget);
        expect(find.text('Singapore'), findsOneWidget);
        final faceId = tester.widget<CupertinoSwitch>(
          find.byType(CupertinoSwitch),
        );
        expect(faceId.value, isFalse);
      },
    );
  });
}

class _Vault extends BiometricVault {
  _Vault({this.biometrics = true, this.match = true});
  final bool biometrics;
  final bool match;
  var asked = 0;

  @override
  Future<bool> get hasBiometrics async => biometrics;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return match;
  }
}

class _NoProfile extends SessionProfile {
  @override
  Future<Profile?> build() async => null;
}

class _Pending extends PendingCodeController {
  _Pending(this.initial);
  final PendingCode initial;
  @override
  PendingCode? build() => initial;
}

class _Draft extends OnboardingController {
  _Draft(this.initial);
  final OnboardingDraft initial;
  @override
  OnboardingDraft build() => initial;
}
