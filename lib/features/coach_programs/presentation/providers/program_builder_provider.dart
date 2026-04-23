import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_program_repository.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_request_models.dart';

part 'program_builder_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────

/// Sealed state for the program builder wizard.
sealed class ProgramBuilderState {
  const ProgramBuilderState();
}

/// No program loaded yet.
class ProgramBuilderInitial extends ProgramBuilderState {
  const ProgramBuilderInitial();
}

/// Fetching or mutating.
class ProgramBuilderLoading extends ProgramBuilderState {
  const ProgramBuilderLoading();
}

/// A program is loaded and ready for editing.
class ProgramBuilderLoaded extends ProgramBuilderState {
  const ProgramBuilderLoaded({required this.program, this.currentStep = 0});

  /// The full program tree (routines + exercises).
  final ClientProgramModel program;

  /// Current wizard step index (0-based):
  /// 0 = Meta, 1 = Routines, 2 = Exercises, 3 = Review & Activate.
  final int currentStep;

  /// Copy with a different step.
  ProgramBuilderLoaded withStep(int step) =>
      ProgramBuilderLoaded(program: program, currentStep: step);

  /// Copy with a refreshed program tree.
  ProgramBuilderLoaded withProgram(ClientProgramModel updated) =>
      ProgramBuilderLoaded(program: updated, currentStep: currentStep);
}

/// An error occurred during a builder operation.
class ProgramBuilderError extends ProgramBuilderState {
  const ProgramBuilderError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────

/// Manages the in-flight program for a specific client.
///
/// Family provider keyed by `clientId`. Each wizard instance owns one
/// program; all mutations hit the server immediately, then re-fetch the
/// full tree to keep state consistent.
@riverpod
class ProgramBuilderNotifier extends _$ProgramBuilderNotifier {
  @override
  ProgramBuilderState build(String clientId) => const ProgramBuilderInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  // ── Lifecycle ──────────────────────────────────────────

