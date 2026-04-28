import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../coach_programs/data/models/program_model.dart';
import '../../coach_programs/data/models/program_request_models.dart';

part 'self_program_repository.g.dart';

class SelfProgramRepository {
  SelfProgramRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<ClientProgramModel, AppError>> createSelfProgram(
    CreateClientProgramRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.userPrograms,
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
        AppLogger.error('Failed to create self program', tag: 'SelfProgramRepo');
        return Failure(error);
      },
    );
  }

  Future<Result<({List<ClientProgramModel> programs, int count}), AppError>> getSelfPrograms({int limit = 50, int offset = 0}) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.userPrograms,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        final programs = (data['programs'] as List<dynamic>)
            .map((e) => ClientProgramModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final count = data['count'] as int;
        return Success((programs: programs, count: count));
      },
      failure: (error) {
        AppLogger.error('Failed to fetch self programs', tag: 'SelfProgramRepo');
        return Failure(error);
      },
    );
  }

  Future<Result<ClientProgramModel, AppError>> getProgramById(String programId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId',
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) {
        AppLogger.error('Failed to fetch program $programId', tag: 'SelfProgramRepo');
        return Failure(error);
      },
    );
  }

  Future<Result<ClientProgramModel, AppError>> updateProgram(
    String programId,
    UpdateClientProgramRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId',
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
        AppLogger.error('Failed to update program $programId', tag: 'SelfProgramRepo');
        return Failure(error);
      },
    );
  }

  Future<Result<void, AppError>> deleteProgram(String programId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<ClientProgramModel, AppError>> addProgramRoutineInline(
    String programId,
    AddProgramRoutineInlineRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId/routines',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<ClientProgramModel, AppError>> updateProgramRoutine(
    String programId,
    String aprId,
    UpdateProgramRoutineRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId/routines/$aprId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final program = ClientProgramModel.fromJson(
          data['program'] as Map<String, dynamic>,
        );
        return Success(program);
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<void, AppError>> deleteProgramRoutine(String programId, String aprId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId/routines/$aprId',
    );
    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<ProgramRoutineExerciseModel, AppError>> addProgramRoutineExercise(
    String programId,
    String aprId,
    AddProgramRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId/routines/$aprId/exercises',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final exercise = ProgramRoutineExerciseModel.fromJson(
          data['exercise'] as Map<String, dynamic>,
        );
        return Success(exercise);
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<ProgramRoutineExerciseModel, AppError>> updateProgramRoutineExercise(
    String programId,
    String aprId,
    String apreId,
    UpdateProgramRoutineExerciseRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId/routines/$aprId/exercises/$apreId',
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final exercise = ProgramRoutineExerciseModel.fromJson(
          data['exercise'] as Map<String, dynamic>,
        );
        return Success(exercise);
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<void, AppError>> deleteProgramRoutineExercise(
    String programId,
    String aprId,
    String apreId,
  ) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.userPrograms}/$programId/routines/$aprId/exercises/$apreId',
    );
    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }
}

@Riverpod(keepAlive: true)
SelfProgramRepository selfProgramRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SelfProgramRepository(apiClient: apiClient);
}
