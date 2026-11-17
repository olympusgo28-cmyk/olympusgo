// Progression suggestions (owner, 17 Nov 2026; Q277 slice 3; R-FIT-11): the
// rule, one test per row of its table, and the line on the workout screen.

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
import 'package:olympus_go/features/fitness/domain/progression.dart';
import 'package:olympus_go/features/fitness/presentation/train_screen.dart';

/// The numbers the owner chose (Q277 c).
const _rules = ProgressRules(
  stepG: 2500,
  stallSessions: 3,
  deloadPct: 10,
  repStep: 1,
  repCap: 20,
  secondsStep: 5,
  secondsCap: 120,
);

ProgressRules _with({
  int? stepG,
  int? stallSessions,
  int? deloadPct,
  int? repStep,
  int? repCap,
  int? secondsStep,
  int? secondsCap,
}) => ProgressRules(
  stepG: stepG ?? _rules.stepG,
  stallSessions: stallSessions ?? _rules.stallSessions,
  deloadPct: deloadPct ?? _rules.deloadPct,
  repStep: repStep ?? _rules.repStep,
  repCap: repCap ?? _rules.repCap,
  secondsStep: secondsStep ?? _rules.secondsStep,
  secondsCap: secondsCap ?? _rules.secondsCap,
);

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

const _pushUp = ProgramItem(
  exerciseId: 'push-up',
  exercise: 'Push-up',
  mark: 'PU',
  sets: 3,
  reps: 10,
);

const _plank = ProgramItem(
  exerciseId: 'plank',
  exercise: 'Plank',
  mark: 'PL',
  sets: 2,
  timed: true,
  seconds: 30,
);

DateTime _day(int daysAgo) => DateTime(2026, 11, 17 - daysAgo, 19);

/// One session's sets, oldest first.
List<PersonalBest> _session(
  int daysAgo,
  List<int> amounts, {
  int? weightG,
  bool seconds = false,
}) => [
  for (final a in amounts)
    PersonalBest(
      exercise: '',
      at: _day(daysAgo),
      reps: seconds ? null : a,
      seconds: seconds ? a : null,
      weightG: weightG,
    ),
];

/// A history from [sessions], newest session first, as the server sends it:
/// newest set first.
ExerciseHistory _history(
  List<List<PersonalBest>> sessions, {
  ProgressRules? rules = _rules,
}) => ExerciseHistory(
  times: sessions.length,
  recent: [for (final s in sessions) ...s.reversed],
  progress: rules,
);

class _Repo extends DemoFitnessRepository {
  _Repo(this.histories, {this.failing = false});

  final Map<String, ExerciseHistory> histories;
  final bool failing;

  @override
  Future<ExerciseHistory> history(String exerciseId) async {
    if (failing) throw StateError('no signal');
    return histories[exerciseId] ?? const ExerciseHistory();
  }
}

ActiveWorkout _workout(List<ProgramItem> plan) => ActiveWorkout(
  key: 'key-12345678',
  name: 'Leg day',
  startedAt: DateTime.now(),
  plan: plan,
);

