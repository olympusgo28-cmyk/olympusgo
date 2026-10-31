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
    this.collectLine = '',
    this.related = const [],
  });

  final Product product;

  /// "Carbon racket 4U, head-light, for fast doubles".
  final String headline;
  final List<String> about;
  final List<OptionGroup> options;
  final List<Review> reviews;
  final int ratings;

  /// "Collect from Racket Lab".
  final String collectLine;
  final List<Product> related;
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
    this.verified = true,
    this.replyTime = '1 hr',
    this.facts = const [],
    this.products = const [],
  });

  final Mall mall;
  final String about;
  final double rating;
  final int ratings;
  final int followers;
  final bool following;
  final bool verified;
  final String replyTime;

  /// Business details, label and value.
  final List<(String, String)> facts;
  final List<Product> products;
}

/// A line in the cart.
class CartLine {
  const CartLine({
    required this.id,
    required this.product,
    this.variant = '',
    this.qty = 1,
    this.slot,
  });

  final String id;
  final Product product;
  final String variant;
  final int qty;

  /// The drop-off time, for a service.
  final DateTime? slot;

  int get totalCents => product.priceCents * qty;
}

enum OrderStep {
  pending('To pay'),
  paid('Paid'),
  started('In progress'),
  ready('Ready to collect'),
  collected('Collected'),
  reported('Problem reported'),
  cancelled('Cancelled'),
  expired('Expired'),
  released('Complete'),
  refunded('Refunded');

  const OrderStep(this.label);
  final String label;

  /// Paid, and not yet handed over.
  bool get waiting =>
      this == OrderStep.paid ||
      this == OrderStep.started ||
      this == OrderStep.ready;
  bool get closed => this == OrderStep.collected || this == OrderStep.released;
  bool get ended =>
      this == OrderStep.cancelled ||
      this == OrderStep.expired ||
      this == OrderStep.refunded;
}

class OrderLine {
  const OrderLine(
    this.name,
    this.variant,
    this.qty,
    this.priceCents, {
    this.id = '',
    this.productId = '',
    this.pointsCents = 0,
    this.shopCents = 0,
    this.refundedQty = 0,
    this.art = ProductArt.bag,
  });
  final String id;
  final String productId;
  final String name;
  final String variant;
  final int qty;

  /// What the buyer pays for one, before points.
  final int priceCents;

  /// Points taken off one, in cents.
  final int pointsCents;

  /// What the shop gets for one.
  final int shopCents;
  final int refundedQty;

  /// The product's picture.
  final ProductArt art;
}

/// One shop, one payment.
class Order {
  const Order({
    required this.id,
    required this.mallId,
    required this.mallName,
    required this.lines,
    required this.placedAt,
    required this.step,
    this.collectAddress = '',
    this.collectBy,
    this.releaseAt,
    this.readyAt,
    this.collectedAt,
    this.holdUntil,
    this.serverNow,
    this.slotAt,
    this.service = false,
    this.reviewed = false,
    this.buyer = '',
    this.buyerId = '',
    this.ownerId = '',
    this.paymentId,
    this.paymentMethod,
    this.paymentStatus = 'succeeded',
    this.receiptNo = '',
    this.refundedCents = 0,
    this.refundStatus,
    this.disputeStatus,
  });

  final String id;
  final String mallId;
  final String mallName;
  final List<OrderLine> lines;
  final DateTime placedAt;
  final OrderStep step;
  final String collectAddress;

  /// The last day to collect, or the booked slot for a service.
  final DateTime? collectBy;

  /// When the payout goes to the shop by itself.
  final DateTime? releaseAt;
  final DateTime? readyAt;
  final DateTime? collectedAt;
  final DateTime? holdUntil;
  final DateTime? serverNow;

  /// The drop-off time for a service.
  final DateTime? slotAt;
  final bool service;
  final bool reviewed;

  /// The buyer's name, for the shop.
  final String buyer;

  /// Who to message: the buyer (for the shop) and the shop's owner.
  final String buyerId;
  final String ownerId;
  final String? paymentId;
  final String? paymentMethod;

