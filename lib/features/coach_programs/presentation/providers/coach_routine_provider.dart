import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/routine_model.dart';
import '../../data/coach_program_repository.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_request_models.dart';

part 'coach_routine_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for coach routines list.
sealed class CoachRoutinesState {
  const CoachRoutinesState();
}

class CoachRoutinesInitial extends CoachRoutinesState {
  const CoachRoutinesInitial();
}

class CoachRoutinesLoading extends CoachRoutinesState {
  const CoachRoutinesLoading();
}

class CoachRoutinesLoaded extends CoachRoutinesState {
  const CoachRoutinesLoaded({required this.routines, required this.pagination});

  final List<RoutineSummaryModel> routines;
  final PaginationMeta pagination;
}

class CoachRoutinesError extends CoachRoutinesState {
  const CoachRoutinesError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Routines List Notifier
// ──────────────────────────────────────────────────────────

/// Manages the list of coach routines with pagination.
@riverpod
class CoachRoutinesNotifier extends _$CoachRoutinesNotifier {
  @override
  CoachRoutinesState build() => const CoachRoutinesInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load routines (replaces current list).
  Future<void> loadRoutines({int limit = 50, int offset = 0}) async {
    state = const CoachRoutinesLoading();

    final result = await _repo.getRoutines(limit: limit, offset: offset);

    result.when(
      success: (data) {
        state = CoachRoutinesLoaded(
          routines: data.routines,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load routines failed: ${error.message}',
          tag: 'CoachRoutinesNotifier',
        );
        state = CoachRoutinesError(error);
      },
    );
  }

  /// Load next page (appends to current list).
  Future<void> loadMore() async {
    final current = state;
    if (current is! CoachRoutinesLoaded || !current.pagination.hasMore) return;

    final nextOffset = current.pagination.offset + current.pagination.limit;

    final result = await _repo.getRoutines(
      limit: current.pagination.limit,
      offset: nextOffset,
    );

    result.when(
      success: (data) {
        state = CoachRoutinesLoaded(
          routines: [...current.routines, ...data.routines],
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load more routines failed: ${error.message}',
          tag: 'CoachRoutinesNotifier',
        );
      },
    );
  }

  /// Create a new routine and prepend it to the list.
  Future<bool> createRoutine(CreateRoutineRequest request) async {
    final result = await _repo.createRoutine(request);

    return result.when(
      success: (routine) {
        // Reload the full list to get computed counts
        loadRoutines();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Create routine failed: ${error.message}',
          tag: 'CoachRoutinesNotifier',
        );
        return false;
      },
    );
  }

  /// Update an existing routine in the list.
  Future<bool> updateRoutine(
    String routineId,
    UpdateRoutineRequest request,
  ) async {
    final result = await _repo.updateRoutine(routineId, request);

    return result.when(
      success: (_) {
        loadRoutines();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update routine failed: ${error.message}',
          tag: 'CoachRoutinesNotifier',
        );
        return false;
      },
    );
  }

  /// Delete a routine and remove it from the list.
  Future<bool> deleteRoutine(String routineId) async {
    final result = await _repo.deleteRoutine(routineId);

    return result.when(
      success: (_) {
        final current = state;
        if (current is CoachRoutinesLoaded) {
          state = CoachRoutinesLoaded(
            routines: current.routines.where((r) => r.id != routineId).toList(),
            pagination: current.pagination.copyWith(
              total: current.pagination.total - 1,
            ),
          );
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete routine failed: ${error.message}',
          tag: 'CoachRoutinesNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Routine Detail Notifier
// ──────────────────────────────────────────────────────────

/// Sealed state for a single routine detail.
sealed class RoutineDetailState {
  const RoutineDetailState();
}

class RoutineDetailInitial extends RoutineDetailState {
  const RoutineDetailInitial();
}

class RoutineDetailLoading extends RoutineDetailState {
  const RoutineDetailLoading();
}

class RoutineDetailLoaded extends RoutineDetailState {
  const RoutineDetailLoaded(this.routine);
  final RoutineModel routine;
}

class RoutineDetailError extends RoutineDetailState {
  const RoutineDetailError(this.error);
  final AppError error;
}

/// Manages a single routine's detail with full exercise list.
///
/// Family provider — one instance per routine ID.
@riverpod
class RoutineDetailNotifier extends _$RoutineDetailNotifier {
  @override
  RoutineDetailState build(String routineId) => const RoutineDetailInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load full routine detail.
  Future<void> load() async {
    state = const RoutineDetailLoading();

    final result = await _repo.getRoutineById(routineId);

    result.when(
      success: (routine) => state = RoutineDetailLoaded(routine),
      failure: (error) {
        AppLogger.error(
          'Load routine detail failed: ${error.message}',
          tag: 'RoutineDetailNotifier',
        );
        state = RoutineDetailError(error);
      },
    );
  }

  /// Add an exercise from the global library to this routine, then refresh.
  Future<bool> addExercise(AddRoutineExerciseRequest request) async {
    final result = await _repo.addExerciseToRoutine(routineId, request);

    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Add exercise failed: ${error.message}',
          tag: 'RoutineDetailNotifier',
        );
        return false;
      },
    );
  }

  /// Update the prescription for an exercise in this routine, then refresh.
  Future<bool> updateExercise(
    String routineExerciseId,
    UpdateRoutineExerciseRequest request,
  ) async {
    final result = await _repo.updateRoutineExercise(
      routineId,
      routineExerciseId,
      request,
    );

    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update exercise failed: ${error.message}',
          tag: 'RoutineDetailNotifier',
        );
        return false;
      },
    );
  }

  /// Remove an exercise from this routine, then refresh.
  Future<bool> removeExercise(String routineExerciseId) async {
    final result = await _repo.removeRoutineExercise(
      routineId,
      routineExerciseId,
    );

    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Remove exercise failed: ${error.message}',
          tag: 'RoutineDetailNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Whether the routines list is currently loading.
@riverpod
bool coachRoutinesLoading(Ref ref) {
  final state = ref.watch(coachRoutinesProvider);
  return state is CoachRoutinesLoading;
}

/// The list of routines, or empty if not loaded.
@riverpod
List<RoutineSummaryModel> coachRoutinesList(Ref ref) {
  final state = ref.watch(coachRoutinesProvider);
  if (state is CoachRoutinesLoaded) return state.routines;
  return [];
}

/// Pagination meta for routines, or null if not loaded.
@riverpod
PaginationMeta? coachRoutinesPagination(Ref ref) {
  final state = ref.watch(coachRoutinesProvider);
  if (state is CoachRoutinesLoaded) return state.pagination;
  return null;
}

/// Error from routines list, or null if no error.
@riverpod
AppError? coachRoutinesError(Ref ref) {
  final state = ref.watch(coachRoutinesProvider);
  if (state is CoachRoutinesError) return state.error;
  return null;
}
