import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/database/app_database.dart';
import '../../../services/pose/frames_blob.dart';

part 'client_pose_repository.g.dart';

/// Repository for client-side pose comparison operations.
///
/// Handles:
/// - Downloading reference forms for exercises (with offline caching)
/// - Downloading coach form frame blobs via presigned URLs
class ClientPoseRepository {
  ClientPoseRepository({
    required ApiClient apiClient,
    required AppDatabase database,
  }) : _apiClient = apiClient,
       _db = database;

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// Bare Dio for S3 GET — no auth interceptors.
  final Dio _s3Dio = Dio(
    BaseOptions(
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  /// Download the active reference form + config for an exercise.
  ///
  /// **Offline-first**: Tries the server first. On success, fetches the
  /// coach frames blob for each form via presigned download URL, merges
  /// them into the response, and caches locally. On failure falls back
  /// to the locally cached response if available.
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

      // Fetch each form's frames blob from S3 and attach to the response
      final forms = data['forms'] as List?;
      if (forms != null) {
        final formsBlobs = <String, Map<String, dynamic>>{};
        for (final formData in forms) {
          final form = formData as Map<String, dynamic>;
          final formId = form['id'] as String?;
          final recordedFramesKey = form['recorded_frames_key'] as String?;
          if (formId != null && recordedFramesKey != null) {
            final blob = await _fetchFormBlob(formId);
            if (blob != null) {
              formsBlobs[formId] = blob;
            }
          }
        }
        data['formsBlobs'] = formsBlobs;
      }

      // Cache the merged response for offline use
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

  /// Fetch the coach frames blob for a form via presigned download URL.
  Future<Map<String, dynamic>?> _fetchFormBlob(String formId) async {
    try {
      final urlResult = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.poseFormDownloadUrl(formId),
      );

      return urlResult.when(
        success: (data) async {
          final url = data['url'] as String?;
          if (url == null) return null;

          try {
            final response = await _s3Dio.get<Map<String, dynamic>>(url);
            return response.data;
          } on DioException catch (e) {
            AppLogger.warning(
              'Failed to download form blob from S3 for $formId: ${e.message}',
              tag: 'ClientPoseRepo',
            );
            return null;
          }
        },
        failure: (error) async {
          AppLogger.warning(
            'Failed to get download URL for form $formId: ${error.message}',
            tag: 'ClientPoseRepo',
          );
          return null;
        },
      );
    } catch (e) {
      AppLogger.warning(
        'Error fetching form blob for $formId: $e',
        tag: 'ClientPoseRepo',
      );
      return null;
    }
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

  /// Parse a cached form blob into a [CoachFramesBlob].
  ///
  /// Used by providers to extract landmark/feature frames from the cached
  /// server response without re-downloading.
  CoachFramesBlob? parseCoachBlob(Map<String, dynamic>? blobJson) {
    if (blobJson == null) return null;
    try {
      final blob = FramesBlob.fromJson(blobJson);
      return blob is CoachFramesBlob ? blob : null;
    } catch (e) {
      AppLogger.warning(
        'Failed to parse CoachFramesBlob: $e',
        tag: 'ClientPoseRepo',
      );
      return null;
    }
  }
}

/// Provider for ClientPoseRepository
@Riverpod(keepAlive: true)
ClientPoseRepository clientPoseRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  final database = ref.watch(appDatabaseProvider);
  return ClientPoseRepository(apiClient: apiClient, database: database);
}
