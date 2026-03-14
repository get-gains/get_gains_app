import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/coach_pose_repository.dart';
import '../../data/models/models.dart';
import '../../services/feature_extractor.dart';
import '../../services/pose_detection_service.dart';
import '../../services/landmark_preprocessor.dart';
import '../../services/setup_validation_service.dart';

part 'form_recording_provider.g.dart';

/// Recording state machine states.
enum RecordingPhase {
  idle,
  setupGuidance,
  countdown,
  recording,
  processing,
  uploading,
  complete,
  error,
}

/// Duration of the pre-recording countdown in seconds.
const kCountdownDurationSeconds = 10;

/// Maximum recording duration in seconds. Recording auto-stops after this.
const kMaxRecordingDurationSeconds = 7;

/// How many consecutive seconds all setup checks must pass before the
/// countdown starts automatically.
const kAutoStartDelaySeconds = 3;

/// Minimum pose/vertex data rate (FPS) for reference form.
/// We require 30+ landmark frames per second for DTW accuracy; video FPS is irrelevant.
const kMinFrameRate = 30;

/// Full state for the form recording flow.
class FormRecordingState {
  const FormRecordingState({
    this.phase = RecordingPhase.idle,
    this.exerciseId = '',
    this.cameraAngle = CameraAngle.front,
    this.setupValidation,
    this.rawFrames = const [],
    this.processedFrames = const [],
    this.featureFrames = const [],
    this.capturedFrames = const [],
    this.capturedFrameCount = 0,
    this.recordingStartMs,
    this.recordingDurationMs = 0,
    this.frameCount = 0,
    this.processingProgress = 0.0,
    this.countdownSeconds = 0,
    this.relevantAngles = const [],
    this.errorMessage,
    this.uploadedForm,
  });

  final RecordingPhase phase;
  final String exerciseId;
  final CameraAngle cameraAngle;
  final SetupValidationResult? setupValidation;
  final List<LandmarkFrame> rawFrames;
  final List<LandmarkFrame> processedFrames;
  final List<FeatureFrame> featureFrames;
  /// Raw camera frames captured during recording (no MLKit). Processed in batch after stop.
  final List<CapturedFrame> capturedFrames;
  /// Set when recording stops; used for FPS = capturedFrameCount / duration (camera FPS).
  final int capturedFrameCount;
  final int? recordingStartMs;
  final int recordingDurationMs;
  final int frameCount;
  final double processingProgress; // 0.0 to 1.0
  final int countdownSeconds;
  final List<String> relevantAngles;
  final String? errorMessage;
  final ExerciseFormModel? uploadedForm;

  bool get canStartRecording =>
      phase == RecordingPhase.setupGuidance &&
      (setupValidation?.allPassed ?? false);

  bool get isRecording => phase == RecordingPhase.recording;
  bool get isCountingDown => phase == RecordingPhase.countdown;

  FormRecordingState copyWith({
    RecordingPhase? phase,
    String? exerciseId,
    CameraAngle? cameraAngle,
    SetupValidationResult? setupValidation,
    List<LandmarkFrame>? rawFrames,
    List<LandmarkFrame>? processedFrames,
    List<FeatureFrame>? featureFrames,
    List<CapturedFrame>? capturedFrames,
    int? capturedFrameCount,
    int? recordingStartMs,
    int? recordingDurationMs,
    int? frameCount,
    double? processingProgress,
    int? countdownSeconds,
    List<String>? relevantAngles,
    String? errorMessage,
    bool clearError = false,
    ExerciseFormModel? uploadedForm,
  }) {
    return FormRecordingState(
      phase: phase ?? this.phase,
      exerciseId: exerciseId ?? this.exerciseId,
      cameraAngle: cameraAngle ?? this.cameraAngle,
      setupValidation: setupValidation ?? this.setupValidation,
      rawFrames: rawFrames ?? this.rawFrames,
      processedFrames: processedFrames ?? this.processedFrames,
      featureFrames: featureFrames ?? this.featureFrames,
      capturedFrames: capturedFrames ?? this.capturedFrames,
      capturedFrameCount: capturedFrameCount ?? this.capturedFrameCount,
      recordingStartMs: recordingStartMs ?? this.recordingStartMs,
      recordingDurationMs: recordingDurationMs ?? this.recordingDurationMs,
      frameCount: frameCount ?? this.frameCount,
      processingProgress: processingProgress ?? this.processingProgress,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      relevantAngles: relevantAngles ?? this.relevantAngles,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadedForm: uploadedForm ?? this.uploadedForm,
    );
  }
}

/// Manages the full form recording pipeline:
/// setup → record → process → upload.
@riverpod
class FormRecordingNotifier extends _$FormRecordingNotifier {
  late LandmarkPreprocessor _preprocessor;
  late FeatureExtractor _featureExtractor;
  late SetupValidationService _setupValidator;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Timer? _elapsedTimer;

