import 'package:og_money/og_money.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/format.dart';
import '../../auth/data/auth_repository.dart';

/// Points earned by playing.
class PointsSummary {
  const PointsSummary({
    this.minor = 0,
    this.pendingMinor = 0,
    this.earning = true,
  });

  /// In cents: 1 point is 10 cents.
  final int minor;
  final int pendingMinor;

  /// Earning is switched on.
  final bool earning;

  /// With earning off and nothing to spend, there's nothing to show.
  bool get worthShowing => earning || minor > 0;
}

/// A way to use points: a product and how much points can take off.
class PointsUse {
  const PointsUse(this.name, this.shop, this.priceCents, this.capCents);
  final String name;
  final String shop;
  final int priceCents;
  final int capCents;
}

class PointsInfo {
  const PointsInfo({
    required this.minor,
    this.pendingMinor = 0,
    this.pendingNote = '',
    this.uses = const [],
    this.activity = const [],
    this.earning = true,
    this.canRedeem = true,
    this.nextExpiry,
  });

  /// In cents: 1 point is 10 cents.
  final int minor;
  final int pendingMinor;

  /// "from Doubles Social tonight. They land once Hannah marks you present."
  final String pendingNote;
  final List<PointsUse> uses;

  /// Title, line and cents of points (negative when spent).
  final List<(String, String, int)> activity;

  /// Earning is switched on.
  final bool earning;

  /// This account can spend points.
  final bool canRedeem;

  /// When the oldest points run out.
  final DateTime? nextExpiry;
}

/// A payment record, kept for the law's retention period.
class ReceiptRecord {
  const ReceiptRecord({
    required this.id,
    required this.title,
    required this.kind,
    required this.at,
    required this.no,
    required this.lines,
    required this.totalCents,
    required this.paidWith,
    this.refund,
  });

  final String id;
  final String title;

  /// Meet, Tournament, Event, Court, Academy, Shop.
  final String kind;
  final DateTime at;
  final String no;
  final List<(String, String)> lines;
  final int totalCents;
  final String paidWith;

  /// "Refunded S$8.00".
  final String? refund;
}

class EarningSource {
  const EarningSource(this.id, this.title, this.sub, this.cents);
  final String id;
  final String title;
  final String sub;
  final int cents;
}

class Earnings {
  const Earnings({
    this.readyCents = 0,
    this.heldCents = 0,
    this.monthCents = 0,
    this.yearCents = 0,
    this.owedCents = 0,
    this.feeDebtCents = 0,
    this.sources = const [],
  });

  final int readyCents;

  /// Fees and card costs bigger than earnings, taken from later payouts.
  final int owedCents;

  /// Organizer fees that couldn't be charged. Blocks organizer-pays Meets.
  final int feeDebtCents;

  /// Waiting for attendance to be marked.
  final int heldCents;
  final int monthCents;
  final int yearCents;
  final List<EarningSource> sources;
}

/// How one session's earnings add up.
class EarningsBreakdown {
  const EarningsBreakdown({
    required this.title,
    required this.sub,
    required this.earnedCents,
    required this.released,
    this.lines = const [],
    this.players = const [],
  });

  final String title;
  final String sub;
  final int earnedCents;

  /// "Released Fri 2 Oct, 10:12 PM, when you marked attendance".
  final String released;
  final List<(String, String)> lines;

  /// Name, how they paid and what came of it, and the amount.
  final List<(String, String, String)> players;
}

/// Stripe collects the bank details and runs the checks, so Olympus only
/// knows how far along they are.
class PayoutAccount {
  const PayoutAccount({this.status = 'none', this.auto = 'Every Monday'});

  /// none, pending, verified, rejected.
  final String status;

  /// Every Monday, Every month, Off.
  final String auto;

  bool get isSet => status == 'verified';

  String get label => switch (status) {
    'verified' => 'Checked, ready for payouts',
    'pending' => 'Waiting for your checks',
    'rejected' => 'Checks didn’t pass',
    _ => 'Not set up',
  };
}

abstract interface class EarningsRepository {
  Future<PointsSummary> summary();
  Future<PointsInfo> points();
  Future<List<ReceiptRecord>> receipts();
  Future<Earnings> earnings();
  Future<EarningsBreakdown> earningsDetail(String sourceId);
  Future<PayoutAccount> payoutAccount();

