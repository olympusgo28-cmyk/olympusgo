import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/home/application/home_services.dart';

/// Home's favourites and More services, saved on the device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = <String, String>{};

  setUp(() {
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = (call.arguments as Map?) ?? const {};
            switch (call.method) {
              case 'read':
                return store[args['key']];
              case 'write':
                store[args['key'] as String] = args['value'] as String;
            }
            return null;
          },
        );
  });

  Future<HomeServices> load() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(homeServicesControllerProvider, (_, _) {});
    // Let the device read finish.
    await Future<void>.delayed(Duration.zero);
    return container.read(homeServicesControllerProvider);
  }

  test('starts with four favourites and the rest in More services', () async {
    final s = await load();
    expect(s.favouriteList, [
      HomeService.play,
      HomeService.group,
      HomeService.academy,
      HomeService.venue,
    ]);
    expect(s.moreList, hasLength(HomeService.values.length - 4));
    expect(s.moreList, isNot(contains(HomeService.play)));
  });

  test('keeps the chosen favourites and order', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final order = [...HomeService.values.reversed];
    await container.read(homeServicesControllerProvider.notifier).save((
      order: order,
      favourites: {
        HomeService.shop,
        HomeService.wallet,
        HomeService.points,
        HomeService.play,
      },
    ));

    final s = await load();
    expect(s.order, order);
    // Favourites follow the saved order.
    expect(s.favouriteList, [
      HomeService.points,
      HomeService.wallet,
      HomeService.shop,
      HomeService.play,
    ]);
  });

  test('ignores a saved value without exactly four favourites', () async {
    store['og_home_services'] = 'play,group,-academy';
    final s = await load();
    expect(s.favourites, hasLength(homeFavouriteCount));
    expect(s.order, HomeService.values);
  });
}
