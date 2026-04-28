import 'package:freezed_annotation/freezed_annotation.dart';

part 'segment_explanation_model.freezed.dart';
part 'segment_explanation_model.g.dart';

/// Help content specific to a body segment score in the results view.
@freezed
abstract class SegmentExplanationModel with _$SegmentExplanationModel {
  const factory SegmentExplanationModel({
    /// Body segment name (matches BodySegment enum)
    required String segmentName,

    /// Human-readable display name
    required String displayName,

    /// What this segment measures
    required String description,

    /// Tips for improving this segment's score
    required String improvementTip,
  }) = _SegmentExplanationModel;

  factory SegmentExplanationModel.fromJson(Map<String, dynamic> json) =>
      _$SegmentExplanationModelFromJson(json);
}
