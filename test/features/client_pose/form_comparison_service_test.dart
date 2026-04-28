import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/client_pose/services/form_comparison_service.dart';
import 'package:get_gains_app/features/coach_pose/data/models/feature_frame_model.dart';
import 'package:get_gains_app/features/coach_pose/data/models/landmark_models.dart';
import 'package:get_gains_app/features/coach_pose/services/feature_extractor.dart';

/// Build a full-body [LandmarkFrame] with a simple squat-like pose.
///
/// [phase] in [0, 1] controls joint angles to simulate movement.
/// All coordinates are in normalized [0, 1] space (post-Fix 2).
LandmarkFrame _buildFullBodyFrame(int timestampMs, double phase) {
  // Simulate a squat: knees flex from 170° (standing) to ~90° (bottom)
  // phase 0 = standing, phase 1 = full squat
  final kneeAngle = 170.0 - 80.0 * phase; // 170° → 90°
  final hipAngle = 170.0 - 70.0 * phase; // 170° → 100°
  final kneeRad = kneeAngle * math.pi / 180.0;
  final hipRad = hipAngle * math.pi / 180.0;

  // Fixed torso at center
  const shoulderY = 0.3;
  const hipY = 0.55;
  const elbowOffset = 0.08;

  // Compute knee and ankle positions from hip using angles
  const upperLegLen = 0.18;
  const lowerLegLen = 0.18;

  final kneeY = hipY + upperLegLen * math.cos(hipRad - math.pi);
  final kneeX = 0.45 + upperLegLen * math.sin(hipRad - math.pi) * 0.1;

  final ankleY = kneeY + lowerLegLen * math.cos(kneeRad - math.pi);
  final ankleX = kneeX + lowerLegLen * math.sin(kneeRad - math.pi) * 0.1;

  return LandmarkFrame(
    timestampMs: timestampMs,
    landmarks: {
      'LEFT_SHOULDER': LandmarkPoint(
        x: 0.45,
        y: shoulderY,
        z: 0.0,
        confidence: 0.95,
      ),
      'RIGHT_SHOULDER': LandmarkPoint(
        x: 0.55,
        y: shoulderY,
        z: 0.0,
        confidence: 0.95,
      ),
      'LEFT_HIP': LandmarkPoint(x: 0.45, y: hipY, z: 0.0, confidence: 0.90),
      'RIGHT_HIP': LandmarkPoint(x: 0.55, y: hipY, z: 0.0, confidence: 0.90),
      'LEFT_ELBOW': LandmarkPoint(
        x: 0.45 - elbowOffset,
        y: shoulderY + 0.1,
        z: 0.0,
        confidence: 0.85,
      ),
      'RIGHT_ELBOW': LandmarkPoint(
        x: 0.55 + elbowOffset,
        y: shoulderY + 0.1,
        z: 0.0,
        confidence: 0.85,
      ),
      'LEFT_WRIST': LandmarkPoint(
        x: 0.45 - elbowOffset - 0.03,
        y: shoulderY + 0.2,
        z: 0.0,
        confidence: 0.80,
      ),
      'RIGHT_WRIST': LandmarkPoint(
        x: 0.55 + elbowOffset + 0.03,
        y: shoulderY + 0.2,
        z: 0.0,
        confidence: 0.80,
      ),
      'LEFT_KNEE': LandmarkPoint(x: kneeX, y: kneeY, z: 0.0, confidence: 0.85),
      'RIGHT_KNEE': LandmarkPoint(
        x: 1.0 - kneeX,
        y: kneeY,
        z: 0.0,
        confidence: 0.85,
      ),
      'LEFT_ANKLE': LandmarkPoint(
        x: ankleX,
        y: ankleY,
        z: 0.0,
        confidence: 0.80,
      ),
      'RIGHT_ANKLE': LandmarkPoint(
        x: 1.0 - ankleX,
        y: ankleY,
        z: 0.0,
        confidence: 0.80,
      ),
      'LEFT_FOOT_INDEX': LandmarkPoint(
        x: ankleX + 0.03,
        y: ankleY + 0.02,
        z: 0.0,
        confidence: 0.75,
      ),
      'RIGHT_FOOT_INDEX': LandmarkPoint(
        x: 1.0 - ankleX - 0.03,
        y: ankleY + 0.02,
        z: 0.0,
        confidence: 0.75,
      ),
    },
  );
}

