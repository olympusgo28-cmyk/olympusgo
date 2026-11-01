import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/fitness_models.dart';

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
    _programs
      ..removeWhere((p) => p.id == program.id)
      ..insert(0, program);
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
  Future<ActiveWorkout?> loadActive() async => _active;

  @override
  Future<void> storeActive(ActiveWorkout? workout) async => _active = workout;
}
