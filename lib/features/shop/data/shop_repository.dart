import 'package:flutter/foundation.dart';
import 'package:og_money/og_money.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../../earnings/data/earnings_repository.dart';
import '../../play/data/payment_gateway.dart'
    show PaymentHold, SupabasePaymentGateway;
import '../../play/domain/meet_ops.dart' show newClientKey;
import '../domain/commerce_models.dart';
import '../domain/shop_models.dart';

/// The Shop: partner shops, the cart, orders paid through OlympusGO and
/// collected at the shop, and the shop owner's side.
abstract interface class ShopRepository {
  Future<List<Mall>> malls();
  Future<List<Product>> popular();
  Future<List<Product>> products({String? mallId, String query = ''});
  Future<List<Product>> deals();
  Future<ProductDetail> product(String id);
  Future<MallDetail> mall(String id);
  Future<void> follow(String mallId, bool on);

  Future<List<CartLine>> cart();
  Future<void> addToCart(String productId, {String variant = '', int qty = 1});
  Future<void> setQty(String lineId, int qty);

  /// The final price of this shop's part of the cart, or of [only].
  Future<ShopQuote> quote(
    String mallId, {
    CartLine? only,
    int pointsCents = 0,
    String? voucherId,
  });

  /// Holds stock and points and starts a payment for [expectedCents]. The same
  /// [key] returns the same hold, and a changed price refuses rather than
  /// charges. Returns the hold and the order's id.
  Future<(PaymentHold, String)> reserve(
    String mallId, {
    required String key,
    required int expectedCents,
    int pointsCents = 0,
    CartLine? only,
    String? voucherId,
  });
  Future<List<Order>> orders();
  Future<Order> order(String id);

  /// "Yes, I got it all": final, and the shop is paid.
  Future<void> collected(String id);

  /// Holds the payment until staff decide.
  Future<void> reportProblem(String id, String note);

  /// Cancels before collecting. Returns the refund in cents.
  Future<int> cancelOrder(String id, {required String reason});

  Future<void> report(
    String productId, {
    required String reason,
    String note = '',
  });

  /// Reviews everything in a collected order.
  Future<void> review(
    String orderId, {
    required int stars,
    required List<String> tags,
    required String text,
    required bool showLevel,
  });

  // The shop's owner.

  /// The shop this account runs, if any.
  Future<Mall?> myShop();
  Future<List<Order>> ownerOrders();
  Future<void> markStarted(String id);
  Future<void> markReady(String id);
  Future<void> ownerCancel(String id, {required String reason});
}

/// The Shop on Supabase.
class SupabaseShopRepository implements ShopRepository {
  SupabaseShopRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Shop error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      if (e.code == '23514') {
        throw const AuthFailure('Check the details and try again.');
      }
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Shop network error');
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

