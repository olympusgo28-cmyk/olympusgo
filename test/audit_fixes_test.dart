// Fixes from the 5 November audit: A02 and A04. A03 (deleting an account)
// is covered by account_deletion_test.dart now that deletion is real.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/router/app_router.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/main.dart';

void main() {
  group('A02: the phone or email code screen', () {
    test('opens only with the address the change started with', () {
      expect(verifyChangeRedirect('+6591234567'), isNull);
      expect(verifyChangeRedirect(null), Routes.personalInfo);
      expect(verifyChangeRedirect(42), Routes.personalInfo);
    });
  });

  group('A04: fonts at start-up', () {
    test('a failed load still lets the app start', () async {
      await waitForFonts(Future<Object?>.error(Exception('offline')));
    });

    test('a slow load stops waiting at the limit', () async {
      final never = Completer<Object?>();
      final watch = Stopwatch()..start();
      await waitForFonts(never.future, limit: const Duration(milliseconds: 50));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('a quick load is waited for', () async {
      var done = false;
      await waitForFonts(
        Future<Object?>.delayed(const Duration(milliseconds: 20), () {
          done = true;
          return null;
        }),
      );
      expect(done, isTrue);
    });
  });
}
