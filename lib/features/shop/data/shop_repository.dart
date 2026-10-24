import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../../wallet/data/wallet_repository.dart';
import '../domain/commerce_models.dart';
import '../domain/shop_models.dart';

/// The Shop: malls, products, videos and lives, the cart, orders, and the
/// seller's side.
abstract interface class ShopRepository {
  Future<List<Mall>> malls();
  Future<List<Product>> popular();
  Future<List<Product>> products({String? mallId, String query = ''});
  Future<List<Product>> deals();
  Future<ProductDetail> product(String id);
  Future<MallDetail> mall(String id);
  Future<void> follow(String mallId, bool on);
  Future<void> claimVoucher(String mallId, String title);
  Future<List<ShopVideo>> videos();
  Future<List<LiveStream>> lives();

  Future<List<CartLine>> cart();
  Future<void> addToCart(String productId, {String variant = '', int qty = 1});
  Future<void> setQty(String lineId, int qty);

  Future<List<Address>> addresses();
  Future<Address> saveAddress(Address address);

  /// Places one order per shop for everything in the cart (or just
  /// [only], for Buy now). Returns the orders.
  Future<List<Order>> checkout({
    required Address address,
    required Delivery delivery,
    required int pointsCents,
    required String paidWith,
    CartLine? only,
  });
  Future<List<Order>> orders();
  Future<Order> order(String id);
  Future<void> confirmReceived(String id);

  /// Cancels before shipping. Returns the refund in cents.
  Future<int> cancelOrder(
    String id, {
    required String reason,
    required bool toWallet,
  });

  Future<Order> bookService(
    String productId, {
    required String slot,
    required String tension,
  });
  Future<void> report(String what, {required String reason, String note = ''});

  /// Reviews everything in a delivered order.
  Future<void> review(
    String orderId, {
    required int stars,
    required List<String> tags,
    required String text,
    required bool showLevel,
  });

  /// Asks the shop to take a delivered order back.
  Future<void> requestReturn(
    String orderId, {
    required String reason,
    required String want,
  });

  // Seller.

  /// Null until the player opens a shop.
  Future<SellerSummary?> sellerSummary();
  Future<void> openShop({
    required String name,
    required String blurb,
    required String about,
    required String shipsFrom,
  });
  Future<void> decideReturn(String orderId, {required bool accept});
  Future<List<Order>> sellerOrders();
  Future<void> markShipped(
    String orderId, {
    required String courier,
    required String tracking,
  });
  Future<List<Product>> sellerProducts();
  Future<Product> saveProduct(Product product);
  Future<void> goLive({
    required String title,
    required List<String> productIds,
    required String deal,
  });
  Future<void> postVideo({required String caption, required String productId});
}

/// The Shop on Supabase, with payments switched off: buyers order and pay
/// the shop directly on delivery or pickup. Videos and live selling come
/// later.
class SupabaseShopRepository implements ShopRepository {
  SupabaseShopRepository(this._client);
  final SupabaseClient _client;

  static const _later = AuthFailure(
    'Videos and live selling open later. Your products are in the Shop now.',
  );

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Shop error: ${e.code} ${e.message}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      if (e.code == '23514') {
        throw const AuthFailure('Check the details and try again.');
      }
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Shop network error: $e');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) =>
      _client.rpc(fn, params: params);

  Future<List<Map<String, dynamic>>> _list(
    String fn, [
    Map<String, dynamic>? params,
  ]) async => [
    for (final r in (await _rpc(fn, params)) as List? ?? const [])
      (r as Map).cast<String, dynamic>(),
  ];

  static Map<String, dynamic> _m(Object? v) =>
      (v as Map).cast<String, dynamic>();

  static Product _product(Map<String, dynamic> r) => Product(
    id: r['id'] as String,
    name: r['name'] as String,
    mallId: r['mall_id'] as String,
    mallName: r['mall_name'] as String,
    priceCents: r['price_cents'] as int,
    oldPriceCents: r['old_price_cents'] as int?,
    maxPoints: r['max_points'] as int? ?? 0,
    art: r['art'] == 'racquet' ? ProductArt.racquet : ProductArt.bag,
    rating: (r['rating'] as num? ?? 0).toDouble(),
    sold: (r['sold'] as num? ?? 0).toInt(),
    service: r['service'] as bool? ?? false,
    stock: r['stock'] as int? ?? 0,
    published: r['published'] as bool? ?? false,
    description: r['description'] as String? ?? '',
  );

  static Mall _mall(Map<String, dynamic> r) => Mall(
    id: r['id'] as String,
    name: r['name'] as String,
    initials: r['initials'] as String,
    blurb: r['blurb'] as String? ?? '',
    color: (r['color'] as num).toInt(),
    ink: (r['ink'] as num).toInt(),
    pointsAccepted: false,
  );

  static Address _address(Map<String, dynamic> r) => Address(
    id: r['id'] as String? ?? '',
    label: r['label'] as String? ?? '',
    name: r['name'] as String? ?? '',
    line: r['line'] as String? ?? '',
    phone: r['phone'] as String? ?? '',
    isDefault: r['is_default'] as bool? ?? false,
    pickup: r['pickup'] as bool? ?? false,
  );

