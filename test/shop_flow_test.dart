import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/earnings/data/earnings_repository.dart';
import 'package:olympus_go/features/play/data/payment_gateway.dart';
import 'package:olympus_go/features/shop/data/shop_repository.dart';
import 'package:olympus_go/features/shop/domain/commerce_models.dart';
import 'package:olympus_go/features/shop/presentation/order_screens.dart';
import 'package:olympus_go/features/shop/presentation/owner_screens.dart';

class _Gateway implements PaymentGateway {
  _Gateway(this.state);
  final PaymentState state;
  int begun = 0;

  @override
  bool get canCollect => true;

  @override
  bool get canSimulate => false;

  @override
  Future<void> simulate(String paymentId) async {}

  @override
  Future<PaymentProgress> progress(String paymentId) async =>
      PaymentProgress(state: state);

  @override
  Future<void> abandon(String paymentId) async {}

  @override
  Future<void> begin(String paymentId, PayMethod method) async => begun++;

  @override
  Future<List<PayMethod>> methods() async => const [
    PayMethod(id: 'card', title: 'Card', detail: ''),
  ];

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

/// The order stays unpaid, as if the buyer left a payment running.
class _Unpaid extends DemoShopRepository {
  _Unpaid() : super(DemoEarningsRepository());

  @override
  Future<Order> order(String id) async => Order(
    id: id,
    mallId: 'm-court',
    mallName: 'Court Supply Co.',
    lines: const [OrderLine('Grip', '', 1, 900)],
    placedAt: DateTime(2026),
    step: OrderStep.pending,
  );
}

/// The money landed, but reading the order back fails.
class _LostAnswer extends DemoShopRepository {
  _LostAnswer() : super(DemoEarningsRepository());

  @override
  Future<Order> order(String id) async =>
      throw const AuthFailure('Can’t reach OlympusGO.');
}

/// Fails until told otherwise.
class _Failing extends DemoShopRepository {
  _Failing() : super(DemoEarningsRepository());
  bool broken = true;

  @override
  Future<Order> order(String id) async {
    if (broken) throw const AuthFailure('Can’t reach OlympusGO.');
    return Order(
      id: id,
      mallId: 'm-court',
      mallName: 'Court Supply Co.',
      lines: const [OrderLine('Grip', '', 1, 900)],
      placedAt: DateTime(2026),
      step: OrderStep.paid,
    );
  }
}

Widget _app(Widget home, ShopRepository repo, [PaymentGateway? gateway]) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/shop/orders/:id',
        builder: (_, _) => const Text('the order page'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      shopRepositoryProvider.overrideWithValue(repo),
      if (gateway != null) paymentGatewayProvider.overrideWithValue(gateway),
    ],
    child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  ShopRepository repo, [
  PaymentGateway? gateway,
]) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home, repo, gateway));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// The demo waits on real timers, which a widget test's clock doesn't run.
Future<OrderStep?> _step(WidgetTester tester, ShopRepository repo, String id) =>
    tester.runAsync(() async => (await repo.order(id)).step);

