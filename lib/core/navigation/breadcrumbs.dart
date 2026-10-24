import 'package:flutter/widgets.dart';

/// Keeps one navigator's stack, so screens can see what is underneath them.
class StackObserver extends NavigatorObserver {
  StackObserver([this.tab]);

  /// Set for a tab's navigator: its first screen is named after the tab.
  final String? tab;
  final routes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : routes.indexOf(oldRoute);
    if (newRoute == null) return;
    i < 0 ? routes.add(newRoute) : routes[i] = newRoute;
  }
}

/// A screen below the current one, by its title.
class Crumb {
  const Crumb(this.route, this.title);
  final Route<dynamic> route;
  final String title;
}

/// Screen titles and navigator stacks for the back label and the trail.
///
/// The app has a root navigator (screens pushed over the tabs) and one
/// navigator per tab. The trail for a screen is: the open tab's screens,
/// then the root screens up to it.
abstract final class Crumbs {
  static final root = StackObserver();
  static final tabs = [
    for (final t in const ['Home', 'Discover', 'Scan', 'Inbox', 'Profile'])
      StackObserver(t),
  ];

  /// The route that shows the tab shell, and the open tab.
  static Route<dynamic>? shellRoute;
  static int tab = 0;

  static final _titles = Expando<String>('crumb title');

  /// Names the screen [context] is on, for the screens above it.
  static void name(BuildContext context, String title) {
    final route = ModalRoute.of(context);
    if (route != null && title.trim().isNotEmpty) _titles[route] = title;
  }

  static String? _title(Route<dynamic> r, StackObserver nav) =>
      _titles[r] ??
      (nav.tab != null && nav.routes.firstOrNull == r ? nav.tab : null);

  static List<Crumb> _from(StackObserver nav, int end) => [
    for (final r in nav.routes.take(end))
      if (_title(r, nav) case final t?) Crumb(r, t),
  ];

  /// The screens underneath the one [context] is on, oldest first, with
  /// repeats (steps of one flow) collapsed to the latest.
  static List<Crumb> below(BuildContext context) {
    final me = ModalRoute.of(context);
    if (me == null) return const [];
    final out = <Crumb>[];
    // go_router also tells the root's observer about pushes inside the tab
    // navigators, so keep only the routes the root navigator really holds.
    final rootNav = shellRoute?.navigator;
    final rootRoutes = rootNav == null
        ? root.routes
        : root.routes.where((r) => r.navigator == rootNav).toList();
    final i = rootRoutes.indexOf(me);
    if (i >= 0) {
      for (final r in rootRoutes.take(i)) {
        if (r == shellRoute) {
          final nav = tabs[tab];
          out.addAll(_from(nav, nav.routes.length));
        } else if (_title(r, root) case final t?) {
          out.add(Crumb(r, t));
        }
      }
    } else {
      for (final nav in tabs) {
        final j = nav.routes.indexOf(me);
        if (j >= 0) out.addAll(_from(nav, j));
      }
    }
    final mine = _titles[me];
    return [
      for (var k = 0; k < out.length; k++)
        if ((k + 1 < out.length ? out[k + 1].title : mine) != out[k].title)
          out[k],
    ];
  }

  /// Goes back to [crumb]'s screen, closing everything above it.
  static void popTo(Crumb crumb) {
    final nav = crumb.route.navigator;
    final rootNav = shellRoute?.navigator ?? root.navigator;
    if (nav == null) return;
    if (nav != rootNav && rootNav != null && shellRoute != null) {
      rootNav.popUntil((r) => r == shellRoute);
    }
    nav.popUntil((r) => r == crumb.route);
  }
}
