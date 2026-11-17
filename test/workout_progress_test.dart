// The workout screen (owner, 17 Nov 2026): a rest timer that keeps its place,
// what the player did last time, and a plain line for a new best.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/fitness/application/fitness_providers.dart';
import 'package:olympus_go/features/fitness/data/fitness_repository.dart';
import 'package:olympus_go/features/fitness/domain/fitness_models.dart';
import 'package:olympus_go/features/fitness/domain/workout_progress.dart';
import 'package:olympus_go/features/fitness/presentation/train_screen.dart';

const _squat = ProgramItem(
  exerciseId: 'squat',
  exercise: 'Back squat',
  mark: 'SQ',
  sets: 3,
  weighted: true,
  reps: 5,
  weightG: 70000,
  restSeconds: 60,
);

const _plank = ProgramItem(
  exerciseId: 'plank',
  exercise: 'Plank',
  mark: 'PL',
  sets: 2,
  timed: true,
  seconds: 30,
  restSeconds: 45,
);

ActiveWorkout _workout(List<ProgramItem> plan, {DateTime? startedAt}) =>
    ActiveWorkout(
      key: 'key-12345678',
      name: 'Leg day',
      startedAt: startedAt ?? DateTime.now(),
      plan: plan,
    );

LoggedSet _set(String id, {int? reps, int? seconds, int? weightG}) =>
    LoggedSet(exerciseId: id, reps: reps, seconds: seconds, weightG: weightG);

/// Thursday 12 November 2026.
final _thu = DateTime(2026, 11, 12, 19);

PersonalBest _past({int? reps, int? seconds, int? weightG, DateTime? at}) =>
    PersonalBest(
      exercise: '',
      at: at ?? _thu,
      reps: reps,
      seconds: seconds,
      weightG: weightG,
    );

/// A history whose last session is [sets], oldest first, as the server sends
/// it: newest first.
ExerciseHistory _history(List<PersonalBest> sets, {PersonalBest? best}) =>
    ExerciseHistory(
      times: sets.isEmpty ? 0 : 1,
      best: best ?? (sets.isEmpty ? null : sets.first),
      recent: sets.reversed.toList(),
    );

class _Repo extends DemoFitnessRepository {
  _Repo({this.histories = const {}, this.failing = false});

  final Map<String, ExerciseHistory> histories;
  bool failing;

  @override
  Future<ExerciseHistory> history(String exerciseId) async {
    if (failing) throw StateError('no signal');
    return histories[exerciseId] ?? const ExerciseHistory();
  }
}

