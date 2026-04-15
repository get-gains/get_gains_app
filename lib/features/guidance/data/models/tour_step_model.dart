import 'package:freezed_annotation/freezed_annotation.dart';

part 'tour_step_model.freezed.dart';
part 'tour_step_model.g.dart';

/// Represents a single step in a multi-step spotlight tour.
@freezed
abstract class TourStepModel with _$TourStepModel {
  const factory TourStepModel({
    /// Unique key matching the GlobalKey name on the target widget
    required String targetKey,

    /// Short title displayed in the tooltip (bold)
    required String title,

    /// 1-2 sentence explanation displayed in the tooltip body
    required String body,

    /// Zero-based step order within the tour
    required int order,

    /// Optional action label override (default: "Next", last step: "Done")
    String? actionLabel,

    /// Whether to scroll the target into view before highlighting
    @Default(false) bool requiresScroll,
  }) = _TourStepModel;

  factory TourStepModel.fromJson(Map<String, dynamic> json) =>
      _$TourStepModelFromJson(json);
}
