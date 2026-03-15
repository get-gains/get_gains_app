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

  /// Normalize for comparison: center + scale + align torso to vertical.
  ///
  /// Use this when comparing coach vs client so global orientation
  /// (e.g. bent vs upright) does not dominate; joint angles still differ.
  LandmarkFrame normalizeForComparison(LandmarkFrame frame) {
    return alignTorsoToVertical(normalize(frame));
  }

  /// Align torso (shoulder–hip axis) to vertical so orientation differences
  /// are reduced before angle extraction. Missing torso landmarks → no rotation.
  LandmarkFrame alignTorsoToVertical(LandmarkFrame frame) {
    if (frame.landmarks.isEmpty) return frame;

    const targetY = 1.0; // canonical up (0, 1, 0)
    final ls = frame.landmarks['LEFT_SHOULDER'];
    final rs = frame.landmarks['RIGHT_SHOULDER'];
    final lh = frame.landmarks['LEFT_HIP'];
    final rh = frame.landmarks['RIGHT_HIP'];

    if (ls == null || rs == null || lh == null || rh == null) return frame;

    final shoulderX = (ls.x + rs.x) / 2;
    final shoulderY = (ls.y + rs.y) / 2;
    final shoulderZ = (ls.z + rs.z) / 2;
    final hipX = (lh.x + rh.x) / 2;
    final hipY = (lh.y + rh.y) / 2;
    final hipZ = (lh.z + rh.z) / 2;

    double tx = shoulderX - hipX;
    double ty = shoulderY - hipY;
    double tz = shoulderZ - hipZ;
    final len = math.sqrt(tx * tx + ty * ty + tz * tz);
    if (len < 1e-6) return frame;
    tx /= len;
    ty /= len;
    tz /= len;

    // Rotation axis: torso x (0, targetY, 0)
    final ax = tz * targetY;
    final ay = 0.0;
    final az = -tx * targetY;
    final axisLen = math.sqrt(ax * ax + ay * ay + az * az);
    if (axisLen < 1e-6) {
      // Torso already aligned to vertical
      if (ty * targetY > 0) return frame;
      // Opposite direction: rotate 180 around X or Z
      return _rotateLandmarks(frame, 0, 1, 0, math.pi);
    }
    final axn = ax / axisLen;
    final ayn = ay / axisLen;
    final azn = az / axisLen;
    final angle = math.acos((ty * targetY).clamp(-1.0, 1.0));

    return _applyRodrigues(frame, axn, ayn, azn, angle);
  }

  LandmarkFrame _rotateLandmarks(LandmarkFrame frame, double ax, double ay, double az, double angle) {
    final rotated = <String, LandmarkPoint>{};
    for (final entry in frame.landmarks.entries) {
      final p = entry.value;
      final (rx, ry, rz) = _rodrigues(p.x, p.y, p.z, ax, ay, az, angle);
      rotated[entry.key] = LandmarkPoint(x: rx, y: ry, z: rz, confidence: p.confidence);
    }
    return LandmarkFrame(timestampMs: frame.timestampMs, landmarks: rotated);
  }

  LandmarkFrame _applyRodrigues(LandmarkFrame frame, double ax, double ay, double az, double angle) {
    return _rotateLandmarks(frame, ax, ay, az, angle);
  }

  (double, double, double) _rodrigues(double x, double y, double z, double ax, double ay, double az, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final dot = ax * x + ay * y + az * z;
    final rx = x * cosA + sinA * (ay * z - az * y) + ax * dot * (1 - cosA);
    final ry = y * cosA + sinA * (az * x - ax * z) + ay * dot * (1 - cosA);
    final rz = z * cosA + sinA * (ax * y - ay * x) + az * dot * (1 - cosA);
    return (rx, ry, rz);
  }

  /// Normalize landmark positions using 3D centroid alignment.
  ///
  /// Centers all landmarks around (0, 0, 0) and scales to a unit sphere.
  /// This allows comparison between different body sizes and camera distances
  /// while preserving depth (z-axis) information for accurate 3D analysis.
  /// Does not apply rotation alignment; use [normalizeForComparison] for that.
  LandmarkFrame normalize(LandmarkFrame frame) {
    if (frame.landmarks.isEmpty) return frame;

    final points = frame.landmarks.values.toList();

    // Compute 3D centroid
    final cx = points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
    final cy = points.map((p) => p.y).reduce((a, b) => a + b) / points.length;
    final cz = points.map((p) => p.z).reduce((a, b) => a + b) / points.length;

    // Center all points in 3D
    final centered = <String, LandmarkPoint>{};
    for (final entry in frame.landmarks.entries) {
      centered[entry.key] = LandmarkPoint(
        x: entry.value.x - cx,
        y: entry.value.y - cy,
        z: entry.value.z - cz,
        confidence: entry.value.confidence,
      );
    }

    // Compute 3D scale factor (max distance from center)
    double maxDist = 0;
    for (final p in centered.values) {
      final dist = math.sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
      maxDist = math.max(maxDist, dist);
    }

    if (maxDist == 0) {
      return LandmarkFrame(timestampMs: frame.timestampMs, landmarks: centered);
    }

    // Scale to unit sphere
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

  /// Upsample a sequence of pose frames to [targetFps] using linear interpolation.
  /// Use in post-processing when capture/detection rate is below target (e.g. 20 FPS → 30 FPS).
  /// [durationMs] is the recording duration; [frames] are assumed to span that duration.
  static List<LandmarkFrame> upsampleToTargetFps(
    List<LandmarkFrame> frames,
    int durationMs,
    int targetFps,
  ) {
    if (frames.isEmpty || durationMs <= 0 || targetFps <= 0) return frames;
    if (frames.length == 1) {
      final targetCount = (durationMs * targetFps / 1000).round();
      if (targetCount <= 1) return frames;
      return List.generate(
        targetCount,
        (i) => LandmarkFrame(
          timestampMs: frames.first.timestampMs + (i * 1000 ~/ targetFps),
          landmarks: Map.from(frames.first.landmarks),
        ),
      );
    }

    final startMs = frames.first.timestampMs;
    final targetCount = (durationMs * targetFps / 1000).round().clamp(1, 900);
    final result = <LandmarkFrame>[];

    for (var i = 0; i < targetCount; i++) {
      final targetTimeMs = startMs + (i * 1000 ~/ targetFps);
      final (a, b, t) = _findBracketAndT(frames, targetTimeMs);
      result.add(_interpolateFrames(a, b, t, targetTimeMs));
    }

    return result;
  }

  static (LandmarkFrame a, LandmarkFrame b, double t) _findBracketAndT(
    List<LandmarkFrame> frames,
    int targetTimeMs,
  ) {
    if (targetTimeMs <= frames.first.timestampMs) {
      return (frames.first, frames[1], 0.0);
    }
    if (targetTimeMs >= frames.last.timestampMs) {
      return (frames[frames.length - 2], frames.last, 1.0);
    }
    for (var i = 0; i < frames.length - 1; i++) {
      final a = frames[i];
      final b = frames[i + 1];
      if (targetTimeMs >= a.timestampMs && targetTimeMs <= b.timestampMs) {
        final span = (b.timestampMs - a.timestampMs);
        final t = span > 0
            ? (targetTimeMs - a.timestampMs) / span
            : 0.0;
        return (a, b, t.clamp(0.0, 1.0));
      }
    }
    return (frames.first, frames.last, 0.5);
  }

  static LandmarkFrame _interpolateFrames(
    LandmarkFrame a,
    LandmarkFrame b,
    double t,
    int timestampMs,
  ) {
    final keys = a.landmarks.keys.toSet().intersection(b.landmarks.keys.toSet());
    final landmarks = <String, LandmarkPoint>{};
    for (final key in keys) {
      final pa = a.landmarks[key]!;
      final pb = b.landmarks[key]!;
      landmarks[key] = LandmarkPoint(
        x: pa.x + t * (pb.x - pa.x),
        y: pa.y + t * (pb.y - pa.y),
        z: pa.z + t * (pb.z - pa.z),
        confidence: pa.confidence + t * (pb.confidence - pa.confidence),
      );
    }
    return LandmarkFrame(timestampMs: timestampMs, landmarks: landmarks);
  }

  /// Process a batch of raw frames: filter → smooth (optional) → normalize for comparison.
  ///
  /// When [skipSmooth] is true (e.g. for reference from server), only filter and
  /// normalize+align are applied so both sides use the same comparison pipeline.
  List<LandmarkFrame> processBatch(
    List<LandmarkFrame> rawFrames, {
    bool skipSmooth = false,
  }) {
    AppLogger.debug(
      'Processing batch of ${rawFrames.length} frames (skipSmooth: $skipSmooth)',
      tag: 'LandmarkPreprocessor',
    );

    // Step 1: Filter low-confidence landmarks per frame
    final filtered = rawFrames.map(filterByConfidence).toList();

    // Step 2: Temporal smoothing (skip for reference if already smoothed on server)
    final smoothed = skipSmooth ? filtered : smoothFrames(filtered);

    // Step 3: Normalize + torso alignment for comparison
    final normalized = smoothed.map(normalizeForComparison).toList();

    AppLogger.debug(
      'Batch processing complete: ${normalized.length} frames',
      tag: 'LandmarkPreprocessor',
    );

    return normalized;
  }
}
