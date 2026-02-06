import 'dart:async';

import 'package:camera/camera.dart';

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
  bool _isCameraInitialized = false;
  int _frameCount = 0;
  bool _isStreamingImages = false;
  bool _isProcessingSetupFrame = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Prefer back camera for form recording
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      AppLogger.info(
        'Initializing camera: ${camera.name}, lens=${camera.lensDirection}, '
        'sensor=${camera.sensorOrientation}°',
        tag: 'FormRecording',
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      AppLogger.info(
        'Camera initialized: ${_cameraController!.value.previewSize}',
        tag: 'FormRecording',
      );

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
          // Start a single continuous image stream for setup checks
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

  /// Start a single continuous image stream.
  /// During setup: processes every ~10th frame for validation.
  /// During recording: processes every 3rd frame for landmarks.
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

      if (state.phase == RecordingPhase.setupGuidance) {
        // During setup: process every 10th frame (~3 checks/sec at 30fps)
        if (_frameCount % 10 == 0) {
          _processSetupFrame(image);
        }
      } else if (state.phase == RecordingPhase.recording) {
        // During recording: process every 3rd frame
        if (_frameCount % 3 == 0) {
          _processRecordingFrame(image);
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

  /// Process a single frame during active recording.
  Future<void> _processRecordingFrame(CameraImage image) async {
    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final frame = await poseService.processFrame(
        image,
        _getCameraRotation(),
        DateTime.now().millisecondsSinceEpoch,
      );

      if (frame != null && mounted) {
        ref
            .read(formRecordingProvider(widget.exerciseId).notifier)
            .addFrame(frame);
      }
    } catch (e) {
      AppLogger.warning(
        'Recording frame processing error: $e',
        tag: 'FormRecording',
      );
    }
  }

  void _startRecording() {
    // Stream is already running — just transition the state machine.
    // The stream callback checks state.phase and switches to recording mode.
    ref
        .read(formRecordingProvider(widget.exerciseId).notifier)
        .startRecording();

    AppLogger.info(
      'Recording started — stream continues',
      tag: 'FormRecording',
    );
  }

  Future<void> _stopRecording() async {
    await _stopImageStream();

    await ref
        .read(formRecordingProvider(widget.exerciseId).notifier)
        .stopRecording();
  }

  InputImageRotation _getCameraRotation() {
    // Default to 0 rotation; in production, use sensor orientation
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(formRecordingProvider(widget.exerciseId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for completion/error
    ref.listen<FormRecordingState>(formRecordingProvider(widget.exerciseId), (
      previous,
      next,
    ) {
      if (next.phase == RecordingPhase.complete) {
        _showSuccess(context, isDark);
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
                      'REC · ${state.frameCount} frames',
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
        state.phase == RecordingPhase.recording) {
      return RecordingControls(
        state: state,
        onStartRecording: _startRecording,
        onStopRecording: _stopRecording,
      );
    }

    return const SizedBox.shrink();
  }

  String _phaseTitle(RecordingPhase phase) {
    return switch (phase) {
      RecordingPhase.idle => 'Record Form',
      RecordingPhase.setupGuidance => 'Setup',
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
              state.phase == RecordingPhase.processing
                  ? 'Processing landmarks...'
                  : 'Uploading form...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${(state.processingProgress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
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
                'Version ${form!.version} · ${form!.totalFrames} frames',
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
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
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
    );
  }
}