  /// succeeded, pending, cancel_requested or cancelled. Empty for the shop.
  final String paymentStatus;
  final String receiptNo;
  final int refundedCents;

  /// pending, done or failed, once a refund exists.
  final String? refundStatus;

  /// open, won or lost, once the buyer's bank disputes the payment.
  final String? disputeStatus;

  int get itemsCents => lines.fold(0, (a, l) => a + l.priceCents * l.qty);
  int get pointsCents => lines.fold(0, (a, l) => a + l.pointsCents * l.qty);
  int get totalCents => itemsCents - pointsCents;

  /// What the shop gets for the order, after refunds. Only the shop sees this.
  int get shopCents => step.ended
      ? 0
      : lines.fold(0, (a, l) => a + l.shopCents * (l.qty - l.refundedQty));

  /// The money really arrived.
  bool get paid => paymentStatus == 'succeeded';

  /// "Card", "PayNow".
  String get paidWith => paymentMethod == 'paynow' ? 'PayNow' : 'Card';

  /// The buyer can still get out of it, on the server's clock. Only a ready
  /// order's clock runs out, and a ready service is finished work.
  bool get canCancel =>
      step == OrderStep.pending ||
      step == OrderStep.paid ||
      (step == OrderStep.ready &&
          !service &&
          (releaseAt == null ||
              (serverNow ?? DateTime.now()).isBefore(releaseAt!)));

  /// "Carbon racket 4U and 1 more".
  String get summary => lines.length == 1
      ? lines.first.name
      : '${lines.first.name} and ${lines.length - 1} more';

  Order copyWith({
    OrderStep? step,
    int? refundedCents,
    bool? reviewed,
    DateTime? readyAt,
    DateTime? collectedAt,
    String? refundStatus,
  }) => Order(
    id: id,
    mallId: mallId,
    mallName: mallName,
    lines: lines,
    placedAt: placedAt,
    step: step ?? this.step,
    collectAddress: collectAddress,
    collectBy: collectBy,
    releaseAt: releaseAt,
    readyAt: readyAt ?? this.readyAt,
    collectedAt: collectedAt ?? this.collectedAt,
    holdUntil: holdUntil,
    serverNow: serverNow,
    slotAt: slotAt,
    service: service,
    reviewed: reviewed ?? this.reviewed,
    buyer: buyer,
    buyerId: buyerId,
    ownerId: ownerId,
    paymentId: paymentId,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    receiptNo: receiptNo,
    refundedCents: refundedCents ?? this.refundedCents,
    refundStatus: refundStatus ?? this.refundStatus,
    disputeStatus: disputeStatus,
  );
}

/// One line of a checkout, as the server priced it.
class QuoteLine {
  const QuoteLine({
    required this.name,
    required this.variant,
    required this.qty,
    required this.priceCents,
    required this.pointsCents,
  });

  final String name;
  final String variant;
  final int qty;

  /// What the buyer pays for one, before points.
  final int priceCents;

  /// Points taken off one, in cents.
  final int pointsCents;
}

/// The final price before paying, from the same arithmetic as the charge.
class ShopQuote {
  const ShopQuote({
    required this.lines,
    required this.totalCents,
    required this.pointsCapCents,
    required this.pointsLeftCents,
    required this.pointsBalanceCents,
    required this.canRedeem,
    required this.collectAddress,
    required this.refundRule,
    required this.canPay,
  });

  final List<QuoteLine> lines;
  final int totalCents;

  /// The most points this order can take.
  final int pointsCapCents;

  /// Points asked for that didn't fit.
  final int pointsLeftCents;
  final int pointsBalanceCents;
  final bool canRedeem;
  final String collectAddress;
  final String refundRule;
  final bool canPay;

  int get itemsCents => lines.fold(0, (a, l) => a + l.priceCents * l.qty);
  int get pointsCents => lines.fold(0, (a, l) => a + l.pointsCents * l.qty);
}
