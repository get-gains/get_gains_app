import 'dart:async';
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../coach_pose/data/models/models.dart';
import '../../../coach_pose/services/feature_extractor.dart';
import '../../../coach_pose/services/landmark_preprocessor.dart';
import '../../../coach_pose/services/pose_detection_service.dart';
import '../../data/client_pose_repository.dart';
import '../../data/models/models.dart';
import '../../services/form_comparison_service.dart';

part 'client_recording_provider.g.dart';

/// Minimum pose/vertex data rate (FPS) for client recording.
/// We require 30+ landmark frames per second for DTW; video FPS is irrelevant.
const kMinClientFrameRate = 30;

/// State for the client recording + comparison pipeline.
sealed class ClientRecordingState {
  const ClientRecordingState();
}

/// Initial state — not yet started
class ClientRecordingInitial extends ClientRecordingState {
  const ClientRecordingInitial();
}

/// Loading reference form data from server
class ClientRecordingLoadingForm extends ClientRecordingState {
  const ClientRecordingLoadingForm();
}

/// Reference form loaded, ready for setup
class ClientRecordingReady extends ClientRecordingState {
  const ClientRecordingReady({
    required this.exerciseName,
    required this.referenceFrames,
    required this.referenceFeatureFrames,
    required this.poseConfig,
    required this.formId,
    required this.cameraAngle,
    this.coachName,
  });

  final String exerciseName;
  final List<LandmarkFrame> referenceFrames;
  final List<FeatureFrame> referenceFeatureFrames;
  final PoseConfigModel? poseConfig;
  final String formId;
  final String cameraAngle;
  final String? coachName;
}

/// Client is actively recording
class ClientRecordingActive extends ClientRecordingState {
  const ClientRecordingActive({
    required this.exerciseName,
    required this.formId,
    required this.cameraAngle,
    required this.referenceLandmarkFrames,
    required this.referenceFeatureFrames,
    required this.clientLandmarkFrames,
    required this.clientFeatureFrames,
    required this.repCount,
    required this.recordingDurationMs,
    this.poseConfig,
    this.coachName,
  });

  final String exerciseName;
  final String formId;
  final String cameraAngle;
  final List<LandmarkFrame> referenceLandmarkFrames;
  final List<FeatureFrame> referenceFeatureFrames;
  final List<LandmarkFrame> clientLandmarkFrames;
  final List<FeatureFrame> clientFeatureFrames;
  final int repCount;
  final int recordingDurationMs;
  final PoseConfigModel? poseConfig;
  final String? coachName;
}

/// Recording stopped, processing comparison
class ClientRecordingProcessing extends ClientRecordingState {
  const ClientRecordingProcessing({
    this.progress = 0.0,
    this.message = 'Preparing...',
  });
  final double progress;
  final String message;
}

/// Comparison complete — show results
class ClientRecordingComplete extends ClientRecordingState {
  const ClientRecordingComplete({
    required this.result,
    required this.repCount,
    this.uploadSuccess = false,
    this.referenceLandmarkFrames = const [],
    this.clientLandmarkFrames = const [],
    this.exerciseName,
  });

  final ComparisonResultModel result;
  final int repCount;
  final bool uploadSuccess;
  final List<LandmarkFrame> referenceLandmarkFrames;
  final List<LandmarkFrame> clientLandmarkFrames;
  final String? exerciseName;
}

/// Error state
class ClientRecordingError extends ClientRecordingState {
  const ClientRecordingError(this.message);
  final String message;
}

/// Manages the full client recording + comparison pipeline:
/// load reference form → setup → record → process → compare → upload.
@riverpod
class ClientRecording extends _$ClientRecording {
  late final FeatureExtractor _featureExtractor;
  late final LandmarkPreprocessor _preprocessor;
  late final FormComparisonService _comparisonService;

  // Recording state: raw capture only during recording; no live MLKit or rep counter
  final List<CapturedFrame> _capturedFramesBuffer = [];
  final List<LandmarkFrame> _clientLandmarks = [];
  final List<LandmarkFrame> _clientNormalizedLandmarks = [];
  final List<FeatureFrame> _clientFeatures = [];
  List<FeatureFrame> _referenceFeatures = [];
  List<LandmarkFrame> _referenceLandmarks = [];
  List<String> _relevantAngles = [];
  String? _formId;
  String? _cameraAngle;
  String? _exerciseName;
  String? _coachName;
  PoseConfigModel? _poseConfig;
  int _recordingStartMs = 0;
  Timer? _elapsedTimer;

  @override
  ClientRecordingState build(String exerciseId) {
    _featureExtractor = FeatureExtractor();
    _preprocessor = LandmarkPreprocessor();
    _comparisonService = FormComparisonService();
    return const ClientRecordingInitial();
  }

