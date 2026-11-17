import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/fitness/application/fitness_providers.dart';
import 'package:olympus_go/features/fitness/data/fitness_repository.dart';
import 'package:olympus_go/features/fitness/domain/fitness_models.dart';
import 'package:olympus_go/features/fitness/presentation/ai_plan_screen.dart';
import 'package:olympus_go/features/fitness/presentation/fitness_screens.dart';
import 'package:olympus_go/features/fitness/presentation/program_screens.dart';
import 'package:olympus_go/features/fitness/presentation/train_screen.dart';
import 'package:olympus_go/features/settings/presentation/settings_screens.dart';

class _Closed extends DemoFitnessRepository {
  @override
  Future<bool> open() async => false;
}

class _Failing extends DemoFitnessRepository {
  @override
  Future<WorkoutSummary> summary({int? days = 30}) async =>
      throw const AuthFailure('Check your connection.');
}

class _Recovers extends DemoFitnessRepository {
  var fail = true;

  @override
  Future<WorkoutSummary> summary({int? days = 30}) async {
    if (fail) throw const AuthFailure('Check your connection.');
    return super.summary(days: days);
  }
}

class _NoAi extends DemoFitnessRepository {
  @override
  Future<AiStatus> aiStatus() async => const AiStatus();
}

class _AiStatusFails extends DemoFitnessRepository {
  @override
  Future<AiStatus> aiStatus() async =>
      throw const AuthFailure('Check your connection.');
}

class _NoneLeft extends DemoFitnessRepository {
  @override
  Future<AiStatus> aiStatus() async =>
      const AiStatus(open: true, agreed: true, left: 0);
}

class _CountsLists extends DemoFitnessRepository {
  var calls = 0;

  @override
  Future<List<WorkoutProgram>> programs() async {
    calls++;
    throw const AuthFailure('Check your connection.');
  }
}

class _SlowPlan extends DemoFitnessRepository {
  final finish = Completer<void>();
  var asks = 0;

  @override
  Future<String> askPlan({
    required String key,
    required String goal,
    required int days,
  }) async {
    asks++;
    await finish.future;
    return super.askPlan(key: key, goal: goal, days: days);
  }
}

class _RemembersGoal extends DemoFitnessRepository {
  String? lastGoal;

  @override
  Future<String> askPlan({
    required String key,
    required String goal,
    required int days,
  }) {
    lastGoal = goal;
    return super.askPlan(key: key, goal: goal, days: days);
  }
}

class _ClosedButAgreed extends DemoFitnessRepository {
  var withdrawn = false;

  @override
  Future<AiStatus> aiStatus() async => AiStatus(agreed: !withdrawn);

  @override
  Future<void> setAiConsent(bool agreed) async => withdrawn = !agreed;
}

class _ListFails extends DemoFitnessRepository {
  var failList = false;
  var asks = 0;

  @override
  Future<List<WorkoutProgram>> programs() async {
    if (failList) throw const AuthFailure('Check your connection.');
    return super.programs();
  }

  @override
  Future<String> askPlan({
    required String key,
    required String goal,
    required int days,
  }) async {
    asks++;
    final fail = failList;
    failList = false;
    final id = await super.askPlan(key: key, goal: goal, days: days);
    failList = fail;
    return id;
  }
}

class _AiFails extends DemoFitnessRepository {
  var offline = true;
  final keys = <String>[];
  final goals = <String>[];

  @override
  Future<String> askPlan({
    required String key,
    required String goal,
    required int days,
  }) async {
    keys.add(key);
    goals.add(goal);
    if (offline) throw const AuthFailure('Check your connection.');
    throw const AiPlanRefused('Couldn’t make a plan. Try again.');
  }
}

class _Minor extends DemoFitnessRepository {
  @override
  Future<WorkoutSummary> summary({int? days = 30}) async =>
      const WorkoutSummary();
}

class _Offline extends DemoFitnessRepository {
  var fail = true;
  var saves = 0;

  @override
  Future<void> saveWorkout(ActiveWorkout workout) async {
    saves++;
    if (fail) throw const AuthFailure('Check your connection.');
    await super.saveWorkout(workout);
  }
}

class _Empty extends DemoFitnessRepository {
  @override
  Future<List<WorkoutProgram>> programs() async => const [];
}