void main() {
  group('the numbers from the server', () {
    test('are read when all seven are there', () {
      final r = ProgressRules.fromJson({
        'step_g': 2500,
        'stall_sessions': 3,
        'deload_pct': 10,
        'rep_step': 1,
        'rep_cap': 20,
        'seconds_step': 5,
        'seconds_cap': 120,
      })!;
      expect(r.stepG, 2500);
      expect(r.stallSessions, 3);
      expect(r.deloadPct, 10);
      expect(r.repStep, 1);
      expect(r.repCap, 20);
      expect(r.secondsStep, 5);
      expect(r.secondsCap, 120);
    });

    test('are nothing when the server sends none (an under-18)', () {
      expect(ProgressRules.fromJson(null), isNull);
      final h = ExerciseHistory.fromJson({
        'times': 1,
        'best': null,
        'recent': <dynamic>[],
        'progress': null,
      });
      expect(h.progress, isNull);
    });

    test('are nothing when one is missing or not a whole number', () {
      final all = {
        'step_g': 2500,
        'stall_sessions': 3,
        'deload_pct': 10,
        'rep_step': 1,
        'rep_cap': 20,
        'seconds_step': 5,
        'seconds_cap': 120,
      };
      for (final key in all.keys) {
        expect(ProgressRules.fromJson({...all}..remove(key)), isNull);
        expect(ProgressRules.fromJson({...all, key: '5'}), isNull);
        expect(ProgressRules.fromJson({...all, key: 2.5}), isNull);
      }
      expect(ProgressRules.fromJson('nope'), isNull);
    });

    test('a history from before this change still reads', () {
      final h = ExerciseHistory.fromJson({
        'times': 0,
        'best': null,
        'recent': <dynamic>[],
      });
      expect(h.progress, isNull);
    });
  });

  group('the rule, row by row', () {
    test('weighted, every set reached the planned reps: add weight', () {
      final s = suggestNext(
        _squat,
        _history([
          _session(5, [5, 5, 5], weightG: 70000),
        ]),
      )!;
      expect(s.text, 'Try 72.5 kg. You hit 5 reps on every set last time.');
      expect(s.weightG, 72500);
      expect(s.reps, isNull);
      expect(s.usable, isTrue);
    });

    test('weighted, more reps than planned still counts as hit', () {
      final s = suggestNext(
        _squat,
        _history([
          _session(5, [6, 5, 7], weightG: 70000),
        ]),
      )!;
      expect(s.weightG, 72500);
    });

    test('weighted, any set missed reps: same weight, nothing to take', () {
      final s = suggestNext(
        _squat,
        _history([
          _session(5, [5, 5, 4], weightG: 70000),
        ]),
      )!;
      expect(s.text, 'Stay at 70 kg. You missed reps on a set last time.');
      expect(s.usable, isFalse);
    });

    test('weighted, reps missed 3 sessions in a row: less weight, rounded '
        'down to the step', () {
      final s = suggestNext(
        _squat,
        _history([
          _session(2, [5, 4, 4], weightG: 70000),
          _session(5, [5, 5, 4], weightG: 70000),
          _session(9, [5, 4, 3], weightG: 70000),
        ]),
      )!;
      // 10% less than 70 kg is 63 kg; down to the 2.5 kg step is 62.5 kg.
      expect(s.text, 'Try 62.5 kg. 3 sessions without hitting your reps.');
      expect(s.weightG, 62500);
    });

    test('weighted, only 2 missed in a row: stay', () {
      final s = suggestNext(
        _squat,
        _history([
          _session(2, [5, 4, 4], weightG: 70000),
          _session(5, [5, 5, 4], weightG: 70000),
          _session(9, [5, 5, 5], weightG: 70000),
        ]),
      )!;
      expect(s.usable, isFalse);
      expect(s.text, startsWith('Stay at 70 kg.'));
    });

    test('weighted, 3 missed but not all at this weight: stay', () {
      final s = suggestNext(
        _squat,
        _history([
          _session(2, [5, 4, 4], weightG: 70000),
          _session(5, [5, 5, 4], weightG: 70000),
          _session(9, [4, 4, 3], weightG: 67500),
        ]),
      )!;
      expect(s.usable, isFalse);
    });

    test('unweighted, every set reached the planned reps: one more rep', () {
      final s = suggestNext(
        _pushUp,
        _history([
          _session(3, [10, 10, 12]),
        ]),
      )!;
      expect(s.text, 'Try 11 reps. You hit 10 on every set last time.');
      expect(s.reps, 11);
      expect(s.weightG, isNull);
    });

    test('unweighted, at the limit: nothing more', () {
      final item = _pushUp.change(reps: 20);
      expect(
        suggestNext(
          item,
          _history([
            _session(3, [20, 20, 20]),
          ]),
        ),
        isNull,
      );
    });

    test('unweighted, a step past the limit stops at the limit', () {
      final s = suggestNext(
        _pushUp.change(reps: 18),
        _history([
          _session(3, [18, 18, 18]),
        ], rules: _with(repStep: 5)),
      )!;
      expect(s.reps, 20);
    });

    test('unweighted, a set missed: no suggestion', () {
      expect(
        suggestNext(
          _pushUp,
          _history([
            _session(3, [10, 9, 10]),
          ]),
        ),
        isNull,
      );
    });

    test('timed, every set reached the planned time: more time', () {
      final s = suggestNext(
        _plank,
        _history([
          _session(3, [30, 31], seconds: true),
        ]),
      )!;
      expect(s.text, 'Try 35 seconds. You held 30 on every set last time.');
      expect(s.seconds, 35);
    });

    test('timed, at the limit, or a set cut short: nothing', () {
      expect(
        suggestNext(
          _plank.change(seconds: 120),
          _history([
            _session(3, [120, 120], seconds: true),
          ]),
        ),
        isNull,
      );
      expect(
        suggestNext(
          _plank,
          _history([
            _session(3, [30, 20], seconds: true),
          ]),
        ),
        isNull,
      );
    });

    test('timed, a step past the limit stops at the limit', () {
      final s = suggestNext(
        _plank.change(seconds: 118),
        _history([
          _session(3, [118, 118], seconds: true),
        ]),
      )!;
      expect(s.seconds, 120);
    });
  });

  group('the history holds no target, so a raised target is not a miss', () {
    test('reps raised since: three sessions that hit 5 are not three misses '
        'at 8', () {
      final item = _squat.change(reps: 8);
      final s = suggestNext(
        item,
        _history([
          for (final d in [2, 5, 9]) _session(d, [5, 5, 5], weightG: 70000),
        ]),
      );
      // Not "Try 62.5 kg", and not "you missed reps" either.
      expect(s, isNull);
    });

    test(
      'only sessions that aimed at these reps count towards less weight',
      () {
        final item = _squat.change(reps: 8);
        final s = suggestNext(
          item,
          _history([
            _session(2, [8, 7, 7], weightG: 70000),
            _session(5, [5, 5, 5], weightG: 70000),
            _session(9, [5, 5, 5], weightG: 70000),
          ]),
        )!;
        expect(s.text, 'Stay at 70 kg. You missed reps on a set last time.');
        expect(s.usable, isFalse);
      },
    );

    test(
      'every set short, every time, gets no line (the known gap, Q277 r)',
      () {
        final s = suggestNext(
          _squat,
          _history([
            for (final d in [2, 5, 9]) _session(d, [4, 4, 3], weightG: 70000),
          ]),
        );
        expect(s, isNull);
      },
    );
  });

  group('edges the review asked for', () {
    test('a timed exercise that carries weight gets no suggestion yet', () {
      const carry = ProgramItem(
        exerciseId: 'farmer-carry',
        exercise: 'Farmer carry',
        mark: 'FC',
        sets: 2,
        timed: true,
        weighted: true,
        seconds: 30,
        weightG: 40000,
      );
      // 30 seconds at 20 kg last time says nothing about 40 kg now.
      expect(
        suggestNext(
          carry,
          _history([
            _session(3, [30, 30], seconds: true, weightG: 20000),
          ]),
        ),
        isNull,
      );
      expect(
        suggestNext(
          carry,
          _history([
            _session(3, [30, 30], seconds: true, weightG: 40000),
          ]),
        ),
        isNull,
      );
    });

    test('a stall setting of 1 reads "1 session"', () {
      final s = suggestNext(
        _squat,
        _history([
          _session(2, [5, 4, 4], weightG: 70000),
        ], rules: _with(stallSessions: 1)),
      )!;
      expect(s.text, 'Try 62.5 kg. 1 session without hitting your reps.');
    });

    test('a limit below 1 means no suggestion, not no limit', () {
      expect(
        suggestNext(
          _pushUp,
          _history([
            _session(3, [10, 10, 10]),
          ], rules: _with(repCap: 0)),
        ),
        isNull,
      );
      expect(
        suggestNext(
          _plank,
          _history([
            _session(3, [30, 30], seconds: true),
          ], rules: _with(secondsCap: -1)),
        ),
        isNull,
      );
    });

    test('ten sets a session: with a full history only two can be trusted', () {
      final full = _history([
        for (final d in [2, 5, 9])
          _session(d, [5, ...List.filled(9, 4)], weightG: 70000),
      ]);
      final s = suggestNext(_squat.change(sets: 10), full)!;
      expect(s.usable, isFalse);
      expect(s.text, startsWith('Stay at 70 kg.'));
    });
  });

  group('no suggestion when it can’t be judged fairly', () {
    final hit = _session(5, [5, 5, 5], weightG: 70000);

    test('an under-18, or numbers that can’t be read', () {
      expect(suggestNext(_squat, _history([hit], rules: null)), isNull);
    });

    test('a first time', () {
      expect(
        suggestNext(_squat, const ExerciseHistory(progress: _rules)),
        isNull,
      );
    });

    test('fewer sets last time than planned now', () {
      // One set before an abandoned workout must not earn "add weight".
      expect(
        suggestNext(
          _squat,
          _history([
            _session(5, [5], weightG: 70000),
          ]),
        ),
        isNull,
      );
      expect(
        suggestNext(
          _squat,
          _history([
            _session(5, [5, 5], weightG: 70000),
          ]),
        ),
        isNull,
      );
    });

    test('mixed weights last time', () {
      final mixed = [
        ..._session(5, [5, 5], weightG: 70000),
        ..._session(5, [5], weightG: 72500),
      ];
      expect(suggestNext(_squat, _history([mixed])), isNull);
    });

    test('a weight planned now that is not last time’s', () {
      expect(
        suggestNext(_squat.change(weightG: 75000), _history([hit])),
        isNull,
      );
      expect(
        suggestNext(_squat.change(weightG: 65000), _history([hit])),
        isNull,
      );
    });

    test('no weight planned, but weight last time', () {
      expect(
        suggestNext(_squat.change(noWeight: true), _history([hit])),
        isNull,
      );
    });

    test('a weighted exercise done with no weight is judged on reps', () {
      final s = suggestNext(
        _squat.change(noWeight: true),
        _history([
          _session(5, [5, 5, 5]),
        ]),
      )!;
      expect(s.reps, 6);
    });

    test('the oldest session is not judged when the history is full', () {
      // 30 sets: three sessions of 10. The oldest may be cut short.
      final full = _history([
        _session(2, [5, ...List.filled(9, 4)], weightG: 70000),
        _session(5, [5, ...List.filled(9, 4)], weightG: 70000),
        _session(9, [5, ...List.filled(9, 4)], weightG: 70000),
      ]);
      expect(full.recent.length, 30);
      final s = suggestNext(_squat, full)!;
      // Only two sessions can be trusted, so it is "stay", not "less".
      expect(s.usable, isFalse);

      // With the only session possibly cut short, nothing at all.
      final one = _history([_session(2, List.filled(30, 5), weightG: 70000)]);
      expect(suggestNext(_squat, one), isNull);
    });

    test('a zero or negative step', () {
      expect(
        suggestNext(_squat, _history([hit], rules: _with(stepG: 0))),
        isNull,
      );
      expect(
        suggestNext(
          _pushUp,
          _history([
            _session(3, [10, 10, 10]),
          ], rules: _with(repStep: 0)),
        ),
        isNull,
      );
      expect(
        suggestNext(
          _plank,
          _history([
            _session(3, [30, 30], seconds: true),
          ], rules: _with(secondsStep: -5)),
        ),
        isNull,
      );
    });

    test('a result past what the database takes', () {
      final top = _session(5, [5, 5, 5], weightG: 500000);
      expect(
        suggestNext(_squat.change(weightG: 500000), _history([top])),
        isNull,
      );
      expect(
        suggestNext(
          _pushUp.change(reps: 200),
          _history([
            _session(3, [200, 200, 200]),
          ], rules: _with(repCap: 0)),
        ),
        isNull,
      );
    });

    test('a percent that makes no sense falls back to stay', () {
      final missed = [
        _session(2, [5, 4, 4], weightG: 70000),
        _session(5, [5, 5, 4], weightG: 70000),
        _session(9, [5, 4, 3], weightG: 70000),
      ];
      // With a sane percent these three do earn "less weight".
      expect(suggestNext(_squat, _history(missed))!.weightG, 62500);
      for (final pct in [0, 100, 150, -10]) {
        final s = suggestNext(
          _squat,
          _history(missed, rules: _with(deloadPct: pct)),
        )!;
        expect(s.usable, isFalse, reason: '$pct%');
      }
      // A light weight can't go below one step.
      final light = [
        for (final d in [2, 5, 9]) _session(d, [5, 4, 4], weightG: 2500),
      ];
      final s = suggestNext(_squat.change(weightG: 2500), _history(light))!;
      expect(s.usable, isFalse);
    });

    test('an exercise with nothing planned', () {
      const none = ProgramItem(
        exerciseId: 'squat',
        exercise: 'Back squat',
        mark: 'SQ',
        sets: 3,
      );
      expect(suggestNext(none, _history([hit])), isNull);
    });
  });

  group('taking a suggestion', () {
    Future<ProviderContainer> open(ActiveWorkout workout) async {
      final repo = _Repo(const {});
      await repo.storeActive(workout);
      final c = ProviderContainer(
        overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
        retry: (_, _) => null,
      );
      addTearDown(c.dispose);
      await c.read(activeSessionProvider.future);
      return c;
    }

    test('changes only the weight, for this workout', () async {
      final c = await open(_workout([_squat]));
      await c
          .read(activeSessionProvider.notifier)
          .applySuggestion(0, from: _squat, weightG: 72500);
      final item = c.read(activeSessionProvider).value!.current!;
      expect(item.weightG, 72500);
      expect(item.reps, 5);
      expect(item.sets, 3);
      expect(item.restSeconds, 60);
    });

    test('changes only the reps, or only the seconds', () async {
      final c = await open(_workout([_pushUp]));
      await c
          .read(activeSessionProvider.notifier)
          .applySuggestion(0, from: _pushUp, reps: 11);
      expect(c.read(activeSessionProvider).value!.current!.reps, 11);

      final t = await open(_workout([_plank]));
      await t
          .read(activeSessionProvider.notifier)
          .applySuggestion(0, from: _plank, seconds: 35);
      expect(t.read(activeSessionProvider).value!.current!.seconds, 35);
    });

    test('never overwrites a change made in the meantime', () async {
      final c = await open(_workout([_squat]));
      final session = c.read(activeSessionProvider.notifier);
      final typed = session.adjust(0, _squat.change(weightG: 60000, reps: 8));
      final late = session.applySuggestion(0, from: _squat, weightG: 72500);
      await Future.wait([typed, late]);
      final item = c.read(activeSessionProvider).value!.current!;
      expect(item.weightG, 60000);
      expect(item.reps, 8);
    });

    test('does nothing once a set is done, or for another exercise', () async {
      final c = await open(_workout([_squat, _plank]));
      final session = c.read(activeSessionProvider.notifier);
      await session.applySuggestion(1, from: _plank, seconds: 35);
      expect(c.read(activeSessionProvider).value!.plan[1].seconds, 30);
      await session.logCurrent();
      await session.applySuggestion(0, from: _squat, weightG: 72500);
      expect(c.read(activeSessionProvider).value!.plan[0].weightG, 70000);
    });

    test('does nothing if only the reps, the seconds or the sets changed '
        'in the meantime', () async {
      final c = await open(_workout([_squat]));
      final session = c.read(activeSessionProvider.notifier);
      // Worked out from 3 sets of 5; the workout now says otherwise.
      await session.applySuggestion(
        0,
        from: _squat.change(reps: 6),
        weightG: 72500,
      );
      await session.applySuggestion(
        0,
        from: _squat.change(sets: 4),
        weightG: 72500,
      );
      expect(c.read(activeSessionProvider).value!.current!.weightG, 70000);

      final t = await open(_workout([_plank]));
      await t
          .read(activeSessionProvider.notifier)
          .applySuggestion(0, from: _plank.change(seconds: 25), seconds: 35);
      expect(t.read(activeSessionProvider).value!.current!.seconds, 30);
    });

    test('refuses a number the database would not take', () async {
      final c = await open(_workout([_squat]));
      final session = c.read(activeSessionProvider.notifier);
      for (final g in [0, -2500, 500001]) {
        await session.applySuggestion(0, from: _squat, weightG: g);
      }
      expect(c.read(activeSessionProvider).value!.current!.weightG, 70000);

      final p = await open(_workout([_pushUp]));
      for (final r in [0, 201]) {
        await p
            .read(activeSessionProvider.notifier)
            .applySuggestion(0, from: _pushUp, reps: r);
      }
      expect(p.read(activeSessionProvider).value!.current!.reps, 10);

      final t = await open(_workout([_plank]));
      for (final sec in [0, 3601]) {
        await t
            .read(activeSessionProvider.notifier)
            .applySuggestion(0, from: _plank, seconds: sec);
      }
      expect(t.read(activeSessionProvider).value!.current!.seconds, 30);
    });

    test('does nothing with a number of the wrong kind', () async {
      final c = await open(_workout([_plank]));
      final session = c.read(activeSessionProvider.notifier);
      await session.applySuggestion(0, from: _plank, weightG: 5000);
      await session.applySuggestion(0, from: _plank, reps: 12);
      final item = c.read(activeSessionProvider).value!.current!;
      expect(item.weightG, isNull);
      expect(item.reps, isNull);
      expect(item.seconds, 30);
    });

    test('is never sent to the server as anything but the sets done', () async {
      final c = await open(_workout([_squat]));
      final session = c.read(activeSessionProvider.notifier);
      await session.applySuggestion(0, from: _squat, weightG: 72500);
      await session.logCurrent();
      final w = c.read(activeSessionProvider).value!;
      expect(w.toSave().keys.toSet(), {
        'name',
        'program_id',
        'started_at',
        'ended_at',
        'sets',
      });
      expect(w.done.single.weightG, 72500);
    });
  });

  group('on the workout screen', () {
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

    final hit = _history([
      _session(5, [5, 5, 5], weightG: 70000),
    ]);

    testWidgets('suggests more weight, and Use takes it for this workout', (
      tester,
    ) async {
      final repo = _Repo({'squat': hit});
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      expect(
        find.text('Try 72.5 kg. You hit 5 reps on every set last time.'),
        findsOne,
      );
      expect(find.text('70 kg'), findsOne);
      await tap(tester, 'Use');
      expect(find.text('72.5 kg'), findsOne);
      expect((await repo.loadActive())!.current!.weightG, 72500);
      // Taken: the plan no longer matches last time, so nothing more is said.
      expect(find.textContaining('Try '), findsNothing);
      // The saved programs are untouched.
      expect(
        (await repo.programs())
            .expand((p) => p.days)
            .expand((d) => d.items)
            .where((i) => i.weightG == 72500),
        isEmpty,
      );
    });

    testWidgets('nothing changes without the tap', (tester) async {
      final repo = _Repo({'squat': hit});
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      await tap(tester, 'Set done');
      expect((await repo.loadActive())!.done.single.weightG, 70000);
    });

    testWidgets('says stay, with no button, after a missed set', (
      tester,
    ) async {
      final repo = _Repo({
        'squat': _history([
          _session(5, [5, 5, 4], weightG: 70000),
        ]),
      });
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      expect(
        find.text('Stay at 70 kg. You missed reps on a set last time.'),
        findsOne,
      );
      expect(find.text('Use'), findsNothing);
    });

    testWidgets('suggests reps and seconds for exercises without weight', (
      tester,
    ) async {
      final repo = _Repo({
        'push-up': _history([
          _session(3, [10, 10, 10]),
        ]),
      });
      await repo.storeActive(_workout([_pushUp]));
      await pump(tester, repo);
      expect(
        find.text('Try 11 reps. You hit 10 on every set last time.'),
        findsOne,
      );
      await tap(tester, 'Use');
      expect((await repo.loadActive())!.current!.reps, 11);
    });

    testWidgets('an under-18 sees last time, and no suggestion', (
      tester,
    ) async {
      final repo = _Repo({
        'push-up': _history([
          _session(3, [10, 10, 10]),
        ], rules: null),
      });
      await repo.storeActive(_workout([_pushUp]));
      await pump(tester, repo);
      expect(find.textContaining('Last time: 10, 10, 10 reps'), findsOne);
      expect(find.textContaining('Try '), findsNothing);
      expect(find.text('Use'), findsNothing);
    });

    testWidgets('a first time, or a history that can’t be read, has none', (
      tester,
    ) async {
      final first = _Repo(const {});
      await first.storeActive(_workout([_squat]));
      await pump(tester, first);
      expect(find.text('First time doing this.'), findsOne);
      expect(find.text('Use'), findsNothing);

      final broken = _Repo(const {}, failing: true);
      await broken.storeActive(_workout([_squat]));
      await pump(tester, broken);
      expect(find.text('Use'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });

    testWidgets('it is offered only before the first set', (tester) async {
      final repo = _Repo({'squat': hit});
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      expect(find.text('Use'), findsOne);
      await tap(tester, 'Set done');
      expect(find.text('Use'), findsNothing);
      expect(find.textContaining('Try '), findsNothing);
    });

    testWidgets('a weight taken from last time gets its suggestion too', (
      tester,
    ) async {
      final repo = _Repo({'squat': hit});
      await repo.storeActive(_workout([_squat.change(noWeight: true)]));
      await pump(tester, repo);
      expect(find.text('70 kg'), findsOne);
      expect(
        find.text('Try 72.5 kg. You hit 5 reps on every set last time.'),
        findsOne,
      );
    });

    testWidgets('the words are a suggestion: no orders, claims or rewards', (
      tester,
    ) async {
      final banned = RegExp(
        r'\bshould\b|\bmust\b|\bsafe|optimal|calor|point|badge|streak|rank|'
        r'healthy|injur|recommend',
        caseSensitive: false,
      );
      final texts = [
        suggestNext(_squat, hit)!.text,
        suggestNext(
          _squat,
          _history([
            _session(5, [5, 5, 4], weightG: 70000),
          ]),
        )!.text,
        suggestNext(
          _squat,
          _history([
            for (final d in [2, 5, 9]) _session(d, [5, 4, 4], weightG: 70000),
          ]),
        )!.text,
        suggestNext(
          _pushUp,
          _history([
            _session(3, [10, 10, 10]),
          ]),
        )!.text,
        suggestNext(
          _plank,
          _history([
            _session(3, [30, 30], seconds: true),
          ]),
        )!.text,
      ];
      expect(texts.length, 5);
      for (final t in texts) {
        expect(banned.hasMatch(t), isFalse, reason: t);
      }
      final repo = _Repo({'squat': hit});
      await repo.storeActive(_workout([_squat]));
      await pump(tester, repo);
      final all = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' | ');
      expect(banned.hasMatch(all), isFalse, reason: all);
    });

    testWidgets('fits a narrow phone with large text', (tester) async {
      final repo = _Repo({'squat': hit});
      await repo.storeActive(_workout([_squat]));
      await tester.binding.setSurfaceSize(const Size(320, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fitnessRepositoryProvider.overrideWithValue(repo)],
          retry: (_, _) => null,
          child: MaterialApp(
            theme: OgTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const TrainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Use'), findsOne);
    });
  });
}
