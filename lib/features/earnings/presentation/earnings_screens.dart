import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../core/widgets/place_code.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/domain/activity.dart' show money;
import '../../play/presentation/pay_flow.dart';
import '../application/earnings_providers.dart';
import '../data/earnings_repository.dart';

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
  });

  final String label;
  final String value;
  final String note;

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
              weight: FontWeight.w600,
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
                  Text(title, style: OgText.body(15, weight: FontWeight.w600)),
                  Text(sub, style: OgText.body(13, color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              amount,
              style: OgText.body(
                15,
                weight: FontWeight.w600,
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
    final how = [
      if (p.earning) ...const [
        (
          'Play',
          'A S\$2.00 fee earns 40 points when you are marked Present at a '
              'paid Meet.',
        ),
        ('Watch', 'Earn points the same way when your ticket is scanned.'),
      ] else
        ('Earn', 'Earning points opens soon.'),
      (
        'Spend',
        '1 point takes S\$0.10 off at partner shops. Each item has a limit.',
      ),
    ];
    return KitScaffold(
      header: const KitHeader(title: 'Points'),
      children: [
        _BalanceCard(
          label: 'Your points',
          value: pointsText(p.minor),
          note: 'Worth ${Money(p.minor)} off at partner shops',
        ),
        if (p.pendingMinor > 0)
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
                    text: '${pointsText(p.pendingMinor)} points pending ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                          weight: FontWeight.w600,
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
                            style: OgText.body(15, weight: FontWeight.w600),
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
        if (p.nextExpiry != null)
          KitKeyValue('Oldest points run out', Fmt.day(p.nextExpiry!)),
        Row(
          children: [
            Expanded(child: Text('Use points', style: OgText.heading(20))),
            KitLink(
              'Open the shop',
              onPressed: () => context.push(Routes.shop),
            ),
          ],
        ),
        if (p.uses.isNotEmpty)
          KitCard(
            children: [
              for (final u in p.uses)
                MoneyRow(
                  title: u.name,
                  sub:
                      '${u.shop} · ${cash(u.priceCents)} · up to ${pointsText(u.capCents)} pts',
                  amount:
                      'You pay ${cash(u.priceCents - u.capCents.clamp(0, p.minor))}',
                  onTap: () => context.push(Routes.shop),
                ),
            ],
          ),
        Text(
          '1 point takes S\$0.10 off. Each item has its own limit. Points left '
          'over stay with you, and run out after 12 months.',
          style: OgText.body(13, color: c.textMuted),
        ),
        if (p.activity.isNotEmpty) ...[
          Text('Activity', style: OgText.heading(20)),
          KitCard(
            children: [
              for (final (title, sub, amt) in p.activity)
                MoneyRow(
                  title: title,
                  sub: sub,
                  amount: '${amt > 0 ? '+' : '−'}${pointsText(amt.abs())} pts',
                  good: amt > 0,
                ),
            ],
          ),
        ],
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
              weight: FontWeight.w600,
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
          note: account?.isSet == true
              ? 'Paid to your bank each week, once our team approves the run.'
              : 'Set up your payout account so we can pay you.',
        ),
        if (e.owedCents > 0)
          KitNote(
            'Fees of ${cash(e.owedCents)} are more than your earnings. They '
            'come off your next payouts.',
            tone: KitTone.warn,
          ),
        if (e.feeDebtCents > 0) _FeesOwed(cents: e.feeDebtCents),
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
              title: 'Payout account',
              subtitle: account?.label ?? '…',
              onTap: () => context.push(Routes.payoutAccount),
            ),
            KitNavTile(
              icon: OgIcons.clipboardList,
              title: 'Receipts',
              subtitle: 'What you’ve paid and had back',
              onTap: () => context.push(Routes.receipts),
            ),
          ],
        ),
      ],
    );
  }
}

/// Organizer fees that couldn't be charged, and a way to clear them.
class _FeesOwed extends ConsumerStatefulWidget {
  const _FeesOwed({required this.cents});

  final int cents;

  @override
  ConsumerState<_FeesOwed> createState() => _FeesOwedState();
}

class _FeesOwedState extends ConsumerState<_FeesOwed> {
  bool _busy = false;

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      await payFeesOwed(context, ref, widget.cents);
      refreshEarnings(ref.invalidate);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitNote(
          'We couldn’t charge ${cash(widget.cents)} of organizer fees to your '
          'card. Your players keep their spots. Clear it to publish another '
          'Meet where you cover the fee.',
          tone: KitTone.warn,
        ),
        const SizedBox(height: 8),
        KitButton(label: 'Pay it now', loading: _busy, onPressed: _pay),
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

/// Where Olympus pays you. Stripe collects the bank details and runs the
/// checks (R-PAY-4), and only the owner gets here (R-PAY-3). Opens with Face ID.
class PayoutAccountScreen extends ConsumerStatefulWidget {
  const PayoutAccountScreen({super.key});

  @override
  ConsumerState<PayoutAccountScreen> createState() =>
      _PayoutAccountScreenState();
}

class _PayoutAccountScreenState extends ConsumerState<PayoutAccountScreen> {
  bool? _unlocked;
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

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final url = await ref.read(earningsRepositoryProvider).startPayouts();
      HapticFeedback.mediumImpact();
      refreshEarnings(ref.invalidate);
      if (url != null) await launchUrl(Uri.parse(url));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _schedule(String auto) async {
    try {
      await ref.read(earningsRepositoryProvider).setPayoutSchedule(auto);
      refreshEarnings(ref.invalidate);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = ref.watch(payoutAccountProvider).value;
    if (_unlocked != true || a == null) {
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
      bottom: [
        if (!a.isSet)
          KitButton(
            label: a.status == 'none' ? 'Set up payouts' : 'Continue set-up',
            loading: _busy,
            onPressed: _start,
          ),
      ],
      children: [
        KitTitle('Where we pay you', lead: a.label),
        if (a.isSet) ...[
          KitButton.outline(
            label: 'Show my code',
            onPressed: () => showPlaceCode(
              context,
              title: 'My code',
              load: (rotate) =>
                  ref.read(playRepositoryProvider).vendorCode(rotate: rotate),
            ),
          ),
          Text('Automatic payout', style: OgText.heading(20)),
          Column(
            children: [
              for (final o in const ['Every Monday', 'Every month', 'Off'])
                KitChoiceRow(
                  title: o,
                  selected: a.auto == o,
                  onTap: () => _schedule(o),
                ),
            ],
          ),
        ] else
          const KitNote(
            'Our payment partner, Stripe, checks who you are and takes your '
            'bank details. OlympusGO never sees your full account number.',
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

/// The card organizer-pays Meets charge. Cards are never stored by Olympus.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(earningsRepositoryProvider).saveCard();
      HapticFeedback.mediumImpact();
      refreshEarnings(ref.invalidate);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(savedCardProvider);
    return KitScaffold(
      header: const KitHeader(title: 'Payment methods'),
      bottom: [
        KitButton(
          label: card.value == null ? 'Save a card' : 'Replace this card',
          loading: _busy,
          onPressed: card.isLoading ? null : _save,
        ),
      ],
      children: [
        KitTitle(
          card.value ?? 'No card saved',
          lead:
              'If you cover the S\$2.00 fee on a free Meet, it’s charged to '
              'this card each time a player joins. You can pay for anything '
              'else with a card or PayNow when you book.',
        ),
      ],
    );
  }
}
