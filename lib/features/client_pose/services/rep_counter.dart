import 'dart:math' as math;

import '../../../core/utils/logger.dart';
import '../../coach_pose/data/models/feature_frame_model.dart';

/// Rep counter that detects repetitions by tracking peak/valley patterns
/// in joint angles over time.
///
/// Algorithm:
/// 1. Selects a primary angle to track (e.g. kneeFlexion for squats)
/// 2. Applies smoothing to reduce noise
/// 3. Detects peaks and valleys in the angle signal
/// 4. Counts a rep when a full peak-valley-peak cycle is completed
///
/// The algorithm is generic and works for any exercise by detecting
/// the dominant oscillating angle automatically.
class RepCounter {
  RepCounter({
    this.primaryAngleName,
    this.smoothingWindowSize = 5,
    this.minPeakProminence = 18.0,
    this.minRepDurationMs = 600,
  });

  /// Specific angle to track (if null, auto-detects the most variable angle)
  final String? primaryAngleName;

  /// Number of frames to use for moving average smoothing
  final int smoothingWindowSize;

  /// Minimum angle change (degrees) to count as a peak/valley
  final double minPeakProminence;

  /// Minimum time (ms) between reps to filter out noise
  final int minRepDurationMs;

  // Internal state
  final List<double> _angleHistory = [];
  final List<int> _timestampHistory = [];
  final List<double> _smoothedHistory = [];

  int _repCount = 0;
  _RepPhase _phase = _RepPhase.idle;
  double? _lastPeakValue;
  double? _lastValleyValue;
  int? _lastRepTimestamp;
  String? _detectedAngleName;
  String? _exerciseHint;

  /// Current rep count
  int get repCount => _repCount;

  /// Set the exercise name so angle selection can be smarter.
  void configure({String? exerciseName}) {
    _exerciseHint = exerciseName?.toLowerCase();
  }

  /// The angle being tracked
  String? get trackedAngle => _detectedAngleName ?? primaryAngleName;

  /// Current phase of the rep cycle
  String get phaseDescription => switch (_phase) {
    _RepPhase.idle => 'Ready',
    _RepPhase.ascending => 'Up',
    _RepPhase.descending => 'Down',
  };

  /// Reset counter state
  void reset() {
    _angleHistory.clear();
    _timestampHistory.clear();
    _smoothedHistory.clear();
    _repCount = 0;
    _phase = _RepPhase.idle;
    _lastPeakValue = null;
    _lastValleyValue = null;
    _lastRepTimestamp = null;
    _detectedAngleName = null;
    // keep _exerciseHint across resets so reconfigure isn't needed
  }

  /// Process a new feature frame and return updated rep count.
  ///
  /// Returns the current rep count after processing this frame.
  int processFrame(FeatureFrame frame) {
    if (frame.angles.isEmpty) return _repCount;

    // Auto-detect primary angle if not specified
    _detectedAngleName ??= _selectPrimaryAngle(frame);
    final angleName = _detectedAngleName ?? primaryAngleName;
    if (angleName == null || !frame.angles.containsKey(angleName)) {
      return _repCount;
    }

    final angleValue = frame.angles[angleName]!;
    _angleHistory.add(angleValue);
    _timestampHistory.add(frame.timestampMs);

    // Apply smoothing
    final smoothed = _movingAverage();
    _smoothedHistory.add(smoothed);

    // Need at least 3 points for peak/valley detection
    if (_smoothedHistory.length < 3) return _repCount;

    _detectRepetition(frame.timestampMs);

    return _repCount;
  }

  /// Process all frames at once (for post-recording analysis)
  int processAllFrames(List<FeatureFrame> frames) {
    reset();
    for (final frame in frames) {
      processFrame(frame);
    }
    return _repCount;
  }

