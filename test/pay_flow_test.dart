import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/play/data/payment_gateway.dart';
import 'package:olympus_go/features/play/presentation/pay_flow.dart';

class _Gateway implements PaymentGateway {
  _Gateway(this.answer);
  PaymentProgress answer;
  bool abandoned = false;
  bool simulated = false;
  bool offline = false;

  @override
  bool get canCollect => true;

  @override
  bool get canSimulate => true;

  @override
  Future<void> simulate(String paymentId) async => simulated = true;

  @override
  Future<PaymentProgress> progress(String paymentId) async {
    if (offline) throw const AuthFailure('offline');
    return answer;
  }

  @override
  Future<void> abandon(String paymentId) async => abandoned = true;

  @override
  Future<void> begin(String paymentId, PayMethod method) async {}

  @override
  Future<List<PayMethod>> methods() async => const [];

  @override
  Future<PayQuote> quote(String activityId, {int qty = 1}) =>
      throw UnimplementedError();

  @override
  Future<PaymentHold> reserve({
    required String activityId,
    required String key,
    int qty = 1,
    String? guestName,
    double? guestLevel,
  }) => throw UnimplementedError();

  @override
  Future<PaymentHold> reserveFeesOwed(String key) => throw UnimplementedError();
}

PaymentHold _hold({Duration left = const Duration(minutes: 10)}) {
  final server = DateTime.utc(2026, 11, 1, 12);
  return PaymentHold(
    result: 'reserved',
    id: 'p1',
    totalCents: 800,
    serverNow: server,
    holdUntil: server.add(left),
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Gateway gateway,
  PaymentHold hold,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [paymentGatewayProvider.overrideWithValue(gateway)],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: PaymentWaitingScreen(hold: hold),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  const waiting = PaymentProgress(state: PaymentState.waiting);

  testWidgets('counts down on the server\'s clock, not the phone\'s', (
    tester,
  ) async {
    await _pump(tester, _Gateway(waiting), _hold());
    expect(find.text('Waiting for payment'), findsOneWidget);
    expect(find.textContaining('S\$8.00 to OlympusGO'), findsOneWidget);
    expect(find.textContaining('holding your spot for 9:5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('says so when the hold runs out', (tester) async {
    await _pump(tester, _Gateway(waiting), _hold(left: Duration.zero));
    expect(find.textContaining('Your hold ran out'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed try keeps the spot', (tester) async {
    await _pump(
      tester,
      _Gateway(
        const PaymentProgress(state: PaymentState.waiting, failed: true),
      ),
      _hold(),
    );
    expect(find.textContaining('didn’t go through'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a refunded payment explains itself', (tester) async {
    await _pump(
      tester,
      _Gateway(const PaymentProgress(state: PaymentState.refunded)),
      _hold(),
    );
    expect(find.text('Your payment is coming back'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an ended payment says nothing was charged', (tester) async {
    await _pump(
      tester,
      _Gateway(const PaymentProgress(state: PaymentState.ended)),
      _hold(),
    );
    expect(find.textContaining('weren’t charged'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancel gives the spot up', (tester) async {
    final gateway = _Gateway(waiting);
    await _pump(tester, gateway, _hold());
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(gateway.abandoned, true);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a poll that fails keeps waiting', (tester) async {
    final gateway = _Gateway(waiting)..offline = true;
    await _pump(tester, gateway, _hold());
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Waiting for payment'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the test button only finishes through the stand-in', (
    tester,
  ) async {
    final gateway = _Gateway(waiting);
    await _pump(tester, gateway, _hold());
    await tester.tap(find.text('Finish test payment'));
    await tester.pump();
    expect(gateway.simulated, true);
    await tester.pumpWidget(const SizedBox());
  });
}
