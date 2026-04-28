import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../api/api_client.dart';

part 'frames_upload_service.g.dart';

/// Service for uploading pose-frames JSON blobs to S3 via presigned PUT URLs.
///
/// Flow:
/// 1. POST to server → get `{ key, url, expiresInSeconds }`
/// 2. PUT the JSON blob directly to S3 using a **bare** [Dio] instance
///    (must NOT use [ApiClient] — its [AuthInterceptor] would attach the
///    Supabase header, causing S3 to reject with `SignatureDoesNotMatch`).
/// 3. Return the S3 object key on success.
@Riverpod(keepAlive: true)
FramesUploadService framesUploadService(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return FramesUploadService(apiClient: apiClient);
}

class FramesUploadService {
  FramesUploadService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Bare Dio for S3 PUT — no auth interceptors.
  final Dio _s3Dio = Dio(
    BaseOptions(
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
    ),
  );

  /// Upload a coach form frames blob and return the S3 key.
  Future<Result<String, AppError>> uploadCoachFormFrames({
    required String exerciseId,
    required Map<String, dynamic> framesBlob,
  }) async {
    return _uploadFrames(
      body: {'kind': 'coach_form', 'exerciseId': exerciseId},
      framesBlob: framesBlob,
      tag: 'coach_form',
    );
  }

  /// Upload a client set frames blob and return the S3 key.
  Future<Result<String, AppError>> uploadClientSetFrames({
    required String workoutSessionId,
    required int setNumber,
    required Map<String, dynamic> framesBlob,
  }) async {
    return _uploadFrames(
      body: {
        'kind': 'client_set',
        'workoutSessionId': workoutSessionId,
        'setNumber': setNumber,
      },
      framesBlob: framesBlob,
      tag: 'client_set',
    );
  }

  Future<Result<String, AppError>> _uploadFrames({
    required Map<String, dynamic> body,
    required Map<String, dynamic> framesBlob,
    required String tag,
  }) async {
    // Step 1: Get presigned PUT URL from server
    final urlResult = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.poseFramesUploadUrl,
      data: body,
    );

    return urlResult.when(
      success: (data) async {
        final key = data['key'] as String;
        final url = data['url'] as String;

        // Step 2: PUT the JSON blob directly to S3 (bare Dio, no auth)
        try {
          final jsonBytes = utf8.encode(jsonEncode(framesBlob));

          await _s3Dio.put<void>(
            url,
            data: Stream.fromIterable([jsonBytes]),
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Content-Length': jsonBytes.length,
              },
            ),
          );

          AppLogger.info(
            'Frames blob uploaded to S3 ($tag)',
            tag: 'FramesUploadService',
          );

          return Success(key);
        } on DioException catch (e) {
          AppLogger.error(
            'S3 PUT failed ($tag)',
            tag: 'FramesUploadService',
            error: e,
          );
          return Failure(
            NetworkError(
              message: 'Failed to upload frames blob: ${e.message}',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) async => Failure(error),
    );
  }
}
