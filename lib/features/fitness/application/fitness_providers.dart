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

Duration? _noRetry(int count, Object error) => null;

// Fails straight away, so a paid plan isn't left waiting on a spinner.
@Riverpod(retry: _noRetry)
Future<List<WorkoutProgram>> workoutPrograms(Ref ref) =>
    ref.watch(fitnessRepositoryProvider).programs();

/// [days] null means all time.
@riverpod
Future<WorkoutSummary> workoutSummary(Ref ref, int? days) =>
    ref.watch(fitnessRepositoryProvider).summary(days: days);

@riverpod
Future<ExerciseHistory> exerciseHistory(Ref ref, String id) =>
    ref.watch(fitnessRepositoryProvider).history(id);

@riverpod
Future<AiStatus> aiStatus(Ref ref) =>
    ref.watch(fitnessRepositoryProvider).aiStatus();

/// A plan that was asked for and hasn't reached the player yet.
class AiPlanTicket {
  const AiPlanTicket({
    required this.key,
    required this.goal,
    required this.days,
    this.programId,
  });

  /// Stays the same on a retry, so a dropped signal can't pay twice.
  final String key;
  final String goal;
  final int days;

  /// Set once the plan is saved, so opening it never asks again.
  final String? programId;

  AiPlanTicket saved(String id) =>
      AiPlanTicket(key: key, goal: goal, days: days, programId: id);
}

/// Outlives the screen, so leaving during the wait can't lose a paid plan.
@Riverpod(keepAlive: true)
class AiPlanRequest extends _$AiPlanRequest {
  @override
  AiPlanTicket? build() {
    // Each account has its own keys.
    ref.watch(currentUserIdProvider.select((v) => v.value));
    return null;
  }

  void start(AiPlanTicket ticket) => state = ticket;

  /// A late answer only touches its own ticket, so it can't reach an account
  /// that signed in since.
  void saved(String key, String programId) {
    if (state?.key == key) state = state!.saved(programId);
  }

  void clear(String key) {
    if (state?.key == key) state = null;
  }
}

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
