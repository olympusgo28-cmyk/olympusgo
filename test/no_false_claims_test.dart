// Q266 (11 Nov 2026): four controls said they had done something when
// nothing happened. They are gone until the feature behind each exists.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/earnings/application/earnings_providers.dart';
import 'package:olympus_go/features/earnings/data/earnings_repository.dart';
import 'package:olympus_go/features/earnings/presentation/earnings_screens.dart';
import 'package:olympus_go/features/fitness/application/fitness_providers.dart';
import 'package:olympus_go/features/fitness/domain/fitness_models.dart';
import 'package:olympus_go/features/settings/data/settings_repository.dart';
import 'package:olympus_go/features/settings/domain/settings_models.dart';
import 'package:olympus_go/features/settings/presentation/account_screens.dart';
import 'package:olympus_go/features/settings/presentation/settings_screens.dart';

class _Settings implements SettingsRepository {
  @override
  Future<PrivacyPrefs> privacy() async => const PrivacyPrefs();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<dynamic> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(820, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(theme: OgTheme.light(), home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a receipt offers no "Email me a copy": nothing sends one', (
    tester,
  ) async {
    await _pump(
      tester,
      const ReceiptsScreen(),
      overrides: [
        receiptsProvider.overrideWith(
          (_) async => [
            ReceiptRecord(
              id: 'r1',
              title: 'Friday doubles',
              kind: 'Meet',
              at: DateTime(2026, 11, 6),
              no: 'R-0001',
              lines: const [('Spot', r'S$8.00')],
              totalCents: 800,
              paidWith: 'Visa ending 4242',
            ),
          ],
        ),
      ],
    );
    await tester.tap(find.text('Friday doubles'));
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT'), findsOneWidget);
    expect(find.text('Paid with'), findsOneWidget);
    expect(find.text('Email me a copy'), findsNothing);
  });

  testWidgets('Language shows English as the only choice, with no Save', (
    tester,
  ) async {
    await _pump(tester, const LanguageScreen());
    expect(find.text('English'), findsWidgets);
    expect(find.text('OlympusGO is in English for now.'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    // The others say they are not ready, and tapping one changes nothing.
    expect(find.text('Coming soon'), findsNWidgets(3));
    await tester.tap(find.text('Bahasa Melayu'));
    await tester.pumpAndSettle();
    expect(find.text('Malay is coming soon.'), findsOneWidget);
    expect(find.text('Language saved'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('Privacy shows only switches that do something', (tester) async {
    await _pump(
      tester,
      const PrivacyScreen(),
      overrides: [
        settingsRepositoryProvider.overrideWithValue(_Settings()),
        aiStatusProvider.overrideWith((_) async => const AiStatus()),
      ],
    );
    expect(find.text('Show my level'), findsOneWidget);
    expect(find.text('Find me by mobile number'), findsNothing);
    expect(find.text('Share my location at Meets'), findsNothing);
  });
}
