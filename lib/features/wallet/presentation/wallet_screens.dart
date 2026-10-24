import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/domain/activity.dart' show money;
import '../application/wallet_providers.dart';
import '../data/wallet_repository.dart';

/// "S$24.00", "−S$8.00", "+S$8.00".
String cash(int cents, {bool sign = false}) {
  final s = 'S\$${money(cents.abs())}';
  if (!sign) return cents < 0 ? '−$s' : s;
  return cents < 0 ? '−$s' : '+$s';
}

/// "S$1,284".
String cashShort(int cents) =>
    'S\$${(cents ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

/// A big number on a dark card, with a line under it.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.note,
    this.action,
  });

  final String label;
  final String value;
  final String note;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OgColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: OgText.body(
              12,
              weight: FontWeight.w800,
              color: t.gold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: OgText.heading(44, color: const Color(0xFFFFFFFF)),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: OgText.body(14, height: 1.4, color: const Color(0xFFC9C6BC)),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

/// A row with a title, a line and an amount.
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.title,
    required this.sub,
    required this.amount,
    this.good = false,
    this.onTap,
  });

  final String title;
  final String sub;
  final String amount;
  final bool good;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: '$title, $sub, $amount',
      onPressed: onTap,
      dimWhenDisabled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OgText.body(15, weight: FontWeight.w700)),
                  Text(sub, style: OgText.body(13, color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              amount,
              style: OgText.body(
                15,
                weight: FontWeight.w800,
                color: good ? context.tones.successInk : c.text,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              OgIcon(OgIcons.chevronRight, size: 16, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wallet: balance, points, recent movements and the refund rules.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final s = ref.watch(walletSummaryProvider).value;
    final recent = ref.watch(walletActivityProvider).value;
    return KitScaffold(
      header: KitHeader(
        title: 'Wallet',
        trailing: KitLink(
          'Receipts',
          onPressed: () => context.push(Routes.receipts),
        ),
      ),
      children: [
        _BalanceCard(
          label: 'Balance',
          value: s == null ? '…' : cash(s.balanceCents),
          note:
              'Refunds and rewards land here. Spend it on Olympus or withdraw '
              'it to your bank.',
          action: KitButton(
            label: 'Withdraw to my bank',
            style: KitButtonStyle.gold,
            onPressed: s == null || s.balanceCents <= 0
                ? null
                : () => context.push(Routes.walletWithdraw),
          ),
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.pointsStar,
              title: '${s?.points.toStringAsFixed(1) ?? '…'} points',
              subtitle: 'Worth S\$1 off each at partner shops',
              onTap: () => context.push(Routes.points),
            ),
            KitNavTile(
              icon: OgIcons.walletCard,
              title: 'Earnings and payouts',
              subtitle: 'What your Meets, tournaments and events made',
              onTap: () => context.push(Routes.earnings),
            ),
          ],
        ),
        Text('Recent', style: OgText.heading(20)),
        if (recent == null)
          const CupertinoActivityIndicator()
        else if (recent.isEmpty)
          Text('Nothing yet.', style: OgText.body(14, color: c.textMuted))
        else
          KitCard(
            children: [
              for (final e in recent)
                MoneyRow(
                  title: e.title,
                  sub: '${e.sub} · ${Fmt.day(e.at)}',
                  amount: cash(e.cents, sign: true),
                  good: e.cents > 0,
                ),
            ],
          ),
        const KitNote(
          'When you cancel in time, you choose: all of it back here, '
          'instantly, or the price without the platform fee back to your '
          'card. If the organizer cancels, you get all of it back either way. '
          'You can’t add money to the wallet yourself yet.',
        ),
      ],
    );
  }
}

/// Picks an amount out of [max]: all of it, or two rounder amounts.
List<int> _amounts(int max) => [
  max,
  for (final x in const [20000, 10000, 5000, 2000, 1000])
    if (x < max) x,
].take(3).toList();

