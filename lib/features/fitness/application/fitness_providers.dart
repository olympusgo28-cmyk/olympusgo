import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/fitness_models.dart';

part 'fitness_providers.g.dart';

@riverpod
Future<bool> fitnessOpen(Ref ref) =>
    ref.watch(fitnessRepositoryProvider).open();

@riverpod
Future<List<CatalogExercise>> exercises(Ref ref) =>
    ref.watch(fitnessRepositoryProvider).exercises();

@riverpod
Future<List<WorkoutProgram>> workoutPrograms(Ref ref) =>
    ref.watch(fitnessRepositoryProvider).programs();

/// [days] null means all time.
@riverpod
Future<WorkoutSummary> workoutSummary(Ref ref, int? days) =>
    ref.watch(fitnessRepositoryProvider).summary(days: days);

@riverpod
Future<ExerciseHistory> exerciseHistory(Ref ref, String id) =>
    ref.watch(fitnessRepositoryProvider).history(id);

/// A random id, made on the phone, so a retry reaches the same row.
String newFitnessId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// The workout in progress. Every change goes to the phone's storage first,
/// one at a time, so a slow write can't lose a set.
@Riverpod(keepAlive: true)
class ActiveSession extends _$ActiveSession {
  Future<void> _tail = Future.value();

  @override
  Future<ActiveWorkout?> build() async {
    // Rebuilt on a new sign-in, so one account never sees another's workout.
    // Only the id, so a failed token refresh with no signal can't break this.
    ref.watch(currentUserIdProvider.select((v) => v.value));
    return ref.watch(fitnessRepositoryProvider).loadActive();
  }

  Future<T> _inOrder<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _set(ActiveWorkout? w) async {
    await ref.read(fitnessRepositoryProvider).storeActive(w);
    state = AsyncData(w);
  }

  /// False, and nothing changes, if a workout is already under way.
  Future<bool> start({
    required String name,
    required List<ProgramItem> plan,
    String? programId,
  }) => _inOrder(() async {
    if (await future != null) return false;
    await _set(
      ActiveWorkout(
        key: newFitnessId(),
        name: name,
        startedAt: DateTime.now(),
        programId: programId,
        plan: plan,
      ),
    );
    return true;
  });

  Future<void> log(LoggedSet set) => _inOrder(() async {
    final w = await future;
    if (w == null || w.complete || w.finished) return;
    await _set(w.logged(set, DateTime.now()));
  });

  /// Changes the exercise at [index], if the workout is still on it.
  Future<void> adjust(int index, ProgramItem changed) => _inOrder(() async {
    final w = await future;
    if (w == null || w.complete || w.finished || w.item != index) return;
    await _set(w.adjusted(changed));
  });

  /// Marks the workout finished, then saves it. If saving fails the workout
  /// stays on the phone, and finishing again sends it with the same key.
  Future<void> finish() => _inOrder(() async {
    final w = await future;
    if (w == null) return;
    final ended = w.finished ? w : w.ended(DateTime.now());
    await _set(ended);
    await ref.read(fitnessRepositoryProvider).saveWorkout(ended);
    // Another account may have signed in while that was saving.
    if ((await future)?.key == ended.key) await _set(null);
    ref.invalidate(workoutSummaryProvider);
  });

  Future<void> discard() => _inOrder(() async {
    await future;
    await _set(null);
  });
}
