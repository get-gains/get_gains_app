import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../workout/data/models/exercise_model.dart';
import '../../workout/data/models/routine_model.dart';
import 'models/coach_client_model.dart';
import 'models/program_model.dart';
import 'models/program_request_models.dart';

part 'coach_program_repository.g.dart';

/// Repository for all coach program operations.
///
/// Covers:
/// - Programs (CRUD)
/// - Routines (CRUD)
/// - ProgramRoutine junctions (assign, update day, remove)
/// - RoutineExercise junctions (add, update prescription, remove)
/// - Assignments (assign to client, list, update, delete)
class CoachProgramRepository {
  CoachProgramRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ──────────────────────────────────────────────────
  // Programs
  // ──────────────────────────────────────────────────

  /// List all programs belonging to the authenticated coach.
  Future<
    Result<
      ({List<ProgramSummaryModel> programs, PaginationMeta pagination}),
      AppError
    >
  >
  getPrograms({int limit = 50, int offset = 0}) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/coach/programs',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        final programs = (data['programs'] as List<dynamic>)
            .map((e) => ProgramSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = PaginationMeta.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
        return Success((programs: programs, pagination: pagination));
      },
      failure: (error) {
        AppLogger.error('Failed to fetch programs', tag: 'CoachProgramRepo');
        return Failure(error);
      },
    );
  }

  /// Get a single program with its full routine / exercise tree.
  Future<Result<ProgramDetailModel, AppError>> getProgramById(
    String programId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/coach/programs/$programId',
    );

    return result.when(
      success: (data) {
        final program = ProgramDetailModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch program $programId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Create a new training program.
  Future<Result<ProgramSummaryModel, AppError>> createProgram(
    CreateProgramRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/coach/programs',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ProgramSummaryModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error('Failed to create program', tag: 'CoachProgramRepo');
        return Failure(error);
      },
    );
  }

  /// Update an existing program's name and/or description.
  Future<Result<ProgramSummaryModel, AppError>> updateProgram(
    String programId,
    UpdateProgramRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/coach/programs/$programId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ProgramSummaryModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update program $programId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Delete a program. Cascades to ProgramRoutine records, NOT to Routines.
  Future<Result<void, AppError>> deleteProgram(String programId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/coach/programs/$programId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to delete program $programId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Routines
  // ──────────────────────────────────────────────────

  /// List all routines owned by the authenticated coach.
  Future<
    Result<
      ({List<RoutineSummaryModel> routines, PaginationMeta pagination}),
      AppError
    >
  >
  getRoutines({int limit = 50, int offset = 0}) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/coach/routines',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        final routines = (data['routines'] as List<dynamic>)
            .map((e) => RoutineSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = PaginationMeta.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
        return Success((routines: routines, pagination: pagination));
      },
      failure: (error) {
        AppLogger.error('Failed to fetch routines', tag: 'CoachProgramRepo');
        return Failure(error);
      },
    );
  }

  /// Get a single routine with its full exercise list.
  Future<Result<RoutineModel, AppError>> getRoutineById(
    String routineId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/coach/routines/$routineId',
    );

    return result.when(
      success: (data) {
        final routine = RoutineModel.fromJson(
          data['routine'] as Map<String, dynamic>,
        );
        return Success(routine);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch routine $routineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Create a new reusable routine.
  Future<Result<RoutineModel, AppError>> createRoutine(
    CreateRoutineRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/coach/routines',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final routine = RoutineModel.fromJson(
          data['routine'] as Map<String, dynamic>,
        );
        return Success(routine);
      },
      failure: (error) {
        AppLogger.error('Failed to create routine', tag: 'CoachProgramRepo');
        return Failure(error);
      },
    );
  }

  /// Update a routine's fields.
  Future<Result<RoutineModel, AppError>> updateRoutine(
    String routineId,
    UpdateRoutineRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/coach/routines/$routineId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final routine = RoutineModel.fromJson(
          data['routine'] as Map<String, dynamic>,
        );
        return Success(routine);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update routine $routineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Delete a routine. Cascades to RoutineExercise and ProgramRoutine, NOT Exercises.
  Future<Result<void, AppError>> deleteRoutine(String routineId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/coach/routines/$routineId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to delete routine $routineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // ProgramRoutine Junctions
  // ──────────────────────────────────────────────────

  /// Assign an existing routine to a program day-slot.
  Future<Result<ProgramRoutineModel, AppError>> assignRoutineToProgram(
    String programId,
    AssignRoutineRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/coach/programs/$programId/routines',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final assignment = ProgramRoutineModel.fromJson(
          data['assignment'] as Map<String, dynamic>,
        );
        return Success(assignment);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to assign routine to program $programId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Reassign a routine to a different day number within a program.
  Future<Result<ProgramRoutineModel, AppError>> updateProgramRoutine(
    String programId,
    String programRoutineId,
    UpdateProgramRoutineRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/coach/programs/$programId/routines/$programRoutineId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final programRoutine = ProgramRoutineModel.fromJson(
          data['programRoutine'] as Map<String, dynamic>,
        );
        return Success(programRoutine);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update program routine $programRoutineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Remove a routine from a program day-slot. Does NOT delete the Routine.
  Future<Result<void, AppError>> removeProgramRoutine(
    String programId,
    String programRoutineId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/coach/programs/$programId/routines/$programRoutineId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to remove program routine $programRoutineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // RoutineExercise Junctions
  // ──────────────────────────────────────────────────

  /// Add an exercise from the global library to a routine.
  Future<Result<RoutineExerciseModel, AppError>> addExerciseToRoutine(
    String routineId,
    AddRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/coach/programs/routines/$routineId/exercises',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final routineExercise = RoutineExerciseModel.fromJson(
          data['routineExercise'] as Map<String, dynamic>,
        );
        return Success(routineExercise);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to add exercise to routine $routineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Update the prescription (sets/reps/rest/order/notes) for an exercise in a routine.
  Future<Result<RoutineExerciseModel, AppError>> updateRoutineExercise(
    String routineId,
    String routineExerciseId,
    UpdateRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/coach/programs/routines/$routineId/exercises/$routineExerciseId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final routineExercise = RoutineExerciseModel.fromJson(
          data['routineExercise'] as Map<String, dynamic>,
        );
        return Success(routineExercise);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update routine exercise $routineExerciseId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Remove an exercise from a routine. Does NOT delete the Exercise.
  Future<Result<void, AppError>> removeRoutineExercise(
    String routineId,
    String routineExerciseId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/coach/programs/routines/$routineId/exercises/$routineExerciseId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to remove routine exercise $routineExerciseId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Program Assignments
  // ──────────────────────────────────────────────────

  /// Assign a program to a client.
  Future<Result<AssignedProgramModel, AppError>> assignProgram(
    AssignProgramRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/coach/assign-program',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final assignment = AssignedProgramModel.fromJson(
          data['assignment'] as Map<String, dynamic>,
        );
        return Success(assignment);
      },
      failure: (error) {
        AppLogger.error('Failed to assign program', tag: 'CoachProgramRepo');
        return Failure(error);
      },
    );
  }

  /// List all program assignments for a specific client.
  Future<Result<List<AssignedProgramModel>, AppError>> getClientPrograms(
    String userId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/coach/clients/$userId/programs',
    );

    return result.when(
      success: (data) {
        final assignments = (data['assignments'] as List<dynamic>)
            .map(
              (e) => AssignedProgramModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        return Success(assignments);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch client programs for $userId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Update an existing program assignment's dates, notes, or active status.
  Future<Result<AssignedProgramModel, AppError>> updateAssignment(
    String assignmentId,
    UpdateAssignmentRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/coach/assign-program/$assignmentId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final assignment = AssignedProgramModel.fromJson(
          data['assignment'] as Map<String, dynamic>,
        );
        return Success(assignment);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update assignment $assignmentId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Delete a program assignment.
  Future<Result<void, AppError>> deleteAssignment(String assignmentId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/coach/assign-program/$assignmentId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to delete assignment $assignmentId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Class Roster (ML-4)
  // ──────────────────────────────────────────────────

  /// Get the coach's class roster — all subscribed clients.
  ///
  /// `GET /coach/class`
  /// Returns clients with `subscribedAt` and `subscriptionExpiresAt` (ML-4).
  Future<
    Result<
      ({List<RosterClientModel> clients, PaginationMeta pagination}),
      AppError
    >
  >
  getClassRoster({int limit = 50, int offset = 0}) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.coachClass,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        final clients = (data['clients'] as List<dynamic>)
            .map((e) => RosterClientModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = PaginationMeta.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
        return Success((clients: clients, pagination: pagination));
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch class roster',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Remove a client from the coach's class.
  ///
  /// `DELETE /coach/class/:clientId`
  Future<Result<void, AppError>> removeClientFromClass(String clientId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.coachClass}/$clientId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to remove client $clientId from class',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Client List with Assignments (ML-4)
  // ──────────────────────────────────────────────────

  /// Get the coach's full client list with assignment info.
  ///
  /// `GET /coach/clients`
  /// Richer than [getClassRoster] — includes `assignedPrograms` and
  /// `isAssigned` fields. Also includes `subscriptionExpiresAt` (ML-4).
  Future<
    Result<
      ({List<CoachClientModel> clients, PaginationMeta pagination}),
      AppError
    >
  >
  getClients({int limit = 50, int offset = 0, bool? isAssigned}) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (isAssigned != null) 'isAssigned': isAssigned,
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.coachClients,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        final clients = (data['clients'] as List<dynamic>)
            .map((e) => CoachClientModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = PaginationMeta.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
        return Success((clients: clients, pagination: pagination));
      },
      failure: (error) {
        AppLogger.error('Failed to fetch clients', tag: 'CoachProgramRepo');
        return Failure(error);
      },
    );
  }
}

/// Singleton provider for [CoachProgramRepository].
@Riverpod(keepAlive: true)
CoachProgramRepository coachProgramRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CoachProgramRepository(apiClient: apiClient);
}
