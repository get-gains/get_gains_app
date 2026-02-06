import 'dart:math' as math;

import '../../../core/utils/logger.dart';
import '../data/models/landmark_models.dart';
import '../data/models/feature_frame_model.dart';

/// Extracts meaningful features (joint angles, distances) from landmark data.
///
/// Converts raw landmark positions into biomechanically relevant measurements
/// that can be compared between coach and client forms.
class FeatureExtractor {
  FeatureExtractor();

  /// Default angle definitions for common exercises.
  ///
  /// Each angle is defined by three landmark names: [joint, from, to].
  /// The angle is measured at the joint (middle) landmark.
  static const Map<String, List<String>> defaultAngleDefinitions = {
    'leftElbowFlexion': ['LEFT_SHOULDER', 'LEFT_ELBOW', 'LEFT_WRIST'],
    'rightElbowFlexion': ['RIGHT_SHOULDER', 'RIGHT_ELBOW', 'RIGHT_WRIST'],
    'leftShoulderAbduction': ['LEFT_ELBOW', 'LEFT_SHOULDER', 'LEFT_HIP'],
    'rightShoulderAbduction': ['RIGHT_ELBOW', 'RIGHT_SHOULDER', 'RIGHT_HIP'],
    'leftKneeFlexion': ['LEFT_HIP', 'LEFT_KNEE', 'LEFT_ANKLE'],
    'rightKneeFlexion': ['RIGHT_HIP', 'RIGHT_KNEE', 'RIGHT_ANKLE'],
    'leftHipFlexion': ['LEFT_SHOULDER', 'LEFT_HIP', 'LEFT_KNEE'],
    'rightHipFlexion': ['RIGHT_SHOULDER', 'RIGHT_HIP', 'RIGHT_KNEE'],
    'torsoLean': ['LEFT_SHOULDER', 'LEFT_HIP', 'LEFT_KNEE'],
    'leftAnkleDorsiflexion': ['LEFT_KNEE', 'LEFT_ANKLE', 'LEFT_FOOT_INDEX'],
    'rightAnkleDorsiflexion': ['RIGHT_KNEE', 'RIGHT_ANKLE', 'RIGHT_FOOT_INDEX'],
  };

  /// Extract a [FeatureFrame] from a [LandmarkFrame].
  ///
  /// Calculates angles for all landmark triplets where all three landmarks
  /// are present in the frame.
  FeatureFrame extractFrame(
    LandmarkFrame frame, {
    Map<String, List<String>>? angleDefinitions,
  }) {
    final definitions = angleDefinitions ?? defaultAngleDefinitions;
    final angles = <String, double>{};

    for (final entry in definitions.entries) {
      final name = entry.key;
      final landmarkNames = entry.value;

      if (landmarkNames.length != 3) continue;

      final a = frame.landmarks[landmarkNames[0]];
      final b = frame.landmarks[landmarkNames[1]]; // Joint (vertex)
      final c = frame.landmarks[landmarkNames[2]];

      if (a == null || b == null || c == null) continue;

      final angle = _calculateAngle(a, b, c);
      if (!angle.isNaN && !angle.isInfinite) {
        angles[name] = angle;
      }
    }

    return FeatureFrame(timestampMs: frame.timestampMs, angles: angles);
  }

  /// Extract features from a batch of landmark frames.
  List<FeatureFrame> extractBatch(
    List<LandmarkFrame> frames, {
    Map<String, List<String>>? angleDefinitions,
  }) {
    AppLogger.debug(
      'Extracting features from ${frames.length} frames',
      tag: 'FeatureExtractor',
    );

    return frames
        .map((f) => extractFrame(f, angleDefinitions: angleDefinitions))
        .toList();
  }

  /// Calculate the angle (in degrees) at vertex B, formed by points A-B-C.
  ///
  /// Uses the dot product formula:
  ///   angle = acos( (BA · BC) / (|BA| × |BC|) )
  double _calculateAngle(
    LandmarkPoint a,
    LandmarkPoint b, // Vertex
    LandmarkPoint c,
  ) {
    // Vectors from B to A and B to C
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;

    // Dot product
    final dotProduct = baX * bcX + baY * bcY;

    // Magnitudes
    final magnitudeBA = math.sqrt(baX * baX + baY * baY);
    final magnitudeBC = math.sqrt(bcX * bcX + bcY * bcY);

    if (magnitudeBA == 0 || magnitudeBC == 0) return double.nan;

    // Clamp to [-1, 1] to handle floating point errors
    final cosAngle = (dotProduct / (magnitudeBA * magnitudeBC)).clamp(
      -1.0,
      1.0,
    );

    // Convert radians to degrees
    return math.acos(cosAngle) * (180.0 / math.pi);
  }
}