Future<void> _pump(
  WidgetTester tester,
  FitnessRepository repo, {
  String at = Routes.fitness,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(path: '/host', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: Routes.fitness,
        builder: (_, _) => const FitnessHomeScreen(),
      ),
      GoRoute(
        path: Routes.fitnessExercises,
        builder: (_, _) => const ExerciseCatalogScreen(),
      ),
      GoRoute(
        path: Routes.fitnessExercisePick,
        builder: (_, _) => const ExerciseCatalogScreen(pick: true),
      ),
      GoRoute(
        path: '/fitness/exercises/:id',
        builder: (_, s) => ExerciseDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.fitnessPrograms,
        builder: (_, _) => const ProgramsScreen(),
      ),
      GoRoute(
        path: '/fitness/programs/:id',
        builder: (_, s) => ProgramBuilderScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.fitnessTrain,
        builder: (_, _) => const TrainScreen(),
      ),
      GoRoute(
        path: Routes.fitnessLog,
        builder: (_, _) => const WorkoutLogScreen(),
      ),
      GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(
        path: Routes.fitnessAiPlan,
        builder: (_, _) => const AiPlanScreen(),
      ),
      GoRoute(
        path: Routes.fitnessCalculators,
        builder: (_, _) => const CalculatorsScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
      retry: (_, _) => null,
      child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push(at);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final f = find.text(label);
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with the flag off the page stays as it was', (tester) async {
    await _pump(tester, _Closed());
    expect(find.text('Workouts will be here. None are open yet.'), findsOne);
    expect(find.text('Start workout'), findsNothing);
  });

  testWidgets('home offers a workout and the four rows', (tester) async {
    await _pump(tester, DemoFitnessRepository());
    expect(find.text('Start workout'), findsOne);
    for (final t in [
      'Exercises',
      'My programs',
      'Workout log',
      'Calculators',
    ]) {
      expect(find.text(t), findsOne);
    }
    expect(find.textContaining('private to you'), findsOne);
    expect(find.textContaining('stay on this phone'), findsNothing);
  });

  testWidgets('home shows a failure and can retry', (tester) async {
    await _pump(tester, _Failing());
    expect(find.text('Check your connection.'), findsOne);
    expect(find.text('Try again'), findsOne);
  });

  testWidgets('with no programs home still works', (tester) async {
    await _pump(tester, _Empty());
    expect(find.text('Start workout'), findsNothing);
    expect(find.text('Exercises'), findsOne);
  });

  testWidgets('the catalogue filters and searches', (tester) async {
    await _pump(tester, DemoFitnessRepository(), at: Routes.fitnessExercises);
    expect(find.text('Back squat'), findsOne);
    await _tap(tester, 'Core');
    expect(find.text('Back squat'), findsNothing);
    expect(find.text('Plank'), findsOne);
    await _tap(tester, 'All');
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No exercise matches'), findsOne);
  });

  testWidgets('an exercise shows its steps and no promises', (tester) async {
    await _pump(
      tester,
      DemoFitnessRepository(),
      at: Routes.fitnessExercise('squat'),
    );
    expect(find.text('How to do it'), findsOne);
    expect(find.textContaining('Sit back and down'), findsOne);
    expect(find.textContaining('faster recovery'), findsNothing);
  });

  testWidgets('a workout runs set by set and saves', (tester) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Start workout');
    expect(find.text('Plank'), findsOne);
    expect(find.textContaining('SET 1 OF 3'), findsOne);

    await _tap(tester, 'Set done');
    expect(find.text('REST'), findsOne);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('REST'), findsOne);
    await tester.tap(find.text('Skip rest'));
    await tester.pump();
    expect(find.textContaining('SET 2 OF 3'), findsOne);

    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    final s = await tester.runAsync(() => repo.summary());
    expect(s!.workouts, 1);
    expect(await tester.runAsync(repo.loadActive), isNull);
  });

  testWidgets('a set in progress reaches the phone straight away', (
    tester,
  ) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Start workout');
    await _tap(tester, 'Set done');
    final kept = await tester.runAsync(repo.loadActive);
    expect(kept!.done, hasLength(1));
    await tester.tap(find.text('Skip rest'));
    await tester.pump();
  });

  testWidgets('no signal keeps the workout, and a retry saves it once', (
    tester,
  ) async {
    final repo = _Offline();
    await _pump(tester, repo);
    await _tap(tester, 'Start workout');
    await _tap(tester, 'Set done');
    await tester.tap(find.text('Skip rest'));
    await tester.pump();
    await _tap(tester, 'Finish workout');
    expect(find.text('Not saved yet'), findsOne);
    expect(find.text('Check your connection.'), findsOne);
    final kept = await tester.runAsync(repo.loadActive);
    expect(kept!.finished, isTrue);
    final key = kept.key;

    repo.fail = false;
    await tester.tap(find.text('Try saving again'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(repo.saves, 2);
    expect(await tester.runAsync(repo.loadActive), isNull);
    final s = await tester.runAsync(() => repo.summary());
    expect(s!.recent.single.id, key);
  });

  testWidgets('a discarded workout is gone', (tester) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Start workout');
    await tester.tap(find.bySemanticsLabel('Discard workout'));
    await tester.pumpAndSettle();
    await _tap(tester, 'Discard workout');
    expect(await tester.runAsync(repo.loadActive), isNull);
  });

  testWidgets('a program is built from a template and saved', (tester) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo, at: Routes.fitnessProgram('new'));
    await _tap(tester, 'Court speed');
    expect(find.text('Plank'), findsOne);
    await _tap(tester, 'Save program');
    final all = await tester.runAsync(repo.programs);
    final mine = all!.where((p) => !p.template).toList();
    expect(mine.single.name, 'Court speed');
    expect(mine.single.id, isNot('court-speed'));
  });

  testWidgets('a program item can be changed', (tester) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo, at: Routes.fitnessProgram('new'));
    await _tap(tester, 'Court speed');
    await _tap(tester, 'Push-up');
    await tester.enterText(find.widgetWithText(TextField, '10').first, '999');
    await _tap(tester, 'Done');
    expect(find.text('Check the sets, reps, weight and rest.'), findsOne);
    await tester.enterText(find.widgetWithText(TextField, '999').first, '12');
    await _tap(tester, 'Done');
    expect(find.textContaining('3 sets × 12'), findsOne);
  });

  testWidgets('a started workout can\'t be wiped by starting another', (
    tester,
  ) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Start workout');
    await _tap(tester, 'Set done');
    final before = await tester.runAsync(repo.loadActive);

    await tester.tap(find.text('Skip rest'));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrainScreen)),
    );
    final started = await tester.runAsync(
      () => container
          .read(activeSessionProvider.notifier)
          .start(name: 'Other', plan: const []),
    );
    expect(started, isFalse);
    final after = await tester.runAsync(repo.loadActive);
    expect(after!.key, before!.key);
    expect(after.done, hasLength(1));
  });

  testWidgets('a workout moves on to its next exercise', (tester) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Start workout');
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'Set done');
      await tester.tap(find.text('Skip rest'));
      await tester.pump();
    }
    expect(find.text('Push-up'), findsOne);
    expect(find.textContaining('EXERCISE 2 OF 2'), findsOne);
  });

  testWidgets('a changed time or rep count is what gets logged', (
    tester,
  ) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo);
    await _tap(tester, 'Start workout');
    await _tap(tester, 'Change weight or reps');
    await tester.enterText(find.byType(TextField).first, '60');
    await _tap(tester, 'Done');
    await _tap(tester, 'Set done');
    final kept = await tester.runAsync(repo.loadActive);
    expect(kept!.done.single.seconds, 60);
    await tester.tap(find.text('Skip rest'));
    await tester.pump();
  });

  testWidgets('no signal on home still shows the waiting workout', (
    tester,
  ) async {
    final repo = _Recovers();
    await tester.runAsync(
      () => repo.storeActive(
        ActiveWorkout(
          key: 'k',
          name: 'Legs',
          startedAt: DateTime(2026, 11),
          plan: const [],
        ).ended(DateTime(2026, 11, 1, 0, 30)),
      ),
    );
    await _pump(tester, repo);
    expect(find.text('Save workout'), findsOne);
    expect(find.textContaining('Can’t load your workouts'), findsOne);
    expect(find.text('Exercises'), findsNothing);

    repo.fail = false;
    await _tap(tester, 'Try again');
    expect(find.text('Save workout'), findsOne);
    expect(find.text('Exercises'), findsOne);
  });

  test('a late change can\'t land on the next exercise', () async {
    final repo = DemoFitnessRepository();
    final c = ProviderContainer(
      overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    const one = ProgramItem(
      exerciseId: 'a',
      exercise: 'A',
      mark: 'AA',
      sets: 1,
      reps: 5,
    );
    const two = ProgramItem(
      exerciseId: 'b',
      exercise: 'B',
      mark: 'BB',
      sets: 1,
      reps: 8,
    );
    final session = c.read(activeSessionProvider.notifier);
    await session.start(name: 'Legs', plan: const [one, two]);
    await session.log(const LoggedSet(exerciseId: 'a', reps: 5));
    await session.adjust(0, one.change(reps: 12));
    final w = await repo.loadActive();
    expect(w!.current!.exerciseId, 'b');
    expect(w.current!.reps, 8);
  });

  testWidgets('deleting a program asks first', (tester) async {
    final repo = DemoFitnessRepository();
    await tester.runAsync(
      () => repo.saveProgram(
        const WorkoutProgram(
          id: 'mine',
          name: 'Mine',
          days: [
            ProgramDay(
              items: [
                ProgramItem(
                  exerciseId: 'plank',
                  exercise: 'Plank',
                  mark: 'PL',
                  sets: 3,
                  timed: true,
                  seconds: 45,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await _pump(tester, repo, at: Routes.fitnessProgram('mine'));
    await tester.tap(find.bySemanticsLabel('Delete program'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this program?'), findsOne);
    await _tap(tester, 'Keep it');
    expect(await tester.runAsync(repo.programs), hasLength(2));
    await tester.tap(find.bySemanticsLabel('Delete program'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete program').last);
    await tester.pumpAndSettle();
    expect(await tester.runAsync(repo.programs), hasLength(1));
  });

  testWidgets('the log shows an empty state, then totals', (tester) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo, at: Routes.fitnessLog);
    expect(find.textContaining('No workouts yet'), findsOne);

    await tester.runAsync(
      () => repo.saveWorkout(
        ActiveWorkout(
          key: 'k',
          name: 'Legs',
          startedAt: DateTime.now().subtract(const Duration(minutes: 46)),
          plan: const [],
          done: const [LoggedSet(exerciseId: 'squat', reps: 5, weightG: 70000)],
        ).ended(DateTime.now()),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, repo, at: Routes.fitnessLog);
    expect(find.text('Legs'), findsOne);
    expect(find.text('350 kg'), findsWidgets);
    expect(find.textContaining('46 min'), findsWidgets);
  });

  testWidgets('an adult sees Plan with AI, and others never do', (
    tester,
  ) async {
    await _pump(tester, DemoFitnessRepository(), at: Routes.fitnessPrograms);
    expect(find.text('Plan with AI'), findsOne);

    await tester.pumpWidget(const SizedBox());
    await _pump(tester, _NoAi(), at: Routes.fitnessPrograms);
    expect(find.text('Plan with AI'), findsNothing);
  });

  testWidgets('AI plans stay hidden if the status can\'t load', (tester) async {
    await _pump(tester, _AiStatusFails(), at: Routes.fitnessPrograms);
    expect(find.text('Plan with AI'), findsNothing);
  });

  testWidgets('going straight to the screen is refused if it isn\'t open', (
    tester,
  ) async {
    await _pump(tester, _NoAi(), at: Routes.fitnessAiPlan);
    expect(find.textContaining('aren’t available'), findsOne);
    expect(find.text('Make my plan'), findsNothing);
    expect(find.text('Agree'), findsNothing);
  });

  testWidgets('the first plan asks first, and says what is sent', (
    tester,
  ) async {
    final repo = DemoFitnessRepository();
    await _pump(tester, repo, at: Routes.fitnessAiPlan);
    expect(find.text('Before your first plan'), findsOne);
    expect(find.textContaining('Anthropic'), findsOne);
    expect(find.textContaining('outside'), findsOne);
    expect(find.textContaining('name, username, email'), findsOne);
    expect(find.text('Make my plan'), findsNothing);

    await _tap(tester, 'Agree');
    expect(find.text('Make my plan'), findsOne);
    expect(find.text('3 plans left today.'), findsOne);
    expect((await tester.runAsync(repo.aiStatus))!.agreed, isTrue);
  });

  testWidgets('a plan opens as a labelled draft', (tester) async {
    final repo = _RemembersGoal();
    await tester.runAsync(() => repo.setAiConsent(true));
    await _pump(tester, repo, at: Routes.fitnessAiPlan);
    await _tap(tester, 'Get stronger');
    await _tap(tester, '2');
    await _tap(tester, 'Make my plan');
    expect(repo.lastGoal, 'strength');
    expect(find.textContaining('AI suggested this plan'), findsOne);
    expect(find.textContaining('coach or a doctor'), findsOne);
    expect(find.text('Save program'), findsOne);
    final all = await tester.runAsync(repo.programs);
    final mine = all!.where((p) => p.fromAi).single;
    expect(mine.days, hasLength(2));
  });

  testWidgets('a dropped signal keeps the key and locks the choices', (
    tester,
  ) async {
    final repo = _AiFails();
    await tester.runAsync(() => repo.setAiConsent(true));
    await _pump(tester, repo, at: Routes.fitnessAiPlan);
    await _tap(tester, 'Make my plan');
    expect(find.text('Check your connection.'), findsOne);

    await _tap(tester, 'Get stronger');
    await _tap(tester, 'Make my plan');
    expect(repo.keys[1], repo.keys[0]);
    expect(repo.goals, ['speed', 'speed']);

    repo.offline = false;
    await _tap(tester, 'Make my plan');
    expect(find.textContaining('Couldn’t make a plan'), findsOne);
    await _tap(tester, 'Make my plan');
    expect(repo.keys[3], isNot(repo.keys[2]));
  });

  testWidgets('leaving the screen keeps the key', (tester) async {
    final repo = _AiFails();
    await tester.runAsync(() => repo.setAiConsent(true));
    await _pump(tester, repo, at: Routes.fitnessAiPlan);
    await _tap(tester, 'Make my plan');
    final element = tester.element(find.byType(AiPlanScreen));
    final c = ProviderScope.containerOf(element);
    GoRouter.of(element).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AiPlanScreen), findsNothing);
    expect(c.read(aiPlanRequestProvider)?.key, repo.keys.single);
  });

  testWidgets('a plan that finishes after leaving is kept, not paid again', (
    tester,
  ) async {
    final repo = _SlowPlan();
    await tester.runAsync(() => repo.setAiConsent(true));
    await _pump(tester, repo, at: Routes.fitnessAiPlan);
    await tester.tap(find.text('Make my plan'));
    await tester.pump();

    final element = tester.element(find.byType(AiPlanScreen));
    final router = GoRouter.of(element);
    router.pop();
    await tester.pumpAndSettle();
    repo.finish.complete();
    await tester.pumpAndSettle();

    router.push(Routes.fitnessAiPlan);
    await tester.pumpAndSettle();
    expect(find.text('Open my plan'), findsOne);
    expect(find.text('Your plan is ready.'), findsOne);
    await _tap(tester, 'Open my plan');
    expect(repo.asks, 1);
    expect(find.textContaining('AI suggested this plan'), findsOne);
  });

  testWidgets('a plan paid for but not opened is never asked for again', (
    tester,
  ) async {
    final repo = _ListFails();
    await tester.runAsync(() => repo.setAiConsent(true));
    await _pump(tester, repo, at: Routes.fitnessAiPlan);
    repo.failList = true;
    await tester.tap(find.text('Make my plan'));
    await tester.pumpAndSettle();
    expect(find.text('Check your connection.'), findsOne);
    expect(find.text('Your plan is ready.'), findsOne);
    expect(repo.asks, 1);

    repo.failList = false;
    await _tap(tester, 'Open my plan');
    expect(repo.asks, 1);
    expect(find.textContaining('AI suggested this plan'), findsOne);
  });

  testWidgets('the button stays off with none left, but a kept key can retry', (
    tester,
  ) async {
    await _pump(tester, _NoneLeft(), at: Routes.fitnessAiPlan);
    final button = tester.widget<KitButton>(
      find.widgetWithText(KitButton, 'Make my plan'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Privacy offers AI plans to adults when open', (tester) async {
    final repo = DemoFitnessRepository();
    await tester.runAsync(() => repo.setAiConsent(true));
    await _pump(tester, repo, at: Routes.privacy);
    expect(find.text('AI plans'), findsOne);
    await tester.tap(find.byType(CupertinoSwitch).last);
    await tester.pumpAndSettle();
    expect((await tester.runAsync(repo.aiStatus))!.agreed, isFalse);
  });

  testWidgets('a ready plan still opens with none left today', (tester) async {
    final repo = _NoneLeft();
    await _pump(tester, repo, at: Routes.fitnessPrograms);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(ProgramsScreen)),
    );
    c
        .read(aiPlanRequestProvider.notifier)
        .start(
          const AiPlanTicket(
            key: 'k',
            goal: 'speed',
            days: 2,
            programId: 'ready',
          ),
        );
    GoRouter.of(tester.element(find.byType(ProgramsScreen)))
        .push(Routes.fitnessAiPlan);
    await tester.pumpAndSettle();
    final button = tester.widget<KitButton>(
      find.widgetWithText(KitButton, 'Open my plan'),
    );
    expect(button.onPressed, isNotNull);
  });

  test('a late answer can\'t land on another ticket', () {
    final c = ProviderContainer(
      overrides: [fitnessRepositoryProvider.overrideWithValue(_NoAi())],
    );
    addTearDown(c.dispose);
    final request = c.read(aiPlanRequestProvider.notifier);
    request.start(const AiPlanTicket(key: 'b', goal: 'speed', days: 2));
    request.saved('a', 'program-of-a');
    expect(c.read(aiPlanRequestProvider)?.programId, isNull);
    request.clear('a');
    expect(c.read(aiPlanRequestProvider)?.key, 'b');
    request.saved('b', 'program-of-b');
    expect(c.read(aiPlanRequestProvider)?.programId, 'program-of-b');
    request.clear('b');
    expect(c.read(aiPlanRequestProvider), isNull);
  });

  test('the program list fails at once, with no retry', () async {
    final repo = _CountsLists();
    final c = ProviderContainer(
      overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(workoutProgramsProvider, (_, _) {});
    addTearDown(sub.close);
    await expectLater(
      c.read(workoutProgramsProvider.future),
      throwsA(isA<AuthFailure>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(repo.calls, 1);
  });

  testWidgets('Privacy says so when AI plans can\'t load', (tester) async {
    await _pump(tester, _AiStatusFails(), at: Routes.privacy);
    expect(find.textContaining('Can’t load AI plans'), findsOne);
  });

  testWidgets('Privacy hides AI plans from those who can\'t use them', (
    tester,
  ) async {
    await _pump(tester, _NoAi(), at: Routes.privacy);
    expect(find.text('AI plans'), findsNothing);
  });

  testWidgets('withdrawing stays possible once AI plans are switched off', (
    tester,
  ) async {
    final repo = _ClosedButAgreed();
    await _pump(tester, repo, at: Routes.privacy);
    expect(find.text('AI plans'), findsOne);
    await tester.tap(find.byType(CupertinoSwitch).last);
    await tester.pumpAndSettle();
    expect(repo.withdrawn, isTrue);
  });

  testWidgets('no plans left today says so', (tester) async {
    await _pump(tester, _NoneLeft(), at: Routes.fitnessAiPlan);
    expect(find.textContaining('made today’s plans'), findsOne);
  });

  testWidgets('an adult sees three calculators, with no health verdict', (
    tester,
  ) async {
    await _pump(tester, DemoFitnessRepository(), at: Routes.fitnessCalculators);
    expect(find.text('79 kg'), findsOne);
    await _tap(tester, 'Plates');
    expect(find.text('20 + 5 kg'), findsOne);
    await _tap(tester, 'Body mass index');
    expect(find.textContaining('healthy'), findsNothing);
  });

  testWidgets('a minor sees only the plates calculator', (tester) async {
    await _pump(tester, _Minor(), at: Routes.fitnessCalculators);
    expect(find.text('One-rep max'), findsNothing);
    expect(find.text('Body mass index'), findsNothing);
    expect(find.text('Plates'), findsOne);
  });

  testWidgets('calculators hide the adult ones if the answer never comes', (
    tester,
  ) async {
    await _pump(tester, _Failing(), at: Routes.fitnessCalculators);
    expect(find.text('One-rep max'), findsNothing);
  });
}
