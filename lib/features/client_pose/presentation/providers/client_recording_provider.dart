import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../../services/pose/frames_blob.dart';
import '../../../../services/pose/frames_upload_service.dart';
import '../../../../services/pose/video_frame_extractor.dart';
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
    required this.formId,
    required this.cameraAngle,
    this.coachName,
  });

  final String exerciseName;
  final List<LandmarkFrame> referenceFrames;
  final List<FeatureFrame> referenceFeatureFrames;
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
    required this.referenceDurationMs,
    this.coachName,
    this.autoStopRequested = false,
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
  final int referenceDurationMs;
  final String? coachName;
  final bool autoStopRequested;
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
    this.recordedFramesKey,
    this.referenceLandmarkFrames = const [],
    this.clientLandmarkFrames = const [],
    this.exerciseName,
  });

  final ComparisonResultModel result;
  final int repCount;
  final bool uploadSuccess;
  final String? recordedFramesKey;
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
/// load reference form → setup → record (video) → extract frames →
/// MLKit batch → compare → upload blob to S3.
@riverpod
class ClientRecording extends _$ClientRecording {
  late final FeatureExtractor _featureExtractor;
  late final LandmarkPreprocessor _preprocessor;
  late final FormComparisonService _comparisonService;

  // Recording state
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
  String? _videoFilePath;
  int _recordingStartMs = 0;
  int _referenceDurationMs = 0;
  Timer? _elapsedTimer;

  @override
  ClientRecordingState build(String exerciseId) {
    _featureExtractor = FeatureExtractor();
    _preprocessor = LandmarkPreprocessor();
    _comparisonService = FormComparisonService();
    return const ClientRecordingInitial();
  }

