import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import '../../coach_pose/data/models/models.dart';
import 'models/models.dart';

part 'client_pose_repository.g.dart';

/// Repository for client-side pose comparison operations.
///
/// Handles:
/// - Downloading reference forms for exercises (with offline caching)
/// - Submitting comparison results to server
/// - Fetching comparison history
class ClientPoseRepository {
  ClientPoseRepository({
    required ApiClient apiClient,
    required AppDatabase database,
  }) : _apiClient = apiClient,
       _db = database;

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// Download the active reference form + config for an exercise.
  ///
  /// **Offline-first**: Tries the server first. On success, caches the
  /// response locally. On failure (e.g. no internet), falls back to the
  /// locally cached response if available.
  Future<Result<Map<String, dynamic>, AppError>> downloadExerciseForm(
    String exerciseId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/download/exercise/$exerciseId',
    );

    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      AppLogger.debug(
        'Downloaded exercise form for $exerciseId',
        tag: 'ClientPoseRepo',
      );
      // Cache the response for offline use
      _cacheFormResponse(exerciseId, data);
      return Success(data);
    }

    // Server request failed — try loading from local cache
    final cached = await _loadCachedForm(exerciseId);
    if (cached != null) {
      AppLogger.info(
        'Loaded cached exercise form for $exerciseId',
        tag: 'ClientPoseRepo',
      );
      return Success(cached);
    }

    // No cache available — return the original error
    return result;
  }

  /// Cache the server response for an exercise form.
  Future<void> _cacheFormResponse(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.upsertCachedExerciseForm(
        exerciseId: exerciseId,
        responseJson: jsonEncode(data),
      );
      AppLogger.debug(
        'Cached exercise form for $exerciseId',
        tag: 'ClientPoseRepo',
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to cache exercise form: $e',
        tag: 'ClientPoseRepo',
      );
    }
  }

  /// Load a previously cached form response.
  Future<Map<String, dynamic>?> _loadCachedForm(String exerciseId) async {
    try {
      final cached = await _db.getCachedExerciseForm(exerciseId);
      if (cached == null) return null;
      return jsonDecode(cached.responseJson) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.warning(
        'Failed to read cached exercise form: $e',
        tag: 'ClientPoseRepo',
      );
      return null;
    }
  }

  /// Pre-cache reference forms for a list of exercises.
  ///
  /// Fire-and-forget — errors are silently logged. Call this when a workout
  /// starts so forms are available if the device goes offline mid-session.
  Future<void> preCacheExerciseForms(List<String> exerciseIds) async {
    for (final id in exerciseIds) {
      try {
        await downloadExerciseForm(id);
      } catch (e) {
        AppLogger.debug('Pre-cache skipped for $id: $e', tag: 'ClientPoseRepo');
      }
    }
  }

  /// Submit a form comparison result after on-device analysis.
  ///
  /// **Offline-first**: If the server is unreachable the result is queued in
  /// the local [SyncQueue] and will be uploaded automatically by
  /// [WorkoutSyncService] when connectivity is restored.
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
    final payload = <String, dynamic>{
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
    };

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/pose/results',
      data: payload,
    );

    if (result is Success<Map<String, dynamic>, AppError>) {
      try {
        final data = result.value;
        final resultData = data['result'] as Map<String, dynamic>;
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
    }

    // Server unreachable — queue for later sync
    AppLogger.warning(
      'Offline: queuing pose result for sync when online',
      tag: 'ClientPoseRepo',
    );
    try {
      await _db.addToSyncQueue(
        SyncQueueCompanion.insert(
          entityTable: 'pose_results',
          recordId: exerciseFormId,
          operation: 'create',
          payload: jsonEncode(payload),
        ),
      );
      AppLogger.info('Pose result queued for sync', tag: 'ClientPoseRepo');
    } catch (e) {
      AppLogger.error(
        'Failed to queue pose result',
        tag: 'ClientPoseRepo',
        error: e,
      );
    }

    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
  }

  /// Get comparison history for the current user.
  ///
  /// **Offline-first**: On success the first page (offset 0) is cached in
  /// [CachedApiResponses]. On network failure the cached page is returned so
  /// the user can still browse their history without connectivity.
  Future<Result<List<ComparisonResultModel>, AppError>> getHistory({
    String? exerciseId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
    if (exerciseId != null) queryParams['exerciseId'] = exerciseId;

    // Build a stable cache key that reflects the query parameters.
    final cacheKey = exerciseId != null
        ? 'pose_history_$exerciseId'
        : 'pose_history';

    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/results',
      queryParameters: queryParams,
    );

    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      // Cache the first page for offline use.
      if (offset == 0) {
        try {
          await _db.upsertCachedApiResponse(
            key: cacheKey,
            responseJson: jsonEncode(data),
          );
        } catch (e) {
          AppLogger.warning(
            'Failed to cache pose history: $e',
            tag: 'ClientPoseRepo',
          );
        }
      }
      try {
        final results = (data['results'] as List)
            .map(
              (r) => ComparisonResultModel.fromJson(r as Map<String, dynamic>),
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
    }

    // Network failed — try returning cached first page.
    try {
      final cached = await _db.getCachedApiResponse(cacheKey);
      if (cached != null) {
        AppLogger.info(
          'Loaded cached pose history ($cacheKey)',
          tag: 'ClientPoseRepo',
        );
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final results = (data['results'] as List)
            .map(
              (r) => ComparisonResultModel.fromJson(r as Map<String, dynamic>),
            )
            .toList();
        return Success(results);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to read cached pose history: $e',
        tag: 'ClientPoseRepo',
      );
    }

    final failure = result as Failure<Map<String, dynamic>, AppError>;
    return Failure(failure.error);
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
  final database = ref.watch(appDatabaseProvider);
  return ClientPoseRepository(apiClient: apiClient, database: database);
}
