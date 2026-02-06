import '../data/models/landmark_models.dart';

/// Validation result for a single setup check.
class SetupCheck {
  const SetupCheck({required this.name, required this.passed, this.message});

  final String name;
  final bool passed;
  final String? message;
}

/// Overall validation result before recording.
class SetupValidationResult {
  const SetupValidationResult({required this.checks});

  final List<SetupCheck> checks;

  bool get allPassed => checks.every((c) => c.passed);

  int get passedCount => checks.where((c) => c.passed).length;
  int get totalCount => checks.length;
}

/// Pre-recording environment and pose validation.
///
/// Validates:
/// - Body visibility (key landmarks detected)
/// - Distance estimation (body size within range)
/// - Confidence quality (average landmark confidence)
class SetupValidationService {
  SetupValidationService({
    this.minConfidence = 0.5,
    this.minBodyRatio = 0.3,
    this.maxBodyRatio = 0.9,
    this.requiredLandmarks = _defaultRequiredLandmarks,
  });

  final double minConfidence;
  final double minBodyRatio;
  final double maxBodyRatio;
  final List<String> requiredLandmarks;

  static const List<String> _defaultRequiredLandmarks = [
    'LEFT_SHOULDER',
    'RIGHT_SHOULDER',
    'LEFT_HIP',
    'RIGHT_HIP',
    'LEFT_KNEE',
    'RIGHT_KNEE',
    'LEFT_ANKLE',
    'RIGHT_ANKLE',
  ];

  /// Validate the current pose frame against setup requirements.
  SetupValidationResult validate(LandmarkFrame? frame) {
    if (frame == null || frame.landmarks.isEmpty) {
      return SetupValidationResult(
        checks: [
          const SetupCheck(
            name: 'Body Detected',
            passed: false,
            message: 'No body detected. Step into frame.',
          ),
          const SetupCheck(
            name: 'Full Body Visible',
            passed: false,
            message: 'Waiting for body detection...',
          ),
          const SetupCheck(
            name: 'Good Distance',
            passed: false,
            message: 'Waiting for body detection...',
          ),
          const SetupCheck(
            name: 'Detection Quality',
            passed: false,
            message: 'Waiting for body detection...',
          ),
        ],
      );
    }

    return SetupValidationResult(
      checks: [
        _checkBodyDetected(frame),
        _checkFullBodyVisible(frame),
        _checkDistance(frame),
        _checkConfidence(frame),
      ],
    );
  }

  /// Check if a body is detected at all.
  SetupCheck _checkBodyDetected(LandmarkFrame frame) {
    final hasBody = frame.landmarks.isNotEmpty;
    return SetupCheck(
      name: 'Body Detected',
      passed: hasBody,
      message: hasBody ? 'Body detected' : 'No body detected. Step into frame.',
    );
  }

  /// Check if all required landmarks are visible.
  SetupCheck _checkFullBodyVisible(LandmarkFrame frame) {
    final missingLandmarks = <String>[];
    for (final landmark in requiredLandmarks) {
      if (!frame.landmarks.containsKey(landmark)) {
        missingLandmarks.add(landmark);
      }
    }

    final allVisible = missingLandmarks.isEmpty;
    return SetupCheck(
      name: 'Full Body Visible',
      passed: allVisible,
      message: allVisible
          ? 'Full body in frame'
          : 'Some body parts not visible. Adjust camera position.',
    );
  }

  /// Check if the person is at an appropriate distance from the camera.
  ///
  /// Estimates distance by the vertical span of the body
  /// (shoulder to ankle ratio within the frame).
  SetupCheck _checkDistance(LandmarkFrame frame) {
    final leftShoulder = frame.landmarks['LEFT_SHOULDER'];
    final rightShoulder = frame.landmarks['RIGHT_SHOULDER'];
    final leftAnkle = frame.landmarks['LEFT_ANKLE'];
    final rightAnkle = frame.landmarks['RIGHT_ANKLE'];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      return const SetupCheck(
        name: 'Good Distance',
        passed: false,
        message: 'Cannot determine distance. Ensure full body is visible.',
      );
    }

    // Approximate body height ratio in frame (using normalized coords)
    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final ankleY = (leftAnkle.y + rightAnkle.y) / 2;
    final bodyRatio = (ankleY - shoulderY).abs();

    String? message;
    bool passed = true;

    if (bodyRatio < minBodyRatio) {
      passed = false;
      message = 'Too far away. Move closer to the camera.';
    } else if (bodyRatio > maxBodyRatio) {
      passed = false;
      message = 'Too close. Move further from the camera.';
    } else {
      message = 'Good distance from camera';
    }

    return SetupCheck(name: 'Good Distance', passed: passed, message: message);
  }

  /// Check average landmark confidence is above threshold.
  SetupCheck _checkConfidence(LandmarkFrame frame) {
    if (frame.landmarks.isEmpty) {
      return const SetupCheck(
        name: 'Detection Quality',
        passed: false,
        message: 'No landmarks detected.',
      );
    }

    final avgConfidence =
        frame.landmarks.values
            .map((p) => p.confidence)
            .reduce((a, b) => a + b) /
        frame.landmarks.length;

    final passed = avgConfidence >= minConfidence;
    return SetupCheck(
      name: 'Detection Quality',
      passed: passed,
      message: passed
          ? 'Good detection quality (${(avgConfidence * 100).toStringAsFixed(0)}%)'
          : 'Poor detection quality. Improve lighting or position.',
    );
  }
}
