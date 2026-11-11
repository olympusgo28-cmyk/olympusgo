// A page inside a tab, pushed from a page outside the tabs (Settings), builds
// the tab shell twice and trips Flutter's duplicate page key assertion. Every
// page under Profile that other screens open sits on the root navigator.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/router/app_router.dart';
import 'package:olympus_go/core/router/routes.dart';

void main() {
  test('Profile\'s pages open on the root navigator', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    final profile = <GoRoute>[];
    void walk(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute && r.path == Routes.profile) profile.add(r);
        walk(r.routes);
      }
    }

    walk(router.configuration.routes);
    expect(profile, hasLength(1));
    final pages = profile.single.routes.whereType<GoRoute>().toList();
    expect(
      pages.map((r) => r.path),
      containsAll(['schedule', 'saved', 'passport', 'sport-passport']),
    );
    for (final page in pages) {
      expect(page.parentNavigatorKey, rootKey, reason: page.path);
    }
  });
}