  /// Step 1: Load the reference form from the server
  Future<void> loadReferenceForm() async {
    state = const ClientRecordingLoadingForm();

    try {
      final repo = ref.read(clientPoseRepositoryProvider);
      final resultFuture = repo.downloadExerciseForm(exerciseId);

      // Apply a 15-second timeout so the screen never hangs indefinitely
      final result = await resultFuture.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Server did not respond within 15 seconds. Check your connection.',
        ),
      );

      result.when(
        success: (data) {
          final forms = data['forms'] as List?;
          if (forms == null || forms.isEmpty) {
            state = const ClientRecordingError(
              'No active reference form found for this exercise. '
              'Ask your coach to record and activate a form.',
            );
            return;
          }

          final form = forms.first as Map<String, dynamic>;
          _formId = form['id'] as String;
          _cameraAngle = form['cameraAngle'] as String;
          _exerciseName = data['exerciseName'] as String?;
          _coachName = form['coachName'] as String?;

          // Parse reference landmark frames
          final landmarkFramesJson = form['landmarkFrames'] as List? ?? [];
          final referenceFrames = landmarkFramesJson
              .map((f) => LandmarkFrame.fromJson(f as Map<String, dynamic>))
              .toList();

          // Parse or extract feature frames
          final featureFramesJson = form['featureFrames'] as List? ?? [];
          List<FeatureFrame> referenceFeatureFrames;
          if (featureFramesJson.isNotEmpty) {
            referenceFeatureFrames = featureFramesJson
                .map((f) => FeatureFrame.fromJson(f as Map<String, dynamic>))
                .toList();
          } else {
            // Extract features from landmarks
            referenceFeatureFrames = referenceFrames
                .map((lf) => _featureExtractor.extractFrame(lf))
                .toList();
          }
          _referenceFeatures = referenceFeatureFrames;
          _referenceLandmarks = referenceFrames;

          // Parse relevant angles from the form (hybrid vertex-dilution fix)
          final relevantAnglesJson = form['relevantAngles'] as List?;
          if (relevantAnglesJson != null && relevantAnglesJson.isNotEmpty) {
            _relevantAngles = relevantAnglesJson.cast<String>();
          } else {
            // Fallback: auto-detect from reference feature frames
            _relevantAngles = FeatureExtractor.detectRelevantAngles(
              referenceFeatureFrames,
            );
          }
          AppLogger.info(
            'Relevant angles for comparison: $_relevantAngles',
            tag: 'ClientRecording',
          );

          // Parse pose config if available
          final configJson = data['poseConfig'] as Map<String, dynamic>?;
          if (configJson != null) {
            try {
              _poseConfig = PoseConfigModel.fromJson({
                'id': '',
                'exerciseId': exerciseId,
                ...configJson,
              });
            } catch (e) {
              AppLogger.warning(
                'Failed to parse pose config: $e',
                tag: 'ClientRecording',
              );
            }
          }

          state = ClientRecordingReady(
            exerciseName: _exerciseName ?? 'Exercise',
            referenceFrames: referenceFrames,
            referenceFeatureFrames: referenceFeatureFrames,
            poseConfig: _poseConfig,
            formId: _formId!,
            cameraAngle: _cameraAngle ?? 'FRONT',
            coachName: _coachName,
          );
        },
        failure: (error) {
          state = ClientRecordingError(
            'Failed to load reference form: ${error.message}',
          );
        },
      );
    } catch (e) {
      AppLogger.error(
        'Error loading reference form',
        tag: 'ClientRecording',
        error: e,
      );
      state = ClientRecordingError('Failed to load reference form: $e');
    }
  }

  /// Step 2: Start recording (capture only; no live MLKit or rep counter)
  void startRecording() {
    _capturedFramesBuffer.clear();
    _clientLandmarks.clear();
    _clientNormalizedLandmarks.clear();
    _clientFeatures.clear();
    _recordingStartMs = DateTime.now().millisecondsSinceEpoch;
    _elapsedTimer?.cancel();

    state = ClientRecordingActive(
      exerciseName: _exerciseName ?? 'Exercise',
      formId: _formId ?? '',
      cameraAngle: _cameraAngle ?? 'FRONT',
      referenceLandmarkFrames: _referenceLandmarks,
      referenceFeatureFrames: _referenceFeatures,
      clientLandmarkFrames: const [],
      clientFeatureFrames: const [],
      repCount: 0,
      recordingDurationMs: 0,
      poseConfig: _poseConfig,
      coachName: _coachName,
    );

    // Update elapsed time every second so REC badge counts up
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is! ClientRecordingActive) return;
      final active = state as ClientRecordingActive;
      final elapsedMs = DateTime.now().millisecondsSinceEpoch - _recordingStartMs;
      state = ClientRecordingActive(
        exerciseName: active.exerciseName,
        formId: active.formId,
        cameraAngle: active.cameraAngle,
        referenceLandmarkFrames: active.referenceLandmarkFrames,
        referenceFeatureFrames: active.referenceFeatureFrames,
        clientLandmarkFrames: active.clientLandmarkFrames,
        clientFeatureFrames: active.clientFeatureFrames,
        repCount: active.repCount,
        recordingDurationMs: elapsedMs,
        poseConfig: active.poseConfig,
        coachName: active.coachName,
      );
    });
  }

  /// Add a raw camera frame during recording (no MLKit). Post-processing runs after stop.
  void addCapturedFrame(CapturedFrame frame) {
    if (state is! ClientRecordingActive) return;
    _capturedFramesBuffer.add(frame);
  }

  /// Step 4: Stop recording and run comparison.
  ///
  /// Same quality as coach: batch MLKit on captured frames, then normalize, features, DTW.
  ///   1. Run MLKit on each captured frame (post-record, high sampling)
  ///   2. Upsample to 30 FPS if needed
  ///   3. Trim to reference length, batch normalise, extract features, DTW, upload
  Future<void> stopRecordingAndCompare() async {
    if (state is! ClientRecordingActive) return;
    final activeState = state as ClientRecordingActive;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    state = const ClientRecordingProcessing(
      progress: 0.0,
      message: 'Detecting pose...',
    );

    try {
      final recordingDurationMs =
          DateTime.now().millisecondsSinceEpoch - _recordingStartMs;
      final captured = List<CapturedFrame>.from(_capturedFramesBuffer);
      _capturedFramesBuffer.clear();

      // Batch MLKit on captured frames (same as coach — high-quality pose data from full capture rate)
      final poseService = ref.read(poseDetectionServiceProvider);
      final startMs = _recordingStartMs;
      final rawLandmarks = <LandmarkFrame>[];
      for (var i = 0; i < captured.length; i++) {
        state = ClientRecordingProcessing(
          progress: 0.05 + 0.25 * (i / math.max(1, captured.length)),
          message: 'Detecting pose...',
        );
        final timestampMs = startMs + (i * 1000 ~/ 30);
        final frame = await poseService.processCapturedFrame(
          captured[i],
          timestampMs,
        );
        if (frame != null) rawLandmarks.add(frame);
      }

      state = const ClientRecordingProcessing(
        progress: 0.35,
        message: 'Analyzing form...',
      );

      var clientLandmarksForPipeline = rawLandmarks;
      var poseFps = recordingDurationMs > 0 && clientLandmarksForPipeline.isNotEmpty
          ? (clientLandmarksForPipeline.length * 1000 / recordingDurationMs).round()
          : 0;

      // Post-processing: if below 30 FPS but we have enough data, upsample to 30 FPS
      // (e.g. when Unity + camera run together, capture rate can drop to ~12 FPS)
      const minFpsToUpsample = 10;
      if (poseFps < kMinClientFrameRate &&
          poseFps >= minFpsToUpsample &&
          recordingDurationMs > 0) {
        AppLogger.info(
          'Upsampling client pose data from $poseFps FPS to $kMinClientFrameRate FPS (post-processing)',
          tag: 'ClientRecording',
        );
        clientLandmarksForPipeline = LandmarkPreprocessor.upsampleToTargetFps(
          clientLandmarksForPipeline,
          recordingDurationMs,
          kMinClientFrameRate,
        );
        poseFps = (clientLandmarksForPipeline.length * 1000 / recordingDurationMs).round();
      }

      if (poseFps < kMinClientFrameRate) {
        AppLogger.warning(
          'Pose data rate ($poseFps FPS) below minimum '
          '($kMinClientFrameRate FPS)',
          tag: 'ClientRecording',
        );
        state = ClientRecordingError(
          'Pose data rate too low ($poseFps FPS). '
          'Minimum $kMinClientFrameRate FPS of pose data required for accurate analysis. '
          'Keep your whole body in frame and try again.',
        );
        return;
      }

      state = const ClientRecordingProcessing(
        progress: 0.45,
        message: 'Comparing to reference...',
      );

      // Reference: same pipeline as client (filter + normalize+align; skip smooth if already smoothed on server)
      final refLen = _referenceLandmarks.length;
      final angleDefinitions = _relevantAngles.isNotEmpty
          ? FeatureExtractor.filteredDefinitions(_relevantAngles)
          : null;
      final referenceNormalized = _preprocessor.processBatch(
        _referenceLandmarks,
        skipSmooth: true,
      );
      final referenceFeatures = _featureExtractor.extractBatch(
        referenceNormalized,
        angleDefinitions: angleDefinitions,
      );

      // Temporal alignment: try several client start offsets, keep best-scoring comparison
      const maxOffsetFrames = 30;
      const offsetStep = 2;
      const maxTries = 15;
      final clientLen = clientLandmarksForPipeline.length;
      final trimLen = math.min(clientLen, refLen);
      if (trimLen < refLen) {
        AppLogger.warning(
          'Client frames ($clientLen) shorter than reference ($refLen); no offset search',
          tag: 'ClientRecording',
        );
      }

      int bestOffset = 0;
      ComparisonResultModel bestResult = _comparisonService.compare(
        exerciseFormId: activeState.formId,
        referenceFrames: referenceFeatures,
        clientFrames: _featureExtractor.extractBatch(
          _preprocessor.processBatch(
            clientLandmarksForPipeline.sublist(0, trimLen),
          ),
          angleDefinitions: angleDefinitions,
        ),
        cameraAngle: activeState.cameraAngle,
        avgLandmarkConfidence: null,
      );
      List<LandmarkFrame> bestTrimmedLandmarks =
          clientLandmarksForPipeline.sublist(0, trimLen);

      final maxOffset = trimLen == refLen
          ? math.min(maxOffsetFrames, clientLen - refLen)
          : -1;
      if (maxOffset > 0) {
        int tries = 0;
        for (int o = 0; o <= maxOffset && tries < maxTries; o += offsetStep, tries++) {
          if (o + refLen > clientLen) break;
          final trimmed = clientLandmarksForPipeline.sublist(o, o + refLen);
          final normalizedLandmarks = _preprocessor.processBatch(trimmed);
          final clientFeatures = _featureExtractor.extractBatch(
            normalizedLandmarks,
            angleDefinitions: angleDefinitions,
          );
          final result = _comparisonService.compare(
            exerciseFormId: activeState.formId,
            referenceFrames: referenceFeatures,
            clientFrames: clientFeatures,
            cameraAngle: activeState.cameraAngle,
            avgLandmarkConfidence: null,
          );
          if (result.overallScore > bestResult.overallScore) {
            bestResult = result;
            bestOffset = o;
            bestTrimmedLandmarks = trimmed;
          }
        }
        if (bestOffset > 0) {
          AppLogger.info(
            'Best temporal offset: $bestOffset frames (score: ${(bestResult.overallScore * 100).toStringAsFixed(1)}%)',
            tag: 'ClientRecording',
          );
        }
      }

      final result = bestResult;

      state = const ClientRecordingProcessing(
        progress: 0.9,
        message: 'Uploading result...',
      );

      AppLogger.info(
        'Post-record batch: ${bestTrimmedLandmarks.length} frames, '
        'angles: ${_relevantAngles.isNotEmpty ? _relevantAngles : "all"}',
        tag: 'ClientRecording',
      );

      // Upload result to server
      bool uploadSuccess = false;
      try {
        final repo = ref.read(clientPoseRepositoryProvider);
        final uploadResult = await repo.submitResult(
          exerciseFormId: activeState.formId,
          overallScore: result.overallScore,
          segmentScores: result.segmentScores,
          corrections: result.corrections.map((c) => c.toJson()).toList(),
          cameraAngle: activeState.cameraAngle,
          durationMs: result.durationMs,
          frameRate: result.frameRate,
          totalFrames: result.totalFrames,
        );
        uploadSuccess = uploadResult.isSuccess;
      } catch (e) {
        AppLogger.warning(
          'Failed to upload comparison result: $e',
          tag: 'ClientRecording',
        );
      }

      state = ClientRecordingComplete(
        result: result,
        repCount: 0,
        uploadSuccess: uploadSuccess,
        referenceLandmarkFrames: List.unmodifiable(_referenceLandmarks),
        clientLandmarkFrames: List.unmodifiable(
          _preprocessor.smoothFrames(bestTrimmedLandmarks),
        ),
        exerciseName: _exerciseName,
      );
    } catch (e) {
      AppLogger.error(
        'Error during comparison',
        tag: 'ClientRecording',
        error: e,
      );
      state = ClientRecordingError('Comparison failed: $e');
    }
  }

  /// Reset to initial state for another attempt
  void resetForNewAttempt() {
    _capturedFramesBuffer.clear();
    _clientLandmarks.clear();
    _clientNormalizedLandmarks.clear();
    _clientFeatures.clear();

    if (_formId != null) {
      state = ClientRecordingReady(
        exerciseName: _exerciseName ?? 'Exercise',
        referenceFrames: _referenceLandmarks,
        referenceFeatureFrames: _referenceFeatures,
        poseConfig: _poseConfig,
        formId: _formId!,
        cameraAngle: _cameraAngle ?? 'FRONT',
        coachName: _coachName,
      );
    } else {
      state = const ClientRecordingInitial();
    }
  }

}
