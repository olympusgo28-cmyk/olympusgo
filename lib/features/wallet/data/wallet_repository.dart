import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';

/// Wallet money (refunds land here) and points earned by playing.
class WalletSummary {
  const WalletSummary({
    this.balanceCents = 0,
    this.points = 0,
    this.pendingPoints = 0,
  });

  final int balanceCents;
  final double points;
  final double pendingPoints;
}

/// A line in the Wallet's Recent list.
class WalletEntry {
  const WalletEntry(this.title, this.sub, this.cents, this.at);
  final String title;

  /// "Meet", "Hannah cancelled, fee included".
  final String sub;

  /// Money in is positive.
  final int cents;
  final DateTime at;
}

/// A way to use points: a product and how many points it takes.
class PointsUse {
  const PointsUse(this.name, this.shop, this.priceCents, this.cap);
  final String name;
  final String shop;
  final int priceCents;
  final int cap;
}

class PointsInfo {
  const PointsInfo({
    required this.points,
    this.pending = 0,
    this.pendingNote = '',
    this.uses = const [],
    this.activity = const [],
  });

  final double points;
  final double pending;

  /// "from Doubles Social tonight. They land once Hannah marks you present."
  final String pendingNote;
  final List<PointsUse> uses;

  /// Title, line and points (negative when spent).
  final List<(String, String, double)> activity;
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

  /// "Refunded S$8.00 to Wallet".
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
    this.sources = const [],
  });

  final int readyCents;

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

class PayoutAccount {
  const PayoutAccount({
    this.holder = '',
    this.bank = '',
    this.number = '',
    this.payNow = '',
    this.auto = 'Every Monday',
  });

  final String holder;
  final String bank;
  final String number;
  final String payNow;

  /// Every Monday, Every month, Off.
  final String auto;

  bool get isSet =>
      holder.isNotEmpty && (number.isNotEmpty || payNow.isNotEmpty);

  /// "[Bank] ending 1234".
  String get label => number.length >= 4
      ? '$bank ending ${number.substring(number.length - 4)}'
      : (payNow.isNotEmpty ? 'PayNow $payNow' : 'Not set');
}

abstract interface class WalletRepository {
  Future<WalletSummary> summary();
  Future<List<WalletEntry>> activity();

  /// Sends [cents] to the bank. Returns the new balance.
  Future<int> withdraw(int cents);
  Future<PointsInfo> points();
  Future<List<ReceiptRecord>> receipts();
  Future<Earnings> earnings();
  Future<EarningsBreakdown> earningsDetail(String sourceId);
  Future<void> payout(int cents);
  Future<PayoutAccount> payoutAccount();
  Future<void> savePayoutAccount(PayoutAccount account);
}

const _soon = AuthFailure(
  "Payouts and withdrawals aren't switched on yet. They open once payments "
  'are connected.',
);

class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<WalletSummary> summary() async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return const WalletSummary();
    // Refunds from leave_activity and court cancellations are the only
    // wallet credits so far; the Wallet phase adds a ledger with top-ups and
    // withdrawals.
    final rows = await _client
        .from('payments')
        .select('amount_cents')
        .eq('user_id', me)
        .eq('status', 'refunded');
    final courts = await _client
        .from('court_bookings')
        .select('refund_cents')
        .eq('user_id', me)
        .eq('refund_to', 'wallet');
    final balance = [
      for (final r in rows) r['amount_cents'] as int,
      for (final r in courts) r['refund_cents'] as int,
    ].fold(0, (a, b) => a + b);
    return WalletSummary(balanceCents: balance);
  }

  @override
  Future<List<WalletEntry>> activity() async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return const [];
    final rows = await _client
        .from('payments')
        .select('amount_cents, status, created_at, activities(title, kind)')
        .eq('user_id', me)
        .order('created_at', ascending: false)
        .limit(30);
    return [
      for (final r in rows)
        WalletEntry(
          r['status'] == 'refunded'
              ? 'Refund, ${(r['activities'] as Map?)?['title'] ?? 'payment'}'
              : ((r['activities'] as Map?)?['title'] as String? ?? 'Payment'),
          r['status'] == 'refunded' ? 'Back to your Wallet' : 'Paid by card',
          r['status'] == 'refunded'
              ? r['amount_cents'] as int
              : -(r['amount_cents'] as int),
          DateTime.parse(r['created_at'] as String).toLocal(),
        ),
    ];
  }

  @override
  Future<int> withdraw(int cents) => throw _soon;

  @override
  Future<PointsInfo> points() async => const PointsInfo(points: 0);

  @override
  Future<List<ReceiptRecord>> receipts() async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return const [];
    final rows = await _client
        .from('payments')
        .select(
          'id, amount_cents, platform_fee_cents, method, status, created_at, '
          'activities(title, kind)',
        )
        .eq('user_id', me)
        .order('created_at', ascending: false);
    return [
      for (final r in rows)
        ReceiptRecord(
          id: r['id'] as String,
          title: (r['activities'] as Map?)?['title'] as String? ?? 'Payment',
          kind: switch ((r['activities'] as Map?)?['kind']) {
            'tournament' => 'Tournament',
            'event' => 'Event',
            _ => 'Meet',
          },
          at: DateTime.parse(r['created_at'] as String).toLocal(),
          no: (r['id'] as String).substring(0, 8).toUpperCase(),
          lines: [
            (
              'Price',
              'S\$${((r['amount_cents'] as int) - (r['platform_fee_cents'] as int)) / 100}',
            ),
            ('Platform fee', 'S\$${(r['platform_fee_cents'] as int) / 100}'),
          ],
          totalCents: r['amount_cents'] as int,
          paidWith: r['method'] == 'wallet' ? 'Wallet' : 'Card',
          refund: r['status'] == 'refunded' ? 'Refunded' : null,
        ),
    ];
  }

  @override
  Future<Earnings> earnings() async => const Earnings();

  @override
  Future<EarningsBreakdown> earningsDetail(String sourceId) => throw _soon;

  @override
  Future<void> payout(int cents) => throw _soon;

  @override
  Future<PayoutAccount> payoutAccount() async => const PayoutAccount();

  @override
  Future<void> savePayoutAccount(PayoutAccount account) => throw _soon;
}