void main() {
  group('the rest kept with the workout', () {
    final at = DateTime(2026, 11, 17, 10);

    test('a set starts a rest of the exercise’s length', () {
      final w = _workout([_squat]).logged(_set('squat', reps: 5), at);
      expect(w.restFor, 60);
      expect(w.restUntil, at.add(const Duration(seconds: 60)));
      expect(w.restLeft(at), 60);
      expect(w.restLeft(at.add(const Duration(seconds: 20))), 40);
      expect(w.restLeft(at.add(const Duration(milliseconds: 59500))), 1);
      expect(w.restLeft(at.add(const Duration(seconds: 60))), 0);
      expect(w.restLeft(at.add(const Duration(hours: 3))), 0);
    });

    test('the rest after an exercise’s last set is that exercise’s', () {
      var w = _workout([_plank, _squat]);
      w = w.logged(_set('plank', seconds: 30), at);
      w = w.logged(_set('plank', seconds: 30), at);
      expect(w.item, 1);
      expect(w.restFor, 45);
    });

    test('there is no rest after the very last set', () {
      var w = _workout([_plank]);
      w = w.logged(_set('plank', seconds: 30), at);
      expect(w.restLeft(at), 45);
      w = w.logged(_set('plank', seconds: 30), at);
      expect(w.complete, isTrue);
      expect(w.restUntil, isNull);
      expect(w.restLeft(at), 0);
    });

    test('an exercise with no rest starts none', () {
      final w = _workout([_squat.change(restSeconds: 0)])
          .logged(_set('squat', reps: 5), at);
      expect(w.restUntil, isNull);
      expect(w.restLeft(at), 0);
    });

    test('a clock moved backwards ends the rest, never freezes it', () {
      final w = _workout([_squat]).logged(_set('squat', reps: 5), at);
      // More left than the rest is long: the clock can't be trusted.
      expect(w.restLeft(at.subtract(const Duration(hours: 5))), 0);
      expect(w.restLeft(at.subtract(const Duration(seconds: 1))), 0);
      expect(w.restLeft(at), 60);
    });

    test('skipping ends it', () {
      final w = _workout([_squat]).logged(_set('squat', reps: 5), at).rested();
      expect(w.restUntil, isNull);
      expect(w.restLeft(at), 0);
      expect(w.done, hasLength(1));
    });

    test('adding time adds to what is left', () {
      final w = _workout([_squat]).logged(_set('squat', reps: 5), at);
      final later = at.add(const Duration(seconds: 50));
      final more = w.restAdded(restAddSeconds, later);
      expect(more.restLeft(later), 40);
      expect(more.restFor, 40);
      expect(more.restLeft(later.add(const Duration(seconds: 40))), 0);
    });

    test('adding time to a rest that is over does nothing', () {
      final w = _workout([_squat]).logged(_set('squat', reps: 5), at);
      final over = at.add(const Duration(seconds: 61));
      expect(identical(w.restAdded(30, over), w), isTrue);
      expect(_workout([_squat]).restAdded(30, at).restUntil, isNull);
    });

    test('a rest can’t be stretched past an hour', () {
      var w = _workout([_squat]).logged(_set('squat', reps: 5), at);
      for (var i = 0; i < 200; i++) {
        w = w.restAdded(restAddSeconds, at);
      }
      expect(w.restLeft(at), ActiveWorkout.longestRestSeconds);
    });

    test('a finished workout is not resting', () {
      final w = _workout([
        _squat,
      ], startedAt: at).logged(_set('squat', reps: 5), at).ended(at);
      expect(w.restLeft(at), 0);
    });

    test('it survives the phone’s storage, and never goes to the server', () {
      final w = _workout([
        _squat,
      ], startedAt: at).logged(_set('squat', reps: 5), at);
      final back = ActiveWorkout.fromJson(w.toJson());
      expect(back.restFor, 60);
      expect(back.restLeft(at.add(const Duration(seconds: 10))), 50);
      // Exactly what the server took before this change, and nothing more.
      expect(w.toSave().keys.toSet(), {
        'name',
        'program_id',
        'started_at',
        'ended_at',
        'sets',
      });
    });

    test('a change marks the exercise, and the mark is kept on the phone', () {
      var w = _workout([_squat, _plank], startedAt: at);
      expect(w.weightSet, isEmpty);
      w = w.adjusted(_squat.change(weightG: 65000));
      w = w.adjusted(_squat.change(noWeight: true));
      expect(w.weightSet, [0]);
      expect(ActiveWorkout.fromJson(w.toJson()).weightSet, [0]);
      expect(w.toSave().keys, isNot(contains('weight_set')));
    });

    test('a workout stored before this change opens with no rest', () {
      final json = _workout([_squat], startedAt: at).toJson()
        ..remove('rest_until')
        ..remove('rest_for')
        ..remove('weight_set');
      final back = ActiveWorkout.fromJson(json);
      expect(back.restUntil, isNull);
      expect(back.restLeft(at), 0);
      expect(back.weightSet, isEmpty);
    });
  });

  group('last time', () {
    test('is the newest workout’s sets, in the order done', () {
      final older = DateTime(2026, 11, 5, 19);
      final h = ExerciseHistory(
        times: 2,
        recent: [
          _past(reps: 4, weightG: 70000),
          _past(reps: 5, weightG: 70000),
          _past(reps: 6, weightG: 70000),
          _past(reps: 9, weightG: 60000, at: older),
        ],
      );
      expect(lastSession(h).map((s) => s.reps), [6, 5, 4]);
    });

    test('weighted sets share their weight', () {
      final h = _history([
        _past(reps: 5, weightG: 70000),
        _past(reps: 5, weightG: 70000),
        _past(reps: 4, weightG: 70000),
      ]);
      expect(lastTimeText(h), '70 kg × 5, 5, 4 · Thu 12 Nov');
    });

    test('a change of weight starts a new group', () {
      final h = _history([
        _past(reps: 5, weightG: 70000),
        _past(reps: 5, weightG: 70000),
        _past(reps: 4, weightG: 72500),
      ]);
      expect(lastTimeText(h), '70 kg × 5, 5; 72.5 kg × 4 · Thu 12 Nov');
    });

    test('unweighted sets are reps', () {
      final h = _history([_past(reps: 10), _past(reps: 10), _past(reps: 8)]);
      expect(lastTimeText(h), '10, 10, 8 reps · Thu 12 Nov');
    });

    test('timed sets are seconds', () {
      final h = _history([_past(seconds: 30), _past(seconds: 25)]);
      expect(lastTimeText(h), '30, 25 seconds · Thu 12 Nov');
    });

    test('nothing earlier is null', () {
      expect(lastTimeText(const ExerciseHistory()), isNull);
      expect(lastSession(const ExerciseHistory()), isEmpty);
    });

    test('the weight to start from is the last set’s', () {
      final h = _history([
        _past(reps: 5, weightG: 70000),
        _past(reps: 4, weightG: 72500),
      ]);
      expect(lastWeightG(h), 72500);
      expect(lastWeightG(_history([_past(reps: 10)])), isNull);
      expect(lastWeightG(_history([_past(reps: 10, weightG: 0)])), isNull);
      expect(lastWeightG(const ExerciseHistory()), isNull);
    });
  });

  group('a new best', () {
    final best = _history([_past(reps: 5, weightG: 70000)]);

    test('is more weight', () {
      final done = [_set('squat', reps: 3, weightG: 72500)];
      expect(isNewBest(done, 0, best), isTrue);
    });

    test('is more reps at the same weight', () {
      expect(
        isNewBest([_set('squat', reps: 6, weightG: 70000)], 0, best),
        isTrue,
      );
    });

    test('is not the same again, or less', () {
      expect(
        isNewBest([_set('squat', reps: 5, weightG: 70000)], 0, best),
        isFalse,
      );
      expect(
        isNewBest([_set('squat', reps: 8, weightG: 65000)], 0, best),
        isFalse,
      );
    });

    test('is never a first time', () {
      final done = [_set('squat', reps: 5, weightG: 70000)];
      expect(isNewBest(done, 0, const ExerciseHistory()), isFalse);
    });

    test('is not claimed when the history could not be read', () {
      expect(
        isNewBest([_set('squat', reps: 9, weightG: 99000)], 0, null),
        isFalse,
      );
    });

    test('must also beat the sets before it in this workout', () {
      final done = [
        _set('squat', reps: 5, weightG: 72500),
        _set('squat', reps: 5, weightG: 72500),
        _set('squat', reps: 5, weightG: 75000),
      ];
      expect(isNewBest(done, 0, best), isTrue);
      expect(isNewBest(done, 1, best), isFalse);
      expect(isNewBest(done, 2, best), isTrue);
    });

    test('0 kg is no weight: it never beats a set done without one', () {
      final noWeight = _history([_past(reps: 20)]);
      expect(
        isNewBest([_set('squat', reps: 1, weightG: 0)], 0, noWeight),
        isFalse,
      );
      expect(
        isNewBest([_set('squat', reps: 21, weightG: 0)], 0, noWeight),
        isTrue,
      );
      final zero = _history([_past(reps: 20, weightG: 0)]);
      expect(isNewBest([_set('squat', reps: 1)], 0, zero), isFalse);
      expect(
        isNewBest([_set('squat', reps: 1, weightG: 2500)], 0, noWeight),
        isTrue,
      );
    });

    test('for seconds and for reps alone', () {
      final plank = _history([_past(seconds: 30)]);
      expect(isNewBest([_set('plank', seconds: 31)], 0, plank), isTrue);
      expect(isNewBest([_set('plank', seconds: 30)], 0, plank), isFalse);
      final pushUp = _history([_past(reps: 10)]);
      expect(isNewBest([_set('push-up', reps: 11)], 0, pushUp), isTrue);
      expect(isNewBest([_set('push-up', reps: 9)], 0, pushUp), isFalse);
    });

    test('other exercises’ sets don’t count against it', () {
      final done = [
        _set('deadlift', reps: 5, weightG: 120000),
        _set('squat', reps: 5, weightG: 72500),
      ];
      expect(isNewBest(done, 1, best), isTrue);
    });

    test('an index outside the workout is not one', () {
      expect(isNewBest(const [], 0, best), isFalse);
      expect(
        isNewBest([_set('squat', reps: 9, weightG: 90000)], 4, best),
        isFalse,
      );
    });

    test('the summary lists one per exercise: its top set', () {
      final done = [
        _set('squat', reps: 5, weightG: 72500),
        _set('squat', reps: 5, weightG: 75000),
        _set('plank', seconds: 20),
        _set('push-up', reps: 12),
      ];
      final bests = newBests(done, {
        'squat': best,
        'plank': _history([_past(seconds: 30)]),
        'push-up': _history([_past(reps: 10)]),
      });
      expect(bests.map((b) => b.exerciseId), ['squat', 'push-up']);
      expect(bests.first.weightG, 75000);
    });
  });

  group('the session', () {
    Future<(ProviderContainer, _Repo)> open(
      ActiveWorkout workout, {
      Map<String, ExerciseHistory> histories = const {},
    }) async {
      final repo = _Repo(histories: histories);
      await repo.storeActive(workout);
      final c = ProviderContainer(
        overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
        retry: (_, _) => null,
      );
      addTearDown(c.dispose);
      await c.read(activeSessionProvider.future);
      return (c, repo);
    }

    test('last time’s weight fills an untouched exercise', () async {
      final (c, _) = await open(_workout([_squat.change(noWeight: true)]));
      await c.read(activeSessionProvider.notifier).prefillWeight(0, 70000);
      final w = c.read(activeSessionProvider).value!;
      expect(w.current!.weightG, 70000);
      expect(w.current!.reps, 5);
      expect(w.weightSet, [0]);
    });

    test('it never overwrites what the player typed in the meantime', () async {
      final (c, _) = await open(_workout([_squat.change(noWeight: true)]));
      final session = c.read(activeSessionProvider.notifier);
      // The player's change and the weight from last time, both on their way.
      final typed = session.adjust(0, _squat.change(weightG: 60000, reps: 8));
      final late = session.prefillWeight(0, 70000);
      await Future.wait([typed, late]);
      final item = c.read(activeSessionProvider).value!.current!;
      expect(item.weightG, 60000);
      expect(item.reps, 8);
    });

    test('it keeps the reps the player changed', () async {
      final (c, _) = await open(_workout([_squat.change(noWeight: true)]));
      final session = c.read(activeSessionProvider.notifier);
      await session.adjust(0, _squat.change(noWeight: true, reps: 8));
      await session.prefillWeight(0, 70000);
      final item = c.read(activeSessionProvider).value!.current!;
      // A change by the player marks the exercise: their empty weight stays.
      expect(item.weightG, isNull);
      expect(item.reps, 8);
    });

    test('it does nothing once a set is done', () async {
      final (c, _) = await open(_workout([_squat.change(noWeight: true)]));
      final session = c.read(activeSessionProvider.notifier);
      final logged = session.logCurrent();
      final late = session.prefillWeight(0, 70000);
      await Future.wait([logged, late]);
      final w = c.read(activeSessionProvider).value!;
      expect(w.done.single.weightG, isNull);
      expect(w.current!.weightG, isNull);
    });

    test('it does nothing for another exercise, a planned weight, an '
        'unweighted exercise or no weight', () async {
      final (c, _) = await open(_workout([_squat, _plank]));
      final session = c.read(activeSessionProvider.notifier);
      await session.prefillWeight(1, 70000);
      await session.prefillWeight(0, 80000);
      await session.prefillWeight(0, 0);
      final w = c.read(activeSessionProvider).value!;
      expect(w.plan[0].weightG, 70000);
      expect(w.plan[1].weightG, isNull);
      expect(w.weightSet, isEmpty);
    });

    test('a set is logged as the workout stands when its turn comes', () async {
      final (c, _) = await open(_workout([_squat.change(noWeight: true)]));
      final session = c.read(activeSessionProvider.notifier);
      final filled = session.prefillWeight(0, 70000);
      final logged = session.logCurrent();
      await Future.wait([filled, logged]);
      expect(c.read(activeSessionProvider).value!.done.single.weightG, 70000);
    });

    test('finishing reads the history afresh', () async {
      final repo = DemoFitnessRepository();
      await repo.storeActive(
        ActiveWorkout(
          key: 'key-finish-1',
          name: 'Legs',
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          plan: const [_squat],
        ),
      );
      final c = ProviderContainer(
        overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
        retry: (_, _) => null,
      );
      addTearDown(c.dispose);
      final sub = c.listen(exerciseHistoryProvider('squat'), (_, _) {});
      addTearDown(sub.close);
      expect((await c.read(exerciseHistoryProvider('squat').future)).times, 0);
      final session = c.read(activeSessionProvider.notifier);
      await c.read(activeSessionProvider.future);
      await session.logCurrent();
      await session.finish();
      final after = await c.read(exerciseHistoryProvider('squat').future);
      expect(after.times, 1);
      expect(lastTimeText(after), startsWith('70 kg × 5 · '));
    });
  });

  group('the workout screen', () {
    Future<void> pump(WidgetTester tester, _Repo repo) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(path: '/host', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: Routes.fitnessTrain,
            builder: (_, _) => const TrainScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
          retry: (_, _) => null,
          child: MaterialApp.router(
            theme: OgTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      router.push(Routes.fitnessTrain);
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    final squatBefore = _history([
      _past(reps: 5, weightG: 70000),
      _past(reps: 5, weightG: 70000),
      _past(reps: 4, weightG: 70000),
    ], best: _past(reps: 5, weightG: 70000));

    testWidgets('shows what the player did last time', (tester) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      expect(find.text('Back squat'), findsOne);
      expect(find.text('Last time: 70 kg × 5, 5, 4 · Thu 12 Nov'), findsOne);
    });

    testWidgets('says so the first time', (tester) async {
      final repo = _Repo();
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      expect(find.text('First time doing this.'), findsOne);
    });

    testWidgets('carries on without it when the history can’t be read', (
      tester,
    ) async {
      final repo = _Repo(failing: true);
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      expect(find.textContaining('Last time'), findsNothing);
      expect(find.text('First time doing this.'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      await tap(tester, 'Set done');
      expect((await repo.loadActive())!.done, hasLength(1));
      expect(find.textContaining('New best'), findsNothing);
    });

    testWidgets('starts at last time’s weight when the program plans none', (
      tester,
    ) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat.change(noWeight: true)]));
      await pump(tester, repo);
      expect(find.text('70 kg'), findsOne);
      await tap(tester, 'Set done');
      expect((await repo.loadActive())!.done.single.weightG, 70000);
    });

    testWidgets('never replaces a weight the program plans', (tester) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat.change(weightG: 60000)]));
      await pump(tester, repo);
      expect(find.text('60 kg'), findsOne);
      expect(find.text('70 kg'), findsNothing);
    });

    testWidgets('a planned weight the player clears stays cleared', (
      tester,
    ) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat.change(weightG: 60000)]));
      await pump(tester, repo);
      await tap(tester, 'Change weight or reps');
      await tester.enterText(find.byType(EditableText).first, '');
      await tap(tester, 'Done');
      expect(find.text('—'), findsOne);
      expect(find.text('70 kg'), findsNothing);
      await tap(tester, 'Set done');
      expect((await repo.loadActive())!.done.single.weightG, isNull);
    });

    testWidgets('a weight from last time that the player clears stays cleared, '
        'even after leaving the screen', (tester) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat.change(noWeight: true)]));
      await pump(tester, repo);
      expect(find.text('70 kg'), findsOne);
      await tap(tester, 'Change weight or reps');
      await tester.enterText(find.byType(EditableText).first, '');
      await tap(tester, 'Done');
      expect(find.text('—'), findsOne);
      // Leave and come back: the screen starts afresh, the workout doesn't.
      await pump(tester, repo);
      expect(find.text('—'), findsOne);
      expect(find.text('70 kg'), findsNothing);
    });

    testWidgets('with the app’s own retries on, a history that can’t be read '
        'leaves the line out', (tester) async {
      final repo = _Repo(failing: true);
      await repo.storeActive(_workout([_squat]));
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(theme: OgTheme.light(), home: const TrainScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Back squat'), findsOne);
      expect(find.bySemanticsLabel('Loading last time'), findsNothing);
      expect(find.textContaining('Last time'), findsNothing);
      expect(find.text('Set done'), findsOne);
      // Take the screen down, so no retry is left waiting.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 2));
    });

    testWidgets('0 kg typed in is kept as no weight', (tester) async {
      final repo = _Repo();
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      await tap(tester, 'Change weight or reps');
      await tester.enterText(find.byType(EditableText).first, '0');
      await tap(tester, 'Done');
      expect(find.text('—'), findsOne);
      await tap(tester, 'Set done');
      expect((await repo.loadActive())!.done.single.weightG, isNull);
    });

    testWidgets('a phone whose clock moved back is not left resting', (
      tester,
    ) async {
      final repo = _Repo();
      // The rest seems to end far later than a 60-second rest ever could.
      final ahead = DateTime.now().add(const Duration(hours: 3));
      await repo.storeActive(
        _workout([_squat]).logged(_set('squat', reps: 5), ahead),
      );
      await pump(tester, repo);
      expect(find.text('REST'), findsNothing);
      expect(find.text('Set done'), findsOne);
    });

    testWidgets('stays empty with no weight last time either', (tester) async {
      final repo = _Repo();
      await repo.storeActive(_workout([_squat.change(noWeight: true)]));
      await pump(tester, repo);
      expect(find.text('—'), findsOne);
    });

    testWidgets('a set that beats the best says so, plainly', (tester) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat.change(weightG: 72500)]));
      await pump(tester, repo);
      expect(find.textContaining('New best'), findsNothing);
      await tap(tester, 'Set done');
      expect(find.text('New best: Back squat, 72.5 kg × 5'), findsOne);
      expect(find.text('REST'), findsOne);
    });

    testWidgets('matching the best is not a new best', (tester) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      await tap(tester, 'Set done');
      expect(find.textContaining('New best'), findsNothing);
    });

    testWidgets('a first time is not a new best', (tester) async {
      final repo = _Repo();
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      await tap(tester, 'Set done');
      expect(find.textContaining('New best'), findsNothing);
    });

    testWidgets('the end lists the new bests', (tester) async {
      final repo = _Repo(
        histories: {
          'squat': squatBefore,
          'plank': _history([_past(seconds: 30)]),
        },
      );
      await repo.storeActive(
        _workout([
          _squat.change(sets: 1, weightG: 72500),
          _plank.change(sets: 1, seconds: 40),
        ]),
      );
      await pump(tester, repo);
      await tap(tester, 'Set done');
      await tap(tester, 'Skip rest');
      await tap(tester, 'Set done');
      expect(find.text('All sets done'), findsOne);
      expect(find.text('2 new bests'), findsOne);
      expect(find.text('Back squat: 72.5 kg × 5'), findsOne);
      expect(find.text('Plank: 40 seconds'), findsOne);
    });

    testWidgets('the end says nothing of bests when there are none', (
      tester,
    ) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(_workout([_squat.change(sets: 1)]));
      await pump(tester, repo);
      await tap(tester, 'Set done');
      expect(find.text('All sets done'), findsOne);
      expect(find.textContaining('new best'), findsNothing);
    });

    testWidgets('coming back mid-rest shows the time really left', (
      tester,
    ) async {
      final repo = _Repo();
      final started = DateTime.now().subtract(const Duration(seconds: 20));
      await repo.storeActive(
        _workout([_squat]).logged(_set('squat', reps: 5), started),
      );
      await pump(tester, repo);
      expect(find.text('REST'), findsOne);
      // 60 seconds of rest, 20 already gone.
      expect(find.textContaining(RegExp(r'^0:(39|40)$')), findsOne);
      expect(find.text('Set done'), findsNothing);
      expect(find.text('Skip rest'), findsOne);
    });

    testWidgets('coming back after the rest goes straight to the next set', (
      tester,
    ) async {
      final repo = _Repo();
      final started = DateTime.now().subtract(const Duration(minutes: 5));
      await repo.storeActive(
        _workout([_squat]).logged(_set('squat', reps: 5), started),
      );
      await pump(tester, repo);
      expect(find.text('REST'), findsNothing);
      expect(find.text('Set done'), findsOne);
      expect(find.textContaining('SET 2 OF 3'), findsOne);
    });

    testWidgets('skipping the rest ends it on the phone too', (tester) async {
      final repo = _Repo();
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      await tap(tester, 'Set done');
      expect((await repo.loadActive())!.restUntil, isNotNull);
      await tap(tester, 'Skip rest');
      expect(find.text('REST'), findsNothing);
      expect(find.text('Set done'), findsOne);
      expect((await repo.loadActive())!.restUntil, isNull);
    });

    testWidgets('Add 30 seconds makes the rest longer', (tester) async {
      final repo = _Repo();
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      expect(find.text('Add 30 seconds'), findsNothing);
      await tap(tester, 'Set done');
      await tap(tester, 'Add 30 seconds');
      final w = (await repo.loadActive())!;
      expect(w.restFor, inInclusiveRange(89, 90));
      expect(find.textContaining(RegExp(r'^1:(29|30)$')), findsOne);
    });

    testWidgets('has no points, badges, streaks or ranks', (tester) async {
      final repo = _Repo(histories: {'squat': squatBefore});
      await repo.storeActive(
        _workout([_squat.change(sets: 1, weightG: 80000)]),
      );
      await pump(tester, repo);
      await tap(tester, 'Set done');
      final all = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' | ');
      expect(
        RegExp(
          r'point|badge|streak|rank|reward|calor|unlocked|congrat',
          caseSensitive: false,
        ).hasMatch(all),
        isFalse,
        reason: all,
      );
    });
  });
}
