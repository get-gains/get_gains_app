import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/cache/cache_service.dart';
import '../../../services/pose/frames_blob.dart';

part 'client_pose_repository.g.dart';

class ClientPoseRepository {
  ClientPoseRepository({required ApiClient apiClient, required CacheService cache})
    : _apiClient = apiClient,
      _cache = cache;

  final ApiClient _apiClient;
  final CacheService _cache;

  final Dio _s3Dio = Dio(BaseOptions(
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
  ));

  static String _formCacheKey(String exerciseId) => 'pose_reference:$exerciseId';

  Future<Result<Map<String, dynamic>, AppError>> downloadExerciseForm(
    String exerciseId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/download/exercise/$exerciseId',
    );

    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      AppLogger.debug('Downloaded exercise form for $exerciseId', tag: 'ClientPoseRepo');

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

      _cache.putJson(_formCacheKey(exerciseId), data, version: DateTime.now().toIso8601String());
      return Success(data);
    }

    final cached = await _cache.get<Map<String, dynamic>>(
      _formCacheKey(exerciseId),
      (json) => json,
    );
    if (cached != null) {
      AppLogger.info('Loaded cached exercise form for $exerciseId', tag: 'ClientPoseRepo');
      return Success(cached);
    }

    return result;
  }

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
      AppLogger.warning('Error fetching form blob for $formId: $e', tag: 'ClientPoseRepo');
      return null;
    }
  }

  Future<void> preCacheExerciseForms(List<String> exerciseIds) async {
    for (final id in exerciseIds) {
      try {
        await downloadExerciseForm(id);
      } catch (e) {
        AppLogger.debug('Pre-cache skipped for $id: $e', tag: 'ClientPoseRepo');
      }
    }
  }

  CoachFramesBlob? parseCoachBlob(Map<String, dynamic>? blobJson) {
    if (blobJson == null) return null;
    try {
      final blob = FramesBlob.fromJson(blobJson);
      return blob is CoachFramesBlob ? blob : null;
    } catch (e) {
      AppLogger.warning('Failed to parse CoachFramesBlob: $e', tag: 'ClientPoseRepo');
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
ClientPoseRepository clientPoseRepository(Ref ref) {
  return ClientPoseRepository(
    apiClient: ref.watch(apiClientProvider),
    cache: ref.watch(cacheServiceProvider),
  );
}
