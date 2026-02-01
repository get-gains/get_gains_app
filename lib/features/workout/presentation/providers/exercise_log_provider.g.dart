part of 'exercise_log_provider.dart';

/// Manages set logging for a specific exercise.
/// Creates editable set entries and syncs with workout session.
///

@ProviderFor(ExerciseLogNotifier)
const exerciseLogProvider = ExerciseLogNotifierProvider._();

/// Exercise Log Provider
///
/// Manages set logging for a specific exercise.
/// Creates editable set entries and syncs with workout session.
///
/// Usage:
/// ```dart
/// // Initialize for an exercise
/// ref.read(exerciseLogProvider.notifier).initializeForExercise(routineExercise);
///
/// // Update current set
/// ref.read(exerciseLogProvider.notifier).updateCurrentSet(
///   reps: 10,
///   weight: 60.0,
/// );
///
/// // Complete current set
/// await ref.read(exerciseLogProvider.notifier).completeCurrentSet();
/// ```
final class ExerciseLogNotifierProvider
    extends $NotifierProvider<ExerciseLogNotifier, ExerciseLogState?> {
  /// Exercise Log Provider
  ///
  /// Manages set logging for a specific exercise.
  /// Creates editable set entries and syncs with workout session.
  ///
  /// Usage:
  /// ```dart
  /// // Initialize for an exercise
  /// ref.read(exerciseLogProvider.notifier).initializeForExercise(routineExercise);
  ///
  /// // Update current set
  /// ref.read(exerciseLogProvider.notifier).updateCurrentSet(
  ///   reps: 10,
  ///   weight: 60.0,
  /// );
  ///
  /// // Complete current set
  /// await ref.read(exerciseLogProvider.notifier).completeCurrentSet();
  /// ```
  const ExerciseLogNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseLogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseLogNotifierHash();

  @$internal
  @override
  ExerciseLogNotifier create() => ExerciseLogNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseLogState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseLogState?>(value),
    );
  }
}

String _$exerciseLogNotifierHash() =>
    r'b6b1d37aec063e4054ee6bc6400abc5a32e6442d';

/// Exercise Log Provider
///
/// Manages set logging for a specific exercise.
/// Creates editable set entries and syncs with workout session.
///
/// Usage:
/// ```dart
/// // Initialize for an exercise
/// ref.read(exerciseLogProvider.notifier).initializeForExercise(routineExercise);
///
/// // Update current set
/// ref.read(exerciseLogProvider.notifier).updateCurrentSet(
///   reps: 10,
///   weight: 60.0,
/// );
///
/// // Complete current set
/// await ref.read(exerciseLogProvider.notifier).completeCurrentSet();
/// ```

abstract class _$ExerciseLogNotifier extends $Notifier<ExerciseLogState?> {
  ExerciseLogState? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ExerciseLogState?, ExerciseLogState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExerciseLogState?, ExerciseLogState?>,
              ExerciseLogState?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