  static Order _order(Map<String, dynamic> r) {
    final step = switch (r['step']) {
      'shipped' => OrderStep.shipped,
      'delivered' => OrderStep.delivered,
      'cancelled' => OrderStep.cancelled,
      _ => OrderStep.packing,
    };
    final ret = (r['return'] as Map?)?.cast<String, dynamic>();
    return Order(
      id: r['id'] as String,
      mallId: r['mall_id'] as String,
      mallName: r['mall_name'] as String,
      lines: [
        for (final l in (r['lines'] as List).cast<Map>())
          OrderLine(
            l['name'] as String,
            l['variant'] as String? ?? '',
            l['qty'] as int,
            l['price_cents'] as int,
          ),
      ],
      placedAt: DateTime.parse(r['placed_at'] as String).toLocal(),
      step: step,
      deliveryCents: r['delivery_cents'] as int? ?? 0,
      paidWith: r['paid_with'] as String? ?? 'Pay the shop',
      address: r['address'] == null ? null : _address(_m(r['address'])),
      delivery: r['delivery'] as String? ?? 'Standard',
      arrives: r['arrives'] == null
          ? null
          : DateTime.parse(r['arrives'] as String),
      tracking: r['tracking'] as String?,
      courier: r['courier'] as String?,
      buyer: r['buyer'] as String? ?? '',
      service: r['service'] as bool? ?? false,
      booking: r['booking'] as String?,
      received: step == OrderStep.delivered,
      reviewed: r['reviewed'] as bool? ?? false,
      returnState: ret?['status'] as String?,
      returnReason: ret == null ? null : '${ret['reason']} · ${ret['want']}',
    );
  }

  @override
  Future<List<Mall>> malls() => _guard(() async {
    return [for (final r in await _list('shop_malls')) _mall(r)];
  });

  Future<List<Product>> _products(
    String kind, {
    String? mallId,
    String query = '',
  }) => _guard(() async {
    final rows = await _list('shop_products', {
      'p_kind': kind,
      'p_mall': mallId,
      'p_query': query,
    });
    return [for (final r in rows) _product(r)];
  });

  @override
  Future<List<Product>> popular() => _products('popular');

  @override
  Future<List<Product>> products({String? mallId, String query = ''}) =>
      _products('all', mallId: mallId, query: query);

  @override
  Future<List<Product>> deals() => _products('deals');

