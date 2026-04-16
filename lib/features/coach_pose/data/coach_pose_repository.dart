import 'package:riverpod_annotation/riverpod_annotation.dart';

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
/// - Form upload, list, delete, activate
/// - Pose config management
class CoachPoseRepository {
  CoachPoseRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============== Exercise Operations ==============

  /// Get exercises from server with optional search/filter
  Future<Result<List<ExerciseModel>, AppError>> getExercises({
    String? search,
    String? muscleGroup,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (muscleGroup != null) queryParams['muscleGroup'] = muscleGroup;

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
        'is_public': true,

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

  // ============== Form Operations ==============

  /// Get all forms for a specific exercise
  Future<Result<List<ExerciseFormModel>, AppError>> getExerciseForms(
    String exerciseId, {
    bool activeOnly = false,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/exercises/$exerciseId/forms',
      queryParameters: {'activeOnly': activeOnly},
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

  /// Get a specific form by ID (full detail with landmark data)
  Future<Result<ExerciseFormDetailModel, AppError>> getFormById(
    String formId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/pose/forms/$formId',
    );

    return result.when(
      success: (data) {
        try {
          final form = ExerciseFormDetailModel.fromJson(
            data['form'] as Map<String, dynamic>,
          );
          return Success(form);
        } catch (e) {
          AppLogger.error(
            'Failed to parse form detail',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse form: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Upload a new reference form
  Future<Result<ExerciseFormModel, AppError>> uploadForm({
    required String exerciseId,
    required String cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    required List<Map<String, dynamic>> landmarkFrames,
    required List<Map<String, dynamic>> featureFrames,
    List<Map<String, dynamic>>? normalizedFrames,
    List<String>? relevantAngles,
    double? avgLandmarkConfidence,
    String? recordingQuality,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/pose/forms',
      data: {
        'exerciseId': exerciseId,
        'cameraAngle': cameraAngle,
        'durationMs': durationMs,
        'frameRate': frameRate,
        'totalFrames': totalFrames,
        'landmarkFrames': landmarkFrames,
        'featureFrames': featureFrames,
        if (normalizedFrames != null) 'normalizedFrames': normalizedFrames,
        if (relevantAngles != null) 'relevantAngles': relevantAngles,
        if (avgLandmarkConfidence != null)
          'avgLandmarkConfidence': avgLandmarkConfidence,
        if (recordingQuality != null) 'recordingQuality': recordingQuality,
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

  /// Activate a specific form version
  Future<Result<ExerciseFormModel, AppError>> activateForm(
    String formId,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      '/pose/forms/$formId/activate',
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
            'Failed to parse activated form',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse form: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Pose Config Operations ==============

  /// Create or update pose config for an exercise
  Future<Result<PoseConfigModel, AppError>> upsertPoseConfig(
    String exerciseId, {
    required List<String> activeSegments,
    required List<String> recommendedAngles,
    required List<Map<String, dynamic>> trackedAngles,
    double minLandmarkConfidence = 0.5,
    String? setupInstructions,
  }) async {
    final result = await _apiClient.put<Map<String, dynamic>>(
      '/pose/exercises/$exerciseId/config',
      data: {
        'activeSegments': activeSegments,
        'recommendedAngles': recommendedAngles,
        'trackedAngles': trackedAngles,
        'minLandmarkConfidence': minLandmarkConfidence,
        if (setupInstructions != null) 'setupInstructions': setupInstructions,
      },
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
            'Failed to parse upserted pose config',
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse config: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get pose config for an exercise.
  ///
  /// Returns `null` inside [Success] when the server responds with 404
  /// (config doesn't exist yet). This is expected for newly-created
  /// exercises that have never had a config set.
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
            tag: 'CoachPoseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse config: $e'));
        }
      },
      failure: (error) {
        // 404 means no config exists yet — perfectly normal for new exercises
        if (error is NetworkError && error.statusCode == 404) {
          AppLogger.debug(
            'No pose config exists yet for exercise $exerciseId',
            tag: 'CoachPoseRepo',
          );
          return const Success(null);
        }
        return Failure(error);
      },
    );
  }
}

/// Provider for CoachPoseRepository
@Riverpod(keepAlive: true)
CoachPoseRepository coachPoseRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CoachPoseRepository(apiClient: apiClient);
}
