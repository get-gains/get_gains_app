import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import 'models/coach_client_model.dart';
import 'models/program_model.dart';
import 'models/program_request_models.dart';

part 'coach_program_repository.g.dart';

/// Repository for all coach program operations.
///
/// Covers:
/// - Client programs (CRUD on `assigned_program`)
/// - Program routines (add/update/delete `assigned_program_routine`)
/// - Program routine exercises (add/update/delete `assigned_program_routine_exercise`)
/// - Routine templates (CRUD on `routine` library)
/// - Class roster and client list
class CoachProgramRepository {
  CoachProgramRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ──────────────────────────────────────────────────
  // Client Programs
  // ──────────────────────────────────────────────────

  /// Create a new program for a specific client.
  ///
  /// `POST /coach/clients/:clientId/programs`
  Future<Result<ClientProgramModel, AppError>> createClientProgram(
    String clientId,
    CreateClientProgramRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.coachClients}/$clientId/programs',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to create program for client $clientId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Get the currently active program for a client.
  ///
  /// `GET /coach/clients/:clientId/program`
  /// Returns `null` if the client has no active program.
  Future<Result<ClientProgramModel?, AppError>> getClientActiveProgram(
    String clientId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.coachClients}/$clientId/program',
    );

    return result.when(
      success: (data) {
        final raw = data['program'];
        if (raw == null) return const Success(null);
        final program = ClientProgramModel.fromJson(
          raw as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch active program for client $clientId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Get a single program with its full routine / exercise tree.
  ///
  /// `GET /coach/programs/:programId`
  Future<Result<ClientProgramModel, AppError>> getProgramById(
    String programId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId',
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
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

  /// Update an existing program's fields.
  ///
  /// `PATCH /coach/programs/:programId`
  Future<Result<ClientProgramModel, AppError>> updateProgram(
    String programId,
    UpdateClientProgramRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
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

  /// Soft-delete a program.
  ///
  /// `DELETE /coach/programs/:programId`
  Future<Result<void, AppError>> deleteProgram(String programId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId',
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
  // Program Routines
  // ──────────────────────────────────────────────────

  /// Add a routine to a program from a template.
  ///
  /// `POST /coach/programs/:programId/routines` with `mode: 'template'`
  /// Returns the full program tree with the new routine.
  Future<Result<ClientProgramModel, AppError>> addProgramRoutineFromTemplate(
    String programId,
    AddProgramRoutineTemplateRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId/routines',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to add template routine to program $programId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Add a routine to a program inline (new routine, not from template).
  ///
  /// `POST /coach/programs/:programId/routines` with `mode: 'inline'`
  /// Returns the full program tree with the new routine.
  Future<Result<ClientProgramModel, AppError>> addProgramRoutineInline(
    String programId,
    AddProgramRoutineInlineRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId/routines',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to add inline routine to program $programId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Update a routine within a program.
  ///
  /// `PATCH /coach/programs/:programId/routines/:aprId`
  /// Returns the full program tree.
  Future<Result<ClientProgramModel, AppError>> updateProgramRoutine(
    String programId,
    String aprId,
    UpdateProgramRoutineRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId/routines/$aprId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update program routine $aprId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Remove a routine from a program (soft-delete).
  ///
  /// `DELETE /coach/programs/:programId/routines/:aprId`
  Future<Result<void, AppError>> deleteProgramRoutine(
    String programId,
    String aprId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId/routines/$aprId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to delete program routine $aprId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Program Routine Exercises
  // ──────────────────────────────────────────────────

  /// Add an exercise to a program routine.
  ///
  /// `POST /coach/programs/:programId/routines/:aprId/exercises`
  Future<Result<ProgramRoutineExerciseModel, AppError>>
  addProgramRoutineExercise(
    String programId,
    String aprId,
    AddProgramRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId/routines/$aprId/exercises',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final exercise = ProgramRoutineExerciseModel.fromJson(
          data['exercise'] as Map<String, dynamic>,
        );
        return Success(exercise);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to add exercise to routine $aprId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Update an exercise within a program routine.
  ///
  /// `PATCH /coach/programs/:programId/routines/:aprId/exercises/:apreId`
  Future<Result<ProgramRoutineExerciseModel, AppError>>
  updateProgramRoutineExercise(
    String programId,
    String aprId,
    String apreId,
    UpdateProgramRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId/routines/$aprId/exercises/$apreId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final exercise = ProgramRoutineExerciseModel.fromJson(
          data['exercise'] as Map<String, dynamic>,
        );
        return Success(exercise);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update program routine exercise $apreId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Remove an exercise from a program routine.
  ///
  /// `DELETE /coach/programs/:programId/routines/:aprId/exercises/:apreId`
  Future<Result<void, AppError>> deleteProgramRoutineExercise(
    String programId,
    String aprId,
    String apreId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.coachPrograms}/$programId/routines/$aprId/exercises/$apreId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to delete program routine exercise $apreId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Routine Templates
  // ──────────────────────────────────────────────────

  /// List all routine templates owned by the authenticated coach.
  ///
  /// `GET /coach/routine-templates`
  Future<
    Result<
      ({List<RoutineSummaryModel> routines, PaginationMeta pagination}),
      AppError
    >
  >
  getRoutines({int limit = 50, int offset = 0}) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/coach/routine-templates',
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
        AppLogger.error(
          'Failed to fetch routine templates',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Get a single routine template.
  ///
  /// `GET /coach/routine-templates/:routineId`
  Future<Result<RoutineSummaryModel, AppError>> getRoutineById(
    String routineId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/coach/routine-templates/$routineId',
    );

    return result.when(
      success: (data) {
        final routine = RoutineSummaryModel.fromJson(
          data['routine'] as Map<String, dynamic>,
        );
        return Success(routine);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch routine template $routineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Create a new routine template.
  ///
  /// `POST /coach/routine-templates`
  Future<Result<RoutineSummaryModel, AppError>> createRoutine(
    CreateRoutineRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/coach/routine-templates',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final routine = RoutineSummaryModel.fromJson(
          data['routine'] as Map<String, dynamic>,
        );
        return Success(routine);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to create routine template',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Update a routine template.
  ///
  /// `PATCH /coach/routine-templates/:routineId`
  Future<Result<RoutineSummaryModel, AppError>> updateRoutine(
    String routineId,
    UpdateRoutineRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/coach/routine-templates/$routineId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final routine = RoutineSummaryModel.fromJson(
          data['routine'] as Map<String, dynamic>,
        );
        return Success(routine);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update routine template $routineId',
          tag: 'CoachProgramRepo',
        );
        return Failure(error);
      },
    );
  }

  /// Delete a routine template (soft-delete).
  ///
  /// `DELETE /coach/routine-templates/:routineId`
  Future<Result<void, AppError>> deleteRoutine(String routineId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/coach/routine-templates/$routineId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) {
        AppLogger.error(
          'Failed to delete routine template $routineId',
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
