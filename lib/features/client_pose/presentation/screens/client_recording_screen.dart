import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/data/models/models.dart';
import '../../../coach_pose/services/pose_detection_service.dart';
import '../../../guidance/guidance.dart';
import '../providers/client_recording_provider.dart';
import '../widgets/pose_view_widget.dart';

/// Client Recording Screen
///
/// Allows clients to record themselves performing an exercise while:
/// - Capturing frames during recording (no live MLKit for performance)
/// - After stopping, post-processing: pose analysis & DTW comparison
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
  bool _isFlipping = false;

  // ── Guidance state ───────────────────────────────────────────────────
  bool _preBriefDismissed = false;
  bool _tipDismissed = false;
  bool _resultsFirstTimeShown = false;

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
        ResolutionPreset.low,
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
      final rotationDegrees = _getCameraRotationDegrees();
      final captured = CapturedFrame.fromCameraImage(image, rotationDegrees);
      ref
          .read(clientRecordingProvider(widget.exerciseId).notifier)
          .addCapturedFrame(captured);
    });
  }

  int _getCameraRotationDegrees() {
    if (_cameraController == null) return 0;
    final o = _cameraController!.description.sensorOrientation;
    return o == 90 || o == 180 || o == 270 ? o : 0;
  }

  void _stopImageStream() {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
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
        ResolutionPreset.low,
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
          // Help / guidance info
          InfoIconButton(content: kRecordingHelp),
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
      ClientRecordingProcessing(:final progress, :final message) =>
        _buildProcessing(context, progress: progress, message: message),
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
    final showPreBrief =
        !_preBriefDismissed &&
        !ref
            .read(guidanceRepositoryProvider)
            .isCompleted(GuidanceRepository.kRecording);

    return Stack(
      children: [
        Column(
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
                                mirrorX: true,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
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
        ),

        // Pre-brief instructional overlay (first-time only)
        if (showPreBrief) _buildPreBriefOverlay(context, isDark),
      ],
    );
  }

  Widget _buildPreBriefOverlay(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Before You Record',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...kRecordingHelp.sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              section.body,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _preBriefDismissed = true);
                        ref
                            .read(guidanceRepositoryProvider)
                            .markCompleted(GuidanceRepository.kRecording);
                      },
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

              // Dismissible recording tip badge
              if (!_tipDismissed)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: Offset.zero,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Follow the form on screen',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _tipDismissed = true),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                            mirrorX: true,
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

  Widget _buildProcessing(
    BuildContext context, {
    required double progress,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = (progress * 100).toStringAsFixed(0);
    return Container(
      color: isDark ? Colors.black87 : Colors.white.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This may take a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
            ),
          ],
        ),
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
          const SizedBox(height: 8),

          // Score grading scale (first-time inline, then info icon)
          _buildScoreExplainer(context, score, isDark),
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
                    'Form analyzed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Segment scores with info icons
          if (state.result.segmentScores.isNotEmpty) ...[
            Text(
              'Segment Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...state.result.segmentScores.entries.map(
              (entry) => _buildSegmentRowWithInfo(
                context,
                entry.key,
                entry.value,
                isDark,
              ),
            ),
          ],

          // Corrections with AI header
          if (state.result.corrections.isNotEmpty) ...[
            const SizedBox(height: 16),
            // AI Form Suggestions header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Form Suggestions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: 'About AI suggestions',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) =>
                          const ContextualHelpSheet(content: kResultsHelp),
                    );
                  },
                ),
              ],
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

  /// Score explainer — inline grading scale for first-time users, info icon otherwise.
  Widget _buildScoreExplainer(BuildContext context, double score, bool isDark) {
    final isFirstTime =
        !_resultsFirstTimeShown &&
        !ref
            .read(guidanceRepositoryProvider)
            .isCompleted(GuidanceRepository.kResults);

    if (isFirstTime && !_resultsFirstTimeShown) {
      _resultsFirstTimeShown = true;
      Future.microtask(() {
        ref
            .read(guidanceRepositoryProvider)
            .markCompleted(GuidanceRepository.kResults);
      });
    }

    if (isFirstTime) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Score Guide',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: kScoreGrades.map((grade) {
              final (min, max, label) = grade;
              return Text(
                '$min-$max%: $label',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // Returning user: small info icon
    return Center(
      child: TextButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const ContextualHelpSheet(content: kResultsHelp),
          );
        },
        icon: const Icon(Icons.info_outline, size: 16),
        label: Text(
          scoreGradeLabel(score),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
    );
  }

  /// Segment row with an info icon that opens segment explanation.
  Widget _buildSegmentRowWithInfo(
    BuildContext context,
    String name,
    double score,
    bool isDark,
  ) {
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
          SizedBox(
            width: 28,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 16),
              tooltip: 'About this segment',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: () {
                final explanation = kSegmentExplanations[name];
                if (explanation == null) return;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => ContextualHelpSheet(
                    content: HelpContentModel(
                      id: 'segment_$name',
                      title: explanation.displayName,
                      sections: [
                        HelpSection(
                          heading: 'What it Measures',
                          body: explanation.description,
                          iconName: 'analytics',
                        ),
                        HelpSection(
                          heading: 'Improvement Tip',
                          body: explanation.improvementTip,
                          iconName: 'lightbulb',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
