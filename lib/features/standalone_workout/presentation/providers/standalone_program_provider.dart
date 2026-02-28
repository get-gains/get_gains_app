import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_program_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes — Programs List
// ──────────────────────────────────────────────────────────

sealed class StandaloneProgramsState {
  const StandaloneProgramsState();
}

class StandaloneProgramsInitial extends StandaloneProgramsState {
  const StandaloneProgramsInitial();
}

class StandaloneProgramsLoading extends StandaloneProgramsState {
  const StandaloneProgramsLoading();
}

class StandaloneProgramsLoaded extends StandaloneProgramsState {
  const StandaloneProgramsLoaded({
    required this.programs,
    this.total = 0,
    this.hasMore = false,
    this.offset = 0,
    this.limit = 50,
  });

  final List<StandaloneProgramSummaryModel> programs;
  final int total;
  final bool hasMore;
  final int offset;
  final int limit;
}

class StandaloneProgramsError extends StandaloneProgramsState {
  const StandaloneProgramsError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Programs List Notifier (Offline-First)
// ──────────────────────────────────────────────────────────

@riverpod
class StandaloneProgramsNotifier extends _$StandaloneProgramsNotifier {
  static const _tag = 'StandaloneProgramsNotifier';

  @override
  StandaloneProgramsState build() => const StandaloneProgramsInitial();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  /// Load programs offline-first: show cached → sync from server.
  Future<void> loadPrograms({int limit = 50, int offset = 0}) async {
    state = const StandaloneProgramsLoading();

    // 1. Load from local cache first
    final authState = ref.read(authStateProvider);
    final userId = authState.userId;
    if (userId != null) {
      final localResult = await _repo.getProgramsLocal(userId);
      localResult.when(
        success: (programs) {
          if (programs.isNotEmpty) {
            state = StandaloneProgramsLoaded(
              programs: programs,
              total: programs.length,
            );
          }
        },
        failure: (_) {},
      );
    }

    // 2. Sync from server in background
    final serverResult = await _repo.syncPrograms(limit: limit, offset: offset);

    serverResult.when(
      success: (response) {
        state = StandaloneProgramsLoaded(
          programs: response.programs,
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        if (state is! StandaloneProgramsLoaded) {
          state = StandaloneProgramsError(error);
        }
        AppLogger.warning(
          'Server sync failed, using cached programs',
          tag: _tag,
          error: error,
        );
      },
    );
  }

  /// Load more programs (pagination).
  Future<void> loadMore() async {
    final current = state;
    if (current is! StandaloneProgramsLoaded || !current.hasMore) return;

    final nextOffset = current.offset + current.limit;
    final result = await _repo.syncPrograms(
      limit: current.limit,
      offset: nextOffset,
    );

    result.when(
      success: (response) {
        state = StandaloneProgramsLoaded(
          programs: [...current.programs, ...response.programs],
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        AppLogger.warning('Load more programs failed', tag: _tag, error: error);
      },
    );
  }

  /// Create a new program.
  Future<bool> createProgram(CreateStandaloneProgramRequest request) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.userId;
    if (userId == null) return false;

    final result = await _repo.createProgram(request, userId: userId);
    return result.when(
      success: (program) {
        final current = state;
        if (current is StandaloneProgramsLoaded) {
          state = StandaloneProgramsLoaded(
            programs: [program, ...current.programs],
            total: current.total + 1,
            hasMore: current.hasMore,
            offset: current.offset,
            limit: current.limit,
          );
        }
        AppLogger.info('Program created: ${program.name}', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Create program failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Delete a program.
  Future<bool> deleteProgram(String programId) async {
    final result = await _repo.deleteProgram(programId);
    return result.when(
      success: (_) {
        final current = state;
        if (current is StandaloneProgramsLoaded) {
          state = StandaloneProgramsLoaded(
            programs: current.programs.where((p) => p.id != programId).toList(),
            total: current.total - 1,
            hasMore: current.hasMore,
            offset: current.offset,
            limit: current.limit,
          );
        }
        AppLogger.info('Program deleted: $programId', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Delete program failed', tag: _tag, error: error);
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// State Classes — Program Detail
// ──────────────────────────────────────────────────────────

sealed class StandaloneProgramDetailState {
  const StandaloneProgramDetailState();
}

class StandaloneProgramDetailInitial extends StandaloneProgramDetailState {
  const StandaloneProgramDetailInitial();
}

class StandaloneProgramDetailLoading extends StandaloneProgramDetailState {
  const StandaloneProgramDetailLoading();
}

class StandaloneProgramDetailLoaded extends StandaloneProgramDetailState {
  const StandaloneProgramDetailLoaded({required this.program});
  final StandaloneProgramDetailModel program;
}

class StandaloneProgramDetailError extends StandaloneProgramDetailState {
  const StandaloneProgramDetailError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Program Detail Notifier
// ──────────────────────────────────────────────────────────

@riverpod
class StandaloneProgramDetailNotifier
    extends _$StandaloneProgramDetailNotifier {
  static const _tag = 'StandaloneProgramDetailNotifier';

  @override
  StandaloneProgramDetailState build(String programId) =>
      const StandaloneProgramDetailInitial();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  /// Load program detail with routine slots.
  Future<void> load() async {
    state = const StandaloneProgramDetailLoading();
    final result = await _repo.getProgramDetail(programId);
    result.when(
      success: (program) {
        state = StandaloneProgramDetailLoaded(program: program);
      },
      failure: (error) {
        state = StandaloneProgramDetailError(error);
        AppLogger.error('Load program detail failed', tag: _tag, error: error);
      },
    );
  }

  /// Update program metadata.
  Future<bool> updateProgram(UpdateStandaloneProgramRequest request) async {
    final result = await _repo.updateProgram(
      programId: programId,
      request: request,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error('Update program failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Assign a routine to a day slot.
  Future<bool> assignRoutine(AssignStandaloneRoutineRequest request) async {
    final result = await _repo.assignRoutine(
      programId: programId,
      request: request,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error('Assign routine failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Update a routine's day number in this program.
  Future<bool> updateProgramRoutine(
    String programRoutineId,
    UpdateStandaloneProgramRoutineRequest request,
  ) async {
    final result = await _repo.updateProgramRoutine(
      programId: programId,
      programRoutineId: programRoutineId,
      request: request,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update program routine failed',
          tag: _tag,
          error: error,
        );
        return false;
      },
    );
  }

  /// Remove a routine from this program.
  Future<bool> removeProgramRoutine(String programRoutineId) async {
    final result = await _repo.removeProgramRoutine(
      programId: programId,
      programRoutineId: programRoutineId,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Remove program routine failed',
          tag: _tag,
          error: error,
        );
        return false;
      },
    );
  }

  /// Activate this program (self-assignment).
  Future<bool> activateProgram({
    ActivateStandaloneProgramRequest? request,
  }) async {
    final result = await _repo.activateProgram(
      programId: programId,
      request: request,
    );
    return result.when(
      success: (_) {
        AppLogger.info('Program activated: $programId', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Activate program failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Deactivate this program.
  Future<bool> deactivateProgram() async {
    final result = await _repo.deactivateProgram(programId);
    return result.when(
      success: (_) {
        AppLogger.info('Program deactivated: $programId', tag: _tag);
        return true;
      },
      failure: (error) {
        AppLogger.error('Deactivate program failed', tag: _tag, error: error);
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Active Program Provider
// ──────────────────────────────────────────────────────────

@riverpod
Future<StandaloneAssignedProgramModel?> standaloneActiveProgram(Ref ref) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getActiveProgram();
  return result.when(
    success: (assignment) => assignment,
    failure: (error) {
      AppLogger.warning('Failed to get active program', error: error);
      return null;
    },
  );
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

@riverpod
bool standaloneProgramsLoading(Ref ref) {
  final state = ref.watch(standaloneProgramsProvider);
  return state is StandaloneProgramsLoading;
}

@riverpod
List<StandaloneProgramSummaryModel> standaloneProgramsList(Ref ref) {
  final state = ref.watch(standaloneProgramsProvider);
  if (state is StandaloneProgramsLoaded) return state.programs;
  return [];
}

@riverpod
AppError? standaloneProgramsError(Ref ref) {
  final state = ref.watch(standaloneProgramsProvider);
  if (state is StandaloneProgramsError) return state.error;
  return null;
}