  /// Starts Stripe's checks. Returns the page to open, if there is one.
  Future<String?> startPayouts();
  Future<void> setPayoutSchedule(String auto);

  /// "Visa ending 4242", or null with no saved card.
  Future<String?> savedCard();

  /// Starts saving a card with Stripe.
  Future<void> saveCard();
}

String _scheduleOf(String? value) => switch (value) {
  'monthly' => 'Every month',
  'off' => 'Off',
  _ => 'Every Monday',
};

class SupabaseEarningsRepository implements EarningsRepository {
  SupabaseEarningsRepository(this._client);
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

  @override
  Future<PointsSummary> summary() => _guard(() async {
    final r = await _client.rpc<Map<String, dynamic>>('points_my');
    return PointsSummary(
      minor: (r['balance_minor'] as num).toInt(),
      earning: r['earning'] as bool? ?? false,
    );
  });

  @override
  Future<PointsInfo> points() => _guard(() async {
    final r = await _client.rpc<Map<String, dynamic>>('points_my');
    return PointsInfo(
      minor: (r['balance_minor'] as num).toInt(),
      earning: r['earning'] as bool? ?? false,
      canRedeem: r['can_redeem'] as bool? ?? false,
      nextExpiry: DateTime.tryParse(r['next_expiry'] as String? ?? '')
          ?.toLocal(),
      activity: [
        for (final h in (r['history'] as List).cast<Map>())
          (
            switch (h['kind']) {
              'earn' => 'Earned',
              'spend' => 'Used in the Shop',
              'return' => 'Points returned',
              'expire' => 'Expired',
              'reverse' => 'Taken back',
              _ => 'Points',
            },
            Fmt.day(DateTime.parse(h['at'] as String).toLocal()),
            (h['amount_minor'] as num).toInt(),
          ),
      ],
    );
  });

  @override
  Future<List<ReceiptRecord>> receipts() => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>('money_my_payments');
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        ReceiptRecord(
          id: r['payment_id'] as String,
          title: r['title'] as String? ?? 'Fees',
          kind: switch (r['purpose']) {
            'ticket' => 'Event',
            'tournament' => 'Tournament',
            'organizer_fee' || 'debt' => 'Fees',
            'shop' => 'Shop',
            _ => 'Meet',
          },
          at: DateTime.parse(r['created_at'] as String).toLocal(),
          no: r['receipt_no'] as String,
          lines: [
            if ((r['price_minor'] as num) > 0)
              ('Price', '${Money((r['price_minor'] as num).toInt())}'),
            if (r['purpose'] != 'shop')
              ('Platform fee', '${Money((r['fee_minor'] as num).toInt())}'),
          ],
          totalCents: (r['amount_minor'] as num).toInt(),
          paidWith: r['method'] == 'paynow' ? 'PayNow' : 'Card',
          refund: (r['refunded_minor'] as num) > 0
              ? 'Refunded ${Money((r['refunded_minor'] as num).toInt())}'
              : null,
        ),
    ];
  });

  Future<Map<String, dynamic>> _earnings() =>
      _client.rpc<Map<String, dynamic>>('money_my_earnings');

  @override
  Future<Earnings> earnings() => _guard(() async {
    final r = await _earnings();
    int cents(String key) => (r[key] as num).toInt();
    return Earnings(
      readyCents: cents('available_minor'),
      heldCents: cents('held_minor'),
      monthCents: cents('month_minor'),
      yearCents: cents('year_minor'),
      owedCents: cents('owed_minor'),
      feeDebtCents: cents('fee_debt_minor'),
      sources: [
        for (final a in (r['activities'] as List).cast<Map<String, dynamic>>())
          EarningSource(
            a['activity_id'] as String,
            a['title'] as String,
            a['released'] == true ? 'Released' : 'Held until attendance',
            (a['price_minor'] as num).toInt(),
          ),
      ],
    );
  });

  @override
  Future<EarningsBreakdown> earningsDetail(String sourceId) =>
      throw const AuthFailure("This breakdown isn't available yet.");

  @override
  Future<PayoutAccount> payoutAccount() => _guard(() async {
    final vendor = (await _earnings())['vendor'] as Map<String, dynamic>?;
    if (vendor == null) return const PayoutAccount();
    return PayoutAccount(
      status: vendor['status'] as String,
      auto: _scheduleOf(vendor['schedule'] as String?),
    );
  });

  @override
  Future<String?> startPayouts() => _guard(() async {
    final res = await _client.functions.invoke('vendor-onboard');
    final url = (res.data as Map?)?['onboarding_url'] as String?;
    if (url == null && Env.localStandIn) {
      await _client.functions.invoke(
        'stripe-local',
        body: {
          'action': 'vendor_verified',
          'owner_id': _client.auth.currentUser?.id,
        },
      );
    }
    return url;
  });

  @override
  Future<void> setPayoutSchedule(String auto) => _guard(
    () => _client.rpc<void>(
      'vendor_set_schedule',
      params: {
        'p_schedule': switch (auto) {
          'Every month' => 'monthly',
          'Off' => 'off',
          _ => 'weekly',
        },
      },
    ),
  );

  @override
  Future<String?> savedCard() => _guard(() async {
    final card = await _client.rpc<Map<String, dynamic>?>('money_my_card');
    if (card == null || card['last4'] == null) return null;
    final brand = (card['brand'] as String? ?? 'Card');
    return '${brand[0].toUpperCase()}${brand.substring(1)} ending ${card['last4']}';
  });

  @override
  Future<void> saveCard() => _guard(() async {
    final res = await _client.functions.invoke('save-card');
    if (!Env.localStandIn) {
      throw const AuthFailure("Saving a card isn't switched on yet.");
    }
    await _client.functions.invoke(
      'stripe-local',
      body: {
        'action': 'save_card',
        'customer': (res.data as Map)['customer'],
        'user_id': _client.auth.currentUser?.id,
      },
    );
  });
}

