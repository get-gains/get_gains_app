import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_form_model.freezed.dart';
part 'exercise_form_model.g.dart';

/// Camera angle enum matching server's CameraAngle
enum CameraAngle {
  @JsonValue('FRONT')
  front,
  @JsonValue('SIDE_LEFT')
  sideLeft,
  @JsonValue('SIDE_RIGHT')
  sideRight,
  @JsonValue('REAR')
  rear,
  @JsonValue('ANGLE_45_LEFT')
  angle45Left,
  @JsonValue('ANGLE_45_RIGHT')
  angle45Right,
}

extension CameraAngleX on CameraAngle {
  String get displayName => switch (this) {
    CameraAngle.front => 'Front',
    CameraAngle.sideLeft => 'Side Left',
    CameraAngle.sideRight => 'Side Right',
    CameraAngle.rear => 'Rear',
    CameraAngle.angle45Left => '45° Left',
    CameraAngle.angle45Right => '45° Right',
  };

  String get serverValue => switch (this) {
    CameraAngle.front => 'FRONT',
    CameraAngle.sideLeft => 'SIDE_LEFT',
    CameraAngle.sideRight => 'SIDE_RIGHT',
    CameraAngle.rear => 'REAR',
    CameraAngle.angle45Left => 'ANGLE_45_LEFT',
    CameraAngle.angle45Right => 'ANGLE_45_RIGHT',
  };
}

/// Coach reference form — matches server `exercise_form` table exactly.
///
/// Heavy data (landmarks, features, etc.) lives in S3 under
/// [recordedFramesKey] and is fetched separately via presigned URL.
@freezed
abstract class ExerciseFormModel with _$ExerciseFormModel {
  const factory ExerciseFormModel({
    required String id,
    @JsonKey(name: 'exercise_id') required String exerciseId,
    @JsonKey(name: 'camera_angle') required CameraAngle cameraAngle,
    @JsonKey(name: 'recorded_frames_key') String? recordedFramesKey,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ExerciseFormModel;

  factory ExerciseFormModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFormModelFromJson(json);
}
