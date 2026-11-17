import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import 'guardian_providers.dart';

/// For screens that list links: whether this player may open a route. A
/// player waiting on a parent may only open some screens (R-AGE), and the
/// router would send any other link straight back.
bool Function(String route) routeAccess(WidgetRef ref) {
  final restricted = ref.watch(restrictionsProvider).value?.restricted ?? false;
  return (route) =>
      !restricted || Routes.restrictedPrefixes.any(route.startsWith);
}