/// Build a frame with LEFT_WRIST missing (for OOV tests).
LandmarkFrame _buildFrameMissingLeftWrist(int timestampMs, double phase) {
  final frame = _buildFullBodyFrame(timestampMs, phase);
  final landmarks = Map<String, LandmarkPoint>.from(frame.landmarks)
    ..remove('LEFT_WRIST');
  return LandmarkFrame(timestampMs: timestampMs, landmarks: landmarks);
}

/// Generate a sinusoidal squat sequence: stand → squat → stand over [numFrames].
List<LandmarkFrame> _generateSquatSequence(int numFrames, {int startMs = 0}) {
  return List.generate(numFrames, (i) {
    final t = i / math.max(1, numFrames - 1);
    // One full squat cycle: 0 → 1 → 0 via sin
    final phase = math.sin(t * math.pi);
    final timestampMs = startMs + (i * 1000 ~/ 30);
    return _buildFullBodyFrame(timestampMs, phase);
  });
}

/// Build a frame for an arm-dominant exercise (bicep curl-like).
///
/// [phase] sweeps the elbows through a large arc while legs stay static.
LandmarkFrame _buildArmExerciseFrame(int timestampMs, double phase) {
  const shoulderY = 0.3;
  const hipY = 0.55;

  // Elbows swing through large arc: 0.3 → 0.0 in Y (curl up)
  final elbowY = shoulderY + 0.15 - 0.15 * phase;
  // Wrists follow: 0.5 → 0.25 in Y
  final wristY = shoulderY + 0.25 - 0.25 * phase;

  return LandmarkFrame(
    timestampMs: timestampMs,
    landmarks: {
      'LEFT_SHOULDER': LandmarkPoint(
        x: 0.45,
        y: shoulderY,
        z: 0.0,
        confidence: 0.95,
      ),
      'RIGHT_SHOULDER': LandmarkPoint(
        x: 0.55,
        y: shoulderY,
        z: 0.0,
        confidence: 0.95,
      ),
      'LEFT_HIP': LandmarkPoint(x: 0.45, y: hipY, z: 0.0, confidence: 0.90),
      'RIGHT_HIP': LandmarkPoint(x: 0.55, y: hipY, z: 0.0, confidence: 0.90),
      'LEFT_ELBOW': LandmarkPoint(x: 0.40, y: elbowY, z: 0.0, confidence: 0.85),
      'RIGHT_ELBOW': LandmarkPoint(
        x: 0.60,
        y: elbowY,
        z: 0.0,
        confidence: 0.85,
      ),
      'LEFT_WRIST': LandmarkPoint(x: 0.38, y: wristY, z: 0.0, confidence: 0.80),
      'RIGHT_WRIST': LandmarkPoint(
        x: 0.62,
        y: wristY,
        z: 0.0,
        confidence: 0.80,
      ),
      'LEFT_KNEE': LandmarkPoint(x: 0.45, y: 0.75, z: 0.0, confidence: 0.85),
      'RIGHT_KNEE': LandmarkPoint(x: 0.55, y: 0.75, z: 0.0, confidence: 0.85),
      'LEFT_ANKLE': LandmarkPoint(x: 0.45, y: 0.92, z: 0.0, confidence: 0.80),
      'RIGHT_ANKLE': LandmarkPoint(x: 0.55, y: 0.92, z: 0.0, confidence: 0.80),
      'LEFT_FOOT_INDEX': LandmarkPoint(
        x: 0.48,
        y: 0.95,
        z: 0.0,
        confidence: 0.75,
      ),
      'RIGHT_FOOT_INDEX': LandmarkPoint(
        x: 0.52,
        y: 0.95,
        z: 0.0,
        confidence: 0.75,
      ),
    },
  );
}

/// Generate an arm curl sequence over [numFrames].
List<LandmarkFrame> _generateArmCurlSequence(int numFrames, {int startMs = 0}) {
  return List.generate(numFrames, (i) {
    final t = i / math.max(1, numFrames - 1);
    final phase = math.sin(t * math.pi);
    final timestampMs = startMs + (i * 1000 ~/ 30);
    return _buildArmExerciseFrame(timestampMs, phase);
  });
}

/// Generate a static-pose sequence: same posture for every frame.
List<LandmarkFrame> _generateStaticSequence(
  int numFrames, {
  int startMs = 0,
  double phase = 0.5,
}) {
  return List.generate(numFrames, (i) {
    final timestampMs = startMs + (i * 1000 ~/ 30);
    return _buildFullBodyFrame(timestampMs, phase);
  });
}