  @override
  Future<ProductDetail> product(String id) => _guard(() async {
    final r = _m(await _rpc('shop_product', {'p_id': id}));
    final p = _product(_m(r['product']));
    final raw = _m(r['product']);
    String ago(DateTime at) {
      final d = DateTime.now().difference(at).inDays;
      return d < 1
          ? 'today'
          : d < 7
          ? '$d ${d == 1 ? 'day' : 'days'} ago'
          : d < 35
          ? '${d ~/ 7} ${d ~/ 7 == 1 ? 'week' : 'weeks'} ago'
          : '${d ~/ 30} months ago';
    }

    return ProductDetail(
      product: p,
      headline: p.name,
      about: [
        for (final line in p.description.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
        'Sold by ${p.mallName}',
        if (!p.service) 'Returns within 7 days, unused',
        'Pay the shop on delivery or pickup',
      ],
      options: [
        for (final o in (raw['options'] as List? ?? const []).cast<Map>())
          OptionGroup(o['title'] as String, [
            for (final v in o['values'] as List) v as String,
          ]),
      ],
      ratings: raw['ratings'] as int? ?? 0,
      reviews: [
        for (final v in (r['reviews'] as List).cast<Map>())
          () {
            final level = (v['level'] as Map?)?.cast<String, dynamic>();
            final sport = level == null
                ? null
                : Sport.values.where((s) => s.id == level['sport']).firstOrNull;
            final body = (v['body'] as String? ?? '').trim();
            final tags = [for (final t in v['tags'] as List) t as String];
            return Review(
              v['name'] as String,
              [
                '${'★' * (v['stars'] as int)}${'☆' * (5 - (v['stars'] as int))}',
                if (sport != null)
                  '${sport.label} ${SkillBand.forLevel((level!['level'] as num).toDouble()).code}',
                'bought ${ago(DateTime.parse(v['at'] as String))}',
              ].join(', '),
              body.isEmpty ? tags.join(', ') : body,
            );
          }(),
      ],
      arrives: p.service
          ? 'Book a drop-off slot. Pay the shop when you collect it'
          : 'Arrives in 3 to 5 working days, delivery from S\$1.99',
      related: [
        for (final x in (r['related'] as List).cast<Map>())
          _product(x.cast<String, dynamic>()),
      ],
    );
  });

  @override
  Future<MallDetail> mall(String id) => _guard(() async {
    final r = _m(await _rpc('shop_mall', {'p_mall': id}));
    final m = _m(r['mall']);
    final opened = DateTime.parse(m['created_at'] as String).toLocal();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return MallDetail(
      mall: _mall(m),
      about: m['about'] as String? ?? '',
      rating: (r['rating'] as num? ?? 0).toDouble(),
      ratings: r['ratings'] as int? ?? 0,
      followers: r['followers'] as int? ?? 0,
      following: r['following'] as bool? ?? false,
      facts: [
        ('Opened on Olympus', '${months[opened.month - 1]} ${opened.year}'),
        if ((m['ships_from'] as String? ?? '').isNotEmpty)
          ('Ships from', m['ships_from'] as String),
        ('Returns', 'Within 7 days, unused'),
        ('Pay with', 'Pay the shop on delivery or pickup'),
        ('Verified shop', m['verified'] == true ? 'Yes' : 'Not yet'),
      ],
      products: [
        for (final p in (r['products'] as List).cast<Map>())
          _product(p.cast<String, dynamic>()),
      ],
    );
  });

  @override
  Future<void> follow(String mallId, bool on) => _guard(() async {
    await _rpc('shop_follow', {'p_mall': mallId, 'p_on': on});
  });

  // Shops don't run vouchers yet, so there is nothing to claim.
  @override
  Future<void> claimVoucher(String mallId, String title) async {}

  @override
  Future<List<ShopVideo>> videos() async => const [];

  @override
  Future<List<LiveStream>> lives() async => const [];

  @override
  Future<List<CartLine>> cart() => _guard(() async {
    return [
      for (final r in await _list('shop_cart'))
        CartLine(
          id: r['id'] as String,
          product: _product(_m(r['product'])),
          variant: r['variant'] as String? ?? '',
          qty: r['qty'] as int,
        ),
    ];
  });

  @override
  Future<void> addToCart(
    String productId, {
    String variant = '',
    int qty = 1,
  }) => _guard(() async {
    await _rpc('shop_cart_add', {
      'p_product': productId,
      'p_variant': variant,
      'p_qty': qty,
    });
  });

  @override
  Future<void> setQty(String lineId, int qty) => _guard(() async {
    await _rpc('shop_cart_set', {'p_line': lineId, 'p_qty': qty});
  });

  @override
  Future<List<Address>> addresses() => _guard(() async {
    final rows = await _client
        .from('addresses')
        .select()
        .order('is_default', ascending: false)
        .order('created_at');
    return [for (final r in rows) _address(r)];
  });

  @override
  Future<Address> saveAddress(Address address) => _guard(() async {
    final id = await _rpc('shop_address_save', {
      'p': {
        'label': address.label,
        'name': address.name,
        'line': address.line,
        'phone': address.phone,
        'is_default': address.isDefault,
      },
    });
    return Address(
      id: id as String,
      label: address.label,
      name: address.name,
      line: address.line,
      phone: address.phone,
      isDefault: address.isDefault,
    );
  });

  @override
  Future<List<Order>> checkout({
    required Address address,
    required Delivery delivery,
    required int pointsCents,
    required String paidWith,
    CartLine? only,
  }) => _guard(() async {
    final ids = await _rpc('shop_checkout', {
      'p_address': {
        'label': address.label,
        'name': address.name,
        'line': address.line,
        'phone': address.phone,
        'pickup': address.pickup || delivery.cents == 0,
      },
      'p_delivery': delivery.name,
      'p_only': only == null
          ? null
          : {
              'product': only.product.id,
              'variant': only.variant,
              'qty': only.qty,
            },
    });
    return [for (final id in ids as List) await order(id as String)];
  });

  @override
  Future<List<Order>> orders() => _guard(() async {
    return [for (final r in await _list('shop_orders')) _order(r)];
  });

  @override
  Future<Order> order(String id) =>
      _guard(() async => _order(_m(await _rpc('shop_order', {'p_order': id}))));

  @override
  Future<void> confirmReceived(String id) => _guard(() async {
    await _rpc('shop_confirm_received', {'p_order': id});
  });

  @override
  Future<int> cancelOrder(
    String id, {
    required String reason,
    required bool toWallet,
  }) => _guard(
    () async =>
        await _rpc('shop_cancel', {'p_order': id, 'p_reason': reason}) as int,
  );

  @override
  Future<Order> bookService(
    String productId, {
    required String slot,
    required String tension,
  }) => _guard(() async {
    final id = await _rpc('shop_book_service', {
      'p_product': productId,
      'p_slot': slot,
      'p_tension': tension,
    });
    return order(id as String);
  });

  @override
  Future<void> report(
    String what, {
    required String reason,
    String note = '',
  }) => _guard(() async {
    await _rpc('shop_report', {
      'p_what': what,
      'p_reason': reason,
      'p_note': note,
    });
  });

  @override
  Future<void> review(
    String orderId, {
    required int stars,
    required List<String> tags,
    required String text,
    required bool showLevel,
  }) => _guard(() async {
    await _rpc('shop_review', {
      'p_order': orderId,
      'p_stars': stars,
      'p_tags': tags,
      'p_body': text,
      'p_show_level': showLevel,
    });
  });

  @override
  Future<void> requestReturn(
    String orderId, {
    required String reason,
    required String want,
  }) => _guard(() async {
    await _rpc('shop_return_request', {
      'p_order': orderId,
      'p_reason': reason,
      'p_want': want,
    });
  });

  @override
  Future<SellerSummary?> sellerSummary() => _guard(() async {
    final r = await _rpc('shop_seller_summary');
    if (r == null) return null;
    final s = _m(r);
    return SellerSummary(
      mall: _mall(_m(s['mall'])),
      salesTodayCents: (s['sales_today_cents'] as num).toInt(),
      toShip: s['to_ship'] as int,
      onTheWay: s['on_the_way'] as int,
      returns: s['returns'] as int,
      listed: s['listed'] as int,
      lowStock: s['low_stock'] as int,
    );
  });

  @override
  Future<void> openShop({
    required String name,
    required String blurb,
    required String about,
    required String shipsFrom,
  }) => _guard(() async {
    await _rpc('shop_open', {
      'p': {
        'name': name,
        'blurb': blurb,
        'about': about,
        'ships_from': shipsFrom,
      },
    });
  });

  @override
  Future<void> decideReturn(String orderId, {required bool accept}) =>
      _guard(() async {
        await _rpc('shop_return_decide', {
          'p_order': orderId,
          'p_accept': accept,
        });
      });

  @override
  Future<List<Order>> sellerOrders() => _guard(() async {
    return [for (final r in await _list('shop_seller_orders')) _order(r)];
  });

  @override
  Future<void> markShipped(
    String orderId, {
    required String courier,
    required String tracking,
  }) => _guard(() async {
    await _rpc('shop_mark_shipped', {
      'p_order': orderId,
      'p_courier': courier,
      'p_tracking': tracking,
    });
  });

  @override
  Future<List<Product>> sellerProducts() => _guard(() async {
    return [for (final r in await _list('shop_seller_products')) _product(r)];
  });

  @override
  Future<Product> saveProduct(Product product) => _guard(() async {
    final r = await _rpc('shop_save_product', {
      'p': {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price_cents': product.priceCents,
        'old_price_cents': product.oldPriceCents,
        'max_points': product.maxPoints,
        'art': product.art.name,
        'service': product.service,
        'stock': product.stock,
        'published': product.published,
      },
    });
    return _product(_m(r));
  });

  @override
  Future<void> goLive({
    required String title,
    required List<String> productIds,
    required String deal,
  }) => throw _later;

  @override
  Future<void> postVideo({
    required String caption,
    required String productId,
  }) => throw _later;
}

/// The design's shops and products, with a working cart and orders. The
/// demo player also runs Racket Lab, for the seller screens.
class DemoShopRepository implements ShopRepository {
  DemoShopRepository([this._wallet]) {
    _seedOrders();
  }

