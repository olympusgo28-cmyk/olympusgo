// Vouchers and campaigns through the real API, the real Edge Functions and the
// Stripe stand-in. Skipped unless LOCAL_MONEY_TESTS is set, because it switches
// payments on for the whole stack: run it alone, with `supabase functions
// serve` running. Never the hosted project.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/game/data/game_repository.dart';
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
  const flags = [
    'payments.enabled',
    'shop.checkout',
    'game.campaigns',
    'game.organizer_rewards',
  ];

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

  String idOf(SupabaseClient c) => c.auth.currentUser!.id;

  Future<(String, String, String)> shop(SupabaseClient owner) async {
    final mall = await admin
        .from('malls')
        .insert({
          'owner_id': idOf(owner),
          'name': 'Voucher shop ${seq++}-${DateTime.now().microsecond}',
          'initials': 'VS',
          'collect_address': '1 Test Road',
          'active': true,
        })
        .select('id')
        .single();
    final item = await admin
        .from('products')
        .insert({
          'mall_id': mall['id'],
          'name': 'Test racket',
          'price_cents': 10000,
          'stock': 5,
          'published': true,
        })
        .select('id')
        .single();
    final type = await admin
        .from('voucher_types')
        .insert({
          'name': 'S\$8 off',
          'kind': 'A',
          'mall_id': mall['id'],
          'amount_minor': 800,
        })
        .select('id')
        .single();
    return (mall['id'] as String, item['id'] as String, type['id'] as String);
  }

  Future<String> voucher(SupabaseClient buyer, String type) async {
    final v = await admin
        .from('vouchers')
        .insert({
          'type_id': type,
          'owner_id': idOf(buyer),
          'code': 'TEST${DateTime.now().microsecondsSinceEpoch}',
          'expires_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'source': 'test:${seq++}:${DateTime.now().microsecondsSinceEpoch}',
        })
        .select('id')
        .single();
    return v['id'] as String;
  }

  CartLine line(String id) => CartLine(
    id: 'now',
    product: Product(
      id: id,
      name: 'Test racket',
      mallId: '',
      mallName: '',
      priceCents: 0,
    ),
    qty: 1,
  );

  Future<String> status(String voucherId) async =>
      (await admin
              .from('vouchers')
              .select('status')
              .eq('id', voucherId)
              .single())['status']
          as String;

  setUpAll(() async {
    if (skip != null) return;
    admin = SupabaseClient(url!, service!);
    await admin
        .from('feature_flags')
        .update({'enabled': true})
        .inFilter('key', flags);
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin
        .from('feature_flags')
        .update({'enabled': false})
        .inFilter('key', flags);
  });

  test(
    'a voucher through checkout, 20 replayed webhooks, cancelled and back',
    () async {
      final owner = await player('vowner');
      final buyer = await player('vbuyer');
      final (mall, item, type) = await shop(owner);
      final v = await voucher(buyer, type);
      final repo = SupabaseShopRepository(buyer);

      var q = await repo.quote(mall, only: line(item));
      expect(q.vouchers.single.id, v);
      expect(q.totalCents, 10000);
      q = await repo.quote(mall, only: line(item), voucherId: v);
      expect(q.voucherCents, 800);
      expect(q.totalCents, 9200);

      final (hold, order) = await repo.reserve(
        mall,
        key: 'voucher-${idOf(buyer)}',
        expectedCents: q.totalCents,
        only: line(item),
        voucherId: v,
      );
      expect(await status(v), 'used');
      final gateway = SupabasePaymentGateway(buyer);
      await gateway.begin(hold.id!, (await gateway.methods()).first);
      await buyer.functions.invoke(
        'stripe-local',
        body: {'action': 'succeed', 'payment_id': hold.id, 'repeat': 20},
      );
      for (var i = 0; i < 40; i++) {
        if ((await repo.order(order)).step == OrderStep.paid) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      final o = await repo.order(order);
      expect(o.step, OrderStep.paid);
      expect(o.voucherCents, 800);
      expect(o.totalCents, 9200);

      // Over the real API, as the buyer, with commit-time checks running.
      await repo.cancelOrder(order, reason: 'Changed my mind');
      expect(await status(v), 'issued');
      final log = await admin
          .from('voucher_redemptions')
          .select('kind')
          .eq('voucher_id', v);
      expect(log.map((r) => r['kind']), ['used', 'returned']);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'someone else can\'t spend it, and the wallet is the owner\'s alone',
    () async {
      final owner = await player('wowner');
      final buyer = await player('wbuyer');
      final other = await player('wother');
      final (mall, item, type) = await shop(owner);
      final v = await voucher(buyer, type);
      await expectLater(
        SupabaseShopRepository(other)
            .quote(mall, only: line(item), voucherId: v),
        throwsA(isA<Object>()),
      );
      expect(await SupabaseGameRepository(other).vouchers(), isEmpty);
      final mine = await SupabaseGameRepository(buyer).vouchers();
      expect(mine.single.usable, isTrue);
      expect(mine.single.code, startsWith('TEST'));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'a campaign: join, attend, and the voucher arrives',
    () async {
      final owner = await player('cowner');
      final runner = await player('crunner');
      final (_, _, type) = await shop(owner);
      final c = await admin
          .from('campaigns')
          .insert({
            'title': 'Play one',
            'starts_at': DateTime.now()
                .toUtc()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'ends_at': DateTime.now()
                .toUtc()
                .add(const Duration(days: 5))
                .toIso8601String(),
            'status': 'live',
          })
          .select('id')
          .single();
      await admin.from('quests').insert({
        'campaign_id': c['id'],
        'type': 'attend_sessions',
        'target': 1,
        'voucher_type_id': type,
      });
      final game = SupabaseGameRepository(runner);
      expect((await game.campaigns()).map((x) => x.id), contains(c['id']));
      await game.join(c['id'] as String);
      expect((await game.campaign(c['id'] as String)).joined, isTrue);
      expect(await game.vouchers(), isEmpty);

      final venue = await admin.from('venues').select('id').limit(1).single();
      // A session counts once it's over, so this one is over in seconds.
      final start = DateTime.now().toUtc().add(const Duration(seconds: 2));
      final meet = await admin
          .from('activities')
          .insert({
            'kind': 'meet',
            'host_id': idOf(owner),
            'title': 'Quest test',
            'sports': ['badminton'],
            'game_type': 'doubles',
            'format': 'open_play',
            'starts_at': start.toIso8601String(),
            'ends_at': start.add(const Duration(seconds: 1)).toIso8601String(),
            'venue_id': venue['id'],
            'capacity': 10,
          })
          .select('id')
          .single();
      await admin.from('activity_participants').insert({
        'activity_id': meet['id'],
        'user_id': idOf(runner),
        'status': 'joined',
      });
      await Future<void>.delayed(const Duration(seconds: 4));
      await admin
          .from('activity_participants')
          .update({'attendance': 'present', 'check_in_method': 'qr'})
          .eq('activity_id', meet['id'] as String);

      final mine = await game.vouchers();
      expect(mine, hasLength(1));
      expect(mine.single.usable, isTrue);
      await admin
          .from('campaigns')
          .update({'status': 'ended'})
          .eq('id', c['id'] as String);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
