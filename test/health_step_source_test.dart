// The real step reader, with a fake health store: what it says about access,
// and how it turns the store's answers into days and hours.

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/fitness/data/health_step_source.dart';
import 'package:olympus_go/features/fitness/domain/steps.dart';

class _Gateway implements HealthGateway {
  _Gateway({
    this.isAvailable = true,
    this.can,
    this.answer = true,
    this.perCall,
  });

  bool isAvailable;

  /// What the store says about reading: true, false, or null (iPhone).
  bool? can;
  bool answer;
  int? Function(DateTime start, DateTime end)? perCall;

  final asks = <int>[];
  final calls = <(DateTime, DateTime)>[];
  var settings = 0;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<bool?> canReadSteps() async => can;

  @override
  Future<bool> askToReadSteps() async {
    asks.add(1);
    if (answer) can = can == null ? null : true;
    return answer;
  }

  @override
  Future<int?> steps(DateTime start, DateTime end) async {
    calls.add((start, end));
    return perCall?.call(start, end);
  }

  @override
  Future<void> openSettings() async => settings++;
}

DateTime _midnight(int daysAgo) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day - daysAgo);
}

void main() {
  group('access', () {
    test('is unavailable with no health store', () async {
      final src = HealthStepSource(
        gateway: _Gateway(isAvailable: false),
        asked: MemoryStepsAskedStore(),
      );
      expect(await src.access(), StepsAccess.unavailable);
      expect(await src.request(), StepsAccess.unavailable);
    });

    test('Android: not asked, then allowed once granted', () async {
      final g = _Gateway(can: false);
      final src = HealthStepSource(gateway: g, asked: MemoryStepsAskedStore());
      expect(await src.access(), StepsAccess.notAsked);
      expect(await src.request(), StepsAccess.allowed);
      g.can = true;
      expect(await src.access(), StepsAccess.allowed);
      expect(g.asks.length, 1);
    });

    test('Android: refused is remembered as denied', () async {
      final g = _Gateway(can: false, answer: false);
      final asked = MemoryStepsAskedStore();
      final src = HealthStepSource(gateway: g, asked: asked);
      expect(await src.request(), StepsAccess.denied);
      expect(asked.asked, isTrue);
      // A fresh start: refused before and still not granted.
      expect(await src.access(), StepsAccess.denied);
    });

    test(
      'iPhone: cannot tell, so not asked until asked, then allowed',
      () async {
        final g = _Gateway();
        final asked = MemoryStepsAskedStore();
        final src = HealthStepSource(gateway: g, asked: asked);
        expect(await src.access(), StepsAccess.notAsked);
        expect(await src.request(), StepsAccess.allowed);
        expect(await src.access(), StepsAccess.allowed);
      },
    );

    test('Android: granted from Settings turns it back on', () async {
      final g = _Gateway(can: false, answer: false);
      final src = HealthStepSource(gateway: g, asked: MemoryStepsAskedStore());
      await src.request();
      expect(await src.access(), StepsAccess.denied);
      g.can = true;
      expect(await src.access(), StepsAccess.allowed);
    });

    test('opening Settings goes to the store', () async {
      final g = _Gateway();
      await HealthStepSource(
        gateway: g,
        asked: MemoryStepsAskedStore(),
      ).openSettings();
      expect(g.settings, 1);
    });
  });

  group('days', () {
    test(
      'one entry per day, oldest first, each asked for its own day',
      () async {
        final g = _Gateway(can: true, perCall: (s, e) => s.day * 100);
        final src = HealthStepSource(
          gateway: g,
          asked: MemoryStepsAskedStore(),
        );
        final days = await src.days(_midnight(2), _midnight(0));
        expect(days.map((d) => d.day), [
          _midnight(2),
          _midnight(1),
          _midnight(0),
        ]);
        expect(days.map((d) => d.steps), [
          for (final d in [2, 1, 0]) _midnight(d).day * 100,
        ]);
        // A finished day runs midnight to midnight.
        expect(g.calls.first.$1, _midnight(2));
        expect(g.calls.first.$2, _midnight(1));
      },
    );

    test('today ends now, not at midnight', () async {
      final g = _Gateway(can: true, perCall: (_, _) => 10);
      final src = HealthStepSource(gateway: g, asked: MemoryStepsAskedStore());
      final before = DateTime.now();
      await src.days(_midnight(0), _midnight(0));
      final end = g.calls.single.$2;
      expect(end.isBefore(before), isFalse);
      expect(end.isAfter(DateTime.now()), isFalse);
    });

    test('a missing or negative count is 0', () async {
      var n = 0;
      final g = _Gateway(
        can: true,
        perCall: (_, _) => switch (n++) {
          0 => null,
          1 => -5,
          _ => 7,
        },
      );
      final src = HealthStepSource(gateway: g, asked: MemoryStepsAskedStore());
      final days = await src.days(_midnight(2), _midnight(0));
      expect(days.map((d) => d.steps).toList()..sort(), [0, 0, 7]);
    });

    test('a failing store throws, so the screen shows its error', () async {
      final g = _Gateway(can: true, perCall: (_, _) => throw StateError('x'));
      final src = HealthStepSource(gateway: g, asked: MemoryStepsAskedStore());
      expect(() => src.days(_midnight(1), _midnight(0)), throwsStateError);
    });
  });

  group('hours', () {
    test('gives 24 numbers, none for hours still to come', () async {
      final g = _Gateway(can: true, perCall: (_, _) => 100);
      final src = HealthStepSource(gateway: g, asked: MemoryStepsAskedStore());
      final past = await src.hours(_midnight(1));
      expect(past.length, 24);
      expect(past.every((h) => h == 100), isTrue);

      final today = await src.hours(_midnight(0));
      expect(today.length, 24);
      final now = DateTime.now();
      for (var h = 0; h < 24; h++) {
        if (DateTime(now.year, now.month, now.day, h).isAfter(now)) {
          expect(today[h], 0, reason: 'hour $h has not started');
        }
      }
    });
  });
}