  final DemoWalletRepository? _wallet;
  static const myShop = 'm-racket';

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  static const _malls = [
    Mall(
      id: 'm-court',
      name: 'Court Supply Co.',
      initials: 'CS',
      blurb: 'Shuttles, grips, strings',
    ),
    Mall(
      id: 'm-racket',
      name: 'Racket Lab',
      initials: 'RL',
      blurb: 'Rackets and restringing',
      color: 0xFFE3ECF3,
      ink: 0xFF2F3A5F,
    ),
    Mall(
      id: 'm-footwork',
      name: 'Footwork',
      initials: 'FW',
      blurb: 'Court shoes and socks',
      color: 0xFFDCEEE6,
      ink: 0xFF0A4F3A,
    ),
  ];

  final _products = <Product>[
    const Product(
      id: 'p-racket',
      name: 'Carbon racket 4U',
      mallId: 'm-racket',
      mallName: 'Racket Lab',
      priceCents: 18900,
      oldPriceCents: 22900,
      maxPoints: 18,
      art: ProductArt.racquet,
      rating: 4.8,
      sold: 1200,
      usedBy: 'Coach Ravi',
      stock: 14,
    ),
    const Product(
      id: 'p-shuttles',
      name: 'Feather shuttles, tube of 12',
      mallId: 'm-court',
      mallName: 'Court Supply Co.',
      priceCents: 2450,
      oldPriceCents: 2800,
      maxPoints: 3,
      art: ProductArt.racquet,
      rating: 4.9,
      sold: 5600,
      usedBy: 'Mei Wong',
      stock: 40,
    ),
    const Product(
      id: 'p-shoes',
      name: 'Court shoe, all-court grip',
      mallId: 'm-footwork',
      mallName: 'Footwork',
      priceCents: 15900,
      maxPoints: 15,
      rating: 4.7,
      sold: 860,
      usedBy: 'Marcus Lee',
      stock: 8,
    ),
    const Product(
      id: 'p-grip',
      name: 'Overgrip, pack of 3',
      mallId: 'm-court',
      mallName: 'Court Supply Co.',
      priceCents: 900,
      maxPoints: 1,
      rating: 4.8,
      sold: 9100,
      stock: 3,
    ),
    const Product(
      id: 'p-bag',
      name: 'Racket bag, 6-piece',
      mallId: 'm-racket',
      mallName: 'Racket Lab',
      priceCents: 6900,
      oldPriceCents: 8900,
      maxPoints: 6,
      rating: 4.6,
      sold: 430,
      stock: 9,
    ),
    const Product(
      id: 'p-restring',
      name: 'Restring service, 24 lb',
      mallId: 'm-racket',
      mallName: 'Racket Lab',
      priceCents: 2500,
      maxPoints: 2,
      rating: 4.9,
      sold: 2300,
      usedBy: 'Coach Ravi',
      service: true,
    ),
    const Product(
      id: 'p-tshuttles',
      name: 'Tournament shuttles, tube of 12',
      mallId: 'm-racket',
      mallName: 'Racket Lab',
      priceCents: 3200,
      maxPoints: 3,
      rating: 4.7,
      sold: 210,
      stock: 0,
    ),
  ];

