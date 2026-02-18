import 'package:freezed_annotation/freezed_annotation.dart';

part 'correction_model.freezed.dart';
part 'correction_model.g.dart';

/// Correction feedback for a specific joint angle or body segment.
@freezed
abstract class CorrectionModel with _$CorrectionModel {
  const factory CorrectionModel({
    required String angleName, // "kneeFlexion"
    required String segment, // "LEFT_LEG"
    required double avgDeviation, // 12.5 degrees
    required double maxDeviation, // 25.0 degrees
    required String direction, // "too_shallow", "too_deep", "too_forward"
    required String message, // Human-readable correction tip
  }) = _CorrectionModel;

  factory CorrectionModel.fromJson(Map<String, dynamic> json) =>
      _$CorrectionModelFromJson(json);
}
