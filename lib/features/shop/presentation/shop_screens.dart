import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart' show pointsText;

import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../earnings/application/earnings_providers.dart';
import '../../earnings/presentation/earnings_screens.dart' show cash;
import '../application/shop_providers.dart';
import '../domain/commerce_models.dart';
import '../domain/shop_models.dart';

/// A spinner, or what went wrong with a way to try again, until there's data.
Widget? shopWaiting(AsyncValue<Object?> v, String title, VoidCallback retry) {
  if (v.hasValue) return null;
  return KitScaffold(
    header: KitHeader(title: title),
    children: v.hasError
        ? [
            const KitNote(
              'Can’t load this right now. Check your connection.',
              tone: KitTone.warn,
            ),
            KitButton(label: 'Try again', onPressed: retry),
          ]
        : const [CupertinoActivityIndicator()],
  );
}

/// "1.2k".
String compact(int n) =>
    n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k' : '$n';

/// The cart icon with a count, for shop headers.
class CartButton extends ConsumerWidget {
  const CartButton({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(cartProvider).value?.fold(0, (a, l) => a + l.qty) ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        KitIconButton(
          icon: OgIcons.cart,
          label: n == 0 ? 'Cart' : 'Cart, $n items',
          color: light ? const Color(0xFFFFFFFF) : null,
          background: light ? const Color(0x38FFFFFF) : null,
          onPressed: () => context.push(Routes.cart),
        ),
        if (n > 0)
          Positioned(right: -2, top: -2, child: KitCountBadge(n, size: 20)),
      ],
    );
  }
}

/// The product picture: an icon on a tint until photos are uploaded.
class ProductArtBox extends StatelessWidget {
  const ProductArtBox({
    super.key,
    required this.product,
    this.height = 120,
    this.radius = 14,
  });

  final Product product;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (product.mallId) {
      'm-racket' => (const Color(0xFFE3ECF3), const Color(0xFF2F3A5F)),
      'm-footwork' => (const Color(0xFFDCEEE6), const Color(0xFF0A4F3A)),
      _ => (const Color(0xFFFBE7B0), const Color(0xFF5A4300)),
    };
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: OgIcon(
        product.service
            ? OgIcons.racquetStrings
            : product.art == ProductArt.racquet
            ? OgIcons.racquet
            : OgIcons.bag,
        size: height * 0.36,
        color: fg,
      ),
    );
  }
}

