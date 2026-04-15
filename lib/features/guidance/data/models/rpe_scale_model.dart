import 'package:freezed_annotation/freezed_annotation.dart';

part 'rpe_scale_model.freezed.dart';
part 'rpe_scale_model.g.dart';

/// Structured data for the RPE (Rate of Perceived Exertion) explanation.
@freezed
abstract class RpeScaleModel with _$RpeScaleModel {
  const factory RpeScaleModel({
    /// RPE numeric value (1-10)
    required int level,

    /// Short effort label
    required String label,

    /// Brief description of what this level feels like
    required String description,
  }) = _RpeScaleModel;

  factory RpeScaleModel.fromJson(Map<String, dynamic> json) =>
      _$RpeScaleModelFromJson(json);
}