  /// Tracks when all setup checks first started passing continuously.
  /// Reset to `null` whenever a check fails.
  DateTime? _setupStableSince;

  /// Mutable buffer for frames during recording. No state updates per frame.
  final List<CapturedFrame> _capturedFramesBuffer = [];

  @override
  FormRecordingState build(String exerciseId) {
    _preprocessor = LandmarkPreprocessor();
    _featureExtractor = FeatureExtractor();
    _setupValidator = SetupValidationService();

    ref.onDispose(() {
      _countdownTimer?.cancel();
      _recordingTimer?.cancel();
      _elapsedTimer?.cancel();
    });

    return FormRecordingState(exerciseId: exerciseId);
  }

  /// Start setup guidance phase — enables camera preview.
  void startSetup({CameraAngle cameraAngle = CameraAngle.front}) {
    // Initialize with all-failing checks so the checklist is visible immediately
    final initialValidation = _setupValidator.validate(null);

    state = state.copyWith(
      phase: RecordingPhase.setupGuidance,
      cameraAngle: cameraAngle,
      setupValidation: initialValidation,
      clearError: true,
    );

    AppLogger.info(
      'Setup started — initial checks: ${initialValidation.checks.length}',
      tag: 'FormRecording',
    );
  }

  /// Called periodically during setup to validate the environment.
  void updateSetupValidation(LandmarkFrame? frame) {
    if (frame != null) {
      AppLogger.debug(
        'Setup check frame received: ${frame.landmarks.length} landmarks',
        tag: 'FormRecording',
      );
    } else {
      AppLogger.debug(
        'Setup check: no pose detected in frame',
        tag: 'FormRecording',
      );
    }

    final validation = _setupValidator.validate(frame);

    AppLogger.debug(
      'Setup validation: ${validation.passedCount}/${validation.totalCount} passed'
      ' [${validation.checks.map((c) => "${c.name}: ${c.passed}").join(", ")}]',
      tag: 'FormRecording',
    );

    state = state.copyWith(setupValidation: validation);

    // --- Auto-start countdown after checks pass for kAutoStartDelaySeconds ---
    if (state.phase == RecordingPhase.setupGuidance) {
      if (validation.allPassed) {
        _setupStableSince ??= DateTime.now();
        final stableMs = DateTime.now()
            .difference(_setupStableSince!)
            .inMilliseconds;
        if (stableMs >= kAutoStartDelaySeconds * 1000) {
          AppLogger.info(
            'All checks stable for ${kAutoStartDelaySeconds}s — auto-starting countdown',
            tag: 'FormRecording',
          );
          startCountdown();
        }
      } else {
        // Reset whenever any check fails
        _setupStableSince = null;
      }
    }
  }

