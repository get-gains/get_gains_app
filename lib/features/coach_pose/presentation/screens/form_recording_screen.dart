import 'dart:async';

import 'package:camera/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/exercise_form_model.dart';
import '../../services/pose_detection_service.dart';
import '../providers/form_recording_provider.dart';
import '../widgets/recording_controls.dart';
import '../widgets/setup_checklist.dart';

/// Form recording screen with camera preview and MLKit processing.
///
/// Flow: Setup Guidance → Recording → Processing → Upload → Complete
class FormRecordingScreen extends ConsumerStatefulWidget {
  const FormRecordingScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<FormRecordingScreen> createState() =>
      _FormRecordingScreenState();
}

class _FormRecordingScreenState extends ConsumerState<FormRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlipping = false;
  int _frameCount = 0;
  bool _isStreamingImages = false;
  bool _isProcessingSetupFrame = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Prefer back camera for form recording
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      await _setupCameraController(camera);

      if (mounted) {
        setState(() => _isCameraInitialized = true);

        // Start setup guidance
        ref
            .read(formRecordingProvider(widget.exerciseId).notifier)
            .startSetup();

        // Warm up the pose detector (pre-loads TFLite model) before
        // starting the camera stream, so the first real frame doesn't stall.
        AppLogger.info(
          'Warming up PoseDetector before stream...',
          tag: 'FormRecording',
        );
        await ref.read(poseDetectionServiceProvider).warmUp();
        AppLogger.info(
          'Warm-up complete, starting image stream',
          tag: 'FormRecording',
        );

        if (mounted) {
          _startImageStream();
        }
      }
    } catch (e) {
      AppLogger.error(
        'Camera initialization failed',
        tag: 'FormRecording',
        error: e,
      );
      _showError('Camera initialization failed: $e');
    }
  }

  /// Create and initialise a [CameraController] for the given [camera].
  Future<void> _setupCameraController(CameraDescription camera) async {
    AppLogger.info(
      'Initializing camera: ${camera.name}, lens=${camera.lensDirection}, '
      'sensor=${camera.sensorOrientation}°',
      tag: 'FormRecording',
    );

    // Use low resolution so frame copy is fast and camera can deliver ~30 FPS.
    _cameraController = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();

    AppLogger.info(
      'Camera initialized: ${_cameraController!.value.previewSize}',
      tag: 'FormRecording',
    );
  }

  /// Toggle between front and back cameras.
  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isFlipping) return;

    final state = ref.read(formRecordingProvider(widget.exerciseId));
    // Only allow flipping during setup or idle
    if (state.phase != RecordingPhase.setupGuidance &&
        state.phase != RecordingPhase.idle) {
      return;
    }

    _isFlipping = true;

    final currentDirection = _cameraController?.description.lensDirection;
    final targetDirection = currentDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final targetCamera = _cameras.firstWhere(
      (c) => c.lensDirection == targetDirection,
      orElse: () => _cameras.first,
    );

    AppLogger.info(
      'Flipping camera: $currentDirection → $targetDirection',
      tag: 'FormRecording',
    );

    try {
      await _stopImageStream();
      await _cameraController?.dispose();

      setState(() => _isCameraInitialized = false);

      await _setupCameraController(targetCamera);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startImageStream();
      }
    } catch (e) {
      AppLogger.error('Flip camera failed', tag: 'FormRecording', error: e);
      _showError('Failed to switch camera: $e');
    } finally {
      _isFlipping = false;
    }
  }

  /// Whether more than one camera is available (front + back).
  bool get _canFlipCamera => _cameras.length >= 2;

  /// Start a single continuous image stream for **setup validation only**.
  /// During recording, the camera uses `startVideoRecording()` instead.
  void _startImageStream() {
    if (_isStreamingImages) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _frameCount = 0;
    _isStreamingImages = true;

    AppLogger.info('Starting camera image stream', tag: 'FormRecording');

    _cameraController!.startImageStream((image) {
      _frameCount++;

      final state = ref.read(formRecordingProvider(widget.exerciseId));

      if (state.phase == RecordingPhase.setupGuidance ||
          state.phase == RecordingPhase.countdown) {
        if (_frameCount % 10 == 0) {
          _processSetupFrame(image);
        }
      }
    });
  }

  /// Stop the image stream safely.
  Future<void> _stopImageStream() async {
    if (!_isStreamingImages) return;
    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      AppLogger.warning(
        'Error stopping image stream: $e',
        tag: 'FormRecording',
      );
    }
    _isStreamingImages = false;
  }

  /// Process a single frame for setup validation (non-blocking).
  Future<void> _processSetupFrame(CameraImage image) async {
    if (_isProcessingSetupFrame) return;
    _isProcessingSetupFrame = true;

    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final frame = await poseService.processFrame(
        image,
        _getCameraRotation(),
        DateTime.now().millisecondsSinceEpoch,
      );

      if (mounted) {
        ref
            .read(formRecordingProvider(widget.exerciseId).notifier)
            .updateSetupValidation(frame);
      }
    } catch (e) {
      AppLogger.warning(
        'Setup frame processing error: $e',
        tag: 'FormRecording',
      );
    } finally {
      _isProcessingSetupFrame = false;
    }
  }

  void _startRecording() {
    // Stream is already running — start the countdown, which will
    // auto-transition to recording once it reaches zero.
    ref
        .read(formRecordingProvider(widget.exerciseId).notifier)
        .startCountdown();

    AppLogger.info(
      'Countdown started — stream continues',
      tag: 'FormRecording',
    );
  }

  void _cancelCountdown() {
    ref
        .read(formRecordingProvider(widget.exerciseId).notifier)
        .cancelCountdown();
  }

  Future<void> _stopRecording() async {
    // Stop video recording and pass the file to the provider
    try {
      final file = await _cameraController!.stopVideoRecording();
      ref
          .read(formRecordingProvider(widget.exerciseId).notifier)
          .setRecordedVideo(file.path);
    } catch (e) {
      AppLogger.error(
        'Failed to stop video recording',
        tag: 'FormRecording',
        error: e,
      );
    }
  }

  int _getCameraRotationDegrees() {
    final camera = _cameraController?.description;
    if (camera == null) return 0;
    final o = camera.sensorOrientation;
    return o == 90 || o == 180 || o == 270 ? o : 0;
  }

  InputImageRotation _getCameraRotation() {
    final camera = _cameraController?.description;
    if (camera == null) return InputImageRotation.rotation0deg;
    final sensorOrientation = camera.sensorOrientation;
    return switch (sensorOrientation) {
      0 => InputImageRotation.rotation0deg,
      90 => InputImageRotation.rotation90deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _ => InputImageRotation.rotation0deg,
    };
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _stopImageStream();
    _cameraController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(formRecordingProvider(widget.exerciseId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for phase transitions
    ref.listen<FormRecordingState>(formRecordingProvider(widget.exerciseId), (
      previous,
      next,
    ) {
      if (next.phase == RecordingPhase.complete) {
        _showSuccess(context, isDark);
      }
      // When countdown finishes and recording starts:
      // stop the image stream and start video recording.
      if (previous?.phase == RecordingPhase.countdown &&
          next.phase == RecordingPhase.recording) {
        _stopImageStream().then((_) async {
          try {
            await _cameraController?.startVideoRecording();
            AppLogger.info('Video recording started', tag: 'FormRecording');
          } catch (e) {
            AppLogger.error(
              'Failed to start video recording',
              tag: 'FormRecording',
              error: e,
            );
          }
        });
      }
      // When the provider auto-stops recording (transitions to processing),
      // we need to stop the video recording and pass the file path.
      if (previous?.phase == RecordingPhase.recording &&
          next.phase == RecordingPhase.processing &&
          next.videoFilePath == null) {
        _cameraController
            ?.stopVideoRecording()
            .then((file) {
              ref
                  .read(formRecordingProvider(widget.exerciseId).notifier)
                  .setRecordedVideo(file.path);
            })
            .catchError((Object e) {
              AppLogger.error(
                'Failed to stop video recording on auto-stop',
                tag: 'FormRecording',
                error: e,
              );
            });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_phaseTitle(state.phase)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          // Flip camera (front/back)
          if (_canFlipCamera &&
              (state.phase == RecordingPhase.setupGuidance ||
                  state.phase == RecordingPhase.idle))
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              tooltip: 'Flip camera',
              onPressed: _flipCamera,
            ),
          // Camera angle selector
          if (state.phase == RecordingPhase.setupGuidance)
            PopupMenuButton<CameraAngle>(
              icon: const Icon(
                Icons.rotate_90_degrees_ccw,
                color: Colors.white,
              ),
              onSelected: (angle) {
                ref
                    .read(formRecordingProvider(widget.exerciseId).notifier)
                    .setCameraAngle(angle);
              },
              itemBuilder: (context) => CameraAngle.values.map((angle) {
                return PopupMenuItem(
                  value: angle,
                  child: Row(
                    children: [
                      if (angle == state.cameraAngle)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      if (angle != state.cameraAngle) const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(angle.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(child: _buildCameraPreview(state)),

          // Controls
          _buildBottomSection(state, isDark),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(FormRecordingState state) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (state.phase == RecordingPhase.processing ||
        state.phase == RecordingPhase.uploading) {
      return _ProcessingOverlay(state: state);
    }

    if (state.phase == RecordingPhase.complete) {
      return _CompleteOverlay(form: state.uploadedForm);
    }

    if (state.phase == RecordingPhase.error) {
      return _ErrorOverlay(
        message: state.errorMessage ?? 'An error occurred',
        onRetry: () => ref
            .read(formRecordingProvider(widget.exerciseId).notifier)
            .retryUpload(),
        onReset: () =>
            ref.read(formRecordingProvider(widget.exerciseId).notifier).reset(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),

        // Setup checklist overlay
        if (state.phase == RecordingPhase.setupGuidance)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SetupChecklist(validation: state.setupValidation),
          ),

        // Countdown overlay
        if (state.isCountingDown)
          Positioned.fill(
            child: _CountdownOverlay(
              seconds: state.countdownSeconds,
              onCancel: _cancelCountdown,
            ),
          ),

        // Recording indicator
        if (state.isRecording)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.phase == RecordingPhase.recording
                          ? 'REC · Recording… (analyzed when you stop)'
                          : 'REC · ${state.frameCount} frames',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Camera angle badge
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.cameraAngle.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(FormRecordingState state, bool isDark) {
    if (state.phase == RecordingPhase.setupGuidance ||
        state.phase == RecordingPhase.countdown ||
        state.phase == RecordingPhase.recording) {
      return RecordingControls(
        state: state,
        onStartRecording: _startRecording,
        onStopRecording: _stopRecording,
        onCancelCountdown: _cancelCountdown,
      );
    }

    return const SizedBox.shrink();
  }

  String _phaseTitle(RecordingPhase phase) {
    return switch (phase) {
      RecordingPhase.idle => 'Record Form',
      RecordingPhase.setupGuidance => 'Setup',
      RecordingPhase.countdown => 'Get Ready',
      RecordingPhase.recording => 'Recording',
      RecordingPhase.processing => 'Processing...',
      RecordingPhase.uploading => 'Uploading...',
      RecordingPhase.complete => 'Complete',
      RecordingPhase.error => 'Error',
    };
  }

  Future<void> _confirmExit(BuildContext context) async {
    final state = ref.read(formRecordingProvider(widget.exerciseId));

    if (state.phase == RecordingPhase.idle ||
        state.phase == RecordingPhase.complete ||
        state.phase == RecordingPhase.error) {
      context.pop();
      return;
    }

    // If in countdown, just cancel and exit
    if (state.phase == RecordingPhase.countdown) {
      _cancelCountdown();
      context.pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recording?'),
        content: const Text(
          'Your recording progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _cameraController?.stopImageStream();
      } catch (_) {}
      if (context.mounted) context.pop();
    }
  }

  void _showSuccess(BuildContext context, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Form recorded and uploaded successfully!'),
        backgroundColor: isDark
            ? AppColors.successMuted
            : AppColors.successLight,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Overlay shown during processing/uploading.
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.state});
  final FormRecordingState state;

  @override
  Widget build(BuildContext context) {
    final message =
        state.processingMessage ??
        (state.phase == RecordingPhase.processing
            ? 'Processing landmarks...'
            : 'Uploading form...');
    final percent = (state.processingProgress * 100).toStringAsFixed(0);
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: state.processingProgress > 0
                    ? state.processingProgress
                    : null,
                strokeWidth: 6,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay shown on successful completion.
class _CompleteOverlay extends StatelessWidget {
  const _CompleteOverlay({this.form});
  final ExerciseFormModel? form;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Just now';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.accentDark,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Form Uploaded!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (form != null) ...[
              const SizedBox(height: 8),
              Text(
                '${form!.cameraAngle.displayName} · ${_formatDate(form!.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay shown on error with retry option.
class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onRetry,
    required this.onReset,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    // Truncate very long error messages (e.g. multi-field validation errors)
    final displayMessage = message.length > 200
        ? '${message.substring(0, 200)}…'
        : message;

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 64),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: onReset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Start Over'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry Upload'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen countdown overlay shown before recording begins.
class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.seconds, required this.onCancel});

  final int seconds;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large countdown number
          TweenAnimationBuilder<double>(
            key: ValueKey(seconds),
            tween: Tween(begin: 1.2, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              '$seconds',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 120,
                fontWeight: FontWeight.bold,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Get into position',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
