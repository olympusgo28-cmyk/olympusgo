// The Shop through the real API, the real Edge Functions and the Stripe
// stand-in, with real parallel connections. Skipped unless LOCAL_MONEY_TESTS is
// set, because it switches payments on for the whole stack: run it alone, with
// `supabase functions serve` running. Never the hosted project.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/play/data/payment_gateway.dart';
import 'package:olympus_go/features/shop/data/shop_repository.dart';
import 'package:olympus_go/features/shop/domain/commerce_models.dart';
import 'package:olympus_go/features/shop/domain/shop_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_accounts.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final service = Platform.environment['LOCAL_SUPABASE_SERVICE_KEY'];
  final skip =
      url == null ||
          key == null ||
          service == null ||
          !url.contains('127.0.0.1') ||
          Platform.environment['LOCAL_MONEY_TESTS'] == null
      ? 'Needs a local stack, its functions and LOCAL_MONEY_TESTS'
      : null;

  late SupabaseClient admin;
  var seq = 0;

  Future<SupabaseClient> player(String name) async {
    final c = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await signUpLocal(
      c,
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await c.rpc(
      'set_birthday',
      params: {'p_birthday': '1990-01-01', 'p_country': 'SG'},
    );
    await c
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 10000000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', c.auth.currentUser!.id);
    return c;
  }

  Future<String> shop(SupabaseClient owner, {bool onTop = false}) async {
    final row = await admin
        .from('malls')
        .insert({
          'owner_id': owner.auth.currentUser!.id,
          'name': 'Shop ${DateTime.now().microsecondsSinceEpoch}-${seq++}',
          'initials': 'SH',
          'collect_address': '1 Test Road',
          'active': true,
          'commission_on_top': onTop,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<String> product(
    String mall, {
    int price = 10000,
    int stock = 5,
  }) async {
    final row = await admin
        .from('products')
        .insert({
          'mall_id': mall,
          'name': 'Test racket',
          'price_cents': price,
          'stock': stock,
          'published': true,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<int> stock(String id) async =>
      (await admin
              .from('products')
              .select('stock')
              .eq('id', id)
              .single())['stock']
          as int;

  CartLine line(String id, {int qty = 1}) => CartLine(
    id: 'now',
    product: Product(
      id: id,
      name: 'Test racket',
      mallId: '',
      mallName: '',
      priceCents: 0,
    ),
    qty: qty,
  );

  Future<void> givePoints(SupabaseClient p, int minor) async {
    final id = DateTime.now().microsecondsSinceEpoch + seq++;
    await admin.from('points_entries').insert({
      'id': id,
      'user_id': p.auth.currentUser!.id,
      'kind': 'earn',
      'amount_minor': minor,
      'lot_id': id,
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(days: 300))
          .toIso8601String(),
      'source_kind': 'test',
      'source_id': '$id',
      'idempotency_key': 'test:$id',
    });
  }

  // Buys through the same calls the app makes, up to a payment that's started.
  Future<(PaymentHold, String)> reserve(
    SupabaseClient p,
    String mall,
    String item, {
    int qty = 1,
    int points = 0,
  }) async {
    final repo = SupabaseShopRepository(p);
    final q = await repo.quote(
      mall,
      only: line(item, qty: qty),
      pointsCents: points,
    );
    return repo.reserve(
      mall,
      key: 'shop-${p.auth.currentUser!.id}-${seq++}',
      expectedCents: q.totalCents,
      pointsCents: points,
      only: line(item, qty: qty),
    );
  }

  Future<(PaymentHold, String)> buy(
    SupabaseClient p,
    String mall,
    String item, {
    int qty = 1,
    int points = 0,
    int repeat = 1,
  }) async {
    final held = await reserve(p, mall, item, qty: qty, points: points);
    final gateway = SupabasePaymentGateway(p);
    await gateway.begin(held.$1.id!, (await gateway.methods()).first);
    await p.functions.invoke(
      'stripe-local',
      body: {'action': 'succeed', 'payment_id': held.$1.id, 'repeat': repeat},
    );
    return held;
  }

  Future<void> runWorker() async {
    for (var i = 0; i < 40; i++) {
      final res = await HttpClient()
          .postUrl(Uri.parse('$url/functions/v1/money-worker'))
          .then((r) {
            r.headers.set('x-worker-secret', 'local-worker-secret');
            r.headers.set('content-type', 'application/json');
            r.write('{}');
            return r.close();
          });
      expect(res.statusCode, 200);
      final body = await res.transform(utf8.decoder).join();
      if (!body.contains('skipped')) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    fail('The worker lease never came free');
  }

  Future<int> ledger(String kind, {String? owner}) async {
    var q = admin.from('ledger_accounts').select('id').eq('kind', kind);
    if (owner != null) q = q.eq('owner_id', owner);
    final ids = [for (final r in await q) r['id']];
    if (ids.isEmpty) return 0;
    final rows = await admin
        .from('ledger_entries')
        .select('amount_minor')
        .inFilter('account_id', ids);
    return rows.fold<int>(0, (a, r) => a + (r['amount_minor'] as num).toInt());
  }

  setUpAll(() async {
    if (skip != null) return;
    admin = SupabaseClient(url!, service!);
    await admin.from('feature_flags').update({'enabled': true}).inFilter(
      'key',
      ['payments.enabled', 'shop.checkout'],
    );
    await admin.from('app_settings').upsert({
      'key': 'points.redeem_min_account_days',
      'value': 0,
    });
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin.from('feature_flags').update({'enabled': false}).inFilter(
      'key',
      ['payments.enabled', 'shop.checkout'],
    );
    await admin
        .from('app_settings')
        .delete()
        .eq('key', 'points.redeem_min_account_days');
  });

  test('buy, 20 replayed webhooks, ready, collected, review', () async {
    final owner = await player('sowner');
    final buyer = await player('sbuyer');
    final mall = await shop(owner);
    final item = await product(mall);
    final repo = SupabaseShopRepository(buyer);
    final shopRepo = SupabaseShopRepository(owner);
    await repo.addToCart(item, qty: 2);
    expect((await repo.cart()).single.qty, 2);

    final q = await repo.quote(mall);
    expect(q.totalCents, 20000);
    expect(q.collectAddress, '1 Test Road');
    expect(q.refundRule, contains('final once collected'));
    expect(q.canPay, isTrue);

    // A wrong price refuses rather than charges.
    await expectLater(
      repo.reserve(mall, key: 'wrong-price-1', expectedCents: 19999),
      throwsA(
        isA<AuthFailure>().having((e) => e.message, 'm', 'price_changed'),
      ),
    );

    final (hold, id) = await repo.reserve(
      mall,
      key: 'journey-${buyer.auth.currentUser!.id}',
      expectedCents: 20000,
    );
    expect(await stock(item), 3);
    expect((await repo.order(id)).step, OrderStep.pending);
    expect(await shopRepo.ownerOrders(), isEmpty);
    await expectLater(shopRepo.order(id), throwsA(isA<AuthFailure>()));

    // The app can't mark its own order paid.
    await buyer.from('orders').update({'step': 'paid'}).eq('id', id);
    expect((await repo.order(id)).step, OrderStep.pending);

    final gateway = SupabasePaymentGateway(buyer);
    await gateway.begin(hold.id!, (await gateway.methods()).first);
    await buyer.functions.invoke(
      'stripe-local',
      body: {'action': 'succeed', 'payment_id': hold.id, 'repeat': 20},
    );
    expect((await gateway.progress(hold.id!)).state, PaymentState.paid);
    final captures = await admin
        .from('ledger_transactions')
        .select('id')
        .eq('idempotency_key', 'capture:${hold.id}');
    expect(captures.length, 1);
    expect(await stock(item), 3);

    var order = await repo.order(id);
    expect(order.step, OrderStep.paid);
    expect(order.totalCents, 20000);
    expect(order.shopCents, 0);
    expect((await shopRepo.order(id)).shopCents, 18000);
    expect((await shopRepo.order(id)).paymentId, isNull);
    expect(order.collectBy, isNotNull);
    expect(order.releaseAt, isNotNull);

    final listed = await shopRepo.ownerOrders();
    expect(listed.single.id, id);
    expect(listed.single.buyer, 'sbuyer Test');
    await shopRepo.markReady(id);
    expect((await repo.order(id)).step, OrderStep.ready);

    await expectLater(
      SupabaseShopRepository(owner).collected(id),
      throwsA(isA<AuthFailure>()),
    );

    final ownerId = owner.auth.currentUser!.id;
    final before = await ledger('organizer', owner: ownerId);
    await Future.wait([for (var i = 0; i < 5; i++) repo.collected(id)]);
    order = await repo.order(id);
    expect(order.step, OrderStep.collected);
    expect(await ledger('organizer', owner: ownerId), before - 18000);
    expect(await ledger('held', owner: id), 0);

    await repo.review(
      id,
      stars: 5,
      tags: const ['Good grip'],
      text: 'Lovely',
      showLevel: false,
    );
    expect((await repo.order(id)).reviewed, isTrue);
    expect((await repo.product(item)).reviews, hasLength(1));
    await owner.dispose();
    await buyer.dispose();
  }, skip: skip);

  test('cancelling gives back the money, the stock and the points', () async {
    final owner = await player('cowner');
    final buyer = await player('cbuyer');
    final mall = await shop(owner);
    final item = await product(mall);
    await givePoints(buyer, 2000);
    final repo = SupabaseShopRepository(buyer);

    final q = await repo.quote(mall, only: line(item), pointsCents: 500);
    expect(q.totalCents, 9500);
    expect(q.pointsCapCents, 500);

    final (hold, id) = await buy(buyer, mall, item, points: 500);
    expect(await stock(item), 4);
    final refunds = await Future.wait([
      for (var i = 0; i < 5; i++)
        repo
            .cancelOrder(id, reason: 'Ordered by mistake')
            .then<Object>((v) => v, onError: (Object e) => e),
    ]);
    expect(refunds.whereType<int>().where((v) => v > 0), [9500]);
    expect(await stock(item), 5);

    await runWorker();
    final rows = await admin
        .from('refunds')
        .select('status, amount_minor')
        .eq('payment_id', hold.id!);
    expect(rows.single['status'], 'succeeded');
    final points = await buyer.rpc<Map<String, dynamic>>('points_my');
    expect(points['balance_minor'], 2000);
    await owner.dispose();
    await buyer.dispose();
  }, skip: skip);

  test('an on-top shop charges the commission on top', () async {
    final owner = await player('tNowner');
    final buyer = await player('tbuyer');
    final mall = await shop(owner, onTop: true);
    final item = await product(mall);
    final repo = SupabaseShopRepository(buyer);
    final (hold, id) = await buy(buyer, mall, item);
    expect(hold.totalCents, 11000);
    await repo.collected(id);
    expect(
      await ledger('organizer', owner: owner.auth.currentUser!.id),
      -10000,
    );
    await owner.dispose();
    await buyer.dispose();
  }, skip: skip);

  test('a report holds the money and a shop cancel refunds it', () async {
    final owner = await player('rowner');
    final buyer = await player('rbuyer');
    final mall = await shop(owner);
    final item = await product(mall);
    final repo = SupabaseShopRepository(buyer);

    final (_, first) = await buy(buyer, mall, item);
    await repo.reportProblem(first, 'The strings are snapped.');
    expect((await repo.order(first)).step, OrderStep.reported);
    await expectLater(repo.collected(first), throwsA(isA<AuthFailure>()));
    expect(await ledger('held', owner: first), lessThan(0));

    final (_, second) = await buy(buyer, mall, item);
    await SupabaseShopRepository(owner)
        .ownerCancel(second, reason: 'Out of stock');
    final order = await repo.order(second);
    expect(order.step, OrderStep.cancelled);
    expect(order.refundedCents, 10000);
    await owner.dispose();
    await buyer.dispose();
  }, skip: skip);

  test(
    '50 buyers race for the last one and one gets it',
    () async {
      final owner = await player('lowner');
      final mall = await shop(owner);
      final item = await product(mall, stock: 1);
      final buyers = await Future.wait([
        for (var i = 0; i < 50; i++) player('l$i'),
      ]);
      final refusals = <String>[];
      final results = await Future.wait([
        for (final b in buyers)
          reserve(b, mall, item).then<bool>(
            (_) => true,
            onError: (Object e) {
              refusals.add((e as AuthFailure).message);
              return false;
            },
          ),
      ]);
      expect(results.where((r) => r).length, 1);
      // Each lost for the right reason: the item went, not a failed call.
      expect(
        refusals,
        everyElement(
          anyOf(contains('Not enough'), contains('price'), contains('listed')),
        ),
      );
      expect(await stock(item), 0);
      for (final p in [owner, ...buyers]) {
        await p.dispose();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('two carts can\'t spend the same points', () async {
    final owner = await player('powner');
    final other = await player('pother');
    final buyer = await player('pbuyer');
    final a = await shop(owner);
    final b = await shop(other);
    final first = await product(a);
    final second = await product(b);
    await givePoints(buyer, 500);

    final results = await Future.wait([
      for (final (mall, item) in [(a, first), (b, second)])
        reserve(
          buyer,
          mall,
          item,
          points: 500,
        ).then<bool>((_) => true, onError: (Object e) => false),
    ]);
    expect(results.where((r) => r).length, 1);
    final points = await buyer.rpc<Map<String, dynamic>>('points_my');
    expect(points['balance_minor'], 0);
    await owner.dispose();
    await other.dispose();
    await buyer.dispose();
  }, skip: skip);
}
