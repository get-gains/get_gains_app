import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/router_provider.dart';
import '../../../../services/database/app_database.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/data/models/landmark_models.dart';
import '../../../coach_pose/services/pose_detection_service.dart';
import '../../../coach_pose/services/setup_validation_service.dart';
import '../../../coach_pose/presentation/widgets/setup_checklist.dart';
import '../../../guidance/guidance.dart';
import '../../../unity/data/unity_cosmetics_loader.dart';
import '../../../unity/data/unity_message_contract.dart';
import '../../../workout/data/models/models.dart';
import '../../../workout/presentation/providers/workout_session_provider.dart';
import '../../../workout/presentation/utils/workout_navigation.dart';
import '../../data/client_pose_repository.dart';
import '../providers/client_recording_provider.dart';
import '../widgets/pose_view_widget.dart';

/// Client Unity Recording Screen
///
/// Allows clients to record and compare their exercise form using a 3D Unity
/// avatar skeleton, mirroring how coaches visualise their recorded forms.
///
/// Pipeline:
/// 1. Load coach's reference form from server
/// 2. Send reference landmark frames to Unity for 3D looping playback
/// 3. Initialise device camera; capture raw frames only during recording (no live MLKit)
/// 4. On stop: post-process (pose analysis) then DTW comparison and show results
class ClientUnityRecordingScreen extends ConsumerStatefulWidget {
  const ClientUnityRecordingScreen({
    super.key,
    required this.exerciseId,
    this.workoutSessionId,
    this.routineExerciseId,
    this.routineExercises,
    this.currentExerciseIndex = 0,
    this.currentSetNumber = 1,
  });

  final String exerciseId;

  /// When non-null the screen is in "workout mode" — set logging UI is shown
  /// after comparison results and navigation goes to the next exercise.
  final String? workoutSessionId;
  final String? routineExerciseId;
  final List<RoutineExerciseModel>? routineExercises;
  final int currentExerciseIndex;
  final int currentSetNumber;

  @override
  ConsumerState<ClientUnityRecordingScreen> createState() =>
      _ClientUnityRecordingScreenState();
}

