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

  /// Extract a lightweight [FeatureFrame] containing only the single
  /// [angleName] specified. Used during live recording to minimise CPU load
  /// while still feeding the rep counter.
  FeatureFrame extractSingleAngle(LandmarkFrame frame, String angleName) {
    final triplet = defaultAngleDefinitions[angleName];
    if (triplet == null || triplet.length != 3) {
      return FeatureFrame(timestampMs: frame.timestampMs, angles: const {});
    }

    final a = frame.landmarks[triplet[0]];
    final b = frame.landmarks[triplet[1]];
    final c = frame.landmarks[triplet[2]];

    if (a == null || b == null || c == null) {
      return FeatureFrame(timestampMs: frame.timestampMs, angles: const {});
    }

    final angle = _calculateAngle(a, b, c);
    return FeatureFrame(
      timestampMs: frame.timestampMs,
      angles: (angle.isNaN || angle.isInfinite) ? const {} : {angleName: angle},
    );
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

  /// Analyse the range of motion for each angle across [frames] and return
  /// the names of angles whose ROM exceeds [minRomDegrees].
  ///
  /// This is the core of the hybrid vertex-dilution fix: angles that barely
  /// move during the coach's reference recording are considered irrelevant
  /// and excluded from DTW comparison.
  static List<String> detectRelevantAngles(
    List<FeatureFrame> frames, {
    double minRomDegrees = 15.0,
  }) {
    if (frames.isEmpty) return defaultAngleDefinitions.keys.toList();

    final mins = <String, double>{};
    final maxs = <String, double>{};

    for (final frame in frames) {
      for (final entry in frame.angles.entries) {
        final name = entry.key;
        final value = entry.value;
        mins[name] = mins.containsKey(name)
            ? math.min(mins[name]!, value)
            : value;
        maxs[name] = maxs.containsKey(name)
            ? math.max(maxs[name]!, value)
            : value;
      }
    }

    final relevant = <String>[];
    for (final name in mins.keys) {
      final rom = maxs[name]! - mins[name]!;
      if (rom >= minRomDegrees) {
        relevant.add(name);
      }
    }

    AppLogger.debug(
      'Relevant angles (ROM >= ${minRomDegrees}°): $relevant '
      '(${relevant.length}/${mins.length} total)',
      tag: 'FeatureExtractor',
    );

    // Fallback: if nothing met the threshold, return all to avoid empty DTW
    if (relevant.isEmpty) return mins.keys.toList();

    return relevant;
  }

  /// Returns a filtered copy of [defaultAngleDefinitions] containing only
  /// the entries whose keys appear in [relevantAngles].
  static Map<String, List<String>> filteredDefinitions(
    List<String> relevantAngles,
  ) {
    return Map.fromEntries(
      defaultAngleDefinitions.entries
          .where((e) => relevantAngles.contains(e.key)),
    );
  }

  /// Calculate the 3D angle (in degrees) at vertex B, formed by points A-B-C.
  ///
  /// Uses the dot product formula in 3D space:
  ///   angle = acos( (BA · BC) / (|BA| × |BC|) )
  double _calculateAngle(
    LandmarkPoint a,
    LandmarkPoint b, // Vertex
    LandmarkPoint c,
  ) {
    // 3D vectors from B to A and B to C
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final baZ = a.z - b.z;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;
    final bcZ = c.z - b.z;

    // 3D dot product
    final dotProduct = baX * bcX + baY * bcY + baZ * bcZ;

    // 3D magnitudes
    final magnitudeBA = math.sqrt(baX * baX + baY * baY + baZ * baZ);
    final magnitudeBC = math.sqrt(bcX * bcX + bcY * bcY + bcZ * bcZ);

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
