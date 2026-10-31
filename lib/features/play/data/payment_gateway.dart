import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/meet_ops.dart' show newClientKey;
import 'play_repository.dart';

/// A way to pay, as listed on the payment sheet.
class PayMethod {
  const PayMethod({
    required this.id,
    required this.title,
    required this.detail,
  });
  final String id;
  final String title;
  final String detail;
}

/// What a spot costs, from the server, and the rule shown before paying.
class PayQuote {
  const PayQuote({
    required this.priceCents,
    required this.feeCents,
    required this.totalCents,
    required this.refundRule,
    required this.paymentsEnabled,
  });

  final int priceCents;
  final int feeCents;
  final int totalCents;
  final String refundRule;
  final bool paymentsEnabled;
}

/// A held spot and the payment behind it.
class PaymentHold {
  const PaymentHold({
    required this.result,
    this.id,
    this.totalCents = 0,
    this.holdUntil,
    this.serverNow,
    this.receiptNo = '',
    this.method,
  });

  /// reserved, waitlist, joined or requested.
  final String result;
  final String? id;
  final int totalCents;
  final DateTime? holdUntil;
  final DateTime? serverNow;
  final String receiptNo;

  /// Set once a payment has started, which fixes how it's paid.
  final String? method;
}

enum PaymentState { waiting, paid, refunded, ended }

class PaymentProgress {
  const PaymentProgress({
    required this.state,
    this.holdUntil,
    this.serverNow,
    this.failed = false,
    this.receiptNo = '',
  });

  final PaymentState state;
  final DateTime? holdUntil;
  final DateTime? serverNow;

  /// The last try failed. The hold stands, so they can try again.
  final bool failed;
  final String receiptNo;
}

/// Takes payment. The app starts a payment and waits: only the server, told by
/// Stripe's webhook, says it's done. Stripe's own sheet slots in behind
/// [begin] once test keys exist; until then a local stack uses a stand-in.
abstract interface class PaymentGateway {
  Future<List<PayMethod>> methods();

  /// What a spot costs. [qty] counts seats or tickets.
  Future<PayQuote> quote(String activityId, {int qty = 1});

  /// Holds a spot. The same [key] returns the same hold, so a double tap or a
  /// retry can't charge twice.
  Future<PaymentHold> reserve({
    required String activityId,
    required String key,
    int qty = 1,
    String? guestName,
    double? guestLevel,
  });

  /// Reserves the organizer fees owed.
  Future<PaymentHold> reserveFeesOwed(String key);

  Future<void> begin(String paymentId, PayMethod method);
  Future<PaymentProgress> progress(String paymentId);
  Future<void> abandon(String paymentId);

  /// Whether this build can actually take money. Stripe's own sheet isn't in
  /// the app yet, so only the stand-in and demo mode can.
  bool get canCollect;

  /// A local stand-in can finish a payment from the app.
  bool get canSimulate;
  Future<void> simulate(String paymentId);
}

