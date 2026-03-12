import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../services/sync/workout_sync_service.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

part 'workout_session_provider.g.dart';

/// Workout Session State
///
/// Represents the current state of a workout session.
sealed class WorkoutSessionState {
  const WorkoutSessionState();
}

/// Initial state - no active session
class WorkoutSessionInitial extends WorkoutSessionState {
  const WorkoutSessionInitial();
}

/// Loading state
class WorkoutSessionLoading extends WorkoutSessionState {
  const WorkoutSessionLoading();
}

/// Active workout session
class WorkoutSessionActive extends WorkoutSessionState {
  const WorkoutSessionActive({
    required this.session,
    required this.routine,
    required this.currentExerciseIndex,
  });

  final WorkoutSessionModel session;
  final RoutineModel? routine;
  final int currentExerciseIndex;

  /// Current exercise being performed
  RoutineExerciseModel? get currentExercise =>
      routine != null && currentExerciseIndex < routine!.exercises.length
      ? routine!.exercises[currentExerciseIndex]
      : null;

  /// Progress through the routine (0.0 - 1.0)
  double get progress {
    if (routine == null || routine!.totalSets == 0) return 0;
    return session.completedSetsCount / routine!.totalSets;
  }

  /// Whether all exercises are completed
  bool get isAllExercisesCompleted =>
      routine != null && currentExerciseIndex >= routine!.exercises.length;

  /// Copy with new values
  WorkoutSessionActive copyWith({
    WorkoutSessionModel? session,
    RoutineModel? routine,
    int? currentExerciseIndex,
  }) {
    return WorkoutSessionActive(
      session: session ?? this.session,
      routine: routine ?? this.routine,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
    );
  }
}

/// Session completed
class WorkoutSessionCompleted extends WorkoutSessionState {
  const WorkoutSessionCompleted(this.session, {this.routine});
  final WorkoutSessionModel session;
  final RoutineModel? routine;
}

/// Error state
class WorkoutSessionError extends WorkoutSessionState {
  const WorkoutSessionError(this.error);
  final AppError error;
}

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
@Riverpod(keepAlive: true)
class WorkoutSessionNotifier extends _$WorkoutSessionNotifier {
  late WorkoutRepository _repository;
  late String? _userId;

  @override
  WorkoutSessionState build() {
    _repository = ref.watch(workoutRepositoryProvider);
    _userId = ref.watch(authStateProvider).userId;

    // Check for active session on initialization
    _checkActiveSession();

    return const WorkoutSessionInitial();
  }

  /// Check if there's an active session
  Future<void> _checkActiveSession() async {
    if (_userId == null) return;

    final result = await _repository.getActiveSession(_userId!);
    if (!ref.mounted) return;
    result.when(
      success: (session) async {
        if (session != null && session.routineId != null) {
          final routineResult = await _repository.getRoutineByModelId(
            session.routineId!,
          );
          if (!ref.mounted) return;
          routineResult.when(
            success: (routine) {
              state = WorkoutSessionActive(
                session: session,
                routine: routine,
                currentExerciseIndex: _calculateCurrentExerciseIndex(
                  session,
                  routine,
                ),
              );
            },
            failure: (_) {
              state = WorkoutSessionActive(
                session: session,
                routine: null,
                currentExerciseIndex: 0,
              );
            },
          );
        }
      },
      failure: (_) {},
    );
  }

  /// Start a new workout session
  Future<void> startSession({
    required String routineModelId,
    String? assignedProgramId,
  }) async {
    if (_userId == null) {
      state = const WorkoutSessionError(
        AuthError(message: 'User not authenticated'),
      );
      return;
    }

    state = const WorkoutSessionLoading();

    // Get routine first
    final routineResult = await _repository.getRoutineByModelId(routineModelId);
    if (!ref.mounted) return;
    final routine = routineResult.valueOrNull;

    // Start session
    final result = await _repository.startWorkoutSession(
      userId: _userId!,
      routineModelId: routineModelId,
      assignedProgramId: assignedProgramId,
    );

    if (!ref.mounted) return;

    result.when(
      success: (session) {
        state = WorkoutSessionActive(
          session: session,
          routine: routine,
          currentExerciseIndex: 0,
        );
      },
      failure: (error) {
        state = WorkoutSessionError(error);
      },
    );
  }

