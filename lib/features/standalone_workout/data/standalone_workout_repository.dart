import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../workout/data/models/models.dart';
import 'models/models.dart';

part 'standalone_workout_repository.g.dart';

@Riverpod(keepAlive: true)
StandaloneWorkoutRepository standaloneWorkoutRepository(
  Ref ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return StandaloneWorkoutRepository(apiClient: apiClient);
}

class StandaloneWorkoutRepository {
  StandaloneWorkoutRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ════════════════════════════════════════════════════════
  //  PROGRAM OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<StandaloneProgramListResponse, AppError>> getPrograms({
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standalonePrograms,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return result.when(
      success: (data) {
        final d = data!;
        final pagination = d['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          d['total'] = pagination['total'];
          d['limit'] = pagination['limit'];
          d['offset'] = pagination['offset'];
          d['hasMore'] = pagination['hasMore'];
        }
        return Success(StandaloneProgramListResponse.fromJson(d));
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneProgramDetail, AppError>> getProgram(
    String programId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
    );
    return result.when(
      success: (data) {
        final program = data!['program'] as Map<String, dynamic>? ?? data;
        return Success(StandaloneProgramDetail.fromJson(program));
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneProgramDetail, AppError>> getActiveProgram() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveProgram,
    );
    return result.when(
      success: (data) {
        final program = data!['program'] as Map<String, dynamic>? ?? data;
        return Success(StandaloneProgramDetail.fromJson(program));
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneProgram, AppError>> createProgram(
    CreateStandaloneProgramRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standalonePrograms,
      data: request.toJson(),
    );
    return result.when(
      success: (data) =>
          Success(StandaloneProgram.fromJson(data!['program'])),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneProgram, AppError>> updateProgram(
    String programId,
    UpdateStandaloneProgramRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
      data: request.toJson(),
    );
    return result.when(
      success: (data) =>
          Success(StandaloneProgram.fromJson(data!['program'])),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<void, AppError>> deleteProgram(String programId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId',
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  Future<Result<void, AppError>> activateProgram(String programId) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/activate',
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  Future<Result<void, AppError>> deactivateProgram(String programId) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/deactivate',
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  // ════════════════════════════════════════════════════════
  //  BUILDER (BULK)
  // ════════════════════════════════════════════════════════

  Future<Result<StandaloneProgramDetail, AppError>> buildProgram(
    BuildStandaloneProgramRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneProgramsBuild,
      data: request.toJson(),
    );
    return result.when(
      success: (data) {
        final program = data!['program'] as Map<String, dynamic>? ?? data;
        return Success(StandaloneProgramDetail.fromJson(program));
      },
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PROGRAM ROUTINE OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<StandaloneProgramDetail, AppError>> addProgramRoutine(
    String programId,
    AddProgramRoutineRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/routines',
      data: {
        'routine_id': request.routineId,
        'order_in_program': request.orderInProgram,
      },
    );
    return result.when(
      success: (data) {
        final programRoutine = data!['program_routine'] as Map<String, dynamic>;
        // Re-fetch full program tree to get updated state
        return getProgram(programId);
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<void, AppError>> updateProgramRoutine(
    String programId,
    String programRoutineId,
    UpdateProgramRoutineRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/routines/$programRoutineId',
      data: {'order_in_program': request.orderInProgram},
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  Future<Result<void, AppError>> deleteProgramRoutine(
    String programId,
    String programRoutineId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standalonePrograms}/$programId/routines/$programRoutineId',
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  // ════════════════════════════════════════════════════════
  //  ROUTINE EXERCISE OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<void, AppError>> addRoutineExercise(
    String routineId,
    AddRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId/exercises',
      data: {
        'exercise_id': request.exerciseId,
        'sets': request.sets,
        'reps_min': request.repsMin,
        'reps_max': request.repsMax,
        'rest_seconds': request.restSeconds,
        'order_in_routine': request.orderInRoutine,
      },
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  Future<Result<void, AppError>> updateRoutineExercise(
    String routineId,
    String routineExerciseId,
    UpdateRoutineExerciseRequest request,
  ) async {
    final Map<String, dynamic> body = {};
    if (request.sets != null) body['sets'] = request.sets;
    if (request.repsMin != null) body['reps_min'] = request.repsMin;
    if (request.repsMax != null) body['reps_max'] = request.repsMax;
    if (request.restSeconds != null) body['rest_seconds'] = request.restSeconds;
    if (request.orderInRoutine != null) body['order_in_routine'] = request.orderInRoutine;

    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId/exercises/$routineExerciseId',
      data: body,
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  Future<Result<void, AppError>> deleteRoutineExercise(
    String routineId,
    String routineExerciseId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId/exercises/$routineExerciseId',
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  // ════════════════════════════════════════════════════════
  //  STANDALONE ROUTINE CRUD
  // ════════════════════════════════════════════════════════

  /// Create a new standalone routine.
  /// Returns the created routine ID for use with [addProgramRoutine].
  Future<Result<String, AppError>> createRoutine({
    required String name,
    String description = '',
    int estimatedDurationMinutes = 45,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneRoutines,
      data: {
        'name': name,
        'description': description,
        'estimated_duration_minutes': estimatedDurationMinutes,
      },
    );
    return result.when(
      success: (data) {
        final routine = data!['routine'] as Map<String, dynamic>;
        return Success(routine['id'] as String);
      },
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PERSONAL EXERCISE CRUD
  // ════════════════════════════════════════════════════════

  /// Create a new personal exercise.
  /// Returns the created exercise ID for use with [addRoutineExercise].
  Future<Result<String, AppError>> createExercise({
    required String name,
    String description = '',
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneExercises,
      data: {
        'name': name,
        'description': description,
      },
    );
    return result.when(
      success: (data) {
        final exercise = data!['exercise'] as Map<String, dynamic>;
        return Success(exercise['id'] as String);
      },
      failure: (error) => Failure(error),
    );
  }

  // ════════════════════════════════════════════════════════
  //  SESSION OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<StandaloneSession, AppError>> startSession(
    StartStandaloneSessionRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneSessions,
      data: {'program_routine_id': request.programRoutineId},
    );
    return result.when(
      success: (data) =>
          Success(StandaloneSession.fromJson(data!['session'])),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneSession?, AppError>> getActiveSession() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneActiveSession,
    );
    return result.when(
      success: (data) {
        final session = data!['session'];
        if (session == null) return const Success(null);
        return Success(StandaloneSession.fromJson(session));
      },
      failure: (error) => Failure(error),
    );
  }

  /// Load the active session and return data suitable for the workout screen.
  /// Returns `null` on success with no active session.
  Future<
    Result<
      ({
        WorkoutSessionModel session,
        List<RoutineExerciseModel> exercises,
        String routineName,
      })?,
      AppError
    >
  >
  resumeActiveSession() async {
    final result = await getActiveSession();
    return result.when(
      success: (session) {
        if (session == null) return const Success(null);
        final workoutSession = WorkoutSessionModel(
          id: session.id,
          userId: session.userId,
          assignedProgramRoutineId: session.programRoutineId,
          startedAt: session.startedAt,
          completedAt: session.completedAt,
          notes: session.feedback,
          createdAt: session.createdAt,
          performedSets: const [],
        );
        final exercises = session.exercises
            .map(
              (e) => RoutineExerciseModel(
                id: e.id,
                exerciseId: e.exerciseId,
                sets: e.sets,
                repsMin: e.repsMin,
                repsMax: e.repsMax,
                restSeconds: e.restSeconds,
                orderInRoutine: e.orderInRoutine,
              ),
            )
            .toList();
        return Success((
          session: workoutSession,
          exercises: exercises,
          routineName: session.routineName ?? 'Workout',
        ));
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneSession, AppError>> getSession(
    String sessionId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId',
    );
    return result.when(
      success: (data) =>
          Success(StandaloneSession.fromJson(data!['session'])),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneSessionListResponse, AppError>> getSessionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneSessions,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return result.when(
      success: (data) {
        final d = data!;
        final pagination = d['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          d['total'] = pagination['total'];
          d['limit'] = pagination['limit'];
          d['offset'] = pagination['offset'];
          d['hasMore'] = pagination['hasMore'];
        }
        return Success(StandaloneSessionListResponse.fromJson(d));
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneSession, AppError>> completeSession(
    String sessionId, {
    String? feedback,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId/complete',
      data: {'feedback': feedback},
    );
    return result.when(
      success: (data) =>
          Success(StandaloneSession.fromJson(data!['session'])),
      failure: (error) => Failure(error),
    );
  }

  /// Start a workout session and return [WorkoutSessionModel] for set
  /// logging.
  Future<Result<WorkoutSessionModel, AppError>> startWorkoutSession({
    required String userId,
    required String programRoutineId,
  }) async {
    AppLogger.debug('Starting standalone workout session',
        tag: 'StandaloneRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneSessions,
      data: {'program_routine_id': programRoutineId},
    );

    return result.when(
      success: (data) {
        try {
          final sessionJson = data!['session'] as Map<String, dynamic>;
          final session = _parseWorkoutSessionModel(sessionJson);

          AppLogger.info(
            'Standalone session started: ${session.id}',
            tag: 'StandaloneRepo',
          );
          return Success(session);
        } catch (e, st) {
          AppLogger.error(
            'Failed to parse standalone session',
            tag: 'StandaloneRepo',
            error: e,
            stackTrace: st,
          );
          return Failure(
            UnknownError(message: 'Failed to parse session: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Parses a server session response handling both snake_case and
  /// camelCase keys.
  WorkoutSessionModel _parseWorkoutSessionModel(
    Map<String, dynamic> json,
  ) {
    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      assignedProgramRoutineId:
          (json['assigned_program_routine_id'] ??
                  json['assignedProgramRoutineId'])
              as String?,
      startedAt:
          DateTime.parse((json['started_at'] ?? json['startedAt']) as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      notes: (json['notes'] ?? json['notes']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      performedSets: const [],
    );
  }

  // ════════════════════════════════════════════════════════
  //  PERFORMED SET OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<StandalonePerformedSet, AppError>> logSet(
    String sessionId,
    LogStandaloneSetRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId/sets',
      data: {
        'routine_exercise_id': request.routineExerciseId,
        'set_number': request.setNumber,
        'reps': request.reps,
        'weight': request.weight,
      },
    );
    return result.when(
      success: (data) => Success(
        StandalonePerformedSet.fromJson(data!['performed_set']),
      ),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandalonePerformedSet, AppError>> updateSet(
    String sessionId,
    String setId,
    UpdateStandaloneSetRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId/sets/$setId',
      data: request.toJson(),
    );
    return result.when(
      success: (data) => Success(
        StandalonePerformedSet.fromJson(data!['performed_set']),
      ),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<void, AppError>> deleteSet(
    String sessionId,
    String setId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId/sets/$setId',
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  // ════════════════════════════════════════════════════════
  //  STATS OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<StandaloneStats, AppError>> getStats() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.standaloneStats,
    );
    return result.when(
      success: (data) => Success(StandaloneStats.fromJson(data!)),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<StandaloneExerciseStat, AppError>> getExerciseStat(
    String exerciseId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.standaloneStats}/exercise/$exerciseId',
    );
    return result.when(
      success: (data) => Success(StandaloneExerciseStat.fromJson(data!)),
      failure: (error) => Failure(error),
    );
  }
}