class SupabasePaymentGateway implements PaymentGateway {
  SupabasePaymentGateway(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      throw AuthFailure(
        e.code == 'P0001' ? e.message : 'Something went wrong. Try again.',
      );
    } on FunctionException catch (e) {
      final detail = e.details;
      throw AuthFailure(
        detail is Map && detail['error'] is String
            ? detail['error'] as String
            : 'Something went wrong. Try again.',
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  static PaymentHold _hold(Map<String, dynamic> r) => PaymentHold(
    result: r['result'] as String? ?? 'reserved',
    id: r['payment_id'] as String?,
    totalCents: (r['amount_minor'] as num?)?.toInt() ?? 0,
    holdUntil: DateTime.tryParse(r['hold_until'] as String? ?? ''),
    serverNow: DateTime.tryParse(r['server_now'] as String? ?? ''),
    receiptNo: r['receipt_no'] as String? ?? '',
    method: r['method'] as String?,
  );

  @override
  Future<List<PayMethod>> methods() async => const [
    PayMethod(id: 'card', title: 'Card', detail: 'Visa, Mastercard and more'),
    PayMethod(id: 'paynow', title: 'PayNow', detail: 'Pay from your bank app'),
  ];

  @override
  Future<PayQuote> quote(String activityId, {int qty = 1}) => _guard(() async {
    final r = await _client.rpc<Map<String, dynamic>>(
      'activity_quote',
      params: {'p_activity': activityId, 'p_qty': qty},
    );
    return PayQuote(
      priceCents: (r['price_minor'] as num).toInt(),
      feeCents: (r['fee_minor'] as num).toInt(),
      totalCents: (r['total_minor'] as num).toInt(),
      refundRule: r['refund_rule'] as String,
      paymentsEnabled: r['payments_enabled'] as bool,
    );
  });

  @override
  Future<PaymentHold> reserve({
    required String activityId,
    required String key,
    int qty = 1,
    String? guestName,
    double? guestLevel,
  }) => _guard(() async {
    final r = await _client.rpc<Map<String, dynamic>>(
      'activity_reserve',
      params: {
        'p_activity': activityId,
        'p_key': key,
        'p_qty': qty,
        'p_guest': guestName,
        'p_guest_level': guestLevel,
      },
    );
    return _hold(r);
  });

  @override
  Future<PaymentHold> reserveFeesOwed(String key) => _guard(() async {
    final r = await _client.rpc<Map<String, dynamic>>(
      'organizer_debt_reserve',
      params: {'p_key': key},
    );
    return _hold(r);
  });

  @override
  Future<void> begin(String paymentId, PayMethod method) => _guard(() async {
    await _client.functions.invoke(
      'create-payment-intent',
      body: {'payment_id': paymentId, 'method': method.id},
    );
  });

  @override
  Future<PaymentProgress> progress(String paymentId) => _guard(() async {
    final r = await _client.rpc<Map<String, dynamic>>(
      'payment_status',
      params: {'p_payment': paymentId},
    );
    final status = r['status'] as String;
    final refunded = (r['refunded_minor'] as num) > 0;
    return PaymentProgress(
      state: switch (status) {
        'succeeded' when refunded => PaymentState.refunded,
        'succeeded' => PaymentState.paid,
        'pending' => PaymentState.waiting,
        // The hold ran out, but money can still land until Stripe stops it.
        'cancel_requested' => PaymentState.waiting,
        _ => PaymentState.ended,
      },
      holdUntil: DateTime.tryParse(r['hold_until'] as String? ?? ''),
      serverNow: DateTime.tryParse(r['server_now'] as String? ?? ''),
      failed: r['failure_code'] != null,
      receiptNo: r['receipt_no'] as String? ?? '',
    );
  });

  @override
  Future<void> abandon(String paymentId) => _guard(
    () =>
        _client.rpc<void>('payment_abandon', params: {'p_payment': paymentId}),
  );

  @override
  bool get canCollect => Env.localStandIn;

  @override
  bool get canSimulate => Env.localStandIn;

  @override
  Future<void> simulate(String paymentId) => _guard(() async {
    await _client.functions.invoke(
      'stripe-local',
      body: {'action': 'succeed', 'payment_id': paymentId},
    );
  });
}

/// Approves every payment and confirms the spot, using the design's sample card.
class DemoPaymentGateway implements PaymentGateway {
  DemoPaymentGateway(this._play);
  final DemoPlayRepository _play;
  final _holds = <String, (String, String?)>{};

  @override
  Future<List<PayMethod>> methods() async => const [
    PayMethod(id: 'card', title: 'Visa ending 4242', detail: 'Default card'),
    PayMethod(id: 'paynow', title: 'PayNow', detail: 'Pay from your bank app'),
  ];

  @override
  Future<PayQuote> quote(String activityId, {int qty = 1}) async {
    final a = await _play.activity(activityId);
    return PayQuote(
      priceCents: a.feeCents * qty,
      feeCents: a.platformCents * qty,
      totalCents: a.totalCents * qty,
      refundRule:
          'Give up your spot before it starts and you get the price back, '
          'without the fee. After that, no refund. If the organizer cancels, '
          'you get everything back.',
      paymentsEnabled: true,
    );
  }

  @override
  Future<PaymentHold> reserve({
    required String activityId,
    required String key,
    int qty = 1,
    String? guestName,
    double? guestLevel,
  }) async {
    final id = newClientKey();
    _holds[id] = (activityId, guestName);
    final now = DateTime.now();
    return PaymentHold(
      result: 'reserved',
      id: id,
      holdUntil: now.add(const Duration(minutes: 10)),
      serverNow: now,
    );
  }

  @override
  Future<PaymentHold> reserveFeesOwed(String key) async =>
      throw const AuthFailure('You don’t owe anything.');

  @override
  Future<void> begin(String paymentId, PayMethod method) async {}

  @override
  Future<PaymentProgress> progress(String paymentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_holds.remove(paymentId) case (final activityId, final guest)?) {
      _play.markPaid(activityId, guestName: guest);
    }
    return const PaymentProgress(
      state: PaymentState.paid,
      receiptNo: 'OG-DEMO-0047',
    );
  }

  @override
  Future<void> abandon(String paymentId) async => _holds.remove(paymentId);

  @override
  bool get canCollect => true;

  @override
  bool get canSimulate => false;

  @override
  Future<void> simulate(String paymentId) async {}
}
