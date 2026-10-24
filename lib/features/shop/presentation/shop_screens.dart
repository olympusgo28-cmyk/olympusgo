import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/navigation/breadcrumbs.dart';
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
import '../../wallet/application/wallet_providers.dart';
import '../../wallet/presentation/wallet_screens.dart' show cash;
import '../application/shop_providers.dart';
import '../domain/commerce_models.dart';
import '../domain/shop_models.dart';

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
                      fontSize: 11,
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
                      fontSize: 11,
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
              style: OgText.body(14, weight: FontWeight.w700, height: 1.25),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(cash(p.priceCents), style: OgText.heading(16)),
                if (p.oldPriceCents != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      cash(p.oldPriceCents!),
                      overflow: TextOverflow.ellipsis,
                      style: OgText.body(
                        12,
                        color: c.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(p.soldLine, style: OgText.body(12, color: c.textMuted)),
            if (p.usedBy != null)
              Text(
                'Used by ${p.usedBy}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OgText.body(12, weight: FontWeight.w700, color: t.onTag),
              ),
            if (p.maxPoints > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: KitTag(
                  'Up to ${p.maxPoints} pts off',
                  height: 22,
                  fontSize: 11,
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
  builder: (_) => _BuySheet(
    product: product,
    options: options,
    buyNow: buyNow,
    priceCents: priceCents,
  ),
);

class _BuySheet extends ConsumerStatefulWidget {
  const _BuySheet({
    required this.product,
    required this.options,
    required this.buyNow,
    this.priceCents,
  });

  final Product product;
  final List<OptionGroup> options;
  final bool buyNow;
  final int? priceCents;

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
        Routes.checkout,
        extra: CartLine(
          id: 'now',
          product: widget.priceCents == null
              ? p
              : p.copyWith(priceCents: widget.priceCents!),
          variant: _variant,
          qty: _qty,
        ),
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
    final c = context.og;
    final p = widget.product;
    final price = widget.priceCents ?? p.priceCents;
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
                    Text(cash(price * _qty), style: OgText.heading(22)),
                    Text(
                      p.name,
                      style: OgText.body(14, weight: FontWeight.w700),
                    ),
                    if (_variant.isNotEmpty)
                      Text(
                        _variant,
                        style: OgText.body(13, color: c.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          for (final (gi, g) in widget.options.indexed) ...[
            const SizedBox(height: 14),
            Text(g.title, style: OgText.body(15, weight: FontWeight.w700)),
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
              Expanded(
                child: Text(
                  'Quantity',
                  style: OgText.body(15, weight: FontWeight.w700),
                ),
              ),
              KitQty(
                value: _qty,
                onLess: _qty <= 1 ? null : () => setState(() => _qty--),
                onMore: () => setState(() => _qty++),
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

/// Shop: watch and shop, deals, videos, lives, services and malls.
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
    final c = context.og;
    final t = context.tones;
    final products = ref.watch(shopProductsProvider(null, _q)).value;
    final deals = ref.watch(shopDealsProvider).value ?? const [];
    final videos = ref.watch(shopVideosProvider).value ?? const [];
    final lives = ref.watch(shopLivesProvider).value ?? const [];
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
          if (products == null)
            const CupertinoActivityIndicator()
          else if (products.isEmpty)
            DashedBox(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Nothing matches. Try a product type, a brand or a shop name.',
                  style: OgText.body(14, color: c.textMuted),
                ),
              ),
            )
          else
            ProductGrid(products: products),
        ] else ...[
          if (videos.isNotEmpty)
            Pressable(
              semanticLabel: 'Watch and shop',
              onPressed: () => context.push(Routes.shopVideo(videos.first.id)),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: OgColors.ink,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gear your coach plays with',
                            style: OgText.heading(
                              22,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Watch it in use, then buy it',
                            style: OgText.body(
                              14,
                              color: const Color(0xFFC9C6BC),
                            ),
                          ),
                          const SizedBox(height: 12),
                          KitTag(
                            'Watch and shop',
                            background: t.gold,
                            foreground: t.onGold,
                            height: 30,
                            fontSize: 13,
                          ),
                        ],
                      ),
                    ),
                    OgIcon(
                      OgIcons.racquet,
                      size: 56,
                      color: const Color(0xFFC6FF00),
                    ),
                  ],
                ),
              ),
            ),
          KitUnderlineTabs(
            labels: const ['For you', 'Videos', 'Live', 'Services', 'Malls'],
            selected: _tab,
            padding: EdgeInsets.zero,
            onSelect: (i) => setState(() => _tab = i),
          ),
          ...switch (_tab) {
            0 => [
              if (deals.isNotEmpty) ...[
                Text('Flash deals', style: OgText.heading(20)),
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
              Text('For you', style: OgText.heading(20)),
              if (products == null)
                const CupertinoActivityIndicator()
              else if (products.where((p) => !p.service).isEmpty)
                _ShopEmpty(
                  'Nothing for sale yet. Players and clubs can open a shop '
                  'from Profile, then My shop.',
                )
              else
                ProductGrid(
                  products: products.where((p) => !p.service).toList(),
                ),
            ],
            1 when videos.isEmpty => [
              const _ShopEmpty(
                'Shoppable videos come later. Browse For you in the meantime.',
              ),
            ],
            2 when lives.isEmpty => [
              const _ShopEmpty(
                'Live selling comes later. Browse For you in the meantime.',
              ),
            ],
            1 => [
              for (final v in videos)
                _MediaRow(
                  title: v.title,
                  sub: '${v.creator} · ${compact(v.views)} views',
                  mark: v.creatorMark,
                  price: cash(v.product.priceCents),
                  onTap: () => context.push(Routes.shopVideo(v.id)),
                ),
            ],
            2 => [
              for (final l in lives)
                _MediaRow(
                  title: l.title,
                  sub: 'Live, ${compact(l.watching)} watching · ${l.shop}',
                  mark: l.shopMark,
                  price: 'Live',
                  live: true,
                  onTap: () => context.push(Routes.shopLive(l.id)),
                ),
              Text(
                'Live prices last until the stream ends.',
                style: OgText.body(13, color: c.textMuted),
              ),
            ],
            3 => [
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
                                  Text(
                                    m.name,
                                    style: OgText.body(
                                      15,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    m.blurb,
                                    style: OgText.body(13, color: c.textMuted),
                                  ),
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

class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.title,
    required this.sub,
    required this.mark,
    required this.price,
    required this.onTap,
    this.live = false,
  });

  final String title;
  final String sub;
  final String mark;
  final String price;
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: '$title, $sub',
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            width: 96,
            height: 128,
            decoration: BoxDecoration(
              color: OgColors.ink,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  CupertinoIcons.play_fill,
                  color: Color(0xFFFFFFFF),
                  size: 32,
                ),
                if (live)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: KitTag(
                      'LIVE',
                      height: 20,
                      fontSize: 10,
                      background: const Color(0xFFD2342C),
                      foreground: const Color(0xFFFFFFFF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OgText.body(16, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SolidAvatar.forId(
                      mark,
                      initials: mark,
                      size: 24,
                      fontSize: 10,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sub,
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(price, style: OgText.heading(16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A shop's page: follow, vouchers, products, videos and about.
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
    final videos = (ref.watch(shopVideosProvider).value ?? const <ShopVideo>[])
        .where((v) => v.product.mallId == m.id)
        .toList();
    Crumbs.name(context, m.name);
    Widget stat(String big, String small) => Expanded(
      child: Column(
        children: [
          Text(big, style: OgText.heading(18)),
          Text(small, style: OgText.body(12, color: c.textMuted)),
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
                      Flexible(child: Text(m.name, style: OgText.heading(22))),
                      const SizedBox(width: 6),
                      KitTag(
                        'Verified',
                        height: 22,
                        fontSize: 11,
                        background: t.successFill,
                        foreground: t.onSuccessFill,
                      ),
                    ],
                  ),
                  Text(
                    d.about,
                    style: OgText.body(13, height: 1.4, color: c.textMuted),
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
                  await ref
                      .read(shopRepositoryProvider)
                      .follow(m.id, !d.following);
                  ref.invalidate(mallDetailProvider(m.id));
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
                    ? showOgToast(context, 'Shop chat opens with the Shop.')
                    : context.push(Routes.messagePlayer(m.ownerId)),
              ),
            ),
          ],
        ),
        Row(
          children: [
            for (final (i, v) in d.vouchers.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.warnFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.title,
                        style: OgText.heading(18, color: t.onWarnFill),
                      ),
                      Text(
                        v.condition,
                        style: OgText.body(12, color: t.onWarnFill),
                      ),
                      const SizedBox(height: 6),
                      KitLink(
                        v.claimed ? 'Claimed' : 'Claim',
                        color: t.onWarnFill,
                        onPressed: v.claimed
                            ? null
                            : () async {
                                await ref
                                    .read(shopRepositoryProvider)
                                    .claimVoucher(m.id, v.title);
                                ref.invalidate(mallDetailProvider(m.id));
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        KitUnderlineTabs(
          labels: const ['Products', 'Videos', 'About'],
          selected: _tab,
          spread: true,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = i),
        ),
        ...switch (_tab) {
          0 => [ProductGrid(products: d.products)],
          1 => [
            if (videos.isEmpty)
              Text(
                'No videos yet.',
                style: OgText.body(14, color: c.textMuted),
              ),
            for (final v in videos)
              _MediaRow(
                title: v.title,
                sub: '${v.creator} · ${compact(v.views)} views',
                mark: v.creatorMark,
                price: cash(v.product.priceCents),
                onTap: () => context.push(Routes.shopVideo(v.id)),
              ),
          ],
          _ => [
            Column(children: [for (final (k, v) in d.facts) KitKeyValue(k, v)]),
            if (m.pointsAccepted)
              const KitNote(
                'Points are accepted on every item here. Each item shows how many points it can take.',
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: KitLink(
                'Report this shop',
                color: c.textMuted,
                onPressed: () =>
                    context.push(Routes.reportListing('Shop: ${m.name}')),
              ),
            ),
          ],
        },
      ],
    );
  }
}

/// A product: price, points, options, the creator's video, reviews.
class ProductPageScreen extends ConsumerWidget {
  const ProductPageScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final d = ref.watch(productDetailProvider(id));
    final points = ref.watch(walletSummaryProvider).value?.points ?? 0;
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
            Expanded(
              child: KitButton(
                label: 'Add to cart',
                style: KitButtonStyle.outline,
                onPressed: soldOut
                    ? null
                    : p.service
                    ? () => context.push(Routes.serviceBook(p.id))
                    : () =>
                          showBuySheet(context, ref, p, options: value.options),
              ),
            ),
            const SizedBox(width: 10),
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
            Text(cash(p.priceCents), style: OgText.heading(30)),
            if (p.oldPriceCents != null) ...[
              const SizedBox(width: 8),
              Text(
                cash(p.oldPriceCents!),
                style: OgText.body(
                  15,
                  color: c.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              KitTag(
                p.deal!,
                background: const Color(0xFFD2342C),
                foreground: const Color(0xFFFFFFFF),
              ),
            ],
          ],
        ),
        Text(value.headline, style: OgText.heading(20, height: 1.2)),
        Text(
          value.ratings == 0 && p.sold == 0
              ? 'New in the Shop'
              : value.ratings == 0
              ? '${compact(p.sold)} sold'
              : '${p.rating.toStringAsFixed(1)} · from ${compact(value.ratings)} ${value.ratings == 1 ? 'rating' : 'ratings'}, ${compact(p.sold)} sold',
          style: OgText.body(14, color: c.textMuted),
        ),
        if (p.maxPoints > 0 && !Env.hasSupabase)
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
                    'Use up to ${p.maxPoints} points here. You have ${points.toStringAsFixed(1)}.',
                    style: OgText.body(
                      14,
                      weight: FontWeight.w600,
                      color: t.onSuccessFill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(value.arrives, style: OgText.body(14, color: c.textMuted)),
        if (value.options.isNotEmpty)
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
        if (p.usedBy != null && value.videoTitle != null)
          KitCard(
            children: [
              KitNavTile(
                icon: OgIcons.racquet,
                tile: OgColors.ink,
                ink: const Color(0xFFC6FF00),
                title: '${p.usedBy} uses this',
                subtitle: '${value.videoTitle} · Watch the video',
                onTap: () => context.push(Routes.shopVideo('v1')),
              ),
            ],
          ),
        Text('About this item', style: OgText.heading(20)),
        KitCheckList(value.about),
        Row(
          children: [
            Expanded(child: Text('Reviews', style: OgText.heading(20))),
            Text(
              'All ${compact(value.ratings)}',
              style: OgText.body(13, color: c.textMuted),
            ),
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
                fontSize: 13,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: OgText.body(14, weight: FontWeight.w700),
                    ),
                    Text(r.meta, style: OgText.body(12, color: c.textMuted)),
                    const SizedBox(height: 4),
                    Text(r.text, style: OgText.body(14, height: 1.4)),
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
              subtitle: 'Seller details, delivery and returns',
              onTap: () => context.push(Routes.mallPage(p.mallId)),
            ),
          ],
        ),
        if (value.related.isNotEmpty) ...[
          Text('Goes well with', style: OgText.heading(20)),
          ProductGrid(products: value.related),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: KitLink(
            'Report this listing',
            color: c.textMuted,
            onPressed: () =>
                context.push(Routes.reportListing('Listing: ${p.name}')),
          ),
        ),
      ],
    );
  }
}

/// A shoppable video: the tagged product with a Buy button.
class ShopVideoScreen extends ConsumerStatefulWidget {
  const ShopVideoScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ShopVideoScreen> createState() => _ShopVideoScreenState();
}

class _ShopVideoScreenState extends ConsumerState<ShopVideoScreen> {
  bool _liked = false;
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(shopVideosProvider).value;
    final v = videos?.where((v) => v.id == widget.id).firstOrNull;
    if (v == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Video'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final i = videos!.indexOf(v);
    const white = Color(0xFFFFFFFF);
    const muted = Color(0xFFC9C6BC);
    return KitScaffold(
      header: KitHeader(
        title: '${i + 1} of ${videos.length}',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KitIconButton(
              icon: OgIcons.flag,
              label: 'Report this video',
              onPressed: () => context.push(Routes.reportVideo(v.id)),
            ),
            const CartButton(),
          ],
        ),
      ),
      background: OgColors.ink,
      children: [
        Container(
          height: 360,
          decoration: BoxDecoration(
            color: const Color(0xFF26292E),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  CupertinoIcons.play_circle_fill,
                  color: white,
                  size: 64,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 16,
                child: Column(
                  children: [
                    KitIconButton(
                      icon: OgIcons.heart,
                      label: _liked ? 'Unlike' : 'Like',
                      fill: _liked,
                      color: white,
                      background: const Color(0x38FFFFFF),
                      onPressed: () => setState(() => _liked = !_liked),
                    ),
                    Text(
                      compact(v.likes + (_liked ? 1 : 0)),
                      style: OgText.body(12, color: white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (v.paid)
          KitTag(
            'Paid partnership',
            background: const Color(0x38FFFFFF),
            foreground: white,
          ),
        Row(
          children: [
            SolidAvatar.forId(
              v.creatorMark,
              initials: v.creatorMark,
              size: 40,
              fontSize: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                v.creator,
                style: OgText.body(16, weight: FontWeight.w700, color: white),
              ),
            ),
            KitButton(
              label: _following ? 'Following' : 'Follow',
              expand: false,
              height: 38,
              radius: 19,
              fontSize: 13,
              style: _following
                  ? KitButtonStyle.outline
                  : KitButtonStyle.primary,
              onPressed: () => setState(() => _following = !_following),
            ),
          ],
        ),
        Text(v.title, style: OgText.heading(20, color: white)),
        Text('${compact(v.views)} views', style: OgText.body(13, color: muted)),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: ProductArtBox(product: v.product, height: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.product.name,
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        color: OgColors.ink,
                      ),
                    ),
                    Text(
                      cash(v.product.priceCents),
                      style: OgText.heading(16, color: OgColors.ink),
                    ),
                    if (v.product.maxPoints > 0)
                      Text(
                        'Up to ${v.product.maxPoints} pts off',
                        style: OgText.body(12, color: const Color(0xFF0A4F3A)),
                      ),
                  ],
                ),
              ),
              KitButton(
                label: 'Buy',
                expand: false,
                height: 42,
                radius: 21,
                onPressed: () => showBuySheet(context, ref, v.product),
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (i > 0)
              Expanded(
                child: KitButton(
                  label: 'Previous',
                  style: KitButtonStyle.outline,
                  onPressed: () => context.pushReplacement(
                    Routes.shopVideo(videos[i - 1].id),
                  ),
                ),
              ),
            if (i > 0 && i < videos.length - 1) const SizedBox(width: 10),
            if (i < videos.length - 1)
              Expanded(
                child: KitButton(
                  label: 'Next video',
                  style: KitButtonStyle.outline,
                  onPressed: () => context.pushReplacement(
                    Routes.shopVideo(videos[i + 1].id),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Live shopping: chat, the pinned product at its live price.
class ShopLiveScreen extends ConsumerStatefulWidget {
  const ShopLiveScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ShopLiveScreen> createState() => _ShopLiveScreenState();
}

class _ShopLiveScreenState extends ConsumerState<ShopLiveScreen> {
  final _ask = TextEditingController();
  final _mine = <String>[];

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = ref
        .watch(shopLivesProvider)
        .value
        ?.where((l) => l.id == widget.id)
        .firstOrNull;
    if (l == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Live'),
        children: [CupertinoActivityIndicator()],
      );
    }
    const white = Color(0xFFFFFFFF);
    const muted = Color(0xFFC9C6BC);
    final pinned = l.products.first;
    final livePrice = l.livePriceCents[pinned.id] ?? pinned.priceCents;
    return KitScaffold(
      header: KitHeader(
        title: l.shop,
        subtitle: 'with ${l.host}',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KitIconButton(
              icon: OgIcons.flag,
              label: 'Report this live',
              onPressed: () =>
                  context.push(Routes.reportVideo(l.id, live: true)),
            ),
            const CartButton(),
          ],
        ),
      ),
      background: OgColors.ink,
      children: [
        Container(
          height: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF26292E),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  KitTag(
                    'LIVE',
                    background: const Color(0xFFD2342C),
                    foreground: white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${compact(l.watching)} watching',
                    style: OgText.body(13, color: white),
                  ),
                ],
              ),
              const Center(
                child: Icon(
                  CupertinoIcons.videocam_fill,
                  color: white,
                  size: 56,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (who, text) in [
                      ...l.chat,
                      for (final m in _mine) ('You', m),
                    ].reversed.take(4).toList().reversed)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$who  ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: text),
                          ],
                        ),
                        style: OgText.body(13, color: white),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: ProductArtBox(product: pinned, height: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live price · ends with the stream',
                      style: OgText.body(
                        11,
                        weight: FontWeight.w800,
                        color: const Color(0xFFD2342C),
                      ),
                    ),
                    Text(
                      pinned.name,
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        color: OgColors.ink,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          cash(livePrice),
                          style: OgText.heading(16, color: OgColors.ink),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cash(pinned.oldPriceCents ?? pinned.priceCents),
                          style: OgText.body(
                            12,
                            color: const Color(0xFF5B6168),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              KitButton(
                label: 'Buy',
                expand: false,
                height: 42,
                radius: 21,
                onPressed: () =>
                    showBuySheet(context, ref, pinned, priceCents: livePrice),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: KitInput(
                label: 'Ask the host',
                controller: _ask,
                hint: 'Type a question',
              ),
            ),
          ],
        ),
        KitButton(
          label: 'Send',
          style: KitButtonStyle.outline,
          onPressed: () {
            if (_ask.text.trim().isEmpty) return;
            setState(() => _mine.add(_ask.text.trim()));
            _ask.clear();
            showOgToast(context, 'Sent. The host sees your question.');
          },
        ),
        Text('In this live', style: OgText.heading(20, color: white)),
        for (final p in l.products)
          Pressable(
            semanticLabel: p.name,
            onPressed: () => context.push(Routes.product(p.id)),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: ProductArtBox(product: p, height: 52),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.name,
                    style: OgText.body(
                      14,
                      weight: FontWeight.w700,
                      color: white,
                    ),
                  ),
                ),
                Text(
                  cash(l.livePriceCents[p.id] ?? p.priceCents),
                  style: OgText.heading(15, color: white),
                ),
              ],
            ),
          ),
        Text(
          'Live prices last until the stream ends.',
          style: OgText.body(13, color: muted),
        ),
      ],
    );
  }
}

