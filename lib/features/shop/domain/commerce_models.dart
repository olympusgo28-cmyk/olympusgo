import 'shop_models.dart';

/// A review on a product page.
class Review {
  const Review(this.name, this.meta, this.text);
  final String name;

  /// "Badminton MI, bought 3 weeks ago".
  final String meta;
  final String text;
}

/// A group of choices on a product: "Weight" with 3U and 4U.
class OptionGroup {
  const OptionGroup(this.title, this.values);
  final String title;
  final List<String> values;
}

/// Everything a product page shows.
class ProductDetail {
  const ProductDetail({
    required this.product,
    this.headline = '',
    this.about = const [],
    this.options = const [],
    this.reviews = const [],
    this.ratings = 0,
    this.arrives = '',
    this.videoTitle,
    this.related = const [],
  });

  final Product product;

  /// "Carbon racket 4U, head-light, for fast doubles".
  final String headline;
  final List<String> about;
  final List<OptionGroup> options;
  final List<Review> reviews;
  final int ratings;

  /// "Arrives Mon 5 to Wed 7 Oct, delivery from S$1.99".
  final String arrives;
  final String? videoTitle;
  final List<Product> related;
}

class Voucher {
  const Voucher(this.title, this.condition, {this.claimed = false});
  final String title;
  final String condition;
  final bool claimed;
}

/// A shop's page.
class MallDetail {
  const MallDetail({
    required this.mall,
    this.about = '',
    this.rating = 0,
    this.ratings = 0,
    this.followers = 0,
    this.following = false,
    this.replyTime = '1 hr',
    this.vouchers = const [],
    this.facts = const [],
    this.products = const [],
  });

  final Mall mall;
  final String about;
  final double rating;
  final int ratings;
  final int followers;
  final bool following;
  final String replyTime;
  final List<Voucher> vouchers;

  /// Business details, label and value.
  final List<(String, String)> facts;
  final List<Product> products;
}

/// A shoppable video.
class ShopVideo {
  const ShopVideo({
    required this.id,
    required this.title,
    required this.creator,
    required this.creatorMark,
    required this.product,
    this.views = 0,
    this.likes = 0,
    this.paid = false,
  });

  final String id;
  final String title;
  final String creator;
  final String creatorMark;
  final Product product;
  final int views;
  final int likes;

  /// A paid partnership with the shop.
  final bool paid;
}

/// A live stream with products to buy.
class LiveStream {
  const LiveStream({
    required this.id,
    required this.title,
    required this.shop,
    required this.shopMark,
    required this.host,
    required this.watching,
    required this.products,
    this.livePriceCents = const {},
    this.chat = const [],
  });

  final String id;
  final String title;
  final String shop;
  final String shopMark;
  final String host;
  final int watching;
  final List<Product> products;

  /// Live-only prices by product id.
  final Map<String, int> livePriceCents;
  final List<(String, String)> chat;
}

/// A line in the cart.
class CartLine {
  const CartLine({
    required this.id,
    required this.product,
    this.variant = '',
    this.qty = 1,
  });

  final String id;
  final Product product;
  final String variant;
  final int qty;

  int get totalCents => product.priceCents * qty;
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.name,
    required this.line,
    this.phone = '',
    this.isDefault = false,
    this.pickup = false,
  });

  final String id;

  /// "Home", "Office".
  final String label;
  final String name;
  final String line;
  final String phone;
  final bool isDefault;

  /// Collect at a venue desk instead of delivery.
  final bool pickup;
}

class Delivery {
  const Delivery(this.name, this.sub, this.cents);
  final String name;
  final String sub;
  final int cents;

  static const options = [
    Delivery('Standard', 'Arrives in 3 to 5 working days', 199),
    Delivery('Express', 'Arrives tomorrow', 499),
    Delivery('Pick up', 'At the venue front desk, from Monday', 0),
  ];
}

enum OrderStep {
  toPay('To pay'),
  packing('Packing'),
  shipped('On the way'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStep(this.label);
  final String label;
}

class OrderLine {
  const OrderLine(
    this.name,
    this.variant,
    this.qty,
    this.priceCents, {
    this.art = ProductArt.bag,
  });
  final String name;
  final String variant;
  final int qty;
  final int priceCents;

