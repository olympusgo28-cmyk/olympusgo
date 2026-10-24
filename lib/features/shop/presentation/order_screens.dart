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
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../wallet/application/wallet_providers.dart';
import '../../wallet/presentation/wallet_screens.dart' show cash;
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
    final lines = ref.watch(cartProvider).value;
    if (lines == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Cart'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final byMall = <String, List<CartLine>>{};
    for (final l in lines) {
      byMall.putIfAbsent(l.product.mallName, () => []).add(l);
    }
    final count = lines.fold(0, (a, l) => a + l.qty);
    final total = lines.fold(0, (a, l) => a + l.totalCents);
    Future<void> setQty(CartLine l, int q) async {
      await ref.read(shopRepositoryProvider).setQty(l.id, q);
      ref.invalidate(cartProvider);
    }

    return KitScaffold(
      header: const KitHeader(title: 'Cart'),
      bottom: lines.isEmpty
          ? null
          : [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cash(total), style: OgText.heading(22)),
                        Text(
                          '$count ${count == 1 ? 'item' : 'items'}',
                          style: OgText.body(12, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  KitButton(
                    label: 'Check out',
                    expand: false,
                    padding: 32,
                    onPressed: () => context.push(Routes.checkout),
                  ),
                ],
              ),
            ],
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
                    'Items you add from a video, a live or a product page wait here.',
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
                    e.key,
                    style: OgText.body(15, weight: FontWeight.w800),
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
                                style: OgText.body(14, weight: FontWeight.w700),
                              ),
                              if (l.variant.isNotEmpty)
                                Text(
                                  l.variant,
                                  style: OgText.body(12, color: c.textMuted),
                                ),
                              Text(
                                cash(l.product.priceCents),
                                style: OgText.body(14, weight: FontWeight.w700),
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
              ],
            ),
          Text(
            'Set an item to 0 to remove it. Points and delivery are chosen at checkout.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Delivery, address and the summary; points and payment on the next step.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.only});

  /// Buy now: just this, not the cart.
  final CartLine? only;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _delivery = 0;
  Address? _address;
  bool _busy = false;
  List<Order>? _placed;

  Future<void> _pay(List<CartLine> lines, Address address) async {
    final delivery = Delivery.options[_delivery];
    final items = lines.fold(0, (a, l) => a + l.totalCents);
    final cap = lines.fold(0, (a, l) => a + l.product.maxPoints * 100 * l.qty);
    final points = ref.read(walletSummaryProvider).value;
    final have = ((points?.points ?? 0) * 100).floor();
    final usable = [have, cap, items].reduce((a, b) => a < b ? a : b);
    final result = await showKitSheet<(int, String)>(
      context,
      builder: (_) => _PaySheet(
        items: items,
        delivery: delivery.cents,
        usablePoints: usable,
        walletCents: points?.balanceCents ?? 0,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final placed = await ref
          .read(shopRepositoryProvider)
          .checkout(
            address: address,
            delivery: delivery,
            pointsCents: result.$1,
            paidWith: result.$2,
            only: widget.only,
          );
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
      refreshWallet(ref.invalidate);
      if (mounted) setState(() => _placed = placed);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    if (_placed case final placed?) {
      final paid = placed.fold(0, (a, o) => a + o.totalCents);
      final pts = placed.fold(0, (a, o) => a + o.pointsCents);
      return KitScaffold(
        header: const KitHeader(title: 'Checkout'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Track my order',
            onPressed: () => context.go(Routes.order(placed.first.id)),
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
                  '${Env.hasSupabase ? '${cash(paid)} to pay the shop on delivery or pickup' : '${cash(paid)} paid with ${placed.first.paidWith}'}. ${placed.length} '
                  '${placed.length == 1 ? 'shop is' : 'shops are'} packing your order.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
                const SizedBox(height: 10),
                for (final o in placed)
                  KitKeyValue(
                    o.mallName,
                    '${o.lines.fold(0, (a, l) => a + l.qty)} ${o.lines.length == 1 && o.lines.first.qty == 1 ? 'item' : 'items'}',
                  ),
                if (pts > 0)
                  KitKeyValue('Points used', (pts / 100).toStringAsFixed(1)),
              ],
            ),
          ),
        ],
      );
    }
    final cartLines = ref.watch(cartProvider).value;
    final lines = widget.only == null ? cartLines : [widget.only!];
    final addresses = ref.watch(addressesProvider).value;
    final points = ref.watch(walletSummaryProvider).value?.points ?? 0;
    final address =
        _address ??
        addresses?.where((a) => a.isDefault).firstOrNull ??
        addresses?.firstOrNull;
    if (lines == null || addresses == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Checkout'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final delivery = Delivery.options[_delivery];
    final items = lines.fold(0, (a, l) => a + l.totalCents);
    final count = lines.fold(0, (a, l) => a + l.qty);
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
                  Text(cash(items + delivery.cents), style: OgText.heading(22)),
                  Text(
                    Env.hasSupabase
                        ? 'Pay the shop on delivery or pickup'
                        : 'Total before points',
                    style: OgText.body(12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            KitButton(
              label: Env.hasSupabase ? 'Review order' : 'Continue to pay',
              expand: false,
              loading: _busy,
              onPressed: lines.isEmpty || address == null
                  ? null
                  : () => _pay(lines, address),
            ),
          ],
        ),
      ],
      children: [
        Pressable(
          semanticLabel: 'Delivery address. Change',
          onPressed: () async {
            final picked = await context.push<Address>(Routes.addresses);
            if (picked != null) setState(() => _address = picked);
          },
          child: Container(
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
                        address == null
                            ? 'Add an address'
                            : (address.pickup
                                  ? address.label
                                  : 'Deliver to ${address.name}'),
                        style: OgText.body(15, weight: FontWeight.w700),
                      ),
                      if (address != null)
                        Text(
                          address.line,
                          style: OgText.body(13, color: c.textMuted),
                        ),
                      if (address != null && address.phone.isNotEmpty)
                        Text(
                          address.phone,
                          style: OgText.body(13, color: c.textMuted),
                        ),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: OgText.body(
                    14,
                    weight: FontWeight.w700,
                    color: c.link,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text('Delivery', style: OgText.heading(20)),
        Column(
          children: [
            for (final (i, d) in Delivery.options.indexed)
              KitChoiceRow(
                title: d.name,
                subtitle: d.sub,
                tag: d.cents == 0 ? 'Free' : cash(d.cents),
                selected: _delivery == i,
                onTap: () => setState(() => _delivery = i),
              ),
          ],
        ),
        Text(
          '$count ${count == 1 ? 'item' : 'items'}',
          style: OgText.heading(20),
        ),
        KitCard(
          children: [
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: ProductArtBox(product: l.product, height: 48),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.product.name,
                            style: OgText.body(14, weight: FontWeight.w700),
                          ),
                          Text(
                            [
                              if (l.variant.isNotEmpty) l.variant,
                              'qty ${l.qty}',
                            ].join(', '),
                            style: OgText.body(12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      cash(l.totalCents),
                      style: OgText.body(14, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
        KitKeyValue('Items', cash(items)),
        KitKeyValue(
          'Delivery',
          delivery.cents == 0 ? 'Free' : cash(delivery.cents),
        ),
        if (!Env.hasSupabase)
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'You have '),
                TextSpan(
                  text: '${points.toStringAsFixed(1)} points',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(
                  text:
                      '. Choose to use them, and how to pay, on the next step.',
                ),
              ],
            ),
            style: OgText.body(14, height: 1.4, color: c.textMuted),
          ),
      ],
    );
  }
}

/// Points, how to pay, then Face ID.
class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({
    required this.items,
    required this.delivery,
    required this.usablePoints,
    required this.walletCents,
  });

  final int items;
  final int delivery;

  /// In cents: 1 point is S$1.
  final int usablePoints;
  final int walletCents;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  late bool _usePoints = !Env.hasSupabase && widget.usablePoints > 0;
  String _method = Env.hasSupabase ? 'Pay the shop' : 'Card ending 4242';

  int get _points => _usePoints ? widget.usablePoints : 0;
  int get _total => widget.items + widget.delivery - _points;

  Future<void> _confirm() async {
    // Card payments are off: the order is placed and the buyer pays the
    // shop directly.
    if (Env.hasSupabase) {
      Navigator.of(context).pop((0, _method));
      return;
    }
    // Demo mode skips the device check, so a simulator never asks for its
    // passcode.
    final ok =
        !Env.hasSupabase ||
        await ref
            .read(biometricVaultProvider)
            .authenticate('Pay ${cash(_total)}');
    if (ok && mounted) {
      Navigator.of(context).pop((_points, _method));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final walletOk = widget.walletCents >= _total;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PAYMENT',
            style: OgText.body(
              12,
              weight: FontWeight.w800,
              color: c.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          Text(cash(_total), style: OgText.heading(30)),
          const SizedBox(height: 10),
          KitKeyValue('Items', cash(widget.items)),
          KitKeyValue(
            'Delivery',
            widget.delivery == 0 ? 'Free' : cash(widget.delivery),
          ),
          if (_points > 0) KitKeyValue('Points used', '−${cash(_points)}'),
          if (Env.hasSupabase) ...[
            const SizedBox(height: 8),
            KitChoiceRow(
              title: 'Pay the shop',
              subtitle:
                  'Cash or PayNow to the shop when it arrives or you '
                  'collect it',
              selected: true,
              onTap: () {},
            ),
            const SizedBox(height: 8),
            Text(
              'Card, Wallet and points payments are coming. For now nothing '
              'is charged in the app.',
              style: OgText.body(13, color: c.textMuted),
            ),
            const SizedBox(height: 14),
            KitButton(label: 'Place order', onPressed: _confirm),
          ] else ...[
            if (widget.usablePoints > 0)
              SwitchRow(
                compact: true,
                title:
                    'Use ${(widget.usablePoints / 100).toStringAsFixed(1)} points',
                subtitle:
                    'Takes ${cash(widget.usablePoints)} off. The rest stay in your wallet.',
                value: _usePoints,
                onChanged: (v) => setState(() => _usePoints = v),
              ),
            const SizedBox(height: 8),
            Text('Pay with', style: OgText.body(15, weight: FontWeight.w700)),
            KitChoiceRow(
              title: 'Card ending 4242',
              subtitle: 'Default card',
              selected: _method == 'Card ending 4242',
              onTap: () => setState(() => _method = 'Card ending 4242'),
            ),
            KitChoiceRow(
              title: 'Wallet',
              subtitle: walletOk
                  ? 'Balance ${cash(widget.walletCents)}'
                  : 'Not enough in your wallet',
              selected: _method == 'Wallet',
              onTap: walletOk
                  ? () => setState(() => _method = 'Wallet')
                  : () {},
            ),
            KitChoiceRow(
              title: 'PayNow',
              subtitle: 'Opens your bank app',
              selected: _method == 'PayNow',
              onTap: () => setState(() => _method = 'PayNow'),
            ),
            const SizedBox(height: 8),
            Text(
              'Shop orders have no platform fee.',
              style: OgText.body(13, color: c.textMuted),
            ),
            const SizedBox(height: 14),
            KitButton(
              label: 'Pay ${cash(_total)}',
              icon: OgIcons.faceId,
              onPressed: _confirm,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pick a delivery address.
class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(addressesProvider).value;
    final picked = _picked ?? list?.where((a) => a.isDefault).firstOrNull?.id;
    return KitScaffold(
      header: const KitHeader(title: 'Addresses'),
      bottom: [
        KitButton(
          label: 'Use this address',
          onPressed: picked == null
              ? null
              : () => context.pop(list!.firstWhere((a) => a.id == picked)),
        ),
        KitButton(
          label: 'Add an address',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.addressNew),
        ),
      ],
      children: [
        const KitTitle(
          'Deliver to',
          lead: 'Pick one for this order, or add a new one.',
        ),
        if (list == null)
          const CupertinoActivityIndicator()
        else
          Column(
            children: [
              for (final a in list)
                KitChoiceRow(
                  title: a.label,
                  subtitle: a.pickup ? a.line : '${a.name} · ${a.line}',
                  tag: a.isDefault ? 'Default' : null,
                  selected: picked == a.id,
                  onTap: () => setState(() => _picked = a.id),
                ),
            ],
          ),
      ],
    );
  }
}

/// A new delivery address.
class AddressNewScreen extends ConsumerStatefulWidget {
  const AddressNewScreen({super.key});

  @override
  ConsumerState<AddressNewScreen> createState() => _AddressNewScreenState();
}

class _AddressNewScreenState extends ConsumerState<AddressNewScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _postal = TextEditingController();
  final _street = TextEditingController();
  final _unit = TextEditingController();
  bool _default = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _postal, _street, _unit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _street.text.trim().isEmpty ||
        _postal.text.trim().length != 6) {
      showOgToast(
        context,
        'Add the name, street and a 6-digit postal code.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .saveAddress(
            Address(
              id: '',
              label: _default ? 'Home' : 'Address',
              name: _name.text.trim(),
              line:
                  '${_street.text.trim()}${_unit.text.trim().isEmpty ? '' : ', ${_unit.text.trim()}'}, Singapore ${_postal.text.trim()}',
              phone: _phone.text.trim(),
              isDefault: _default,
            ),
          );
      ref.invalidate(addressesProvider);
      if (mounted) context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => KitScaffold(
    header: const KitHeader(title: 'New address'),
    bottom: [
      KitButton(label: 'Save address', loading: _busy, onPressed: _save),
    ],
    children: [
      KitInput(label: 'Name', controller: _name),
      KitInput(
        label: 'Mobile',
        controller: _phone,
        keyboardType: TextInputType.phone,
      ),
      KitInput(
        label: 'Postal code',
        controller: _postal,
        keyboardType: TextInputType.number,
        maxLength: 6,
      ),
      KitInput(label: 'Street and block', controller: _street),
      KitInput(label: 'Unit', controller: _unit, hint: '#08-12'),
      SwitchRow(
        compact: true,
        title: 'Make this my default address',
        subtitle: 'Used first at checkout',
        value: _default,
        onChanged: (v) => setState(() => _default = v),
      ),
    ],
  );
}

/// My orders, by step.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, this.tab = 'all'});

  final String tab;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  static const _tabs = ['All', 'To ship', 'To receive', 'To review'];
  late int _tab = switch (widget.tab) {
    'ship' => 1,
    'receive' => 2,
    'review' => 3,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final all = ref.watch(myOrdersProvider).value;
    final shown = (all ?? const <Order>[])
        .where(
          (o) => switch (_tab) {
            1 => o.step == OrderStep.packing,
            2 => o.step == OrderStep.shipped,
            3 => o.step == OrderStep.delivered && !o.reviewed,
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
        if (all == null)
          const CupertinoActivityIndicator()
        else if (shown.isEmpty)
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
          for (final o in shown)
            Pressable(
              semanticLabel: '${o.mallName}, ${o.summary}, ${o.step.label}',
              onPressed: () => context.push(Routes.order(o.id)),
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
                              style: OgText.body(15, weight: FontWeight.w800),
                            ),
                          ),
                          KitTag(
                            o.service && o.step == OrderStep.packing
                                ? 'Booked'
                                : o.step.label,
                            background: o.step == OrderStep.cancelled
                                ? t.dangerFill
                                : t.tag,
                            foreground: o.step == OrderStep.cancelled
                                ? t.onDangerFill
                                : t.onTag,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        o.summary,
                        style: OgText.body(14, weight: FontWeight.w600),
                      ),
                      Text(
                        o.booking ??
                            (o.arrives == null ||
                                    o.step == OrderStep.delivered ||
                                    o.step == OrderStep.cancelled
                                ? 'Ordered ${Fmt.day(o.placedAt)}'
                                : 'Arrives ${Fmt.day(o.arrives!)}'),
                        style: OgText.body(13, color: c.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cash(o.totalCents),
                              style: OgText.heading(18),
                            ),
                          ),
                          if (o.step == OrderStep.shipped)
                            KitButton(
                              label: 'Confirm received',
                              expand: false,
                              height: 38,
                              radius: 19,
                              fontSize: 13,
                              onPressed: () async {
                                await ref
                                    .read(shopRepositoryProvider)
                                    .confirmReceived(o.id);
                                refreshShop(ref.invalidate);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// One order: the tracking steps, items, totals and what you can do.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final o = ref.watch(orderDetailProvider(id)).value;
    if (o == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Order'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final steps = [
      ('Order placed', Fmt.dayTimeComma(o.placedAt)),
      (
        'Packed by ${o.mallName}',
        o.step.index >= OrderStep.shipped.index && o.step != OrderStep.cancelled
            ? 'Done'
            : 'Next',
      ),
      (
        'With the courier',
        o.tracking == null
            ? 'Tracking number comes when it ships'
            : '${o.courier ?? 'Courier'} · ${o.tracking}',
      ),
      (
        'Out for delivery',
        o.arrives == null ? '' : 'Expected ${Fmt.day(o.arrives!)}',
      ),
      ('Delivered', 'You confirm, then you can review'),
    ];
    final reached = switch (o.step) {
      OrderStep.toPay => 0,
      OrderStep.packing => 1,
      OrderStep.shipped => 3,
      OrderStep.delivered => 5,
      OrderStep.cancelled => 1,
    };
    return KitScaffold(
      header: const KitHeader(title: 'Order'),
      bottom: [
        if (o.step == OrderStep.packing)
          KitButton(
            label: 'Cancel order',
            style: KitButtonStyle.dangerOutline,
            onPressed: () => context.push(Routes.orderCancel(o.id)),
          )
        else if (o.step == OrderStep.shipped)
          KitButton(
            label: 'Confirm received',
            onPressed: () async {
              await ref.read(shopRepositoryProvider).confirmReceived(o.id);
              refreshShop(ref.invalidate);
            },
          )
        else if (o.step == OrderStep.cancelled)
          KitButton(
            label: 'Refund status',
            onPressed: () => context.push(Routes.refund(o.id)),
          ),
      ],
      children: [
        KitTitle(
          o.step == OrderStep.cancelled
              ? 'Cancelled'
              : o.service
              ? 'Booked'
              : (o.arrives != null && o.step != OrderStep.delivered
                    ? 'Arrives ${Fmt.day(o.arrives!)}'
                    : o.step.label),
          lead: o.booking ?? o.step.label,
        ),
        if (!o.service && o.step != OrderStep.cancelled)
          KitCard(
            padding: const EdgeInsets.all(14),
            children: [
              Column(
                children: [
                  for (final (i, (title, sub)) in steps.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i < reached ? c.primary : t.tag,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: OgText.body(
                                12,
                                weight: FontWeight.w800,
                                color: i < reached ? c.onPrimary : t.onTag,
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
                                  style: OgText.body(
                                    14,
                                    weight: FontWeight.w700,
                                    color: i < reached ? c.text : c.textMuted,
                                  ),
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
        Text(o.mallName, style: OgText.heading(20)),
        KitCard(
          children: [
            for (final l in o.lines)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.name,
                            style: OgText.body(14, weight: FontWeight.w700),
                          ),
                          Text(
                            [
                              if (l.variant.isNotEmpty) l.variant,
                              'qty ${l.qty}',
                            ].join(', '),
                            style: OgText.body(12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      cash(l.priceCents * l.qty),
                      style: OgText.body(14, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Column(
          children: [
            KitKeyValue('Items', cash(o.itemsCents)),
            if (o.voucherCents > 0)
              KitKeyValue('Voucher', '−${cash(o.voucherCents)}'),
            if (!o.service)
              KitKeyValue(
                'Delivery',
                o.deliveryCents == 0 ? 'Free' : cash(o.deliveryCents),
              ),
            if (o.pointsCents > 0)
              KitKeyValue('Points used', '−${cash(o.pointsCents)}'),
            KitKeyValue(
              o.paidWith == 'Pay the shop'
                  ? (o.step == OrderStep.delivered
                        ? 'Paid to the shop'
                        : 'To pay the shop')
                  : 'Paid with ${o.paidWith}',
              cash(o.totalCents),
            ),
            if (o.address != null)
              KitKeyValue(
                o.address!.pickup ? 'Pick up' : 'Deliver to ${o.address!.name}',
                o.address!.line,
              ),
          ],
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.chatRound,
              title: 'Chat with ${o.mallName}',
              onTap: () => o.ownerId.isEmpty
                  ? showOgToast(context, 'Shop chat opens with the Shop.')
                  : context.push(Routes.messagePlayer(o.ownerId)),
            ),
            if (o.step == OrderStep.delivered && !o.reviewed)
              KitNavTile(
                icon: OgIcons.star,
                title: 'Write a review',
                subtitle: 'Help other players pick the right gear',
                onTap: () => context.push(Routes.orderReview(o.id)),
              ),
            if (o.returnState case final state?)
              KitNavTile(
                icon: OgIcons.leave,
                title: switch (state) {
                  'accepted' => 'Return accepted',
                  'declined' => 'Return declined',
                  _ => 'Return requested',
                },
                subtitle: state == 'requested'
                    ? '${o.returnReason ?? ''}. ${o.mallName} answers within 2 working days'
                    : o.returnReason,
                onTap: () {},
              )
            else if (o.step == OrderStep.delivered && !o.service)
              KitNavTile(
                icon: OgIcons.leave,
                title: 'Return or refund',
                subtitle: 'Within 7 days, unused',
                onTap: () => context.push(Routes.orderReturn(o.id)),
              ),
            KitNavTile(
              icon: OgIcons.flag,
              title: 'Report this order',
              onTap: () =>
                  context.push(Routes.reportListing('Order: ${o.summary}')),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cancel before it ships: why, and where the refund goes.
class OrderCancelScreen extends ConsumerStatefulWidget {
  const OrderCancelScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<OrderCancelScreen> createState() => _OrderCancelScreenState();
}

class _OrderCancelScreenState extends ConsumerState<OrderCancelScreen> {
  String? _why;
  bool _toWallet = true;
  bool _busy = false;
  int? _done;

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      final back = await ref
          .read(shopRepositoryProvider)
          .cancelOrder(widget.id, reason: _why!, toWallet: _toWallet);
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
      refreshWallet(ref.invalidate);
      if (mounted) setState(() => _done = back);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final o = ref.watch(orderDetailProvider(widget.id)).value;
    if (_done case final back?) {
      return KitScaffold(
        header: const KitHeader(title: 'Cancel order'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          if (!Env.hasSupabase)
            KitButton(
              label: 'Track the refund',
              onPressed: () =>
                  context.pushReplacement(Routes.refund(widget.id)),
            ),
          KitButton(
            label: 'Back to my orders',
            style: Env.hasSupabase
                ? KitButtonStyle.primary
                : KitButtonStyle.outline,
            onPressed: () => context.go(Routes.orders()),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Cancelled'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              Env.hasSupabase
                  ? 'Nothing was charged, so there is nothing to refund. The shop has been told.'
                  : '${cash(back)} refunded. It goes to ${_toWallet ? 'your Wallet, now' : 'your card, in 3 to 5 working days'}. Points you used are back in your wallet.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    if (o == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Cancel order'),
        children: [CupertinoActivityIndicator()],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Cancel order'),
      bottom: [
        KitButton(
          label: _why == null ? 'Pick a reason' : 'Cancel order',
          style: KitButtonStyle.danger,
          loading: _busy,
          onPressed: _why == null ? null : _cancel,
        ),
      ],
      children: [
        KitCard(
          children: [
            MoneyLine(
              title: o.summary,
              sub: '${o.mallName} · being packed',
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
              'Delivery takes too long',
              'Changed my mind',
            ])
              KitChoiceRow(
                title: r,
                selected: _why == r,
                onTap: () => setState(() => _why = r),
              ),
          ],
        ),
        if (Env.hasSupabase)
          Text(
            'You pay the shop on delivery or pickup, so nothing has been '
            'charged. You can cancel free until the shop ships.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          )
        else ...[
          Text('Where should the refund go?', style: OgText.heading(20)),
          KitChoiceRow(
            title: 'Wallet',
            subtitle: '${cash(o.totalCents)} · instant',
            selected: _toWallet,
            onTap: () => setState(() => _toWallet = true),
          ),
          KitChoiceRow(
            title: 'Card ending 4242',
            subtitle: '${cash(o.totalCents)} · 3 to 5 working days',
            selected: !_toWallet,
            onTap: () => setState(() => _toWallet = false),
          ),
          Text(
            'You can cancel free until the shop ships. Shop orders have no '
            'platform fee, so you get all of it back either way.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
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
              Text(title, style: OgText.body(15, weight: FontWeight.w700)),
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
    final o = ref.watch(orderDetailProvider(id)).value;
    if (o == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Refund'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final wallet = o.refundTo == 'Wallet';
    final steps = [
      ('Order cancelled', 'Today'),
      ('Refund approved', 'Automatic before shipping'),
      ('Sent to ${wallet ? 'your Wallet' : 'your card'}', 'Today'),
      (
        'In your account',
        wallet ? 'Already there' : 'Card refunds take 3 to 5 working days',
      ),
    ];
    final done = wallet ? 4 : 3;
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
          wallet ? 'Refunded' : 'On its way',
          lead: '${cash(o.refundCents)} · ${o.summary} · ${o.mallName}',
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
                              weight: FontWeight.w800,
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
                                style: OgText.body(14, weight: FontWeight.w700),
                              ),
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
        KitKeyValue('To', o.refundTo ?? 'Card'),
        if (o.pointsCents > 0)
          KitKeyValue(
            'Points returned',
            '${(o.pointsCents / 100).toStringAsFixed(1)}, already in your wallet',
          ),
        KitKeyValue('Reference', 'RF-${o.id.toUpperCase()}'),
        Text(
          'Wallet refunds are instant. Card and PayNow refunds depend on your bank.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Report a listing, shop, review or order.
class ReportListingScreen extends ConsumerStatefulWidget {
  const ReportListingScreen({super.key, required this.what});

  /// "Listing: Carbon racket 4U".
  final String what;

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
  bool _hide = true;
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
          .report(widget.what, reason: _why!, note: _note.text.trim());
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
    final parts = widget.what.split(': ');
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
          children: [
            MoneyLine(
              title: parts.length > 1 ? parts[1] : widget.what,
              sub: parts.length > 1 ? parts[0] : 'Report',
              amount: '',
            ),
          ],
        ),
        Text('What is wrong with it?', style: OgText.heading(20)),
        Text(
          'Reports are private. The seller is not told who reported.',
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
        SwitchRow(
          compact: true,
          title: 'Hide this from me now',
          subtitle: 'You won’t see it while we review',
          value: _hide,
          onChanged: (v) => setState(() => _hide = v),
        ),
        if (_why != null && _reasons.any((r) => r.$1 == _why && r.$3))
          KitNote('Urgent reports are reviewed first.', tone: KitTone.warn),
      ],
    );
  }
}

/// Rate a delivered order: stars, what stood out, and a few words.
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
    'Fast delivery',
    'Well packed',
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
      refreshShop(ref.invalidate);
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
                      style: OgText.body(15, weight: FontWeight.w700),
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

/// Ask the shop to take a delivered item back.
class ReturnRequestScreen extends ConsumerStatefulWidget {
  const ReturnRequestScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReturnRequestScreen> createState() =>
      _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  static const _reasons = [
    ('Wrong size', 'Too small or too big'),
    ('Damaged or faulty', 'Arrived broken or does not work'),
    ('Not as described', 'Different from the photos or details'),
    ('Changed my mind', 'Item is unused'),
  ];
  static const _wants = ['Refund', 'Exchange for another size'];

  String? _why;
  String _want = _wants.first;
  bool _busy = false;
  bool _sent = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .requestReturn(widget.id, reason: _why!, want: _want);
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
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
    final o = ref.watch(orderDetailProvider(widget.id)).value;
    if (_sent) {
      return KitScaffold(
        header: const KitHeader(title: 'Return an item'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to my orders',
            onPressed: () => context.go(Routes.orders()),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Request sent'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  o == null ? _want : '$_want, ${cash(o.itemsCents)}',
                  style: OgText.heading(26),
                ),
                const SizedBox(height: 4),
                Text(
                  '${o?.mallName ?? 'The shop'} answers within 2 working days '
                  'and arranges the return with you.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final deadline = o == null
        ? null
        : (o.deliveredAt ?? o.arrives ?? o.placedAt).add(
            const Duration(days: 7),
          );
    return KitScaffold(
      header: const KitHeader(title: 'Return an item'),
      bottom: [
        KitButton(
          label: _why == null ? 'Pick a reason' : 'Send return request',
          loading: _busy,
          onPressed: _why == null ? null : _send,
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
                      style: OgText.body(15, weight: FontWeight.w700),
                    ),
                    Text(
                      o.mallName,
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Text(cash(o.itemsCents), style: OgText.heading(20)),
            ],
          ),
        Text('Why are you returning it?', style: OgText.heading(20)),
        Column(
          children: [
            for (final (title, sub) in _reasons)
              KitChoiceRow(
                title: title,
                subtitle: sub,
                selected: _why == title,
                onTap: () => setState(() => _why = title),
              ),
          ],
        ),
        Text('What would you like?', style: OgText.heading(20)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in _wants)
              KitChip(
                label: w,
                selected: _want == w,
                onTap: () => setState(() => _want = w),
              ),
          ],
        ),
        KitNote(
          '${o?.mallName ?? 'The shop'} accepts returns within 7 days if the '
          'item is unused${deadline == null ? '' : '. You have until ${Fmt.day(deadline)}'}. '
          '${Env.hasSupabase ? 'You paid the shop directly, so it refunds you directly.' : 'Points you used come back to your wallet.'}',
          tone: KitTone.warn,
        ),
      ],
    );
  }
}
