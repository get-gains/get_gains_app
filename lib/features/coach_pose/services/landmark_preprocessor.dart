import 'dart:math' as math;

import '../../../core/utils/logger.dart';
import '../data/models/landmark_models.dart';

/// Preprocesses raw MLKit landmark data.
///
/// Handles:
/// - Filtering low-confidence landmarks
/// - Temporal smoothing across frames
/// - Normalization (Procrustes alignment)
class LandmarkPreprocessor {
  LandmarkPreprocessor({
    this.confidenceThreshold = 0.5,
    this.smoothingWindowSize = 3,
  });

  final double confidenceThreshold;
  final int smoothingWindowSize;

  /// Filter out landmarks below the confidence threshold.
  ///
  /// Returns a new [LandmarkFrame] with only high-confidence landmarks.
  LandmarkFrame filterByConfidence(LandmarkFrame frame) {
    final filtered = Map<String, LandmarkPoint>.fromEntries(
      frame.landmarks.entries.where(
        (entry) => entry.value.confidence >= confidenceThreshold,
      ),
    );

    return LandmarkFrame(timestampMs: frame.timestampMs, landmarks: filtered);
  }

  /// Apply temporal smoothing to a sequence of frames using a moving average.
  ///
  /// Reduces jitter by averaging landmark positions over a sliding window.
  List<LandmarkFrame> smoothFrames(List<LandmarkFrame> frames) {
    if (frames.length < smoothingWindowSize) return frames;

    final smoothed = <LandmarkFrame>[];

    for (int i = 0; i < frames.length; i++) {
      final windowStart = math.max(0, i - smoothingWindowSize ~/ 2);
      final windowEnd = math.min(
        frames.length,
        i + smoothingWindowSize ~/ 2 + 1,
      );
      final window = frames.sublist(windowStart, windowEnd);

      final avgLandmarks = _averageLandmarks(window);
      smoothed.add(
        LandmarkFrame(
          timestampMs: frames[i].timestampMs,
          landmarks: avgLandmarks,
        ),
      );
    }

    return smoothed;
  }

  /// Average landmark positions across multiple frames.
  Map<String, LandmarkPoint> _averageLandmarks(List<LandmarkFrame> frames) {
    if (frames.isEmpty) return {};

    // Collect all landmark keys present in any frame
    final allKeys = <String>{};
    for (final frame in frames) {
      allKeys.addAll(frame.landmarks.keys);
    }

    final averaged = <String, LandmarkPoint>{};

    for (final key in allKeys) {
      final points = frames
          .where((f) => f.landmarks.containsKey(key))
          .map((f) => f.landmarks[key]!)
          .toList();

      if (points.isEmpty) continue;

      final avgX =
          points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
      final avgY =
          points.map((p) => p.y).reduce((a, b) => a + b) / points.length;
      final avgZ =
          points.map((p) => p.z).reduce((a, b) => a + b) / points.length;
      final avgConf =
          points.map((p) => p.confidence).reduce((a, b) => a + b) /
          points.length;

      averaged[key] = LandmarkPoint(
        x: avgX,
        y: avgY,
        z: avgZ,
        confidence: avgConf,
      );
    }

    return averaged;
  }

  /// Normalize landmark positions using centroid alignment.
  ///
  /// Centers all landmarks around (0, 0) and scales to a unit bounding box.
  /// This allows comparison between different body sizes and camera distances.
  LandmarkFrame normalize(LandmarkFrame frame) {
    if (frame.landmarks.isEmpty) return frame;

    final points = frame.landmarks.values.toList();

    // Compute centroid
    final cx = points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
    final cy = points.map((p) => p.y).reduce((a, b) => a + b) / points.length;

    // Center all points
    final centered = <String, LandmarkPoint>{};
    for (final entry in frame.landmarks.entries) {
      centered[entry.key] = LandmarkPoint(
        x: entry.value.x - cx,
        y: entry.value.y - cy,
        z: entry.value.z,
        confidence: entry.value.confidence,
      );
    }

    // Compute scale factor (max distance from center)
    double maxDist = 0;
    for (final p in centered.values) {
      final dist = math.sqrt(p.x * p.x + p.y * p.y);
      maxDist = math.max(maxDist, dist);
    }

    if (maxDist == 0) {
      return LandmarkFrame(timestampMs: frame.timestampMs, landmarks: centered);
    }

    // Scale to unit circle
    final normalized = <String, LandmarkPoint>{};
    for (final entry in centered.entries) {
      normalized[entry.key] = LandmarkPoint(
        x: entry.value.x / maxDist,
        y: entry.value.y / maxDist,
        z: entry.value.z / maxDist,
        confidence: entry.value.confidence,
      );
    }

    return LandmarkFrame(timestampMs: frame.timestampMs, landmarks: normalized);
  }

  /// Smooth a single frame in real-time using the last [smoothingWindowSize]
  /// frames from [recentFrames]. Call this as each new frame arrives for
  /// jitter-free live display.
  LandmarkFrame smoothRealtime(
    LandmarkFrame frame,
    List<LandmarkFrame> recentFrames,
  ) {
    // Use the tail of recentFrames as the smoothing window
    final windowStart = recentFrames.length < smoothingWindowSize
        ? 0
        : recentFrames.length - smoothingWindowSize;
    final window = recentFrames.sublist(windowStart);

    if (window.length < 2) return frame; // not enough history yet

    final avgLandmarks = _averageLandmarks(window);
    return LandmarkFrame(
      timestampMs: frame.timestampMs,
      landmarks: avgLandmarks,
    );
  }

  /// Compute the average confidence across all landmarks in a frame.
  double averageConfidence(LandmarkFrame frame) {
    if (frame.landmarks.isEmpty) return 0.0;
    final total = frame.landmarks.values
        .map((p) => p.confidence)
        .reduce((a, b) => a + b);
    return total / frame.landmarks.length;
  }

  /// Process a batch of raw frames: filter → smooth → normalize.
  List<LandmarkFrame> processBatch(List<LandmarkFrame> rawFrames) {
    AppLogger.debug(
      'Processing batch of ${rawFrames.length} frames',
      tag: 'LandmarkPreprocessor',
    );

    // Step 1: Filter low-confidence landmarks per frame
    final filtered = rawFrames.map(filterByConfidence).toList();

    // Step 2: Temporal smoothing
    final smoothed = smoothFrames(filtered);

    // Step 3: Normalize each frame
    final normalized = smoothed.map(normalize).toList();

    AppLogger.debug(
      'Batch processing complete: ${normalized.length} frames',
      tag: 'LandmarkPreprocessor',
    );

    return normalized;
  }
}