  /// Create a brand-new program for this client (wizard Step 1).
  ///
  /// On success, transitions to [ProgramBuilderLoaded] at step 1.
  Future<bool> createProgram({
    required String name,
    String description = '',
    String? notes,
    String? startDate,
    String? endDate,
  }) async {
    state = const ProgramBuilderLoading();

    final result = await _repo.createClientProgram(
      clientId,
      CreateClientProgramRequest(
        name: name,
        description: description,
        notes: notes,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    return result.when(
      success: (program) {
        state = ProgramBuilderLoaded(program: program, currentStep: 1);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Create program failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        state = ProgramBuilderError(error);
        return false;
      },
    );
  }

  /// Load an existing program into the builder (edit mode).
  ///
  /// Enters at step 1 (routines) so the coach can start editing immediately.
  Future<void> loadExistingProgram(String programId) async {
    state = const ProgramBuilderLoading();

    final result = await _repo.getProgramById(programId);

    result.when(
      success: (program) {
        state = ProgramBuilderLoaded(program: program, currentStep: 1);
      },
      failure: (error) {
        AppLogger.error(
          'Load existing program failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        state = ProgramBuilderError(error);
      },
    );
  }

  /// Navigate to a specific wizard step.
  void goToStep(int step) {
    final current = state;
    if (current is ProgramBuilderLoaded) {
      state = current.withStep(step);
    }
  }

  // ── Program Meta ───────────────────────────────────────

  /// Update program-level fields (name, description, notes, active, dates).
  ///
  /// Used by Step 1 edits and Step 4 "Activate".
  Future<bool> updateProgram({
    String? name,
    String? description,
    String? notes,
    bool? isActive,
    String? startDate,
    String? endDate,
  }) async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.updateProgram(
      current.program.id,
      UpdateClientProgramRequest(
        name: name,
        description: description,
        notes: notes,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    return result.when(
      success: (program) {
        state = current.withProgram(program);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update program failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  /// Soft-delete the current program.
  Future<bool> deleteProgram() async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.deleteProgram(current.program.id);

    return result.when(
      success: (_) {
        state = const ProgramBuilderInitial();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete program failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  // ── Routines ───────────────────────────────────────────

  /// Add a routine from the template library.
  Future<bool> addRoutineFromTemplate({
    required String sourceRoutineId,
    required List<DayOfWeek> daysOfWeek,
    required int orderInProgram,
  }) async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.addProgramRoutineFromTemplate(
      current.program.id,
      AddProgramRoutineTemplateRequest(
        sourceRoutineId: sourceRoutineId,
        daysOfWeek: daysOfWeek,
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
          'Add template routine failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  /// Add a brand-new inline routine to the program.
  Future<bool> addRoutineInline({
    required String name,
    String description = '',
    required int estimatedDurationMinutes,
    required List<DayOfWeek> daysOfWeek,
    required int orderInProgram,
    List<InlineExerciseRequest> exercises = const [],
  }) async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.addProgramRoutineInline(
      current.program.id,
      AddProgramRoutineInlineRequest(
        name: name,
        description: description,
        estimatedDurationMinutes: estimatedDurationMinutes,
        daysOfWeek: daysOfWeek,
        orderInProgram: orderInProgram,
        exercises: exercises,
      ),
    );

    return result.when(
      success: (program) {
        state = current.withProgram(program);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Add inline routine failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  /// Update an existing routine's metadata / schedule.
  Future<bool> updateRoutine(
    String aprId, {
    String? name,
    String? description,
    int? estimatedDurationMinutes,
    List<DayOfWeek>? daysOfWeek,
    int? orderInProgram,
  }) async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.updateProgramRoutine(
      current.program.id,
      aprId,
      UpdateProgramRoutineRequest(
        name: name,
        description: description,
        estimatedDurationMinutes: estimatedDurationMinutes,
        daysOfWeek: daysOfWeek,
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
          'Update routine failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  /// Delete a routine from the program.
  Future<bool> deleteRoutine(String aprId) async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.deleteProgramRoutine(current.program.id, aprId);

    return result.when(
      success: (_) {
        // Re-fetch full tree since delete doesn't return updated program
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete routine failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  // ── Exercises ──────────────────────────────────────────

  /// Add an exercise to a program routine.
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
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.addProgramRoutineExercise(
      current.program.id,
      aprId,
      AddProgramRoutineExerciseRequest(
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
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  /// Update an exercise's prescription within a program routine.
  Future<bool> updateExercise(
    String aprId,
    String apreId, {
    String? exerciseId,
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    int? orderInRoutine,
  }) async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.updateProgramRoutineExercise(
      current.program.id,
      aprId,
      apreId,
      UpdateProgramRoutineExerciseRequest(
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
          'Update exercise failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  /// Delete an exercise from a program routine.
  Future<bool> deleteExercise(String aprId, String apreId) async {
    final current = state;
    if (current is! ProgramBuilderLoaded) return false;

    final result = await _repo.deleteProgramRoutineExercise(
      current.program.id,
      aprId,
      apreId,
    );

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete exercise failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        return false;
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────

  /// Re-fetch the full program tree to refresh state after a mutation
  /// that doesn't return the updated tree.
  Future<void> _refreshTree(ProgramBuilderLoaded current) async {
    final result = await _repo.getProgramById(current.program.id);

    result.when(
      success: (program) {
        state = current.withProgram(program);
      },
      failure: (error) {
        AppLogger.error(
          'Refresh tree failed: ${error.message}',
          tag: 'ProgramBuilder',
        );
        // Keep existing state rather than clobbering with an error
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Selectors
// ──────────────────────────────────────────────────────────

/// The program ID from the builder, or `null` if not loaded.
@riverpod
String? programBuilderId(Ref ref, String clientId) {
  final state = ref.watch(programBuilderProvider(clientId));
  if (state is ProgramBuilderLoaded) return state.program.id;
  return null;
}

/// Whether the builder is in a loading state.
@riverpod
bool programBuilderLoading(Ref ref, String clientId) {
  final state = ref.watch(programBuilderProvider(clientId));
  return state is ProgramBuilderLoading;
}

/// The current wizard step, or `null` if not loaded.
@riverpod
int? programBuilderStep(Ref ref, String clientId) {
  final state = ref.watch(programBuilderProvider(clientId));
  if (state is ProgramBuilderLoaded) return state.currentStep;
  return null;
}

/// The full program model, or `null` if not loaded.
@riverpod
ClientProgramModel? programBuilderProgram(Ref ref, String clientId) {
  final state = ref.watch(programBuilderProvider(clientId));
  if (state is ProgramBuilderLoaded) return state.program;
  return null;
}
