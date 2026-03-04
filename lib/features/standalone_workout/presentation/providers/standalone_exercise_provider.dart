import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_exercise_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

sealed class StandaloneExercisesState {
  const StandaloneExercisesState();
}

class StandaloneExercisesInitial extends StandaloneExercisesState {
  const StandaloneExercisesInitial();
}

class StandaloneExercisesLoading extends StandaloneExercisesState {
  const StandaloneExercisesLoading();
}

class StandaloneExercisesLoaded extends StandaloneExercisesState {
  const StandaloneExercisesLoaded({
    required this.exercises,
    this.total = 0,
    this.hasMore = false,
    this.offset = 0,
    this.limit = 50,
  });

  final List<StandaloneExerciseModel> exercises;
  final int total;
  final bool hasMore;
  final int offset;
  final int limit;
}

class StandaloneExercisesError extends StandaloneExercisesState {
  const StandaloneExercisesError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Exercises List Notifier (Offline-First)
// ──────────────────────────────────────────────────────────

@riverpod
class StandaloneExercisesNotifier extends _$StandaloneExercisesNotifier {
  static const _tag = 'StandaloneExercisesNotifier';

  @override
  StandaloneExercisesState build() => const StandaloneExercisesInitial();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  /// Load exercises offline-first: show cached → sync from server.
  Future<void> loadExercises({
    MuscleGroup? muscleGroup,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    state = const StandaloneExercisesLoading();

    // 1. Load from local cache first
    final localResult = await _repo.getExercisesLocal();
    localResult.when(
      success: (exercises) {
        if (exercises.isNotEmpty) {
          state = StandaloneExercisesLoaded(
            exercises: exercises,
            total: exercises.length,
          );
        }
      },
      failure: (_) {},
    );

    // 2. Sync from server in background
    final serverResult = await _repo.syncExercises(
      muscleGroup: muscleGroup,
      search: search,
      limit: limit,
      offset: offset,
    );

    serverResult.when(
      success: (response) {
        state = StandaloneExercisesLoaded(
          exercises: response.exercises,
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        // Only show error if we have no cached data
        if (state is! StandaloneExercisesLoaded) {
          state = StandaloneExercisesError(error);
        }
        AppLogger.warning(
          'Server sync failed, using cached data',
          tag: _tag,
          error: error,
        );
      },
    );
  }

  /// Load more exercises (pagination).
  Future<void> loadMore() async {
    final current = state;
    if (current is! StandaloneExercisesLoaded || !current.hasMore) return;

    final nextOffset = current.offset + current.limit;
    final result = await _repo.syncExercises(
      limit: current.limit,
      offset: nextOffset,
    );

    result.when(
      success: (response) {
        state = StandaloneExercisesLoaded(
          exercises: [...current.exercises, ...response.exercises],
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        AppLogger.warning('Load more failed', tag: _tag, error: error);
      },
    );
  }

  /// Create a new personal exercise.
  Future<bool> createExercise(CreateStandaloneExerciseRequest request) async {
    final result = await _repo.createExercise(request);
    return result.when(
      success: (exercise) {
        final current = state;
        if (current is StandaloneExercisesLoaded) {
          state = StandaloneExercisesLoaded(
            exercises: [exercise, ...current.exercises],
            total: current.total + 1,
            hasMore: current.hasMore,
            offset: current.offset,
            limit: current.limit,
          );
        }
        AppLogger.info('Exercise created: ${exercise.name}', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Create exercise failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Update an existing exercise.
  Future<bool> updateExercise(
    String exerciseId,
    UpdateStandaloneExerciseRequest request,
  ) async {
    final result = await _repo.updateExercise(
      exerciseId: exerciseId,
      request: request,
    );
    return result.when(
      success: (updated) {
        final current = state;
        if (current is StandaloneExercisesLoaded) {
          final updatedList = current.exercises.map((e) {
            return e.id == exerciseId ? updated : e;
          }).toList();
          state = StandaloneExercisesLoaded(
            exercises: updatedList,
            total: current.total,
            hasMore: current.hasMore,
            offset: current.offset,
            limit: current.limit,
          );
        }
        AppLogger.info('Exercise updated: ${updated.name}', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Update exercise failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Delete an exercise.
  Future<bool> deleteExercise(String exerciseId) async {
    final result = await _repo.deleteExercise(exerciseId);
    return result.when(
      success: (_) {
        final current = state;
        if (current is StandaloneExercisesLoaded) {
          state = StandaloneExercisesLoaded(
            exercises: current.exercises
                .where((e) => e.id != exerciseId)
                .toList(),
            total: current.total - 1,
            hasMore: current.hasMore,
            offset: current.offset,
            limit: current.limit,
          );
        }
        AppLogger.info('Exercise deleted: $exerciseId', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Delete exercise failed', tag: _tag, error: error);
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

@riverpod
bool standaloneExercisesLoading(Ref ref) {
  final state = ref.watch(standaloneExercisesProvider);
  return state is StandaloneExercisesLoading;
}

@riverpod
List<StandaloneExerciseModel> standaloneExercisesList(Ref ref) {
  final state = ref.watch(standaloneExercisesProvider);
  if (state is StandaloneExercisesLoaded) return state.exercises;
  return [];
}

@riverpod
AppError? standaloneExercisesError(Ref ref) {
  final state = ref.watch(standaloneExercisesProvider);
  if (state is StandaloneExercisesError) return state.error;
  return null;
}