  /// The product's picture.
  final ProductArt art;
}

/// One shop's part of an order.
class Order {
  const Order({
    required this.id,
    required this.mallId,
    required this.mallName,
    required this.lines,
    required this.placedAt,
    required this.step,
    this.voucherCents = 0,
    this.deliveryCents = 0,
    this.pointsCents = 0,
    this.paidWith = 'Card',
    this.address,
    this.delivery = 'Standard',
    this.arrives,
    this.tracking,
    this.courier,
    this.buyer = '',
    this.refundCents = 0,
    this.refundTo,
    this.service = false,
    this.booking,
    this.received = false,
    this.deliveredAt,
    this.buyerId = '',
    this.ownerId = '',
    this.reviewed = false,
    this.returnState,
    this.returnReason,
  });

  final String id;
  final String mallId;
  final String mallName;
  final List<OrderLine> lines;
  final DateTime placedAt;
  final OrderStep step;
  final int voucherCents;
  final int deliveryCents;

  /// Points used, as cents off (1 point is S$1).
  final int pointsCents;
  final String paidWith;
  final Address? address;
  final String delivery;
  final DateTime? arrives;
  final String? tracking;
  final String? courier;

  /// The buyer's name, for the seller.
  final String buyer;
  final int refundCents;
  final String? refundTo;
  final bool service;

  /// "Sat 10 Oct, 10:00 AM" for a booked service.
  final String? booking;
  final bool received;
  final DateTime? deliveredAt;

  /// Who to message: the buyer (for the seller) and the shop's owner.
  final String buyerId;
  final String ownerId;
  final bool reviewed;

  /// 'requested', 'accepted' or 'declined' once a return is asked for.
  final String? returnState;

  /// "Wrong size · Refund to Wallet".
  final String? returnReason;

  int get itemsCents => lines.fold(0, (a, l) => a + l.priceCents * l.qty);
  int get totalCents => itemsCents - voucherCents + deliveryCents - pointsCents;

  /// "Carbon racket 4U and 1 more".
  String get summary => lines.length == 1
      ? lines.first.name
      : '${lines.first.name} and ${lines.length - 1} more';

  Order copyWith({
    OrderStep? step,
    String? tracking,
    String? courier,
    int? refundCents,
    String? refundTo,
    bool? received,
    bool? reviewed,
    String? returnState,
    String? returnReason,
  }) => Order(
    id: id,
    mallId: mallId,
    mallName: mallName,
    lines: lines,
    placedAt: placedAt,
    step: step ?? this.step,
    voucherCents: voucherCents,
    deliveryCents: deliveryCents,
    pointsCents: pointsCents,
    paidWith: paidWith,
    address: address,
    delivery: delivery,
    arrives: arrives,
    tracking: tracking ?? this.tracking,
    courier: courier ?? this.courier,
    buyer: buyer,
    refundCents: refundCents ?? this.refundCents,
    refundTo: refundTo ?? this.refundTo,
    service: service,
    booking: booking,
    received: received ?? this.received,
    deliveredAt: deliveredAt,
    buyerId: buyerId,
    ownerId: ownerId,
    reviewed: reviewed ?? this.reviewed,
    returnState: returnState ?? this.returnState,
    returnReason: returnReason ?? this.returnReason,
  );
}

/// The seller's dashboard numbers.
class SellerSummary {
  const SellerSummary({
    required this.mall,
    this.salesTodayCents = 0,
    this.toShip = 0,
    this.onTheWay = 0,
    this.returns = 0,
    this.listed = 0,
    this.lowStock = 0,
    this.readyCents = 0,
    this.voucher = '',
  });

  final Mall mall;
  final int salesTodayCents;
  final int toShip;
  final int onTheWay;
  final int returns;
  final int listed;
  final int lowStock;
  final int readyCents;
  final String voucher;
}

/// Olympus keeps 8% of shop sales; buyers pay no platform fee.
int shopCommission(int cents) => (cents * 0.08).round();
