import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../earnings/application/earnings_providers.dart';
import '../../earnings/presentation/earnings_screens.dart' show cash;
import '../application/shop_providers.dart';
import '../domain/commerce_models.dart';
import 'order_screens.dart';
import 'shop_screens.dart' show shopWaiting;

/// The shop owner's orders: what to get ready, and what's been collected.
class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final orders = ref.watch(ownerOrdersProvider);
    if (shopWaiting(
          orders,
          'My shop',
          () => ref.invalidate(ownerOrdersProvider),
        )
        case final waiting?) {
      return waiting;
    }
    final shown = orders.requireValue
        .where(
          (o) => switch (_tab) {
            0 => o.step == OrderStep.paid || o.step == OrderStep.started,
            1 => o.step == OrderStep.ready || o.step == OrderStep.reported,
            _ => o.step.closed || o.step.ended,
          },
        )
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'My shop'),
      children: [
        KitUnderlineTabs(
          labels: const ['To get ready', 'Ready', 'Done'],
          selected: _tab,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = i),
        ),
        if (shown.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nothing here. New orders show up as soon as they’re paid.',
                style: OgText.body(14, color: c.textMuted),
              ),
            ),
          )
        else
          for (final o in shown)
            OrderCard(
              order: o,
              route: Routes.ownerOrder(o.id),
              line: o.slotAt != null
                  ? '${o.buyer} · drop off ${Fmt.dayTimeComma(o.slotAt!)}'
                  : '${o.buyer} · ordered ${Fmt.day(o.placedAt)}',
              amount: o.shopCents,
            ),
      ],
    );
  }
}

/// One order, for the shop. The buyer taps "Yes, I got it all" in their app,
/// and the shop hands over once this screen says Collected.
class OwnerOrderScreen extends ConsumerStatefulWidget {
  const OwnerOrderScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<OwnerOrderScreen> createState() => _OwnerOrderScreenState();
}

class _OwnerOrderScreenState extends ConsumerState<OwnerOrderScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      HapticFeedback.mediumImpact();
      if (mounted) {
        refreshShop(ref.invalidate);
        refreshEarnings(ref.invalidate);
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final why = await showKitSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cancel this order?', style: OgText.heading(24)),
          const SizedBox(height: 8),
          Text(
            'The buyer gets everything back, and the card fee comes out of '
            'your next payout.',
            style: OgText.body(15, height: 1.45, color: sheet.og.textMuted),
          ),
          const SizedBox(height: 12),
          for (final r in const [
            'Out of stock',
            'Can’t do this service',
            'Buyer asked me to',
          ])
            KitChoiceRow(
              title: r,
              selected: false,
              onTap: () => Navigator.of(sheet).pop(r),
            ),
        ],
      ),
    );
    if (why == null || !mounted) return;
    await _run(
      () =>
          ref.read(shopRepositoryProvider).ownerCancel(widget.id, reason: why),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final repo = ref.read(shopRepositoryProvider);
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
      OrderStep.paid => ('Paid', 'Get it ready, then tell the buyer.'),
      OrderStep.started => ('In progress', 'Tell the buyer when it’s ready.'),
      OrderStep.ready => (
        'Ready to collect',
        'Hand over once this screen says Collected.',
      ),
      OrderStep.collected => (
        'Collected',
        'You can hand it over. The payment is on its way to your payouts.',
      ),
      OrderStep.released => (
        'Complete',
        'The payment has gone to your payouts.',
      ),
      OrderStep.reported => (
        'Problem reported',
        'The payment stays held while OlympusGO looks into it.',
      ),
      _ => (o.step.label, 'There is nothing to do for this order.'),
    };
    return KitScaffold(
      header: const KitHeader(title: 'Order'),
      bottom: [
        if (o.service && o.step == OrderStep.paid)
          KitButton(
            label: 'Start work',
            style: KitButtonStyle.outline,
            loading: _busy,
            onPressed: () => _run(() => repo.markStarted(o.id)),
          ),
        if (o.step == OrderStep.paid || o.step == OrderStep.started)
          KitButton(
            label: 'Mark ready',
            loading: _busy,
            onPressed: () => _run(() => repo.markReady(o.id)),
          ),
        if (o.step.waiting)
          KitButton(
            label: 'Cancel order',
            style: KitButtonStyle.dangerOutline,
            onPressed: _busy ? null : _cancel,
          ),
      ],
      children: [
        KitTitle(title, lead: lead),
        KitKeyValue('Buyer', o.buyer),
        if (o.slotAt != null)
          KitKeyValue('Drop off', Fmt.dayTimeComma(o.slotAt!)),
        if (o.collectBy != null && !o.service)
          KitKeyValue('Collect by', Fmt.day(o.collectBy!)),
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
                amount: cash(
                  o.step.ended ? 0 : l.shopCents * (l.qty - l.refundedQty),
                ),
              ),
          ],
        ),
        KitKeyValue('You get', cash(o.shopCents)),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.chatRound,
              title: 'Chat with ${o.buyer}',
              onTap: () => context.push(Routes.messagePlayer(o.buyerId)),
            ),
          ],
        ),
        Text(
          'Points a buyer uses never change what you get.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}
