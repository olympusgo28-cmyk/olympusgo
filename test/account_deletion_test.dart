// P1-14: deleting an account in the app, and keeping it again.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/format.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:olympus_go/features/guardian/application/guardian_providers.dart';
import 'package:olympus_go/features/guardian/domain/guardian_models.dart';
import 'package:olympus_go/features/settings/data/settings_repository.dart';
import 'package:olympus_go/features/settings/presentation/account_screens.dart';

final _until = DateTime(2026, 12, 8);

class _Settings implements SettingsRepository {
  final requested = <String?>[];
  var kept = 0;
  AuthFailure? fail;
  Completer<void>? gate;

  @override
  Future<DateTime> requestDeletion(String? reason) async {
    await gate?.future;
    if (fail != null) throw fail!;
    requested.add(reason);
    return _until;
  }

  @override
  Future<void> keepAccount() async {
    if (fail != null) throw fail!;
    kept++;
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
  _Settings settings,
  _Vault vault, {
  String start = Routes.deleteAccount,
  DateTime? closingUntil,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const Text('home')),
      GoRoute(path: Routes.welcome, builder: (_, _) => const Text('welcome')),
      GoRoute(
        path: Routes.deleteAccount,
        builder: (_, _) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: Routes.closing,
        builder: (_, _) => const AccountClosingScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        biometricVaultProvider.overrideWithValue(vault),
        restrictionsProvider.overrideWith(
          (ref) async => Restrictions(closingUntil: closingUntil),
        ),
      ],
      child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  router.push<void>(start).ignore();
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  group('Delete account', () {
    testWidgets('says what happens before anything is confirmed', (
      tester,
    ) async {
      await _open(tester, _Settings(), _Vault(true));
      expect(find.text('Delete my account'), findsOneWidget);
      expect(find.textContaining('refunded in full'), findsOneWidget);
      expect(find.textContaining('Former player'), findsOneWidget);
      expect(find.textContaining('30 days'), findsWidgets);
      // No turnaround or retention number is promised (Q14, Q228).
      expect(find.textContaining('5 years'), findsNothing);
      expect(find.textContaining('support'), findsNothing);

      await _tap(tester, 'Delete my account');
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.text('Delete with Face ID'), findsOneWidget);
      expect(find.textContaining('keep their accounts'), findsOneWidget);
    });

    testWidgets('closes the account after Face ID and says how to undo', (
      tester,
    ) async {
      final settings = _Settings();
      final vault = _Vault(true);
      await _open(tester, settings, vault);
      await _tap(tester, 'Privacy worries');
      await _tap(tester, 'Delete my account');
      await _tap(tester, 'Delete with Face ID');

      expect(vault.asked, 1);
      expect(settings.requested, ['Privacy worries']);
      expect(find.text('Closing'), findsOneWidget);
      expect(find.text('You can still change your mind'), findsOneWidget);
      expect(
        find.textContaining('Log in before ${Fmt.day(_until)}'),
        findsOneWidget,
      );
      expect(find.textContaining('@'), findsNothing);

      await _tap(tester, 'Done');
      expect(find.text('welcome'), findsOneWidget);
    });

    testWidgets('does nothing when Face ID fails or the sheet is cancelled', (
      tester,
    ) async {
      final settings = _Settings();
      await _open(tester, settings, _Vault(false));
      await _tap(tester, 'Delete my account');
      await _tap(tester, 'Delete with Face ID');
      await _tap(tester, 'Delete my account');
      await _tap(tester, 'Cancel');

      expect(settings.requested, isEmpty);
      expect(find.text('Closing'), findsNothing);
    });

    testWidgets('shows the database\'s reason when it refuses', (tester) async {
      final settings = _Settings()
        ..fail = const AuthFailure(
          'Hand your club to another member, or delete it, first.',
        );
      await _open(tester, settings, _Vault(true));
      await _tap(tester, 'Delete my account');
      await _tap(tester, 'Delete with Face ID');

      expect(find.textContaining('Hand your club'), findsOneWidget);
      expect(find.text('Closing'), findsNothing);
      final button = tester.widget<KitButton>(
        find
            .ancestor(
              of: find.text('Delete my account'),
              matching: find.byType(KitButton),
            )
            .first,
      );
      expect(button.onPressed, isNotNull, reason: 'can be tried again');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('can\'t be asked twice while it is sending', (tester) async {
      final settings = _Settings()..gate = Completer<void>();
      await _open(tester, settings, _Vault(true));
      await _tap(tester, 'Delete my account');
      await tester.tap(find.text('Delete with Face ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final button = tester.widget<KitButton>(
        find.byWidgetPredicate(
          (w) => w is KitButton && w.label == 'Delete my account',
        ),
      );
      expect(button.loading, isTrue);
      expect(button.onPressed, isNull);

      settings.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Closing'), findsOneWidget);
    });
  });

  group('A closing account', () {
    testWidgets('sees the date and can keep the account', (tester) async {
      final settings = _Settings();
      await _open(
        tester,
        settings,
        _Vault(true),
        start: Routes.closing,
        closingUntil: _until,
      );
      expect(find.text('Your account is closing'), findsOneWidget);
      expect(
        find.textContaining('erased on ${Fmt.day(_until)}'),
        findsOneWidget,
      );

      await _tap(tester, 'Keep my account');
      expect(settings.kept, 1);
      expect(find.textContaining('Your account stays open'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('a failed keep says so', (tester) async {
      final settings = _Settings()
        ..fail = const AuthFailure('Check your connection.');
      await _open(
        tester,
        settings,
        _Vault(true),
        start: Routes.closing,
        closingUntil: _until,
      );
      await _tap(tester, 'Keep my account');
      expect(settings.kept, 0);
      expect(find.text('Check your connection.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  test('closing_until is read from my_restrictions', () {
    final r = Restrictions.fromRow({
      'audience': 'adult',
      'restricted': false,
      'pending_parent': false,
      'can_scan': true,
      'can_chat': true,
      'can_discover': true,
      'can_shop': true,
      'can_host': true,
      'closing_until': '2026-12-08T01:00:00+00:00',
    });
    expect(r.closing, isTrue);
    expect(r.closingUntil, DateTime.parse('2026-12-08T01:00:00+00:00'));
    expect(
      Restrictions.fromRow({
        'audience': 'adult',
        'restricted': false,
        'pending_parent': false,
        'can_scan': true,
        'can_chat': true,
        'can_discover': true,
        'can_shop': true,
        'can_host': true,
        'closing_until': null,
      }).closing,
      isFalse,
    );
  });
}
