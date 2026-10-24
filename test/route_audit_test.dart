// Opens every screen in demo mode and records what goes wrong.
// Run with --dart-define=DEMO_SIGNED_IN=true for every screen, or without
// it for the welcome and log-in screens.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/config/env.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/app_router.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';

import 'route_audit_routes.dart';

/// Loads the app's fonts (copied from the simulator's google_fonts cache)
/// under the family names google_fonts asks for, e.g. "Archivo_800".
Future<void> _loadFonts() async {
  final dir = Directory(Platform.environment['AUDIT_FONTS'] ?? '');
  if (!dir.existsSync()) return;
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last.split('.').first;
    final family = name.replaceFirst(RegExp(r'_[0-9a-f]{64}$'), '');
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  testWidgets(
    'every screen opens without errors',
    timeout: const Timeout(Duration(minutes: 25)),
    (tester) async {
      // Signed out, only the welcome and log-in screens can open.
      final routes = Env.demoSignedIn
          ? auditRoutes
          : [
              for (final r in auditRoutes)
                if ([
                  ...Routes.publicPrefixes,
                  ...Routes.openPrefixes,
                ].any(r.$2.startsWith))
                  r,
            ];
      // iPhone 17: 402 × 874 points.
      tester.view.physicalSize = const Size(1206, 2622);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Listen like the app does, or Riverpod pauses these providers.
      container
        ..listen(appRouterProvider, (_, _) {})
        ..listen(currentUserIdProvider, (_, _) {})
        ..listen(sessionProfileProvider, (_, _) {});
      final router = container.read(appRouterProvider);
      // AUDIT_SHOTS=<dir> saves a picture of the screens named in
      // AUDIT_ONLY (comma-separated), or of every screen.
      final shots = Platform.environment['AUDIT_SHOTS'];
      final only = (Platform.environment['AUDIT_ONLY'] ?? '')
          .split(',')
          .where((n) => n.isNotEmpty)
          .toSet();
      final shotKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: shotKey,
          child: UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: OgTheme.light(),
              routerConfig: router,
            ),
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // ignore: avoid_print
      print(
        'user: ${container.read(currentUserIdProvider)} '
        'profile: ${container.read(sessionProfileProvider)} '
        'at: ${router.routerDelegate.currentConfiguration.uri}',
      );
      final report = StringBuffer();
      final original = FlutterError.onError;
      for (final (name, location) in routes) {
        final errors = <String>{};
        FlutterError.onError = (d) =>
            errors.add(d.exceptionAsString().split('\n').first.trim());
        final match = router.configuration.findMatch(Uri.parse(location));
        if (match.isError) {
          report.writeln('NO_SCREEN\t$name\t$location');
          FlutterError.onError = original;
          continue;
        }
        router.go(location);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 250));
          final e = tester.takeException();
          if (e != null) errors.add('$e'.split('\n').first);
        }
        final landed = router.routerDelegate.currentConfiguration.uri
            .toString();
        final notFound =
            find.textContaining('isn\'t available').evaluate().isNotEmpty ||
            find.textContaining('no longer').evaluate().isNotEmpty ||
            find.textContaining('not found').evaluate().isNotEmpty;
        if (shots != null && (only.isEmpty || only.contains(name))) {
          // Font loading finishes here; its warnings aren't screen errors.
          final before = {...errors};
          await tester.runAsync(() async {
            final boundary =
                shotKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File('$shots/$name.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(bytes!.buffer.asUint8List());
          });
          errors
            ..clear()
            ..addAll(before);
        }
        FlutterError.onError = original;
        final status = errors.isNotEmpty
            ? 'ERROR'
            : landed != location
            ? 'REDIRECTED'
            : notFound
            ? 'EMPTY'
            : 'OK';
        report.writeln(
          '$status\t$name\t$location'
          '${landed != location ? '\t-> $landed' : ''}'
          '${errors.isEmpty ? '' : '\t${errors.join(' | ')}'}',
        );
      }
      final out = Platform.environment['AUDIT_OUT'] ?? 'build/route_audit.tsv';
      File(out)
        ..createSync(recursive: true)
        ..writeAsStringSync(report.toString());
      // Let pending demo timers finish before the test ends.
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
