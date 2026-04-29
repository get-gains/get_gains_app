import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../data/exercise_repository.dart';

part 'create_exercise_notifier.g.dart';

/// State for creating a new exercise.
sealed class CreateExerciseState {
  const CreateExerciseState();
}

class CreateExerciseInitial extends CreateExerciseState {
  const CreateExerciseInitial();
}

class CreateExerciseLoading extends CreateExerciseState {
  const CreateExerciseLoading();
}

class CreateExerciseSuccess extends CreateExerciseState {
  const CreateExerciseSuccess({required this.exercise});
  final ExerciseModel exercise;
}

class CreateExerciseError extends CreateExerciseState {
  const CreateExerciseError({required this.message});
  final String message;
}

/// Manages exercise creation form submission.
///
/// Uses [ExerciseRepository] which calls the shared `POST /workout/exercises`
/// endpoint (open to all authenticated users, not just coaches).
@riverpod
class CreateExerciseNotifier extends _$CreateExerciseNotifier {
  @override
  CreateExerciseState build() => const CreateExerciseInitial();

  /// Submit a new exercise to the server.
  ///
  /// @param name Exercise display name (min 3 chars).
  /// @param description Brief description.
  /// @param primaryMuscleGroup The primary [MuscleGroup] enum value.
  /// @param targetMuscles Optional additional muscle strings.
  /// @param equipmentNeeded List of equipment item strings.
  Future<void> createExercise({
    required String name,
    required String description,
    required MuscleGroup primaryMuscleGroup,
    List<String> targetMuscles = const [],
    List<String> equipmentNeeded = const [],
  }) async {
    state = const CreateExerciseLoading();

    final repo = ref.read(exerciseRepositoryProvider);
    final result = await repo.createExercise(
      name: name,
      description: description,
      primaryMuscleGroup: primaryMuscleGroup.name.toUpperCase(),
      targetMuscles: targetMuscles,
      equipmentNeeded: equipmentNeeded,
    );

    result.when(
      success: (exercise) {
        AppLogger.info(
          'Exercise created: ${exercise.name}',
          tag: 'CreateExercise',
        );
        state = CreateExerciseSuccess(exercise: exercise);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to create exercise',
          tag: 'CreateExercise',
          error: error,
        );
        state = CreateExerciseError(message: error.message);
      },
    );
  }

  /// Reset to initial state (e.g., after dismissing error).
  void reset() {
    state = const CreateExerciseInitial();
  }
}
