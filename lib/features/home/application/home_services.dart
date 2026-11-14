import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/og_icon.dart';

part 'home_services.g.dart';

/// A shortcut on Home: one of Your favourites, or in More services.
enum HomeService {
  play('Play', 'Find a game to join', OgIcons.racquet),
  group('Group', 'Clubs and teams', OgIcons.group),
  academy('Academy', 'Classes and coaching', OgIcons.mortarboard),
  venue('Venue', 'Find and book courts', OgIcons.mapPin),
  game('Game', 'Campaigns and challenges', OgIcons.trophyTeam),
  shop('Shop', 'Gear, services and malls', OgIcons.bag),
  wallet('Wallet', 'Balance, refunds and history', OgIcons.walletCard),
  points('Points', 'Earn by playing, spend in the Shop', OgIcons.pointsStar),
  tickets('Tickets', 'Event tickets and entry codes', OgIcons.ticket),
  rankings('Rankings', 'Leaderboards across campaigns', OgIcons.podium),
  gear('My gear', 'Rackets, shoes and strings', OgIcons.racquetStrings),
  orders('Orders', 'Shop orders and returns', OgIcons.cart);

  const HomeService(this.label, this.sub, this.icon);
  final String label;
  final String sub;
  final String icon;

  String get route => switch (this) {
    play => Routes.play,
    group => Routes.clubs,
    academy => Routes.academies,
    venue => Routes.venues,
    game => Routes.game,
    shop => Routes.shop,
    wallet => Routes.wallet,
    points => Routes.points,
    tickets => Routes.myTickets,
    rankings => Routes.leaderboards,
    gear => Routes.gear,
    orders => Routes.orders(),
  };
}

/// The order of Home's services, and which four are favourites.
typedef HomeServices = ({List<HomeService> order, Set<HomeService> favourites});

/// Your favourites is a 2 × 2 grid.
const homeFavouriteCount = 4;

const _defaultFavourites = {
  HomeService.play,
  HomeService.group,
  HomeService.academy,
  HomeService.venue,
};

/// Saved on the device, like other display choices.
@Riverpod(keepAlive: true)
class HomeServicesController extends _$HomeServicesController {
  static const _key = 'og_home_services';
  static const _storage = FlutterSecureStorage();

  @override
  HomeServices build() {
    _load();
    return (order: HomeService.values, favourites: _defaultFavourites);
  }

  /// "play,group,-game,…": the order, with non-favourites marked "-".
  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved == null || saved.isEmpty) return;
    final order = <HomeService>[];
    final favourites = <HomeService>{};
    for (final part in saved.split(',')) {
      final name = part.replaceFirst('-', '');
      final s = HomeService.values.where((s) => s.name == name).firstOrNull;
      if (s == null || order.contains(s)) continue;
      order.add(s);
      if (!part.startsWith('-')) favourites.add(s);
    }
    // Services added in a later version go at the end of More services.
    for (final s in HomeService.values) {
      if (!order.contains(s)) order.add(s);
    }
    // A service removed in a later version can leave fewer than four.
    if (favourites.length != homeFavouriteCount) return;
    state = (order: order, favourites: favourites);
  }

  Future<void> save(HomeServices value) async {
    state = value;
    await _storage.write(
      key: _key,
      value: value.order
          .map((s) => value.favourites.contains(s) ? s.name : '-${s.name}')
          .join(','),
    );
  }
}

extension HomeServicesX on HomeServices {
  /// Your favourites, in the chosen order.
  List<HomeService> get favouriteList => [
    for (final s in order)
      if (favourites.contains(s)) s,
  ];

  /// Everything else, for More services.
  List<HomeService> get moreList => [
    for (final s in order)
      if (!favourites.contains(s)) s,
  ];
}
