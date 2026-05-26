import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

Map<String, dynamic> _normalizeExerciseModelJson(Map<String, dynamic> json) {
  final normalizedJson = Map<String, dynamic>.from(json);

  normalizedJson['primaryMuscleGroup'] =
      resolvePrimaryMuscleGroupApiValue(normalizedJson);
  normalizedJson['equipmentNeeded'] = normalizeStringList(
    normalizedJson['equipmentNeeded'] ?? normalizedJson['equipment_needed'],
  );
  normalizedJson['isPublic'] ??= normalizedJson['is_public'];
  normalizedJson['createdAt'] ??= normalizedJson['created_at'];
  normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];
  normalizedJson['description'] ??= '';

  return normalizedJson;
}

Map<String, dynamic> _normalizeRoutineExerciseModelJson(
  Map<String, dynamic> json,
) {
  final normalizedJson = Map<String, dynamic>.from(json);

  normalizedJson['routineId'] ??= normalizedJson['routine_id'];
  normalizedJson['exerciseId'] ??= normalizedJson['exercise_id'];
  normalizedJson['repsMin'] ??= normalizedJson['reps_min'];
  normalizedJson['repsMax'] ??= normalizedJson['reps_max'];
  normalizedJson['restSeconds'] ??= normalizedJson['rest_seconds'];
  normalizedJson['orderInRoutine'] ??= normalizedJson['order_in_routine'];
  normalizedJson['createdAt'] ??= normalizedJson['created_at'];
  normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];

  return normalizedJson;
}

const _supportedMuscleGroupValues = <String>{
  'TRAPS',
  'SHOULDERS',
  'CHEST',
  'ABS',
  'OBLIQUES',
  'UPPER_BACK',
  'LATS',
  'LOWER_BACK',
  'BICEPS',
  'TRICEPS',
  'FOREARMS',
  'GLUTES',
  'QUADS',
  'HAMSTRINGS',
  'CALVES',
};

String? normalizeMuscleGroupApiValue(dynamic value) {
  if (value == null) return null;

  final normalized = value.toString().trim().toUpperCase();
  if (normalized.isEmpty) return null;

  final token = normalized.replaceAll('-', '_').replaceAll(' ', '_');
  switch (token) {
    case 'UPPERBACK':
      return 'UPPER_BACK';
    case 'LOWERBACK':
      return 'LOWER_BACK';
  }

  if (_supportedMuscleGroupValues.contains(token)) {
    return token;
  }
  return null;
}

List<String> normalizeMuscleGroupApiList(dynamic value) {
  if (value is! List<dynamic>) return const [];
  return value
      .map(normalizeMuscleGroupApiValue)
      .whereType<String>()
      .toList(growable: false);
}

List<String> normalizeStringList(dynamic value) {
  if (value is! List<dynamic>) return const [];
  return value
      .where((item) => item != null)
      .map((item) => item.toString())
      .toList(growable: false);
}

String resolvePrimaryMuscleGroupApiValue(Map<String, dynamic> json) {
  final primary = normalizeMuscleGroupApiValue(
    json['primaryMuscleGroup'] ?? json['primary_muscle_group'],
  );
  if (primary != null) {
    return primary;
  }

  final targetMuscles = normalizeMuscleGroupApiList(
    json['targetMuscles'] ?? json['target_muscles'],
  );
  if (targetMuscles.isNotEmpty) {
    return targetMuscles.first;
  }

  return 'CHEST';
}

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
    @Default(false) bool isPublic,
    @Default([]) List<String> equipmentNeeded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(_normalizeExerciseModelJson(json));
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
      _$RoutineExerciseModelFromJson(_normalizeRoutineExerciseModelJson(json));
}
