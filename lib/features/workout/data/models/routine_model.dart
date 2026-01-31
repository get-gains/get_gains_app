import 'package:freezed_annotation/freezed_annotation.dart';

import 'exercise_model.dart';

part 'routine_model.freezed.dart';
part 'routine_model.g.dart';

/// Routine Model
///
/// Represents a workout routine containing multiple exercises.
@freezed
abstract class RoutineModel with _$RoutineModel {
  const factory RoutineModel({
    required String id,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,
    @Default([]) List<RoutineExerciseModel> exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoutineModel;

  factory RoutineModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineModelFromJson(json);
}

/// Extension for routine completion status
extension RoutineModelX on RoutineModel {
  /// Total number of exercises in this routine
  int get totalExercises => exercises.length;

  /// Total number of sets across all exercises
  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.sets);
}