/// Generate an inverted squat: squat → stand → squat (opposite phase).
List<LandmarkFrame> _generateInvertedSquatSequence(
  int numFrames, {
  int startMs = 0,
}) {
  return List.generate(numFrames, (i) {
    final t = i / math.max(1, numFrames - 1);
    // Inverted: start at bottom (phase=1), go up (phase=0), back down
    final phase = math.cos(t * math.pi) * 0.5 + 0.5;
    final timestampMs = startMs + (i * 1000 ~/ 30);
    return _buildFullBodyFrame(timestampMs, phase);
  });
}

void main() {
  late FeatureExtractor featureExtractor;
  late FormComparisonService comparisonService;

  setUp(() {
    featureExtractor = FeatureExtractor();
    comparisonService = FormComparisonService();
  });

  group('FormComparisonService', () {
    test('Fixture 1: Identity — ref == client → high score, full coverage', () {
      // 60 frames of identical squat movement
      final landmarks = _generateSquatSequence(60);
      final features = featureExtractor.extractBatch(landmarks);

      final result = comparisonService.compare(
        exerciseFormId: 'test-form',
        referenceFrames: features,
        clientFrames: List.from(features), // exact copy
        cameraAngle: 'FRONT',
      );

      expect(result.overallScore, greaterThanOrEqualTo(0.95));

      // Every angle that exists in the reference should have 1.0 coverage
      if (result.angleCoverage != null) {
        for (final entry in result.angleCoverage!.entries) {
          expect(
            entry.value,
            equals(1.0),
            reason: '${entry.key} should have full coverage',
          );
        }
      }
    });

    test(
      'Fixture 2: Tempo half-speed — client 2× longer, same shape → score drops',
      () {
        // Reference: 60 frames
        final refLandmarks = _generateSquatSequence(60);
        final refFeatures = featureExtractor.extractBatch(refLandmarks);

        // Client: 120 frames, same movement stretched to 2× duration
        final clientLandmarks = _generateSquatSequence(120);
        final clientFeatures = featureExtractor.extractBatch(clientLandmarks);

        final result = comparisonService.compare(
          exerciseFormId: 'test-form',
          referenceFrames: refFeatures,
          clientFrames: clientFeatures,
          cameraAngle: 'FRONT',
        );

        // With Sakoe-Chiba band (Fix 5), a 2× tempo mismatch should score
        // significantly lower than identity. Without the band, DTW warps
        // freely and the score stays high — which is the bug.
        expect(result.overallScore, lessThan(0.90));
      },
    );

    test(
      'Fixture 3: OOV mid-sequence — LEFT_WRIST missing frames 20-40 of 60',
      () {
        // Reference: full body for all 60 frames
        final refLandmarks = _generateSquatSequence(60);
        final refFeatures = featureExtractor.extractBatch(refLandmarks);

        // Client: full body except LEFT_WRIST missing for frames 20-40
        final clientLandmarks = List.generate(60, (i) {
          final t = i / 59.0;
          final phase = math.sin(t * math.pi);
          final timestampMs = i * 1000 ~/ 30;
          if (i >= 20 && i < 40) {
            return _buildFrameMissingLeftWrist(timestampMs, phase);
          }
          return _buildFullBodyFrame(timestampMs, phase);
        });
        final clientFeatures = featureExtractor.extractBatch(clientLandmarks);

        final result = comparisonService.compare(
          exerciseFormId: 'test-form',
          referenceFrames: refFeatures,
          clientFrames: clientFeatures,
          cameraAngle: 'FRONT',
        );

        // leftElbowFlexion should have ~0.67 coverage (40 of 60 frames)
        if (result.angleCoverage != null) {
          final elbowCoverage = result.angleCoverage!['leftElbowFlexion'];
          expect(elbowCoverage, isNotNull);
          expect(elbowCoverage!, closeTo(0.67, 0.1));
        }

        // The angle should still be scored (coverage > 0.30)
        // Overall score should be reasonable, not artificially boosted
        expect(result.overallScore, greaterThan(0.0));
      },
    );

    test('Fixture 4: Total OOV — LEFT_WRIST missing entire sequence', () {
      // Reference: full body for 60 frames
      final refLandmarks = _generateSquatSequence(60);
      final refFeatures = featureExtractor.extractBatch(refLandmarks);

      // Client: LEFT_WRIST missing for ALL frames
      final clientLandmarks = List.generate(60, (i) {
        final t = i / 59.0;
        final phase = math.sin(t * math.pi);
        final timestampMs = i * 1000 ~/ 30;
        return _buildFrameMissingLeftWrist(timestampMs, phase);
      });
      final clientFeatures = featureExtractor.extractBatch(clientLandmarks);

      final result = comparisonService.compare(
        exerciseFormId: 'test-form',
        referenceFrames: refFeatures,
        clientFrames: clientFeatures,
        cameraAngle: 'FRONT',
      );

      // leftElbowFlexion should be excluded (coverage 0 < 0.30 threshold)
      if (result.angleCoverage != null) {
        final elbowCoverage = result.angleCoverage!['leftElbowFlexion'];
        if (elbowCoverage != null) {
          expect(elbowCoverage, equals(0.0));
        }
      }

      // Overall score should still be positive from other angles
      expect(result.overallScore, greaterThan(0.0));
    });

    test('empty frames return zero score', () {
      final result = comparisonService.compare(
        exerciseFormId: 'test-form',
        referenceFrames: [],
        clientFrames: [],
        cameraAngle: 'FRONT',
      );

      expect(result.overallScore, equals(0.0));
    });

    test(
      'Fixture 5: Wrong exercise — squat ref vs arm curl client → low score',
      () {
        // Reference: squat (leg-dominant)
        final refLandmarks = _generateSquatSequence(60);
        final refFeatures = featureExtractor.extractBatch(refLandmarks);

        // Client: arm curls (arm-dominant, legs static)
        final clientLandmarks = _generateArmCurlSequence(60);
        final clientFeatures = featureExtractor.extractBatch(clientLandmarks);

        final result = comparisonService.compare(
          exerciseFormId: 'test-form',
          referenceFrames: refFeatures,
          clientFrames: clientFeatures,
          cameraAngle: 'FRONT',
        );

        // Wrong exercise must score well below 50% — the ROM penalty and
        // Pearson correlation should crush the score.
        expect(
          result.overallScore,
          lessThanOrEqualTo(0.50),
          reason:
              'Wrong exercise should score ≤50%, got '
              '${(result.overallScore * 100).toStringAsFixed(1)}%',
        );
      },
    );

    test(
      'Fixture 6: Static client — ref full ROM squat, client holds mid-squat → low score',
      () {
        // Reference: dynamic squat
        final refLandmarks = _generateSquatSequence(60);
        final refFeatures = featureExtractor.extractBatch(refLandmarks);

        // Client: static mid-squat position for all frames
        final clientLandmarks = _generateStaticSequence(60);
        final clientFeatures = featureExtractor.extractBatch(clientLandmarks);

        final result = comparisonService.compare(
          exerciseFormId: 'test-form',
          referenceFrames: refFeatures,
          clientFrames: clientFeatures,
          cameraAngle: 'FRONT',
        );

        // Static client should score low: zero ROM → heavy ROM penalty,
        // zero variance → Pearson undefined (returns 0) → 0.5 multiplier.
        expect(
          result.overallScore,
          lessThanOrEqualTo(0.40),
          reason:
              'Static client should score ≤40%, got '
              '${(result.overallScore * 100).toStringAsFixed(1)}%',
        );
      },
    );

    test(
      'Fixture 7: Inverted pattern — same ROM, opposite phase → low score',
      () {
        // Reference: normal squat (stand → squat → stand)
        final refLandmarks = _generateSquatSequence(60);
        final refFeatures = featureExtractor.extractBatch(refLandmarks);

        // Client: inverted squat (squat → stand → squat)
        final clientLandmarks = _generateInvertedSquatSequence(60);
        final clientFeatures = featureExtractor.extractBatch(clientLandmarks);

        final result = comparisonService.compare(
          exerciseFormId: 'test-form',
          referenceFrames: refFeatures,
          clientFrames: clientFeatures,
          cameraAngle: 'FRONT',
        );

        // Inverted pattern has same ROM but Pearson ≈ -1 → 0.5 multiplier.
        // Score should be noticeably below identity.
        expect(
          result.overallScore,
          lessThanOrEqualTo(0.60),
          reason:
              'Inverted pattern should score ≤60%, got '
              '${(result.overallScore * 100).toStringAsFixed(1)}%',
        );
      },
    );
  });
}
