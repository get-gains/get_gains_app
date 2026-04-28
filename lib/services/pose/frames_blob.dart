import 'package:freezed_annotation/freezed_annotation.dart';

import '../../features/client_pose/data/models/correction_model.dart';
import '../../features/coach_pose/data/models/feature_frame_model.dart';
import '../../features/coach_pose/data/models/landmark_models.dart';

part 'frames_blob.freezed.dart';
part 'frames_blob.g.dart';

/// Sealed blob model for pose-frames JSON stored in S3.
///
/// Discriminated on [kind]:
/// - `coach` — reference form recorded by a coach
/// - `client` — comparison result recorded during a workout set
///
/// The JSON is uploaded/downloaded via presigned S3 URLs and never sent
/// inline to the server API.
@Freezed(unionKey: 'kind')
sealed class FramesBlob with _$FramesBlob {
  @FreezedUnionValue('coach')
  const factory FramesBlob.coach({
    required int version,
    required String cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    required List<LandmarkFrame> landmarkFrames,
    required List<FeatureFrame> featureFrames,
    List<LandmarkFrame>? normalizedFrames,
    List<String>? relevantAngles,
    double? avgLandmarkConfidence,
  }) = CoachFramesBlob;

  @FreezedUnionValue('client')
  const factory FramesBlob.client({
    required int version,
    required String cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    required List<LandmarkFrame> landmarkFrames,
    required List<FeatureFrame> featureFrames,
    required double overallScore,
    required Map<String, double> segmentScores,
    required List<CorrectionModel> corrections,
    List<LandmarkFrame>? normalizedFrames,
    List<String>? relevantAngles,
    double? avgLandmarkConfidence,
  }) = ClientFramesBlob;

  factory FramesBlob.fromJson(Map<String, dynamic> json) =>
      _$FramesBlobFromJson(json);
}
