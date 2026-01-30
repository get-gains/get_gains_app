part of 'routine_model.dart';

_RoutineModel _$RoutineModelFromJson(
  Map<String, dynamic> json,
) => _RoutineModel(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num).toInt(),
  muscleGroupsTargeted:
      (json['muscleGroupsTargeted'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
          .toList() ??
      const [],
  exercises:
      (json['exercises'] as List<dynamic>?)
          ?.map((e) => RoutineExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RoutineModelToJson(_RoutineModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'estimatedDurationMinutes': instance.estimatedDurationMinutes,
      'muscleGroupsTargeted': instance.muscleGroupsTargeted
          .map((e) => _$MuscleGroupEnumMap[e]!)
          .toList(),
      'exercises': instance.exercises,
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
