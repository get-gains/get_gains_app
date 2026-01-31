part of 'exercise_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseModel _$ExerciseModelFromJson(Map<String, dynamic> json) =>
    _ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      primaryMuscleGroup: $enumDecode(
        _$MuscleGroupEnumMap,
        json['primaryMuscleGroup'],
      ),
      equipmentNeeded:
          (json['equipmentNeeded'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ExerciseModelToJson(_ExerciseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'primaryMuscleGroup': _$MuscleGroupEnumMap[instance.primaryMuscleGroup]!,
      'equipmentNeeded': instance.equipmentNeeded,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$MuscleGroupEnumMap = {
  MuscleGroup.traps: 'TRAPS',
  MuscleGroup.shoulders: 'SHOULDERS',
  MuscleGroup.chest: 'CHEST',
  MuscleGroup.abs: 'ABS',
  MuscleGroup.obliques: 'OBLIQUES',
  MuscleGroup.upperBack: 'UPPER_BACK',
  MuscleGroup.lats: 'LATS',
  MuscleGroup.lowerBack: 'LOWER_BACK',
  MuscleGroup.biceps: 'BICEPS',
  MuscleGroup.triceps: 'TRICEPS',
  MuscleGroup.forearms: 'FOREARMS',
  MuscleGroup.glutes: 'GLUTES',
  MuscleGroup.quads: 'QUADS',
  MuscleGroup.hamstrings: 'HAMSTRINGS',
  MuscleGroup.calves: 'CALVES',
};

_RoutineExerciseModel _$RoutineExerciseModelFromJson(
  Map<String, dynamic> json,
) => _RoutineExerciseModel(
  id: json['id'] as String,
  routineId: json['routineId'] as String,
  exerciseId: json['exerciseId'] as String,
  sets: (json['sets'] as num).toInt(),
  repsMin: (json['repsMin'] as num).toInt(),
  repsMax: (json['repsMax'] as num).toInt(),
  restSeconds: (json['restSeconds'] as num).toInt(),
  orderInRoutine: (json['orderInRoutine'] as num).toInt(),
  notes: json['notes'] as String?,
  exercise: json['exercise'] == null
      ? null
      : ExerciseModel.fromJson(json['exercise'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RoutineExerciseModelToJson(
  _RoutineExerciseModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'routineId': instance.routineId,
  'exerciseId': instance.exerciseId,
  'sets': instance.sets,
  'repsMin': instance.repsMin,
  'repsMax': instance.repsMax,
  'restSeconds': instance.restSeconds,
  'orderInRoutine': instance.orderInRoutine,
  'notes': instance.notes,
  'exercise': instance.exercise,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
