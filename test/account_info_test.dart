// Account information on the shared settings rows and sections.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/domain/country.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/motion_page.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/theme/og_layout.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/theme/og_tones.dart';
import 'package:olympus_go/core/widgets/og_icon.dart';
import 'package:olympus_go/core/widgets/settings_list.dart';
import 'package:olympus_go/features/academy/application/academy_providers.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:olympus_go/features/earnings/application/earnings_providers.dart';
import 'package:olympus_go/features/settings/application/settings_providers.dart';
import 'package:olympus_go/features/settings/data/settings_repository.dart';
import 'package:olympus_go/features/settings/domain/account_info.dart';
import 'package:olympus_go/features/settings/domain/settings_models.dart';
import 'package:olympus_go/features/settings/presentation/account_info_screens.dart';
import 'package:olympus_go/features/settings/presentation/account_screens.dart';
import 'package:olympus_go/features/settings/presentation/settings_screens.dart';

final _full = PrivateInfo(
  email: 'nicholas8@example.com',
  phone: '+6591234567',
  birthday: DateTime(1996, 6, 8),
  country: Country.singapore,
);

class _Settings implements SettingsRepository {
  _Settings(this.answers);

  /// One answer per load: a value, an error to throw, or a future that
  /// never finishes.
  final List<Object> answers;
  var loads = 0;

