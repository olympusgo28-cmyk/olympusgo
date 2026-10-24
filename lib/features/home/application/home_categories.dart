import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/og_icon.dart';

part 'home_categories.g.dart';

/// A shortcut in Home's Categories grid.
enum HomeCategory {
  play('Play', 'Meets, tournaments, events', OgIcons.racquet, Routes.play),
  group('Group', 'Clubs and teams', OgIcons.group, Routes.clubs),
  academy(
    'Academy',
    'Classes and coaching',
    OgIcons.mortarboard,
    Routes.academies,
  ),
  game('Game', 'Campaigns and challenges', OgIcons.trophyTeam, Routes.game),
  venue('Venue', 'Find and book courts', OgIcons.mapPin, Routes.venues),
  shop('Shop', 'Gear, services and malls', OgIcons.bag, Routes.shop);

  const HomeCategory(this.label, this.sub, this.icon, this.route);
  final String label;
  final String sub;
  final String icon;
  final String route;
}

/// The order of Home's categories, and which are shown.
typedef HomeCategories = ({List<HomeCategory> order, Set<HomeCategory> shown});

/// At least this many stay on.
const minHomeCategories = 3;

/// Saved on the device, like other display choices.
@Riverpod(keepAlive: true)
class HomeCategoriesController extends _$HomeCategoriesController {
  static const _key = 'og_home_categories';
  static const _storage = FlutterSecureStorage();

  @override
  HomeCategories build() {
    _load();
    return (order: HomeCategory.values, shown: HomeCategory.values.toSet());
  }

  /// "play,group,-academy,…": the order, with hidden ones marked "-".
  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved == null || saved.isEmpty) return;
    final order = <HomeCategory>[];
    final shown = <HomeCategory>{};
    for (final part in saved.split(',')) {
      final name = part.replaceFirst('-', '');
      final c = HomeCategory.values.where((c) => c.name == name).firstOrNull;
      if (c == null || order.contains(c)) continue;
      order.add(c);
      if (!part.startsWith('-')) shown.add(c);
    }
    // Categories added in a later version go at the end, switched on.
    for (final c in HomeCategory.values) {
      if (!order.contains(c)) order.add(c);
      if (!saved.contains(c.name)) shown.add(c);
    }
    state = (order: order, shown: shown);
  }

  Future<void> save(HomeCategories value) async {
    state = value;
    await _storage.write(
      key: _key,
      value: value.order
          .map((c) => value.shown.contains(c) ? c.name : '-${c.name}')
          .join(','),
    );
  }
}