class DemoEarningsRepository implements EarningsRepository {
  int _points = 212;
  var _account = const PayoutAccount(status: 'verified');
  final _pointsLog = <(String, String, int)>[];
  final _receipts = <ReceiptRecord>[];

  DemoEarningsRepository() {
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));
    _pointsLog.addAll([
      ('Doubles Social', 'Present · ${_day(ago(3))}', 400),
      ('Overgrip, pack of 3', 'Used at Court Supply Co.', -45),
      ('Tampines Open, Finals Day', '2 tickets scanned', 800),
      ('Morning Singles', 'Present', 400),
    ]);
    _receipts.addAll([
      ReceiptRecord(
        id: 'r1',
        title: 'Doubles Social',
        kind: 'Meet',
        at: ago(0),
        no: 'OG-20261002-0047',
        lines: const [('Session', 'S\$6.00'), ('Platform fee', 'S\$2.00')],
        totalCents: 800,
        paidWith: 'PayNow',
      ),
      ReceiptRecord(
        id: 'r2',
        title: 'Tampines Open 2026',
        kind: 'Tournament',
        at: ago(5),
        no: 'OG-20260927-0031',
        lines: const [
          ('Mixed doubles, per pair', 'S\$30.00'),
          ('Platform fee', 'S\$3.00'),
        ],
        totalCents: 3300,
        paidWith: 'Card ending 4242',
      ),
      ReceiptRecord(
        id: 'r3',
        title: 'Tampines Open, Finals Day',
        kind: 'Event',
        at: ago(7),
        no: 'OG-20260925-0012',
        lines: const [('2 tickets', 'S\$20.00'), ('Platform fee', 'S\$4.00')],
        totalCents: 2400,
        paidWith: 'Card ending 4242',
      ),
      ReceiptRecord(
        id: 'r4',
        title: 'Morning Singles',
        kind: 'Meet',
        at: ago(9),
        no: 'OG-20260923-0008',
        lines: const [('Session', 'S\$6.00'), ('Platform fee', 'S\$2.00')],
        totalCents: 800,
        paidWith: 'Card ending 4242',
        refund: 'Refunded S\$8.00 to your card, Hannah cancelled',
      ),
      ReceiptRecord(
        id: 'r5',
        title: 'Overgrip, pack of 3',
        kind: 'Shop',
        at: ago(8),
        no: 'OG-20260924-0019',
        lines: const [('Items', 'S\$9.00'), ('Points used', '−S\$3.00')],
        totalCents: 600,
        paidWith: 'PayNow',
      ),
    ]);
  }

  static String _day(DateTime d) =>
      '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} ${d.day} '
      '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  /// The demo balance, in cents of points.
  int get balance => _points;

  /// Used by the demo shop: spend points.
  void spend(String title, String sub, {int minor = 0}) {
    _points -= minor;
    if (minor > 0) _pointsLog.insert(0, (title, 'Used at $sub', -minor));
  }

  /// Used by the demo shop: points back.
  void credit(String title, String sub, {int minor = 0}) {
    _points += minor;
    if (minor > 0) _pointsLog.insert(0, (title, 'Points returned', minor));
  }

  void addReceipt(ReceiptRecord r) => _receipts.insert(0, r);

  @override
  Future<PointsSummary> summary() async =>
      PointsSummary(minor: _points, pendingMinor: 400);

  @override
  Future<PointsInfo> points() async {
    await _tick();
    return PointsInfo(
      minor: _points,
      pendingMinor: 400,
      pendingNote:
          'from Doubles Social tonight. They land once Hannah marks you '
          'present.',
      uses: const [
        PointsUse('Carbon racket 4U', 'Racket Lab', 18900, 945),
        PointsUse(
          'Feather shuttles, tube of 12',
          'Court Supply Co.',
          2450,
          122,
        ),
        PointsUse('Court shoe, all-court grip', 'Footwork', 15900, 795),
      ],
      activity: List.of(_pointsLog),
    );
  }

  @override
  Future<List<ReceiptRecord>> receipts() async {
    await _tick();
    return List.of(_receipts);
  }

  @override
  Future<Earnings> earnings() async {
    await _tick();
    return Earnings(
      readyCents: 31200,
      heldCents: 9600,
      monthCents: 128400,
      yearCents: 794000,
      sources: const [
        EarningSource(
          'ts-social',
          'Doubles Social, 8 Meets',
          'Meet · 86 paid spots at S\$6.00',
          51600,
        ),
        EarningSource(
          't-open',
          'Tampines Open 2026',
          'Tournament · 66 entries',
          162000,
        ),
        EarningSource(
          'reward',
          'Tampines Smashers',
          'Club reward voucher',
          2000,
        ),
        EarningSource(
          'ts-singles',
          'Morning Singles, you cancelled',
          'Card fees on 5 refunds',
          -385,
        ),
        EarningSource(
          'e-festival',
          'East Side Sports Festival',
          'Event · 148 free tickets, you pay the fee',
          -29600,
        ),
      ],
    );
  }

  @override
  Future<EarningsBreakdown> earningsDetail(String sourceId) async {
    await _tick();
    return const EarningsBreakdown(
      title: 'Doubles Social',
      sub: 'Meet · Fri 2 Oct',
      earnedCents: 4800,
      released: 'Released Fri 2 Oct, 10:12 PM, when you marked attendance',
      lines: [
        ('Paid players present', '8 × S\$6.00 = S\$48.00'),
        ('Walk-in, cash to you', '1 × S\$6.00, not through Olympus'),
        ('Refunded, left before start', '1 × S\$6.00'),
        ('Platform fee, paid by players', '8 × S\$2.00, not yours'),
        ('Your own spot', 'S\$2.00 platform fee, paid by you'),
      ],
      players: [
        ('Aaron Ng', 'Paid by card · Present', 'S\$6.00'),
        ('Priya Raman', 'Paid by PayNow · Present', 'S\$6.00'),
        ('Daniel Tan', 'Paid by card · Absent, no refund', 'S\$6.00'),
        ('Mei Ling', 'Left before start, refunded', 'Refunded'),
      ],
    );
  }

  @override
  Future<PayoutAccount> payoutAccount() async => _account;

  @override
  Future<String?> startPayouts() async {
    await _tick();
    _account = const PayoutAccount(status: 'verified');
    return null;
  }

  @override
  Future<void> setPayoutSchedule(String auto) async {
    await _tick();
    _account = PayoutAccount(status: _account.status, auto: auto);
  }

  @override
  Future<String?> savedCard() async => 'Visa ending 4242';

  @override
  Future<void> saveCard() => _tick();
}
