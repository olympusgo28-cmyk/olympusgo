// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(malls)
final mallsProvider = MallsProvider._();

final class MallsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Mall>>,
          List<Mall>,
          FutureOr<List<Mall>>
        >
    with $FutureModifier<List<Mall>>, $FutureProvider<List<Mall>> {
  MallsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mallsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mallsHash();

  @$internal
  @override
  $FutureProviderElement<List<Mall>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Mall>> create(Ref ref) {
    return malls(ref);
  }
}

String _$mallsHash() => r'8cc951082e1f2365986db8f2bc56bb73334a3df3';

@ProviderFor(popularProducts)
final popularProductsProvider = PopularProductsProvider._();

final class PopularProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          FutureOr<List<Product>>
        >
    with $FutureModifier<List<Product>>, $FutureProvider<List<Product>> {
  PopularProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'popularProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$popularProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Product>> create(Ref ref) {
    return popularProducts(ref);
  }
}

String _$popularProductsHash() => r'b139ae6223ce5573ef2b19690bc6bae98c192240';

@ProviderFor(shopProducts)
final shopProductsProvider = ShopProductsFamily._();

final class ShopProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          FutureOr<List<Product>>
        >
    with $FutureModifier<List<Product>>, $FutureProvider<List<Product>> {
  ShopProductsProvider._({
    required ShopProductsFamily super.from,
    required (String?, String) super.argument,
  }) : super(
         retry: null,
         name: r'shopProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopProductsHash();

  @override
  String toString() {
    return r'shopProductsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Product>> create(Ref ref) {
    final argument = this.argument as (String?, String);
    return shopProducts(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopProductsHash() => r'a482ee0837a2f099c0cf9cc790a5bc6d2f26eb53';

final class ShopProductsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Product>>, (String?, String)> {
  ShopProductsFamily._()
    : super(
        retry: null,
        name: r'shopProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShopProductsProvider call(String? mallId, String query) =>
      ShopProductsProvider._(argument: (mallId, query), from: this);

  @override
  String toString() => r'shopProductsProvider';
}

@ProviderFor(shopDeals)
final shopDealsProvider = ShopDealsProvider._();

final class ShopDealsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          FutureOr<List<Product>>
        >
    with $FutureModifier<List<Product>>, $FutureProvider<List<Product>> {
  ShopDealsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shopDealsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shopDealsHash();

  @$internal
  @override
  $FutureProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Product>> create(Ref ref) {
    return shopDeals(ref);
  }
}

String _$shopDealsHash() => r'219df811811d5e5d4a1767e4a18b20684f907df3';

@ProviderFor(productDetail)
final productDetailProvider = ProductDetailFamily._();

final class ProductDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductDetail>,
          ProductDetail,
          FutureOr<ProductDetail>
        >
    with $FutureModifier<ProductDetail>, $FutureProvider<ProductDetail> {
  ProductDetailProvider._({
    required ProductDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productDetailHash();

  @override
  String toString() {
    return r'productDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProductDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProductDetail> create(Ref ref) {
    final argument = this.argument as String;
    return productDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productDetailHash() => r'4fcbb9a657e60a729d4f641c220e93917a139143';

final class ProductDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProductDetail>, String> {
  ProductDetailFamily._()
    : super(
        retry: null,
        name: r'productDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductDetailProvider call(String id) =>
      ProductDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'productDetailProvider';
}

@ProviderFor(mallDetail)
final mallDetailProvider = MallDetailFamily._();

final class MallDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<MallDetail>,
          MallDetail,
          FutureOr<MallDetail>
        >
    with $FutureModifier<MallDetail>, $FutureProvider<MallDetail> {
  MallDetailProvider._({
    required MallDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mallDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mallDetailHash();

  @override
  String toString() {
    return r'mallDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MallDetail> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MallDetail> create(Ref ref) {
    final argument = this.argument as String;
    return mallDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MallDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mallDetailHash() => r'76487c478849453f9443780984852496ec3e44b4';

final class MallDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MallDetail>, String> {
  MallDetailFamily._()
    : super(
        retry: null,
        name: r'mallDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MallDetailProvider call(String id) =>
      MallDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'mallDetailProvider';
}

@ProviderFor(cart)
final cartProvider = CartProvider._();

final class CartProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CartLine>>,
          List<CartLine>,
          FutureOr<List<CartLine>>
        >
    with $FutureModifier<List<CartLine>>, $FutureProvider<List<CartLine>> {
  CartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartHash();

  @$internal
  @override
  $FutureProviderElement<List<CartLine>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CartLine>> create(Ref ref) {
    return cart(ref);
  }
}

String _$cartHash() => r'c68a754f8bf794c7777d22508ee4e608e3e5f3f8';

@ProviderFor(myOrders)
final myOrdersProvider = MyOrdersProvider._();

final class MyOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          FutureOr<List<Order>>
        >
    with $FutureModifier<List<Order>>, $FutureProvider<List<Order>> {
  MyOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myOrdersHash();

  @$internal
  @override
  $FutureProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Order>> create(Ref ref) {
    return myOrders(ref);
  }
}

String _$myOrdersHash() => r'6c1ed9933b590ec1158d490c3cb3c8b1f45d83d9';

@ProviderFor(orderDetail)
final orderDetailProvider = OrderDetailFamily._();

final class OrderDetailProvider
    extends $FunctionalProvider<AsyncValue<Order>, Order, FutureOr<Order>>
    with $FutureModifier<Order>, $FutureProvider<Order> {
  OrderDetailProvider._({
    required OrderDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDetailHash();

  @override
  String toString() {
    return r'orderDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Order> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Order> create(Ref ref) {
    final argument = this.argument as String;
    return orderDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDetailHash() => r'572ca9c98a62718235282d38fff53174b6b0d7db';

final class OrderDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Order>, String> {
  OrderDetailFamily._()
    : super(
        retry: null,
        name: r'orderDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderDetailProvider call(String id) =>
      OrderDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'orderDetailProvider';
}

/// The shop this account runs, if any.

@ProviderFor(myShop)
final myShopProvider = MyShopProvider._();

/// The shop this account runs, if any.

final class MyShopProvider
    extends $FunctionalProvider<AsyncValue<Mall?>, Mall?, FutureOr<Mall?>>
    with $FutureModifier<Mall?>, $FutureProvider<Mall?> {
  /// The shop this account runs, if any.
  MyShopProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myShopProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myShopHash();

  @$internal
  @override
  $FutureProviderElement<Mall?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Mall?> create(Ref ref) {
    return myShop(ref);
  }
}

String _$myShopHash() => r'8412d19515af86304fd2eb9bbb3d2ecbbdb0d977';

@ProviderFor(ownerOrders)
final ownerOrdersProvider = OwnerOrdersProvider._();

final class OwnerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          FutureOr<List<Order>>
        >
    with $FutureModifier<List<Order>>, $FutureProvider<List<Order>> {
  OwnerOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerOrdersHash();

  @$internal
  @override
  $FutureProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Order>> create(Ref ref) {
    return ownerOrders(ref);
  }
}

String _$ownerOrdersHash() => r'4e44483fcf7d3a4f7559ff55503d08f3a78c6f16';