  /// Log a set for the current exercise
  Future<void> logSet({
    required int setNumber,
    required int reps,
    double? weight,
    int? rpe,
    String? notes,
    String? routineExerciseIdOverride,
  }) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final routineExerciseId =
        routineExerciseIdOverride ?? currentState.currentExercise?.id;
    if (routineExerciseId == null) return;

    final result = await _repository.logSet(
      workoutSessionModelId: currentState.session.id,
      routineExerciseModelId: routineExerciseId,
      setNumber: setNumber,
      repsCompleted: reps,
      weightKg: weight,
      rpe: rpe,
      notes: notes,
    );

    result.when(
      success: (performedSet) {
        // Update session with new set
        final updatedSets = [
          ...currentState.session.performedSets,
          performedSet,
        ];

        final updatedSession = currentState.session.copyWith(
          performedSets: updatedSets,
        );

        // Auto-advance to next exercise if current one is now complete
        final newIndex = _calculateCurrentExerciseIndex(
          updatedSession,
          currentState.routine,
        );

        state = currentState.copyWith(
          session: updatedSession,
          currentExerciseIndex: newIndex,
        );
      },
      failure: (_) {},
    );
  }

  /// Move to the next exercise
  void nextExercise() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    state = currentState.copyWith(
      currentExerciseIndex: currentState.currentExerciseIndex + 1,
    );
  }

  /// Move to the previous exercise
  void previousExercise() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;
    if (currentState.currentExerciseIndex <= 0) return;

    state = currentState.copyWith(
      currentExerciseIndex: currentState.currentExerciseIndex - 1,
    );
  }

  /// Go to a specific exercise
  void goToExercise(int index) {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;
    if (currentState.routine == null) return;
    if (index < 0 || index >= currentState.routine!.exercises.length) return;

    state = currentState.copyWith(currentExerciseIndex: index);
  }

  /// Complete the workout session
  Future<void> completeSession({String? notes}) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    state = const WorkoutSessionLoading();

    final result = await _repository.completeWorkoutSession(
      sessionId: int.parse(currentState.session.id),
      notes: notes,
    );

    if (!ref.mounted) return;

    result.when(
      success: (session) {
        state = WorkoutSessionCompleted(session, routine: currentState.routine);
        // Trigger sync so the server has the session for history
        ref.read(workoutSyncServiceProvider).syncAll();
      },
      failure: (error) {
        // Restore previous state on error
        state = currentState;
      },
    );
  }

  /// Cancel the workout session
  Future<void> cancelSession() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    // For now, just reset state
    // In a real app, you might want to save as draft or delete
    state = const WorkoutSessionInitial();
  }

  /// Reset to initial state
  void reset() {
    state = const WorkoutSessionInitial();
  }

  /// Calculate current exercise index based on completed sets
  int _calculateCurrentExerciseIndex(
    WorkoutSessionModel session,
    RoutineModel? routine,
  ) {
    if (routine == null || routine.exercises.isEmpty) return 0;

    for (int i = 0; i < routine.exercises.length; i++) {
      final exercise = routine.exercises[i];
      final completedSets = session.setsForExercise(exercise.id);
      if (completedSets.length < exercise.sets) {
        return i;
      }
    }

    // All exercises completed
    return routine.exercises.length;
  }
}

/// Provider that fetches today's completed session for a routine from local DB.
///
/// Returns a [WorkoutSessionModel] with all performed sets if the user
/// completed a workout for the given routine today, otherwise null.
@riverpod
Future<WorkoutSessionModel?> todayCompletedSession(
  Ref ref,
  String routineId,
) async {
  final userId = ref.watch(authStateProvider).userId;
  if (userId == null) return null;

  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getTodayCompletedSession(
    userId: userId,
    routineModelId: routineId,
  );
  return result.valueOrNull;
}