/// A product in a grid: picture, deal, price, sold and points.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final p = product;
    return Pressable(
      semanticLabel: '${p.name}, ${cash(p.priceCents)}',
      onPressed: () => context.push(Routes.product(p.id)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProductArtBox(product: p),
                if (p.deal != null)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: KitTag(
                      p.deal!,
                      height: 22,
                      background: const Color(0xFFD2342C),
                      foreground: const Color(0xFFFFFFFF),
                    ),
                  ),
                if (!p.service && p.stock == 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: KitTag(
                      'Sold out',
                      height: 22,
                      background: OgColors.ink,
                      foreground: const Color(0xFFFFFFFF),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.type.body.copyWith(height: 1.25),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(cash(p.priceCents), style: context.type.section),
                if (p.oldPriceCents != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      cash(p.oldPriceCents!),
                      overflow: TextOverflow.ellipsis,
                      style: context.type.caption.copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(p.soldLine, style: context.type.caption),
            if (p.pointsCapCents > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: KitTag(
                  'Up to ${pointsText(p.pointsCapCents)} pts off',
                  height: 22,
                  background: t.successFill,
                  foreground: t.onSuccessFill,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Two products a row.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < products.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: ProductTile(product: products[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < products.length
                      ? ProductTile(product: products[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

/// Options, quantity, then Add to cart or Buy now.
Future<void> showBuySheet(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  List<OptionGroup> options = const [],
  bool buyNow = false,
  int? priceCents,
}) => showKitSheet<void>(
  context,
  builder: (_) => _BuySheet(product: product, options: options, buyNow: buyNow),
);

class _BuySheet extends ConsumerStatefulWidget {
  const _BuySheet({
    required this.product,
    required this.options,
    required this.buyNow,
  });

  final Product product;
  final List<OptionGroup> options;
  final bool buyNow;

  @override
  ConsumerState<_BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends ConsumerState<_BuySheet> {
  late final _picked = [for (final g in widget.options) g.values.first];
  int _qty = 1;

  String get _variant => _picked.join(', ');

  Future<void> _go(bool buy) async {
    final p = widget.product;
    final nav = Navigator.of(context);
    final outer = Navigator.of(context, rootNavigator: true).context;
    if (buy) {
      nav.pop();
      outer.push(
        Routes.checkout(p.mallId),
        extra: CartLine(id: 'now', product: p, variant: _variant, qty: _qty),
      );
      return;
    }
    try {
      await ref
          .read(shopRepositoryProvider)
          .addToCart(p.id, variant: _variant, qty: _qty);
      HapticFeedback.mediumImpact();
      ref.invalidate(cartProvider);
      nav.pop();
      if (outer.mounted) showOgToast(outer, 'Added to cart');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final price = p.priceCents;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(width: 72, child: ProductArtBox(product: p, height: 72)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cash(price * _qty), style: context.type.score),
                    Text(p.name, style: context.type.body),
                    if (_variant.isNotEmpty)
                      Text(_variant, style: context.type.caption),
                  ],
                ),
              ),
            ],
          ),
          for (final (gi, g) in widget.options.indexed) ...[
            const SizedBox(height: 14),
            Text(g.title, style: context.type.body),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in g.values)
                  KitChip(
                    label: v,
                    selected: _picked[gi] == v,
                    onTap: () => setState(() => _picked[gi] = v),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Quantity', style: context.type.body)),
              KitQty(
                value: _qty,
                onLess: _qty <= 1 ? null : () => setState(() => _qty--),
                onMore: !p.service && _qty >= p.stock
                    ? null
                    : () => setState(() => _qty++),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: KitButton(
                  label: 'Add to cart',
                  style: KitButtonStyle.outline,
                  onPressed: () => _go(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KitButton(label: 'Buy now', onPressed: () => _go(true)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shop: deals, services and partner shops.
class ShopHomeScreen extends ConsumerStatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  ConsumerState<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends ConsumerState<ShopHomeScreen> {
  int _tab = 0;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final loading = ref.watch(shopProductsProvider(null, _q));
    final products = loading.value;
    final deals = ref.watch(shopDealsProvider).value ?? const [];
    final malls = ref.watch(mallsProvider).value ?? const [];
    final searching = _q.trim().isNotEmpty;
    return KitScaffold(
      header: KitHeader(
        title: 'Shop',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KitIconButton(
              icon: OgIcons.clipboardList,
              label: 'My orders',
              onPressed: () => context.push(Routes.orders()),
            ),
            const CartButton(),
          ],
        ),
      ),
      children: [
        KitSearchField(
          hint: 'Search products, brands and shops',
          onChanged: (v) => setState(() => _q = v),
        ),
        if (searching) ...[
          if (loading.hasError)
            const _ShopEmpty('Can’t search right now. Check your connection.')
          else if (products == null)
            const CupertinoActivityIndicator()
          else if (products.isEmpty)
            DashedBox(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Nothing matches. Try a product type, a brand or a shop name.',
                  style: context.type.secondary,
                ),
              ),
            )
          else
            ProductGrid(products: products),
        ] else ...[
          KitUnderlineTabs(
            labels: const ['For you', 'Services', 'Shops'],
            selected: _tab,
            padding: EdgeInsets.zero,
            onSelect: (i) => setState(() => _tab = i),
          ),
          ...switch (_tab) {
            0 => [
              if (deals.isNotEmpty) ...[
                Text('Flash deals', style: context.type.section),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, d) in deals.indexed) ...[
                        if (i > 0) const SizedBox(width: 10),
                        SizedBox(width: 160, child: ProductTile(product: d)),
                      ],
                    ],
                  ),
                ),
              ],
              Text('For you', style: context.type.section),
              if (loading.hasError)
                const _ShopEmpty('Can’t load the Shop. Check your connection.')
              else if (products == null)
                const CupertinoActivityIndicator()
              else if (products.where((p) => !p.service).isEmpty)
                const _ShopEmpty(
                  'Nothing for sale yet. Partner shops open soon.',
                )
              else
                ProductGrid(
                  products: products.where((p) => !p.service).toList(),
                ),
            ],
            1 => [
              if (loading.hasError)
                const _ShopEmpty('Can’t load services. Check your connection.'),
              if (products != null && !products.any((p) => p.service))
                const _ShopEmpty('No services yet.'),
              if (products != null)
                for (final p in products.where((p) => p.service))
                  KitCard(
                    children: [
                      KitNavTile(
                        icon: OgIcons.racquetStrings,
                        title: p.name,
                        subtitle:
                            '${p.mallName} · ${cash(p.priceCents)} · ${p.soldLine}',
                        onTap: () => context.push(Routes.serviceBook(p.id)),
                      ),
                    ],
                  ),
            ],
            _ => [
              if (malls.isEmpty) const _ShopEmpty('No shops yet.'),
              KitCard(
                children: [
                  for (final m in malls)
                    Pressable(
                      semanticLabel: m.name,
                      onPressed: () => context.push(Routes.mallPage(m.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ClubLogo(
                              initials: m.initials,
                              color: Color(m.color),
                              ink: Color(m.ink),
                              size: 48,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: context.type.body),
                                  Text(m.blurb, style: context.type.caption),
                                ],
                              ),
                            ),
                            if (m.pointsAccepted)
                              KitTag(
                                'Points',
                                background: t.successFill,
                                foreground: t.onSuccessFill,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          },
        ],
      ],
    );
  }
}

/// A shop's page: follow, products and about.
class MallPageScreen extends ConsumerStatefulWidget {
  const MallPageScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MallPageScreen> createState() => _MallPageScreenState();
}

class _MallPageScreenState extends ConsumerState<MallPageScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final d = ref.watch(mallDetailProvider(widget.id)).value;
    if (d == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Shop'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final m = d.mall;
    Crumbs.name(context, m.name);
    Widget stat(String big, String small) => Expanded(
      child: Column(
        children: [
          Text(big, style: context.type.section),
          Text(small, style: context.type.caption),
        ],
      ),
    );
    return KitScaffold(
      header: KitHeader(title: m.name, trailing: const CartButton()),
      children: [
        Row(
          children: [
            ClubLogo(
              initials: m.initials,
              color: Color(m.color),
              ink: Color(m.ink),
              size: 64,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(m.name, style: context.type.section),
                      ),
                      const SizedBox(width: 6),
                      if (d.verified)
                        KitTag(
                          'Verified',
                          height: 22,
                          background: t.successFill,
                          foreground: t.onSuccessFill,
                        ),
                    ],
                  ),
                  Text(
                    d.about,
                    style: context.type.caption.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            stat(d.rating.toStringAsFixed(1), '${compact(d.ratings)} ratings'),
            stat(compact(d.followers), 'followers'),
            stat(d.replyTime, 'reply time'),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: KitButton(
                label: d.following ? 'Following' : 'Follow',
                style: d.following
                    ? KitButtonStyle.outline
                    : KitButtonStyle.primary,
                height: 46,
                onPressed: () async {
                  try {
                    await ref
                        .read(shopRepositoryProvider)
                        .follow(m.id, !d.following);
                    ref.invalidate(mallDetailProvider(m.id));
                  } on AuthFailure catch (e) {
                    if (context.mounted) {
                      showOgToast(context, e.message, error: true);
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KitButton(
                label: 'Chat',
                style: KitButtonStyle.outline,
                height: 46,
                onPressed: () => m.ownerId.isEmpty
                    ? showOgToast(context, 'This shop can’t be messaged yet.')
                    : context.push(Routes.messagePlayer(m.ownerId)),
              ),
            ),
          ],
        ),
        KitUnderlineTabs(
          labels: const ['Products', 'About'],
          selected: _tab,
          spread: true,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = i),
        ),
        ...switch (_tab) {
          0 => [ProductGrid(products: d.products)],
          _ => [
            Column(children: [for (final (k, v) in d.facts) KitKeyValue(k, v)]),
            if (m.pointsAccepted)
              const KitNote(
                'Points are accepted on every item here. Each item shows how many points it can take.',
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: KitLink(
                'Get help with this shop',
                color: c.textMuted,
                onPressed: () => context.push(Routes.help),
              ),
            ),
          ],
        },
      ],
    );
  }
}

/// A product: price, points, options, reviews.
class ProductPageScreen extends ConsumerWidget {
  const ProductPageScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final d = ref.watch(productDetailProvider(id));
    final points = ref.watch(pointsSummaryProvider).value?.minor ?? 0;
    final value = d.value;
    if (value == null) {
      return KitScaffold(
        header: const KitHeader(title: 'Product'),
        children: [
          if (d.hasError)
            KitNote(
              d.error is AuthFailure
                  ? (d.error! as AuthFailure).message
                  : 'This item is no longer listed.',
              tone: KitTone.warn,
            )
          else
            const CupertinoActivityIndicator(),
        ],
      );
    }
    final p = value.product;
    final soldOut = !p.service && p.stock == 0;
    Crumbs.name(context, p.name);
    return KitScaffold(
      header: const KitHeader(title: 'Product', trailing: CartButton()),
      bottom: [
        Row(
          children: [
            if (!p.service) ...[
              Expanded(
                child: KitButton(
                  label: 'Add to cart',
                  style: KitButtonStyle.outline,
                  onPressed: soldOut
                      ? null
                      : () => showBuySheet(
                          context,
                          ref,
                          p,
                          options: value.options,
                        ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: KitButton(
                label: soldOut ? 'Sold out' : (p.service ? 'Book' : 'Buy now'),
                onPressed: soldOut
                    ? null
                    : p.service
                    ? () => context.push(Routes.serviceBook(p.id))
                    : () => showBuySheet(
                        context,
                        ref,
                        p,
                        options: value.options,
                        buyNow: true,
                      ),
              ),
            ),
          ],
        ),
      ],
      children: [
        ProductArtBox(product: p, height: 260, radius: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(cash(p.priceCents), style: context.type.score),
            if (p.deal case final deal?) ...[
              const SizedBox(width: 8),
              Text(
                cash(p.oldPriceCents!),
                style: context.type.secondary.copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              KitTag(
                deal,
                background: const Color(0xFFD2342C),
                foreground: const Color(0xFFFFFFFF),
              ),
            ],
          ],
        ),
        Text(value.headline, style: context.type.section.copyWith(height: 1.2)),
        Text(
          value.ratings == 0 && p.sold == 0
              ? 'New in the Shop'
              : value.ratings == 0
              ? '${compact(p.sold)} sold'
              : '${p.rating.toStringAsFixed(1)} · from ${compact(value.ratings)} ${value.ratings == 1 ? 'rating' : 'ratings'}, ${compact(p.sold)} sold',
          style: context.type.secondary,
        ),
        if (p.pointsCapCents > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.successFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                OgIcon(OgIcons.pointsStar, size: 22, color: t.onSuccessFill),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use up to ${pointsText(p.pointsCapCents)} points here. You have ${pointsText(points)}.',
                    style: context.type.body.copyWith(color: t.onSuccessFill),
                  ),
                ),
              ],
            ),
          ),
        Text(value.collectLine, style: context.type.secondary),
        if (value.options.isNotEmpty && !p.service && !soldOut)
          KitCard(
            children: [
              KitNavTile(
                icon: OgIcons.sliders,
                title: 'Options',
                subtitle: value.options
                    .map((g) => g.values.join(' / '))
                    .join(' · '),
                onTap: () =>
                    showBuySheet(context, ref, p, options: value.options),
              ),
            ],
          ),
        Text('About this item', style: context.type.section),
        KitCheckList(value.about),
        Row(
          children: [
            Expanded(child: Text('Reviews', style: context.type.section)),
            Text('All ${compact(value.ratings)}', style: context.type.caption),
          ],
        ),
        for (final r in value.reviews)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SolidAvatar.forId(
                r.name,
                initials: r.name.split(' ').map((w) => w[0]).take(2).join(),
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: context.type.body),
                    Text(r.meta, style: context.type.caption),
                    const SizedBox(height: 4),
                    Text(
                      r.text,
                      style: context.type.body.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.bag,
              title: p.mallName,
              subtitle: 'About the shop and where to collect',
              onTap: () => context.push(Routes.mallPage(p.mallId)),
            ),
          ],
        ),
        if (value.related.isNotEmpty) ...[
          Text('Goes well with', style: context.type.section),
          ProductGrid(products: value.related),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: KitLink(
            'Report this listing',
            color: c.textMuted,
            onPressed: () => context.push(Routes.reportListing(p.id, p.name)),
          ),
        ),
      ],
    );
  }
}

/// A service: tension and a drop-off time, then checkout.
class ServiceBookScreen extends ConsumerStatefulWidget {
  const ServiceBookScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ServiceBookScreen> createState() => _ServiceBookScreenState();
}

class _ServiceBookScreenState extends ConsumerState<ServiceBookScreen> {
  String _tension = '24 lb';
  int _day = 0;
  (int, int, String)? _time;

  static const _times = [
    (10, 0, '10:00 AM'),
    (12, 0, '12:00 PM'),
    (15, 0, '3:00 PM'),
    (18, 0, '6:00 PM'),
  ];

  List<DateTime> get _days {
    final now = DateTime.now();
    return [
      for (var i = 1; i <= 4; i++) DateTime(now.year, now.month, now.day + i),
    ];
  }

  String _dayLabel(DateTime d) =>
      '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} ${d.day}';

  void _book(Product p) {
    final (hour, minute, _) = _time!;
    final day = _days[_day];
    context.push(
      Routes.checkout(p.mallId),
      extra: CartLine(
        id: 'now',
        product: p,
        variant: _tension,
        slot: DateTime(day.year, day.month, day.day, hour, minute),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.id));
    if (shopWaiting(
          detail,
          'Book a service',
          () => ref.invalidate(productDetailProvider(widget.id)),
        )
        case final waiting?) {
      return waiting;
    }
    final d = detail.requireValue;
    final p = d.product;
    return KitScaffold(
      header: const KitHeader(title: 'Book a service'),
      bottom: [
        KitButton(
          label: _time == null ? 'Pick a time' : 'Continue',
          onPressed: _time == null ? null : () => _book(p),
        ),
      ],
      children: [
        Row(
          children: [
            SizedBox(width: 64, child: ProductArtBox(product: p, height: 64)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: context.type.section),
                  Text(
                    '${p.mallName} · ${p.rating.toStringAsFixed(1)} from ${compact(d.ratings)} reviews',
                    style: context.type.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        Text('String tension', style: context.type.section),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in const ['22 lb', '24 lb', '26 lb', '28 lb'])
              KitChip(
                label: s,
                selected: _tension == s,
                onTap: () => setState(() => _tension = s),
              ),
          ],
        ),
        Text('Drop-off day', style: context.type.section),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, day) in _days.indexed)
              KitChip(
                label: _dayLabel(day),
                selected: _day == i,
                onTap: () => setState(() => _day = i),
              ),
          ],
        ),
        Text('Drop-off time', style: context.type.section),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _times)
              KitChip(
                label: t.$3,
                selected: _time == t,
                onTap: () => setState(() => _time = t),
              ),
          ],
        ),
        KitKeyValue('Where', p.mallName),
        KitKeyValue(
          'Price',
          '${cash(p.priceCents)}, no platform fee for the buyer',
        ),
        Text(
          'Pay now. OlympusGO holds your payment until you collect your '
          'racket, and you can cancel until the shop starts work.',
          style: context.type.caption.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _ShopEmpty extends StatelessWidget {
  const _ShopEmpty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => DashedBox(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(text, style: context.type.secondary),
    ),
  );
}