  final _following = <String>{'m-court'};
  final _claimed = <String>{};
  final _cart = <CartLine>[];
  int _lineSeq = 0;
  final _addresses = <Address>[
    const Address(
      id: 'a-home',
      label: 'Home',
      name: 'Aaron Ng',
      line: '21 Tampines Ave 1, #08-12, Singapore 529773',
      phone: '+65 9123 4567',
      isDefault: true,
    ),
    const Address(
      id: 'a-office',
      label: 'Office',
      name: 'Aaron Ng',
      line: '1 Changi Business Park, Singapore 486025',
      phone: '+65 9123 4567',
    ),
    const Address(
      id: 'a-pickup',
      label: 'Pick up at Our Tampines Hub',
      name: 'Front desk',
      line: 'Free, from Monday',
      pickup: true,
    ),
  ];
  final _orders = <Order>[];
  final _sellerOrders = <Order>[];

  Product _p(String id) {
    final p = _products.where((p) => p.id == id).firstOrNull;
    if (p == null) throw const AuthFailure('This item is no longer listed.');
    return p;
  }

  void _seedOrders() {
    final now = DateTime.now();
    _orders.addAll([
      Order(
        id: 'o-1001',
        mallId: 'm-racket',
        mallName: 'Racket Lab',
        lines: const [
          OrderLine('Carbon racket 4U', '4U, G5, strung 24 lb', 1, 18900),
        ],
        placedAt: now.subtract(const Duration(days: 2, hours: 3)),
        step: OrderStep.shipped,
        voucherCents: 500,
        deliveryCents: 199,
        pointsCents: 199,
        paidWith: 'Card',
        address: _addresses.first,
        arrives: now.add(const Duration(days: 1)),
        tracking: 'NV-SG-29384756',
        courier: 'Ninja Van',
      ),
      Order(
        id: 'o-1002',
        mallId: 'm-court',
        mallName: 'Court Supply Co.',
        lines: const [
          OrderLine('Overgrip, pack of 3', 'White', 2, 900),
          OrderLine('Feather shuttles, tube of 12', 'Speed 77', 1, 2450),
        ],
        placedAt: now.subtract(const Duration(hours: 5)),
        step: OrderStep.packing,
        paidWith: 'Card',
        address: _addresses.first,
        arrives: now.add(const Duration(days: 4)),
      ),
      Order(
        id: 'o-0990',
        mallId: 'm-footwork',
        mallName: 'Footwork',
        lines: const [
          OrderLine('Court shoe, all-court grip', 'US 9', 1, 15900),
        ],
        placedAt: now.subtract(const Duration(days: 20)),
        step: OrderStep.delivered,
        deliveryCents: 199,
        paidWith: 'Card',
        address: _addresses.first,
        received: true,
      ),
    ]);
    _sellerOrders.addAll([
      Order(
        id: 's-2001',
        mallId: myShop,
        mallName: 'Racket Lab',
        lines: const [
          OrderLine('Carbon racket 4U', '3U G5, strung 24 lb', 1, 18900),
        ],
        placedAt: now.subtract(const Duration(hours: 2)),
        step: OrderStep.packing,
        buyer: 'Priya Raman',
        address: const Address(
          id: 'x',
          label: 'Home',
          name: 'Priya Raman',
          line: '9 Bedok North Ave 3, Singapore 469652',
          phone: '+65 9876 5432',
        ),
        pointsCents: 2120,
        deliveryCents: 199,
      ),
      Order(
        id: 's-2002',
        mallId: myShop,
        mallName: 'Racket Lab',
        lines: const [OrderLine('Racket bag, 6-piece', 'Black', 1, 6900)],
        placedAt: now.subtract(const Duration(hours: 6)),
        step: OrderStep.packing,
        buyer: 'Kelvin Ho',
        address: const Address(
          id: 'y',
          label: 'Home',
          name: 'Kelvin Ho',
          line: '3 Pasir Ris Dr 1, Singapore 519447',
        ),
        deliveryCents: 199,
      ),
      Order(
        id: 's-2003',
        mallId: myShop,
        mallName: 'Racket Lab',
        lines: const [
          OrderLine(
            'Restring service, 24 lb',
            'Sat 10:00 AM drop-off',
            1,
            2500,
          ),
        ],
        placedAt: now.subtract(const Duration(days: 1)),
        step: OrderStep.shipped,
        buyer: 'Daniel Tan',
        service: true,
      ),
    ]);
  }

  @override
  Future<List<Mall>> malls() async => _malls;

  @override
  Future<List<Product>> popular() async =>
      _products.where((p) => !p.service && p.stock > 0).take(4).toList();

