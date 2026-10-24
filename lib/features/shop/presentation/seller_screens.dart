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
import '../../wallet/presentation/wallet_screens.dart' show cash, cashShort;
import '../application/shop_providers.dart';
import '../domain/commerce_models.dart';
import '../domain/shop_models.dart';
import 'shop_screens.dart' show ProductArtBox;

/// The seller's dashboard.
class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final s = ref.watch(sellerSummaryProvider);
    final v = s.value;
    if (s.hasValue && v == null) return const _OpenShop();
    if (v == null) {
      return KitScaffold(
        header: const KitHeader(title: 'My shop'),
        children: [
          if (s.hasError)
            KitNote(
              s.error is AuthFailure
                  ? (s.error! as AuthFailure).message
                  : 'Couldn’t load your shop.',
              tone: KitTone.warn,
            )
          else
            const CupertinoActivityIndicator(),
        ],
      );
    }
    final m = v.mall;
    Widget stat(String big, String small) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: t.tag,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(big, style: OgText.heading(22)),
            Text(small, style: OgText.body(12, color: t.onTag)),
          ],
        ),
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'My shop'),
      children: [
        Row(
          children: [
            ClubLogo(
              initials: m.initials,
              color: Color(m.color),
              ink: Color(m.ink),
              size: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: OgText.heading(22)),
                  Text(
                    Env.hasSupabase
                        ? 'Buyers pay you on delivery or pickup'
                        : 'Verified shop · 4.8 from 1.2k reviews',
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            stat(cashShort(v.salesTodayCents), 'sales today'),
            const SizedBox(width: 8),
            stat('${v.toShip}', 'to ship'),
            const SizedBox(width: 8),
            stat('${v.returns}', 'returns'),
          ],
        ),
        if (!Env.hasSupabase)
          Row(
            children: [
              Expanded(
                child: KitButton(
                  label: 'Go live',
                  icon: OgIcons.megaphone,
                  onPressed: () => context.push(Routes.sellerLive),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KitButton(
                  label: 'Post a video',
                  style: KitButtonStyle.outline,
                  onPressed: () => context.push(Routes.sellerVideo),
                ),
              ),
            ],
          ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.clipboardList,
              title: 'Orders',
              subtitle: '${v.toShip} to ship, ${v.onTheWay} on the way',
              onTap: () => context.push(Routes.sellerOrders),
            ),
            KitNavTile(
              icon: OgIcons.bag,
              title: 'Products',
              subtitle:
                  '${v.listed} listed${v.lowStock > 0 ? ', ${v.lowStock} low on stock' : ''}',
              onTap: () => context.push(Routes.sellerProducts),
            ),
            KitNavTile(
              icon: OgIcons.plus,
              title: 'Add a product',
              subtitle: 'Photos, price, stock, points',
              onTap: () => context.push(Routes.sellerProduct('new')),
            ),
            if (!Env.hasSupabase) ...[
              KitNavTile(
                icon: OgIcons.ticket,
                title: 'Vouchers',
                subtitle: '1 running: ${v.voucher}',
                onTap: () =>
                    showOgToast(context, 'Voucher editing comes next.'),
              ),
              KitNavTile(
                icon: OgIcons.walletCard,
                title: 'Earnings and payouts',
                subtitle: '${cashShort(v.readyCents)} ready',
                onTap: () => context.push(Routes.earnings),
              ),
            ],
          ],
        ),
        Env.hasSupabase
            ? const KitNote(
                'Card payments are off for now. Buyers pay you directly when '
                'their order arrives or when they collect it. Mark each order '
                'shipped so they know it is coming.',
                tone: KitTone.info,
              )
            : const KitNote(
                'Shoppable videos bring 62% of your sales. Shops that go live '
                'weekly sell about twice as much.',
                tone: KitTone.info,
              ),
      ],
    );
  }
}

/// Opens the player's shop: a name, a line about it and where it ships
/// from.
class _OpenShop extends ConsumerStatefulWidget {
  const _OpenShop();

