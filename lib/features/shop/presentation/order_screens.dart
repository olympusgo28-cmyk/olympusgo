import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart' show pointsText;

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../earnings/application/earnings_providers.dart';
import '../../earnings/presentation/earnings_screens.dart' show cash;
import '../../play/data/payment_gateway.dart' show PaymentHold;
import '../../play/domain/meet_ops.dart' show newClientKey;
import '../../play/presentation/pay_flow.dart' show PayingFor, finishPayment;
import '../application/shop_providers.dart';
import '../domain/commerce_models.dart';
import '../domain/shop_models.dart';
import 'shop_screens.dart';

/// The cart, grouped by shop.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final cart = ref.watch(cartProvider);
    if (shopWaiting(cart, 'Cart', () => ref.invalidate(cartProvider))
        case final waiting?) {
      return waiting;
    }
    final lines = cart.requireValue;
    final byMall = <String, List<CartLine>>{};
    for (final l in lines) {
      byMall.putIfAbsent(l.product.mallId, () => []).add(l);
    }
    Future<void> setQty(CartLine l, int q) async {
      try {
        await ref.read(shopRepositoryProvider).setQty(l.id, q);
        ref.invalidate(cartProvider);
      } on AuthFailure catch (e) {
        if (context.mounted) showOgToast(context, e.message, error: true);
      }
    }

    return KitScaffold(
      header: const KitHeader(title: 'Cart'),
      children: [
        if (lines.isEmpty) ...[
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your cart is empty', style: OgText.heading(20)),
                  const SizedBox(height: 6),
                  Text(
                    'Items you add from a product page wait here.',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
          KitButton(
            label: 'Open the shop',
            onPressed: () => context.go(Routes.shop),
          ),
        ] else ...[
          for (final e in byMall.entries)
            KitCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Text(
                    e.value.first.product.mallName,
                    style: OgText.body(15, weight: FontWeight.w600),
                  ),
                ),
                for (final l in e.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: ProductArtBox(product: l.product, height: 56),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.product.name,
                                style: OgText.body(14, weight: FontWeight.w600),
                              ),
                              if (l.variant.isNotEmpty)
                                Text(
                                  l.variant,
                                  style: OgText.body(12, color: c.textMuted),
                                ),
                              Text(
                                cash(l.product.priceCents),
                                style: OgText.body(14, weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        KitQty(
                          value: l.qty,
                          onLess: () => setQty(l, l.qty - 1),
                          onMore: () => setQty(l, l.qty + 1),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: KitButton(
                    label:
                        'Check out · ${cash(e.value.fold(0, (a, l) => a + l.totalCents))}',
                    onPressed: () => context.push(Routes.checkout(e.key)),
                  ),
                ),
              ],
            ),
          Text(
            'Set an item to 0 to remove it. Each shop is paid separately. '
            'Points are chosen at checkout.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      ],
    );
  }
}

/// One shop's order: where to collect, the final price, points and paying.
/// Each shop is paid separately.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.mallId, this.only});

  final String mallId;

  /// Buy now, or a booked service: just this, not the cart.
  final CartLine? only;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  ShopQuote? _quote;
  String? _error;
  bool _usePoints = false;
  bool _busy = false;
  bool _pricing = true;
  int _ask = 0;
  String _key = newClientKey();
  Order? _placed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Asks the server for the price, with as many points as fit. Only the
  /// newest answer counts, so a quick toggle can't leave an old price showing.
  Future<void> _load() async {
    final ask = ++_ask;
    setState(() => _pricing = true);
    final repo = ref.read(shopRepositoryProvider);
    try {
      var q = await repo.quote(widget.mallId, only: widget.only);
      if (_usePoints && q.canRedeem) {
        var points = q.pointsBalanceCents < q.pointsCapCents
            ? q.pointsBalanceCents
            : q.pointsCapCents;
        q = await repo.quote(
          widget.mallId,
          only: widget.only,
          pointsCents: points,
        );
        // Points come off whole units, so a little may not fit.
        while (q.pointsLeftCents > 0) {
          points -= q.pointsLeftCents;
          q = await repo.quote(
            widget.mallId,
            only: widget.only,
            pointsCents: points,
          );
        }
      }
      if (mounted && ask == _ask) {
        setState(() {
          _quote = q;
          _error = null;
          _pricing = false;
        });
      }
    } on AuthFailure catch (e) {
      if (!mounted || ask != _ask) return;
      setState(() {
        _pricing = false;
        // A failed toggle keeps the price that's on screen.
        if (_quote == null) {
          _error = e.message;
        } else {
          _usePoints = _quote!.pointsCents > 0;
        }
      });
      if (_quote != null) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _pay(ShopQuote q, String mallName) async {
    final gateway = ref.read(paymentGatewayProvider);
    final method = await showPaySheet(
      context,
      kicker: 'Self-collect',
      title: mallName,
      subtitle: q.collectAddress,
      lines: [
        ('Items', cash(q.itemsCents)),
        if (q.pointsCents > 0) ('Points used', '−${cash(q.pointsCents)}'),
      ],
      totalCents: q.totalCents,
      payee: 'OlympusGO',
      notes: [q.refundRule, 'OlympusGO holds your payment until you collect.'],
    );
    if (method == null || !mounted) return;
    setState(() => _busy = true);
    String? orderId;
    try {
      final (hold, id) = await ref
          .read(shopRepositoryProvider)
          .reserve(
            widget.mallId,
            key: _key,
            expectedCents: q.totalCents,
            pointsCents: q.pointsCents,
            only: widget.only,
          );
      orderId = id;
      if (!mounted) return;
      await finishPayment(
        context,
        gateway,
        hold,
        method,
        paying: PayingFor.order,
      );
    } on AuthFailure catch (e) {
      if (mounted) {
        if (e.message == 'price_changed') {
          showOgToast(context, 'The price changed. Check it and pay again.');
          _load();
        } else {
          showOgToast(context, e.message, error: true);
        }
      }
    }
    // Pay stays off until the order has said what happened.
    if (orderId != null && mounted) await _landed(orderId);
    // No answer means a new try, and an order left behind stays the only one.
    if (orderId == null) _key = newClientKey();
    if (mounted) setState(() => _busy = false);
  }

  /// The order says what happened, whatever the waiting screen was left at. A
  /// payment left running can still land, so Pay must not come back for it.
  Future<void> _landed(String id) async {
    refreshShop(ref.invalidate);
    refreshEarnings(ref.invalidate);
    final repo = ref.read(shopRepositoryProvider);
    try {
      final o = await repo.order(id);
      if (!mounted) return;
      switch (o.step) {
        case OrderStep.pending:
          showOgToast(context, 'Your order is held until you pay.');
          context.go(Routes.order(id));
        case OrderStep.cancelled || OrderStep.expired:
          _key = newClientKey();
        default:
          HapticFeedback.mediumImpact();
          setState(() => _placed = o);
      }
    } on AuthFailure {
      if (mounted) context.go(Routes.order(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    if (_placed case final o?) {
      return KitScaffold(
        header: const KitHeader(title: 'Checkout'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'See my order',
            onPressed: () => context.go(Routes.order(o.id)),
          ),
          KitButton(
            label: 'Keep shopping',
            style: KitButtonStyle.outline,
            onPressed: () => context.go(Routes.shop),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Order placed'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${cash(o.totalCents)} paid. ${o.mallName} will tell you '
                  'when it’s ready. OlympusGO holds your payment until you '
                  'collect.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
                const SizedBox(height: 10),
                KitKeyValue('Collect from', o.collectAddress),
                if (o.pointsCents > 0)
                  KitKeyValue('Points used', pointsText(o.pointsCents)),
              ],
            ),
          ),
        ],
      );
    }
    final only = widget.only;
    final cart = ref.watch(cartProvider);
    if (only == null) {
      if (shopWaiting(cart, 'Checkout', () => ref.invalidate(cartProvider))
          case final waiting?) {
        return waiting;
      }
    }
    final lines = only != null
        ? [only]
        : cart.requireValue
              .where((l) => l.product.mallId == widget.mallId)
              .toList();
    final q = _quote;
    if (_error case final message?) {
      return KitScaffold(
        header: const KitHeader(title: 'Checkout'),
        children: [
          KitNote(message, tone: KitTone.warn),
          KitButton(label: 'Try again', onPressed: _load),
        ],
      );
    }
    if (q == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Checkout'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final mallName = lines.isEmpty ? 'Shop' : lines.first.product.mallName;
    final canPay = q.canPay && ref.read(paymentGatewayProvider).canCollect;
    return KitScaffold(
      header: const KitHeader(title: 'Checkout'),
      bottom: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cash(q.totalCents), style: OgText.heading(22)),
                  Text(
                    'Final price',
                    style: OgText.body(12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            KitButton(
              label: 'Pay',
              expand: false,
              padding: 32,
              loading: _busy,
              onPressed: q.lines.isEmpty || !canPay || _pricing
                  ? null
                  : () => _pay(q, mallName),
            ),
          ],
        ),
      ],
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderControl, width: 1.5),
          ),
          child: Row(
            children: [
              OgIcon(OgIcons.mapPin, size: 22, color: c.text),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collect from $mallName',
                      style: OgText.body(15, weight: FontWeight.w600),
                    ),
                    Text(
                      q.collectAddress,
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (only?.slot case final slot?)
          KitKeyValue('Drop off', Fmt.dayTimeComma(slot)),
        if (q.lines.isEmpty)
          const KitNote(
            'Nothing here can be bought right now.',
            tone: KitTone.warn,
          ),
        KitCard(
          children: [
            for (final l in q.lines)
              MoneyLine(
                title: l.name,
                sub: [
                  if (l.variant.isNotEmpty) l.variant,
                  'qty ${l.qty}',
                ].join(', '),
                amount: cash(l.priceCents * l.qty),
              ),
          ],
        ),
        if (q.pointsCapCents > 0 && q.canRedeem && q.pointsBalanceCents > 0)
          SwitchRow(
            compact: true,
            title: 'Use points',
            subtitle:
                'You have ${pointsText(q.pointsBalanceCents)}. Up to '
                '${pointsText(q.pointsCapCents)} can be used here.',
            value: _usePoints,
            onChanged: (v) {
              setState(() => _usePoints = v);
              _load();
            },
          ),
        Column(
          children: [
            KitKeyValue('Items', cash(q.itemsCents)),
            if (q.pointsCents > 0)
              KitKeyValue('Points used', '−${cash(q.pointsCents)}'),
            KitKeyValue('Total', cash(q.totalCents)),
          ],
        ),
        Text(
          q.refundRule,
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
        if (!canPay)
          const KitNote(
            'Paying in the Shop isn’t open yet. It opens once payments are '
            'switched on.',
            tone: KitTone.warn,
          ),
      ],
    );
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, this.tab = 'all'});

  final String tab;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  static const _tabs = ['All', 'To collect', 'To review'];
  late int _tab = switch (widget.tab) {
    'collect' => 1,
    'review' => 2,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final orders = ref.watch(myOrdersProvider);
    if (shopWaiting(orders, 'My orders', () => ref.invalidate(myOrdersProvider))
        case final waiting?) {
      return waiting;
    }
    final shown = orders.requireValue
        .where(
          (o) => switch (_tab) {
            1 => o.step.waiting,
            2 => o.collectedAt != null && !o.reviewed,
            _ => true,
          },
        )
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'My orders'),
      children: [
        KitUnderlineTabs(
          labels: _tabs,
          selected: _tab,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = i),
        ),
        if (shown.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nothing here. Orders in this step show up here.',
                style: OgText.body(14, color: c.textMuted),
              ),
            ),
          )
        else
          for (final o in shown) OrderCard(order: o, route: Routes.order(o.id)),
      ],
    );
  }
}

