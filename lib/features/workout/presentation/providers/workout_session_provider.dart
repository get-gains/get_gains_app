import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../services/outbox/outbox_service.dart';
import '../../../client_pose/data/client_pose_repository.dart';
import '../../../gains_coins/data/coins_repository.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';
import 'calendar_provider.dart';

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

    // Ensure program cache is hydrated so routine lookup finds APRE CUIDs.
    final cached = await _repository.getPrograms();
    if (cached.valueOrNull?.isEmpty ?? true) {
      await _repository.syncPrograms();
    }

    final result = await _repository.getActiveSession(_userId!);
    if (!ref.mounted) return;
    result.when(
      success: (session) async {
        if (session != null) {
          // Try APRE CUID first (matches program cache), then local int ID.
          final routineKey =
              session.assignedProgramRoutineId ?? session.routineId;
          if (routineKey != null) {
            final routineResult = await _repository.getRoutineByModelId(
              routineKey,
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
        }
      },
      failure: (_) {},
    );
  }

  /// Start a new workout session, or resume an existing active session
  /// for the same routine.
  ///
  /// When [routine] is provided it is used directly, skipping a repo lookup.
  Future<void> startSession({
    required String routineModelId,
    RoutineModel? routine,
    String? assignedProgramId,
  }) async {
    if (_userId == null) {
      state = const WorkoutSessionError(
        AuthError(message: 'User not authenticated'),
      );
      return;
    }

    state = const WorkoutSessionLoading();

    // Refresh assigned programs so cached APRE CUIDs match the server.
    // The runtime RoutineModel is hydrated from AssignedPrograms.routinesJson,
    // not the local Routines table.
    await _repository.syncPrograms();
    if (!ref.mounted) return;

    // Pre-cache reference forms for all exercises across all programs
    // so pose analysis works offline once the user starts a workout.
    _preCacheForms(ref);

    // Check for an existing active session for the same routine first.
    // This prevents creating orphan sessions when the user leaves and
    // returns to the same workout.
    final activeResult = await _repository.getActiveSession(_userId!);
    if (!ref.mounted) return;
    final activeSession = activeResult.valueOrNull;
    if (activeSession != null && activeSession.routineId == routineModelId) {
      // Resume the existing session — all logged sets are already in the
      // model's performedSets (loaded from Drift by getActiveSession).
      final resolvedRoutine =
          routine ??
          (await _repository.getRoutineByModelId(routineModelId)).valueOrNull;
      if (!ref.mounted) return;

      state = WorkoutSessionActive(
        session: activeSession,
        routine: resolvedRoutine,
        currentExerciseIndex: _calculateCurrentExerciseIndex(
          activeSession,
          resolvedRoutine,
        ),
      );
      return;
    }

    // Resolve the routine if not provided
    final resolvedRoutine =
        routine ??
        (await _repository.getRoutineByModelId(routineModelId)).valueOrNull;
    if (!ref.mounted) return;

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
          routine: resolvedRoutine,
          currentExerciseIndex: 0,
        );
      },
      failure: (error) {
        state = WorkoutSessionError(error);
      },
    );
  }

  /// Log a set for the current exercise
  Future<bool> logSet({
    required int setNumber,
    required int reps,
    double? weight,
    int? rpe,
    String? notes,
    String? routineExerciseIdOverride,
    String? recordedFramesKey,
    double? overallScore,
    String? exerciseNameSnapshot,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRestSeconds,
    double? targetWeightKg,
  }) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return false;

    final routineExerciseId =
        routineExerciseIdOverride ?? currentState.currentExercise?.id;
    if (routineExerciseId == null) return false;

    final loggedExerciseIndex = currentState.routine?.exercises.indexWhere(
      (exercise) => exercise.id == routineExerciseId,
    );
    final resolvedLoggedExerciseIndex =
        (loggedExerciseIndex != null && loggedExerciseIndex >= 0)
        ? loggedExerciseIndex
        : currentState.currentExerciseIndex;

    final result = await _repository.logSet(
      workoutSessionModelId: currentState.session.id,
      routineExerciseModelId: routineExerciseId,
      setNumber: setNumber,
      repsCompleted: reps,
      weightKg: weight,
      rpe: rpe,
      notes: notes,
      recordedFramesKey: recordedFramesKey,
      overallScore: overallScore,
      exerciseNameSnapshot: exerciseNameSnapshot,
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRestSeconds: targetRestSeconds,
      targetWeightKg: targetWeightKg,
    );

    var didLogSuccessfully = false;

    result.when(
      success: (performedSet) {
        didLogSuccessfully = true;
        // Update session with new set
        final updatedSets = [
          ...currentState.session.performedSets,
          performedSet,
        ];

        final updatedSession = currentState.session.copyWith(
          performedSets: updatedSets,
        );

        // Keep focus on the exercise that was just logged. Only advance
        // forward when that specific exercise is completed.
        var newIndex = resolvedLoggedExerciseIndex;
        final routine = currentState.routine;
        if (routine != null &&
            resolvedLoggedExerciseIndex < routine.exercises.length) {
          final loggedExercise = routine.exercises[resolvedLoggedExerciseIndex];
          final loggedSets = updatedSession.setsForExercise(loggedExercise.id);
          final isLoggedExerciseCompleted =
              loggedSets.length >= loggedExercise.sets;

          if (isLoggedExerciseCompleted) {
            final nextIncomplete = routine.exercises.indexWhere(
              (exercise) =>
                  updatedSession.setsForExercise(exercise.id).length <
                  exercise.sets,
              resolvedLoggedExerciseIndex + 1,
            );

            newIndex = nextIncomplete >= 0
                ? nextIncomplete
                : routine.exercises.length;
          }
        }

        state = currentState.copyWith(
          session: updatedSession,
          currentExerciseIndex: newIndex,
        );
      },
      failure: (error) {
        AppLogger.error(
          'logSet failed: ${error.message}',
          tag: 'WorkoutSession',
        );
      },
    );

    return didLogSuccessfully;
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
      sessionId: currentState.session.id,
      notes: notes,
    );

    if (!ref.mounted) return;

    result.when(
      success: (session) async {
        // Drain outbox so the server has all sets and the coin reward
        // is reflected when the completion screen reads the balance.
        try {
          await ref
              .read(outboxServiceProvider)
              .drain()
              .timeout(const Duration(seconds: 6));
          // Refresh coin balance after outbox drain
          ref.read(coinsRepositoryProvider).syncBalance();
        } catch (_) {
          // Best-effort — user can still see local data
        }
        if (!ref.mounted) return;
        state = WorkoutSessionCompleted(session, routine: currentState.routine);
        ref.invalidate(monthlyWorkoutDaysProvider);
      },
      failure: (error) {
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

  /// Refresh active session from local repository.
  ///
  /// Rehydrates session + all performed sets from Drift DB. Called when
  /// returning to session screen with readOnly: true, or after process
  /// recreation to restore full state from the local database.
  ///
  /// When [preferredExerciseIndex] is provided, it is used (if valid) so
  /// external flows can restore focus to the expected exercise page.
  Future<void> refreshActiveSession({int? preferredExerciseIndex}) async {
    if (_userId == null) return;

    // Ensure program cache is hydrated so routine lookup finds APRE CUIDs.
    final cached = await _repository.getPrograms();
    if (cached.valueOrNull?.isEmpty ?? true) {
      await _repository.syncPrograms();
    }

    final result = await _repository.getActiveSession(_userId!);
    if (!ref.mounted) return;

    await result.when(
      success: (session) async {
        if (session == null) {
          state = const WorkoutSessionInitial();
          return;
        }

        RoutineModel? routine;
        // Try APRE CUID first (matches program cache), then local int ID.
        final routineKey =
            session.assignedProgramRoutineId ?? session.routineId;
        if (routineKey != null) {
          final routineResult = await _repository.getRoutineByModelId(
            routineKey,
          );
          if (!ref.mounted) return;
          routine = routineResult.valueOrNull;
        }

        int? resolvedIndex;
        if (preferredExerciseIndex != null &&
            preferredExerciseIndex >= 0 &&
            routine != null &&
            preferredExerciseIndex < routine.exercises.length) {
          resolvedIndex = preferredExerciseIndex;
        }

        final currentState = state;
        if (resolvedIndex == null && currentState is WorkoutSessionActive) {
          if (routine == null ||
              currentState.currentExerciseIndex < routine.exercises.length) {
            resolvedIndex = currentState.currentExerciseIndex;
          }
        }

        resolvedIndex ??= _calculateCurrentExerciseIndex(session, routine);

        state = WorkoutSessionActive(
          session: session,
          routine: routine,
          currentExerciseIndex: resolvedIndex,
        );
      },
      failure: (_) async {},
    );
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

  /// Pre-cache reference pose forms for all exercises across the user's
  /// assigned programs so "Analyze Form" works offline during a workout.
  ///
  /// Fire-and-forget — never blocks the session start flow.
  void _preCacheForms(Ref ref) {
    final poseRepo = ref.read(clientPoseRepositoryProvider);
    _repository.getPrograms().then((result) {
      final programs = result.valueOrNull;
      if (programs == null) return;
      for (final p in programs) {
        for (final r in p.routines) {
          for (final e in r.exercises) {
            poseRepo.preCacheExerciseForms([e.exerciseId]);
          }
        }
      }
    });
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
