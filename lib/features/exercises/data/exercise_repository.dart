import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../workout/data/models/exercise_model.dart';

part 'exercise_repository.g.dart';

/// Shared repository for exercise creation, used by both coach and free-tier
/// self-program flows.
///
/// Backed by `POST /workout/exercises` which is open to any authenticated user.
class ExerciseRepository {
  ExerciseRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Create a new exercise.
  ///
  /// @param name Display name of the exercise (min 3 chars).
  /// @param description Brief description of the movement.
  /// @param primaryMuscleGroup Uppercase muscle-group enum string (e.g. `CHEST`).
  /// @param targetMuscles Additional muscles targeted (uppercased automatically).
  /// @param equipmentNeeded List of equipment item strings.
  /// @returns The created [ExerciseModel] on success, or an [AppError] on failure.
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
        'is_public': false, // user-created exercises are private by default

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
            tag: 'ExerciseRepo',
            error: e,
          );
          return Failure(UnknownError(message: 'Failed to parse exercise: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }
}

/// Singleton provider for [ExerciseRepository].
@Riverpod(keepAlive: true)
ExerciseRepository exerciseRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExerciseRepository(apiClient: apiClient);
}
