import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_program_builder_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────

/// Sealed state for the standalone program builder wizard.
sealed class StandaloneProgramBuilderState {
  const StandaloneProgramBuilderState();
}

/// No program loaded yet.
class StandaloneProgramBuilderInitial extends StandaloneProgramBuilderState {
  const StandaloneProgramBuilderInitial();
}

/// Fetching or mutating.
class StandaloneProgramBuilderLoading extends StandaloneProgramBuilderState {
  const StandaloneProgramBuilderLoading();
}

/// A program is loaded and ready for editing.
class StandaloneProgramBuilderLoaded extends StandaloneProgramBuilderState {
  const StandaloneProgramBuilderLoaded({
    required this.program,
    this.currentStep = 0,
  });

  final StandaloneProgramDetail program;
  final int currentStep;

  StandaloneProgramBuilderLoaded withStep(int step) =>
      StandaloneProgramBuilderLoaded(program: program, currentStep: step);

  StandaloneProgramBuilderLoaded withProgram(StandaloneProgramDetail updated) =>
      StandaloneProgramBuilderLoaded(program: updated, currentStep: currentStep);
}

/// An error occurred during a builder operation.
class StandaloneProgramBuilderError extends StandaloneProgramBuilderState {
  const StandaloneProgramBuilderError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────

@riverpod
class StandaloneProgramBuilderNotifier
    extends _$StandaloneProgramBuilderNotifier {
  @override
  StandaloneProgramBuilderState build() =>
      const StandaloneProgramBuilderInitial();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  // ── Lifecycle ──────────────────────────────────────────

  Future<bool> createProgram({
    required String name,
    String description = '',
  }) async {
    state = const StandaloneProgramBuilderLoading();

    final result = await _repo.createProgram(
      CreateStandaloneProgramRequest(name: name, description: description),
    );

    return result.when(
      success: (program) async {
        // Re-fetch full detail to get the program tree
        final detailResult = await _repo.getProgram(program.id);
        detailResult.when(
          success: (detail) {
            state = StandaloneProgramBuilderLoaded(
                program: detail, currentStep: 1);
          },
          failure: (error) {
            state = StandaloneProgramBuilderError(error);
          },
        );
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Create standalone program failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        state = StandaloneProgramBuilderError(error);
        return false;
      },
    );
  }

  Future<void> loadExistingProgram(String programId) async {
    state = const StandaloneProgramBuilderLoading();

    final result = await _repo.getProgram(programId);

    result.when(
      success: (program) {
        state =
            StandaloneProgramBuilderLoaded(program: program, currentStep: 1);
      },
      failure: (error) {
        AppLogger.error(
          'Load standalone program failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        state = StandaloneProgramBuilderError(error);
      },
    );
  }

  void goToStep(int step) {
    final current = state;
    if (current is StandaloneProgramBuilderLoaded) {
      state = current.withStep(step);
    }
  }

  // ── Program Meta ───────────────────────────────────────

  Future<bool> updateProgram({
    String? name,
    String? description,
  }) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.updateProgram(
      current.program.id,
      UpdateStandaloneProgramRequest(
        name: name,
        description: description,
      ),
    );

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update standalone program failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  Future<bool> deleteProgram() async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.deleteProgram(current.program.id);

    return result.when(
      success: (_) {
        state = const StandaloneProgramBuilderInitial();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete standalone program failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  // ── Routines ───────────────────────────────────────────

  Future<bool> addRoutine({
    required String routineId,
    required int orderInProgram,
  }) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.addProgramRoutine(
      current.program.id,
      AddProgramRoutineRequest(
        routineId: routineId,
        orderInProgram: orderInProgram,
      ),
    );

    return result.when(
      success: (program) {
        state = current.withProgram(program);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Add routine failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  Future<bool> updateRoutine(
    String aprId, {
    required int orderInProgram,
  }) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.updateProgramRoutine(
      current.program.id,
      aprId,
      UpdateProgramRoutineRequest(orderInProgram: orderInProgram),
    );

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update routine failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  Future<bool> deleteRoutine(String aprId) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.deleteProgramRoutine(current.program.id, aprId);

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete routine failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  // ── Exercises ──────────────────────────────────────────

  Future<bool> addExercise(
    String aprId, {
    required String exerciseId,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
  }) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.addRoutineExercise(
      aprId,
      AddRoutineExerciseRequest(
        exerciseId: exerciseId,
        sets: sets,
        repsMin: repsMin,
        repsMax: repsMax,
        restSeconds: restSeconds,
        orderInRoutine: orderInRoutine,
      ),
    );

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Add exercise failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  Future<bool> updateExercise(
    String aprId,
    String apreId, {
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    int? orderInRoutine,
  }) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.updateRoutineExercise(
      aprId,
      apreId,
      UpdateRoutineExerciseRequest(
        sets: sets,
        repsMin: repsMin,
        repsMax: repsMax,
        restSeconds: restSeconds,
        orderInRoutine: orderInRoutine,
      ),
    );

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update exercise failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  Future<bool> deleteExercise(String aprId, String apreId) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final result = await _repo.deleteRoutineExercise(aprId, apreId);

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete exercise failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────

  Future<bool> createAndAddRoutine({
    required String name,
    required String description,
    required int orderInProgram,
  }) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final createResult = await _repo.createRoutine(
      name: name,
      description: description,
    );

    return createResult.when(
      success: (routineId) async {
        final addResult = await _repo.addProgramRoutine(
          current.program.id,
          AddProgramRoutineRequest(
            routineId: routineId,
            orderInProgram: orderInProgram,
          ),
        );
        return addResult.when(
          success: (program) {
            state = current.withProgram(program);
            return true;
          },
          failure: (error) {
            AppLogger.error(
              'Add routine after create failed: ${error.message}',
              tag: 'StandaloneProgramBuilder',
            );
            return false;
          },
        );
      },
      failure: (error) {
        AppLogger.error(
          'Create routine failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  Future<bool> createAndAddExercise({
    required String routineId,
    required String name,
    required String description,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
  }) async {
    final current = state;
    if (current is! StandaloneProgramBuilderLoaded) return false;

    final createExerciseResult = await _repo.createExercise(
      name: name,
      description: description,
    );

    return createExerciseResult.when(
      success: (exerciseId) async {
        final addResult = await _repo.addRoutineExercise(
          routineId,
          AddRoutineExerciseRequest(
            exerciseId: exerciseId,
            sets: sets,
            repsMin: repsMin,
            repsMax: repsMax,
            restSeconds: restSeconds,
            orderInRoutine: orderInRoutine,
          ),
        );
        return addResult.when(
          success: (_) {
            _refreshTree(current);
            return true;
          },
          failure: (error) {
            AppLogger.error(
              'Add exercise after create failed: ${error.message}',
              tag: 'StandaloneProgramBuilder',
            );
            return false;
          },
        );
      },
      failure: (error) {
        AppLogger.error(
          'Create exercise failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
        return false;
      },
    );
  }

  Future<void> _refreshTree(StandaloneProgramBuilderLoaded current) async {
    final result = await _repo.getProgram(current.program.id);

    result.when(
      success: (program) {
        state = current.withProgram(program);
      },
      failure: (error) {
        AppLogger.error(
          'Refresh tree failed: ${error.message}',
          tag: 'StandaloneProgramBuilder',
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Selectors
// ──────────────────────────────────────────────────────────

@riverpod
String? standaloneProgramBuilderId(Ref ref) {
  final state = ref.watch(standaloneProgramBuilderProvider);
  if (state is StandaloneProgramBuilderLoaded) return state.program.id;
  return null;
}

@riverpod
bool standaloneProgramBuilderLoading(Ref ref) {
  final state = ref.watch(standaloneProgramBuilderProvider);
  return state is StandaloneProgramBuilderLoading;
}

@riverpod
int? standaloneProgramBuilderStep(Ref ref) {
  final state = ref.watch(standaloneProgramBuilderProvider);
  if (state is StandaloneProgramBuilderLoaded) return state.currentStep;
  return null;
}

@riverpod
StandaloneProgramDetail? standaloneProgramBuilderProgram(Ref ref) {
  final state = ref.watch(standaloneProgramBuilderProvider);
  if (state is StandaloneProgramBuilderLoaded) return state.program;
  return null;
}
