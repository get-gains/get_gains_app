import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_program_repository.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_request_models.dart';

part 'coach_program_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for coach programs list.
sealed class CoachProgramsState {
  const CoachProgramsState();
}

class CoachProgramsInitial extends CoachProgramsState {
  const CoachProgramsInitial();
}

class CoachProgramsLoading extends CoachProgramsState {
  const CoachProgramsLoading();
}

class CoachProgramsLoaded extends CoachProgramsState {
  const CoachProgramsLoaded({required this.programs, required this.pagination});

  final List<ProgramSummaryModel> programs;
  final PaginationMeta pagination;
}

class CoachProgramsError extends CoachProgramsState {
  const CoachProgramsError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Programs List Notifier
// ──────────────────────────────────────────────────────────

/// Manages the list of coach programs with pagination.
@riverpod
class CoachProgramsNotifier extends _$CoachProgramsNotifier {
  @override
  CoachProgramsState build() => const CoachProgramsInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load programs (replaces current list).
  Future<void> loadPrograms({int limit = 50, int offset = 0}) async {
    state = const CoachProgramsLoading();

    final result = await _repo.getPrograms(limit: limit, offset: offset);

    result.when(
      success: (data) {
        state = CoachProgramsLoaded(
          programs: data.programs,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load programs failed: ${error.message}',
          tag: 'CoachProgramsNotifier',
        );
        state = CoachProgramsError(error);
      },
    );
  }

  /// Load next page (appends to current list).
  Future<void> loadMore() async {
    final current = state;
    if (current is! CoachProgramsLoaded || !current.pagination.hasMore) return;

    final nextOffset = current.pagination.offset + current.pagination.limit;

    final result = await _repo.getPrograms(
      limit: current.pagination.limit,
      offset: nextOffset,
    );

    result.when(
      success: (data) {
        state = CoachProgramsLoaded(
          programs: [...current.programs, ...data.programs],
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load more programs failed: ${error.message}',
          tag: 'CoachProgramsNotifier',
        );
        // Keep existing data on pagination failure
      },
    );
  }

  /// Create a new program and prepend it to the list.
  Future<bool> createProgram(CreateProgramRequest request) async {
    final result = await _repo.createProgram(request);

    return result.when(
      success: (program) {
        final current = state;
        if (current is CoachProgramsLoaded) {
          state = CoachProgramsLoaded(
            programs: [program, ...current.programs],
            pagination: current.pagination.copyWith(
              total: current.pagination.total + 1,
            ),
          );
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Create program failed: ${error.message}',
          tag: 'CoachProgramsNotifier',
        );
        return false;
      },
    );
  }

  /// Update an existing program in the list.
  Future<bool> updateProgram(
    String programId,
    UpdateProgramRequest request,
  ) async {
    final result = await _repo.updateProgram(programId, request);

    return result.when(
      success: (updated) {
        final current = state;
        if (current is CoachProgramsLoaded) {
          state = CoachProgramsLoaded(
            programs: current.programs.map((p) {
              if (p.id == programId) {
                return p.copyWith(
                  name: updated.name,
                  description: updated.description,
                  updatedAt: updated.updatedAt,
                );
              }
              return p;
            }).toList(),
            pagination: current.pagination,
          );
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update program failed: ${error.message}',
          tag: 'CoachProgramsNotifier',
        );
        return false;
      },
    );
  }

  /// Delete a program and remove it from the list.
  Future<bool> deleteProgram(String programId) async {
    final result = await _repo.deleteProgram(programId);

    return result.when(
      success: (_) {
        final current = state;
        if (current is CoachProgramsLoaded) {
          state = CoachProgramsLoaded(
            programs: current.programs.where((p) => p.id != programId).toList(),
            pagination: current.pagination.copyWith(
              total: current.pagination.total - 1,
            ),
          );
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete program failed: ${error.message}',
          tag: 'CoachProgramsNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Program Detail Notifier
// ──────────────────────────────────────────────────────────

/// Sealed state for a single program detail.
sealed class ProgramDetailState {
  const ProgramDetailState();
}

class ProgramDetailInitial extends ProgramDetailState {
  const ProgramDetailInitial();
}

class ProgramDetailLoading extends ProgramDetailState {
  const ProgramDetailLoading();
}

class ProgramDetailLoaded extends ProgramDetailState {
  const ProgramDetailLoaded(this.program);
  final ProgramDetailModel program;
}

class ProgramDetailError extends ProgramDetailState {
  const ProgramDetailError(this.error);
  final AppError error;
}

/// Manages a single program's detail view with full routine / exercise tree.
///
/// Family provider — one instance per program ID.
@riverpod
class ProgramDetailNotifier extends _$ProgramDetailNotifier {
  @override
  ProgramDetailState build(String programId) => const ProgramDetailInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load full program detail.
  Future<void> load() async {
    state = const ProgramDetailLoading();

    final result = await _repo.getProgramById(programId);

    result.when(
      success: (program) => state = ProgramDetailLoaded(program),
      failure: (error) {
        AppLogger.error(
          'Load program detail failed: ${error.message}',
          tag: 'ProgramDetailNotifier',
        );
        state = ProgramDetailError(error);
      },
    );
  }

  /// Assign a routine to a day-slot then refresh.
  Future<bool> assignRoutine(AssignRoutineRequest request) async {
    final result = await _repo.assignRoutineToProgram(programId, request);

    return result.when(
      success: (_) {
        load(); // refresh full tree
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Assign routine failed: ${error.message}',
          tag: 'ProgramDetailNotifier',
        );
        return false;
      },
    );
  }

  /// Update a routine's day-slot then refresh.
  Future<bool> updateProgramRoutine(
    String programRoutineId,
    UpdateProgramRoutineRequest request,
  ) async {
    final result = await _repo.updateProgramRoutine(
      programId,
      programRoutineId,
      request,
    );

    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update program routine failed: ${error.message}',
          tag: 'ProgramDetailNotifier',
        );
        return false;
      },
    );
  }

  /// Remove a routine from a day-slot then refresh.
  Future<bool> removeProgramRoutine(String programRoutineId) async {
    final result = await _repo.removeProgramRoutine(
      programId,
      programRoutineId,
    );

    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Remove program routine failed: ${error.message}',
          tag: 'ProgramDetailNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Whether the programs list is currently loading.
@riverpod
bool coachProgramsLoading(Ref ref) {
  final state = ref.watch(coachProgramsProvider);
  return state is CoachProgramsLoading;
}

/// The list of programs, or empty if not loaded.
@riverpod
List<ProgramSummaryModel> coachProgramsList(Ref ref) {
  final state = ref.watch(coachProgramsProvider);
  if (state is CoachProgramsLoaded) return state.programs;
  return [];
}

/// Pagination meta, or null if not loaded.
@riverpod
PaginationMeta? coachProgramsPagination(Ref ref) {
  final state = ref.watch(coachProgramsProvider);
  if (state is CoachProgramsLoaded) return state.pagination;
  return null;
}

/// Error from programs list, or null if no error.
@riverpod
AppError? coachProgramsError(Ref ref) {
  final state = ref.watch(coachProgramsProvider);
  if (state is CoachProgramsError) return state.error;
  return null;
}
