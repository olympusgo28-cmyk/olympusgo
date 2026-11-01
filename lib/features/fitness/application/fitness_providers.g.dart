// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fitnessOpen)
final fitnessOpenProvider = FitnessOpenProvider._();

final class FitnessOpenProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  FitnessOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fitnessOpenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fitnessOpenHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return fitnessOpen(ref);
  }
}

String _$fitnessOpenHash() => r'e2c8a02622080a23b86e8fd739d63eb64fe32c66';

@ProviderFor(exercises)
final exercisesProvider = ExercisesProvider._();

final class ExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogExercise>>,
          List<CatalogExercise>,
          FutureOr<List<CatalogExercise>>
        >
    with
        $FutureModifier<List<CatalogExercise>>,
        $FutureProvider<List<CatalogExercise>> {
  ExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exercisesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exercisesHash();

  @$internal
  @override
  $FutureProviderElement<List<CatalogExercise>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CatalogExercise>> create(Ref ref) {
    return exercises(ref);
  }
}

String _$exercisesHash() => r'dc51c46748c0b55ccbe86ad524f976c94afc29d9';

@ProviderFor(workoutPrograms)
final workoutProgramsProvider = WorkoutProgramsProvider._();

final class WorkoutProgramsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkoutProgram>>,
          List<WorkoutProgram>,
          FutureOr<List<WorkoutProgram>>
        >
    with
        $FutureModifier<List<WorkoutProgram>>,
        $FutureProvider<List<WorkoutProgram>> {
  WorkoutProgramsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutProgramsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutProgramsHash();

  @$internal
  @override
  $FutureProviderElement<List<WorkoutProgram>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkoutProgram>> create(Ref ref) {
    return workoutPrograms(ref);
  }
}

String _$workoutProgramsHash() => r'7c6a74e64ae1af8b4ae1bff3100474ee6a6eaf37';

/// [days] null means all time.

@ProviderFor(workoutSummary)
final workoutSummaryProvider = WorkoutSummaryFamily._();

/// [days] null means all time.

final class WorkoutSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutSummary>,
          WorkoutSummary,
          FutureOr<WorkoutSummary>
        >
    with $FutureModifier<WorkoutSummary>, $FutureProvider<WorkoutSummary> {
  /// [days] null means all time.
  WorkoutSummaryProvider._({
    required WorkoutSummaryFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'workoutSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutSummaryHash();

  @override
  String toString() {
    return r'workoutSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkoutSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkoutSummary> create(Ref ref) {
    final argument = this.argument as int?;
    return workoutSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutSummaryHash() => r'27349db357ce9d3f13c0acf8f2041a354ce36e4e';

/// [days] null means all time.

final class WorkoutSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkoutSummary>, int?> {
  WorkoutSummaryFamily._()
    : super(
        retry: null,
        name: r'workoutSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [days] null means all time.

  WorkoutSummaryProvider call(int? days) =>
      WorkoutSummaryProvider._(argument: days, from: this);

  @override
  String toString() => r'workoutSummaryProvider';
}

@ProviderFor(exerciseHistory)
final exerciseHistoryProvider = ExerciseHistoryFamily._();

final class ExerciseHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExerciseHistory>,
          ExerciseHistory,
          FutureOr<ExerciseHistory>
        >
    with $FutureModifier<ExerciseHistory>, $FutureProvider<ExerciseHistory> {
  ExerciseHistoryProvider._({
    required ExerciseHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseHistoryHash();

  @override
  String toString() {
    return r'exerciseHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ExerciseHistory> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExerciseHistory> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseHistoryHash() => r'c9f2cda596e73bbf93d2bcbae7a3fe22b28c686e';

final class ExerciseHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ExerciseHistory>, String> {
  ExerciseHistoryFamily._()
    : super(
        retry: null,
        name: r'exerciseHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExerciseHistoryProvider call(String id) =>
      ExerciseHistoryProvider._(argument: id, from: this);

  @override
  String toString() => r'exerciseHistoryProvider';
}

/// The workout in progress. Every change goes to the phone's storage first,
/// one at a time, so a slow write can't lose a set.

@ProviderFor(ActiveSession)
final activeSessionProvider = ActiveSessionProvider._();

/// The workout in progress. Every change goes to the phone's storage first,
/// one at a time, so a slow write can't lose a set.
final class ActiveSessionProvider
    extends $AsyncNotifierProvider<ActiveSession, ActiveWorkout?> {
  /// The workout in progress. Every change goes to the phone's storage first,
  /// one at a time, so a slow write can't lose a set.
  ActiveSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSessionHash();

  @$internal
  @override
  ActiveSession create() => ActiveSession();
}

String _$activeSessionHash() => r'90bdd91dcbabb1cf253a0a80c1c95f929694f050';

/// The workout in progress. Every change goes to the phone's storage first,
/// one at a time, so a slow write can't lose a set.

abstract class _$ActiveSession extends $AsyncNotifier<ActiveWorkout?> {
  FutureOr<ActiveWorkout?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ActiveWorkout?>, ActiveWorkout?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ActiveWorkout?>, ActiveWorkout?>,
              AsyncValue<ActiveWorkout?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
