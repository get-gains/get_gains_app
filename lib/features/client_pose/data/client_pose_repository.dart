import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../coach_pose/data/models/models.dart';
import 'models/models.dart';

part 'client_pose_repository.g.dart';

/// Repository for client-side pose comparison operations.
///
/// Handles:
/// - Downloading reference forms for exercises
/// - Submitting comparison results to server
/// - Fetching comparison history
class ClientPoseRepository {
  ClientPoseRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Download the active reference form + config for an exercise.
  ///
  /// Returns form data with landmarks for on-device DTW comparison.
  Future<Result<Map<String, dynamic>, AppError>> downloadExerciseForm(
    String exerciseId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/download/exercise/$exerciseId',
    );

    return result.when(
      success: (data) {
        AppLogger.debug(
          'Downloaded exercise form for $exerciseId',
          tag: 'ClientPoseRepo',
        );
        return Success(data);
      },
      failure: (error) => Failure(error),
    );
  }

  /// Submit a form comparison result after on-device analysis.
  Future<Result<ComparisonResultModel, AppError>> submitResult({
    required String exerciseFormId,
    String? workoutSessionId,
    String? routineExerciseId,
    required double overallScore,
    required Map<String, double> segmentScores,
    required List<Map<String, dynamic>> corrections,
    required String cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    double? avgLandmarkConfidence,
    List<Map<String, dynamic>>? clientLandmarkFrames,
    List<Map<String, dynamic>>? clientFeatureFrames,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/pose/results',
      data: {
        'exerciseFormId': exerciseFormId,
        if (workoutSessionId != null) 'workoutSessionId': workoutSessionId,
        if (routineExerciseId != null) 'routineExerciseId': routineExerciseId,
        'overallScore': overallScore,
        'segmentScores': segmentScores,
        'corrections': corrections,
        'cameraAngle': cameraAngle,
        'durationMs': durationMs,
        'frameRate': frameRate,
        'totalFrames': totalFrames,
        if (avgLandmarkConfidence != null)
          'avgLandmarkConfidence': avgLandmarkConfidence,
        if (clientLandmarkFrames != null)
          'clientLandmarkFrames': clientLandmarkFrames,
        if (clientFeatureFrames != null)
          'clientFeatureFrames': clientFeatureFrames,
      },
    );

    return result.when(
      success: (data) {
        try {
          final resultData = data['result'] as Map<String, dynamic>;
          // Server returns partial data; build the model
          return Success(
            ComparisonResultModel(
              id: resultData['id'] as String?,
              exerciseFormId: exerciseFormId,
              overallScore: (resultData['overallScore'] as num).toDouble(),
              segmentScores: segmentScores,
              corrections:
                  (resultData['corrections'] as List?)
                      ?.map(
                        (c) =>
                            CorrectionModel.fromJson(c as Map<String, dynamic>),
                      )
                      .toList() ??
                  [],
              cameraAngle: cameraAngle,
              durationMs: durationMs,
              frameRate: frameRate,
              totalFrames: totalFrames,
              createdAt: resultData['createdAt'] != null
                  ? DateTime.parse(resultData['createdAt'] as String)
                  : null,
            ),
          );
        } catch (e) {
          AppLogger.error(
            'Failed to parse submitted result',
            tag: 'ClientPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse result: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get comparison history for the current user.
  Future<Result<List<ComparisonResultModel>, AppError>> getHistory({
    String? exerciseId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
    if (exerciseId != null) queryParams['exerciseId'] = exerciseId;

    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/results',
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final results = (data['results'] as List)
              .map(
                (r) =>
                    ComparisonResultModel.fromJson(r as Map<String, dynamic>),
              )
              .toList();
          return Success(results);
        } catch (e) {
          AppLogger.error(
            'Failed to parse history',
            tag: 'ClientPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse history: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get the pose config for an exercise (used for comparison setup).
  Future<Result<PoseConfigModel?, AppError>> getPoseConfig(
    String exerciseId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/exercises/$exerciseId/config',
    );

    return result.when(
      success: (data) {
        try {
          final config = PoseConfigModel.fromJson(
            data['config'] as Map<String, dynamic>,
          );
          return Success(config);
        } catch (e) {
          AppLogger.error(
            'Failed to parse pose config',
            tag: 'ClientPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse config: $e'));
        }
      },
      failure: (error) {
        if (error is NetworkError && error.statusCode == 404) {
          return const Success(null);
        }
        return Failure(error);
      },
    );
  }
}

/// Provider for ClientPoseRepository
@Riverpod(keepAlive: true)
ClientPoseRepository clientPoseRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientPoseRepository(apiClient: apiClient);
}