void main() {
  late DemoShopRepository repo;
  setUp(() => repo = DemoShopRepository(DemoEarningsRepository()));

  testWidgets('P4b-04 the buyer confirms only after a warning', (tester) async {
    await _pump(tester, const OrderDetailScreen(id: 'o-1001'), repo);
    expect(find.text('Ready to collect'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);

    await tester.tap(find.text('Yes, I got it all'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Got everything?'), findsOneWidget);
    expect((await _step(tester, repo, 'o-1001')), OrderStep.ready);

    await tester.tap(find.text('Yes, I got it all').last);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect((await _step(tester, repo, 'o-1001')), OrderStep.collected);
  });

  testWidgets('P4b-04 a collected order can\'t be cancelled', (tester) async {
    await _pump(tester, const OrderDetailScreen(id: 'o-0990'), repo);
    expect(find.text('Cancel order'), findsNothing);
    expect(find.text('Yes, I got it all'), findsNothing);
    expect(find.text('Write a review'), findsOneWidget);
  });

  testWidgets('P4b-03 checkout shows the final price and where to collect', (
    tester,
  ) async {
    await repo.addToCart('p-grip', qty: 2);
    await _pump(tester, const CheckoutScreen(mallId: 'm-court'), repo);
    expect(find.text('Collect from Court Supply Co.'), findsOneWidget);
    expect(find.text('Final price'), findsOneWidget);
    expect(find.text('S\$18.00'), findsWidgets);
    expect(find.textContaining('final once collected'), findsOneWidget);
  });

  // Pay, the sheet, Confirm, then the waiting screen.
  Future<void> pay(WidgetTester tester) async {
    await tester.tap(find.text('Pay'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.textContaining('Pay S\$').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Confirm'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('P4b-03 paying ends on the order placed', (tester) async {
    await repo.addToCart('p-grip');
    final gateway = _Gateway(PaymentState.paid);
    await _pump(tester, const CheckoutScreen(mallId: 'm-court'), repo, gateway);
    await pay(tester);
    expect(gateway.begun, 1);
    expect(find.text('Order placed'), findsOneWidget);
  });

  testWidgets('P4b-03 a payment left running can\'t be paid twice', (
    tester,
  ) async {
    final unpaid = _Unpaid();
    await unpaid.addToCart('p-grip');
    await _pump(
      tester,
      const CheckoutScreen(mallId: 'm-court'),
      unpaid,
      _Gateway(PaymentState.ended),
    );
    await pay(tester);
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('the order page'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // The toast's timer.
  });

  testWidgets('P4b-03 a lost answer after paying doesn\'t offer Pay again', (
    tester,
  ) async {
    final lost = _LostAnswer();
    await lost.addToCart('p-grip');
    await _pump(
      tester,
      const CheckoutScreen(mallId: 'm-court'),
      lost,
      _Gateway(PaymentState.paid),
    );
    await pay(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('the order page'), findsOneWidget);
  });

  testWidgets('P4b-04 a ready service can\'t be cancelled', (tester) async {
    await tester.runAsync(() => repo.markReady('s-2003'));
    expect(
      (await tester.runAsync(() => repo.order('s-2003')))!.canCancel,
      isFalse,
    );
  });

  testWidgets('P4b-04 the owner marks an order ready', (tester) async {
    await _pump(tester, const OwnerOrderScreen(id: 's-2001'), repo);
    expect(find.text('You get'), findsOneWidget);
    await tester.tap(find.text('Mark ready'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect((await _step(tester, repo, 's-2001')), OrderStep.ready);
  });

  testWidgets('P4b-04 only a service can be started', (tester) async {
    await _pump(tester, const OwnerOrderScreen(id: 's-2001'), repo);
    expect(find.text('Start work'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, const OwnerOrderScreen(id: 's-2003'), repo);
    expect(find.text('Start work'), findsOneWidget);
  });

  test('an ended order says where the money went', () {
    Order order({
      String status = 'succeeded',
      int refunded = 0,
      String? refund,
      String? dispute,
    }) => Order(
      id: 'o',
      mallId: 'm',
      mallName: 'Shop',
      lines: const [],
      placedAt: DateTime(2026),
      step: OrderStep.cancelled,
      paymentStatus: status,
      refundedCents: refunded,
      refundStatus: refund,
      disputeStatus: dispute,
    );
    expect(shopMoneyLine(order(status: 'cancelled')), 'You weren’t charged.');
    expect(
      shopMoneyLine(order(status: 'cancel_requested')),
      contains('still lands'),
    );
    expect(shopMoneyLine(order(refunded: 900)), contains('S\$9.00'));
    expect(shopMoneyLine(order(dispute: 'open')), contains('on hold'));
    expect(shopMoneyLine(order(dispute: 'lost')), contains('bank returned'));
    expect(
      shopMoneyLine(order(refunded: 900, refund: 'failed')),
      contains('hasn’t gone through'),
    );
  });

  testWidgets('a failed load says so, and can try again', (tester) async {
    final failing = _Failing();
    await _pump(tester, const OrderDetailScreen(id: 'o-1'), failing);
    expect(find.textContaining('Can’t load this'), findsOneWidget);
    failing.broken = false;
    await tester.tap(find.text('Try again'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Report a problem'), findsOneWidget);
  });

  testWidgets('the owner\'s list shows what the shop gets', (tester) async {
    await _pump(tester, const OwnerOrdersScreen(), repo);
    expect(find.text('S\$170.10'), findsOneWidget);
    expect(Routes.ownerOrder('x'), '/shop/owner/orders/x');
  });
}
