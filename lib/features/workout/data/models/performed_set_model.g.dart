part of 'performed_set_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PerformedSetModel _$PerformedSetModelFromJson(Map<String, dynamic> json) =>
    _PerformedSetModel(
      id: json['id'] as String,
      workoutSessionId: json['workoutSessionId'] as String,
      routineExerciseId: json['routineExerciseId'] as String,
      setNumber: (json['setNumber'] as num).toInt(),
      repsCompleted: (json['repsCompleted'] as num).toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      rpe: (json['rpe'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PerformedSetModelToJson(_PerformedSetModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workoutSessionId': instance.workoutSessionId,
      'routineExerciseId': instance.routineExerciseId,
      'setNumber': instance.setNumber,
      'repsCompleted': instance.repsCompleted,
      'weightKg': instance.weightKg,
      'rpe': instance.rpe,
      'notes': instance.notes,
      'isCompleted': instance.isCompleted,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