  @override
  Future<List<Product>> products({String? mallId, String query = ''}) async {
    await _tick();
    final q = query.trim().toLowerCase();
    return _products
        .where((p) => p.published)
        .where((p) => mallId == null || p.mallId == mallId)
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              p.mallName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<List<Product>> deals() async =>
      _products.where((p) => p.deal != null).toList();

  @override
  Future<ProductDetail> product(String id) async {
    await _tick();
    final p = _p(id);
    final racket = p.id == 'p-racket';
    return ProductDetail(
      product: p,
      headline: racket
          ? 'Carbon racket 4U, head-light, for fast doubles'
          : p.name,
      about: racket
          ? const [
              '83 g frame, head-light balance for quick defence',
              'Stiff shaft, suits Mid Intermediate and above',
              'Comes strung at 24 lb, or unstrung',
              '1-year frame warranty from Racket Lab',
            ]
          : ['Sold by ${p.mallName}', 'Returns within 7 days, unused'],
      options: racket
          ? const [
              OptionGroup('Weight', ['3U', '4U']),
              OptionGroup('Grip', ['G5', 'G6']),
              OptionGroup('Strings', ['Strung 24 lb', 'Unstrung']),
            ]
          : p.id == 'p-grip'
          ? const [
              OptionGroup('Colour', ['White', 'Black', 'Orange']),
            ]
          : const [],
      ratings: (p.sold * 0.26).round(),
      reviews: const [
        Review(
          'Priya Raman',
          'Badminton MI, bought 3 weeks ago',
          'Lighter than my old racket and my drives are faster. Grip is thin, add an overgrip.',
        ),
        Review(
          'Daniel Tan',
          'Badminton HB, bought last month',
          'Good control. A bit stiff for me, so I restrung at 22 lb.',
        ),
      ],
      arrives: p.service
          ? 'Ready 2 hours after drop-off'
          : 'Arrives in 3 to 5 working days, delivery from S\$1.99',
      videoTitle: p.usedBy == null ? null : '3 drills for a heavier smash',
      related: _products
          .where((x) => x.mallId == p.mallId && x.id != p.id)
          .take(2)
          .toList(),
    );
  }

  @override
  Future<MallDetail> mall(String id) async {
    await _tick();
    final m = _malls.firstWhere((m) => m.id == id);
    final racket = id == 'm-racket';
    return MallDetail(
      mall: m,
      about: racket
          ? 'Rackets and restringing in Tampines. Pick up at Our Tampines Hub or get it delivered.'
          : '${m.blurb}. Delivered across Singapore.',
      rating: racket ? 4.8 : 4.9,
      ratings: racket ? 2100 : 5400,
      followers: racket ? 3400 + (_following.contains(id) ? 1 : 0) : 8100,
      following: _following.contains(id),
      vouchers: [
        Voucher(
          'S\$5 off',
          'Orders over S\$50',
          claimed: _claimed.contains('$id:S\$5 off'),
        ),
        Voucher(
          'Free delivery',
          'Orders over S\$80',
          claimed: _claimed.contains('$id:Free delivery'),
        ),
      ],
      facts: [
        ('Opened on Olympus', 'March 2025'),
        ('Business name', '${m.name} Pte Ltd'),
        ('Ships from', 'Tampines, Singapore'),
        ('Returns', 'Within 7 days, unused'),
        ('Delivery', '1 to 3 working days'),
        ('Pay with', 'Card, PayNow, points'),
        ('Business licence', 'Checked by Olympus'),
      ],
      products: _products.where((p) => p.mallId == id && p.published).toList(),
    );
  }

  @override
  Future<void> follow(String mallId, bool on) async =>
      on ? _following.add(mallId) : _following.remove(mallId);

  @override
  Future<void> claimVoucher(String mallId, String title) async =>
      _claimed.add('$mallId:$title');

  @override
  Future<List<ShopVideo>> videos() async => [
    ShopVideo(
      id: 'v1',
      title: '3 drills for a heavier smash',
      creator: 'Coach Ravi',
      creatorMark: 'CR',
      product: _p('p-racket'),
      views: 48200,
      likes: 3100,
      paid: true,
    ),
    ShopVideo(
      id: 'v2',
      title: 'Why I switched to feather shuttles',
      creator: 'Mei Wong',
      creatorMark: 'MW',
      product: _p('p-shuttles'),
      views: 12900,
      likes: 870,
    ),
    ShopVideo(
      id: 'v3',
      title: 'Footwork test: 30 lunges in these',
      creator: 'Marcus Lee',
      creatorMark: 'ML',
      product: _p('p-shoes'),
      views: 9400,
      likes: 610,
      paid: true,
    ),
  ];

  @override
  Future<List<LiveStream>> lives() async => [
    LiveStream(
      id: 'l1',
      title: 'Restring night with Coach Ravi',
      shop: 'Racket Lab',
      shopMark: 'RL',
      host: 'Coach Ravi',
      watching: 1284,
      products: [_p('p-racket'), _p('p-restring'), _p('p-bag'), _p('p-grip')],
      livePriceCents: const {'p-racket': 17900},
      chat: const [
        ('Kelvin', 'Does 24 lb suit a beginner?'),
        ('Priya R.', 'Got mine restrung here last month, feels great'),
        ('Daniel', 'Is the flash price for 3U too?'),
        ('Racket Lab', 'Yes, both weights. 14 left at this price.'),
      ],
    ),
  ];

  @override
  Future<List<CartLine>> cart() async => List.of(_cart);

  @override
  Future<void> addToCart(
    String productId, {
    String variant = '',
    int qty = 1,
  }) async {
    final p = _p(productId);
    if (!p.service && p.stock <= 0) {
      throw const AuthFailure('This is sold out.');
    }
    final i = _cart.indexWhere(
      (l) => l.product.id == productId && l.variant == variant,
    );
    if (i >= 0) {
      final l = _cart[i];
      _cart[i] = CartLine(
        id: l.id,
        product: l.product,
        variant: l.variant,
        qty: l.qty + qty,
      );
    } else {
      _cart.add(
        CartLine(id: 'c${++_lineSeq}', product: p, variant: variant, qty: qty),
      );
    }
  }

  @override
  Future<void> setQty(String lineId, int qty) async {
    final i = _cart.indexWhere((l) => l.id == lineId);
    if (i < 0) return;
    final l = _cart[i];
    if (qty <= 0) {
      _cart.removeAt(i);
    } else {
      _cart[i] = CartLine(
        id: l.id,
        product: l.product,
        variant: l.variant,
        qty: qty,
      );
    }
  }

  @override
  Future<List<Address>> addresses() async => List.of(_addresses);

  @override
  Future<Address> saveAddress(Address address) async {
    await _tick();
    final a = Address(
      id: 'a-${DateTime.now().millisecondsSinceEpoch}',
      label: address.label,
      name: address.name,
      line: address.line,
      phone: address.phone,
      isDefault: address.isDefault,
    );
    if (a.isDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        final x = _addresses[i];
        _addresses[i] = Address(
          id: x.id,
          label: x.label,
          name: x.name,
          line: x.line,
          phone: x.phone,
          pickup: x.pickup,
        );
      }
      _addresses.insert(0, a);
    } else {
      _addresses.insert(_addresses.length - 1, a);
    }
    return a;
  }

