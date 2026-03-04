import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

/// Muscle Group enum
enum MuscleGroup {
  @JsonValue('TRAPS')
  traps,
  @JsonValue('SHOULDERS')
  shoulders,
  @JsonValue('CHEST')
  chest,
  @JsonValue('ABS')
  abs,
  @JsonValue('OBLIQUES')
  obliques,
  @JsonValue('UPPER_BACK')
  upperBack,
  @JsonValue('LATS')
  lats,
  @JsonValue('LOWER_BACK')
  lowerBack,
  @JsonValue('BICEPS')
  biceps,
  @JsonValue('TRICEPS')
  triceps,
  @JsonValue('FOREARMS')
  forearms,
  @JsonValue('GLUTES')
  glutes,
  @JsonValue('QUADS')
  quads,
  @JsonValue('HAMSTRINGS')
  hamstrings,
  @JsonValue('CALVES')
  calves,
}

/// Extension for display names
extension MuscleGroupX on MuscleGroup {
  String get displayName => switch (this) {
    MuscleGroup.traps => 'Traps',
    MuscleGroup.shoulders => 'Shoulders',
    MuscleGroup.chest => 'Chest',
    MuscleGroup.abs => 'Abs',
    MuscleGroup.obliques => 'Obliques',
    MuscleGroup.upperBack => 'Upper Back',
    MuscleGroup.lats => 'Lats',
    MuscleGroup.lowerBack => 'Lower Back',
    MuscleGroup.biceps => 'Biceps',
    MuscleGroup.triceps => 'Triceps',
    MuscleGroup.forearms => 'Forearms',
    MuscleGroup.glutes => 'Glutes',
    MuscleGroup.quads => 'Quads',
    MuscleGroup.hamstrings => 'Hamstrings',
    MuscleGroup.calves => 'Calves',
  };
}

/// Exercise Model
///
/// Represents an exercise in the Get Gains application.
@freezed
abstract class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    required String id,
    required String name,
    required String description,
    required MuscleGroup primaryMuscleGroup,
    @Default([]) List<String> equipmentNeeded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);
}

/// Routine Exercise Model
///
/// An exercise within a routine with prescribed sets/reps (the template).
@freezed
abstract class RoutineExerciseModel with _$RoutineExerciseModel {
  const factory RoutineExerciseModel({
    required String id,
    String? routineId,
    required String exerciseId,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
    String? notes,
    ExerciseModel? exercise,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoutineExerciseModel;

  factory RoutineExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineExerciseModelFromJson(json);
}