/// Send Wallet money to the bank.
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  int? _amount;
  bool _busy = false;
  int? _done;

  Future<void> _go(int cents) async {
    setState(() => _busy = true);
    try {
      await ref.read(walletRepositoryProvider).withdraw(cents);
      HapticFeedback.mediumImpact();
      refreshWallet(ref.invalidate);
      if (mounted) setState(() => _done = cents);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final s = ref.watch(walletSummaryProvider).value;
    final account = ref.watch(payoutAccountProvider).value;
    if (_done case final sent?) {
      return KitScaffold(
        header: const KitHeader(title: 'Withdraw'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(label: 'Back to Wallet', onPressed: () => context.pop()),
        ],
        children: [
          const KitDoneBanner(title: 'On its way'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${cash(sent)} to ${account?.label ?? 'your bank'}. Your wallet '
              'balance is updated now. You get a message when the money lands.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    if (s == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Withdraw'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final options = _amounts(s.balanceCents);
    final amount = _amount ?? options.first;
    return KitScaffold(
      header: const KitHeader(title: 'Withdraw'),
      bottom: [
        KitButton(
          label: 'Withdraw ${cash(amount)}',
          loading: _busy,
          onPressed: account?.isSet == true ? () => _go(amount) : null,
        ),
      ],
      children: [
        KitTitle(
          'Withdraw to your bank',
          lead: '${cash(s.balanceCents)} is in your wallet.',
        ),
        Column(
          children: [
            for (final (i, a) in options.indexed)
              KitChoiceRow(
                title: i == 0 ? 'All, ${cash(a)}' : cash(a),
                selected: amount == a,
                onTap: () => setState(() => _amount = a),
              ),
          ],
        ),
        Text('Send to', style: OgText.heading(20)),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.walletCard,
              title: account?.isSet == true
                  ? 'Bank account'
                  : 'Add a bank account',
              subtitle: account?.label ?? '…',
              onTap: () => context.push(Routes.payoutAccount),
            ),
          ],
        ),
        const KitKeyValue('Arrives', '1 to 2 working days'),
        const KitKeyValue('Fee', 'Free'),
        Text(
          'Points can’t be withdrawn. They stay in your points wallet.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Points: what they are worth, what is pending, how to use them.
class PointsWalletScreen extends ConsumerWidget {
  const PointsWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final p = ref.watch(pointsInfoProvider).value;
    if (p == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Points'),
        children: [CupertinoActivityIndicator()],
      );
    }
    const how = [
      (
        'Play',
        'Earn 4 points each time you are marked Present at a paid Meet.',
      ),
      ('Watch', 'Earn 4 points per ticket scanned at an event.'),
      (
        'Spend',
        '1 point takes S\$1 off at partner shops. Each item has a limit.',
      ),
    ];
    return KitScaffold(
      header: const KitHeader(title: 'Points'),
      children: [
        _BalanceCard(
          label: 'Your points',
          value: p.points.toStringAsFixed(1),
          note: 'Worth S\$${p.points.toStringAsFixed(2)} off at partner shops',
        ),
        if (p.pending > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.tag,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${p.pending.toStringAsFixed(0)} points pending ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: p.pendingNote),
                ],
              ),
              style: OgText.body(14, height: 1.4),
            ),
          ),
        Text('How points work', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final (i, (title, text)) in how.indexed)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: OgText.body(
                          13,
                          weight: FontWeight.w800,
                          color: c.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            text,
                            style: OgText.body(
                              13,
                              height: 1.4,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('Use points', style: OgText.heading(20))),
            KitLink(
              'Open the shop',
              onPressed: () => context.push(Routes.shop),
            ),
          ],
        ),
        KitCard(
          children: [
            for (final u in p.uses)
              MoneyRow(
                title: u.name,
                sub: '${u.shop} · ${cash(u.priceCents)} · up to ${u.cap} pts',
                amount:
                    'You pay ${cash(u.priceCents - (u.cap.clamp(0, p.points.floor())) * 100)}',
                onTap: () => context.push(Routes.shop),
              ),
          ],
        ),
        Text(
          '1 point takes S\$1 off. Each item has its own limit. Points left '
          'over stay in your wallet.',
          style: OgText.body(13, color: c.textMuted),
        ),
        Text('Activity', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final (title, sub, amt) in p.activity)
              MoneyRow(
                title: title,
                sub: sub,
                amount:
                    '${amt > 0 ? '+' : '−'}${amt.abs().toStringAsFixed(amt % 1 == 0 ? 0 : 1)} pts',
                good: amt > 0,
              ),
          ],
        ),
      ],
    );
  }
}

