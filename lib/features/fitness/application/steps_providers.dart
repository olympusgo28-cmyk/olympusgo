import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../data/health_step_source.dart';
import '../data/step_source.dart';
import '../domain/steps.dart';

/// Fails straight away, so a phone that cannot answer shows its error state
/// instead of waiting on a spinner (Riverpod would retry for ever).
Duration? _noRetry(int count, Object error) => null;

/// Where steps are read from: the phone's health store, or made-up numbers in
/// demo mode. A release build always reads the phone, so a build with no keys
/// can never show invented steps as real. Tests override it.
final stepSourceProvider = Provider<StepSource>(
  (ref) => Env.hasSupabase || kReleaseMode
      ? HealthStepSource()
      : FakeStepSource.demo(),
);

/// Where the player's goal is kept.
final stepGoalStoreProvider = Provider<StepGoalStore>(
  (ref) => const SecureStepGoalStore(),
);

/// Whether steps may be read, and asking.
class StepsAccessController extends AsyncNotifier<StepsAccess> {
  @override
  Future<StepsAccess> build() => ref.watch(stepSourceProvider).access();

  /// Asks the player. Once allowed, the numbers are read afresh.
  Future<void> request() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(stepSourceProvider).request);
    ref.invalidate(stepsProvider);
  }

  /// Opens the phone's settings. A phone that cannot is left as it was.
  Future<void> openSettings() async {
    try {
      await ref.read(stepSourceProvider).openSettings();
    } catch (_) {}
  }
}

final stepsAccessProvider =
    AsyncNotifierProvider<StepsAccessController, StepsAccess>(
      StepsAccessController.new,
      retry: _noRetry,
    );

/// The player's daily goal.
class StepGoalController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final saved = await ref.watch(stepGoalStoreProvider).read();
    return saved == null ? defaultStepGoal : clampStepGoal(saved);
  }

  Future<void> set(int goal) async {
    final next = clampStepGoal(goal);
    await ref.read(stepGoalStoreProvider).write(next);
    state = AsyncData(next);
  }
}

final stepGoalProvider = AsyncNotifierProvider<StepGoalController, int>(
  StepGoalController.new,
);

/// The last 30 days of steps with the goal. Null when steps may not be read.
final stepsProvider = FutureProvider.autoDispose<StepsSummary?>(
  retry: _noRetry,
  (ref) async {
    final access = await ref.watch(stepsAccessProvider.future);
    if (access != StepsAccess.allowed) return null;
    final goal = await ref.watch(stepGoalProvider.future);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(today.year, today.month, today.day - 29);
    final days = await ref.watch(stepSourceProvider).days(from, today);
    return StepsSummary(days: days, goal: goal, asOf: now);
  },
);

/// The steps in each hour of a day, for the Day tab.
final stepHoursProvider = FutureProvider.autoDispose
    .family<List<int>, DateTime>(
      retry: _noRetry,
      (ref, day) => ref.watch(stepSourceProvider).hours(day),
    );
