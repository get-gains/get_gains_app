import 'package:freezed_annotation/freezed_annotation.dart';

import 'exercise_form_model.dart';

part 'pose_config_model.freezed.dart';
part 'pose_config_model.g.dart';

/// Body segment enum matching server's BodySegment
enum BodySegment {
  @JsonValue('HEAD_NECK')
  headNeck,
  @JsonValue('LEFT_ARM')
  leftArm,
  @JsonValue('RIGHT_ARM')
  rightArm,
  @JsonValue('TORSO')
  torso,
  @JsonValue('LEFT_LEG')
  leftLeg,
  @JsonValue('RIGHT_LEG')
  rightLeg,
  @JsonValue('FULL_BODY')
  fullBody,
}

extension BodySegmentX on BodySegment {
  String get displayName => switch (this) {
    BodySegment.headNeck => 'Head & Neck',
    BodySegment.leftArm => 'Left Arm',
    BodySegment.rightArm => 'Right Arm',
    BodySegment.torso => 'Torso',
    BodySegment.leftLeg => 'Left Leg',
    BodySegment.rightLeg => 'Right Leg',
    BodySegment.fullBody => 'Full Body',
  };
}

/// Tracked angle definition
@freezed
abstract class TrackedAngle with _$TrackedAngle {
  const factory TrackedAngle({
    required String name, // "kneeFlexion"
    required List<String> landmarks, // ["LEFT_HIP", "LEFT_KNEE", "LEFT_ANKLE"]
    required double idealMin, // 80.0
    required double idealMax, // 100.0
  }) = _TrackedAngle;

  factory TrackedAngle.fromJson(Map<String, dynamic> json) =>
      _$TrackedAngleFromJson(json);
}

/// Per-exercise pose configuration
@freezed
abstract class PoseConfigModel with _$PoseConfigModel {
  const factory PoseConfigModel({
    required String id,
    required String exerciseId,
    required List<BodySegment> activeSegments,
    required List<CameraAngle> recommendedAngles,
    required List<TrackedAngle> trackedAngles,
    @Default(0.5) double minLandmarkConfidence,
    String? setupInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PoseConfigModel;

  factory PoseConfigModel.fromJson(Map<String, dynamic> json) =>
      _$PoseConfigModelFromJson(json);
}
