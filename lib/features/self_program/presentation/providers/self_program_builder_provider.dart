import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../coach_programs/data/models/program_model.dart';
import '../../../coach_programs/data/models/program_request_models.dart';
import '../../data/self_program_repository.dart';

part 'self_program_builder_provider.g.dart';

sealed class SelfProgramBuilderState {
  const SelfProgramBuilderState();
}

class SelfProgramBuilderInitial extends SelfProgramBuilderState {
  const SelfProgramBuilderInitial();
}

class SelfProgramBuilderLoading extends SelfProgramBuilderState {
  const SelfProgramBuilderLoading();
}

class SelfProgramBuilderLoaded extends SelfProgramBuilderState {
  const SelfProgramBuilderLoaded({required this.program, this.currentStep = 0});

  final ClientProgramModel program;
  final int currentStep;

  SelfProgramBuilderLoaded withStep(int step) =>
      SelfProgramBuilderLoaded(program: program, currentStep: step);

  SelfProgramBuilderLoaded withProgram(ClientProgramModel updated) =>
      SelfProgramBuilderLoaded(program: updated, currentStep: currentStep);
}

class SelfProgramBuilderError extends SelfProgramBuilderState {
  const SelfProgramBuilderError(this.error);
  final AppError error;
}

@riverpod
class SelfProgramBuilderNotifier extends _$SelfProgramBuilderNotifier {
  @override
  SelfProgramBuilderState build() => const SelfProgramBuilderInitial();

  SelfProgramRepository get _repo => ref.read(selfProgramRepositoryProvider);

  Future<bool> createProgram({
    required String name,
    String description = '',
    String? notes,
    String? startDate,
    String? endDate,
  }) async {
    state = const SelfProgramBuilderLoading();

    final result = await _repo.createSelfProgram(
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
        state = SelfProgramBuilderLoaded(program: program, currentStep: 1);
        return true;
      },
      failure: (error) {
        AppLogger.error('Create program failed: ${error.message}', tag: 'SelfProgramBuilder');
        state = SelfProgramBuilderError(error);
        return false;
      },
    );
  }

  Future<void> loadExistingProgram(String programId) async {
    state = const SelfProgramBuilderLoading();

    final result = await _repo.getProgramById(programId);

    result.when(
      success: (program) {
        state = SelfProgramBuilderLoaded(program: program, currentStep: 0);
      },
      failure: (error) {
        AppLogger.error('Load existing program failed: ${error.message}', tag: 'SelfProgramBuilder');
        state = SelfProgramBuilderError(error);
      },
    );
  }

  void goToStep(int step) {
    final current = state;
    if (current is SelfProgramBuilderLoaded) {
      state = current.withStep(step);
    }
  }

  Future<bool> updateProgram({
    String? name,
    String? description,
    String? notes,
    bool? isActive,
    String? startDate,
    String? endDate,
  }) async {
    final current = state;
    if (current is! SelfProgramBuilderLoaded) return false;

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
        AppLogger.error('Update program failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

  Future<bool> deleteProgram() async {
    final current = state;
    if (current is! SelfProgramBuilderLoaded) return false;

    final result = await _repo.deleteProgram(current.program.id);

    return result.when(
      success: (_) {
        state = const SelfProgramBuilderInitial();
        return true;
      },
      failure: (error) {
        AppLogger.error('Delete program failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

  Future<bool> addRoutineInline({
    required String name,
    String description = '',
    required int estimatedDurationMinutes,
    required List<DayOfWeek> daysOfWeek,
    required int orderInProgram,
    List<InlineExerciseRequest> exercises = const [],
  }) async {
    final current = state;
    if (current is! SelfProgramBuilderLoaded) return false;

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
        AppLogger.error('Add inline routine failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

  Future<bool> updateRoutine(
    String aprId, {
    String? name,
    String? description,
    int? estimatedDurationMinutes,
    List<DayOfWeek>? daysOfWeek,
    int? orderInProgram,
  }) async {
    final current = state;
    if (current is! SelfProgramBuilderLoaded) return false;

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
        AppLogger.error('Update routine failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

  Future<bool> deleteRoutine(String aprId) async {
    final current = state;
    if (current is! SelfProgramBuilderLoaded) return false;

    final result = await _repo.deleteProgramRoutine(current.program.id, aprId);

    return result.when(
      success: (_) {
        _refreshTree(current);
        return true;
      },
      failure: (error) {
        AppLogger.error('Delete routine failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

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
    if (current is! SelfProgramBuilderLoaded) return false;

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
        AppLogger.error('Add exercise failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

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
    if (current is! SelfProgramBuilderLoaded) return false;

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
        AppLogger.error('Update exercise failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

  Future<bool> deleteExercise(String aprId, String apreId) async {
    final current = state;
    if (current is! SelfProgramBuilderLoaded) return false;

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
        AppLogger.error('Delete exercise failed: ${error.message}', tag: 'SelfProgramBuilder');
        return false;
      },
    );
  }

  Future<void> _refreshTree(SelfProgramBuilderLoaded current) async {
    final result = await _repo.getProgramById(current.program.id);

    result.when(
      success: (program) {
        state = current.withProgram(program);
      },
      failure: (error) {
        AppLogger.error('Refresh tree failed: ${error.message}', tag: 'SelfProgramBuilder');
      },
    );
  }
}

@riverpod
String? selfProgramBuilderId(Ref ref) {
  final state = ref.watch(selfProgramBuilderProvider);
  if (state is SelfProgramBuilderLoaded) return state.program.id;
  return null;
}

@riverpod
bool selfProgramBuilderLoading(Ref ref) {
  final state = ref.watch(selfProgramBuilderProvider);
  return state is SelfProgramBuilderLoading;
}

@riverpod
int? selfProgramBuilderStep(Ref ref) {
  final state = ref.watch(selfProgramBuilderProvider);
  if (state is SelfProgramBuilderLoaded) return state.currentStep;
  return null;
}

@riverpod
ClientProgramModel? selfProgramBuilderProgram(Ref ref) {
  final state = ref.watch(selfProgramBuilderProvider);
  if (state is SelfProgramBuilderLoaded) return state.program;
  return null;
}
