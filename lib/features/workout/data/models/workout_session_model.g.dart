part of 'workout_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutSessionModel _$WorkoutSessionModelFromJson(Map<String, dynamic> json) =>
    _WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      assignedProgramId: json['assignedProgramId'] as String?,
      routineId: json['routineId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      notes: json['notes'] as String?,
      performedSets:
          (json['performedSets'] as List<dynamic>?)
              ?.map(
                (e) => PerformedSetModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$WorkoutSessionModelToJson(
  _WorkoutSessionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'assignedProgramId': instance.assignedProgramId,
  'routineId': instance.routineId,
  'startedAt': instance.startedAt.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'notes': instance.notes,
  'performedSets': instance.performedSets,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