  @override
  Future<PrivateInfo> privateInfo() async {
    final a = answers[loads < answers.length ? loads : answers.length - 1];
    loads++;
    if (a is Future<PrivateInfo>) return a;
    if (a is AuthFailure) throw a;
    return a as PrivateInfo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements AuthRepository {
  _Auth({this.refuse});

  /// Thrown by every start, when set.
  final AuthFailure? refuse;
  final phones = <String>[];
  final emails = <String>[];
  final verified = <String>[];

  @override
  Future<void> startPhoneChange(String phone) async {
    if (refuse != null) throw refuse!;
    phones.add(phone);
  }

  @override
  Future<void> startEmailChange(String email) async {
    if (refuse != null) throw refuse!;
    emails.add(email);
  }

  @override
  Future<void> verifyPhoneChange(String phone, String code) async =>
      verified.add(phone);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FaceIdOff extends FaceIdEnabled {
  @override
  Future<bool> build() async => false;
}

const _phone = Size(402, 874);
const _tablet = Size(820, 1180);

Future<GoRouter> _open(
  WidgetTester tester, {
  List<Object>? answers,
  _Settings? settings,
  _Auth? auth,
  ThemeData? theme,
  Size size = _phone,
  bool onboarding = false,
  bool realVerify = false,
  double textScale = 1,
  BiometricVault? vault,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  Widget placeholder(String name) => Scaffold(body: Text('at $name'));
  GoRoute route(String path, Widget child) => GoRoute(
    path: path,
    pageBuilder: (_, s) => MotionPage<void>(key: s.pageKey, child: child),
  );
  final router = GoRouter(
    initialLocation: Routes.accountInfo,
    routes: [
      GoRoute(path: Routes.profile, builder: (_, _) => placeholder('profile')),
      route(Routes.accountInfo, AccountInfoScreen(onboarding: onboarding)),
      route(Routes.changePhone, const ChangePhoneScreen()),
      route(Routes.changeEmail, const ChangeEmailScreen()),
      GoRoute(
        path: Routes.verifyPhoneChange,
        builder: (_, s) => realVerify
            ? VerifyPhoneChangeScreen(phone: s.extra! as String)
            : _FakeVerify('${s.extra}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          settings ?? _Settings(answers ?? [_full]),
        ),
        authRepositoryProvider.overrideWithValue(auth ?? _Auth()),
        faceIdEnabledProvider.overrideWith(_FaceIdOff.new),
        if (vault != null) biometricVaultProvider.overrideWithValue(vault),
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

/// Stands in for the code screen: Verify reports success to the screen
/// that pushed it.
class _FakeVerify extends StatelessWidget {
  const _FakeVerify(this.target);

  final String target;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('at verify $target'),
        TextButton(
          onPressed: () => context.pop(true),
          child: const Text('Verify'),
        ),
      ],
    ),
  );
}

Finder _row(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(SettingsRow));

Finder _chevron(String label) =>
    find.descendant(of: _row(label), matching: find.byType(OgIcon));

/// The Account Centre on a phone, opened (demo mode skips Face ID).
Future<void> _openHub(
  WidgetTester tester, {
  PrivateInfo info = const PrivateInfo(),
  bool skipFaceId = false,
}) async {
  await tester.binding.setSurfaceSize(_phone);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        biometricVaultProvider.overrideWithValue(
          BiometricVault(skip: skipFaceId),
        ),
        faceIdEnabledProvider.overrideWith(_FaceIdOff.new),
        privateInfoProvider.overrideWith((_) async => info),
        myStudentsProvider.overrideWith((_) async => const []),
        savedCardProvider.overrideWith((_) async => null),
      ],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: const AccountHubScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('masking', () {
    test('email keeps the first and last character before the @', () {
      expect(maskEmail('nicholas8@example.com'), 'n***8@example.com');
      expect(maskEmail('abc@x.co'), 'a***c@x.co');
      expect(maskEmail('ab@x.co'), 'a***@x.co');
      expect(maskEmail('a@x.co'), 'a***@x.co');
      expect(maskEmail('not-an-email'), '***');
    });

    test('phone shows the dialling code and the last 4 digits', () {
      expect(maskPhone('+6591234567'), '+65 •••• 4567');
      expect(maskPhone('+60123456789'), '+60 •••• 6789');
      expect(maskPhone('6591234567'), '+65 •••• 4567');
      expect(maskPhone('+4479460000'), '•••• 0000');
    });

    test('a screen reader hears the ending, not the dots', () {
      expect(spokenMaskedPhone('+6591234567'), '+65, ending in 4567');
    });

    test('the model reads the private details', () {
      final info = AccountInfo.from(_full);
      expect(info.maskedEmail, 'n***8@example.com');
      expect(info.maskedPhone, '+65 •••• 4567');
      expect(info.birthdayText, '8 June 1996');
      expect(info.region, Country.singapore);
      expect(AccountInfo.from(const PrivateInfo()).maskedPhone, isNull);
    });

    test('its text form carries no contact details or birthday', () {
      final text = AccountInfo.from(_full).toString();
      expect(text, isNot(contains('nicholas')));
      expect(text, isNot(contains('4567')));
      expect(text, isNot(contains('1996')));
    });
  });

  group('Account information screen', () {
    testWidgets('shows the Face ID switch', (tester) async {
      await _open(tester);
      await tester.scrollUntilVisible(find.text('Enable Face ID'), 200);
      expect(find.text('Sign-in'), findsOneWidget);
    });

    testWidgets('local testing without Face ID hides the switch, here and '
        'in the Account Centre', (tester) async {
      final vault = BiometricVault(skip: true);
      await _open(tester, vault: vault);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Enable Face ID'), findsNothing);
      expect(find.text('Sign-in'), findsNothing);

      for (final skip in [false, true]) {
        await tester.pumpWidget(const SizedBox());
        await _openHub(tester, skipFaceId: skip);
        expect(find.text('Account Centre'), findsOneWidget);
        expect(find.text('Face ID'), skip ? findsNothing : findsOneWidget);
      }
    });

    testWidgets('the Account Centre keeps a long email from squeezing its '
        'label', (tester) async {
      const email = 'nicholas.ong.with.a.long.address@example.com';
      await _openHub(
        tester,
        info: const PrivateInfo(email: email, phone: '+6587654321'),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(email), findsOneWidget);
      expect(find.text('+6587654321'), findsOneWidget);
      expect(find.text('Verified'), findsNWidgets(2));
      // One line, like Mobile, not a letter per line.
      expect(
        tester.getSize(find.text('Email')).height,
        tester.getSize(find.text('Mobile')).height,
      );
      expect(
        tester.getSize(find.text('Email')).width,
        greaterThan(tester.getSize(find.text('Email')).height * 3),
      );
    });

    testWidgets('the Account Centre shows no Verified tag without an email', (
      tester,
    ) async {
      await _openHub(tester, info: const PrivateInfo(phone: '+6587654321'));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('masks the email and the phone by default', (tester) async {
      await _open(tester);
      expect(find.text('+65 •••• 4567'), findsOneWidget);
      expect(find.text('n***8@example.com'), findsOneWidget);
      expect(find.textContaining('nicholas8'), findsNothing);
      expect(find.textContaining('9123'), findsNothing);
      expect(find.text('8 June 1996'), findsOneWidget);
      expect(find.text('Singapore'), findsOneWidget);
      expect(find.text(AccountInfoScreen.regionNote), findsOneWidget);
    });

    testWidgets('read-only rows show no chevron; contacts do', (tester) async {
      await _open(tester);
      expect(_chevron('Date of birth'), findsNothing);
      expect(_chevron('Account region'), findsNothing);
      expect(_chevron('Phone number'), findsOneWidget);
      expect(_chevron('Email'), findsOneWidget);
    });

    testWidgets('an empty phone shows Add in the link colour', (tester) async {
      await _open(tester, answers: [_full.copyWith(phone: '')]);
      final add = tester.widget<Text>(find.text('Add'));
      expect(add.style?.color, OgColors.light.link);
      expect(add.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('rows read as "label, value, button" when they open', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester);
      expect(
        tester.getSemantics(_row('Phone number')),
        matchesSemantics(
          label: 'Phone number',
          value: '+65, ending in 4567',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_row('Date of birth')),
        matchesSemantics(label: 'Date of birth', value: '8 June 1996'),
      );
      handle.dispose();
    });

    testWidgets('rows are at least 56 tall', (tester) async {
      await _open(tester);
      for (final label in ['Phone number', 'Email', 'Date of birth']) {
        expect(
          tester.getSize(_row(label)).height,
          greaterThanOrEqualTo(OgSize.row),
        );
      }
    });

    testWidgets('loading shows skeleton rows at the same height', (
      tester,
    ) async {
      final later = Completer<PrivateInfo>();
      // Wide enough that the test font's square letters don't wrap a label.
      await _open(tester, answers: [later.future], size: _tablet);
      expect(find.text('+65 •••• 4567'), findsNothing);
      expect(find.text('Phone number'), findsOneWidget);
      final labels = [
        'Phone number',
        'Email',
        'Date of birth',
        'Account region',
      ];
      final loading = [for (final l in labels) tester.getSize(_row(l)).height];
      // Nothing opens until the details are there.
      await tester.tap(find.text('Phone number'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePhoneScreen), findsNothing);

      later.complete(_full);
      await tester.pumpAndSettle();
      expect(find.text('+65 •••• 4567'), findsOneWidget);
      expect([for (final l in labels) tester.getSize(_row(l)).height], loading);
    });

    testWidgets('an error offers Try again, which loads the details', (
      tester,
    ) async {
      await _open(tester, answers: [const AuthFailure('offline'), _full]);
      expect(find.textContaining("couldn't load"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('+65 •••• 4567'), findsOneWidget);
    });

    testWidgets('on a tablet the card centres at 560 wide', (tester) async {
      await _open(tester, size: _tablet);
      final card = find.byType(SettingsSection).first;
      expect(tester.getSize(card).width, OgSize.readableWidth);
      expect(tester.getCenter(card).dx, _tablet.width / 2);
    });

    testWidgets('during onboarding Continue goes to the profile', (
      tester,
    ) async {
      await _open(tester, onboarding: true);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('at profile'), findsOneWidget);
    });

    testWidgets('at 200% text the value moves under the label, uncut', (
      tester,
    ) async {
      await _open(tester, textScale: 2);
      final label = tester.getTopLeft(find.text('Phone number'));
      final value = tester.getTopLeft(find.text('+65 •••• 4567'));
      expect(value.dy, greaterThan(label.dy));
      expect(value.dx, label.dx);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pressing a row tints it with the track colour', (
      tester,
    ) async {
      await _open(tester);
      Color? tint() =>
          (tester
                      .widget<Container>(
                        find
                            .descendant(
                              of: _row('Email'),
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration?)
              ?.color;
      final track = OgTones.light.track;
      expect(tint(), isNot(track));
      final press = await tester.startGesture(
        tester.getCenter(find.text('Email')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(OgMotion.press);
      expect(tint(), track);
      await press.cancel();
      await tester.pumpAndSettle();
      expect(tint(), isNot(track));
    });

    testWidgets('on a phone the card fills the width inside the margins', (
      tester,
    ) async {
      await _open(tester);
      // Inside the outlined card: the side margins and its hairline border.
      expect(
        tester.getSize(_row('Email')).width,
        _phone.width - 2 * OgSpace.s4 - 2 * OgSize.hairline,
      );
    });
  });

  group('editing', () {
    testWidgets('Phone number opens its screen and sends a code', (
      tester,
    ) async {
      final auth = _Auth();
      await _open(tester, auth: auth);
      await tester.tap(find.text('Phone number'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePhoneScreen), findsOneWidget);
      expect(find.text('9123 4567'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '8123 4567');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(auth.phones, ['+6581234567']);
      expect(find.text('at verify +6581234567'), findsOneWidget);

      // Verified: back on Account information, not Settings.
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePhoneScreen), findsNothing);
      expect(find.byType(AccountInfoScreen), findsOneWidget);
    });

    testWidgets('a Malaysian number keeps +60 on a Singapore account (Q254)', (
      tester,
    ) async {
      final auth = _Auth();
      await _open(
        tester,
        auth: auth,
        answers: [_full.copyWith(phone: '+60123456789')],
      );
      expect(find.text('+60 •••• 6789'), findsOneWidget);
      await tester.tap(find.text('Phone number'));
      await tester.pumpAndSettle();
      expect(find.text('+60'), findsOneWidget);
      expect(find.text('+65'), findsNothing);
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(auth.phones, isEmpty);
    });

    testWidgets('a number with an unlisted code is not re-sent under +65', (
      tester,
    ) async {
      final auth = _Auth();
      await _open(
        tester,
        auth: auth,
        answers: [_full.copyWith(phone: '+6421234567')],
      );
      await tester.tap(find.text('Phone number'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(auth.phones, isEmpty);
      expect(find.byType(AccountInfoScreen), findsOneWidget);
    });

    testWidgets('Add opens an empty phone screen; empty is refused', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final auth = _Auth();
      await _open(
        tester,
        auth: auth,
        answers: [_full.copyWith(phone: '')],
      );
      expect(
        tester.getSemantics(_row('Phone number')),
        matchesSemantics(
          label: 'Phone number',
          value: 'Add',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePhoneScreen), findsOneWidget);
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your mobile number.'), findsOneWidget);
      expect(auth.phones, isEmpty);
      handle.dispose();
    });

    testWidgets('a refused change shows why and stays on the screen', (
      tester,
    ) async {
      await _open(
        tester,
        auth: _Auth(refuse: const AuthFailure('Try again in a minute.')),
      );
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'new@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.text('Try again in a minute.'), findsOneWidget);
      expect(find.byType(ChangeEmailScreen), findsOneWidget);
    });

    testWidgets('the real code screen returns here and shows the new number', (
      tester,
    ) async {
      final auth = _Auth();
      final settings = _Settings([_full, _full.copyWith(phone: '+6581234567')]);
      await _open(tester, auth: auth, settings: settings, realVerify: true);
      await tester.tap(find.text('Phone number'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '8123 4567');
      await tester.tap(find.text('Send code'));
      // The code screen's resend timer never settles, so pump by time.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(VerifyPhoneChangeScreen), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '123456');
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(auth.verified, ['+6581234567']);
      expect(find.byType(VerifyPhoneChangeScreen), findsNothing);
      expect(find.byType(ChangePhoneScreen), findsNothing);
      expect(find.text('+65 •••• 4567'), findsOneWidget);
      // Let the "Mobile number updated" toast go.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('an unchanged phone goes back without a code', (tester) async {
      final auth = _Auth();
      await _open(tester, auth: auth);
      await tester.tap(find.text('Phone number'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(auth.phones, isEmpty);
      expect(find.byType(AccountInfoScreen), findsOneWidget);
    });

    testWidgets('Email opens its screen and sends a code', (tester) async {
      final auth = _Auth();
      await _open(tester, auth: auth);
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangeEmailScreen), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'new@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(auth.emails, ['new@example.com']);
    });
  });

  group('motion', () {
    testWidgets('pages slide in the iOS way', (tester) async {
      final router = await _open(tester);
      router.push<void>(Routes.changeEmail).ignore();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CupertinoPageTransition), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('with reduced motion pages fade in place', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final router = await _open(tester);

      final press = tester.widget<AnimatedContainer>(
        find.descendant(
          of: _row('Phone number'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(press.duration, Duration.zero);

      router.push<void>(Routes.changeEmail).ignore();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      // Halfway: the new page is see-through but has not moved, and the
      // page underneath has not moved either.
      expect(tester.getTopLeft(find.byType(ChangeEmailScreen)).dx, 0);
      expect(tester.getTopLeft(find.byType(AccountInfoScreen)).dx, 0);
      final fade = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.byType(ChangeEmailScreen),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((f) => f.opacity.value)
          .reduce((a, b) => a < b ? a : b);
      expect(fade, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(find.byType(ChangeEmailScreen), findsOneWidget);
    });

    for (final still in [false, true]) {
      testWidgets(
        'an edge swipe goes back${still ? ' with reduced motion' : ''}',
        (tester) async {
          if (still) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(
              tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
          }
          await _open(tester);
          await tester.tap(find.text('Email'));
          await tester.pumpAndSettle();
          expect(find.byType(ChangeEmailScreen), findsOneWidget);
          await tester.dragFrom(const Offset(4, 500), const Offset(300, 0));
          await tester.pumpAndSettle();
          expect(find.byType(ChangeEmailScreen), findsNothing);
          expect(find.byType(AccountInfoScreen), findsOneWidget);
        },
      );
    }

    testWidgets('press feedback takes 150 ms otherwise', (tester) async {
      await _open(tester);
      final press = tester.widget<AnimatedContainer>(
        find.descendant(
          of: _row('Phone number'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(press.duration, OgMotion.press);
    });
  });

  group('goldens', () {
    for (final (name, theme) in [
      ('light', OgTheme.light()),
      ('dark', OgTheme.dark()),
    ]) {
      for (final (device, size) in [('phone', _phone), ('tablet', _tablet)]) {
        testWidgets('Account information, $device, $name', (tester) async {
          await _open(tester, theme: theme, size: size);
          await expectLater(
            find.byType(AccountInfoScreen),
            matchesGoldenFile('goldens/account_info_${device}_$name.png'),
          );
        });
      }
    }
  });
}
