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
  });
}
