import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../workout/data/models/exercise_model.dart';
import 'models/models.dart';

part 'coach_pose_repository.g.dart';

/// Repository for coach pose-related operations.
///
/// Handles API calls for:
/// - Exercise CRUD
/// - Form upload, list, delete
/// - Form download URL retrieval
class CoachPoseRepository {
  CoachPoseRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============== Exercise Operations ==============

  /// Get exercises from server with optional search/filter
  Future<Result<List<ExerciseModel>, AppError>> getExercises({
    String? search,
    String? muscleGroup,
    bool onlyMine = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (muscleGroup != null) queryParams['muscleGroup'] = muscleGroup;
    if (onlyMine) queryParams['onlyMine'] = 'true';

    final result = await _apiClient.get<Map<String, dynamic>>(
      '/workout/exercises',
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final exercises = (data['exercises'] as List)
              .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Success(exercises);
        } catch (e) {
          AppLogger.error(
            'Failed to parse exercises',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(
            UnknownError(message: 'Failed to parse exercises: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Create a new exercise
  Future<Result<ExerciseModel, AppError>> createExercise({
    required String name,
    required String description,
    required String primaryMuscleGroup,
    List<String> targetMuscles = const [],
    List<String> equipmentNeeded = const [],
    bool isPublic = true,
  }) async {
    final normalizedTargetMuscles = <String>{
      primaryMuscleGroup.toUpperCase(),
      ...targetMuscles.map((muscle) => muscle.toUpperCase()),
    }.toList(growable: false);

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/workout/exercises',
      data: {
        'name': name,
        'description': description,
        'target_muscles': normalizedTargetMuscles,
        'is_public': isPublic,

        // Backward compatibility for environments still expecting camelCase.
        'primaryMuscleGroup': primaryMuscleGroup,
        'targetMuscles': normalizedTargetMuscles,
        'equipmentNeeded': equipmentNeeded,
      },
    );

    return result.when(
      success: (data) {
        try {
          final exercise = ExerciseModel.fromJson(
            data['exercise'] as Map<String, dynamic>,
          );
          return Success(exercise);
        } catch (e) {
          AppLogger.error(
            'Failed to parse created exercise',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse exercise: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Update an existing exercise
  Future<Result<ExerciseModel, AppError>> updateExercise({
    required String exerciseId,
    String? name,
    String? description,
    String? primaryMuscleGroup,
    List<String>? targetMuscles,
    List<String>? equipmentNeeded,
    bool? isPublic,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isPublic != null) data['is_public'] = isPublic;

    if (primaryMuscleGroup != null || targetMuscles != null) {
      final normalizedTargetMuscles = <String>{
        if (primaryMuscleGroup != null) primaryMuscleGroup.toUpperCase(),
        ...(targetMuscles ?? []).map((m) => m.toUpperCase()),
      }.toList(growable: false);

      data['target_muscles'] = normalizedTargetMuscles;

      // Backward compatibility
      if (primaryMuscleGroup != null)
        data['primaryMuscleGroup'] = primaryMuscleGroup;
      data['targetMuscles'] = normalizedTargetMuscles;
    }

    if (equipmentNeeded != null) data['equipmentNeeded'] = equipmentNeeded;

    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/workout/exercises/$exerciseId',
      data: data,
    );

    return result.when(
      success: (data) {
        try {
          final exercise = ExerciseModel.fromJson(
            data['exercise'] as Map<String, dynamic>,
          );
          return Success(exercise);
        } catch (e) {
          AppLogger.error(
            'Failed to parse updated exercise',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse exercise: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Delete an exercise
  Future<Result<void, AppError>> deleteExercise(String exerciseId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/workout/exercises/$exerciseId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }

  // ============== Form Operations ==============

  /// Get all forms for a specific exercise
  Future<Result<List<ExerciseFormModel>, AppError>> getExerciseForms(
    String exerciseId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/exercises/$exerciseId/forms',
    );

    return result.when(
      success: (data) {
        try {
          final forms = (data['forms'] as List)
              .map((f) => ExerciseFormModel.fromJson(f as Map<String, dynamic>))
              .toList();
          return Success(forms);
        } catch (e) {
          AppLogger.error(
            'Failed to parse forms',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse forms: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Upload a new reference form.
  ///
  /// The rich frame data (landmarks, features, etc.) is already in S3
  /// via [FramesUploadService]. This call only sends the lightweight
  /// metadata + the S3 key to the server.
  Future<Result<ExerciseFormModel, AppError>> uploadForm({
    required String exerciseId,
    required String cameraAngle,
    required String recordedFramesKey,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/pose/forms',
      data: {
        'exerciseId': exerciseId,
        'cameraAngle': cameraAngle,
        'recorded_frames_key': recordedFramesKey,
      },
    );

    return result.when(
      success: (data) {
        try {
          final form = ExerciseFormModel.fromJson(
            data['form'] as Map<String, dynamic>,
          );
          return Success(form);
        } catch (e) {
          AppLogger.error(
            'Failed to parse uploaded form',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse form: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Delete a form
  Future<Result<void, AppError>> deleteForm(String formId) async {
    final result = await _apiClient.delete<Map<String, dynamic>>(
      '/pose/forms/$formId',
    );

    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }

  /// Get a presigned download URL for a form's frames blob in S3.
  Future<Result<String, AppError>> getFormDownloadUrl(String formId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.poseFormDownloadUrl(formId),
    );

    return result.when(
      success: (data) {
        final url = data['url'] as String;
        return Success(url);
      },
      failure: (error) => Failure(error),
    );
  }
}

/// Provider for CoachPoseRepository
@Riverpod(keepAlive: true)
CoachPoseRepository coachPoseRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CoachPoseRepository(apiClient: apiClient);
}