  @override
  ConsumerState<_OpenShop> createState() => _OpenShopState();
}

class _OpenShopState extends ConsumerState<_OpenShop> {
  final _name = TextEditingController();
  final _blurb = TextEditingController();
  final _about = TextEditingController();
  final _from = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _blurb, _about, _from]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _open() async {
    if (_name.text.trim().length < 2) {
      showOgToast(context, 'Give your shop a name.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .openShop(
            name: _name.text.trim(),
            blurb: _blurb.text.trim(),
            about: _about.text.trim(),
            shipsFrom: _from.text.trim(),
          );
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => KitScaffold(
    header: const KitHeader(title: 'Open a shop'),
    bottom: [
      KitButton(label: 'Open my shop', loading: _busy, onPressed: _open),
    ],
    children: [
      const KitTitle(
        'Sell to players',
        lead:
            'List gear or services like restringing. Buyers order in the app '
            'and pay you directly on delivery or pickup.',
      ),
      KitInput(label: 'Shop name', controller: _name, maxLength: 40),
      KitInput(
        label: 'What you sell',
        hint: 'Rackets and restringing',
        controller: _blurb,
        maxLength: 80,
      ),
      KitInput(
        label: 'Ships from',
        hint: 'Tampines, Singapore',
        controller: _from,
        maxLength: 80,
      ),
      KitTextArea(
        label: 'About your shop',
        optional: true,
        controller: _about,
        lines: 4,
      ),
      const KitNote(
        'Sell only things you own and can deliver. Shops that break the '
        'community rules are closed.',
      ),
    ],
  );
}

/// Orders by step.
class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final all = ref.watch(sellerOrdersProvider).value;
    final shown = (all ?? const <Order>[])
        .where(
          (o) => switch (_tab) {
            0 => o.step == OrderStep.packing,
            1 => o.step == OrderStep.shipped,
            _ => o.step == OrderStep.delivered || o.step == OrderStep.cancelled,
          },
        )
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Orders'),
      children: [
        KitUnderlineTabs(
          labels: const ['To ship', 'On the way', 'Done'],
          selected: _tab,
          spread: true,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = i),
        ),
        if (all == null)
          const CupertinoActivityIndicator()
        else if (shown.isEmpty)
          Text(
            'Nothing here. Orders in this step show up here.',
            style: OgText.body(14, color: c.textMuted),
          )
        else
          KitCard(
            children: [
              for (final o in shown)
                Pressable(
                  semanticLabel: '${o.buyer}, ${o.summary}',
                  onPressed: () => context.push(Routes.sellerOrder(o.id)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.buyer,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                o.summary,
                                style: OgText.body(13, color: c.textMuted),
                              ),
                              Text(
                                o.service
                                    ? 'Service booking'
                                    : '${o.step.label} · ordered ${Fmt.dayTimeComma(o.placedAt)}',
                                style: OgText.body(12, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(cash(o.itemsCents), style: OgText.heading(16)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Pack and ship one order.
class SellerOrderDetailScreen extends ConsumerStatefulWidget {
  const SellerOrderDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<SellerOrderDetailScreen> createState() =>
      _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState
    extends ConsumerState<SellerOrderDetailScreen> {
  final _tracking = TextEditingController();
  String? _courier;
  bool _busy = false;

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  Future<void> _decide(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .decideReturn(widget.id, accept: accept);
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ship({bool ready = false}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .markShipped(
            widget.id,
            courier: ready ? '' : _courier!,
            tracking: ready ? '' : _tracking.text.trim(),
          );
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
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
    if (o == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Order'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final first = o.buyer.split(' ').first;
    // Card payments are off, so buyers pay the shop in full.
    final receive = Env.hasSupabase
        ? o.itemsCents
        : o.itemsCents - shopCommission(o.itemsCents);
    final shipped = o.step != OrderStep.packing;
    final handOver = o.service || o.delivery == 'Pick up';
    return KitScaffold(
      header: const KitHeader(title: 'Order'),
      bottom: o.returnState == 'requested'
          ? [
              Text(
                'Return asked: ${o.returnReason ?? ''}',
                style: OgText.body(14, weight: FontWeight.w700),
              ),
              Row(
                children: [
                  Expanded(
                    child: KitButton(
                      label: 'Decline',
                      style: KitButtonStyle.outline,
                      onPressed: _busy ? null : () => _decide(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KitButton(
                      label: 'Accept return',
                      loading: _busy,
                      onPressed: () => _decide(true),
                    ),
                  ),
                ],
              ),
            ]
          : shipped || (o.service && !Env.hasSupabase)
          ? [KitButton(label: 'Back to orders', onPressed: () => context.pop())]
          : handOver
          ? [
              KitButton(
                label: o.service ? 'Mark as ready' : 'Ready to collect',
                loading: _busy,
                onPressed: () => _ship(ready: true),
              ),
            ]
          : [
              ListenableBuilder(
                listenable: _tracking,
                builder: (context, _) => KitButton(
                  label: _courier == null
                      ? 'Pick a courier'
                      : 'Mark as shipped',
                  loading: _busy,
                  onPressed: _courier == null || _tracking.text.trim().isEmpty
                      ? null
                      : _ship,
                ),
              ),
            ],
      children: [
        KitTitle(
          shipped
              ? 'Shipped'
              : 'Ship by ${Fmt.dayTimeComma(o.placedAt.add(const Duration(days: 1)))}',
          lead:
              '${o.buyer} · ordered ${Fmt.dayTimeComma(o.placedAt)} · ${o.delivery} delivery',
        ),
        Text(o.service ? 'Booking' : 'Pack', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final l in o.lines)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.name,
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            '${l.variant} · qty ${l.qty}',
                            style: OgText.body(13, color: c.textMuted),
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
        if (o.address != null && !o.service) ...[
          Text('Send to', style: OgText.heading(20)),
          Column(
            children: [
              KitKeyValue('Name', o.address!.name),
              KitKeyValue('Address', o.address!.line),
              if (o.address!.phone.isNotEmpty)
                KitKeyValue('Mobile', o.address!.phone),
            ],
          ),
        ],
        if (!shipped && !o.service) ...[
          KitInput(label: 'Tracking number', controller: _tracking),
          Text('Courier', style: OgText.body(15, weight: FontWeight.w700)),
          Column(
            children: [
              for (final cr in const ['Ninja Van', 'J&T Express', 'SingPost'])
                KitChoiceRow(
                  title: cr,
                  selected: _courier == cr,
                  onTap: () => setState(() => _courier = cr),
                ),
            ],
          ),
        ],
        if (shipped && o.tracking != null)
          KitNote(
            '$first is told. They see ${o.courier ?? 'the'} tracking number ${o.tracking} in My orders. You are paid when they confirm, or 7 days after delivery.',
            tone: KitTone.info,
          ),
        Column(
          children: [
            KitKeyValue(
              'Buyer paid',
              o.pointsCents > 0
                  ? '${cash(o.itemsCents + o.deliveryCents - o.pointsCents)} with ${(o.pointsCents / 100).toStringAsFixed(1)} points'
                  : cash(o.itemsCents + o.deliveryCents),
            ),
            KitKeyValue(
              'You receive',
              '${cash(receive)} after delivery is confirmed',
            ),
          ],
        ),
        KitButton(
          label: 'Message $first',
          style: KitButtonStyle.outline,
          onPressed: () =>
              showOgToast(context, 'Shop chat opens with the Shop.'),
        ),
      ],
    );
  }
}

/// The seller's products, by status.
class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  String _filter = 'All';

  static String _status(Product p) => !p.published
      ? 'Draft'
      : p.service
      ? 'Live'
      : p.stock == 0
      ? 'Sold out'
      : p.stock <= 3
      ? 'Low stock'
      : 'Live';

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final all = ref.watch(sellerProductsProvider).value;
    final shown = (all ?? const <Product>[])
        .where((p) => _filter == 'All' || _status(p) == _filter)
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Products'),
      bottom: [
        KitButton(
          label: 'Add a product',
          icon: OgIcons.plus,
          onPressed: () => context.push(Routes.sellerProduct('new')),
        ),
      ],
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in const [
                'All',
                'Live',
                'Low stock',
                'Sold out',
                'Draft',
              ]) ...[
                KitChip(
                  label: f,
                  selected: _filter == f,
                  onTap: () => setState(() => _filter = f),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (all == null)
          const CupertinoActivityIndicator()
        else
          KitCard(
            children: [
              for (final p in shown)
                Pressable(
                  semanticLabel: p.name,
                  onPressed: () => context.push(Routes.sellerProduct(p.id)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: ProductArtBox(product: p, height: 52),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                '${cash(p.priceCents)} · ${p.service ? 'service' : '${p.stock} in stock'}',
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        KitTag(
                          _status(p),
                          background: switch (_status(p)) {
                            'Live' => t.successFill,
                            'Low stock' => t.warnFill,
                            'Sold out' => t.dangerFill,
                            _ => t.tag,
                          },
                          foreground: switch (_status(p)) {
                            'Live' => t.onSuccessFill,
                            'Low stock' => t.onWarnFill,
                            'Sold out' => t.onDangerFill,
                            _ => t.onTag,
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Add or edit a product.
class SellerProductEditScreen extends ConsumerStatefulWidget {
  const SellerProductEditScreen({super.key, required this.id});

  /// "new" for a new product.
  final String id;

  @override
  ConsumerState<SellerProductEditScreen> createState() =>
      _SellerProductEditScreenState();
}

class _SellerProductEditScreenState
    extends ConsumerState<SellerProductEditScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  bool _service = false;
  int _points = 10;
  final _delivery = <String>{'Standard', 'Pick up'};
  Product? _base;
  bool _loaded = false;
  bool _busy = false;
  Product? _saved;

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _priceCents => ((double.tryParse(_price.text) ?? 0) * 100).round();

  Future<void> _save(bool publish) async {
    if (_name.text.trim().length < 3 || _priceCents <= 0) {
      showOgToast(context, 'Add a name and a price.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final base =
          _base ??
          const Product(
            id: '',
            name: '',
            mallId: '',
            mallName: '',
            priceCents: 0,
          );
      final saved = await ref
          .read(shopRepositoryProvider)
          .saveProduct(
            base.copyWith(
              name: _name.text.trim(),
              description: _desc.text.trim(),
              priceCents: _priceCents,
              stock: int.tryParse(_stock.text) ?? 0,
              service: _service,
              maxPoints: (_priceCents / 100 * _points / 100).floor(),
              published: publish,
            ),
          );
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
      if (mounted) setState(() => _saved = saved);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    if (!_loaded && widget.id != 'new') {
      final p = ref
          .watch(sellerProductsProvider)
          .value
          ?.where((p) => p.id == widget.id)
          .firstOrNull;
      if (p != null) {
        _loaded = true;
        _base = p;
        _name.text = p.name;
        _desc.text = p.description;
        _price.text = (p.priceCents / 100).toStringAsFixed(2);
        _stock.text = '${p.stock}';
        _service = p.service;
        _points = p.priceCents == 0
            ? 10
            : (p.maxPoints * 10000 / p.priceCents).round().clamp(0, 20);
      }
    }
    if (_saved case final p?) {
      return KitScaffold(
        header: const KitHeader(title: 'Product'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Post a video for it',
            onPressed: () => context.pushReplacement(Routes.sellerVideo),
          ),
          KitButton(
            label: 'Back to products',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          KitDoneBanner(title: p.published ? 'Live' : 'Saved'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              p.published
                  ? '${p.name} is live. It shows in your shop now. Tag it in a video to reach more players.'
                  : '${p.name} is saved as a draft.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    final commission = shopCommission(_priceCents);
    return KitScaffold(
      header: KitHeader(title: widget.id == 'new' ? 'New product' : 'Product'),
      bottom: [
        KitButton(
          label: 'Save and publish',
          loading: _busy,
          onPressed: () => _save(true),
        ),
        KitButton(
          label: 'Save as draft',
          style: KitButtonStyle.outline,
          onPressed: () => _save(false),
        ),
      ],
      children: [
        Text('What are you selling?', style: OgText.heading(20)),
        KitSegments(
          labels: const ['Product', 'Service'],
          selected: _service ? 1 : 0,
          onSelect: (i) => setState(() => _service = i == 1),
        ),
        DashedBox(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                OgIcon(OgIcons.plus, size: 22, color: c.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photos come with photo uploads.',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
        KitInput(label: 'Name', controller: _name, maxLength: 60),
        KitTextArea(
          label: 'Description',
          controller: _desc,
          hint: 'Head-light 4U frame for fast doubles. Strung at 24 lb.',
        ),
        Row(
          children: [
            Expanded(
              child: KitInput(
                label: 'Price (SGD)',
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (!_service) ...[
              const SizedBox(width: 10),
              Expanded(
                child: KitInput(
                  label: 'Stock',
                  controller: _stock,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ],
        ),
        Text(
          'Points buyers can use',
          style: OgText.body(15, weight: FontWeight.w700),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final p in const [0, 5, 10, 20])
              KitChip(
                label: p == 0 ? 'None' : 'Up to $p%',
                selected: _points == p,
                onTap: () => setState(() => _points = p),
              ),
          ],
        ),
        if (!_service) ...[
          Text('Delivery', style: OgText.body(15, weight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const ['Standard', 'Express', 'Pick up'])
                KitChip(
                  label: d,
                  selected: _delivery.contains(d),
                  onTap: () => setState(
                    () => _delivery.contains(d)
                        ? _delivery.remove(d)
                        : _delivery.add(d),
                  ),
                ),
            ],
          ),
        ],
        KitCard(
          padding: const EdgeInsets.all(14),
          children: [
            Column(
              children: [
                KitKeyValue(
                  'Buyer pays',
                  '${cash(_priceCents)}, no platform fee',
                ),
                KitKeyValue('Olympus commission', '8% · ${cash(commission)}'),
                KitKeyValue('You receive', cash(_priceCents - commission)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Set up a live: title, products, a live-only deal.
class SellerGoLiveScreen extends ConsumerStatefulWidget {
  const SellerGoLiveScreen({super.key});

  @override
  ConsumerState<SellerGoLiveScreen> createState() => _SellerGoLiveScreenState();
}

class _SellerGoLiveScreenState extends ConsumerState<SellerGoLiveScreen> {
  final _title = TextEditingController(text: 'Restring night');
  final _picked = <String>{};
  String _deal = 'No deal';
  bool _paid = false;
  bool _busy = false;
  bool _live = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .goLive(
            title: _title.text.trim(),
            productIds: _picked.toList(),
            deal: _deal,
          );
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _live = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final products =
        ref.watch(sellerProductsProvider).value ?? const <Product>[];
    if (_live) {
      return KitScaffold(
        header: const KitHeader(title: 'Go live'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Open my live',
            onPressed: () => context.pushReplacement(Routes.shopLive('l1')),
          ),
          KitButton(
            label: 'End and go back',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'You’re live'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '12 watching. Pin a product to put its Buy button on screen.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Go live'),
      bottom: [
        KitButton(
          label: _picked.isEmpty ? 'Pick a product' : 'Start live',
          loading: _busy,
          onPressed: _picked.isEmpty ? null : _start,
        ),
      ],
      children: [
        const KitTitle(
          'Set up your live',
          lead: 'Buyers can ask questions and buy without leaving the video.',
        ),
        KitInput(label: 'Title', controller: _title, maxLength: 60),
        Text('Products to show', style: OgText.heading(20)),
        Column(
          children: [
            for (final p in products.where((p) => p.published))
              KitChoiceRow(
                title: p.name,
                subtitle:
                    '${cash(p.priceCents)}${p.service ? '' : ' · ${p.stock} in stock'}',
                multi: true,
                selected: _picked.contains(p.id),
                onTap: () => setState(
                  () => _picked.contains(p.id)
                      ? _picked.remove(p.id)
                      : _picked.add(p.id),
                ),
              ),
          ],
        ),
        Text(
          'Live-only price',
          style: OgText.body(15, weight: FontWeight.w700),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final d in const ['No deal', '10% off', 'Free delivery'])
              KitChip(
                label: d,
                selected: _deal == d,
                onTap: () => setState(() => _deal = d),
              ),
          ],
        ),
        SwitchRow(
          compact: true,
          title: 'Paid partnership',
          subtitle: 'Shows a label to buyers',
          value: _paid,
          onChanged: (v) => setState(() => _paid = v),
        ),
        Text(
          'Check your light and sound first. Lives are saved to your shop for 30 days.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Post a shoppable video with a tagged product.
class SellerUploadVideoScreen extends ConsumerStatefulWidget {
  const SellerUploadVideoScreen({super.key});

  @override
  ConsumerState<SellerUploadVideoScreen> createState() =>
      _SellerUploadVideoScreenState();
}

class _SellerUploadVideoScreenState
    extends ConsumerState<SellerUploadVideoScreen> {
  final _caption = TextEditingController();
  String? _product;
  String _sport = 'Badminton';
  bool _paid = false;
  bool _busy = false;
  bool _posted = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .postVideo(caption: _caption.text.trim(), productId: _product!);
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _posted = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final products =
        ref.watch(sellerProductsProvider).value ?? const <Product>[];
    if (_posted) {
      return KitScaffold(
        header: const KitHeader(title: 'Post a video'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'See it in the Shop',
            onPressed: () => context.go(Routes.shop),
          ),
          KitButton(
            label: 'Back to my shop',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Posted'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your video is live. It shows in Shop, For you, and on your shop page.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Post a video'),
      bottom: [
        KitButton(
          label: _product == null ? 'Tag a product' : 'Post video',
          loading: _busy,
          onPressed: _product == null ? null : _post,
        ),
      ],
      children: [
        DashedBox(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                OgIcon(OgIcons.plus, size: 28, color: c.textMuted),
                const SizedBox(height: 6),
                Text(
                  'Pick a video. Uploads come with media support.',
                  textAlign: TextAlign.center,
                  style: OgText.body(14, color: c.textMuted),
                ),
              ],
            ),
          ),
        ),
        KitTextArea(
          label: 'Caption',
          controller: _caption,
          hint: 'Why 4U frames are faster at the net',
        ),
        Text('Tag products', style: OgText.heading(20)),
        Column(
          children: [
            for (final p in products.where((p) => p.published))
              KitChoiceRow(
                title: p.name,
                subtitle: cash(p.priceCents),
                selected: _product == p.id,
                onTap: () => setState(() => _product = p.id),
              ),
          ],
        ),
        Text('Sport', style: OgText.body(15, weight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          children: [
            for (final s in const ['Badminton', 'Pickleball', 'Tennis'])
              KitChip(
                label: s,
                selected: _sport == s,
                onTap: () => setState(() => _sport = s),
              ),
          ],
        ),
        SwitchRow(
          compact: true,
          title: 'Paid partnership',
          subtitle: 'Shows a label to viewers',
          value: _paid,
          onChanged: (v) => setState(() => _paid = v),
        ),
        Text(
          'Videos under 60 seconds with one tagged product sell best. Music must be yours to use.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}