  @override
  Future<List<Order>> checkout({
    required Address address,
    required Delivery delivery,
    required int pointsCents,
    required String paidWith,
    CartLine? only,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final lines = only == null ? List.of(_cart) : [only];
    if (lines.isEmpty) throw const AuthFailure('Your cart is empty.');
    final byMall = <String, List<CartLine>>{};
    for (final l in lines) {
      byMall.putIfAbsent(l.product.mallId, () => []).add(l);
    }
    var pointsLeft = pointsCents;
    final placed = <Order>[];
    for (final e in byMall.entries) {
      final items = e.value.fold(0, (a, l) => a + l.totalCents);
      final cap = e.value.fold(
        0,
        (a, l) => a + l.product.maxPoints * 100 * l.qty,
      );
      final pts = pointsLeft.clamp(0, cap.clamp(0, items));
      pointsLeft -= pts;
      final voucher = _claimed.contains('${e.key}:S\$5 off') && items >= 5000
          ? 500
          : 0;
      final o = Order(
        id: 'o-${DateTime.now().millisecondsSinceEpoch % 100000}${placed.length}',
        mallId: e.key,
        mallName: e.value.first.product.mallName,
        lines: [
          for (final l in e.value)
            OrderLine(l.product.name, l.variant, l.qty, l.product.priceCents),
        ],
        placedAt: DateTime.now(),
        step: OrderStep.packing,
        voucherCents: voucher,
        deliveryCents: placed.isEmpty ? delivery.cents : 0,
        pointsCents: pts,
        paidWith: paidWith,
        address: address,
        delivery: delivery.name,
        arrives: DateTime.now().add(
          Duration(days: delivery.name == 'Express' ? 1 : 4),
        ),
      );
      placed.add(o);
      _orders.insert(0, o);
      _wallet?.addReceipt(
        ReceiptRecord(
          id: o.id,
          title: o.summary,
          kind: 'Shop',
          at: o.placedAt,
          no: 'OG-${o.id.toUpperCase()}',
          lines: [
            ('Items', 'S\$${(o.itemsCents / 100).toStringAsFixed(2)}'),
            if (o.voucherCents > 0)
              ('Voucher', '−S\$${(o.voucherCents / 100).toStringAsFixed(2)}'),
            if (o.deliveryCents > 0)
              ('Delivery', 'S\$${(o.deliveryCents / 100).toStringAsFixed(2)}'),
            if (o.pointsCents > 0)
              (
                'Points used',
                '−S\$${(o.pointsCents / 100).toStringAsFixed(2)}',
              ),
          ],
          totalCents: o.totalCents,
          paidWith: paidWith,
        ),
      );
    }
    final spent = pointsCents - pointsLeft;
    if (paidWith == 'Wallet') {
      _wallet?.spend(
        'Shop order',
        placed.map((o) => o.mallName).join(', '),
        cents: placed.fold(0, (a, o) => a + o.totalCents),
      );
    }
    if (spent > 0) {
      _wallet?.spend('Shop order', placed.first.mallName, points: spent / 100);
    }
    if (only == null) _cart.clear();
    return placed;
  }

  @override
  Future<List<Order>> orders() async {
    await _tick();
    return List.of(_orders);
  }

  @override
  Future<Order> order(String id) async {
    await _tick();
    return [..._orders, ..._sellerOrders].firstWhere((o) => o.id == id);
  }

  @override
  Future<void> confirmReceived(String id) async {
    final i = _orders.indexWhere((o) => o.id == id);
    _orders[i] = _orders[i].copyWith(step: OrderStep.delivered, received: true);
  }

  @override
  Future<int> cancelOrder(
    String id, {
    required String reason,
    required bool toWallet,
  }) async {
    await _tick();
    final i = _orders.indexWhere((o) => o.id == id);
    final o = _orders[i];
    if (o.step != OrderStep.packing && o.step != OrderStep.toPay) {
      throw const AuthFailure('It has shipped, so ask for a return instead.');
    }
    final back = o.totalCents;
    _orders[i] = o.copyWith(
      step: OrderStep.cancelled,
      refundCents: back,
      refundTo: toWallet ? 'Wallet' : 'Card ending 4242',
    );
    if (toWallet) {
      _wallet?.credit(
        'Refund, ${o.summary}',
        '${o.mallName}, order cancelled',
        cents: back,
      );
    }
    if (o.pointsCents > 0) {
      _wallet?.credit(
        'Refund, ${o.summary}',
        o.mallName,
        points: o.pointsCents / 100,
      );
    }
    return back;
  }

  @override
  Future<Order> bookService(
    String productId, {
    required String slot,
    required String tension,
  }) async {
    await _tick();
    final p = _p(productId);
    final o = Order(
      id: 'o-${DateTime.now().millisecondsSinceEpoch % 100000}',
      mallId: p.mallId,
      mallName: p.mallName,
      lines: [OrderLine(p.name, '$tension · $slot', 1, p.priceCents)],
      placedAt: DateTime.now(),
      step: OrderStep.packing,
      paidWith: 'Card',
      service: true,
      booking: slot,
    );
    _orders.insert(0, o);
    return o;
  }

  @override
  Future<void> report(
    String what, {
    required String reason,
    String note = '',
  }) async => _tick();

  @override
  Future<SellerSummary?> sellerSummary() async {
    await _tick();
    final mine = _products.where((p) => p.mallId == myShop).toList();
    return SellerSummary(
      mall: _malls.firstWhere((m) => m.id == myShop),
      salesTodayCents: 84200,
      toShip: _sellerOrders.where((o) => o.step == OrderStep.packing).length,
      onTheWay: _sellerOrders.where((o) => o.step == OrderStep.shipped).length,
      returns: 0,
      listed: mine.where((p) => p.published).length,
      lowStock: mine.where((p) => !p.service && p.stock <= 3).length,
      readyCents: 312000,
      voucher: 'S\$5 off above S\$50',
    );
  }

  @override
  Future<List<Order>> sellerOrders() async {
    await _tick();
    return List.of(_sellerOrders);
  }

  @override
  Future<void> markShipped(
    String orderId, {
    required String courier,
    required String tracking,
  }) async {
    await _tick();
    final i = _sellerOrders.indexWhere((o) => o.id == orderId);
    _sellerOrders[i] = _sellerOrders[i].copyWith(
      step: OrderStep.shipped,
      courier: courier,
      tracking: tracking,
    );
  }

  @override
  Future<List<Product>> sellerProducts() async {
    await _tick();
    return _products.where((p) => p.mallId == myShop).toList();
  }

  @override
  Future<Product> saveProduct(Product product) async {
    await _tick();
    final i = _products.indexWhere((p) => p.id == product.id);
    final saved = product.copyWith(
      id: i < 0 ? 'p-${DateTime.now().millisecondsSinceEpoch}' : product.id,
      mallId: myShop,
      mallName: 'Racket Lab',
    );
    i < 0 ? _products.add(saved) : _products[i] = saved;
    return saved;
  }

  @override
  Future<void> goLive({
    required String title,
    required List<String> productIds,
    required String deal,
  }) => _tick();

  @override
  Future<void> postVideo({
    required String caption,
    required String productId,
  }) => _tick();

  @override
  Future<void> review(
    String orderId, {
    required int stars,
    required List<String> tags,
    required String text,
    required bool showLevel,
  }) async {
    await _tick();
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) _orders[i] = _orders[i].copyWith(reviewed: true);
  }

  @override
  Future<void> requestReturn(
    String orderId, {
    required String reason,
    required String want,
  }) async {
    await _tick();
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      _orders[i] = _orders[i].copyWith(
        returnState: 'requested',
        returnReason: '$reason · $want',
      );
    }
  }

  @override
  Future<void> openShop({
    required String name,
    required String blurb,
    required String about,
    required String shipsFrom,
  }) async {
    await _tick();
    throw const AuthFailure('The sample player already runs Racket Lab.');
  }

  @override
  Future<void> decideReturn(String orderId, {required bool accept}) async {
    await _tick();
    final i = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      _sellerOrders[i] = _sellerOrders[i].copyWith(
        returnState: accept ? 'accepted' : 'declined',
      );
    }
  }
}
