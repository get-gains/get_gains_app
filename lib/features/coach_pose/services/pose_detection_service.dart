import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../data/models/landmark_models.dart';

part 'pose_detection_service.g.dart';

/// Wrapper around Google MLKit Pose Detection.
///
/// Provides:
/// - Live camera frame processing
/// - Converting MLKit Pose → [LandmarkFrame]
/// - Confidence filtering
/// - Resource cleanup
///
/// NOTE: Uses [PoseDetectionMode.single] intentionally. The `stream` mode
/// enables GPU acceleration (MediaPipe GPU delegate) which deadlocks with
/// CameraX on many Android devices (especially Mali GPUs). `single` mode
/// uses CPU-only TFLite inference — slower per frame (~50-100ms) but reliable.
/// Since we only process every 10th frame during setup and every 3rd during
/// recording, this is fast enough.
class PoseDetectionService {
  PoseDetectionService() {
    _initDetector();
  }

  late PoseDetector _poseDetector;
  bool _isBusy = false;
  int _processedCount = 0;
  int _detectedCount = 0;
  bool _isWarmedUp = false;
  bool _isDisposed = false;

  void _initDetector() {
    AppLogger.info(
      'Initializing PoseDetector (mode=single, model=base)',
      tag: 'PoseDetection',
    );
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.base,
      ),
    );
    _isWarmedUp = false;
    AppLogger.info('PoseDetector created successfully', tag: 'PoseDetection');
  }

  /// Warm up the detector by processing a tiny synthetic image.
  /// This pre-loads the TFLite model so the first real frame is fast.
  Future<void> warmUp() async {
    if (_isWarmedUp || _isDisposed) return;

    AppLogger.info('Warming up PoseDetector...', tag: 'PoseDetection');
    try {
      // Create a small 100x100 NV21 image (all grey — Y=128, UV=128)
      final bytes = Uint8List(100 * 100 * 3 ~/ 2)
        ..fillRange(0, 100 * 100 * 3 ~/ 2, 128);
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: const Size(100, 100),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 100,
        ),
      );

      await _poseDetector
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              AppLogger.warning(
                'Warm-up timed out (15s) — will try real frames anyway',
                tag: 'PoseDetection',
              );
              return <Pose>[];
            },
          );

      _isWarmedUp = true;
      AppLogger.info(
        'PoseDetector warmed up successfully',
        tag: 'PoseDetection',
      );
    } catch (e) {
      AppLogger.warning(
        'PoseDetector warm-up failed: $e — will try real frames anyway',
        tag: 'PoseDetection',
      );
    }
  }

  /// Process a camera image and return a [LandmarkFrame] if a pose is detected.
  ///
  /// Returns `null` if:
  /// - Another frame is currently being processed
  /// - No pose is detected in the frame
  ///
  /// IMPORTANT: The [CameraImage] bytes are backed by native memory that gets
  /// recycled by the camera plugin. We must copy the bytes synchronously before
  /// any async gap to avoid reading freed/overwritten memory.
  Future<LandmarkFrame?> processFrame(
    CameraImage image,
    InputImageRotation rotation,
    int timestampMs,
  ) async {
    if (_isBusy || _isDisposed) return null;
    _isBusy = true;
    _processedCount++;
    final frameNum = _processedCount;

    // CRITICAL: Build InputImage synchronously to copy bytes before they
    // get recycled by the camera's next frame delivery.
    final inputImage = _buildInputImage(image, rotation);
    if (inputImage == null) {
      AppLogger.warning(
        'MLKit: failed to build InputImage — '
        'format=${image.format.group}, '
        'size=${image.width}x${image.height}, '
        'planes=${image.planes.length}',
        tag: 'PoseDetection',
      );
      _isBusy = false;
      return null;
    }

    AppLogger.info(
      'MLKit: processing frame #$frameNum '
      '(${image.width}x${image.height}, '
      'format=${image.format.group}, '
      'rotation=$rotation, '
      'warmedUp=$_isWarmedUp)',
      tag: 'PoseDetection',
    );

    try {
      bool timedOut = false;
      final poses = await _poseDetector
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              timedOut = true;
              AppLogger.error(
                'MLKit: processImage TIMED OUT on frame #$frameNum (10s). '
                'Detector will be recreated.',
                tag: 'PoseDetection',
              );
              return <Pose>[];
            },
          );

      // If we timed out, the native detector is likely stuck. Recreate it.
      if (timedOut) {
        AppLogger.warning(
          'MLKit: Recreating PoseDetector after timeout...',
          tag: 'PoseDetection',
        );
        try {
          await _poseDetector.close();
        } catch (_) {}
        _initDetector();
        // Warm up the new instance in the background
        unawaited(warmUp());
        return null;
      }

      AppLogger.info(
        'MLKit: processImage returned for frame #$frameNum — '
        '${poses.length} pose(s)',
        tag: 'PoseDetection',
      );

      if (poses.isEmpty) {
        AppLogger.info(
          'MLKit: frame #$frameNum — no poses detected '
          '(total detected: $_detectedCount/$_processedCount)',
          tag: 'PoseDetection',
        );
        return null;
      }

      _detectedCount++;

      // Use the first (most confident) detected pose
      final pose = poses.first;
      final frame = _poseToLandmarkFrame(pose, timestampMs);

      final avgConf =
          frame.landmarks.values
              .map((l) => l.confidence)
              .reduce((a, b) => a + b) /
          frame.landmarks.length;

      AppLogger.info(
        'MLKit: frame #$frameNum — POSE DETECTED! '
        '${frame.landmarks.length} landmarks, '
        'avg confidence=${(avgConf * 100).toStringAsFixed(1)}% '
        '(total: $_detectedCount/$_processedCount)',
        tag: 'PoseDetection',
      );

      return frame;
    } catch (e) {
      AppLogger.error(
        'MLKit: processing error on frame #$frameNum',
        tag: 'PoseDetection',
        error: e,
      );
      return null;
    } finally {
      _isBusy = false;
    }
  }

  /// Convert a single [Pose] to a [LandmarkFrame].
  LandmarkFrame _poseToLandmarkFrame(Pose pose, int timestampMs) {
    final landmarks = <String, LandmarkPoint>{};

    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      final landmark = entry.value;

      landmarks[_landmarkTypeToString(type)] = LandmarkPoint(
        x: landmark.x,
        y: landmark.y,
        z: landmark.z,
        confidence: landmark.likelihood,
      );
    }

    return LandmarkFrame(timestampMs: timestampMs, landmarks: landmarks);
  }

  /// Build an [InputImage] from a [CameraImage].
  ///
  /// IMPORTANT: Camera image bytes are backed by native memory that gets
  /// recycled. We copy all bytes to ensure MLKit reads stable data.
  InputImage? _buildInputImage(CameraImage image, InputImageRotation rotation) {
    // NV21 format (Android)
    if (image.format.group == ImageFormatGroup.nv21) {
      // Copy bytes — the original buffer is recycled by the camera plugin
      final bytes = Uint8List.fromList(image.planes.first.bytes);
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    }

    // BGRA8888 format (iOS)
    if (image.format.group == ImageFormatGroup.bgra8888) {
      // Copy bytes — the original buffer is recycled by the camera plugin
      final bytes = Uint8List.fromList(image.planes.first.bytes);
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    }

    // YUV420 format (alternative Android)
    if (image.format.group == ImageFormatGroup.yuv420) {
      final allBytes = image.planes.fold<List<int>>(
        [],
        (prev, plane) => prev..addAll(plane.bytes),
      );
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.yuv_420_888,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      return InputImage.fromBytes(
        bytes: Uint8List.fromList(allBytes),
        metadata: metadata,
      );
    }

    AppLogger.warning(
      'Unsupported image format: ${image.format.group}',
      tag: 'PoseDetection',
    );
    return null;
  }

  /// Map [PoseLandmarkType] to server-compatible string
  String _landmarkTypeToString(PoseLandmarkType type) {
    return switch (type) {
      PoseLandmarkType.nose => 'NOSE',
      PoseLandmarkType.leftEyeInner => 'LEFT_EYE_INNER',
      PoseLandmarkType.leftEye => 'LEFT_EYE',
      PoseLandmarkType.leftEyeOuter => 'LEFT_EYE_OUTER',
      PoseLandmarkType.rightEyeInner => 'RIGHT_EYE_INNER',
      PoseLandmarkType.rightEye => 'RIGHT_EYE',
      PoseLandmarkType.rightEyeOuter => 'RIGHT_EYE_OUTER',
      PoseLandmarkType.leftEar => 'LEFT_EAR',
      PoseLandmarkType.rightEar => 'RIGHT_EAR',
      PoseLandmarkType.leftMouth => 'LEFT_MOUTH',
      PoseLandmarkType.rightMouth => 'RIGHT_MOUTH',
      PoseLandmarkType.leftShoulder => 'LEFT_SHOULDER',
      PoseLandmarkType.rightShoulder => 'RIGHT_SHOULDER',
      PoseLandmarkType.leftElbow => 'LEFT_ELBOW',
      PoseLandmarkType.rightElbow => 'RIGHT_ELBOW',
      PoseLandmarkType.leftWrist => 'LEFT_WRIST',
      PoseLandmarkType.rightWrist => 'RIGHT_WRIST',
      PoseLandmarkType.leftPinky => 'LEFT_PINKY',
      PoseLandmarkType.rightPinky => 'RIGHT_PINKY',
      PoseLandmarkType.leftIndex => 'LEFT_INDEX',
      PoseLandmarkType.rightIndex => 'RIGHT_INDEX',
      PoseLandmarkType.leftThumb => 'LEFT_THUMB',
      PoseLandmarkType.rightThumb => 'RIGHT_THUMB',
      PoseLandmarkType.leftHip => 'LEFT_HIP',
      PoseLandmarkType.rightHip => 'RIGHT_HIP',
      PoseLandmarkType.leftKnee => 'LEFT_KNEE',
      PoseLandmarkType.rightKnee => 'RIGHT_KNEE',
      PoseLandmarkType.leftAnkle => 'LEFT_ANKLE',
      PoseLandmarkType.rightAnkle => 'RIGHT_ANKLE',
      PoseLandmarkType.leftHeel => 'LEFT_HEEL',
      PoseLandmarkType.rightHeel => 'RIGHT_HEEL',
      PoseLandmarkType.leftFootIndex => 'LEFT_FOOT_INDEX',
      PoseLandmarkType.rightFootIndex => 'RIGHT_FOOT_INDEX',
    };
  }

  /// Release resources
  Future<void> dispose() async {
    _isDisposed = true;
    try {
      await _poseDetector.close();
    } catch (e) {
      AppLogger.warning('Error closing PoseDetector: $e', tag: 'PoseDetection');
    }
  }
}

/// Provider for PoseDetectionService.
/// keepAlive so it persists across screen rebuilds and doesn't create
/// competing native MLKit instances.
@Riverpod(keepAlive: true)
PoseDetectionService poseDetectionService(Ref ref) {
  final service = PoseDetectionService();
  ref.onDispose(() => service.dispose());
  return service;
}
