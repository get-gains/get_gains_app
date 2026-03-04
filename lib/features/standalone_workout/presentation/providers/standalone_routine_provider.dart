import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/routine_model.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_routine_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes — Routines List
// ──────────────────────────────────────────────────────────

sealed class StandaloneRoutinesState {
  const StandaloneRoutinesState();
}

class StandaloneRoutinesInitial extends StandaloneRoutinesState {
  const StandaloneRoutinesInitial();
}

class StandaloneRoutinesLoading extends StandaloneRoutinesState {
  const StandaloneRoutinesLoading();
}

class StandaloneRoutinesLoaded extends StandaloneRoutinesState {
  const StandaloneRoutinesLoaded({
    required this.routines,
    this.total = 0,
    this.hasMore = false,
    this.offset = 0,
    this.limit = 50,
  });

  final List<StandaloneRoutineSummaryModel> routines;
  final int total;
  final bool hasMore;
  final int offset;
  final int limit;
}

class StandaloneRoutinesError extends StandaloneRoutinesState {
  const StandaloneRoutinesError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Routines List Notifier (Offline-First)
// ──────────────────────────────────────────────────────────

@riverpod
class StandaloneRoutinesNotifier extends _$StandaloneRoutinesNotifier {
  static const _tag = 'StandaloneRoutinesNotifier';

