import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/router/app_router.dart';
import 'package:olympus_go/core/theme/og_theme.dart';

/// iOS swipe-back must work for screens pushed over the tab shell.
void main() {
  testWidgets('edge swipe pops a screen pushed over the tab shell', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/settings',
          pageBuilder: (_, s) =>
              cupertinoPage(s, const Scaffold(body: Text('Settings'))),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  pageBuilder: (_, s) =>
                      cupertinoPage(s, const Scaffold(body: Text('Home'))),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    router.push('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.dragFrom(const Offset(5, 300), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
