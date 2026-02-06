import 'package:freezed_annotation/freezed_annotation.dart';

import 'landmark_models.dart';
import 'feature_frame_model.dart';

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

/// Coach reference form — list view (without heavy landmark data)
@freezed
abstract class ExerciseFormModel with _$ExerciseFormModel {
  const factory ExerciseFormModel({
    required String id,
    required String exerciseId,
    required String coachId,
    required CameraAngle cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    required int version,
    required bool isActive,
    double? avgLandmarkConfidence,
    String? recordingQuality,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciseFormModel;

  factory ExerciseFormModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFormModelFromJson(json);
}

/// Coach reference form — full detail with landmark and feature data
@freezed
abstract class ExerciseFormDetailModel with _$ExerciseFormDetailModel {
  const factory ExerciseFormDetailModel({
    required String id,
    required String exerciseId,
    required String coachId,
    required CameraAngle cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    required List<LandmarkFrame> landmarkFrames,
    required List<FeatureFrame> featureFrames,
    List<LandmarkFrame>? normalizedFrames,
    required int version,
    required bool isActive,
    double? avgLandmarkConfidence,
    String? recordingQuality,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciseFormDetailModel;

  factory ExerciseFormDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFormDetailModelFromJson(json);
}
