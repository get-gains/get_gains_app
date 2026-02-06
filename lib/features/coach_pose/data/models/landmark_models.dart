import 'package:freezed_annotation/freezed_annotation.dart';

part 'landmark_models.freezed.dart';
part 'landmark_models.g.dart';

/// A single pose landmark point (x, y, z, confidence)
@freezed
abstract class LandmarkPoint with _$LandmarkPoint {
  const factory LandmarkPoint({
    required double x, // Normalized 0.0-1.0
    required double y, // Normalized 0.0-1.0
    required double z, // Depth estimate
    required double confidence, // 0.0-1.0
  }) = _LandmarkPoint;

  factory LandmarkPoint.fromJson(Map<String, dynamic> json) =>
      _$LandmarkPointFromJson(json);
}

/// One frame of pose landmarks with timestamp
@freezed
abstract class LandmarkFrame with _$LandmarkFrame {
  const factory LandmarkFrame({
    required int timestampMs,
    required Map<String, LandmarkPoint> landmarks,
  }) = _LandmarkFrame;

  factory LandmarkFrame.fromJson(Map<String, dynamic> json) =>
      _$LandmarkFrameFromJson(json);
}
