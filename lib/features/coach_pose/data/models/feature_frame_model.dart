import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_frame_model.freezed.dart';
part 'feature_frame_model.g.dart';

/// Extracted joint angles and distances for a single frame
@freezed
abstract class FeatureFrame with _$FeatureFrame {
  const factory FeatureFrame({
    required int timestampMs,
    required Map<String, double> angles, // "kneeFlexion": 92.5
    @Default({}) Map<String, double> distances,
  }) = _FeatureFrame;

  factory FeatureFrame.fromJson(Map<String, dynamic> json) =>
      _$FeatureFrameFromJson(json);
}
