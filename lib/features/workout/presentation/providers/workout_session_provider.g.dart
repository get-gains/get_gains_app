part of 'workout_session_provider.dart';

/// Workout Session Provider
///
/// Manages active workout session state.

@ProviderFor(WorkoutSessionNotifier)
const workoutSessionProvider = WorkoutSessionNotifierProvider._();

/// Workout Session Provider
///
/// Manages active workout session state.

final class WorkoutSessionNotifierProvider
    extends $NotifierProvider<WorkoutSessionNotifier, WorkoutSessionState> {
  /// Workout Session Provider
  ///
  /// Manages active workout session state.

  const WorkoutSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutSessionNotifierHash();

  @$internal
  @override
  WorkoutSessionNotifier create() => WorkoutSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutSessionState>(value),
    );
  }
}

String _$workoutSessionNotifierHash() =>
    r'd2b675b8a67ec0293dcd3e1a219a9d64c85d73ac';

/// Workout Session Provider
///
/// Manages active workout session state.
///
/// Usage:
/// ```dart
/// // Start a session
/// await ref.read(workoutSessionProvider.notifier).startSession(routineId: 1);
///
/// // Log a set
/// await ref.read(workoutSessionProvider.notifier).logSet(
///   reps: 10,
///   weight: 60.0,
/// );
///
/// // Move to next exercise
/// ref.read(workoutSessionProvider.notifier).nextExercise();
///
/// // Complete session
/// await ref.read(workoutSessionProvider.notifier).completeSession();
/// ```

abstract class _$WorkoutSessionNotifier extends $Notifier<WorkoutSessionState> {
  WorkoutSessionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<WorkoutSessionState, WorkoutSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkoutSessionState, WorkoutSessionState>,
              WorkoutSessionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