  @override
  StandaloneRoutinesState build() => const StandaloneRoutinesInitial();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  /// Load routines offline-first: show cached → sync from server.
  Future<void> loadRoutines({int limit = 50, int offset = 0}) async {
    state = const StandaloneRoutinesLoading();

    // 1. Load from local cache first
    final localResult = await _repo.getRoutinesLocal();
    localResult.when(
      success: (routines) {
        if (routines.isNotEmpty) {
          state = StandaloneRoutinesLoaded(
            routines: routines
                .map(
                  (r) => StandaloneRoutineSummaryModel(
                    id: r.id,
                    name: r.name,
                    description: r.description,
                    estimatedDurationMinutes: r.estimatedDurationMinutes,
                    muscleGroupsTargeted: r.muscleGroupsTargeted,
                    exerciseCount: r.exercises.length,
                  ),
                )
                .toList(),
            total: routines.length,
          );
        }
      },
      failure: (_) {},
    );

    // 2. Sync from server in background
    final serverResult = await _repo.syncRoutines(limit: limit, offset: offset);

    serverResult.when(
      success: (response) {
        state = StandaloneRoutinesLoaded(
          routines: response.routines,
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        if (state is! StandaloneRoutinesLoaded) {
          state = StandaloneRoutinesError(error);
        }
        AppLogger.warning(
          'Server sync failed, using cached routines',
          tag: _tag,
          error: error,
        );
      },
    );
  }

  /// Load more routines (pagination).
  Future<void> loadMore() async {
    final current = state;
    if (current is! StandaloneRoutinesLoaded || !current.hasMore) return;

    final nextOffset = current.offset + current.limit;
    final result = await _repo.syncRoutines(
      limit: current.limit,
      offset: nextOffset,
    );

    result.when(
      success: (response) {
        state = StandaloneRoutinesLoaded(
          routines: [...current.routines, ...response.routines],
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        AppLogger.warning('Load more routines failed', tag: _tag, error: error);
      },
    );
  }

  /// Create a new routine.
  Future<bool> createRoutine(CreateStandaloneRoutineRequest request) async {
    final result = await _repo.createRoutine(request);
    return result.when(
      success: (routine) {
        final current = state;
        final summary = StandaloneRoutineSummaryModel(
          id: routine.id,
          name: routine.name,
          description: routine.description,
          estimatedDurationMinutes: routine.estimatedDurationMinutes,
          muscleGroupsTargeted: routine.muscleGroupsTargeted,
          exerciseCount: routine.exercises.length,
        );
        if (current is StandaloneRoutinesLoaded) {
          state = StandaloneRoutinesLoaded(
            routines: [summary, ...current.routines],
            total: current.total + 1,
            hasMore: current.hasMore,
            offset: current.offset,
            limit: current.limit,
          );
        }
        AppLogger.info('Routine created: ${routine.name}', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Create routine failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Delete a routine.
  Future<bool> deleteRoutine(String routineId) async {
    final result = await _repo.deleteRoutine(routineId);
    return result.when(
      success: (_) {
        final current = state;
        if (current is StandaloneRoutinesLoaded) {
          state = StandaloneRoutinesLoaded(
            routines: current.routines.where((r) => r.id != routineId).toList(),
            total: current.total - 1,
            hasMore: current.hasMore,
            offset: current.offset,
            limit: current.limit,
          );
        }
        AppLogger.info('Routine deleted: $routineId', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Delete routine failed', tag: _tag, error: error);
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// State Classes — Routine Detail
// ──────────────────────────────────────────────────────────

sealed class StandaloneRoutineDetailState {
  const StandaloneRoutineDetailState();
}

class StandaloneRoutineDetailInitial extends StandaloneRoutineDetailState {
  const StandaloneRoutineDetailInitial();
}

class StandaloneRoutineDetailLoading extends StandaloneRoutineDetailState {
  const StandaloneRoutineDetailLoading();
}

class StandaloneRoutineDetailLoaded extends StandaloneRoutineDetailState {
  const StandaloneRoutineDetailLoaded({required this.routine});
  final RoutineModel routine;
}

class StandaloneRoutineDetailError extends StandaloneRoutineDetailState {
  const StandaloneRoutineDetailError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Routine Detail Notifier
// ──────────────────────────────────────────────────────────

@riverpod
class StandaloneRoutineDetailNotifier
    extends _$StandaloneRoutineDetailNotifier {
  static const _tag = 'StandaloneRoutineDetailNotifier';

  @override
  StandaloneRoutineDetailState build(String routineId) =>
      const StandaloneRoutineDetailInitial();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  /// Load routine detail from server (with exercise list).
  Future<void> load() async {
    state = const StandaloneRoutineDetailLoading();
    final result = await _repo.getRoutineDetail(routineId);
    result.when(
      success: (routine) {
        state = StandaloneRoutineDetailLoaded(routine: routine);
      },
      failure: (error) {
        state = StandaloneRoutineDetailError(error);
        AppLogger.error('Load routine detail failed', tag: _tag, error: error);
      },
    );
  }

  /// Update routine metadata.
  Future<bool> updateRoutine(UpdateStandaloneRoutineRequest request) async {
    final result = await _repo.updateRoutine(
      routineId: routineId,
      request: request,
    );
    return result.when(
      success: (updated) {
        state = StandaloneRoutineDetailLoaded(routine: updated);
        return true;
      },
      failure: (error) {
        AppLogger.error('Update routine failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Add an exercise to this routine.
  Future<bool> addExercise(AddStandaloneRoutineExerciseRequest request) async {
    final result = await _repo.addRoutineExercise(
      routineId: routineId,
      request: request,
    );
    return result.when(
      success: (_) {
        // Reload to get updated exercise list
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error('Add exercise failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Update an exercise in this routine.
  Future<bool> updateExercise(
    String routineExerciseId,
    UpdateStandaloneRoutineExerciseRequest request,
  ) async {
    final result = await _repo.updateRoutineExercise(
      routineId: routineId,
      routineExerciseId: routineExerciseId,
      request: request,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error('Update exercise failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Remove an exercise from this routine.
  Future<bool> removeExercise(String routineExerciseId) async {
    final result = await _repo.removeRoutineExercise(
      routineId: routineId,
      routineExerciseId: routineExerciseId,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error('Remove exercise failed', tag: _tag, error: error);
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

@riverpod
bool standaloneRoutinesLoading(Ref ref) {
  final state = ref.watch(standaloneRoutinesProvider);
  return state is StandaloneRoutinesLoading;
}

@riverpod
List<StandaloneRoutineSummaryModel> standaloneRoutinesList(Ref ref) {
  final state = ref.watch(standaloneRoutinesProvider);
  if (state is StandaloneRoutinesLoaded) return state.routines;
  return [];
}

@riverpod
AppError? standaloneRoutinesError(Ref ref) {
  final state = ref.watch(standaloneRoutinesProvider);
  if (state is StandaloneRoutinesError) return state.error;
  return null;
}
