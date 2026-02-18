import 'dart:math' as math;

import '../../../core/utils/logger.dart';
import '../../coach_pose/data/models/feature_frame_model.dart';
import '../data/models/models.dart';

/// Compares client's recorded form against coach's reference form using
/// Dynamic Time Warping (DTW) on extracted joint angle features.
///
/// DTW handles different movement speeds by finding the optimal alignment
/// between two time series, giving a similarity score independent of tempo.
class FormComparisonService {
  FormComparisonService();

  /// Compare client frames against reference (coach) frames.
  ///
  /// Returns a [ComparisonResultModel] with:
  /// - overallScore (0.0 - 1.0, higher = better match)
  /// - segmentScores per tracked angle
  /// - corrections for angles that deviate significantly
  ComparisonResultModel compare({
    required String exerciseFormId,
    required List<FeatureFrame> referenceFrames,
    required List<FeatureFrame> clientFrames,
    required String cameraAngle,
    String? workoutSessionId,
    String? routineExerciseId,
    double? avgLandmarkConfidence,
  }) {
    AppLogger.info(
      'Starting form comparison: ${referenceFrames.length} ref frames, '
      '${clientFrames.length} client frames',
      tag: 'FormComparison',
    );

    if (referenceFrames.isEmpty || clientFrames.isEmpty) {
      return ComparisonResultModel(
        exerciseFormId: exerciseFormId,
        workoutSessionId: workoutSessionId,
        routineExerciseId: routineExerciseId,
        overallScore: 0.0,
        segmentScores: {},
        corrections: [],
        cameraAngle: cameraAngle,
        durationMs: 0,
        frameRate: 0,
        totalFrames: clientFrames.length,
        avgLandmarkConfidence: avgLandmarkConfidence,
      );
    }

    // Collect all angle names present in both sequences
    final refAngles = _collectAngleNames(referenceFrames);
    final clientAngles = _collectAngleNames(clientFrames);
    final commonAngles = refAngles.intersection(clientAngles);

    if (commonAngles.isEmpty) {
      AppLogger.warning(
        'No common angles between reference and client',
        tag: 'FormComparison',
      );
      return ComparisonResultModel(
        exerciseFormId: exerciseFormId,
        workoutSessionId: workoutSessionId,
        routineExerciseId: routineExerciseId,
        overallScore: 0.0,
        segmentScores: {},
        corrections: [],
        cameraAngle: cameraAngle,
        durationMs: _computeDurationMs(clientFrames),
        frameRate: _computeFrameRate(clientFrames),
        totalFrames: clientFrames.length,
        avgLandmarkConfidence: avgLandmarkConfidence,
      );
    }

    // Compute DTW score per angle
    final segmentScores = <String, double>{};
    final corrections = <CorrectionModel>[];

    for (final angleName in commonAngles) {
      final refSeries = _extractAngleSeries(referenceFrames, angleName);
      final clientSeries = _extractAngleSeries(clientFrames, angleName);

      if (refSeries.length < 2 || clientSeries.length < 2) continue;

      final dtwDistance = _dtw(refSeries, clientSeries);

      // Normalize DTW distance to a 0-1 score
      // Max reasonable deviation per frame pair is ~180 degrees
      final maxPossibleDistance =
          180.0 * math.max(refSeries.length, clientSeries.length);
      final score = 1.0 - (dtwDistance / maxPossibleDistance).clamp(0.0, 1.0);
      segmentScores[angleName] = score;

      // Generate correction if score is below threshold
      if (score < 0.7) {
        final avgDev =
            dtwDistance / math.max(refSeries.length, clientSeries.length);
        final maxDev = _maxDeviation(refSeries, clientSeries);
        final direction = _inferDirection(refSeries, clientSeries);
        final segment = _angleToSegment(angleName);

        corrections.add(
          CorrectionModel(
            angleName: angleName,
            segment: segment,
            avgDeviation: avgDev,
            maxDeviation: maxDev,
            direction: direction,
            message: _generateCorrectionMessage(angleName, direction, avgDev),
          ),
        );
      }
    }

    // Overall score is weighted average of angles
    final overallScore = segmentScores.isEmpty
        ? 0.0
        : segmentScores.values.reduce((a, b) => a + b) / segmentScores.length;

    final result = ComparisonResultModel(
      exerciseFormId: exerciseFormId,
      workoutSessionId: workoutSessionId,
      routineExerciseId: routineExerciseId,
      overallScore: overallScore,
      segmentScores: segmentScores,
      corrections: corrections,
      cameraAngle: cameraAngle,
      durationMs: _computeDurationMs(clientFrames),
      frameRate: _computeFrameRate(clientFrames),
      totalFrames: clientFrames.length,
      avgLandmarkConfidence: avgLandmarkConfidence,
    );

    AppLogger.info(
      'Comparison complete: overall=${(overallScore * 100).toStringAsFixed(1)}%, '
      '${corrections.length} corrections',
      tag: 'FormComparison',
    );

    return result;
  }