/// Book a service like a restring: tension, day and time, then pay.
class ServiceBookScreen extends ConsumerStatefulWidget {
  const ServiceBookScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ServiceBookScreen> createState() => _ServiceBookScreenState();
}

class _ServiceBookScreenState extends ConsumerState<ServiceBookScreen> {
  String _tension = '24 lb';
  int _day = 0;
  String? _time;
  bool _busy = false;
  Order? _done;

  List<DateTime> get _days {
    final now = DateTime.now();
    return [
      for (var i = 1; i <= 4; i++) DateTime(now.year, now.month, now.day + i),
    ];
  }

  String _dayLabel(DateTime d) =>
      '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} ${d.day}';

  Future<void> _book(Product p) async {
    setState(() => _busy = true);
    try {
      final o = await ref
          .read(shopRepositoryProvider)
          .bookService(
            p.id,
            slot: '${_dayLabel(_days[_day])}, $_time',
            tension: _tension,
          );
      HapticFeedback.mediumImpact();
      refreshShop(ref.invalidate);
      if (mounted) setState(() => _done = o);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final d = ref.watch(productDetailProvider(widget.id)).value;
    if (d == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Book a service'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final p = d.product;
    if (_done case final o?) {
      return KitScaffold(
        header: const KitHeader(title: 'Book a service'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'See my orders',
            onPressed: () => context.go(Routes.orders()),
          ),
          KitButton(
            label: 'Back to the Shop',
            style: KitButtonStyle.outline,
            onPressed: () => context.go(Routes.shop),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Booked'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${p.name}, ${o.booking} at ${p.mallName}. Show the booking when you drop off your racket.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Book a service'),
      bottom: [
        KitButton(
          label: _time == null ? 'Pick a time' : 'Book · ${cash(p.priceCents)}',
          loading: _busy,
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
                  Text(p.name, style: OgText.heading(20)),
                  Text(
                    '${p.mallName} · ${p.rating.toStringAsFixed(1)} from ${compact(d.ratings)} reviews',
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text('String tension', style: OgText.heading(18)),
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
        Text('Drop-off day', style: OgText.heading(18)),
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
        Text('Drop-off time', style: OgText.heading(18)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in const [
              '10:00 AM',
              '12:00 PM',
              '3:00 PM',
              '6:00 PM',
            ])
              KitChip(
                label: s,
                selected: _time == s,
                onTap: () => setState(() => _time = s),
              ),
          ],
        ),
        const KitKeyValue('Ready', '2 hours after drop-off'),
        KitKeyValue('Where', '${p.mallName}, Tampines'),
        KitKeyValue(
          'Price',
          '${cash(p.priceCents)}, no platform fee for the buyer',
        ),
        Text(
          'Free to cancel up to 2 hours before your slot. Services are booked '
          'and paid like anything else in the Shop, and points can be used.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
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
      child: Text(text, style: OgText.body(14, color: context.og.textMuted)),
    ),
  );
}