class _ClientUnityRecordingScreenState
    extends ConsumerState<ClientUnityRecordingScreen> {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isFlipping = false;
  int _frameSkipCount = 0; // for setup validation stream throttle

  // ── Unity ───────────────────────────────────────────────────────────────
  bool _isUnityLoaded = false;

  // Show Unity avatar (true) or 2D skeleton fallback (false).
  // Defaults to false — auto-enabled when Unity sends scene_loaded.
  // Prevents native crash dialog on emulators where libmain.so is absent.
  bool _showUnity = false;
  // ── Workout mode: set logger ─────────────────────────────────────────────────────
  bool get _isWorkoutMode => widget.workoutSessionId != null;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  bool _isLoggingSet = false;
  bool _isNavigatingAfterLog = false;
  late int _workoutSetNumber;

  // ── Guidance state ───────────────────────────────────────────────────
  bool _preBriefDismissed = false;
  bool _tipDismissed = false;
  bool _resultsFirstTimeShown = false;

  // ── Setup validation ──────────────────────────────────────────────────────
  final SetupValidationService _setupValidator = SetupValidationService();
  SetupValidationResult? _setupValidation;
  bool _isProcessingSetupFrame = false;
  bool _isSetupStreamActive = false;
  bool get _setupPassed => _setupValidation?.allPassed ?? false;

  // ── Auto-start countdown ───────────────────────────────────────────────────
  static const _autoStartSeconds = 3;
  Timer? _autoStartTimer;
  int _autoStartSecondsLeft = 0;
  bool get _isAutoStarting => _autoStartSecondsLeft > 0;

  @override
  void initState() {
    super.initState();
    _workoutSetNumber = widget.currentSetNumber;
    final prescribedSets = _currentExercisePrescribedSets;
    if (prescribedSets != null && prescribedSets > 0) {
      _workoutSetNumber = _workoutSetNumber.clamp(1, prescribedSets);
    }
    WakelockPlus.enable();
    _init();
  }

  int? get _safeCurrentExerciseIndex {
    final exercises = widget.routineExercises;
    if (exercises == null || exercises.isEmpty) return null;
    return widget.currentExerciseIndex.clamp(0, exercises.length - 1);
  }

  int? get _currentExercisePrescribedSets {
    final exercises = widget.routineExercises;
    final safeIndex = _safeCurrentExerciseIndex;
    if (exercises == null || safeIndex == null) return null;
    return exercises[safeIndex].sets;
  }

  Future<void> _handleCloseTap() async {
    // Check if we have unlogged recording results
    final recordingState = ref.read(clientRecordingProvider(widget.exerciseId));
    final hasUnloggedRecording = recordingState is ClientRecordingComplete;

    if (hasUnloggedRecording) {
      final shouldDiscard = await showAppConfirmDialog(
        context: context,
        title: 'Discard Recording?',
        message: 'Your set has not been logged yet. Discard this recording?',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep Recording',
        isDestructive: true,
      );

      if (shouldDiscard != true || !mounted) return;
    }

    navigateToWorkoutParentOrHome(context, ref);
  }

  Future<void> _init() async {
    // Load reference form data — defer to avoid modifying provider during build
    Future.microtask(() {
      if (mounted) {
        ref
            .read(clientRecordingProvider(widget.exerciseId).notifier)
            .loadReferenceForm();
      }
    });

    // Pre-cache forms for remaining exercises so they load instantly
    // (and are available offline if connectivity drops mid-workout).
    final exercises = widget.routineExercises;
    if (exercises != null && exercises.length > 1) {
      final remaining = exercises
          .where((e) => e.exerciseId != widget.exerciseId)
          .map((e) => e.exerciseId)
          .toList();
      if (remaining.isNotEmpty) {
        ref.read(clientPoseRepositoryProvider).preCacheExerciseForms(remaining);
      }
    }

    // Init device camera in parallel
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _isCameraError = true);
        return;
      }

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
      await ref.read(poseDetectionServiceProvider).warmUp();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          // Initialise with all-failing checks so the checklist appears
          _setupValidation = _setupValidator.validate(null);
        });
        // Start processing frames for setup checks
        _startSetupStream();
      }
    } catch (e) {
      AppLogger.error(
        'Camera init failed',
        tag: 'ClientUnityRecording',
        error: e,
      );
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  // ── Setup validation stream ──────────────────────────────────────────────

  /// Start a camera image stream that validates pose setup (body in frame, etc.)
  void _startSetupStream() {
    if (_isSetupStreamActive) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    _isSetupStreamActive = true;
    _frameSkipCount = 0;

    _cameraController!.startImageStream((CameraImage image) {
      _frameSkipCount++;
      // Process every 10th frame (~3 checks/sec at 30fps)
      if (_frameSkipCount % 10 != 0) return;
      _processSetupFrame(image);
    });
  }

  /// Stop the setup validation stream.
  void _stopSetupStream() {
    if (!_isSetupStreamActive) return;
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    _isSetupStreamActive = false;
  }

  /// Process a single camera frame for body detection checks.
  Future<void> _processSetupFrame(CameraImage image) async {
    if (_isProcessingSetupFrame) return;
    _isProcessingSetupFrame = true;

    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final rotation = _cameraController!.description.sensorOrientation;
      final inputRotation = InputImageRotation.values.firstWhere(
        (r) => r.rawValue == rotation,
        orElse: () => InputImageRotation.rotation0deg,
      );
      final ts = DateTime.now().millisecondsSinceEpoch;

      final frame = await poseService.processFrame(image, inputRotation, ts);

      if (mounted) {
        final wasPassed = _setupPassed;
        setState(() {
          _setupValidation = _setupValidator.validate(frame);
        });
        final isPassed = _setupPassed;
        if (isPassed && !wasPassed && !_isAutoStarting) {
          _startAutoStartCountdown();
        } else if (!isPassed && _isAutoStarting) {
          _cancelAutoStartCountdown();
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Setup frame processing error: $e',
        tag: 'ClientUnityRecording',
      );
    } finally {
      _isProcessingSetupFrame = false;
    }
  }

  // ── Auto-start helpers ──────────────────────────────────────────────────────────

  void _startAutoStartCountdown() {
    if (_isAutoStarting) return;
    setState(() => _autoStartSecondsLeft = _autoStartSeconds);
    _autoStartTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      // If setup is no longer passing, abort
      if (!_setupPassed) {
        t.cancel();
        setState(() => _autoStartSecondsLeft = 0);
        return;
      }
      setState(() => _autoStartSecondsLeft--);
      if (_autoStartSecondsLeft <= 0) {
        t.cancel();
        _onStartRecording();
      }
    });
  }

  void _cancelAutoStartCountdown() {
    _autoStartTimer?.cancel();
    _autoStartTimer = null;
    if (mounted) setState(() => _autoStartSecondsLeft = 0);
  }

  // ── Unity callbacks ──────────────────────────────────────────────────────

  void _onMessageFromUnity(String message) {
    if (!mounted) return;
    if (message == UnityMessageContract.unityEventSceneLoaded) {
      setState(() {
        _isUnityLoaded = true;
        _showUnity =
            true; // Unity successfully loaded — switch from 2D fallback
      });
      // Load equipped cosmetics onto the character
      UnityCosmeticsLoader.loadEquippedCosmetics(ref.read(appDatabaseProvider));
      // Send reference frames now that Unity scene is ready
      _sendReferenceFramesToUnity();
    } else if (message == UnityMessageContract.unityEventPoseReady) {
      // Frames loaded by Unity — ready for playback
    }
  }

  /// Sends the coach's reference landmark frames to Unity for looping 3D playback.
  void _sendReferenceFramesToUnity() {
    final state = ref.read(clientRecordingProvider(widget.exerciseId));
    if (state is! ClientRecordingReady && state is! ClientRecordingActive) {
      return;
    }

    final frames = state is ClientRecordingReady
        ? state.referenceFrames
        : (state as ClientRecordingActive).referenceLandmarkFrames;

    if (frames.isEmpty) return;

    final payload = jsonEncode({
      'frames': frames.map((f) => f.toJson()).toList(),
      'fps': 15,
      'loop': true,
    });

    // Ensure full-figure framing (restores wide orbit if previously in Cosmetic mode).
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetCameraViewMode,
      'WORKOUT',
    );

    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodLoadPoseFrames,
      payload,
    );

    // Set camera angle in Unity to match the coach's recording angle
    final angle = state is ClientRecordingReady
        ? state.cameraAngle
        : (state as ClientRecordingActive).cameraAngle;
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetCameraAngle,
      angle,
    );

    // Reference skeleton: cyan color
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetSkeletonColor,
      '#00FFFF',
    );
  }

  // ── Camera stream ────────────────────────────────────────────────────────

  // Setup phase keeps startImageStream for live setup-validation preview.
  void _startSetupImageStream() {
    // Reuse _startSetupStream which is already camera-based.
  }

  // ── Recording actions ────────────────────────────────────────────────────

  void _onStartRecording() {
    _isNavigatingAfterLog = false;
    // Stop the setup validation stream before starting video recording
    _stopSetupStream();
    ref
        .read(clientRecordingProvider(widget.exerciseId).notifier)
        .startRecording();
    // Start video recording
    _cameraController
        ?.startVideoRecording()
        .then((_) {
          AppLogger.info(
            'Video recording started',
            tag: 'ClientUnityRecording',
          );
        })
        .catchError((Object e) {
          AppLogger.error(
            'Failed to start video recording',
            tag: 'ClientUnityRecording',
            error: e,
          );
        });
    // Switch Unity skeleton color to green for client's live pose
    if (_isUnityLoaded) {
      sendToUnity(
        UnityMessageContract.gameObjectName,
        UnityMessageContract.methodSetSkeletonColor,
        '#00FF88',
      );
      sendToUnity(
        UnityMessageContract.gameObjectName,
        UnityMessageContract.methodPlayPose,
        '',
      );
    }
  }

  Future<void> _onStopRecording() async {
    try {
      final file = await _cameraController!.stopVideoRecording();
      ref
          .read(clientRecordingProvider(widget.exerciseId).notifier)
          .setRecordedVideo(file.path);
    } catch (e) {
      AppLogger.error(
        'Failed to stop video recording',
        tag: 'ClientUnityRecording',
        error: e,
      );
    }
  }

  void _onTryAgain() {
    _isNavigatingAfterLog = false;
    _cancelAutoStartCountdown();
    _repsController.clear();
    _weightController.clear();
    ref
        .read(clientRecordingProvider(widget.exerciseId).notifier)
        .resetForNewAttempt();
    // Reload reference skeleton in Unity
    _sendReferenceFramesToUnity();
    // Restart setup validation
    setState(() {
      _setupValidation = _setupValidator.validate(null);
    });
    _startSetupStream();
  }

  // ── Flip camera ──────────────────────────────────────────────────────────

  /// Whether more than one camera is available (front + back).
  bool get _canFlipCamera => _cameras.length >= 2;

  /// Toggle between front and back cameras.
  /// Only allowed while in the Ready (setup) state — not during recording.
  Future<void> _flipCamera() async {
    if (!_canFlipCamera || _isFlipping) return;

    final state = ref.read(clientRecordingProvider(widget.exerciseId));
    // Block flipping once recording has started
    if (state is! ClientRecordingReady) return;

    _cancelAutoStartCountdown();
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
      tag: 'ClientUnityRecording',
    );

    try {
      _stopSetupStream();
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

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _setupValidation = _setupValidator.validate(null);
        });
        _startSetupStream();
      }
    } catch (e) {
      AppLogger.error(
        'Flip camera failed',
        tag: 'ClientUnityRecording',
        error: e,
      );
    } finally {
      _isFlipping = false;
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _autoStartTimer?.cancel();
    _stopSetupStream();
    _cameraController?.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(clientRecordingProvider(widget.exerciseId));

    // When form loads into Ready state, push reference frames to Unity.
    // When recording auto-stops (Active → Processing), stop the camera stream.
    ref.listen(clientRecordingProvider(widget.exerciseId), (prev, next) {
      if (next is ClientRecordingReady && _isUnityLoaded) {
        _sendReferenceFramesToUnity();
      }
      // When recording auto-stops (Active → Processing), stop the camera
      // video recording and pass the file to the provider.
      if (prev is ClientRecordingActive && next is ClientRecordingProcessing) {
        _cameraController
            ?.stopVideoRecording()
            .then((file) {
              ref
                  .read(clientRecordingProvider(widget.exerciseId).notifier)
                  .setRecordedVideo(file.path);
            })
            .catchError((Object e) {
              AppLogger.error(
                'Failed to stop video recording on auto-stop',
                tag: 'ClientUnityRecording',
                error: e,
              );
            });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleCloseTap();
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(_getTitle(state)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleCloseTap,
          ),
          actions: [
            // Flip camera (only during setup/ready phase)
            if (_canFlipCamera && state is ClientRecordingReady)
              IconButton(
                icon: const Icon(Icons.flip_camera_ios),
                tooltip: 'Flip camera',
                onPressed: _isFlipping ? null : _flipCamera,
              ),
            // Toggle Unity ↔ 2D skeleton
            IconButton(
              icon: Icon(_showUnity ? Icons.view_in_ar : Icons.grain),
              tooltip: _showUnity
                  ? 'Switch to 2D skeleton'
                  : 'Switch to 3D Unity',
              onPressed: () => setState(() => _showUnity = !_showUnity),
            ),
            // Help / guidance info
            InfoIconButton(content: kRecordingHelp),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBody(context, state, isDark),
            // Pre-warm Unity: keep a 1×1 invisible EmbedUnity in the tree so
            // Unity finishes loading during setup / countdown, before recording
            // begins. Removed once scene_loaded fires (_isUnityLoaded = true).
            if (!_isUnityLoaded)
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: EmbedUnity(onMessageFromUnity: _onMessageFromUnity),
              ),
          ],
        ),
      ),
    );
  }

  String _getTitle(ClientRecordingState state) {
    final safeExerciseIndex = _safeCurrentExerciseIndex;
    final exercisePosition = safeExerciseIndex != null
        ? safeExerciseIndex + 1
        : widget.currentExerciseIndex + 1;
    final totalExercises = widget.routineExercises?.length ?? '?';
    final prescribedSets = _currentExercisePrescribedSets;
    final displaySetNumber = prescribedSets != null
        ? _workoutSetNumber.clamp(1, prescribedSets)
        : _workoutSetNumber;

    final exercisePrefix = _isWorkoutMode
        ? 'Ex $exercisePosition/$totalExercises: '
        : '';
    final setInfo = _isWorkoutMode
        ? ' (Set $displaySetNumber/${prescribedSets ?? '?'})'
        : '';
    if (state is ClientRecordingActive)
      return '$exercisePrefix${state.exerciseName}$setInfo';
    if (state is ClientRecordingReady)
      return '$exercisePrefix${state.exerciseName}$setInfo';
    if (state is ClientRecordingComplete)
      return '${exercisePrefix}Results$setInfo';
    return '${exercisePrefix}Record Form$setInfo';
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
      ClientRecordingReady() => _buildReady(context, state, isDark),
      ClientRecordingActive() => _buildRecording(context, state, isDark),
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
          actionLabel: _isWorkoutMode
              ? 'Continue Without Recording'
              : 'Go Back',
          onAction: _isWorkoutMode ? _skipToWorkoutLogger : _handleCloseTap,
          secondaryActionLabel: _isWorkoutMode ? 'Go Back' : null,
          onSecondaryAction: _isWorkoutMode ? _handleCloseTap : null,
        ),
      ),
    );
  }

  /// Skip form recording and go to the workout session logger so the
  /// user can continue logging sets offline.
  void _skipToWorkoutLogger() {
    context.go(AppRoutes.workoutSession, extra: {'readOnly': true});
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

  Widget _buildReady(
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
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            // Camera preview with setup checklist overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-screen camera preview
                  _buildCameraPreview(isDark),

                  // Setup checklist overlay (top)
                  if (_setupValidation != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: SetupChecklist(validation: _setupValidation),
                    ),

                  // Camera angle badge (bottom-left)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatAngle(state.cameraAngle),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildReadyControls(context, state, isDark),
          ],
        ),

        // Pre-brief instructional overlay (first-time only)
        if (showPreBrief)
          _buildPreBriefOverlay(
            context,
            isDark,
            hasReferenceForm: state.referenceFrames.isNotEmpty,
          ),
      ],
    );
  }

  Widget _buildPreBriefOverlay(
    BuildContext context,
    bool isDark, {
    bool hasReferenceForm = true,
  }) {
    final theme = Theme.of(context);

    // When no reference form is available, show alternate content
    final sections = hasReferenceForm
        ? kRecordingHelp.sections
        : [
            const HelpSection(
              heading: 'No Reference Form',
              body:
                  'There is no reference form available for this exercise. '
                  'Focus on performing the exercise with your best technique.',
              iconName: 'info',
            ),
            const HelpSection(
              heading: 'Record Your Form',
              body:
                  'The app will still record and analyze your movement. '
                  'Do your best and review the results after.',
              iconName: 'videocam',
            ),
          ];

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
                  ...sections.map(
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

  Widget _buildRecording(
    BuildContext context,
    ClientRecordingActive state,
    bool isDark,
  ) {
    final durationSec = (state.recordingDurationMs / 1000).toStringAsFixed(1);

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main view: Unity 3D or 2D skeleton
              _buildMainSkeletonView(
                isDark: isDark,
                referenceFrames: state.referenceLandmarkFrames,
              ),

              // Camera pip (bottom-right)
              Positioned(bottom: 12, right: 12, child: _buildCameraPip(isDark)),

              // REC badge
              Positioned(top: 16, left: 16, child: _buildRecBadge(durationSec)),

              // Frame count
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildFrameCount(state.clientFeatureFrames.length),
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
            ],
          ),
        ),
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

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  /// Upper area: Unity embed or 2D skeleton fallback; below it the live camera.
  Widget _buildSkeletonView({
    required BuildContext context,
    required bool isDark,
    required String topLabel,
    required List<LandmarkFrame> referenceFrames,
    required bool showLiveCamera,
  }) {
    return Column(
      children: [
        // Reference skeleton (Unity or 2D)
        Expanded(
          flex: showLiveCamera ? 1 : 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _buildMainSkeletonView(
                    isDark: isDark,
                    referenceFrames: referenceFrames,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Live camera preview
        if (showLiveCamera)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Camera',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: _buildCameraPreview(isDark)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainSkeletonView({
    required bool isDark,
    required List<LandmarkFrame> referenceFrames,
  }) {
    if (_showUnity) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            EmbedUnity(onMessageFromUnity: _onMessageFromUnity),
            if (!_isUnityLoaded)
              Container(
                color: const Color(0xFF0F0F1A),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.cyanAccent),
                      SizedBox(height: 12),
                      Text(
                        'Loading Unity 3D...',
                        style: TextStyle(color: Colors.cyanAccent),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // 2D skeleton fallback
    if (referenceFrames.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No landmark data', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return PoseViewWidget(
      landmarkFrames: referenceFrames,
      mode: PoseViewMode.raw2D,
      color: Colors.cyanAccent,
      backgroundColor: const Color(0xFF0F0F1A),
      mirrorX: true,
    );
  }

  Widget _buildCameraPreview(bool isDark) {
    if (_isCameraInitialized && _cameraController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CameraPreview(_cameraController!),
      );
    }
    if (_isCameraError) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 32, color: Colors.redAccent),
              SizedBox(height: 8),
              Text(
                'Camera unavailable',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildCameraPip(bool isDark) {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: _isCameraInitialized && _cameraController != null
            ? CameraPreview(_cameraController!)
            : Container(
                color: Colors.black54,
                child: const Center(
                  child: Icon(Icons.videocam_off, color: Colors.white38),
                ),
              ),
      ),
    );
  }

  Widget _buildReadyControls(
    BuildContext context,
    ClientRecordingReady state,
    bool isDark,
  ) {
    final canRecord = _isCameraInitialized && _setupPassed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface1Dark.withValues(alpha: 0.95)
            : AppColors.cardLight.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Record button (mirroring coach style)
            _RecordButton(
              enabled: canRecord && !_isAutoStarting,
              onPressed: _isAutoStarting ? null : _onStartRecording,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            if (_isAutoStarting)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Starting in $_autoStartSecondsLeft…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _cancelAutoStartCountdown,
                    child: const Text('Cancel'),
                  ),
                ],
              )
            else
              Text(
                canRecord
                    ? 'All checks passed — tap to record'
                    : 'Complete all setup checks to begin',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecBadge(String durationSec) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.85),
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
    );
  }

  Widget _buildFrameCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count frames',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    final scoreColor = score >= 0.8
        ? Colors.green
        : score >= 0.6
        ? Colors.orange
        : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Side-by-side skeleton comparison ──────────────────────────
          if (state.referenceLandmarkFrames.isNotEmpty ||
              state.clientLandmarkFrames.isNotEmpty) ...[
            Text(
              'Form Comparison',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  // Coach skeleton (cyan)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Coach',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.cyanAccent),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: state.referenceLandmarkFrames.isNotEmpty
                              ? PoseViewWidget(
                                  landmarkFrames: state.referenceLandmarkFrames,
                                  mode: PoseViewMode.raw2D,
                                  color: Colors.cyanAccent,
                                  backgroundColor: const Color(0xFF0F0F1A),
                                  showControls: false,
                                  borderRadius: BorderRadius.circular(12),
                                  mirrorX: true,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F1A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No data',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Client skeleton (green)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'You',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: state.clientLandmarkFrames.isNotEmpty
                              ? PoseViewWidget(
                                  landmarkFrames: state.clientLandmarkFrames,
                                  mode: PoseViewMode.raw2D,
                                  color: Colors.greenAccent,
                                  backgroundColor: const Color(0xFF0F0F1A),
                                  showControls: false,
                                  borderRadius: BorderRadius.circular(12),
                                  mirrorX: true,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F0F1A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No data',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Score circle ─────────────────────────────────────────────
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

          // ── Workout mode: set logger (above fold) ───────────────────
          if (_isWorkoutMode) ...[
            _buildSetLogger(context, state, isDark),
            const SizedBox(height: 16),
          ],

          // Segment scores
          if (state.result.segmentScores.isNotEmpty) ...[
            Text(
              'Segment Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...state.result.segmentScores.entries
                .where((e) => e.value > 0)
                .map(
                  (e) =>
                      _buildSegmentRowWithInfo(context, e.key, e.value, isDark),
                ),
          ],

          // Corrections
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
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard.elevated(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.message,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Action buttons ──────────────────────────────────────────
          if (!_isWorkoutMode)
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
                    onPressed: () {
                      final router = GoRouter.of(context);
                      if (router.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                ),
              ],
            ),

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

  // ── Workout set logger ─────────────────────────────────────────────────

  Widget _buildSetLogger(
    BuildContext context,
    ClientRecordingComplete state,
    bool isDark,
  ) {
    final exercises = widget.routineExercises;
    final currentRoutineExercise =
        exercises != null && widget.currentExerciseIndex < exercises.length
        ? exercises[widget.currentExerciseIndex]
        : null;
    final isLastExercise =
        exercises == null ||
        widget.currentExerciseIndex >= exercises.length - 1;

    final sessionState = ref.watch(workoutSessionProvider);
    final routineExerciseIdForLookup =
        widget.routineExerciseId ?? currentRoutineExercise?.id;
    int existingSetCount = 0;
    if (sessionState is WorkoutSessionActive &&
        routineExerciseIdForLookup != null) {
      existingSetCount = sessionState.session
          .setsForExercise(routineExerciseIdForLookup)
          .length;
    }
    final nextSetNumber = _workoutSetNumber > existingSetCount + 1
        ? _workoutSetNumber
        : existingSetCount + 1;
    final prescribedSets = currentRoutineExercise?.sets ?? 1;
    final isLastSetForExercise = nextSetNumber >= prescribedSets;

    final isSetLoggerFirstTime = !ref
        .read(guidanceRepositoryProvider)
        .isCompleted(GuidanceRepository.kSetLogger);
    if (isSetLoggerFirstTime) {
      // Mark shown so first-time labels only appear once
      Future.microtask(() {
        ref
            .read(guidanceRepositoryProvider)
            .markCompleted(GuidanceRepository.kSetLogger);
      });
    }

    return AppCard.elevated(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log This Set',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter the reps and weight you used.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Reps (manual input)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reps',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(Icons.repeat, size: 18),
                        ),
                      ),
                      if (isSetLoggerFirstTime) ...[
                        const SizedBox(height: 4),
                        Text(
                          'How many reps you completed',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Weight input
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight (kg)',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: '0.0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.fitness_center,
                            size: 18,
                          ),
                        ),
                      ),
                      if (isSetLoggerFirstTime) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Weight used (kg)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (currentRoutineExercise != null) ...[
              const SizedBox(height: 8),
              Text(
                'Prescribed: ${currentRoutineExercise.sets} sets × '
                '${currentRoutineExercise.repsMin}-${currentRoutineExercise.repsMax} reps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your coach prescribed this range to match your training goals.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton.primary(
                  label: _isLoggingSet ? 'Logging...' : 'Log Set',
                  icon: _isLoggingSet ? null : Icons.check,
                  isFullWidth: true,
                  onPressed: _isLoggingSet
                      ? null
                      : () => _logSetAndContinue(state),
                ),
                const SizedBox(height: 8),
                AppButton.ghost(
                  label: 'Record Again',
                  icon: Icons.refresh,
                  isFullWidth: true,
                  onPressed: _isLoggingSet ? null : _onTryAgain,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logSetAndContinue(ClientRecordingComplete state) async {
    if (_isLoggingSet || _isNavigatingAfterLog) return;

    setState(() => _isLoggingSet = true);

    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text) ?? 0;
    final sessionState = ref.read(workoutSessionProvider);
    final exercises =
        widget.routineExercises ??
        (sessionState is WorkoutSessionActive
            ? sessionState.routine?.exercises
            : null);

    int resolvedCurrentExerciseIndex = widget.currentExerciseIndex;
    if (exercises != null && exercises.isNotEmpty) {
      final matchedIndex = exercises.indexWhere(
        (exercise) => exercise.id == widget.routineExerciseId,
      );
      if (matchedIndex >= 0) {
        resolvedCurrentExerciseIndex = matchedIndex;
      } else if (resolvedCurrentExerciseIndex >= exercises.length) {
        resolvedCurrentExerciseIndex = exercises.length - 1;
      }
    }

    final currentRoutineExercise =
        exercises != null && resolvedCurrentExerciseIndex < exercises.length
        ? exercises[resolvedCurrentExerciseIndex]
        : null;
    final routineExerciseIdForLookup =
        widget.routineExerciseId ?? currentRoutineExercise?.id;

    // Determine set number and navigation target BEFORE the async log call,
    // so we don't rely on state being flushed by the time we read it back.
    int setNumber = 1;
    int existingSetCount = 0;
    if (sessionState is WorkoutSessionActive &&
        routineExerciseIdForLookup != null) {
      final existing = sessionState.session.setsForExercise(
        routineExerciseIdForLookup,
      );
      existingSetCount = existing.length;
      setNumber = existing.length + 1;
    }

    if (_workoutSetNumber > setNumber) {
      setNumber = _workoutSetNumber;
    }

    final prescribedSets = exercises != null && exercises.isNotEmpty
        ? exercises[resolvedCurrentExerciseIndex].sets
        : 1;

    // Guard against stale route extras that can request an impossible set
    // (e.g. Set 4/3). Skip logging and continue to the next target.
    if (existingSetCount >= prescribedSets) {
      if (!mounted) return;
      setState(() => _isLoggingSet = false);
      _isNavigatingAfterLog = true;
      _workoutSetNumber = prescribedSets;
      _navigateAfterLog();
      return;
    }

    if (setNumber > prescribedSets) {
      setNumber = prescribedSets;
    }

    bool didLogSuccessfully = false;
    // Log via workout session provider
    try {
      didLogSuccessfully = await ref
          .read(workoutSessionProvider.notifier)
          .logSet(
            setNumber: setNumber,
            reps: reps,
            weight: weight,
            routineExerciseIdOverride: routineExerciseIdForLookup,
          );
    } catch (e) {
      AppLogger.warning('Failed to log set: $e', tag: 'ClientUnityRecording');
      if (mounted) {
        AppToast.error(context, 'Failed to log set. Please try again.');
      }
    }

    if (!mounted) return;
    setState(() => _isLoggingSet = false);

    if (!didLogSuccessfully) return;

    _isNavigatingAfterLog = true;
    _workoutSetNumber = setNumber + 1;

    // Ensure a fresh recording attempt is required for the next set.
    ref
        .read(clientRecordingProvider(widget.exerciseId).notifier)
        .resetForNewAttempt();

    _navigateAfterLog();
  }

  void _navigateAfterLog() {
    final sessionState = ref.read(workoutSessionProvider);

    if (sessionState is WorkoutSessionActive && sessionState.routine != null) {
      if (sessionState.isAllExercisesCompleted) {
        context.go(
          AppRoutes.workoutSession,
          extra: {'readOnly': true, 'nextSetNavigation': null},
        );
        return;
      }

      final routine = sessionState.routine!;
      final targetIndex = sessionState.currentExerciseIndex;

      if (targetIndex >= 0 && targetIndex < routine.exercises.length) {
        final targetExercise = routine.exercises[targetIndex];
        final targetExerciseId =
            targetExercise.exercise?.id ?? targetExercise.exerciseId;
        final completedSetCount = sessionState.session
            .setsForExercise(targetExercise.id)
            .length;
        final nextSetNumber = completedSetCount + 1;

        if (targetExerciseId.isNotEmpty &&
            nextSetNumber <= targetExercise.sets) {
          context.go(
            AppRoutes.workoutSession,
            extra: {
              'readOnly': true,
              'nextSetNavigation': {
                'workoutSessionId': sessionState.session.id,
                'routineExerciseId': targetExercise.id,
                'routineExercises': routine.exercises,
                'currentExerciseIndex': targetIndex,
                'currentSetNumber': nextSetNumber,
                'exerciseId': targetExerciseId,
              },
            },
          );
          return;
        }

        final nextIncompleteIndex = routine.exercises.indexWhere(
          (exercise) =>
              sessionState.session.setsForExercise(exercise.id).length <
              exercise.sets,
        );

        if (nextIncompleteIndex >= 0) {
          final nextExercise = routine.exercises[nextIncompleteIndex];
          final nextExerciseId =
              nextExercise.exercise?.id ?? nextExercise.exerciseId;
          final nextSetNumber =
              sessionState.session.setsForExercise(nextExercise.id).length + 1;

          if (nextExerciseId.isNotEmpty && nextSetNumber <= nextExercise.sets) {
            context.go(
              AppRoutes.workoutSession,
              extra: {
                'readOnly': true,
                'nextSetNavigation': {
                  'workoutSessionId': sessionState.session.id,
                  'routineExerciseId': nextExercise.id,
                  'routineExercises': routine.exercises,
                  'currentExerciseIndex': nextIncompleteIndex,
                  'currentSetNumber': nextSetNumber,
                  'exerciseId': nextExerciseId,
                },
              },
            );
            return;
          }
        }
      }
    }

    context.go(
      AppRoutes.workoutSession,
      extra: {'readOnly': true, 'nextSetNavigation': null},
    );
  }

  Widget _buildSegmentRow(
    BuildContext context,
    String name,
    double score,
    bool isDark,
  ) {
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
              '${(score * 100).toStringAsFixed(0)}%',
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

  /// Segment row with an info icon that opens segment explanation.
  Widget _buildSegmentRowWithInfo(
    BuildContext context,
    String name,
    double score,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(child: _buildSegmentRow(context, name, score, isDark)),
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
    );
  }

  /// Score explainer — inline grading scale for first-time users, info icon otherwise.
  Widget _buildScoreExplainer(BuildContext context, double score, bool isDark) {
    final isFirstTime =
        !_resultsFirstTimeShown &&
        !ref
            .read(guidanceRepositoryProvider)
            .isCompleted(GuidanceRepository.kResults);

    if (isFirstTime && !_resultsFirstTimeShown) {
      // Mark shown so we don't re-trigger during this session
      _resultsFirstTimeShown = true;
      Future.microtask(() {
        ref
            .read(guidanceRepositoryProvider)
            .markCompleted(GuidanceRepository.kResults);
      });
    }

    if (isFirstTime) {
      // First-time: show inline grading scale
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

/// Circular record button matching the coach recording screen.
class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.enabled,
    required this.onPressed,
    required this.isDark,
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final buttonColor = enabled
        ? Colors.red
        : Colors.red.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white38 : Colors.black26,
            width: 4,
          ),
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor,
            ),
          ),
        ),
      ),
    );
  }
}