/// A row in a list of orders, for the buyer or the shop.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.route,
    this.line,
    this.amount,
  });

  final Order order;
  final String route;

  /// The line under the summary, when not the collection date.
  final String? line;
  final int? amount;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final o = order;
    final bad = o.step.ended || o.step == OrderStep.reported;
    return Pressable(
      semanticLabel: '${o.mallName}, ${o.summary}, ${o.step.label}',
      onPressed: () => context.push(route),
      child: KitCard(
        padding: const EdgeInsets.all(14),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      o.mallName,
                      style: OgText.body(15, weight: FontWeight.w600),
                    ),
                  ),
                  KitTag(
                    o.step.label,
                    background: bad ? t.dangerFill : t.tag,
                    foreground: bad ? t.onDangerFill : t.onTag,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(o.summary, style: OgText.body(14, weight: FontWeight.w600)),
              Text(
                line ??
                    (o.slotAt != null
                        ? 'Drop off ${Fmt.dayTimeComma(o.slotAt!)}'
                        : o.step.waiting && o.collectBy != null
                        ? 'Collect by ${Fmt.day(o.collectBy!)}'
                        : 'Ordered ${Fmt.day(o.placedAt)}'),
                style: OgText.body(13, color: c.textMuted),
              ),
              const SizedBox(height: 8),
              Text(cash(amount ?? o.totalCents), style: OgText.heading(18)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where an ended order's money went, without promising what isn't known.
String shopMoneyLine(Order o) => o.disputeStatus == 'lost'
    ? 'Your bank returned your payment.'
    : o.refundStatus == 'failed'
    ? 'Your refund hasn’t gone through yet. We’re on it.'
    : o.refundedCents > 0
    ? '${cash(o.refundedCents)} goes back to how you paid.'
    : o.disputeStatus == 'open'
    ? 'Your refund is on hold while your bank looks into a dispute.'
    : o.paid
    ? 'We’re sorting out your refund and will be in touch.'
    : o.paymentStatus == 'cancel_requested'
    ? 'You haven’t been charged. If a payment still lands, it all comes back.'
    : 'You weren’t charged.';

/// One order: where it is, the items, and what you can do.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;
  bool _paying = false;

  Future<void> _collected() async {
    final yes = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Got everything?', style: OgText.heading(24)),
          const SizedBox(height: 8),
          Text(
            'OlympusGO pays the shop now, and sports equipment is final once '
            'collected. Only tap this once it’s all in your hands.',
            style: OgText.body(15, height: 1.45, color: sheet.og.textMuted),
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Yes, I got it all',
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: 10),
          KitButton(
            label: 'Not yet',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(shopRepositoryProvider).collected(widget.id);
      HapticFeedback.mediumImpact();
      if (mounted) refreshShop(ref.invalidate);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Picks up a payment that hasn't finished.
  Future<void> _finishPaying(Order o) async {
    if (_paying) return;
    setState(() => _paying = true);
    final gateway = ref.read(paymentGatewayProvider);
    final method = await showPaySheet(
      context,
      kicker: 'Self-collect',
      title: o.mallName,
      subtitle: o.collectAddress,
      lines: [
        ('Items', cash(o.itemsCents)),
        if (o.pointsCents > 0) ('Points used', '−${cash(o.pointsCents)}'),
      ],
      totalCents: o.totalCents,
      payee: 'OlympusGO',
      notes: const ['OlympusGO holds your payment until you collect.'],
    );
    if (!mounted) return;
    if (method == null) {
      setState(() => _paying = false);
      return;
    }
    try {
      await finishPayment(
        context,
        gateway,
        PaymentHold(
          result: 'reserved',
          id: o.paymentId,
          totalCents: o.totalCents,
          holdUntil: o.holdUntil,
          serverNow: o.serverNow,
          method: o.paymentMethod,
        ),
        method,
        paying: PayingFor.order,
      );
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
    if (!mounted) return;
    setState(() => _paying = false);
    refreshShop(ref.invalidate);
    refreshEarnings(ref.invalidate);
  }

  /// Where the money went, without promising what isn't known.
  String _moneyLine(Order o) => shopMoneyLine(o);

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final order = ref.watch(orderDetailProvider(widget.id));
    if (shopWaiting(
          order,
          'Order',
          () => ref.invalidate(orderDetailProvider(widget.id)),
        )
        case final waiting?) {
      return waiting;
    }
    final o = order.requireValue;
    final (title, lead) = switch (o.step) {
      OrderStep.pending => ('To pay', 'Your order is held until you pay.'),
      OrderStep.paid =>
        o.service
            ? ('Booked', '${o.mallName} has your booking.')
            : (
                'Paid',
                '${o.mallName} will tell you when it’s ready to collect.',
              ),
      OrderStep.started => (
        'In progress',
        '${o.mallName} has started work on it.',
      ),
      OrderStep.ready => (
        'Ready to collect',
        'OlympusGO holds your payment until you collect.',
      ),
      OrderStep.collected || OrderStep.released =>
        o.collectedAt == null
            ? (
                'Collection time ended',
                'The payment went to ${o.mallName}. Ask them about your order.',
              )
            : ('Collected', 'This sale is final.'),
      OrderStep.reported => (
        'Problem reported',
        'Your payment stays held while we look into it.',
      ),
      OrderStep.cancelled => ('Cancelled', _moneyLine(o)),
      OrderStep.expired => ('Expired', _moneyLine(o)),
      OrderStep.refunded => ('Refunded', _moneyLine(o)),
    };
    return KitScaffold(
      header: const KitHeader(title: 'Order'),
      bottom: [
        if (o.step == OrderStep.pending && o.paymentId != null)
          KitButton(
            label: 'Pay ${cash(o.totalCents)}',
            loading: _paying,
            onPressed: () => _finishPaying(o),
          ),
        if (o.step.waiting) ...[
          KitButton(
            label: 'Yes, I got it all',
            loading: _busy,
            onPressed: _collected,
          ),
          KitButton(
            label: 'Report a problem',
            style: KitButtonStyle.outline,
            onPressed: () => context.push(Routes.orderProblem(o.id)),
          ),
        ],
        if (o.canCancel)
          KitButton(
            label: 'Cancel order',
            style: KitButtonStyle.dangerOutline,
            onPressed: () => context.push(Routes.orderCancel(o.id)),
          ),
        if (o.refundedCents > 0)
          KitButton(
            label: 'Refund status',
            onPressed: () => context.push(Routes.refund(o.id)),
          ),
      ],
      children: [
        KitTitle(title, lead: lead),
        if (o.step.waiting) ...[
          KitNote(
            o.step == OrderStep.ready
                ? 'Tap “Yes, I got it all” at the shop once it’s in your hands. '
                      'That pays the shop, and the shop should wait to see it.'
                : 'You’ll be told when it’s ready. Tap “Yes, I got it all” only '
                      'once it’s in your hands.',
          ),
          if (o.collectBy != null && !o.service)
            KitKeyValue('Collect by', Fmt.day(o.collectBy!)),
          if (o.step == OrderStep.ready && o.releaseAt != null)
            KitKeyValue(
              'Payment goes to the shop',
              Fmt.dayTimeComma(o.releaseAt!),
            ),
        ],
        if (o.slotAt != null)
          KitKeyValue('Drop off', Fmt.dayTimeComma(o.slotAt!)),
        KitKeyValue('Collect from', o.collectAddress),
        Text(o.mallName, style: OgText.heading(20)),
        KitCard(
          children: [
            for (final l in o.lines)
              MoneyLine(
                title: l.name,
                sub: [
                  if (l.variant.isNotEmpty) l.variant,
                  'qty ${l.qty}',
                  if (l.refundedQty > 0) '${l.refundedQty} refunded',
                ].join(', '),
                amount: cash(l.priceCents * l.qty),
              ),
          ],
        ),
        Column(
          children: [
            KitKeyValue('Items', cash(o.itemsCents)),
            if (o.pointsCents > 0)
              KitKeyValue('Points used', '−${cash(o.pointsCents)}'),
            KitKeyValue(
              o.paid ? 'Paid with ${o.paidWith}' : 'Total',
              cash(o.totalCents),
            ),
            if (o.receiptNo.isNotEmpty) KitKeyValue('Receipt', o.receiptNo),
          ],
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.chatRound,
              title: 'Chat with ${o.mallName}',
              onTap: () => o.ownerId.isEmpty
                  ? showOgToast(context, 'This shop can’t be messaged yet.')
                  : context.push(Routes.messagePlayer(o.ownerId)),
            ),
            if (o.collectedAt != null && !o.reviewed)
              KitNavTile(
                icon: OgIcons.star,
                title: 'Write a review',
                subtitle: 'Help other players pick the right gear',
                onTap: () => context.push(Routes.orderReview(o.id)),
              ),
            KitNavTile(
              icon: OgIcons.flag,
              title: 'Get help',
              onTap: () => context.push(Routes.help),
            ),
          ],
        ),
        if (o.step.waiting)
          Text(
            o.step == OrderStep.ready
                ? 'Your payment goes to the shop when you tap “Yes, I got it '
                      'all”, or on the date above.'
                : 'Your payment goes to the shop when you tap “Yes, I got it all”.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
      ],
    );
  }
}

/// What's wrong with an order. The payment stays held until staff decide.
class OrderProblemScreen extends ConsumerStatefulWidget {
  const OrderProblemScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<OrderProblemScreen> createState() => _OrderProblemScreenState();
}

class _OrderProblemScreenState extends ConsumerState<OrderProblemScreen> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .reportProblem(widget.id, _note.text.trim());
      HapticFeedback.mediumImpact();
      if (mounted) {
        refreshShop(ref.invalidate);
        showOgToast(context, 'Reported. Your payment stays held.');
        context.pop();
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KitScaffold(
      header: const KitHeader(title: 'Report a problem'),
      bottom: [
        ListenableBuilder(
          listenable: _note,
          builder: (_, _) => KitButton(
            label: _note.text.trim().isEmpty ? 'Tell us what’s wrong' : 'Send',
            loading: _busy,
            onPressed: _note.text.trim().isEmpty ? null : _send,
          ),
        ),
      ],
      children: [
        const KitTitle(
          'What’s wrong?',
          lead:
              'Wrong item, something missing or damaged. Your payment stays '
              'held while OlympusGO looks into it, and we’ll tell you the '
              'outcome.',
        ),
        KitTextArea(label: 'What happened', controller: _note),
      ],
    );
  }
}

/// Cancel before collecting: why, and where the refund goes.
class OrderCancelScreen extends ConsumerStatefulWidget {
  const OrderCancelScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<OrderCancelScreen> createState() => _OrderCancelScreenState();
}

class _OrderCancelScreenState extends ConsumerState<OrderCancelScreen> {
  String? _why;
  bool _busy = false;
  int? _done;
  Order? _was;

  Future<void> _cancel(Order o) async {
    setState(() {
      _busy = true;
      _was = o;
    });
    try {
      final back = await ref
          .read(shopRepositoryProvider)
          .cancelOrder(widget.id, reason: _why!);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      refreshShop(ref.invalidate);
      refreshEarnings(ref.invalidate);
      setState(() => _done = back);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final order = ref.watch(orderDetailProvider(widget.id));
    if (_done case final back?) {
      return KitScaffold(
        header: const KitHeader(title: 'Cancel order'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          if (back > 0)
            KitButton(
              label: 'Track the refund',
              onPressed: () =>
                  context.pushReplacement(Routes.refund(widget.id)),
            ),
          KitButton(
            label: 'Back to my orders',
            style: back > 0 ? KitButtonStyle.outline : KitButtonStyle.primary,
            onPressed: () => context.go(Routes.orders()),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Cancelled'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              [
                if (back > 0)
                  '${cash(back)} goes back to how you paid.'
                else if (_was?.paymentMethod != null && _was?.paid != true)
                  'You haven’t been charged. If a payment still lands, it all comes back.'
                else if (_was?.paid == true)
                  'We’re sorting out your refund and will be in touch.'
                else
                  'You weren’t charged.',
                if ((_was?.pointsCents ?? 0) > 0)
                  'Points you used are back with you.',
              ].join(' '),
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    if (shopWaiting(
          order,
          'Cancel order',
          () => ref.invalidate(orderDetailProvider(widget.id)),
        )
        case final waiting?) {
      return waiting;
    }
    final o = order.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'Cancel order'),
      bottom: [
        KitButton(
          label: _why == null ? 'Pick a reason' : 'Cancel order',
          style: KitButtonStyle.danger,
          loading: _busy,
          onPressed: _why == null ? null : () => _cancel(o),
        ),
      ],
      children: [
        KitCard(
          children: [
            MoneyLine(
              title: o.summary,
              sub: '${o.mallName} · ${o.step.label}',
              amount: cash(o.totalCents),
            ),
          ],
        ),
        Text('Why are you cancelling?', style: OgText.heading(20)),
        Column(
          children: [
            for (final r in const [
              'Ordered by mistake',
              'Found it cheaper',
              'Can’t get to the shop',
              'Changed my mind',
            ])
              KitChoiceRow(
                title: r,
                selected: _why == r,
                onTap: () => setState(() => _why = r),
              ),
          ],
        ),
        Text(
          'You can cancel free until you collect. There is no platform fee on '
          'Shop orders, so all of it goes back to how you paid.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// A title, a line and an amount, without a tap.
class MoneyLine extends StatelessWidget {
  const MoneyLine({
    super.key,
    required this.title,
    required this.sub,
    required this.amount,
  });

  final String title;
  final String sub;
  final String amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: OgText.body(15, weight: FontWeight.w600)),
              Text(sub, style: OgText.body(13, color: context.og.textMuted)),
            ],
          ),
        ),
        Text(amount, style: OgText.heading(18)),
      ],
    ),
  );
}

/// Where a refund is.
class RefundStatusScreen extends ConsumerWidget {
  const RefundStatusScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final order = ref.watch(orderDetailProvider(id));
    if (shopWaiting(
          order,
          'Refund',
          () => ref.invalidate(orderDetailProvider(id)),
        )
        case final waiting?) {
      return waiting;
    }
    final o = order.requireValue;
    final steps = [
      ('Refund approved', ''),
      ('Sent back to how you paid', ''),
      ('In your account', 'Card refunds take 3 to 5 working days'),
    ];
    final (title, done) = switch (o.refundStatus) {
      'done' => ('Refunded', 3),
      'failed' => ('Taking longer than usual', 1),
      _ => ('On its way', 1),
    };
    return KitScaffold(
      header: const KitHeader(title: 'Refund'),
      bottom: [
        KitButton(
          label: 'Back to my orders',
          onPressed: () => context.go(Routes.orders()),
        ),
        KitButton(
          label: 'Chat with support',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.help),
        ),
      ],
      children: [
        KitTitle(
          title,
          lead: '${cash(o.refundedCents)} · ${o.summary} · ${o.mallName}',
        ),
        KitCard(
          padding: const EdgeInsets.all(14),
          children: [
            Column(
              children: [
                for (final (i, (title, sub)) in steps.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i < done ? c.primary : t.tag,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: OgText.body(
                              12,
                              weight: FontWeight.w600,
                              color: i < done ? c.onPrimary : t.onTag,
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
                                style: OgText.body(14, weight: FontWeight.w600),
                              ),
                              if (sub.isNotEmpty)
                                Text(
                                  sub,
                                  style: OgText.body(12, color: c.textMuted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        KitKeyValue('To', o.paidWith),
        if (o.pointsCents > 0 && o.step == OrderStep.cancelled)
          KitKeyValue(
            'Points returned',
            '${pointsText(o.pointsCents)}, already back with you',
          ),
        if (o.receiptNo.isNotEmpty) KitKeyValue('Reference', o.receiptNo),
        Text(
          'Card and PayNow refunds depend on your bank.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Report a listing.
class ReportListingScreen extends ConsumerStatefulWidget {
  const ReportListingScreen({
    super.key,
    required this.productId,
    required this.name,
  });

  final String productId;
  final String name;

  @override
  ConsumerState<ReportListingScreen> createState() =>
      _ReportListingScreenState();
}

class _ReportListingScreenState extends ConsumerState<ReportListingScreen> {
  static const _reasons = [
    (
      'Fake or unsafe product',
      'Not as described, counterfeit, or dangerous',
      false,
    ),
    ('Scam or fraud', 'Fake offer, asks for money or codes', false),
    ('Copyright', 'Uses my photo, video or music without permission', false),
    ('Harassment or bullying', 'Insults, threats, unwanted contact', false),
    (
      'Personal details shared',
      'Address, phone, school or workplace posted without consent',
      true,
    ),
    ('Hate or violence', 'Threats, or attacks on race or religion', true),
    ('Something else', 'Tell us in your own words', false),
  ];

  String? _why;
  final _note = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .report(widget.productId, reason: _why!, note: _note.text.trim());
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    if (_sent) {
      return KitScaffold(
        header: const KitHeader(title: 'Report'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [KitButton(label: 'Done', onPressed: () => context.pop())],
        children: [
          const KitDoneBanner(title: 'Report sent'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Thank you. We review every report within 24 hours, and urgent '
              'ones first. If someone is in danger, call 999.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Report'),
      bottom: [
        KitButton(
          label: _why == null ? 'Pick what is wrong' : 'Send report',
          loading: _busy,
          onPressed: _why == null ? null : _send,
        ),
      ],
      children: [
        KitCard(
          children: [MoneyLine(title: widget.name, sub: 'Listing', amount: '')],
        ),
        Text('What is wrong with it?', style: OgText.heading(20)),
        Text(
          'Reports are private. The shop is not told who reported.',
          style: OgText.body(13, color: c.textMuted),
        ),
        Column(
          children: [
            for (final (title, sub, urgent) in _reasons)
              KitChoiceRow(
                title: title,
                subtitle: sub,
                tag: urgent ? 'Urgent' : null,
                selected: _why == title,
                onTap: () => setState(() => _why = title),
              ),
          ],
        ),
        KitTextArea(label: 'Tell us more', optional: true, controller: _note),
        if (_why != null && _reasons.any((r) => r.$1 == _why && r.$3))
          KitNote('Urgent reports are reviewed first.', tone: KitTone.warn),
      ],
    );
  }
}

/// Rate a collected order: stars, what stood out, and a few words.
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  static const _tags = [
    'Good grip',
    'True to size',
    'Comfortable',
    'Good value',
    'Quick to get ready',
    'Helpful shop',
  ];
  static const _words = [
    'Tap to rate',
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  int _stars = 0;
  final _picked = <String>{};
  final _text = TextEditingController();
  bool _showLevel = true;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .review(
            widget.id,
            stars: _stars,
            tags: _picked.toList(),
            text: _text.text.trim(),
            showLevel: _showLevel,
          );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      refreshShop(ref.invalidate);
      setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    if (_sent) {
      return KitScaffold(
        header: const KitHeader(title: 'Write a review'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to my orders',
            onPressed: () => context.go(Routes.orders()),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Review posted'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Thanks. Reviews from players at your level help others pick '
              'the right gear.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    final o = ref.watch(orderDetailProvider(widget.id)).value;
    return KitScaffold(
      header: const KitHeader(title: 'Write a review'),
      bottom: [
        KitButton(
          label: _stars == 0 ? 'Tap a star to rate' : 'Post review',
          loading: _busy,
          onPressed: _stars == 0 ? null : _send,
        ),
      ],
      children: [
        if (o != null)
          Row(
            children: [
              SizedBox(
                width: 56,
                child: ProductArtBox(
                  height: 56,
                  product: Product(
                    id: '',
                    name: o.lines.first.name,
                    mallId: o.mallId,
                    mallName: o.mallName,
                    priceCents: o.lines.first.priceCents,
                    art: o.lines.first.art,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.summary,
                      style: OgText.body(15, weight: FontWeight.w600),
                    ),
                    Text(
                      o.mallName,
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  KitIconButton(
                    icon: OgIcons.star,
                    label: '$i ${i == 1 ? 'star' : 'stars'}',
                    size: 34,
                    fill: i <= _stars,
                    color: i <= _stars ? t.gold : c.textMuted,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stars = i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_words[_stars], style: OgText.heading(24)),
          ],
        ),
        Text('What stood out?', style: OgText.heading(20)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in _tags)
              KitChip(
                label: tag,
                selected: _picked.contains(tag),
                onTap: () => setState(() {
                  if (!_picked.remove(tag)) _picked.add(tag);
                }),
              ),
          ],
        ),
        KitTextArea(
          label: 'Tell other players more',
          optional: true,
          controller: _text,
          lines: 4,
        ),
        KitChoiceRow(
          title: 'Show my sport and level next to my review',
          selected: _showLevel,
          multi: true,
          onTap: () => setState(() => _showLevel = !_showLevel),
        ),
      ],
    );
  }
}
