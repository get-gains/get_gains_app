import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../data/coach_pose_repository.dart';

part 'edit_exercise_provider.g.dart';

/// State for editing an exercise.
sealed class EditExerciseState {
  const EditExerciseState();
}

class EditExerciseInitial extends EditExerciseState {
  const EditExerciseInitial();
}

class EditExerciseLoading extends EditExerciseState {
  const EditExerciseLoading();
}

class EditExerciseSuccess extends EditExerciseState {
  const EditExerciseSuccess({required this.exercise});
  final ExerciseModel exercise;
}

class EditExerciseError extends EditExerciseState {
  const EditExerciseError({required this.message});
  final String message;
}

/// Manages exercise edit form submission.
@riverpod
class EditExerciseNotifier extends _$EditExerciseNotifier {
  @override
  EditExerciseState build() => const EditExerciseInitial();

  /// Submit an updated exercise to the server.
  Future<void> updateExercise({
    required String exerciseId,
    required String name,
    required String description,
    required MuscleGroup primaryMuscleGroup,
    List<String> targetMuscles = const [],
    List<String> equipmentNeeded = const [],
    bool? isPublic,
  }) async {
    state = const EditExerciseLoading();

    final repo = ref.read(coachPoseRepositoryProvider);
    final result = await repo.updateExercise(
      exerciseId: exerciseId,
      name: name,
      description: description,
      primaryMuscleGroup: primaryMuscleGroup.name.toUpperCase(),
      targetMuscles: targetMuscles,
      equipmentNeeded: equipmentNeeded,
      isPublic: isPublic,
    );

    result.when(
      success: (exercise) {
        AppLogger.info(
          'Exercise updated: ${exercise.name}',
          tag: 'EditExercise',
        );
        state = EditExerciseSuccess(exercise: exercise);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update exercise',
          tag: 'EditExercise',
          error: error,
        );
        state = EditExerciseError(message: error.message);
      },
    );
  }

  /// Reset to initial state (e.g., after dismissing error).
  void reset() {
    state = const EditExerciseInitial();
  }
}
