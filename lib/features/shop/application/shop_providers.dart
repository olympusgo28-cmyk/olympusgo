import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/commerce_models.dart';
import '../domain/shop_models.dart';

part 'shop_providers.g.dart';

@riverpod
Future<List<Mall>> malls(Ref ref) => ref.watch(shopRepositoryProvider).malls();

@riverpod
Future<List<Product>> popularProducts(Ref ref) =>
    ref.watch(shopRepositoryProvider).popular();

@riverpod
Future<List<Product>> shopProducts(Ref ref, String? mallId, String query) =>
    ref.watch(shopRepositoryProvider).products(mallId: mallId, query: query);

@riverpod
Future<List<Product>> shopDeals(Ref ref) =>
    ref.watch(shopRepositoryProvider).deals();

@riverpod
Future<ProductDetail> productDetail(Ref ref, String id) =>
    ref.watch(shopRepositoryProvider).product(id);

@riverpod
Future<MallDetail> mallDetail(Ref ref, String id) =>
    ref.watch(shopRepositoryProvider).mall(id);

@riverpod
Future<List<ShopVideo>> shopVideos(Ref ref) =>
    ref.watch(shopRepositoryProvider).videos();

@riverpod
Future<List<LiveStream>> shopLives(Ref ref) =>
    ref.watch(shopRepositoryProvider).lives();

@riverpod
Future<List<CartLine>> cart(Ref ref) =>
    ref.watch(shopRepositoryProvider).cart();

@riverpod
Future<List<Address>> addresses(Ref ref) =>
    ref.watch(shopRepositoryProvider).addresses();

@riverpod
Future<List<Order>> myOrders(Ref ref) =>
    ref.watch(shopRepositoryProvider).orders();

@riverpod
Future<Order> orderDetail(Ref ref, String id) =>
    ref.watch(shopRepositoryProvider).order(id);

@riverpod
Future<SellerSummary?> sellerSummary(Ref ref) =>
    ref.watch(shopRepositoryProvider).sellerSummary();

@riverpod
Future<List<Order>> sellerOrders(Ref ref) =>
    ref.watch(shopRepositoryProvider).sellerOrders();

@riverpod
Future<List<Product>> sellerProducts(Ref ref) =>
    ref.watch(shopRepositoryProvider).sellerProducts();

/// Refreshes the shop after the cart, an order or a listing changes.
void refreshShop(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(cartProvider);
  invalidate(myOrdersProvider);
  invalidate(orderDetailProvider);
  invalidate(sellerSummaryProvider);
  invalidate(sellerOrdersProvider);
  invalidate(sellerProductsProvider);
  invalidate(shopProductsProvider);
  invalidate(productDetailProvider);
  invalidate(mallDetailProvider);
  invalidate(addressesProvider);
}
