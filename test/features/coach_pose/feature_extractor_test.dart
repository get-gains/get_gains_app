import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/coach_pose/data/models/landmark_models.dart';
import 'package:get_gains_app/features/coach_pose/services/feature_extractor.dart';

void main() {
  late FeatureExtractor extractor;

  setUp(() {
    extractor = FeatureExtractor();
  });

  group('_calculateAngle via extractFrame', () {
    test('Fixture 5: known 3D angle — 90° right angle', () {
      // Place three landmarks forming a perfect 90° angle at the joint.
      // A = (1, 0, 0), B = (0, 0, 0), C = (0, 1, 0)
      // BA = (1, 0, 0), BC = (0, 1, 0) → dot = 0, angle = 90°
      final frame = LandmarkFrame(
        timestampMs: 0,
        landmarks: {
          'LEFT_SHOULDER': const LandmarkPoint(
            x: 1.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_ELBOW': const LandmarkPoint(
            x: 0.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_WRIST': const LandmarkPoint(
            x: 0.0,
            y: 1.0,
            z: 0.0,
            confidence: 1.0,
          ),
        },
      );

      final features = extractor.extractFrame(frame);
      expect(features.angles['leftElbowFlexion'], isNotNull);
      expect(features.angles['leftElbowFlexion']!, closeTo(90.0, 0.1));
    });

    test('Fixture 5b: known 3D angle — 180° straight line', () {
      // A = (-1, 0, 0), B = (0, 0, 0), C = (1, 0, 0)
      // BA = (-1, 0, 0), BC = (1, 0, 0) → dot = -1, angle = 180°
      final frame = LandmarkFrame(
        timestampMs: 0,
        landmarks: {
          'LEFT_SHOULDER': const LandmarkPoint(
            x: -1.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_ELBOW': const LandmarkPoint(
            x: 0.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_WRIST': const LandmarkPoint(
            x: 1.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
        },
      );

      final features = extractor.extractFrame(frame);
      expect(features.angles['leftElbowFlexion']!, closeTo(180.0, 0.1));
    });

    test('Fixture 5c: known 3D angle — 60° with z component', () {
      // A = (1, 0, 0), B = (0, 0, 0), C = (0.5, sqrt(3)/2, 0)
      // cos(60°) = 0.5, angle = 60°
      final frame = LandmarkFrame(
        timestampMs: 0,
        landmarks: {
          'LEFT_SHOULDER': const LandmarkPoint(
            x: 1.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_ELBOW': const LandmarkPoint(
            x: 0.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_WRIST': LandmarkPoint(
            x: 0.5,
            y: math.sqrt(3) / 2,
            z: 0.0,
            confidence: 1.0,
          ),
        },
      );

      final features = extractor.extractFrame(frame);
      expect(features.angles['leftElbowFlexion']!, closeTo(60.0, 0.1));
    });

    test('Fixture 5d: 3D angle uses z properly when all on same scale', () {
      // A = (1, 0, 0), B = (0, 0, 0), C = (0, 0, 1)
      // dot = 0, angle = 90°
      final frame = LandmarkFrame(
        timestampMs: 0,
        landmarks: {
          'LEFT_SHOULDER': const LandmarkPoint(
            x: 1.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_ELBOW': const LandmarkPoint(
            x: 0.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_WRIST': const LandmarkPoint(
            x: 0.0,
            y: 0.0,
            z: 1.0,
            confidence: 1.0,
          ),
        },
      );

      final features = extractor.extractFrame(frame);
      expect(features.angles['leftElbowFlexion']!, closeTo(90.0, 0.1));
    });

    test('missing landmark returns no angle', () {
      final frame = LandmarkFrame(
        timestampMs: 0,
        landmarks: {
          'LEFT_SHOULDER': const LandmarkPoint(
            x: 1.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          'LEFT_ELBOW': const LandmarkPoint(
            x: 0.0,
            y: 0.0,
            z: 0.0,
            confidence: 1.0,
          ),
          // LEFT_WRIST missing
        },
      );

      final features = extractor.extractFrame(frame);
      expect(features.angles.containsKey('leftElbowFlexion'), isFalse);
    });
  });
}