  /// Step 1: Load the reference form from the server.
  ///
  /// The repo now fetches each form's frames blob from S3 via presigned
  /// download URL and merges them into `data['formsBlobs']`.
  Future<void> loadReferenceForm() async {
    state = const ClientRecordingLoadingForm();

    try {
      final repo = ref.read(clientPoseRepositoryProvider);
      final resultFuture = repo.downloadExerciseForm(exerciseId);

      // Form downloads contain heavy landmark payloads — allow generous timeout
      final result = await resultFuture.timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException(
          'Server did not respond within 120 seconds. Check your connection.',
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
          _cameraAngle =
              (form['camera_angle'] ?? form['cameraAngle']) as String?;
          _exerciseName = data['exerciseName'] as String?;
          _coachName = form['coachName'] as String?;

          // Parse reference data from the cached blob (fetched by repo)
          final formsBlobs = data['formsBlobs'] as Map<String, dynamic>?;
          final blobJson = formsBlobs?[_formId!] as Map<String, dynamic>?;
          final coachBlob = repo.parseCoachBlob(blobJson);

          List<LandmarkFrame> referenceFrames;
          List<FeatureFrame> referenceFeatureFrames;

          if (coachBlob != null) {
            // Reject old-format references — z normalization changed in v3
            if (coachBlob.version < 3) {
              state = const ClientRecordingError(
                'This reference form was recorded with an older app version '
                'and is no longer compatible. Ask your coach to re-record it.',
              );
              return;
            }

            referenceFrames = coachBlob.landmarkFrames;
            referenceFeatureFrames = coachBlob.featureFrames;

            // Use relevant angles from the blob if available
            if (coachBlob.relevantAngles != null &&
                coachBlob.relevantAngles!.isNotEmpty) {
              _relevantAngles = coachBlob.relevantAngles!;
            } else {
              _relevantAngles = FeatureExtractor.detectRelevantAngles(
                referenceFeatureFrames,
              );
            }

            // Duration from blob
            if (coachBlob.durationMs > 0) {
              _referenceDurationMs = coachBlob.durationMs + 500;
            } else if (referenceFrames.isNotEmpty) {
              _referenceDurationMs =
                  ((referenceFrames.length / 30) * 1000).round() + 500;
            }
          } else {
            // Fallback: try parsing inline frames from form JSON (legacy cache)
            final landmarkFramesJson = form['landmarkFrames'] as List? ?? [];
            referenceFrames = landmarkFramesJson
                .map((f) => LandmarkFrame.fromJson(f as Map<String, dynamic>))
                .toList();

            final featureFramesJson = form['featureFrames'] as List? ?? [];
            if (featureFramesJson.isNotEmpty) {
              referenceFeatureFrames = featureFramesJson
                  .map((f) => FeatureFrame.fromJson(f as Map<String, dynamic>))
                  .toList();
            } else {
              referenceFeatureFrames = referenceFrames
                  .map((lf) => _featureExtractor.extractFrame(lf))
                  .toList();
            }

            final relevantAnglesJson = form['relevantAngles'] as List?;
            if (relevantAnglesJson != null && relevantAnglesJson.isNotEmpty) {
              _relevantAngles = relevantAnglesJson.cast<String>();
            } else {
              _relevantAngles = FeatureExtractor.detectRelevantAngles(
                referenceFeatureFrames,
              );
            }

            final formDurationMs = form['durationMs'] as int?;
            if (formDurationMs != null && formDurationMs > 0) {
              _referenceDurationMs = formDurationMs + 500;
            } else if (referenceFrames.isNotEmpty) {
              _referenceDurationMs =
                  ((referenceFrames.length / 30) * 1000).round() + 500;
            }
          }

          _referenceFeatures = referenceFeatureFrames;
          _referenceLandmarks = referenceFrames;

          AppLogger.info(
            'Relevant angles for comparison: $_relevantAngles',
            tag: 'ClientRecording',
          );
          AppLogger.info(
            'Reference form duration: ${_referenceDurationMs}ms '
            '(${referenceFrames.length} frames)',
            tag: 'ClientRecording',
          );

          state = ClientRecordingReady(
            exerciseName: _exerciseName ?? 'Exercise',
            referenceFrames: referenceFrames,
            referenceFeatureFrames: referenceFeatureFrames,
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

  /// Step 2: Start recording. The screen starts video recording via
  /// [CameraController.startVideoRecording]; the provider just runs timers.
  void startRecording() {
    _clientLandmarks.clear();
    _clientNormalizedLandmarks.clear();
    _clientFeatures.clear();
    _videoFilePath = null;
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
      referenceDurationMs: _referenceDurationMs,
      coachName: _coachName,
    );

    // Update elapsed time every second so REC badge counts up.
    // Auto-stop recording when elapsed >= reference duration.
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is! ClientRecordingActive) return;
      final active = state as ClientRecordingActive;
      final elapsedMs =
          DateTime.now().millisecondsSinceEpoch - _recordingStartMs;

      // Auto-stop: elapsed reached the coach reference form duration
      if (_referenceDurationMs > 0 && elapsedMs >= _referenceDurationMs) {
        AppLogger.info(
          'Auto-stopping recording: elapsed ${elapsedMs}ms >= '
          'reference ${_referenceDurationMs}ms',
          tag: 'ClientRecording',
        );
        stopRecording();
        return;
      }

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
        referenceDurationMs: _referenceDurationMs,
        coachName: active.coachName,
        autoStopRequested: active.autoStopRequested,
      );
    });
  }

  /// Signal to stop recording.
  ///
  /// The screen owns [CameraController] and listens for this flag to call
  /// `stopVideoRecording()` exactly once, then forwards the output via
  /// [setRecordedVideo].
  void stopRecording() {
    if (state is! ClientRecordingActive) return;
    final active = state as ClientRecordingActive;
    if (active.autoStopRequested) return;

    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    state = ClientRecordingActive(
      exerciseName: active.exerciseName,
      formId: active.formId,
      cameraAngle: active.cameraAngle,
      referenceLandmarkFrames: active.referenceLandmarkFrames,
      referenceFeatureFrames: active.referenceFeatureFrames,
      clientLandmarkFrames: active.clientLandmarkFrames,
      clientFeatureFrames: active.clientFeatureFrames,
      repCount: active.repCount,
      recordingDurationMs: active.recordingDurationMs,
      referenceDurationMs: active.referenceDurationMs,
      coachName: active.coachName,
      autoStopRequested: true,
    );
  }

  /// Called by the screen after [CameraController.stopVideoRecording] returns.
  /// Transitions to processing and kicks off the video → ffmpeg → MLKit pipeline.
  void setRecordedVideo(String path) {
    _videoFilePath = path;

    final endMs = DateTime.now().millisecondsSinceEpoch;
    final durationMs = endMs - _recordingStartMs;

    state = const ClientRecordingProcessing(
      progress: 0.0,
      message: 'Extracting frames...',
    );

    AppLogger.info(
      'Recording stopped. Video at $path, ${durationMs}ms',
      tag: 'ClientRecording',
    );

    _processVideo(durationMs);
  }

  /// Called by the screen if camera stop fails.
  void setRecordingError(String message) {
    state = ClientRecordingError(message);
  }

  /// Legacy entry point — stop recording and run comparison directly.
  /// Now just signals the screen to stop video recording; the actual
  /// processing starts when [setRecordedVideo] is called.
  Future<void> stopRecordingAndCompare() async {
    stopRecording();
  }

  /// Extract frames from video via ffmpeg, run MLKit on each, then compare.
  Future<void> _processVideo(int recordingDurationMs) async {
    final videoPath = _videoFilePath;
    if (videoPath == null) {
      state = const ClientRecordingError(
        'No video file available for processing.',
      );
      return;
    }

    List<File> extractedFrames = [];
    try {
      final extractor = ref.read(videoFrameExtractorProvider);
      final poseService = ref.read(poseDetectionServiceProvider);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final dir = await extractor.createTempFrameDir('client-$exerciseId-$ts');

      state = const ClientRecordingProcessing(
        progress: 0.05,
        message: 'Extracting frames...',
      );

      extractedFrames = await extractor.extractFrames(
        videoPath: videoPath,
        targetFps: 30,
        outputDirPath: dir,
      );

      AppLogger.info(
        'Extracted ${extractedFrames.length} frames from video',
        tag: 'ClientRecording',
      );

      state = const ClientRecordingProcessing(
        progress: 0.1,
        message: 'Detecting pose...',
      );

      // Run MLKit on each extracted frame sequentially
      final startMs = _recordingStartMs;
      final rawLandmarks = <LandmarkFrame>[];
      for (var i = 0; i < extractedFrames.length; i++) {
        state = ClientRecordingProcessing(
          progress: 0.1 + 0.2 * (i / math.max(1, extractedFrames.length)),
          message: 'Detecting pose...',
        );
        final timestampMs = startMs + (i * 1000 ~/ 30);
        final frame = await poseService.processImageFile(
          extractedFrames[i],
          timestampMs,
        );
        rawLandmarks.add(
          frame ?? LandmarkFrame(timestampMs: timestampMs, landmarks: const {}),
        );
      }

      state = const ClientRecordingProcessing(
        progress: 0.35,
        message: 'Analyzing form...',
      );

      var clientLandmarksForPipeline = rawLandmarks;
      var poseFps =
          recordingDurationMs > 0 && clientLandmarksForPipeline.isNotEmpty
          ? (clientLandmarksForPipeline.length * 1000 / recordingDurationMs)
                .round()
          : 0;

      // Post-processing: if below 30 FPS but we have enough data, upsample
      const minFpsToUpsample = 10;
      if (poseFps < kMinClientFrameRate &&
          poseFps >= minFpsToUpsample &&
          recordingDurationMs > 0) {
        AppLogger.info(
          'Upsampling client pose data from $poseFps FPS to $kMinClientFrameRate FPS',
          tag: 'ClientRecording',
        );
        clientLandmarksForPipeline = LandmarkPreprocessor.upsampleToTargetFps(
          clientLandmarksForPipeline,
          recordingDurationMs,
          kMinClientFrameRate,
        );
        poseFps =
            (clientLandmarksForPipeline.length * 1000 / recordingDurationMs)
                .round();
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

      // Reference: same pipeline as client
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

      // Temporal alignment: try several client start offsets, keep best-scoring
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
        exerciseFormId: _formId ?? '',
        referenceFrames: referenceFeatures,
        clientFrames: _featureExtractor.extractBatch(
          _preprocessor.processBatch(
            clientLandmarksForPipeline.sublist(0, trimLen),
          ),
          angleDefinitions: angleDefinitions,
        ),
        cameraAngle: _cameraAngle ?? 'FRONT',
        avgLandmarkConfidence: null,
      );
      List<LandmarkFrame> bestTrimmedLandmarks = clientLandmarksForPipeline
          .sublist(0, trimLen);

      final maxOffset = trimLen == refLen
          ? math.min(maxOffsetFrames, clientLen - refLen)
          : -1;
      if (maxOffset > 0) {
        int tries = 0;
        for (
          int o = 0;
          o <= maxOffset && tries < maxTries;
          o += offsetStep, tries++
        ) {
          if (o + refLen > clientLen) break;
          final trimmed = clientLandmarksForPipeline.sublist(o, o + refLen);
          final normalizedLandmarks = _preprocessor.processBatch(trimmed);
          final clientFeatures = _featureExtractor.extractBatch(
            normalizedLandmarks,
            angleDefinitions: angleDefinitions,
          );
          final result = _comparisonService.compare(
            exerciseFormId: _formId ?? '',
            referenceFrames: referenceFeatures,
            clientFrames: clientFeatures,
            cameraAngle: _cameraAngle ?? 'FRONT',
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
        progress: 0.85,
        message: 'Uploading result...',
      );

      AppLogger.info(
        'Post-record batch: ${bestTrimmedLandmarks.length} frames, '
        'angles: ${_relevantAngles.isNotEmpty ? _relevantAngles : "all"}',
        tag: 'ClientRecording',
      );

      // Build and upload ClientFramesBlob to S3
      bool uploadSuccess = false;
      String? recordedFramesKey;
      try {
        final clientNormalized = _preprocessor.processBatch(
          bestTrimmedLandmarks,
        );
        final clientFeatureFrames = _featureExtractor.extractBatch(
          clientNormalized,
          angleDefinitions: angleDefinitions,
        );

        final blob = FramesBlob.client(
          version: 3,
          cameraAngle: _cameraAngle ?? 'FRONT',
          durationMs: recordingDurationMs,
          frameRate: poseFps,
          totalFrames: bestTrimmedLandmarks.length,
          landmarkFrames: bestTrimmedLandmarks,
          featureFrames: clientFeatureFrames,
          overallScore: result.overallScore,
          segmentScores: result.segmentScores,
          corrections: result.corrections,
          relevantAngles: _relevantAngles.isNotEmpty ? _relevantAngles : null,
        );

        final uploadService = ref.read(framesUploadServiceProvider);
        final keyResult = await uploadService.uploadClientSetFrames(
          workoutSessionId: 'standalone',
          setNumber: 1,
          framesBlob: blob.toJson(),
        );

        keyResult.when(
          success: (key) {
            recordedFramesKey = key;
            uploadSuccess = true;
          },
          failure: (error) {
            AppLogger.warning(
              'Failed to upload client frames blob: ${error.message}',
              tag: 'ClientRecording',
            );
          },
        );
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
        recordedFramesKey: recordedFramesKey,
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
    } finally {
      // Cleanup: delete extracted frames and video file
      if (extractedFrames.isNotEmpty) {
        ref.read(videoFrameExtractorProvider).cleanup(extractedFrames);
      }
      if (videoPath != null) {
        try {
          await File(videoPath).delete();
        } catch (_) {}
      }
    }
  }

  /// Reset to initial state for another attempt
  void resetForNewAttempt() {
    _clientLandmarks.clear();
    _clientNormalizedLandmarks.clear();
    _clientFeatures.clear();
    _videoFilePath = null;

    if (_formId != null) {
      state = ClientRecordingReady(
        exerciseName: _exerciseName ?? 'Exercise',
        referenceFrames: _referenceLandmarks,
        referenceFeatureFrames: _referenceFeatures,
        formId: _formId!,
        cameraAngle: _cameraAngle ?? 'FRONT',
        coachName: _coachName,
      );
    } else {
      state = const ClientRecordingInitial();
    }
  }
}