class DemoWalletRepository implements WalletRepository {
  int _balance = 2400;
  double _points = 21.2;
  int _ready = 31200;
  var _account = const PayoutAccount(
    holder: 'Aaron Ng',
    bank: 'DBS',
    number: '0123456789',
    auto: 'Every Monday',
  );
  final _entries = <WalletEntry>[];
  final _pointsLog = <(String, String, double)>[];
  final _receipts = <ReceiptRecord>[];

  DemoWalletRepository() {
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));
    _entries.addAll([
      WalletEntry('Doubles Social', 'Meet', -800, ago(0)),
      WalletEntry('Withdrawn to bank', 'DBS ending 6789', -3000, ago(4)),
      WalletEntry(
        'Refund, Morning Singles',
        'Hannah cancelled, fee included',
        800,
        ago(6),
      ),
      WalletEntry('Overgrip, pack of 3', 'Court Supply Co.', -600, ago(8)),
    ]);
    _pointsLog.addAll([
      ('Doubles Social', 'Present · ${_day(ago(3))}', 4),
      ('Overgrip, pack of 3', 'Used at Court Supply Co.', -3),
      ('Tampines Open, Finals Day', '2 tickets scanned', 8),
      ('Morning Singles', 'Present', 4),
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
        paidWith: 'Wallet',
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
        refund: 'Refunded S\$8.00 to Wallet, Hannah cancelled',
      ),
      ReceiptRecord(
        id: 'r5',
        title: 'Overgrip, pack of 3',
        kind: 'Shop',
        at: ago(8),
        no: 'OG-20260924-0019',
        lines: const [('Items', 'S\$9.00'), ('Points used', '−S\$3.00')],
        totalCents: 600,
        paidWith: 'Wallet',
      ),
    ]);
  }

  static String _day(DateTime d) =>
      '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} ${d.day} '
      '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  /// Used by the demo shop: spend from the Wallet or points.
  void spend(String title, String sub, {int cents = 0, double points = 0}) {
    _balance -= cents;
    _points -= points;
    if (cents > 0) {
      _entries.insert(0, WalletEntry(title, sub, -cents, DateTime.now()));
    }
    if (points > 0) _pointsLog.insert(0, (title, 'Used at $sub', -points));
  }

  /// Used by the demo shop: refunds and points back.
  void credit(String title, String sub, {int cents = 0, double points = 0}) {
    _balance += cents;
    _points += points;
    if (cents > 0) {
      _entries.insert(0, WalletEntry(title, sub, cents, DateTime.now()));
    }
    if (points > 0) _pointsLog.insert(0, (title, 'Points returned', points));
  }

  void addReceipt(ReceiptRecord r) => _receipts.insert(0, r);

  @override
  Future<WalletSummary> summary() async =>
      WalletSummary(balanceCents: _balance, points: _points, pendingPoints: 4);

  @override
  Future<List<WalletEntry>> activity() async {
    await _tick();
    return List.of(_entries);
  }

  @override
  Future<int> withdraw(int cents) async {
    await _tick();
    if (cents <= 0 || cents > _balance) {
      throw const AuthFailure('That is more than your balance.');
    }
    _balance -= cents;
    _entries.insert(
      0,
      WalletEntry('Withdrawn to bank', _account.label, -cents, DateTime.now()),
    );
    return _balance;
  }

  @override
  Future<PointsInfo> points() async {
    await _tick();
    return PointsInfo(
      points: _points,
      pending: 4,
      pendingNote:
          'from Doubles Social tonight. They land once Hannah marks you '
          'present.',
      uses: const [
        PointsUse('Carbon racket 4U', 'Racket Lab', 18900, 18),
        PointsUse('Feather shuttles, tube of 12', 'Court Supply Co.', 2450, 3),
        PointsUse('Court shoe, all-court grip', 'Footwork', 15900, 15),
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
      readyCents: _ready,
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
        ('Priya Raman', 'Paid by Wallet · Present', 'S\$6.00'),
        ('Daniel Tan', 'Paid by card · Absent, no refund', 'S\$6.00'),
        ('Mei Ling', 'Left before start, refunded to her Wallet', 'Refunded'),
      ],
    );
  }

  @override
  Future<void> payout(int cents) async {
    await _tick();
    if (cents <= 0 || cents > _ready) {
      throw const AuthFailure('That is more than is ready to pay out.');
    }
    _ready -= cents;
  }

  @override
  Future<PayoutAccount> payoutAccount() async => _account;

  @override
  Future<void> savePayoutAccount(PayoutAccount account) async {
    await _tick();
    _account = account;
  }
}
