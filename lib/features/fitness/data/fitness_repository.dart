import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/fitness_models.dart';

/// The server turned a plan down, so trying the same key again won't help.
class AiPlanRefused extends AuthFailure {
  const AiPlanRefused(super.message);
}

abstract class FitnessRepository {
  /// Whether Fitness has been switched on.
  Future<bool> open();
  Future<List<CatalogExercise>> exercises();
  Future<List<WorkoutProgram>> programs();
  Future<void> saveProgram(WorkoutProgram program);
  Future<void> deleteProgram(String id);
  Future<void> saveWorkout(ActiveWorkout workout);
  Future<void> deleteWorkout(String id);

  /// [days] null means all time.
  Future<WorkoutSummary> summary({int? days = 30});
  Future<ExerciseHistory> history(String exerciseId);

  Future<AiStatus> aiStatus();

  /// Records or withdraws the player's agreement to AI plans.
  Future<void> setAiConsent(bool agreed);

  /// Asks for a plan and gives the new program's id. [key] stays the same on a
  /// retry, so a dropped signal can't pay for a second plan.
  Future<String> askPlan({
    required String key,
    required String goal,
    required int days,
  });

  /// The workout in progress, kept on the phone so a dropped signal or a
  /// closed app loses nothing.
  Future<ActiveWorkout?> loadActive();
  Future<void> storeActive(ActiveWorkout? workout);
}