  /// Select the best angle to track based on exercise hint, then fallback.
  String? _selectPrimaryAngle(FeatureFrame frame) {
    if (primaryAngleName != null &&
        frame.angles.containsKey(primaryAngleName)) {
      return primaryAngleName;
    }

    // Try to infer from exercise name
    final hint = _exerciseHint ?? '';
    List<String>? hintAngles;
    if (_matchesAny(hint, ['curl', 'bicep', 'hammer', 'tricep'])) {
      hintAngles = ['leftElbowFlexion', 'rightElbowFlexion'];
    } else if (_matchesAny(hint, ['squat', 'lunge', 'leg'])) {
      hintAngles = ['leftKneeFlexion', 'rightKneeFlexion'];
    } else if (_matchesAny(hint, ['press', 'push', 'bench', 'chest'])) {
      hintAngles = ['leftElbowFlexion', 'rightElbowFlexion'];
    } else if (_matchesAny(hint, ['deadlift', 'hinge', 'row'])) {
      hintAngles = ['leftHipFlexion', 'rightHipFlexion'];
    }

    if (hintAngles != null) {
      for (final angle in hintAngles) {
        if (frame.angles.containsKey(angle)) {
          AppLogger.debug(
            'Hint-selected primary angle: $angle (hint=$hint)',
            tag: 'RepCounter',
          );
          return angle;
        }
      }
    }

    // Fallback: elbow first (more common in gym), then knee, hip, shoulder
    const preferredAngles = [
      'leftElbowFlexion',
      'rightElbowFlexion',
      'leftKneeFlexion',
      'rightKneeFlexion',
      'leftHipFlexion',
      'rightHipFlexion',
      'leftShoulderAbduction',
      'rightShoulderAbduction',
    ];

    for (final angle in preferredAngles) {
      if (frame.angles.containsKey(angle)) {
        AppLogger.debug(
          'Auto-selected primary angle: $angle',
          tag: 'RepCounter',
        );
        return angle;
      }
    }

    // Fallback: use first available angle
    return frame.angles.keys.firstOrNull;
  }

  bool _matchesAny(String text, List<String> keywords) =>
      keywords.any(text.contains);

  /// Calculate moving average at the current position
  double _movingAverage() {
    final n = _angleHistory.length;
    final start = math.max(0, n - smoothingWindowSize);
    double sum = 0;
    int count = 0;
    for (int i = start; i < n; i++) {
      sum += _angleHistory[i];
      count++;
    }
    return sum / count;
  }

  /// Core rep detection logic using peak/valley analysis
  void _detectRepetition(int currentTimestamp) {
    final n = _smoothedHistory.length;
    if (n < 3) return;

    final prev = _smoothedHistory[n - 3];
    final curr = _smoothedHistory[n - 2];
    final next = _smoothedHistory[n - 1];

    // Detect local peak (ascending then descending)
    if (curr > prev && curr > next) {
      if (_lastValleyValue != null) {
        final prominence = curr - _lastValleyValue!;
        if (prominence >= minPeakProminence) {
          _lastPeakValue = curr;

          if (_phase == _RepPhase.ascending) {
            // Completed one full rep cycle (valley → peak)
            final timeSinceLastRep = _lastRepTimestamp != null
                ? currentTimestamp - _lastRepTimestamp!
                : minRepDurationMs + 1;

            if (timeSinceLastRep >= minRepDurationMs) {
              _repCount++;
              _lastRepTimestamp = currentTimestamp;
              AppLogger.debug(
                'Rep $_repCount detected (prominence: ${prominence.toStringAsFixed(1)}°)',
                tag: 'RepCounter',
              );
            }
          }
          _phase = _RepPhase.descending;
        }
      } else {
        // First peak — just record it
        _lastPeakValue = curr;
        _phase = _RepPhase.descending;
      }
    }

    // Detect local valley (descending then ascending)
    if (curr < prev && curr < next) {
      if (_lastPeakValue != null) {
        final prominence = _lastPeakValue! - curr;
        if (prominence >= minPeakProminence) {
          _lastValleyValue = curr;
          _phase = _RepPhase.ascending;
        }
      } else {
        // First valley — just record it
        _lastValleyValue = curr;
        _phase = _RepPhase.ascending;
      }
    }
  }
}

/// Phase of a single repetition cycle
enum _RepPhase {
  /// Waiting for first movement
  idle,

  /// Angle increasing (e.g. straightening leg on way up in squat)
  ascending,

  /// Angle decreasing (e.g. bending knee on way down in squat)
  descending,
}
