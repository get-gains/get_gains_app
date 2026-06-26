import '../../../workout/data/models/exercise_model.dart';
import '../models/standalone_program_model.dart';

extension StandaloneRoutineExerciseConversion on StandaloneRoutineExercise {
  RoutineExerciseModel toRoutineExerciseModel() {
    return RoutineExerciseModel(
      id: id,
      exerciseId: exerciseId,
      exercise: ExerciseModel(
        id: exerciseId,
        name: exerciseName,
        description: '',
        primaryMuscleGroup: MuscleGroup.chest,
      ),
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
      restSeconds: restSeconds,
      orderInRoutine: orderInRoutine,
    );
  }
}