  /// Start the pre-recording countdown (10 seconds by default).
  ///
  /// The countdown gives the coach time to get into position after
  /// tapping the record button. When it reaches zero, recording begins
  /// automatically.
  void startCountdown() {
    if (!state.canStartRecording) {
      AppLogger.warning(
        'Cannot start countdown — setup checks not passed',
        tag: 'FormRecording',
      );
      return;
    }

    _countdownTimer?.cancel();

    state = state.copyWith(
      phase: RecordingPhase.countdown,
      countdownSeconds: kCountdownDurationSeconds,
      clearError: true,
    );

    AppLogger.info(
      'Countdown started (${kCountdownDurationSeconds}s)',
      tag: 'FormRecording',
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.countdownSeconds - 1;
      if (remaining <= 0) {
        _countdownTimer?.cancel();
        _beginRecording();
      } else {
        state = state.copyWith(countdownSeconds: remaining);
      }
    });
  }

  /// Cancel the countdown and return to setup guidance.
  void cancelCountdown() {
    _countdownTimer?.cancel();
    _setupStableSince = null;
    state = state.copyWith(
      phase: RecordingPhase.setupGuidance,
      countdownSeconds: 0,
    );
    AppLogger.info('Countdown cancelled', tag: 'FormRecording');
  }

  /// Internal: transition from countdown to active recording.
  void _beginRecording() {
    _recordingTimer?.cancel();
    _capturedFramesBuffer.clear();

    state = state.copyWith(
      phase: RecordingPhase.recording,
      rawFrames: [],
      capturedFrames: [],
      capturedFrameCount: 0,
      recordingStartMs: DateTime.now().millisecondsSinceEpoch,
      frameCount: 0,
      countdownSeconds: 0,
    );

    // Auto-stop after kMaxRecordingDurationSeconds
    _recordingTimer = Timer(
      Duration(seconds: kMaxRecordingDurationSeconds),
      () {
        if (state.phase == RecordingPhase.recording) {
          AppLogger.info(
            'Auto-stopping recording after ${kMaxRecordingDurationSeconds}s',
            tag: 'FormRecording',
          );
          stopRecording();
        }
      },
    );

    // Update elapsed time every second so the UI timer (0:00) counts up
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase != RecordingPhase.recording) return;
      final startMs = state.recordingStartMs ?? 0;
      state = state.copyWith(
        recordingDurationMs: DateTime.now().millisecondsSinceEpoch - startMs,
      );
    });

    AppLogger.info(
      'Recording started (auto-stop in ${kMaxRecordingDurationSeconds}s)',
      tag: 'FormRecording',
    );
  }

  /// Add a raw camera frame during recording (no MLKit, no pose detection).
  /// Frames are buffered in memory; state is updated only when recording stops.
  void addCapturedFrame(CapturedFrame frame) {
    if (state.phase != RecordingPhase.recording) return;
    _capturedFramesBuffer.add(frame);
  }

  /// Stop recording and begin processing (batch MLKit then pipeline).
  Future<void> stopRecording() async {
    if (state.phase != RecordingPhase.recording) return;
    _recordingTimer?.cancel();
    _elapsedTimer?.cancel();

    final endMs = DateTime.now().millisecondsSinceEpoch;
    final durationMs = endMs - (state.recordingStartMs ?? endMs);
    final capturedCount = _capturedFramesBuffer.length;
    final captured = List<CapturedFrame>.from(_capturedFramesBuffer);
    _capturedFramesBuffer.clear();

    state = state.copyWith(
      phase: RecordingPhase.processing,
      recordingDurationMs: durationMs,
      capturedFrames: captured,
      capturedFrameCount: capturedCount,
      frameCount: capturedCount,
      processingProgress: 0.0,
    );

    AppLogger.info(
      'Recording stopped. $capturedCount captured frames, ${durationMs}ms',
      tag: 'FormRecording',
    );

    await _processCapturedFrames();
  }

  /// Run MLKit on each captured frame (batch, after recording), then pipeline.
  Future<void> _processCapturedFrames() async {
    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      final startMs = state.recordingStartMs ?? 0;
      final captured = state.capturedFrames;

      final rawFrames = <LandmarkFrame>[];
      for (var i = 0; i < captured.length; i++) {
        state = state.copyWith(
          processingProgress: 0.05 + 0.15 * (i / captured.length),
        );
        final timestampMs = startMs + (i * 1000 ~/ 30);
        final frame = await poseService.processCapturedFrame(
          captured[i],
          timestampMs,
        );
        if (frame != null) rawFrames.add(frame);
      }

      state = state.copyWith(rawFrames: rawFrames);
      await _processFrames();
    } catch (e) {
      AppLogger.error(
        'Batch pose processing failed',
        tag: 'FormRecording',
        error: e,
      );
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: 'Failed to process recording: $e',
      );
    }
  }

  /// Process recorded frames: filter+smooth → extract features → normalize.
  Future<void> _processFrames() async {
    try {
      // Step 1: Filter low-confidence landmarks + smooth
      state = state.copyWith(processingProgress: 0.1);
      final filtered = state.rawFrames
          .map(_preprocessor.filterByConfidence)
          .toList();
      final smoothed = _preprocessor.smoothFrames(filtered);

      state = state.copyWith(
        processedFrames: smoothed,
        processingProgress: 0.3,
      );

      // Step 2: Extract features (joint angles) from smoothed frames
      final features = _featureExtractor.extractBatch(smoothed);

      // Step 2b: Auto-detect which angles are relevant (ROM >= 15°)
      final relevantAngles = FeatureExtractor.detectRelevantAngles(features);

      state = state.copyWith(featureFrames: features, processingProgress: 0.5);

      // Step 3: Normalize (Procrustes) for the normalizedFrames payload
      final normalized = smoothed.map(_preprocessor.normalize).toList();

      state = state.copyWith(
        processingProgress: 0.8,
        relevantAngles: relevantAngles,
      );

      // Step 4: Move to upload phase
      state = state.copyWith(
        phase: RecordingPhase.uploading,
        processingProgress: 1.0,
      );

      AppLogger.info(
        'Processing complete: ${smoothed.length} frames, '
        '${features.length} feature frames, '
        '${normalized.length} normalized frames, '
        '${relevantAngles.length} relevant angles: $relevantAngles',
        tag: 'FormRecording',
      );

      await _uploadForm(normalizedFrames: normalized);
    } catch (e) {
      AppLogger.error('Processing failed', tag: 'FormRecording', error: e);
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: 'Failed to process recording: $e',
      );
    }
  }

  /// Upload the processed form to the server.
  Future<void> _uploadForm({List<LandmarkFrame>? normalizedFrames}) async {
    try {
      final repo = ref.read(coachPoseRepositoryProvider);

      // FPS = pose/vertex data rate (landmark frames per second), not video FPS
      var processedFrames = state.processedFrames;
      var featureFrames = state.featureFrames;
      var normalizedForUpload = normalizedFrames;

      var poseFrameCount = processedFrames.length;
      var frameRate = state.recordingDurationMs > 0 && poseFrameCount > 0
          ? (poseFrameCount * 1000 / state.recordingDurationMs).round()
          : 0;

      // Post-processing: if pose data is below 30 FPS but we have enough to interpolate, upsample
      const minFpsToUpsample = 15;
      if (frameRate < kMinFrameRate &&
          frameRate >= minFpsToUpsample &&
          state.recordingDurationMs > 0) {
        AppLogger.info(
          'Upsampling pose data from $frameRate FPS to $kMinFrameRate FPS (post-processing)',
          tag: 'FormRecording',
        );
        processedFrames = LandmarkPreprocessor.upsampleToTargetFps(
          processedFrames,
          state.recordingDurationMs,
          kMinFrameRate,
        );
        featureFrames = _featureExtractor.extractBatch(processedFrames);
        normalizedForUpload = processedFrames.map(_preprocessor.normalize).toList();
        poseFrameCount = processedFrames.length;
        frameRate = kMinFrameRate;
      }

      if (frameRate < kMinFrameRate) {
        AppLogger.warning(
          'Pose data rate ($frameRate FPS) below minimum '
          '($kMinFrameRate FPS) — rejecting upload',
          tag: 'FormRecording',
        );
        state = state.copyWith(
          phase: RecordingPhase.error,
          errorMessage:
              'Pose data rate too low ($frameRate FPS). '
              'Minimum $kMinFrameRate FPS of pose data required for accurate analysis. '
              'Keep your whole body in frame and try again.',
        );
        return;
      }

      // Compute average confidence
      double avgConfidence = 0;
      if (processedFrames.isNotEmpty) {
        final totalConfidence = processedFrames
            .expand((f) => f.landmarks.values)
            .map((p) => p.confidence)
            .fold<double>(0, (sum, c) => sum + c);
        final totalPoints = processedFrames.fold<int>(
          0,
          (sum, f) => sum + f.landmarks.length,
        );
        if (totalPoints > 0) {
          avgConfidence = totalConfidence / totalPoints;
        }
      }

      final result = await repo.uploadForm(
        exerciseId: state.exerciseId,
        cameraAngle: state.cameraAngle.serverValue,
        durationMs: state.recordingDurationMs,
        frameRate: frameRate,
        totalFrames: poseFrameCount,
        landmarkFrames: processedFrames.map((f) => f.toJson()).toList(),
        featureFrames: featureFrames.map((f) => f.toJson()).toList(),
        normalizedFrames: normalizedForUpload?.map((f) => f.toJson()).toList(),
        relevantAngles: state.relevantAngles.isNotEmpty
            ? state.relevantAngles
            : null,
        avgLandmarkConfidence: avgConfidence,
        recordingQuality: _assessQuality(avgConfidence),
      );

      result.when(
        success: (form) {
          AppLogger.info('Form uploaded: ${form.id}', tag: 'FormRecording');
          state = state.copyWith(
            phase: RecordingPhase.complete,
            uploadedForm: form,
          );
        },
        failure: (error) {
          AppLogger.error('Upload failed', tag: 'FormRecording', error: error);
          state = state.copyWith(
            phase: RecordingPhase.error,
            errorMessage: 'Failed to upload form: ${error.message}',
          );
        },
      );
    } catch (e) {
      AppLogger.error('Upload exception', tag: 'FormRecording', error: e);
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: 'Upload error: $e',
      );
    }
  }

  String _assessQuality(double avgConfidence) {
    if (avgConfidence >= 0.8) return 'good';
    if (avgConfidence >= 0.5) return 'acceptable';
    return 'poor';
  }

  /// Retry upload after a failure.
  Future<void> retryUpload() async {
    if (state.phase != RecordingPhase.error) return;
    state = state.copyWith(phase: RecordingPhase.uploading, clearError: true);
    await _uploadForm();
  }

  /// Reset to idle state for a fresh recording.
  void reset() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _setupStableSince = null;
    state = FormRecordingState(exerciseId: state.exerciseId);
  }

  /// Change camera angle before recording starts.
  void setCameraAngle(CameraAngle angle) {
    if (state.phase == RecordingPhase.setupGuidance ||
        state.phase == RecordingPhase.idle) {
      state = state.copyWith(cameraAngle: angle);
    }
  }
}