class SupabaseFitnessRepository implements FitnessRepository {
  SupabaseFitnessRepository(this._client, [FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final SupabaseClient _client;
  final FlutterSecureStorage _storage;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Fitness error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on FunctionException catch (e) {
      final detail = e.details;
      // Only a real refusal is final. A gateway error, a rate limit, a 503, or
      // a 409 while the first try runs may still end in a plan, so the key
      // stays.
      if (e.status == 409 ||
          e.status == 429 ||
          e.status == 503 ||
          detail is! Map ||
          detail['error'] is! String) {
        throw AuthFailure(
          detail is Map && detail['error'] is String
              ? detail['error'] as String
              : 'Can’t reach OlympusGO. Check your connection and try again.',
        );
      }
      throw AiPlanRefused(detail['error'] as String);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Fitness network error: ${e.runtimeType}');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  String? get _activeKey {
    final user = _client.auth.currentUser?.id;
    return user == null ? null : 'fitness.active.$user';
  }

  @override
  Future<bool> open() => _guard(() async {
    final r = await _client
        .from('feature_flags')
        .select('enabled')
        .eq('key', 'fitness.enabled')
        .maybeSingle();
    return r?['enabled'] as bool? ?? false;
  });

  @override
  Future<List<CatalogExercise>> exercises() => _guard(() async {
    final r = await _client.rpc('exercise_list') as List;
    return [
      for (final e in r) CatalogExercise.fromJson(e as Map<String, dynamic>),
    ];
  });

  @override
  Future<List<WorkoutProgram>> programs() => _guard(() async {
    final r = await _client.rpc('program_list') as List;
    return [
      for (final p in r) WorkoutProgram.fromJson(p as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> saveProgram(WorkoutProgram program) => _guard(() async {
    await _client.rpc('program_save', params: {'p_program': program.toJson()});
  });

  @override
  Future<void> deleteProgram(String id) => _guard(() async {
    await _client.rpc('program_delete', params: {'p_program': id});
  });

  @override
  Future<void> saveWorkout(ActiveWorkout workout) => _guard(() async {
    // A dead signal can hang. The key makes it safe to try again.
    await _client
        .rpc(
          'workout_save',
          params: {'p_client_key': workout.key, 'p_workout': workout.toSave()},
        )
        .timeout(const Duration(seconds: 20));
  });

  @override
  Future<void> deleteWorkout(String id) => _guard(() async {
    await _client.rpc('workout_delete', params: {'p_workout': id});
  });

  @override
  Future<WorkoutSummary> summary({int? days = 30}) => _guard(() async {
    final r = await _client.rpc('workout_summary', params: {'p_days': days});
    return WorkoutSummary.fromJson(r as Map<String, dynamic>);
  });

  @override
  Future<ExerciseHistory> history(String exerciseId) => _guard(() async {
    final r = await _client.rpc(
      'exercise_history',
      params: {'p_exercise': exerciseId},
    );
    return ExerciseHistory.fromJson(r as Map<String, dynamic>);
  });

  @override
  Future<AiStatus> aiStatus() => _guard(() async {
    final r = await _client.rpc('ai_plan_status');
    return AiStatus.fromJson(r as Map<String, dynamic>);
  });

  @override
  Future<void> setAiConsent(bool agreed) => _guard(() async {
    if (agreed) {
      await _client.rpc(
        'consent_set',
        params: {'p_kind': 'ai_plans', 'p_granted': true},
      );
    } else {
      await _client.rpc('ai_plan_withdraw');
    }
  });

  @override
  Future<String> askPlan({
    required String key,
    required String goal,
    required int days,
  }) => _guard(() async {
    // Longer than the function's own deadline. The key makes a retry safe.
    final res = await _client.functions
        .invoke(
          'ai-plan',
          body: {'client_key': key, 'goal': goal, 'days': days},
        )
        .timeout(const Duration(seconds: 140));
    return (res.data as Map)['program_id'] as String;
  });

  @override
  Future<ActiveWorkout?> loadActive() async {
    final key = _activeKey;
    if (key == null) return null;
    try {
      final text = await _storage.read(key: key);
      if (text == null) return null;
      return ActiveWorkout.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Fitness storage error: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<void> storeActive(ActiveWorkout? workout) async {
    final key = _activeKey;
    if (key == null) return;
    try {
      if (workout == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: jsonEncode(workout.toJson()));
      }
    } catch (e) {
      debugPrint('Fitness storage error: ${e.runtimeType}');
    }
  }
}

/// A small catalogue held in memory, for builds with no backend.
class DemoFitnessRepository implements FitnessRepository {
  static const _catalogue = [
    CatalogExercise(
      id: 'squat',
      name: 'Back squat',
      mark: 'SQ',
      group: 'legs',
      equipment: 'Barbell',
      muscles: ['Quads', 'Glutes', 'Core'],
      steps: [
        'Bar on your upper back, feet shoulder-width apart',
        'Sit back and down until thighs are level with the floor',
        'Keep your chest up and knees over your toes',
        'Drive up through your heels',
      ],
      tip:
          'Good for badminton: stronger lunges and a quicker push back to '
          'base.',
      safety: 'Stop if you feel pain in your knees or lower back.',
      weighted: true,
    ),
    CatalogExercise(
      id: 'lunge',
      name: 'Walking lunge',
      mark: 'LU',
      group: 'legs',
      equipment: 'Dumbbells',
      muscles: ['Quads', 'Glutes'],
      steps: ['Hold a dumbbell in each hand', 'Step forward and lower'],
      safety: 'Stop if you feel pain.',
      weighted: true,
    ),
    CatalogExercise(
      id: 'plank',
      name: 'Plank',
      mark: 'PL',
      group: 'core',
      equipment: 'Bodyweight',
      muscles: ['Core'],
      steps: ['Forearms on the floor', 'Straight line from head to heels'],
      safety: 'Stop if you feel pain.',
      timed: true,
    ),
    CatalogExercise(
      id: 'push-up',
      name: 'Push-up',
      mark: 'PU',
      group: 'upper',
      equipment: 'Bodyweight',
      muscles: ['Chest', 'Shoulders', 'Triceps'],
      steps: ['Hands under your shoulders', 'Lower and press back up'],
      safety: 'Stop if you feel pain.',
    ),
  ];

  final _programs = <WorkoutProgram>[
    const WorkoutProgram(
      id: 'court-speed',
      name: 'Court speed',
      template: true,
      days: [
        ProgramDay(
          name: 'Legs and core',
          items: [
            ProgramItem(
              exerciseId: 'plank',
              exercise: 'Plank',
              mark: 'PL',
              sets: 3,
              timed: true,
              seconds: 45,
            ),
            ProgramItem(
              exerciseId: 'push-up',
              exercise: 'Push-up',
              mark: 'PU',
              sets: 3,
              reps: 10,
            ),
          ],
        ),
      ],
    ),
  ];
  final _log = <WorkoutEntry>[];
  ActiveWorkout? _active;
  var _agreed = false;
  var _plans = 0;

  @override
  Future<bool> open() async => true;

  @override
  Future<List<CatalogExercise>> exercises() async => _catalogue;

  @override
  Future<List<WorkoutProgram>> programs() async => [
    ..._programs.where((p) => !p.template),
    ..._programs.where((p) => p.template),
  ];

  @override
  Future<void> saveProgram(WorkoutProgram program) async {
    final old = _programs.where((p) => p.id == program.id).firstOrNull;
    _programs
      ..removeWhere((p) => p.id == program.id)
      ..insert(
        0,
        WorkoutProgram(
          id: program.id,
          name: program.name,
          days: program.days,
          source: old?.source ?? program.source,
        ),
      );
  }

  @override
  Future<void> deleteProgram(String id) async =>
      _programs.removeWhere((p) => p.id == id && !p.template);

  @override
  Future<void> saveWorkout(ActiveWorkout workout) async {
    if (_log.any((w) => w.id == workout.key)) return;
    final ended = workout.endedAt ?? DateTime.now();
    _log.insert(
      0,
      WorkoutEntry(
        id: workout.key,
        name: workout.name,
        startedAt: workout.startedAt,
        seconds: ended.difference(workout.startedAt).inSeconds,
        exercises: workout.done.map((s) => s.exerciseId).toSet().length,
        liftedG: workout.done.fold(
          0,
          (sum, s) => sum + (s.weightG ?? 0) * (s.reps ?? 0),
        ),
      ),
    );
  }

  @override
  Future<void> deleteWorkout(String id) async =>
      _log.removeWhere((w) => w.id == id);

  @override
  Future<WorkoutSummary> summary({int? days = 30}) async {
    final from = days == null
        ? null
        : DateTime.now().subtract(Duration(days: days));
    final shown = [
      for (final w in _log)
        if (from == null || w.startedAt.isAfter(from)) w,
    ];
    return WorkoutSummary(
      minor: false,
      workouts: shown.length,
      seconds: shown.fold(0, (s, w) => s + w.seconds),
      liftedG: shown.fold(0, (s, w) => s + w.liftedG),
      workouts30d: _log.length,
      weekStreak: _log.isEmpty ? 0 : 1,
      liftedWeekG: _log.fold(0, (s, w) => s + w.liftedG),
      recent: shown,
    );
  }

  @override
  Future<ExerciseHistory> history(String exerciseId) async =>
      const ExerciseHistory();

  @override
  Future<AiStatus> aiStatus() async =>
      AiStatus(open: true, agreed: _agreed, left: (3 - _plans).clamp(0, 3));

  @override
  Future<void> setAiConsent(bool agreed) async => _agreed = agreed;

  @override
  Future<String> askPlan({
    required String key,
    required String goal,
    required int days,
  }) async {
    final id = 'ai-$key';
    if (_programs.any((p) => p.id == id)) return id;
    _plans++;
    await saveProgram(
      WorkoutProgram(
        id: id,
        name: 'My AI plan',
        source: 'ai',
        days: [
          for (var d = 1; d <= days; d++)
            ProgramDay(name: 'Day $d', items: _programs.last.days.first.items),
        ],
      ),
    );
    return id;
  }

  @override
  Future<ActiveWorkout?> loadActive() async => _active;

  @override
  Future<void> storeActive(ActiveWorkout? workout) async => _active = workout;
}