/// Every payment, by kind, with the full receipt.
class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  String _kind = 'All';

  void _open(ReceiptRecord r) => showKitSheet<void>(
    context,
    builder: (sheet) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RECEIPT',
            style: OgText.body(
              12,
              weight: FontWeight.w800,
              color: sheet.og.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          Text(r.title, style: OgText.heading(24)),
          Text(
            '${r.kind} · ${Fmt.day(r.at)} · ${r.no}',
            style: OgText.body(14, color: sheet.og.textMuted),
          ),
          const SizedBox(height: 12),
          for (final (k, v) in r.lines) KitKeyValue(k, v),
          KitKeyValue('Total', cash(r.totalCents)),
          KitKeyValue('Paid with', r.paidWith),
          if (r.refund != null) ...[
            const SizedBox(height: 8),
            KitNote(r.refund!, tone: KitTone.info),
          ],
          const SizedBox(height: 16),
          KitButton(
            label: 'Email me a copy',
            style: KitButtonStyle.outline,
            onPressed: () {
              Navigator.of(sheet).pop();
              showOgToast(context, 'Sent to your email');
            },
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final all = ref.watch(receiptsProvider).value;
    final kinds = [
      'All',
      ...{for (final r in all ?? const <ReceiptRecord>[]) r.kind},
    ];
    final shown = (all ?? const <ReceiptRecord>[])
        .where((r) => _kind == 'All' || r.kind == _kind)
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Receipts'),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final k in kinds) ...[
                KitChip(
                  label: k,
                  selected: _kind == k,
                  onTap: () => setState(() => _kind = k),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (all == null)
          const CupertinoActivityIndicator()
        else if (shown.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No receipts here yet. Try another filter.',
                style: OgText.body(14, color: c.textMuted),
              ),
            ),
          )
        else ...[
          Text(
            '${shown.length} ${shown.length == 1 ? 'receipt' : 'receipts'}',
            style: OgText.body(13, color: c.textMuted),
          ),
          KitCard(
            children: [
              for (final r in shown)
                MoneyRow(
                  title: r.title,
                  sub: ['${r.kind} · ${Fmt.day(r.at)}', ?r.refund].join(' · '),
                  amount: cash(r.totalCents),
                  onTap: () => _open(r),
                ),
            ],
          ),
        ],
        Text(
          'Receipts stay here for 5 years, also after an account is deleted, '
          'because payment records must be kept by law.',
          style: OgText.body(13, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }
}

/// What the player's sessions earned, and where it came from.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final e = ref.watch(earningsProvider).value;
    final account = ref.watch(payoutAccountProvider).value;
    if (e == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Earnings'),
        children: [CupertinoActivityIndicator()],
      );
    }
    Widget tile(String big, String small) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: t.tag,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            FittedBox(child: Text(big, style: OgText.heading(20))),
            Text(
              small,
              textAlign: TextAlign.center,
              style: OgText.body(12, color: t.onTag),
            ),
          ],
        ),
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Earnings'),
      children: [
        _BalanceCard(
          label: 'Ready to pay out',
          value: cash(e.readyCents),
          note: 'Paid to your bank every Monday, or take it out now.',
          action: KitButton(
            label: 'Pay out now',
            style: KitButtonStyle.gold,
            onPressed: e.readyCents > 0
                ? () => context.push(Routes.payout)
                : null,
          ),
        ),
        Row(
          children: [
            tile(cash(e.heldCents), 'held until attendance'),
            const SizedBox(width: 8),
            tile(cashShort(e.monthCents), 'this month'),
            const SizedBox(width: 8),
            tile(cashShort(e.yearCents), 'this year'),
          ],
        ),
        Text('Where it came from', style: OgText.heading(20)),
        if (e.sources.isEmpty)
          Text(
            'Nothing yet. Paid Meets, tournaments and events you run show here.',
            style: OgText.body(14, color: c.textMuted),
          )
        else
          KitCard(
            children: [
              for (final s in e.sources)
                MoneyRow(
                  title: s.title,
                  sub: s.sub,
                  amount: cash(s.cents),
                  good: s.cents > 0,
                  onTap: s.id == 'ts-social'
                      ? () => context.push(Routes.earningsDetail(s.id))
                      : null,
                ),
            ],
          ),
        const KitNote(
          'You keep the full price you set. The platform fee is added on top '
          'and paid by the player. Olympus holds each payment until you mark '
          'attendance, or 24 hours after the end if you don’t. If you cancel, '
          'players get everything back and the card fees come off your '
          'earnings.',
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.walletCard,
              title: 'Bank account',
              subtitle: account?.label ?? '…',
              onTap: () => context.push(Routes.payoutAccount),
            ),
          ],
        ),
      ],
    );
  }
}

