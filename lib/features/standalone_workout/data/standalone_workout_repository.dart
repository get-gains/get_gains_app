import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
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
      success: (data) =>
          Success(StandaloneProgramListResponse.fromJson(data!)),
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
      data: request.toJson(),
    );
    return result.when(
      success: (data) {
        final program = data!['program'] as Map<String, dynamic>? ??
            data['program_routine'];
        return Success(StandaloneProgramDetail.fromJson(program ?? data));
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
      data: request.toJson(),
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
      data: request.toJson(),
    );
    return result.when(success: (_) => const Success(null), failure: Failure.new);
  }

  Future<Result<void, AppError>> updateRoutineExercise(
    String routineId,
    String routineExerciseId,
    UpdateRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.standaloneRoutines}/$routineId/exercises/$routineExerciseId',
      data: request.toJson(),
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
  //  SESSION OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<StandaloneSession, AppError>> startSession(
    StartStandaloneSessionRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.standaloneSessions,
      data: request.toJson(),
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
      success: (data) =>
          Success(StandaloneSessionListResponse.fromJson(data!)),
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

  // ════════════════════════════════════════════════════════
  //  PERFORMED SET OPERATIONS
  // ════════════════════════════════════════════════════════

  Future<Result<StandalonePerformedSet, AppError>> logSet(
    String sessionId,
    LogStandaloneSetRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.standaloneSessions}/$sessionId/sets',
      data: request.toJson(),
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
