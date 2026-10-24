import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_models.freezed.dart';

/// A shop in the mall, shown as a tile on Home and in the Shop.
@freezed
abstract class Mall with _$Mall {
  const factory Mall({
    required String id,
    required String name,
    required String initials,
    @Default('') String blurb,
    @Default(0xFFFBE7B0) int color,
    @Default(0xFF5A4300) int ink,
    @Default(true) bool pointsAccepted,

    /// The player who runs it, for chat.
    @Default('') String ownerId,
  }) = _Mall;
}

enum ProductArt { racquet, bag }

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String mallId,
    required String mallName,
    required int priceCents,

    /// Points the buyer can spend on it.
    @Default(0) int maxPoints,
    @Default(ProductArt.bag) ProductArt art,

    /// The price before a deal, when there is one.
    int? oldPriceCents,
    @Default(0) double rating,
    @Default(0) int sold,

    /// "Coach Ravi", the creator who plays with it.
    String? usedBy,

    /// A service is booked (restringing), not shipped.
    @Default(false) bool service,
    @Default(10) int stock,

    /// For the seller: draft, live.
    @Default(true) bool published,

    /// What the seller wrote about it.
    @Default('') String description,
  }) = _Product;

  const Product._();

  /// "17% off".
  String? get deal => oldPriceCents == null || oldPriceCents! <= priceCents
      ? null
      : '${((1 - priceCents / oldPriceCents!) * 100).round()}% off';

  /// "4.8, 1.2k sold", or "New" before anyone has bought or rated it.
  String get soldLine => sold == 0 && rating == 0
      ? 'New'
      : [
          if (rating > 0) rating.toStringAsFixed(1),
          '${sold >= 1000 ? '${(sold / 1000).toStringAsFixed(1)}k' : sold} sold',
        ].join(', ');

  /// Two letters for the product tile: "CR" for Carbon racket.
  String get mark {
    final words = name.split(RegExp(r'[\s,]+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }
}
