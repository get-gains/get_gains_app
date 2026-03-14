import 'dart:async';
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../coach_pose/data/models/models.dart';
import '../../../coach_pose/services/feature_extractor.dart';
import '../../../coach_pose/services/landmark_preprocessor.dart';
import '../../data/client_pose_repository.dart';
import '../../data/models/models.dart';
import '../../services/form_comparison_service.dart';
import '../../services/rep_counter.dart';

part 'client_recording_provider.g.dart';

/// Minimum acceptable frame rate (FPS) for a client recording.
/// Recordings below this threshold produce unreliable DTW scores.
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
  const ClientRecordingProcessing();
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
  late final RepCounter _repCounter;
  late final FormComparisonService _comparisonService;

  // Recording state
  final List<LandmarkFrame> _clientLandmarks = []; // Raw 0-1 coords for display
  final List<LandmarkFrame> _clientNormalizedLandmarks =
      []; // Procrustes-normalized for comparison
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
  Map<String, LandmarkPoint> _lastDisplayLandmarks = {};

  // Velocity-adaptive EMA parameters
  static const double _emaAlphaMin = 0.12; // heavy smoothing for noise
  static const double _emaAlphaMax = 0.55; // light smoothing for real movement
  static const double _noiseGate = 0.005; // movement below this is clamped to 0
  static const double _velocitySaturation =
      0.06; // movement above this gets max alpha
  static const double _minDisplayConfidence = 0.5;

  @override
  ClientRecordingState build(String exerciseId) {
    _featureExtractor = FeatureExtractor();
    _preprocessor = LandmarkPreprocessor();
    _repCounter = RepCounter();
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

          // Tell the rep counter which exercise this is
          _repCounter.configure(exerciseName: _exerciseName);

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

  /// Step 2: Start recording
  void startRecording() {
    _clientLandmarks.clear();
    _clientNormalizedLandmarks.clear();
    _clientFeatures.clear();
    _lastDisplayLandmarks = {};
    _repCounter.reset();
    _recordingStartMs = DateTime.now().millisecondsSinceEpoch;

    state = ClientRecordingActive(
      exerciseName: _exerciseName ?? 'Exercise',
      formId: _formId ?? '',
      cameraAngle: _cameraAngle ?? 'FRONT',
      referenceLandmarkFrames: _referenceLandmarks,
      referenceFeatureFrames: _referenceFeatures,
      clientLandmarkFrames: List.unmodifiable(_clientLandmarks),
      clientFeatureFrames: List.unmodifiable(_clientFeatures),
      repCount: 0,
      recordingDurationMs: 0,
      poseConfig: _poseConfig,
      coachName: _coachName,
    );
  }

  /// Step 3: Process each camera frame during recording.
  ///
  /// Only performs lightweight work to keep 30+ FPS capture rate:
  ///   - Stabilise landmarks for display
  ///   - Extract a single primary angle for the rep counter
  ///
  /// Full 3D normalisation and multi-angle feature extraction is deferred
  /// to [stopRecordingAndCompare] (post-record batch processing).
  void processFrame(LandmarkFrame landmarkFrame) {
    if (state is! ClientRecordingActive) return;

    // Stabilize raw landmarks for smooth display (keeps 0-1 range)
    final stabilized = _stabilizeForDisplay(landmarkFrame);
    _clientLandmarks.add(stabilized);

    // Lightweight: only extract the single primary angle for rep counting
    final primaryAngle = _repCounter.trackedAngle;
    FeatureFrame repFeature;
    if (primaryAngle != null) {
      repFeature = _featureExtractor.extractSingleAngle(
        stabilized,
        primaryAngle,
      );
    } else {
      // First frame — let the rep counter auto-detect from a full extraction
      repFeature = _featureExtractor.extractFrame(stabilized);
    }

    final repCount = _repCounter.processFrame(repFeature);

    final elapsed = DateTime.now().millisecondsSinceEpoch - _recordingStartMs;

    state = ClientRecordingActive(
      exerciseName: _exerciseName ?? 'Exercise',
      formId: _formId ?? '',
      cameraAngle: _cameraAngle ?? 'FRONT',
      referenceLandmarkFrames: _referenceLandmarks,
      referenceFeatureFrames: _referenceFeatures,
      clientLandmarkFrames: List.unmodifiable(_clientLandmarks),
      clientFeatureFrames: const [],
      repCount: repCount,
      recordingDurationMs: elapsed,
      poseConfig: _poseConfig,
      coachName: _coachName,
    );
  }

  /// Step 4: Stop recording and run comparison.
  ///
  /// All heavy processing happens here (post-record, during the loading
  /// screen) so that the live camera loop stays at 30+ FPS:
  ///   1. Trim raw landmarks to reference length
  ///   2. Batch normalise (3D Procrustes)
  ///   3. Extract features using only relevant angles
  ///   4. Run DTW comparison
  ///   5. Upload results
  Future<void> stopRecordingAndCompare() async {
    if (state is! ClientRecordingActive) return;
    final activeState = state as ClientRecordingActive;

    state = const ClientRecordingProcessing();

    try {
      // Validate minimum frame rate before processing
      final recordingDurationMs =
          DateTime.now().millisecondsSinceEpoch - _recordingStartMs;
      final clientFps = recordingDurationMs > 0
          ? (_clientLandmarks.length * 1000 / recordingDurationMs).round()
          : 0;

      if (clientFps < kMinClientFrameRate) {
        AppLogger.warning(
          'Client recording frame rate ($clientFps FPS) below minimum '
          '($kMinClientFrameRate FPS)',
          tag: 'ClientRecording',
        );
        state = ClientRecordingError(
          'Recording quality too low ($clientFps FPS). '
          'Minimum $kMinClientFrameRate FPS required. '
          'Please ensure good lighting and try again.',
        );
        return;
      }

      // Trim client landmarks to reference length (US2)
      final refLen = _referenceLandmarks.length;
      final trimLen = math.min(_clientLandmarks.length, refLen);
      final trimmedLandmarks = _clientLandmarks.sublist(0, trimLen);

      // Batch normalise the raw landmarks (3D Procrustes)
      final normalizedLandmarks = _preprocessor.processBatch(trimmedLandmarks);

      // Extract features using only the relevant angles (vertex-dilution fix)
      final angleDefinitions = _relevantAngles.isNotEmpty
          ? FeatureExtractor.filteredDefinitions(_relevantAngles)
          : null;

      final clientFeatures = _featureExtractor.extractBatch(
        normalizedLandmarks,
        angleDefinitions: angleDefinitions,
      );

      // Re-extract reference features with the same filtered definitions so
      // DTW compares apples to apples
      final referenceFeatures = _featureExtractor.extractBatch(
        _referenceLandmarks.map(_preprocessor.normalize).toList(),
        angleDefinitions: angleDefinitions,
      );

      AppLogger.info(
        'Post-record batch: ${normalizedLandmarks.length} frames, '
        '${clientFeatures.length} feature frames, '
        'angles: ${_relevantAngles.isNotEmpty ? _relevantAngles : "all"}',
        tag: 'ClientRecording',
      );

      // Run DTW comparison with batch-processed features
      final result = _comparisonService.compare(
        exerciseFormId: activeState.formId,
        referenceFrames: referenceFeatures,
        clientFrames: clientFeatures,
        cameraAngle: activeState.cameraAngle,
        avgLandmarkConfidence: null,
      );

      final repCount = _repCounter.repCount;

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
        repCount: repCount,
        uploadSuccess: uploadSuccess,
        referenceLandmarkFrames: List.unmodifiable(_referenceLandmarks),
        clientLandmarkFrames: List.unmodifiable(
          _preprocessor.smoothFrames(trimmedLandmarks),
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
    _clientLandmarks.clear();
    _clientNormalizedLandmarks.clear();
    _clientFeatures.clear();
    _lastDisplayLandmarks = {};
    _repCounter.reset();

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

  /// Velocity-adaptive EMA stabilization for smooth, jitter-free display.
  ///
  /// Instead of a fixed alpha, the blend factor scales with how much each
  /// landmark actually moved. Tiny movements (noise) get heavy smoothing,
  /// large movements (real motion) pass through quickly.
  LandmarkFrame _stabilizeForDisplay(LandmarkFrame frame) {
    final filtered = _preprocessor.filterByConfidence(frame);

    final current = filtered.landmarks;
    final prev = _lastDisplayLandmarks;
    final allKeys = <String>{...current.keys, ...prev.keys};
    final stabilized = <String, LandmarkPoint>{};

    for (final key in allKeys) {
      final curr = current[key];
      final old = prev[key];

      if (curr != null && old != null) {
        // Compute per-landmark velocity (Euclidean distance)
        final dx = curr.x - old.x;
        final dy = curr.y - old.y;
        final velocity = math.sqrt(dx * dx + dy * dy);

        // Below noise gate → snap to previous (no jitter)
        if (velocity < _noiseGate) {
          stabilized[key] = old;
          continue;
        }

        // Adaptive alpha: scales linearly from min to max based on velocity
        final t = ((velocity - _noiseGate) / (_velocitySaturation - _noiseGate))
            .clamp(0.0, 1.0);
        final alpha = _emaAlphaMin + t * (_emaAlphaMax - _emaAlphaMin);

        final x = (curr.x * alpha) + (old.x * (1 - alpha));
        final y = (curr.y * alpha) + (old.y * (1 - alpha));
        final z = (curr.z * alpha) + (old.z * (1 - alpha));
        stabilized[key] = LandmarkPoint(
          x: x.clamp(0.0, 1.0),
          y: y.clamp(0.0, 1.0),
          z: z,
          confidence: curr.confidence,
        );
      } else if (curr != null) {
        // New landmark — use as-is
        stabilized[key] = LandmarkPoint(
          x: curr.x.clamp(0.0, 1.0),
          y: curr.y.clamp(0.0, 1.0),
          z: curr.z,
          confidence: curr.confidence,
        );
      } else if (old != null) {
        // Landmark disappeared — hold with decaying confidence
        final decayedConfidence = old.confidence * 0.92;
        if (decayedConfidence >= _minDisplayConfidence) {
          stabilized[key] = LandmarkPoint(
            x: old.x,
            y: old.y,
            z: old.z,
            confidence: decayedConfidence,
          );
        }
      }
    }

    _lastDisplayLandmarks = stabilized;
    return LandmarkFrame(timestampMs: frame.timestampMs, landmarks: stabilized);
  }
}
