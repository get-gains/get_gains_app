import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/services/pose_detection_service.dart';
import '../providers/client_recording_provider.dart';
import '../widgets/pose_view_widget.dart';

/// Client Recording Screen
///
/// Allows clients to record themselves performing an exercise while:
/// - Detecting pose via MLKit
/// - Counting reps in real-time
/// - After stopping, running DTW comparison against coach's reference form
/// - Displaying similarity score and corrections
///
/// Each recording session counts as one set.
class ClientRecordingScreen extends ConsumerStatefulWidget {
  const ClientRecordingScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<ClientRecordingScreen> createState() =>
      _ClientRecordingScreenState();
}

class _ClientRecordingScreenState extends ConsumerState<ClientRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isProcessingFrame = false;
  bool _isFlipping = false;
  int _frameSkipCount = 0;
  static const _processEveryNFrames = 3; // Process every 3rd frame

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _init();
  }

  Future<void> _init() async {
    // Load reference form first
    ref
        .read(clientRecordingProvider(widget.exerciseId).notifier)
        .loadReferenceForm();

    // Init camera
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      // Warm up pose detector
      await ref.read(poseDetectionServiceProvider).warmUp();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      AppLogger.error('Camera init failed', tag: 'ClientRecording', error: e);
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) {
      _frameSkipCount++;
      if (_frameSkipCount % _processEveryNFrames != 0) return;
      if (_isProcessingFrame) return;

      _isProcessingFrame = true;
      _processImage(image).whenComplete(() {
        _isProcessingFrame = false;
      });
    });
  }

  void _stopImageStream() {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final rotation = _cameraController!.description.sensorOrientation;
      final inputRotation = InputImageRotation.values.firstWhere(
        (r) => r.rawValue == rotation,
        orElse: () => InputImageRotation.rotation0deg,
      );
      final timestampMs = DateTime.now().millisecondsSinceEpoch;

      final landmarkFrame = await poseService.processFrame(
        image,
        inputRotation,
        timestampMs,
      );

      if (landmarkFrame != null) {
        ref
            .read(clientRecordingProvider(widget.exerciseId).notifier)
            .processFrame(landmarkFrame);
      }
    } catch (e) {
      // Silently skip failed frames
    }
  }

  void _onStartRecording() {
    ref
        .read(clientRecordingProvider(widget.exerciseId).notifier)
        .startRecording();
    _startImageStream();
  }

  Future<void> _onStopRecording() async {
    _stopImageStream();
    await ref
        .read(clientRecordingProvider(widget.exerciseId).notifier)
        .stopRecordingAndCompare();
  }

  void _onTryAgain() {
    ref
        .read(clientRecordingProvider(widget.exerciseId).notifier)
        .resetForNewAttempt();
  }

  // ── Flip camera ──────────────────────────────────────────────────────────

  /// Whether more than one camera is available (front + back).
  bool get _canFlipCamera => _cameras.length >= 2;

  /// Toggle between front and back cameras.
  /// Only allowed while in the Ready (setup) state — not during recording.
  Future<void> _flipCamera() async {
    if (!_canFlipCamera || _isFlipping) return;

    final state = ref.read(clientRecordingProvider(widget.exerciseId));
    if (state is! ClientRecordingReady) return;

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
      tag: 'ClientRecording',
    );

    try {
      await _cameraController?.dispose();
      _cameraController = null;

      if (mounted) setState(() => _isCameraInitialized = false);

      final controller = CameraController(
        targetCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      _cameraController = controller;
      await controller.initialize();

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      AppLogger.error('Flip camera failed', tag: 'ClientRecording', error: e);
    } finally {
      _isFlipping = false;
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(clientRecordingProvider(widget.exerciseId));

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_getTitle(state)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_canFlipCamera && state is ClientRecordingReady)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              tooltip: 'Flip camera',
              onPressed: _isFlipping ? null : _flipCamera,
            ),
        ],
      ),
      body: _buildBody(context, state, isDark),
    );
  }

  String _getTitle(ClientRecordingState state) {
    if (state is ClientRecordingActive) return state.exerciseName;
    if (state is ClientRecordingReady) return state.exerciseName;
    if (state is ClientRecordingComplete) return 'Results';
    return 'Compare Form';
  }

  Widget _buildBody(
    BuildContext context,
    ClientRecordingState state,
    bool isDark,
  ) {
    return switch (state) {
      ClientRecordingInitial() || ClientRecordingLoadingForm() => const Center(
        child: CircularProgressIndicator(),
      ),
      ClientRecordingError(message: final msg) => _buildError(context, msg),
      ClientRecordingReady() => _buildReadyState(context, state, isDark),
      ClientRecordingActive() => _buildRecordingState(context, state, isDark),
      ClientRecordingProcessing() => _buildProcessing(context),
      ClientRecordingComplete() => _buildResults(context, state, isDark),
    };
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          description: message,
          actionLabel: 'Go Back',
          onAction: () => context.pop(),
        ),
      ),
    );
  }

  Widget _buildReadyState(
    BuildContext context,
    ClientRecordingReady state,
    bool isDark,
  ) {
    return Column(
      children: [
        // Coach reference playback + camera preview (split view)
        Expanded(
          child: Column(
            children: [
              // Coach's reference skeleton
              if (state.referenceFrames.isNotEmpty)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Coach's Form",
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: PoseViewWidget(
                            landmarkFrames: state.referenceFrames,
                            mode: PoseViewMode.raw2D,
                            color: Colors.cyanAccent,
                            backgroundColor: const Color(0xFF0F0F1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Camera preview
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Camera',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _isCameraInitialized
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CameraPreview(_cameraController!),
                              )
                            : _isCameraError
                            ? Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surface1Dark
                                      : AppColors.surface1Light,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.videocam_off,
                                        size: 32,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Camera unavailable',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Info + start button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (state.coachName != null) ...[
                Text(
                  'Coach: ${state.coachName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Camera: ${_formatAngle(state.cameraAngle)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Watch the coach\'s form above, then record yours.\n'
                'Each recording counts as one set.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              AppButton.primary(
                label: 'Start Recording',
                icon: Icons.fiber_manual_record,
                isFullWidth: true,
                onPressed: _isCameraInitialized ? _onStartRecording : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingState(
    BuildContext context,
    ClientRecordingActive state,
    bool isDark,
  ) {
    final durationSec = (state.recordingDurationMs / 1000).toStringAsFixed(1);

    return Column(
      children: [
        // Camera preview with overlay
        Expanded(
          child: Stack(
            children: [
              // Camera feed
              if (_isCameraInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CameraPreview(_cameraController!),
                ),

              // Recording indicator
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
                      const SizedBox(width: 6),
                      Text(
                        'REC ${durationSec}s',
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

              // Rep counter overlay
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.repeat, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${state.repCount} reps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Coach's reference skeleton (PiP overlay)
              if (state.referenceLandmarkFrames.isNotEmpty)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: PoseViewWidget(
                            landmarkFrames: state.referenceLandmarkFrames,
                            mode: PoseViewMode.raw2D,
                            color: Colors.cyanAccent,
                            backgroundColor: const Color(0xDD0F0F1A),
                            showControls: false,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Coach',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Frame count
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.clientFeatureFrames.length} frames',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Stop button
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton.primary(
            label: 'Stop & Compare',
            icon: Icons.stop,
            isFullWidth: true,
            onPressed: _onStopRecording,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyzing your form...'),
          SizedBox(height: 8),
          Text(
            'Comparing against coach\'s reference',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    ClientRecordingComplete state,
    bool isDark,
  ) {
    final score = state.result.overallScore;
    final scorePercent = (score * 100).toStringAsFixed(0);
    final scoreColor = _getScoreColor(score);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$scorePercent%',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  _getScoreLabel(score),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: scoreColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rep count
          AppCard.elevated(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.repCount} reps completed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Segment scores
          if (state.result.segmentScores.isNotEmpty) ...[
            Text(
              'Segment Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...state.result.segmentScores.entries.map(
              (entry) => _SegmentScoreRow(
                name: entry.key,
                score: entry.value,
                isDark: isDark,
              ),
            ),
          ],

          // Corrections
          if (state.result.corrections.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Form Corrections',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...state.result.corrections.map(
              (correction) =>
                  _CorrectionCard(correction: correction, isDark: isDark),
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  onPressed: _onTryAgain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.primary(
                  label: 'Done',
                  icon: Icons.check,
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),

          // Upload status
          if (state.uploadSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Results saved to server',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.8) return 'Great';
    if (score >= 0.7) return 'Good';
    if (score >= 0.6) return 'Fair';
    if (score >= 0.4) return 'Needs Work';
    return 'Keep Practicing';
  }

  String _formatAngle(String angle) {
    return angle
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _SegmentScoreRow extends StatelessWidget {
  const _SegmentScoreRow({
    required this.name,
    required this.score,
    required this.isDark,
  });

  final String name;
  final double score;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scorePercent = (score * 100).toStringAsFixed(0);
    final color = score >= 0.8
        ? Colors.green
        : score >= 0.6
        ? Colors.orange
        : Colors.red;

    final prettyName = name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)!.toLowerCase()}',
        )
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              prettyName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$scorePercent%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.correction, required this.isDark});

  final dynamic correction; // CorrectionModel
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard.elevated(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correction.message as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
