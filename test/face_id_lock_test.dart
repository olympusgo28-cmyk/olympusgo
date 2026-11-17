// R-ACC-8, per screen since the Account Centre went (owner, 9 Nov 2026,
// Q265): private screens ask for Face ID before they build.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/face_id_lock.dart';
import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:olympus_go/features/earnings/presentation/earnings_screens.dart';
import 'package:olympus_go/features/settings/presentation/account_screens.dart';

/// Answers each Face ID check in turn; a null answer never comes.
class _Vault extends BiometricVault {
  _Vault(this.answers) : super(skip: false);

  final List<bool?> answers;
  final reasons = <String>[];

  @override
  Future<bool> authenticate(String reason) {
    reasons.add(reason);
    final answer = answers.isEmpty ? false : answers.removeAt(0);
    return answer == null ? Completer<bool>().future : Future.value(answer);
  }
}

const _locked = 'Face ID didn’t match, so this page stays locked.';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required _Vault vault,
  bool asks = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        biometricVaultProvider.overrideWithValue(vault),
        faceIdAsksProvider.overrideWithValue(asks),
      ],
      child: MaterialApp(theme: OgTheme.light(), home: screen),
    ),
  );
  await tester.pump();
}

const _secret = FaceIdLock(
  title: 'Private',
  reason: 'Open your private page',
  child: Scaffold(body: Text('card ending 4242')),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('stays locked until Face ID passes; Try again asks again', (
    tester,
  ) async {
    final vault = _Vault([false, true]);
    await _pump(tester, _secret, vault: vault);
    expect(find.text(_locked), findsOneWidget);
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('card ending 4242'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('card ending 4242'), findsOneWidget);
    expect(vault.reasons, ['Open your private page', 'Open your private page']);
  });

  testWidgets('while it asks, a spinner says so', (tester) async {
    await _pump(tester, _secret, vault: _Vault([null]));
    expect(find.bySemanticsLabel('Checking Face ID'), findsOneWidget);
    expect(find.text('card ending 4242'), findsNothing);
    expect(find.text(_locked), findsNothing);
  });

  testWidgets('demo mode opens without asking', (tester) async {
    final vault = _Vault([false]);
    await _pump(tester, _secret, vault: vault, asks: false);
    expect(find.text('card ending 4242'), findsOneWidget);
    expect(vault.reasons, isEmpty);
  });

  testWidgets('Payment methods asks first', (tester) async {
    final vault = _Vault([false]);
    await _pump(tester, const PaymentMethodsScreen(), vault: vault);
    expect(vault.reasons, ['Open your payment methods']);
    expect(find.text('Payment methods'), findsOneWidget);
    expect(find.text(_locked), findsOneWidget);
  });

  testWidgets('Delete account asks first, as it lists children and points', (
    tester,
  ) async {
    final vault = _Vault([false]);
    await _pump(tester, const DeleteAccountScreen(), vault: vault);
    expect(vault.reasons, ['Open delete account']);
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text(_locked), findsOneWidget);
  });

  testWidgets('Identity check asks first', (tester) async {
    final vault = _Vault([false]);
    await _pump(tester, const IdentityCheckScreen(), vault: vault);
    expect(vault.reasons, ['Open your identity check']);
    expect(find.text('Identity check'), findsOneWidget);
    expect(find.text(_locked), findsOneWidget);
  });
}
