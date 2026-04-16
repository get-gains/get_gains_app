import 'package:freezed_annotation/freezed_annotation.dart';

import 'exercise_model.dart';

part 'routine_model.freezed.dart';
part 'routine_model.g.dart';

/// Routine Model
///
/// Represents a workout routine containing multiple exercises.
/// When created by a coach, [coachId] is populated with the owning coach's ID.
@freezed
abstract class RoutineModel with _$RoutineModel {
  const factory RoutineModel({
    required String id,
    String? coachId,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,
    @Default([]) List<RoutineExerciseModel> exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoutineModel;

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    final normalizedJson = Map<String, dynamic>.from(json);

    normalizedJson['coachId'] ??=
        normalizedJson['coach_id'] ??
        normalizedJson['userId'] ??
        normalizedJson['user_id'];
    normalizedJson['estimatedDurationMinutes'] ??=
        normalizedJson['estimated_duration_minutes'];
    normalizedJson['muscleGroupsTargeted'] = normalizeMuscleGroupApiList(
      normalizedJson['muscleGroupsTargeted'] ??
          normalizedJson['muscle_groups_targeted'],
    );
    normalizedJson['exercises'] ??= const [];
    normalizedJson['createdAt'] ??= normalizedJson['created_at'];
    normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];

    return _$RoutineModelFromJson(normalizedJson);
  }
}

/// Extension for routine completion status
extension RoutineModelX on RoutineModel {
  /// Total number of exercises in this routine
  int get totalExercises => exercises.length;

  /// Total number of sets across all exercises
  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.sets);
}
