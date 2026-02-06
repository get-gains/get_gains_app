import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/coach_pose_repository.dart';
import '../../data/models/models.dart';
import '../../services/feature_extractor.dart';
import '../../services/landmark_preprocessor.dart';
import '../../services/setup_validation_service.dart';

part 'form_recording_provider.g.dart';

/// Recording state machine states.
enum RecordingPhase {
  idle,
  setupGuidance,
  recording,
  processing,
  uploading,
  complete,
  error,
}

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
    this.recordingStartMs,
    this.recordingDurationMs = 0,
    this.frameCount = 0,
    this.processingProgress = 0.0,
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
  final int? recordingStartMs;
  final int recordingDurationMs;
  final int frameCount;
  final double processingProgress; // 0.0 to 1.0
  final String? errorMessage;
  final ExerciseFormModel? uploadedForm;

  bool get canStartRecording =>
      phase == RecordingPhase.setupGuidance &&
      (setupValidation?.allPassed ?? false);

  bool get isRecording => phase == RecordingPhase.recording;

  FormRecordingState copyWith({
    RecordingPhase? phase,
    String? exerciseId,
    CameraAngle? cameraAngle,
    SetupValidationResult? setupValidation,
    List<LandmarkFrame>? rawFrames,
    List<LandmarkFrame>? processedFrames,
    List<FeatureFrame>? featureFrames,
    int? recordingStartMs,
    int? recordingDurationMs,
    int? frameCount,
    double? processingProgress,
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
      recordingStartMs: recordingStartMs ?? this.recordingStartMs,
      recordingDurationMs: recordingDurationMs ?? this.recordingDurationMs,
      frameCount: frameCount ?? this.frameCount,
      processingProgress: processingProgress ?? this.processingProgress,
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

  @override
  FormRecordingState build(String exerciseId) {
    _preprocessor = LandmarkPreprocessor();
    _featureExtractor = FeatureExtractor();
    _setupValidator = SetupValidationService();

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
  }

  /// Transition from setup to active recording.
  void startRecording() {
    if (!state.canStartRecording) {
      AppLogger.warning(
        'Cannot start recording — setup checks not passed',
        tag: 'FormRecording',
      );
      return;
    }

    state = state.copyWith(
      phase: RecordingPhase.recording,
      rawFrames: [],
      recordingStartMs: DateTime.now().millisecondsSinceEpoch,
      frameCount: 0,
    );

    AppLogger.info('Recording started', tag: 'FormRecording');
  }

  /// Add a frame captured during recording.
  void addFrame(LandmarkFrame frame) {
    if (state.phase != RecordingPhase.recording) return;

    state = state.copyWith(
      rawFrames: [...state.rawFrames, frame],
      frameCount: state.frameCount + 1,
    );
  }

  /// Stop recording and begin processing.
  Future<void> stopRecording() async {
    if (state.phase != RecordingPhase.recording) return;

    final endMs = DateTime.now().millisecondsSinceEpoch;
    final durationMs = endMs - (state.recordingStartMs ?? endMs);

    state = state.copyWith(
      phase: RecordingPhase.processing,
      recordingDurationMs: durationMs,
      processingProgress: 0.0,
    );

    AppLogger.info(
      'Recording stopped. ${state.rawFrames.length} frames, ${durationMs}ms',
      tag: 'FormRecording',
    );

    await _processFrames();
  }

  /// Process recorded frames: preprocess → extract features.
  Future<void> _processFrames() async {
    try {
      // Step 1: Preprocess landmarks (filter, smooth, normalize)
      state = state.copyWith(processingProgress: 0.2);
      final processed = _preprocessor.processBatch(state.rawFrames);

      state = state.copyWith(
        processedFrames: processed,
        processingProgress: 0.5,
      );

      // Step 2: Extract features (joint angles)
      final features = _featureExtractor.extractBatch(processed);

      state = state.copyWith(featureFrames: features, processingProgress: 0.8);

      // Step 3: Move to upload phase
      state = state.copyWith(
        phase: RecordingPhase.uploading,
        processingProgress: 1.0,
      );

      AppLogger.info(
        'Processing complete: ${processed.length} frames, ${features.length} feature frames',
        tag: 'FormRecording',
      );

      await _uploadForm();
    } catch (e) {
      AppLogger.error('Processing failed', tag: 'FormRecording', error: e);
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: 'Failed to process recording: $e',
      );
    }
  }

  /// Upload the processed form to the server.
  Future<void> _uploadForm() async {
    try {
      final repo = ref.read(coachPoseRepositoryProvider);

      final frameRate = state.recordingDurationMs > 0
          ? (state.rawFrames.length * 1000 / state.recordingDurationMs).round()
          : 30;

      // Compute average confidence
      double avgConfidence = 0;
      if (state.processedFrames.isNotEmpty) {
        final totalConfidence = state.processedFrames
            .expand((f) => f.landmarks.values)
            .map((p) => p.confidence)
            .fold<double>(0, (sum, c) => sum + c);
        final totalPoints = state.processedFrames.fold<int>(
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
        totalFrames: state.rawFrames.length,
        landmarkFrames: state.processedFrames.map((f) => f.toJson()).toList(),
        featureFrames: state.featureFrames.map((f) => f.toJson()).toList(),
        normalizedFrames: state.processedFrames.map((f) => f.toJson()).toList(),
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