  static DateTime? _at(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  static Product _product(Map<String, dynamic> r) => Product(
    id: r['id'] as String,
    name: r['name'] as String,
    mallId: r['mall_id'] as String,
    mallName: r['mall_name'] as String,
    priceCents: r['price_cents'] as int,
    oldPriceCents: r['old_price_cents'] as int?,
    pointsCapCents: (r['points_cap_minor'] as num?)?.toInt() ?? 0,
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
    ownerId: r['owner_id'] as String? ?? '',
    pointsAccepted: r['points_open'] as bool? ?? false,
  );

  // Orders from before payments have no unit amounts, and a shop isn't shown them.
  static int _linePrice(Map l) {
    final paid = ((l['unit_paid'] as num) + (l['unit_points'] as num)).toInt();
    return paid > 0
        ? paid + (l['unit_voucher'] as num? ?? 0).toInt()
        : (l['price_cents'] as num).toInt();
  }

  static Order _order(Map<String, dynamic> r) {
    final pay = (r['payment'] as Map?)?.cast<String, dynamic>();
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
            _linePrice(l),
            id: l['id'] as String,
            productId: l['product_id'] as String? ?? '',
            pointsCents: (l['unit_points'] as num).toInt(),
            voucherCents: (l['unit_voucher'] as num? ?? 0).toInt(),
            shopCents: (l['unit_shop'] as num).toInt(),
            refundedQty: l['refunded_qty'] as int? ?? 0,
            art: l['art'] == 'racquet' ? ProductArt.racquet : ProductArt.bag,
          ),
      ],
      placedAt: DateTime.parse(r['placed_at'] as String).toLocal(),
      step: OrderStep.values.byName(r['step'] as String),
      collectAddress: r['collect_address'] as String? ?? '',
      collectBy: _at(r['collect_by']),
      releaseAt: _at(r['release_at']),
      readyAt: _at(r['ready_at']),
      collectedAt: _at(r['collected_at']),
      holdUntil: _at(r['hold_until']),
      serverNow: _at(r['server_now']),
      slotAt: _at(r['slot_at']),
      service: r['service'] as bool? ?? false,
      reviewed: r['reviewed'] as bool? ?? false,
      buyer: r['buyer'] as String? ?? '',
      buyerId: r['buyer_id'] as String? ?? '',
      ownerId: r['owner_id'] as String? ?? '',
      paymentId: pay?['id'] as String?,
      paymentMethod: pay?['method'] as String?,
      paymentStatus: pay?['status'] as String? ?? '',
      receiptNo: pay?['receipt_no'] as String? ?? '',
      refundedCents: (pay?['refunded_minor'] as num?)?.toInt() ?? 0,
      refundStatus: pay?['refund_status'] as String?,
      disputeStatus: pay?['dispute_status'] as String?,
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
        'Self-collect from the shop',
        'Final once collected',
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
      collectLine: p.service
          ? 'Book a drop-off time and collect from ${p.mallName}'
          : 'Collect from ${p.mallName}',
      related: [
        for (final x in (r['related'] as List).cast<Map>())
          _product(x.cast<String, dynamic>()),
      ],
    );
  });

  @override
  Future<MallDetail> mall(String id) => _guard(() async {
    final raw = await _rpc('shop_mall', {'p_mall': id});
    if (raw == null) throw const AuthFailure('This shop isn’t open.');
    final r = _m(raw);
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
      verified: m['verified'] == true,
      facts: [
        ('Opened on Olympus', '${months[opened.month - 1]} ${opened.year}'),
        if ((m['collect_address'] as String? ?? '').isNotEmpty)
          ('Collect from', m['collect_address'] as String),
        ('Final once collected', 'Check it at the shop'),
        ('Pay with', 'Card or PayNow, held until you collect'),
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

  static Map<String, dynamic>? _only(CartLine? only) => only == null
      ? null
      : {'product': only.product.id, 'variant': only.variant, 'qty': only.qty};

  @override
  Future<ShopQuote> quote(
    String mallId, {
    CartLine? only,
    int pointsCents = 0,
    String? voucherId,
  }) => _guard(() async {
    final r = _m(
      await _rpc('shop_quote', {
        'p_mall': mallId,
        'p_only': _only(only),
        'p_points': pointsCents,
        'p_voucher': voucherId,
      }),
    );
    int n(String k) => (r[k] as num? ?? 0).toInt();
    return ShopQuote(
      lines: [
        for (final l in (r['lines'] as List).cast<Map>())
          QuoteLine(
            name: l['name'] as String,
            variant: l['variant'] as String? ?? '',
            qty: l['qty'] as int,
            priceCents:
                ((l['unit_paid'] as num) +
                        (l['unit_points'] as num) +
                        (l['unit_voucher'] as num? ?? 0))
                    .toInt(),
            pointsCents: (l['unit_points'] as num).toInt(),
            voucherCents: (l['unit_voucher'] as num? ?? 0).toInt(),
          ),
      ],
      voucherId: r['voucher_id'] as String?,
      vouchers: [
        for (final v in (r['vouchers'] as List? ?? const []).cast<Map>())
          CheckoutVoucher(
            id: v['id'] as String,
            name: v['name'] as String,
            amountCents: (v['amount_minor'] as num).toInt(),
          ),
      ],
      totalCents: n('total_minor'),
      pointsCapCents: n('points_cap_minor'),
      pointsLeftCents: n('points_left_minor'),
      pointsBalanceCents: n('points_balance_minor'),
      canRedeem: r['can_redeem'] as bool? ?? false,
      collectAddress: r['collect_address'] as String? ?? '',
      refundRule: r['refund_rule'] as String? ?? '',
      canPay: r['can_pay'] as bool? ?? false,
    );
  });

  @override
  Future<(PaymentHold, String)> reserve(
    String mallId, {
    required String key,
    required int expectedCents,
    int pointsCents = 0,
    CartLine? only,
    String? voucherId,
  }) => _guard(() async {
    final r = _m(
      await _rpc('shop_reserve', {
        'p_mall': mallId,
        'p_key': key,
        'p_expected_minor': expectedCents,
        'p_points': pointsCents,
        'p_only': _only(only),
        'p_slot': only?.slot?.toUtc().toIso8601String(),
        'p_voucher': voucherId,
      }),
    );
    return (SupabasePaymentGateway.holdFrom(r), r['order_id'] as String);
  });

  @override
  Future<List<Order>> orders() => _guard(() async {
    return [for (final r in await _list('shop_orders')) _order(r)];
  });

  @override
  Future<Order> order(String id) =>
      _guard(() async => _order(_m(await _rpc('shop_order', {'p_order': id}))));

  @override
  Future<void> collected(String id) => _guard(() async {
    await _rpc('shop_collected', {'p_order': id});
  });

  @override
  Future<void> reportProblem(String id, String note) => _guard(() async {
    await _rpc('shop_report_problem', {'p_order': id, 'p_note': note});
  });

  @override
  Future<int> cancelOrder(String id, {required String reason}) => _guard(
    () async => ((await _rpc('shop_order_cancel', {
      'p_order': id,
      'p_reason': reason,
    })) as num).toInt(),
  );

  @override
  Future<void> report(
    String productId, {
    required String reason,
    String note = '',
  }) => _guard(() async {
    await _rpc('shop_report', {
      'p_product': productId,
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
  Future<Mall?> myShop() => _guard(() async {
    final r = await _rpc('shop_my_mall');
    return r == null ? null : _mall(_m(r));
  });

  @override
  Future<List<Order>> ownerOrders() => _guard(() async {
    return [for (final r in await _list('shop_owner_orders')) _order(r)];
  });

  @override
  Future<void> markStarted(String id) => _guard(() async {
    await _rpc('shop_mark_started', {'p_order': id});
  });

  @override
  Future<void> markReady(String id) => _guard(() async {
    await _rpc('shop_mark_ready', {'p_order': id});
  });

  @override
  Future<void> ownerCancel(String id, {required String reason}) =>
      _guard(() async {
        await _rpc('shop_owner_cancel', {'p_order': id, 'p_reason': reason});
      });
}

/// The design's shops and products, with a working cart and orders. The
/// demo player also runs Racket Lab, for the owner's screens.
class DemoShopRepository implements ShopRepository {
  DemoShopRepository([this._wallet]) {
    _seedOrders();
  }

  final DemoEarningsRepository? _wallet;
  static const myShop_ = 'm-racket';

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
      pointsCapCents: 945,
      art: ProductArt.racquet,
      rating: 4.8,
      sold: 1200,
      stock: 14,
    ),
    const Product(
      id: 'p-shuttles',
      name: 'Feather shuttles, tube of 12',
      mallId: 'm-court',
      mallName: 'Court Supply Co.',
      priceCents: 2450,
      oldPriceCents: 2800,
      pointsCapCents: 122,
      art: ProductArt.racquet,
      rating: 4.9,
      sold: 5600,
      stock: 40,
    ),
    const Product(
      id: 'p-shoes',
      name: 'Court shoe, all-court grip',
      mallId: 'm-footwork',
      mallName: 'Footwork',
      priceCents: 15900,
      pointsCapCents: 795,
      rating: 4.7,
      sold: 860,
      stock: 8,
    ),
    const Product(
      id: 'p-grip',
      name: 'Overgrip, pack of 3',
      mallId: 'm-court',
      mallName: 'Court Supply Co.',
      priceCents: 900,
      pointsCapCents: 45,
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
      pointsCapCents: 345,
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
      pointsCapCents: 125,
      rating: 4.9,
      sold: 2300,
      service: true,
    ),
    const Product(
      id: 'p-tshuttles',
      name: 'Tournament shuttles, tube of 12',
      mallId: 'm-racket',
      mallName: 'Racket Lab',
      priceCents: 3200,
      pointsCapCents: 160,
      rating: 4.7,
      sold: 210,
      stock: 0,
    ),
  ];

  final _following = <String>{'m-court'};
  final _cart = <CartLine>[];
  int _lineSeq = 0;
  final _orders = <Order>[];
  final _ownerOrders = <Order>[];

  Product _p(String id) {
    final p = _products.where((p) => p.id == id).firstOrNull;
    if (p == null) throw const AuthFailure('This item is no longer listed.');
    return p;
  }

  static const _address = '4 Tampines Central 5, #01-12, Singapore 529510';

  void _seedOrders() {
    final now = DateTime.now();
    _orders.addAll([
      Order(
        id: 'o-1001',
        mallId: 'm-racket',
        mallName: 'Racket Lab',
        lines: const [
          OrderLine(
            'Carbon racket 4U',
            '4U, G5, strung 24 lb',
            1,
            18900,
            pointsCents: 200,
            shopCents: 17010,
          ),
        ],
        placedAt: now.subtract(const Duration(days: 2, hours: 3)),
        step: OrderStep.ready,
        collectAddress: _address,
        collectBy: now.add(const Duration(days: 5)),
        releaseAt: now.add(const Duration(days: 7)),
        readyAt: now.subtract(const Duration(days: 1)),
        paymentMethod: 'card',
        receiptNo: 'OG-1001',
      ),
      Order(
        id: 'o-1002',
        mallId: 'm-court',
        mallName: 'Court Supply Co.',
        lines: const [
          OrderLine('Overgrip, pack of 3', 'White', 2, 900, shopCents: 810),
          OrderLine(
            'Feather shuttles, tube of 12',
            'Speed 77',
            1,
            2450,
            shopCents: 2205,
          ),
        ],
        placedAt: now.subtract(const Duration(hours: 5)),
        step: OrderStep.paid,
        collectAddress: _address,
        collectBy: now.add(const Duration(days: 7)),
        releaseAt: now.add(const Duration(days: 9)),
        paymentMethod: 'paynow',
        receiptNo: 'OG-1002',
      ),
      Order(
        id: 'o-0990',
        mallId: 'm-footwork',
        mallName: 'Footwork',
        lines: const [
          OrderLine(
            'Court shoe, all-court grip',
            'US 9',
            1,
            15900,
            shopCents: 14310,
          ),
        ],
        placedAt: now.subtract(const Duration(days: 20)),
        step: OrderStep.collected,
        collectAddress: _address,
        collectedAt: now.subtract(const Duration(days: 18)),
        paymentMethod: 'card',
        receiptNo: 'OG-0990',
      ),
    ]);
    _ownerOrders.addAll([
      Order(
        id: 's-2001',
        mallId: myShop_,
        mallName: 'Racket Lab',
        lines: const [
          OrderLine(
            'Carbon racket 4U',
            '3U G5, strung 24 lb',
            1,
            18900,
            shopCents: 17010,
          ),
        ],
        placedAt: now.subtract(const Duration(hours: 2)),
        step: OrderStep.paid,
        buyer: 'Priya Raman',
        collectAddress: _address,
        collectBy: now.add(const Duration(days: 7)),
        releaseAt: now.add(const Duration(days: 9)),
      ),
      Order(
        id: 's-2002',
        mallId: myShop_,
        mallName: 'Racket Lab',
        lines: const [
          OrderLine('Racket bag, 6-piece', 'Black', 1, 6900, shopCents: 6210),
        ],
        placedAt: now.subtract(const Duration(hours: 6)),
        step: OrderStep.ready,
        buyer: 'Kelvin Ho',
        collectAddress: _address,
        collectBy: now.add(const Duration(days: 6)),
        releaseAt: now.add(const Duration(days: 8)),
      ),
      Order(
        id: 's-2003',
        mallId: myShop_,
        mallName: 'Racket Lab',
        lines: const [
          OrderLine(
            'Restring service, 24 lb',
            '24 lb',
            1,
            2500,
            shopCents: 2250,
          ),
        ],
        placedAt: now.subtract(const Duration(days: 1)),
        step: OrderStep.paid,
        buyer: 'Daniel Tan',
        service: true,
        slotAt: now.add(const Duration(days: 2)),
        collectAddress: _address,
        collectBy: now.add(const Duration(days: 2)),
        releaseAt: now.add(const Duration(days: 4)),
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
          : ['Sold by ${p.mallName}', 'Final once collected'],
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
      collectLine: p.service
          ? 'Ready 2 hours after drop-off'
          : 'Collect from ${p.mallName}',
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
          ? 'Rackets and restringing in Tampines. Collect from the shop.'
          : '${m.blurb}. Collect from the shop.',
      rating: racket ? 4.8 : 4.9,
      ratings: racket ? 2100 : 5400,
      followers: racket ? 3400 + (_following.contains(id) ? 1 : 0) : 8100,
      following: _following.contains(id),
      facts: [
        ('Opened on Olympus', 'March 2025'),
        ('Business name', '${m.name} Pte Ltd'),
        ('Collect from', _address),
        ('Final once collected', 'Check it at the shop'),
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

  static const _voucherId = 'dv-1';
  static const _voucherShop = 'Racket Lab';
  bool _voucherSpent = false;

  List<CartLine> _linesFor(String mallId, CartLine? only) => only == null
      ? _cart.where((l) => l.product.mallId == mallId).toList()
      : [only];

  @override
  Future<ShopQuote> quote(
    String mallId, {
    CartLine? only,
    int pointsCents = 0,
    String? voucherId,
  }) async {
    await _tick();
    var left = pointsCents;
    final lines = <QuoteLine>[];
    var cap = 0;
    final cart = _linesFor(mallId, only);
    // The demo wallet's one voucher goes on the dearest item at its shop.
    final dearest = cart.isEmpty || cart.first.product.mallName != _voucherShop
        ? null
        : cart.reduce(
            (a, b) => b.product.priceCents > a.product.priceCents ? b : a,
          );
    final off = dearest == null
        ? 0
        : [
            800,
            dearest.product.priceCents - 50,
          ].reduce((a, b) => a < b ? a : b);
    for (final l in cart) {
      var qty = l.qty;
      if (voucherId == _voucherId && identical(l, dearest) && !_voucherSpent) {
        lines.add(
          QuoteLine(
            name: l.product.name,
            variant: l.variant,
            qty: 1,
            priceCents: l.product.priceCents,
            pointsCents: 0,
            voucherCents: off,
          ),
        );
        qty -= 1;
        if (qty == 0) continue;
      }
      final unit = [
        l.product.pointsCapCents,
        left ~/ qty,
      ].reduce((a, b) => a < b ? a : b);
      left -= unit * qty;
      cap += l.product.pointsCapCents * qty;
      lines.add(
        QuoteLine(
          name: l.product.name,
          variant: l.variant,
          qty: qty,
          priceCents: l.product.priceCents,
          pointsCents: unit,
        ),
      );
    }
    final total = lines.fold(
      0,
      (a, l) => a + (l.priceCents - l.pointsCents - l.voucherCents) * l.qty,
    );
    return ShopQuote(
      lines: lines,
      totalCents: total,
      pointsCapCents: cap,
      pointsLeftCents: left,
      pointsBalanceCents: ((_wallet?.balance ?? 0)).toInt(),
      canRedeem: true,
      collectAddress: _address,
      refundRule:
          'Cancel before you collect and you get everything back. Sports '
          'equipment is final once collected.',
      canPay: true,
      voucherId: lines.any((l) => l.voucherCents > 0) ? voucherId : null,
      vouchers: [
        if (off > 0 && !_voucherSpent)
          CheckoutVoucher(
            id: _voucherId,
            name: 'S\$8 off at $_voucherShop',
            amountCents: off,
          ),
      ],
    );
  }

  @override
  Future<(PaymentHold, String)> reserve(
    String mallId, {
    required String key,
    required int expectedCents,
    int pointsCents = 0,
    CartLine? only,
    String? voucherId,
  }) async {
    await _tick();
    final q = await quote(
      mallId,
      only: only,
      pointsCents: pointsCents,
      voucherId: voucherId,
    );
    final lines = _linesFor(mallId, only);
    if (lines.isEmpty) throw const AuthFailure('Your cart is empty.');
    final now = DateTime.now();
    final o = Order(
      id: 'o-${now.millisecondsSinceEpoch % 100000}',
      mallId: mallId,
      mallName: lines.first.product.mallName,
      lines: [
        for (final l in q.lines)
          OrderLine(
            l.name,
            l.variant,
            l.qty,
            l.priceCents,
            productId: lines
                .firstWhere((x) => x.product.name == l.name)
                .product
                .id,
            pointsCents: l.pointsCents,
            voucherCents: l.voucherCents,
            shopCents: ((l.priceCents - l.voucherCents) * 9 + 5) ~/ 10,
          ),
      ],
      placedAt: now,
      step: OrderStep.paid,
      collectAddress: _address,
      service: only?.slot != null,
      slotAt: only?.slot,
      collectBy: only?.slot ?? now.add(const Duration(days: 7)),
      releaseAt: (only?.slot ?? now.add(const Duration(days: 7))).add(
        const Duration(hours: 48),
      ),
      paymentMethod: 'card',
      receiptNo: 'OG-${now.millisecondsSinceEpoch % 100000}',
    );
    _orders.insert(0, o);
    _wallet?.addReceipt(
      ReceiptRecord(
        id: o.id,
        title: o.summary,
        kind: 'Shop',
        at: o.placedAt,
        no: o.receiptNo,
        lines: [
          ('Items', '${Money(o.itemsCents)}'),
          if (o.voucherCents > 0) ('Voucher', '${Money(-o.voucherCents)}'),
          if (o.pointsCents > 0) ('Points used', '${Money(-o.pointsCents)}'),
        ],
        totalCents: o.totalCents,
        paidWith: o.paidWith,
      ),
    );
    if (o.pointsCents > 0) {
      _wallet?.spend('Shop order', o.mallName, minor: o.pointsCents);
    }
    if (o.voucherCents > 0) _voucherSpent = true;
    if (only == null) _cart.removeWhere((l) => l.product.mallId == mallId);
    return (
      PaymentHold(
        result: 'reserved',
        id: newClientKey(),
        totalCents: o.totalCents,
        holdUntil: now.add(const Duration(minutes: 10)),
        serverNow: now,
      ),
      o.id,
    );
  }

  @override
  Future<List<Order>> orders() async {
    await _tick();
    return List.of(_orders);
  }

  @override
  Future<Order> order(String id) async {
    await _tick();
    return [..._orders, ..._ownerOrders].firstWhere((o) => o.id == id);
  }

  void _set(String id, Order Function(Order) change) {
    for (final list in [_orders, _ownerOrders]) {
      final i = list.indexWhere((o) => o.id == id);
      if (i >= 0) list[i] = change(list[i]);
    }
  }

  @override
  Future<void> collected(String id) async {
    await _tick();
    _set(
      id,
      (o) => o.copyWith(step: OrderStep.collected, collectedAt: DateTime.now()),
    );
  }

  @override
  Future<void> reportProblem(String id, String note) async {
    await _tick();
    _set(id, (o) => o.copyWith(step: OrderStep.reported));
  }

  @override
  Future<int> cancelOrder(String id, {required String reason}) async {
    await _tick();
    final o = _orders.firstWhere((o) => o.id == id);
    if (!o.canCancel) {
      throw const AuthFailure('This order can’t be cancelled now.');
    }
    final back = o.totalCents;
    _set(
      id,
      (o) => o.copyWith(
        step: OrderStep.cancelled,
        refundedCents: back,
        refundStatus: 'pending',
      ),
    );
    if (o.pointsCents > 0) {
      _wallet?.credit('Refund, ${o.summary}', o.mallName, minor: o.pointsCents);
    }
    return back;
  }

  @override
  Future<void> report(
    String productId, {
    required String reason,
    String note = '',
  }) async => _tick();

  @override
  Future<void> review(
    String orderId, {
    required int stars,
    required List<String> tags,
    required String text,
    required bool showLevel,
  }) async {
    await _tick();
    _set(orderId, (o) => o.copyWith(reviewed: true));
  }

  @override
  Future<Mall?> myShop() async => _malls.firstWhere((m) => m.id == myShop_);

  @override
  Future<List<Order>> ownerOrders() async {
    await _tick();
    return List.of(_ownerOrders);
  }

  @override
  Future<void> markStarted(String id) async {
    await _tick();
    _set(id, (o) => o.copyWith(step: OrderStep.started));
  }

  @override
  Future<void> markReady(String id) async {
    await _tick();
    _set(id, (o) => o.copyWith(step: OrderStep.ready, readyAt: DateTime.now()));
  }

  @override
  Future<void> ownerCancel(String id, {required String reason}) async {
    await _tick();
    final o = _ownerOrders.firstWhere((o) => o.id == id);
    _set(
      id,
      (o) => o.copyWith(
        step: OrderStep.cancelled,
        refundedCents: o.totalCents,
        refundStatus: 'pending',
      ),
    );
    if (o.pointsCents > 0) {
      _wallet?.credit('Refund, ${o.summary}', o.mallName, minor: o.pointsCents);
    }
  }
}
