import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/game/data/game_repository.dart';
import 'package:olympus_go/features/game/domain/game_models.dart';
import 'package:olympus_go/features/game/presentation/reward_screens.dart';

class _Empty extends DemoGameRepository {
  @override
  Future<List<GameVoucher>> vouchers() async => const [];

  @override
  Future<OrganizerRewards> organizerRewards() async =>
      const OrganizerRewards(counted: 0, nextGame: 2, nextA: 1);
}

class _Failing extends DemoGameRepository {
  @override
  Future<List<GameVoucher>> vouchers() async =>
      throw const AuthFailure('Check your connection.');
}

class _Waiting extends DemoGameRepository {
  @override
  Future<OrganizerRewards> organizerRewards() async =>
      const OrganizerRewards(counted: 8, nextGame: 12, nextA: 2, waiting: 3);
}

class _Settings extends DemoGameRepository {
  @override
  Future<OrganizerRewards> organizerRewards() async => const OrganizerRewards(
    counted: 0,
    nextGame: 2,
    nextA: 1,
    minPresent: 8,
    feeCents: 300,
  );
}

class _Open extends DemoGameRepository {
  @override
  Future<OrganizerRewards> organizerRewards() async => const OrganizerRewards(
    counted: 8,
    nextGame: 12,
    nextA: 2,
    waiting: 1,
    open: true,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, [
  GameRepository? repo,
]) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repo ?? DemoGameRepository()),
      ],
      child: MaterialApp.router(
        theme: OgTheme.light(),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => screen),
            GoRoute(
              path: '/:rest(.*)',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('wallet', () {
    testWidgets('a usable voucher shows its code and date', (tester) async {
      await _pump(tester, const WalletScreen());
      expect(find.text('Ready to use'), findsOneWidget);
      expect(find.text('A1B2C3D4E5F6'), findsOneWidget);
      expect(find.textContaining('Use by'), findsOneWidget);
    });

    testWidgets('Voucher B waits for court booking, with no code', (
      tester,
    ) async {
      await _pump(tester, const WalletScreen());
      expect(find.text('Opens with court booking'), findsOneWidget);
      expect(find.text('0F1E2D3C4B5A'), findsNothing);
    });

    testWidgets('empty', (tester) async {
      await _pump(tester, const WalletScreen(), _Empty());
      expect(find.textContaining('No vouchers yet'), findsOneWidget);
    });

    testWidgets('a failure offers a retry', (tester) async {
      await _pump(tester, const WalletScreen(), _Failing());
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('organizer rewards', () {
    testWidgets('says what the next game earns', (tester) async {
      await _pump(tester, const OrganizerRewardsScreen());
      expect(find.text('3 counted games'), findsOneWidget);
      expect(
        find.textContaining('Game 4 earns 1 shop voucher'),
        findsOneWidget,
      );
    });

    testWidgets('says why a game didn’t count', (tester) async {
      await _pump(tester, const OrganizerRewardsScreen());
      expect(find.textContaining('Game 3'), findsOneWidget);
      expect(
        find.textContaining('Not everyone was scanned in by QR'),
        findsWidgets,
      );
    });

    testWidgets('the organizer needn’t pay, and it says so', (tester) async {
      await _pump(tester, const OrganizerRewardsScreen());
      expect(
        find.textContaining('You don’t have to pay or play'),
        findsOneWidget,
      );
    });

    testWidgets('the numbers come from the server', (tester) async {
      await _pump(tester, const OrganizerRewardsScreen(), _Settings());
      expect(find.textContaining('8 or more players'), findsOneWidget);
      expect(find.textContaining('S\$3.00 fee'), findsOneWidget);
    });

    testWidgets('rewards waiting with no voucher set up', (tester) async {
      await _pump(tester, const OrganizerRewardsScreen(), _Open());
      expect(
        find.textContaining('Our team is setting them up'),
        findsOneWidget,
      );
    });

    testWidgets('rewards waiting to open', (tester) async {
      await _pump(tester, const OrganizerRewardsScreen(), _Waiting());
      expect(find.textContaining('3 vouchers waiting'), findsOneWidget);
    });
  });

  test('every reason reads as a sentence', () {
    for (final r in [
      'counted',
      'under_six',
      'unpaid',
      'not_scanned',
      'cancelled',
      'organizer_minor',
      'organizer_flagged',
    ]) {
      final g = OrganizerGame(
        title: 'x',
        at: DateTime(2026),
        counted: false,
        reason: r,
      );
      expect(g.why, isNotEmpty);
    }
  });
}