/// How one session's earnings add up.
class EarningsDetailScreen extends ConsumerWidget {
  const EarningsDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final d = ref.watch(earningsDetailProvider(id));
    return switch (d) {
      AsyncData(:final value) => KitScaffold(
        header: KitHeader(title: value.title),
        children: [
          KitTitle(
            '${cash(value.earnedCents)} earned',
            lead: '${value.sub}\n${value.released}',
          ),
          Text('How it adds up', style: OgText.heading(20)),
          Column(
            children: [for (final (k, v) in value.lines) KitKeyValue(k, v)],
          ),
          KitKeyValue('You receive', cash(value.earnedCents)),
          Text('Players', style: OgText.heading(20)),
          KitCard(
            children: [
              for (final (name, sub, amt) in value.players)
                MoneyRow(title: name, sub: sub, amount: amt),
            ],
          ),
          Text(
            'Absent players are not refunded, so you still receive their spot. '
            'A player who left in time costs you nothing: their refund comes '
            'from the money Olympus was holding.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      ),
      AsyncError(:final error) => KitScaffold(
        header: const KitHeader(title: 'Earnings'),
        children: [
          KitNote(
            error is AuthFailure ? error.message : 'Couldn’t load this.',
            tone: KitTone.warn,
          ),
        ],
      ),
      _ => const KitScaffold(
        header: KitHeader(title: 'Earnings'),
        children: [CupertinoActivityIndicator()],
      ),
    };
  }
}

/// Take earnings out now.
class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  int? _amount;
  bool _instant = false;
  bool _busy = false;
  int? _done;

  Future<void> _go(int cents) async {
    setState(() => _busy = true);
    try {
      await ref.read(walletRepositoryProvider).payout(cents);
      HapticFeedback.mediumImpact();
      refreshWallet(ref.invalidate);
      if (mounted) setState(() => _done = cents);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final e = ref.watch(earningsProvider).value;
    final account = ref.watch(payoutAccountProvider).value;
    if (_done case final sent?) {
      return KitScaffold(
        header: const KitHeader(title: 'Pay out'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(label: 'Back to earnings', onPressed: () => context.pop()),
        ],
        children: [
          const KitDoneBanner(title: 'On its way'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${cash(sent)} to ${_instant ? 'PayNow' : account?.label ?? 'your bank'}. You get a message when it lands. It also shows under Earnings.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    if (e == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Pay out'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final options = _amounts(e.readyCents);
    final amount = _amount ?? options.first;
    return KitScaffold(
      header: const KitHeader(title: 'Pay out'),
      bottom: [
        KitButton(
          label: 'Pay out ${cash(amount)}',
          loading: _busy,
          onPressed: account?.isSet == true ? () => _go(amount) : null,
        ),
      ],
      children: [
        KitTitle(
          'Take out your earnings',
          lead: '${cash(e.readyCents)} is ready.',
        ),
        Column(
          children: [
            for (final (i, a) in options.indexed)
              KitChoiceRow(
                title: i == 0 ? 'All, ${cash(a)}' : cash(a),
                selected: amount == a,
                onTap: () => setState(() => _amount = a),
              ),
          ],
        ),
        Text('Send to', style: OgText.heading(20)),
        KitChoiceRow(
          title: 'Bank account',
          subtitle: account?.label ?? '…',
          tag: 'Free',
          selected: !_instant,
          onTap: () => setState(() => _instant = false),
        ),
        KitChoiceRow(
          title: 'PayNow, instant',
          subtitle: account?.payNow.isNotEmpty == true
              ? account!.payNow
              : 'Add PayNow in your payout account',
          tag: 'S\$0.50',
          selected: _instant,
          onTap: () => setState(() => _instant = true),
        ),
        KitKeyValue(
          'Arrives',
          _instant ? 'Within minutes' : '1 to 2 working days',
        ),
        KitKeyValue('Fee', _instant ? 'S\$0.50' : 'Free'),
      ],
    );
  }
}

/// Where Olympus pays you. Opens with Face ID.
class PayoutAccountScreen extends ConsumerStatefulWidget {
  const PayoutAccountScreen({super.key});

  @override
  ConsumerState<PayoutAccountScreen> createState() =>
      _PayoutAccountScreenState();
}

class _PayoutAccountScreenState extends ConsumerState<PayoutAccountScreen> {
  bool? _unlocked;
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _payNow = TextEditingController();
  String _auto = 'Every Monday';
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    // Demo mode skips the device check, so a simulator never asks for its
    // passcode.
    final ok =
        !Env.hasSupabase ||
        await ref
            .read(biometricVaultProvider)
            .authenticate('Open your payout account');
    if (mounted) setState(() => _unlocked = ok);
  }

  @override
  void dispose() {
    _holder.dispose();
    _bank.dispose();
    _number.dispose();
    _payNow.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(walletRepositoryProvider)
          .savePayoutAccount(
            PayoutAccount(
              holder: _holder.text.trim(),
              bank: _bank.text.trim(),
              number: _number.text.replaceAll(' ', ''),
              payNow: _payNow.text.trim(),
              auto: _auto,
            ),
          );
      HapticFeedback.mediumImpact();
      refreshWallet(ref.invalidate);
      if (!mounted) return;
      showOgToast(context, 'Saved. It applies from the next payout.');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = ref.watch(payoutAccountProvider).value;
    if (a != null && !_loaded) {
      _loaded = true;
      _holder.text = a.holder;
      _bank.text = a.bank;
      _number.text = a.number;
      _payNow.text = a.payNow;
      _auto = a.auto;
    }
    if (_unlocked != true) {
      return KitScaffold(
        header: const KitHeader(title: 'Payout account'),
        children: [
          if (_unlocked == false) ...[
            const KitNote(
              'Face ID didn’t match, so the account stays locked.',
              tone: KitTone.warn,
            ),
            KitButton(label: 'Try again', onPressed: _unlock),
          ] else
            const CupertinoActivityIndicator(),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Payout account'),
      bottom: [KitButton(label: 'Save', loading: _busy, onPressed: _save)],
      children: [
        const KitTitle(
          'Where we pay you',
          lead: 'Changes take effect from the next payout.',
        ),
        KitInput(label: 'Account holder name', controller: _holder),
        KitInput(label: 'Bank', controller: _bank, hint: 'DBS, OCBC, UOB'),
        KitInput(
          label: 'Account number',
          controller: _number,
          keyboardType: TextInputType.number,
        ),
        KitInput(
          label: 'PayNow mobile or UEN',
          controller: _payNow,
          hint: 'Optional',
        ),
        Text('Automatic payout', style: OgText.heading(20)),
        Column(
          children: [
            for (final o in const ['Every Monday', 'Every month', 'Off'])
              KitChoiceRow(
                title: o,
                selected: _auto == o,
                onTap: () => setState(() => _auto = o),
              ),
          ],
        ),
        Text(
          'For a club or academy, the owner sets this. Admins and coaches can '
          'see earnings but can’t change the account.',
          style: OgText.body(13, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }
}
