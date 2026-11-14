// The money path through the real API, the real Edge Functions and the Stripe
// stand-in, with real parallel connections. Skipped unless LOCAL_MONEY_TESTS is
// set, because it switches payments on for the whole stack: run it alone, with
// `supabase functions serve` running. Never the hosted project.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/play/data/payment_gateway.dart';
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

  SupabaseClient client() => SupabaseClient(
    url!,
    key!,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );

  late SupabaseClient admin;

  Future<SupabaseClient> player(String name) async {
    final c = client();
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

  Future<String> meet(
    SupabaseClient host, {
    int feeCents = 600,
    int capacity = 4,
  }) async {
    final venue = await host.from('venues').select('id').limit(1).single();
    final start = DateTime.now().toUtc().add(const Duration(days: 3));
    final row = await host
        .from('activities')
        .insert({
          'kind': 'meet',
          'host_id': host.auth.currentUser!.id,
          'title': 'Money Meet',
          'sports': ['badminton'],
          'game_type': 'doubles',
          'format': 'open_play',
          'starts_at': start.toIso8601String(),
          'ends_at': start.add(const Duration(hours: 2)).toIso8601String(),
          'venue_id': venue['id'],
          'capacity': capacity,
          'fee_cents': feeCents,
          'players_pay_fee': feeCents == 0,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  // The timer's worker may hold the lease, so ask again until this one runs.
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

  setUpAll(() async {
    if (skip != null) return;
    admin = SupabaseClient(url!, service!);
    await admin
        .from('feature_flags')
        .update({'enabled': true})
        .eq('key', 'payments.enabled');
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin
        .from('feature_flags')
        .update({'enabled': false})
        .eq('key', 'payments.enabled');
  });

  test('join, pay, confirm by webhook, give up, refund', () async {
    final host = await player('mhost');
    final p = await player('mplayer');
    final id = await meet(host);
    final gateway = SupabasePaymentGateway(p);

    final quote = await gateway.quote(id);
    expect(quote.totalCents, 800);
    expect(quote.refundRule, contains('without the fee'));

    final hold = await gateway.reserve(
      activityId: id,
      key: 'journey-${p.auth.currentUser!.id}',
    );
    expect(hold.result, 'reserved');
    expect(hold.totalCents, 800);
    await gateway.begin(hold.id!, (await gateway.methods()).last);

    var state = await gateway.progress(hold.id!);
    expect(state.state, PaymentState.waiting);

    // The app can't confirm its own payment.
    await expectLater(
      p.from('payments').update({'status': 'succeeded'}).eq('id', hold.id!),
      throwsA(isA<PostgrestException>()),
    );

    await p.functions.invoke(
      'stripe-local',
      body: {'action': 'succeed', 'payment_id': hold.id, 'repeat': 3},
    );
    state = await gateway.progress(hold.id!);
    expect(state.state, PaymentState.paid);

    final refund = await p.rpc<int>('leave_activity', params: {'activity': id});
    expect(refund, 600);

    await runWorker();
    final rows = await admin
        .from('refunds')
        .select('status, amount_minor')
        .eq('payment_id', hold.id!);
    expect(rows.single['status'], 'succeeded');
    expect(rows.single['amount_minor'], 600);
    await host.dispose();
    await p.dispose();
  }, skip: skip);

  test(
    '50 players race for the last spot and one gets it',
    () async {
      final host = await player('rhost');
      final first = await player('rfirst');
      final id = await meet(host, capacity: 2);
      await SupabasePaymentGateway(first).reserve(
        activityId: id,
        key: 'race-first-${first.auth.currentUser!.id}',
      );

      final players = await Future.wait([
        for (var i = 0; i < 50; i++) player('r$i'),
      ]);
      final results = await Future.wait([
        for (final (i, p) in players.indexed)
          SupabasePaymentGateway(p)
              .reserve(
                activityId: id,
                key: 'race-player-$i-${p.auth.currentUser!.id}',
              )
              .then((h) => h.result),
      ]);
      expect(results.where((r) => r == 'reserved').length, 1);
      expect(results.where((r) => r == 'waitlist').length, 49);
      final taken = await admin.rpc<int>(
        'activity_spots_taken',
        params: {'a': id},
      );
      expect(taken, 2);
      for (final p in [host, first, ...players]) {
        await p.dispose();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('parallel refunds and replayed webhooks move the money once', () async {
    final host = await player('dhost');
    final p = await player('dplayer');
    final id = await meet(host);
    final gateway = SupabasePaymentGateway(p);
    final hold = await gateway.reserve(
      activityId: id,
      key: 'once-${p.auth.currentUser!.id}',
    );
    await gateway.begin(hold.id!, (await gateway.methods()).first);

    await p.functions.invoke(
      'stripe-local',
      body: {'action': 'succeed', 'payment_id': hold.id, 'repeat': 20},
    );
    final captures = await admin
        .from('ledger_transactions')
        .select('id')
        .eq('idempotency_key', 'capture:${hold.id}');
    expect(captures.length, 1);

    final refunds = await Future.wait([
      for (var i = 0; i < 10; i++)
        p.rpc<int>('leave_activity', params: {'activity': id}),
    ]);
    expect(refunds.reduce((a, b) => a + b), 600);
    final rows = await admin
        .from('refunds')
        .select('id')
        .eq('payment_id', hold.id!);
    expect(rows.length, 1);
    await host.dispose();
    await p.dispose();
  }, skip: skip);

  test(
    'a free Meet: the organizer saves a card and is charged per join',
    () async {
      final host = await player('ohost');
      final me = host.auth.currentUser!.id;
      final venue = await host.from('venues').select('id').limit(1).single();
      final start = DateTime.now().toUtc().add(const Duration(days: 3));
      final row = {
        'kind': 'meet',
        'host_id': me,
        'title': 'Free Meet',
        'sports': ['badminton'],
        'game_type': 'doubles',
        'format': 'open_play',
        'starts_at': start.toIso8601String(),
        'ends_at': start.add(const Duration(hours: 2)).toIso8601String(),
        'venue_id': venue['id'],
        'capacity': 4,
      };
      await expectLater(
        host.from('activities').insert(row),
        throwsA(
          isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            'card_required',
          ),
        ),
      );

      final saved = await host.functions.invoke('save-card');
      await host.functions.invoke(
        'stripe-local',
        body: {
          'action': 'save_card',
          'customer': (saved.data as Map)['customer'],
          'user_id': me,
        },
      );
      final card = await host.rpc<Map<String, dynamic>?>('money_my_card');
      expect(card?['last4'], '4242');

      final created = await host
          .from('activities')
          .insert(row)
          .select('id')
          .single();
      final p = await player('ojoin');
      await p.rpc<String>('join_activity', params: {'activity': created['id']});
      await runWorker();
      final fees = await admin
          .from('payments')
          .select('status, amount_minor')
          .eq('activity_id', created['id'] as String)
          .eq('purpose', 'organizer_fee');
      expect(fees.single['status'], 'succeeded');
      expect(fees.single['amount_minor'], 200);
      await host.dispose();
      await p.dispose();
    },
    skip: skip,
  );
}
