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
Future<List<CartLine>> cart(Ref ref) =>
    ref.watch(shopRepositoryProvider).cart();

@riverpod
Future<List<Order>> myOrders(Ref ref) =>
    ref.watch(shopRepositoryProvider).orders();

@riverpod
Future<Order> orderDetail(Ref ref, String id) =>
    ref.watch(shopRepositoryProvider).order(id);

/// The shop this account runs, if any.
@riverpod
Future<Mall?> myShop(Ref ref) => ref.watch(shopRepositoryProvider).myShop();

@riverpod
Future<List<Order>> ownerOrders(Ref ref) =>
    ref.watch(shopRepositoryProvider).ownerOrders();

/// Refreshes the shop after the cart, an order or a listing changes.
void refreshShop(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(cartProvider);
  invalidate(myOrdersProvider);
  invalidate(orderDetailProvider);
  invalidate(ownerOrdersProvider);
  invalidate(shopProductsProvider);
  invalidate(productDetailProvider);
  invalidate(mallDetailProvider);
}