  /// Classic DTW algorithm — returns accumulated distance
  double _dtw(List<double> s, List<double> t) {
    final n = s.length;
    final m = t.length;
    final dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );
    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = (s[i - 1] - t[j - 1]).abs();
        dtw[i][j] =
            cost +
            [
              dtw[i - 1][j], // insertion
              dtw[i][j - 1], // deletion
              dtw[i - 1][j - 1], // match
            ].reduce(math.min);
      }
    }

    return dtw[n][m];
  }

  Set<String> _collectAngleNames(List<FeatureFrame> frames) {
    final names = <String>{};
    for (final f in frames) {
      names.addAll(f.angles.keys);
    }
    return names;
  }

  List<double> _extractAngleSeries(List<FeatureFrame> frames, String name) {
    return frames
        .where((f) => f.angles.containsKey(name))
        .map((f) => f.angles[name]!)
        .toList();
  }

  double _maxDeviation(List<double> ref, List<double> client) {
    double maxDev = 0;
    final len = math.min(ref.length, client.length);
    for (int i = 0; i < len; i++) {
      maxDev = math.max(maxDev, (ref[i] - client[i]).abs());
    }
    return maxDev;
  }

  String _inferDirection(List<double> ref, List<double> client) {
    final len = math.min(ref.length, client.length);
    double totalDiff = 0;
    for (int i = 0; i < len; i++) {
      totalDiff += client[i] - ref[i];
    }
    final avgDiff = totalDiff / len;

    if (avgDiff > 5) return 'too_extended';
    if (avgDiff < -5) return 'too_shallow';
    return 'inconsistent';
  }

  String _angleToSegment(String angleName) {
    if (angleName.contains('Knee') || angleName.contains('Ankle')) {
      return angleName.startsWith('left') ? 'LEFT_LEG' : 'RIGHT_LEG';
    }
    if (angleName.contains('Hip')) return 'TORSO';
    if (angleName.contains('Elbow') || angleName.contains('Shoulder')) {
      return angleName.startsWith('left') ? 'LEFT_ARM' : 'RIGHT_ARM';
    }
    if (angleName.contains('torso')) return 'TORSO';
    return 'FULL_BODY';
  }

  String _generateCorrectionMessage(
    String angleName,
    String direction,
    double avgDev,
  ) {
    final anglePretty = angleName
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)!.toLowerCase()}',
        )
        .trim();

    return switch (direction) {
      'too_extended' =>
        'Your $anglePretty is too extended by ~${avgDev.toStringAsFixed(0)}°. Try to match the coach\'s range.',
      'too_shallow' =>
        'Your $anglePretty is too shallow by ~${avgDev.toStringAsFixed(0)}°. Try deeper movement.',
      _ =>
        'Your $anglePretty movement pattern differs from the coach by ~${avgDev.toStringAsFixed(0)}°.',
    };
  }

  int _computeDurationMs(List<FeatureFrame> frames) {
    if (frames.length < 2) return 0;
    return frames.last.timestampMs - frames.first.timestampMs;
  }

  int _computeFrameRate(List<FeatureFrame> frames) {
    if (frames.length < 2) return 0;
    final durationS = _computeDurationMs(frames) / 1000.0;
    if (durationS <= 0) return 0;
    return (frames.length / durationS).round();
  }
}
