// Fixes from the 5 November audit: A02, A03 and A04.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/app_router.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:olympus_go/features/settings/presentation/account_screens.dart';
import 'package:olympus_go/features/social/data/social_repository.dart';
import 'package:olympus_go/main.dart';

class _Social implements SocialRepository {
  final sent = <String>[];
  AuthFailure? fail;
  Completer<void>? gate;

  @override
  Future<void> contactSupport(String message) async {
    await gate?.future;
    if (fail != null) throw fail!;
    sent.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Vault extends BiometricVault {
  _Vault(this.ok);
  final bool ok;
  var asked = 0;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return ok;
  }
}

Future<void> _open(
  WidgetTester tester,
  _Social social,
  _Vault vault, {
  bool bySupport = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const Text('home')),
      GoRoute(
        path: Routes.deleteAccount,
        builder: (_, _) => DeleteAccountScreen(bySupport: bySupport),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialRepositoryProvider.overrideWithValue(social),
        biometricVaultProvider.overrideWithValue(vault),
      ],
      child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  router.push<void>(Routes.deleteAccount).ignore();
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  group('A02: the phone or email code screen', () {
    test('opens only with the address the change started with', () {
      expect(verifyChangeRedirect('+6591234567'), isNull);
      expect(verifyChangeRedirect(null), Routes.personalInfo);
      expect(verifyChangeRedirect(42), Routes.personalInfo);
    });
  });

  group('A03: deleting a real account', () {
    testWidgets('says support does it before anything is confirmed', (
      tester,
    ) async {
      await _open(tester, _Social(), _Vault(true));
      expect(find.text('Ask us to delete my account'), findsOneWidget);
      expect(find.text('Delete my account'), findsNothing);
      expect(
        find.textContaining('Our support team deletes accounts for now'),
        findsOneWidget,
      );
      expect(find.textContaining('leave the app at once'), findsNothing);

      await _tap(tester, 'Ask us to delete my account');
      expect(find.text('Ask us to delete your account?'), findsOneWidget);
      expect(find.text('Send with Face ID'), findsOneWidget);
    });

    testWidgets('sends support the request after Face ID', (tester) async {
      final social = _Social();
      final vault = _Vault(true);
      await _open(tester, social, vault);
      await _tap(tester, 'Privacy worries');
      await _tap(tester, 'Ask us to delete my account');
      await _tap(tester, 'Send with Face ID');

      expect(vault.asked, 1);
      expect(social.sent, [
        'Please delete my account. Reason: Privacy worries',
      ]);
      expect(find.text('Request sent'), findsOneWidget);
      expect(find.text('Support has your request'), findsOneWidget);
      // No turnaround is promised, and the email is never shown back.
      expect(find.textContaining('30 days'), findsNothing);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('can\'t be sent twice while it is sending', (tester) async {
      final social = _Social()..gate = Completer<void>();
      await _open(tester, social, _Vault(true));
      await _tap(tester, 'Ask us to delete my account');
      await tester.tap(find.text('Send with Face ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final button = tester.widget<KitButton>(
        find.byWidgetPredicate(
          (w) => w is KitButton && w.label == 'Ask us to delete my account',
        ),
      );
      expect(button.loading, isTrue);
      expect(button.onPressed, isNull);

      social.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Request sent'), findsOneWidget);
    });

    testWidgets('sends nothing when Face ID fails or the sheet is cancelled', (
      tester,
    ) async {
      final social = _Social();
      await _open(tester, social, _Vault(false));
      await _tap(tester, 'Ask us to delete my account');
      await _tap(tester, 'Send with Face ID');
      await _tap(tester, 'Ask us to delete my account');
      await _tap(tester, 'Cancel');

      expect(social.sent, isEmpty);
      expect(find.text('Request sent'), findsNothing);
    });

    testWidgets('a failed send says so and can be tried again', (tester) async {
      final social = _Social()
        ..fail = const AuthFailure('Check your connection.');
      await _open(tester, social, _Vault(true));
      await _tap(tester, 'Ask us to delete my account');
      await _tap(tester, 'Send with Face ID');

      expect(find.text('Check your connection.'), findsOneWidget);
      expect(find.text('Request sent'), findsNothing);
      final button = tester.widget<KitButton>(
        find
            .ancestor(
              of: find.text('Ask us to delete my account'),
              matching: find.byType(KitButton),
            )
            .first,
      );
      expect(button.onPressed, isNotNull);
      // Let the toast go before the test ends.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('A03: deleting in demo mode', () {
    testWidgets('keeps the demo flow and shows no email', (tester) async {
      final social = _Social();
      final vault = _Vault(true);
      await _open(tester, social, vault, bySupport: false);
      await _tap(tester, 'Delete my account');
      await _tap(tester, 'Delete with Face ID');

      expect(vault.asked, 0);
      expect(social.sent, isEmpty);
      expect(find.text('Closing'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
    });
  });

  group('A04: fonts at start-up', () {
    test('a failed load still lets the app start', () async {
      await waitForFonts(Future<Object?>.error(Exception('offline')));
    });

    test('a slow load stops waiting at the limit', () async {
      final never = Completer<Object?>();
      final watch = Stopwatch()..start();
      await waitForFonts(never.future, limit: const Duration(milliseconds: 50));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('a quick load is waited for', () async {
      var done = false;
      await waitForFonts(
        Future<Object?>.delayed(const Duration(milliseconds: 20), () {
          done = true;
          return null;
        }),
      );
      expect(done, isTrue);
    });
  });
}
