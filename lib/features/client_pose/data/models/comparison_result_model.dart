import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../coach_pose/data/models/landmark_models.dart';
import '../../../coach_pose/data/models/feature_frame_model.dart';
import 'correction_model.dart';

part 'comparison_result_model.freezed.dart';
part 'comparison_result_model.g.dart';

/// Result from comparing a client's recording to the coach's reference form.
///
/// No server round-trip — the full payload is uploaded as a [ClientFramesBlob]
/// to S3 and referenced via `performed_set.recorded_frames_key`.
@freezed
abstract class ComparisonResultModel with _$ComparisonResultModel {
  const factory ComparisonResultModel({
    required String exerciseFormId,
    String? workoutSessionId,
    String? routineExerciseId,
    required double overallScore, // 0.0 - 1.0
    required Map<String, double> segmentScores, // {"TORSO": 0.85, ...}
    required List<CorrectionModel> corrections,
    required String cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    double? avgLandmarkConfidence,
    List<LandmarkFrame>? clientLandmarkFrames,
    List<FeatureFrame>? clientFeatureFrames,
    // Enrichment from server history queries
    String? exerciseName,
    String? coachName,
  }) = _ComparisonResultModel;

  factory ComparisonResultModel.fromJson(Map<String, dynamic> json) =>
      _$ComparisonResultModelFromJson(json);
}
