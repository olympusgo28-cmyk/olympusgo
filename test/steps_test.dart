// Step tracking (owner, 17 Nov 2026): the summary maths, the Steps card on
// Fitness, the Steps screen with each state, and the daily goal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/fitness/application/steps_providers.dart';
import 'package:olympus_go/features/fitness/data/step_source.dart';
import 'package:olympus_go/features/fitness/domain/steps.dart';
import 'package:olympus_go/features/fitness/presentation/steps_screen.dart';

DateTime _midnight(int daysAgo) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day - daysAgo);
}

/// Steps for the last days, oldest first, the last one today.
Map<DateTime, int> _steps(List<int> lastDays) => {
  for (var i = 0; i < lastDays.length; i++)
    _midnight(lastDays.length - 1 - i): lastDays[i],
};

StepsSummary _summary(List<int> lastDays, {int goal = 10000}) => StepsSummary(
  days: [
    for (var i = 0; i < lastDays.length; i++)
      StepsDay(_midnight(lastDays.length - 1 - i), lastDays[i]),
  ],
  goal: goal,
  asOf: DateTime.now(),
);

void main() {
  group('the daily goal', () {
    test('stays between 1,000 and 50,000 in steps of 500', () {
      expect(clampStepGoal(0), 1000);
      expect(clampStepGoal(999), 1000);
      expect(clampStepGoal(1000), 1000);
      expect(clampStepGoal(10200), 10000);
      expect(clampStepGoal(10300), 10500);
      expect(clampStepGoal(50000), 50000);
      expect(clampStepGoal(90000), 50000);
    });

    test('is 10,000 until the player picks one', () {
      expect(defaultStepGoal, 10000);
    });
  });

  group('summary maths', () {
    test('today, percent and the ring', () {
      final s = _summary([1, 2, 6420]);
      expect(s.today, 6420);
      expect(s.percent, 64);
      expect(s.progress, closeTo(0.642, 0.0001));
      expect(s.reached, isFalse);
      expect(s.none, isFalse);
    });

    test('over the goal the ring is full and the goal is reached', () {
      final s = _summary([5000, 12104]);
      expect(s.progress, 1.0);
      expect(s.percent, 100);
      expect(s.reached, isTrue);
    });

    test('exactly on the goal counts as reached', () {
      expect(_summary([10000]).reached, isTrue);
      expect(_summary([9999]).reached, isFalse);
      expect(_summary([9999]).percent, 99);
    });

    test('no steps today is none, not a number that looks like data', () {
      final s = _summary([8000, 0]);
      expect(s.none, isTrue);
      expect(s.percent, 0);
      expect(_summary(const []).none, isTrue);
    });

    test('week is the last 7 days, month is all 30, day is today', () {
      final s = _summary([for (var i = 1; i <= 30; i++) i * 100]);
      expect(s.inRange(StepsRange.day).map((d) => d.steps), [3000]);
      expect(s.inRange(StepsRange.week).length, 7);
      expect(s.inRange(StepsRange.week).first.steps, 2400);
      expect(s.inRange(StepsRange.week).last.steps, 3000);
      expect(s.inRange(StepsRange.month).length, 30);
    });

    test('a short history is not padded', () {
      expect(_summary([1, 2, 3]).inRange(StepsRange.week).length, 3);
    });

    test('the average leaves out days with no steps', () {
      final s = _summary([0, 4000, 0, 6000, 8000]);
      // 18,000 over the three days that have steps.
      expect(s.average(StepsRange.week), 6000);
    });

    test('the average of nothing is 0', () {
      expect(_summary([0, 0, 0]).average(StepsRange.week), 0);
    });

    test('the best day is the one with most steps, or null', () {
      final s = _summary([3000, 9000, 4000]);
      expect(s.best(StepsRange.week)!.steps, 9000);
      expect(s.best(StepsRange.week)!.day, _midnight(1));
      expect(_summary([0, 0]).best(StepsRange.week), isNull);
    });

    test('the best day follows the range', () {
      // 20,000 is 10 days ago: in the month, not in the week.
      final s = _summary(
        [
          20000,
          ...List.filled(9, 1000),
          ...List.filled(10, 2000),
        ].followedBy(List.filled(10, 3000)).toList(),
      );
      expect(s.best(StepsRange.month)!.steps, 20000);
      expect(s.best(StepsRange.week)!.steps, 3000);
    });
  });

  group('the fake source', () {
    test(
      'answers one entry per day, oldest first, and 0 for a quiet day',
      () async {
        final src = FakeStepSource(steps: {_midnight(1): 500});
        final days = await src.days(_midnight(2), _midnight(0));
        expect(days.map((d) => d.steps), [0, 500, 0]);
        expect(days.first.day, _midnight(2));
      },
    );

    test('asking changes what it answers', () async {
      final src = FakeStepSource(access: StepsAccess.notAsked);
      expect(await src.access(), StepsAccess.notAsked);
      expect(await src.request(), StepsAccess.allowed);
      expect(await src.access(), StepsAccess.allowed);
      expect(src.requests, 1);
    });

    test('24 hours that add up to the day', () async {
      final src = FakeStepSource(steps: {_midnight(1): 8000});
      final hours = await src.hours(_midnight(1));
      expect(hours.length, 24);
      // Rounding can move the total by a few steps, no more.
      expect((hours.reduce((a, b) => a + b) - 8000).abs(), lessThan(24));
    });
  });

  group('the goal is kept on the phone', () {
    test('reads what was saved, and keeps it in range', () async {
      final store = MemoryStepGoalStore(12000);
      expect(await store.read(), 12000);
      await store.write(7500);
      expect(await store.read(), 7500);
    });
  });

  group('screens', () {
    Future<void> pump(
      WidgetTester tester, {
      required StepSource source,
      StepGoalStore? store,
      String at = Routes.fitnessSteps,
      Widget? host,
    }) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: host == null ? at : '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [host ?? const SizedBox()],
              ),
            ),
          ),
          GoRoute(
            path: Routes.fitnessSteps,
            builder: (_, _) => const StepsScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stepSourceProvider.overrideWithValue(source),
            stepGoalStoreProvider.overrideWithValue(
              store ?? MemoryStepGoalStore(),
            ),
          ],
          retry: (_, _) => null,
          child: MaterialApp.router(
            theme: OgTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, String label) async {
      final f = find.text(label);
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await tester.pumpAndSettle();
    }

    FakeStepSource week([int today = 6420]) => FakeStepSource(
      steps: _steps([9000, 12104, 5400, 7300, 8200, 10100, today]),
    );

    String allText(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join(' | ');

    group('the card on Fitness', () {
      Future<void> card(
        WidgetTester tester,
        StepSource source, {
        StepGoalStore? store,
      }) => pump(tester, source: source, store: store, host: const StepsCard());

      testWidgets('shows today, the goal and the ring percent', (tester) async {
        await card(tester, week());
        expect(find.text('Steps today'), findsOne);
        expect(find.text('6,420'), findsOne);
        expect(find.text('Goal 10,000'), findsOne);
        expect(find.text('64%'), findsOne);
      });

      testWidgets('over the goal it says so, with no badge', (tester) async {
        await card(tester, week(12104));
        expect(find.text('Goal reached'), findsOne);
        expect(find.text('100%'), findsOne);
        expect(find.text('Goal 10,000'), findsNothing);
      });

      testWidgets('uses the player’s own goal', (tester) async {
        await card(tester, week(), store: MemoryStepGoalStore(8000));
        expect(find.text('Goal 8,000'), findsOne);
        expect(find.text('80%'), findsOne);
      });

      testWidgets('no steps yet today shows 0 and an empty ring', (
        tester,
      ) async {
        await card(tester, week(0));
        expect(find.text('0'), findsOne);
        expect(find.text('0%'), findsOne);
      });

      testWidgets('asks first when not asked, and shows steps once allowed', (
        tester,
      ) async {
        final src = FakeStepSource(
          access: StepsAccess.notAsked,
          steps: _steps([1000, 2000, 3000]),
        );
        await card(tester, src);
        expect(find.text('Count your steps'), findsOne);
        expect(find.text('Steps today'), findsNothing);
        await tap(tester, 'Allow step counting');
        expect(src.requests, 1);
        expect(find.text('Steps today'), findsOne);
        expect(find.text('3,000'), findsOne);
      });

      testWidgets('says steps are off when refused, and opens Settings', (
        tester,
      ) async {
        final src = FakeStepSource(
          access: StepsAccess.notAsked,
          grants: StepsAccess.denied,
        );
        await card(tester, src);
        await tap(tester, 'Allow step counting');
        expect(find.text('Steps are off'), findsOne);
        expect(find.text('Steps today'), findsNothing);
        await tap(tester, 'Open Settings');
        expect(src.settingsOpened, 1);
      });

      testWidgets('is not shown when the phone has no health store', (
        tester,
      ) async {
        await card(tester, FakeStepSource(access: StepsAccess.unavailable));
        expect(find.text('Count your steps'), findsNothing);
        expect(find.text('Steps today'), findsNothing);
      });

      testWidgets('shows a plain message and Try again when it cannot read', (
        tester,
      ) async {
        final src = week()..failing = true;
        await card(tester, src);
        expect(find.text('Can’t read your steps right now'), findsOne);
        expect(find.textContaining('StateError'), findsNothing);
        src.failing = false;
        await tap(tester, 'Try again');
        expect(find.text('6,420'), findsOne);
      });

      testWidgets('shows a placeholder while it loads', (tester) async {
        final src = FakeStepSource(
          latency: const Duration(seconds: 1),
          steps: _steps([100]),
        );
        await tester.binding.setSurfaceSize(const Size(390, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              stepSourceProvider.overrideWithValue(src),
              stepGoalStoreProvider.overrideWithValue(MemoryStepGoalStore()),
            ],
            retry: (_, _) => null,
            child: MaterialApp(
              theme: OgTheme.light(),
              home: const Scaffold(body: StepsCard()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.bySemanticsLabel('Loading your steps'), findsOne);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Steps today'), findsOne);
      });

      testWidgets('opens the Steps screen', (tester) async {
        await card(tester, week());
        await tester.tap(find.text('Steps today'));
        await tester.pumpAndSettle();
        expect(find.byType(StepsScreen), findsOne);
      });

      testWidgets('is read aloud with the count and the goal', (tester) async {
        await card(tester, week());
        expect(
          find.bySemanticsLabel(
            RegExp(r'^Steps\. 6,420 today, goal 10,000\. Open Steps'),
          ),
          findsOne,
        );
      });
    });

    group('the Steps screen', () {
      testWidgets('shows the ring, the count, the week and the numbers', (
        tester,
      ) async {
        await pump(tester, source: week());
        expect(find.text('Steps'), findsOne);
        expect(find.text('6,420'), findsOne);
        expect(find.text('of 10,000 steps'), findsOne);
        expect(find.textContaining('Updated '), findsOne);
        expect(find.text('Week'), findsOne);
        expect(find.text('daily average'), findsOne);
        // 9000, 12104, 5400, 7300, 8200, 10100, 6420 → 58,524 / 7 = 8,361.
        expect(find.text('8,361'), findsOne);
        expect(find.text('12,104'), findsOne);
        expect(find.textContaining('best day, '), findsOne);
        expect(find.text('Daily goal'), findsOne);
        expect(find.text('10,000 steps'), findsOne);
        expect(
          find.text(
            'Steps come from this phone and stay on it. Nobody else can see '
            'them.',
          ),
          findsOne,
        );
      });

      testWidgets('Day shows hours, with no goal line', (tester) async {
        await pump(tester, source: week());
        await tap(tester, 'Day');
        expect(find.bySemanticsLabel(RegExp('^Steps by hour today')), findsOne);
        expect(find.text('6am'), findsOne);
        expect(find.text('Goal'), findsNothing);
        expect(find.text('steps today'), findsOne);
      });

      testWidgets('Week and Month show the goal line', (tester) async {
        await pump(tester, source: week());
        expect(
          find.bySemanticsLabel(RegExp('^Steps for the last 7 days')),
          findsOne,
        );
        expect(find.text('Goal'), findsOne);
        await tap(tester, 'Month');
        expect(
          find.bySemanticsLabel(RegExp('^Steps for the last 30 days')),
          findsOne,
        );
        expect(find.text('Goal'), findsOne);
      });

      testWidgets('over the goal says Goal reached', (tester) async {
        await pump(tester, source: week(11000));
        expect(find.text('Goal reached'), findsOne);
        expect(find.text('of 10,000 steps'), findsNothing);
      });

      testWidgets('no steps yet today says so', (tester) async {
        await pump(tester, source: week(0));
        expect(find.text('No steps yet today'), findsOne);
        expect(find.textContaining('Updated '), findsNothing);
      });

      testWidgets('with nothing read for 30 days it says where to look', (
        tester,
      ) async {
        await pump(tester, source: FakeStepSource(steps: const {}));
        expect(find.textContaining('No steps showing?'), findsOne);
      });

      testWidgets('with steps it does not nag', (tester) async {
        await pump(tester, source: week());
        expect(find.textContaining('No steps showing?'), findsNothing);
      });

      testWidgets('with no steps at all the best day is a dash', (
        tester,
      ) async {
        await pump(tester, source: FakeStepSource(steps: const {}));
        expect(find.text('—'), findsOne);
        expect(find.text('best day'), findsOne);
      });

      testWidgets('asks for permission when not asked', (tester) async {
        final src = FakeStepSource(
          access: StepsAccess.notAsked,
          steps: _steps([1, 2, 4000]),
        );
        await pump(tester, source: src);
        expect(find.text('Count your steps'), findsOne);
        await tap(tester, 'Allow step counting');
        expect(src.requests, 1);
        expect(find.text('4,000'), findsAtLeast(1));
      });

      testWidgets('tells the player how to turn steps back on', (tester) async {
        final src = FakeStepSource(access: StepsAccess.denied);
        await pump(tester, source: src);
        expect(find.text('Steps are off'), findsOne);
        await tap(tester, 'Open Settings');
        expect(src.settingsOpened, 1);
      });

      testWidgets('says plainly when this phone has no health store', (
        tester,
      ) async {
        await pump(
          tester,
          source: FakeStepSource(access: StepsAccess.unavailable),
        );
        expect(find.text('Steps aren’t available on this phone'), findsOne);
        expect(find.text('Allow step counting'), findsNothing);
      });

      testWidgets('shows Try again, never a raw error', (tester) async {
        final src = week()..failing = true;
        await pump(tester, source: src);
        expect(find.text('Can’t read your steps right now'), findsOne);
        expect(find.textContaining('StateError'), findsNothing);
        src.failing = false;
        await tap(tester, 'Try again');
        expect(find.text('6,420'), findsOne);
      });

      testWidgets('has no calories, points, badges, streaks or ranks', (
        tester,
      ) async {
        await pump(tester, source: week(12104));
        final all = allText(tester);
        expect(
          RegExp(
            r'calor|burn|point|badge|streak|rank|leaderboard|reward|rating',
            caseSensitive: false,
          ).hasMatch(all),
          isFalse,
          reason: all,
        );
        await tap(tester, 'Month');
        expect(
          RegExp(
            r'calor|burn|point|badge|streak|rank',
            caseSensitive: false,
          ).hasMatch(allText(tester)),
          isFalse,
        );
      });
    });

    group('the goal sheet', () {
      testWidgets('opens on the current goal', (tester) async {
        await pump(tester, source: week(), store: MemoryStepGoalStore(8000));
        await tap(tester, 'Daily goal');
        expect(find.text('steps a day'), findsOne);
        expect(find.text('8,000'), findsAtLeast(1));
        expect(find.text('Save goal'), findsOne);
      });

      testWidgets('moves by 500 and saves on the phone', (tester) async {
        final store = MemoryStepGoalStore();
        await pump(tester, source: week(), store: store);
        await tap(tester, 'Daily goal');
        await tester.tap(find.bySemanticsLabel('Raise goal'));
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Raise goal'));
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Lower goal'));
        await tester.pump();
        await tap(tester, 'Save goal');
        expect(store.goal, 10500);
        expect(find.text('10,500 steps'), findsOne);
        expect(find.text('of 10,500 steps'), findsOne);
      });

      testWidgets('cannot go under 1,000', (tester) async {
        final store = MemoryStepGoalStore(1000);
        await pump(tester, source: week(), store: store);
        await tap(tester, 'Daily goal');
        await tester.tap(find.bySemanticsLabel('Lower goal'));
        await tester.pump();
        await tap(tester, 'Save goal');
        expect(store.goal, 1000);
      });

      testWidgets('cannot go over 50,000', (tester) async {
        final store = MemoryStepGoalStore(50000);
        await pump(tester, source: week(), store: store);
        await tap(tester, 'Daily goal');
        await tester.tap(find.bySemanticsLabel('Raise goal'));
        await tester.pump();
        await tap(tester, 'Save goal');
        expect(store.goal, 50000);
      });

      testWidgets('a saved goal outside the range is brought back in', (
        tester,
      ) async {
        await pump(tester, source: week(), store: MemoryStepGoalStore(900000));
        expect(find.text('of 50,000 steps'), findsOne);
      });
    });
  });
}
