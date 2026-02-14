# Pose Detection - Flutter App Implementation Plan

> **Status**: 🔮 Not Implemented  
> **Last Updated**: February 11, 2026  
> **Covers**: Camera Recording, MLKit Pose Detection, Feature Extraction, DTW Comparison, Limb Isolation, Offline Caching, Score & Corrections Display  
> **Depends On**: [CONTEXT.md](../CONTEXT.md), [Server POSE_DETECTION.md](../../get-gains-server/docs/features/POSE_DETECTION.md)

---

## Overview

### Purpose

The Pose Detection feature enables **on-device exercise form analysis** with all ML processing happening at the edge:

- **Coach Flow**: Record a reference form for an exercise → MLKit extracts landmarks → extract feature angles → upload processed data to server
- **Client Flow**: Download coach's reference form (offline-first) → record their own attempt → MLKit processes → DTW compares on-device → generate score + corrections → display results → upload results to server for records
- **Limb Isolation**: Configure which body segments to analyze per exercise, allowing partial body tracking and handling obstructed views
- **Offline-First**: Reference forms are downloaded and cached locally in Drift, enabling form comparison without network

### What Happens on the App vs. Server

| Responsibility | App (On-Device) | Server |
|---------------|-----------------|--------|
| Camera preview + recording | ✅ | ❌ |
| Setup guidance (lighting, distance, angle) | ✅ | ❌ |
| MLKit Pose Detection | ✅ | ❌ |
| Landmark preprocessing + smoothing | ✅ | ❌ |
| Feature extraction (joint angles, distances) | ✅ | ❌ |
| Normalization (Procrustes alignment) | ✅ | ❌ |
| DTW similarity comparison | ✅ | ❌ |
| Score calculation | ✅ | ❌ |
| Correction generation | ✅ | ❌ |
| Results display + visualization | ✅ | ❌ |
| Store/retrieve reference forms | ❌ (caches locally) | ✅ |
| Store comparison results | ❌ (generates, uploads) | ✅ |
| Limb isolation config | ❌ (reads from server) | ✅ |

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `camera` | existing | Camera preview and video recording |
| `google_mlkit_pose_detection` | existing | On-device pose landmark detection |
| `drift` | existing | Local SQLite caching for offline forms |
| `dio` | existing | HTTP client for API calls |
| `riverpod_annotation` | existing | State management |
| `freezed_annotation` | existing | Immutable models |
| `flutter_embed_unity` | existing | Unity 3D visualization (future) |
| `path_provider` | existing | Temp file storage for recordings |
| `video_player` | new (add) | Video frame extraction |
| `image` | new (add) | Image processing utilities |

### Entry Points (To Be Created)

| File | Description |
|------|-------------|
| `/lib/features/pose_detection/` | Feature root |
| `/lib/features/pose_detection/data/` | Models, repository |
| `/lib/features/pose_detection/services/` | MLKit, DTW, feature extraction |
| `/lib/features/pose_detection/presentation/` | Screens, providers, widgets |

---

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                              POSE DETECTION FEATURE                               │
│                                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                         PRESENTATION LAYER                                  │  │
│  │                                                                             │  │
│  │  Screens:                        Providers:                                 │  │
│  │  ┌─────────────────────┐        ┌──────────────────────────────┐           │  │
│  │  │ SetupGuidanceScreen │        │ poseRecordingProvider        │           │  │
│  │  │ RecordingScreen     │        │ poseProcessingProvider       │           │  │
│  │  │ ProcessingScreen    │        │ poseResultProvider           │           │  │
│  │  │ ResultScreen        │        │ formDownloadProvider         │           │  │
│  │  │ FormHistoryScreen   │        │ poseConfigProvider           │           │  │
│  │  └─────────────────────┘        └──────────────────────────────┘           │  │
│  │                                                                             │  │
│  │  Widgets:                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────┐               │  │
│  │  │ SetupChecklist, ScoreGauge, SegmentScoreCard,           │               │  │
│  │  │ CorrectionCard, AngleIndicator, LimbSelector            │               │  │
│  │  └─────────────────────────────────────────────────────────┘               │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
│                          │                                                        │
│                          ▼                                                        │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                          SERVICE LAYER                                      │  │
│  │                                                                             │  │
│  │  ┌─────────────────────┐  ┌───────────────────┐  ┌──────────────────────┐  │  │
│  │  │ PoseDetectionService│  │ FeatureExtractor  │  │ DTWComparisonService │  │  │
│  │  │ (MLKit wrapper)     │  │ (Angles/Distances)│  │ (Similarity scoring) │  │  │
│  │  └─────────────────────┘  └───────────────────┘  └──────────────────────┘  │  │
│  │                                                                             │  │
│  │  ┌─────────────────────┐  ┌───────────────────┐  ┌──────────────────────┐  │  │
│  │  │ LandmarkPreprocessor│  │ LimbIsolation     │  │ CorrectionGenerator  │  │  │
│  │  │ (Smooth, normalize) │  │ Service           │  │ (Angle deviations)   │  │  │
│  │  └─────────────────────┘  └───────────────────┘  └──────────────────────┘  │  │
│  │                                                                             │  │
│  │  ┌─────────────────────┐                                                   │  │
│  │  │ SetupValidation     │                                                   │  │
│  │  │ Service             │                                                   │  │
│  │  └─────────────────────┘                                                   │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
│                          │                                                        │
│                          ▼                                                        │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                           DATA LAYER                                        │  │
│  │                                                                             │  │
│  │  ┌─────────────────────┐  ┌───────────────────┐  ┌──────────────────────┐  │  │
│  │  │ PoseRepository      │  │ Drift Tables       │  │ Freezed Models       │  │  │
│  │  │ (API + local cache) │  │ (Offline storage)  │  │ (Data structures)    │  │  │
│  │  └─────────────────────┘  └───────────────────┘  └──────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────────┘
                          │
                          ▼
               ┌─────────────────────┐
               │   GET GAINS SERVER  │
               │   /api/pose/*       │
               └─────────────────────┘
```

---

## Data Flow

### Complete Pipeline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: SETUP GUIDANCE (Pre-recording — lightweight camera preview)       │
│                                                                              │
│  Camera Preview → Periodic MLKit check (every 10th frame) →                 │
│  Validate: Lighting ✓ | Full Body Visible ✓ | Distance ✓ | Angle ✓        │
│                                                                              │
│  Show checklist UI:                                                          │
│  ☑ Good lighting    ☑ Full body in frame                                    │
│  ☑ Correct distance ☑ Correct camera angle                                  │
│  → All checks pass → Enable "Start Recording" button                        │
└──────────────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: RECORDING (Minimal processing — just capture video)               │
│                                                                              │
│  Start video recording → Save MP4 to temp storage                           │
│  Optional: Sparse MLKit check (every 10th frame) for "body still in frame" │
│  warning overlay                                                             │
│  User presses Stop → Video file saved                                       │
└──────────────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: PROCESSING (Post-recording — no time pressure, full accuracy)     │
│                                                                              │
│  Progress: "Analyzing your form..." with percentage                         │
│                                                                              │
│  Step 1: Extract frames from video (target 15 FPS)         [0% - 15%]      │
│  Step 2: Run MLKit on ALL frames (with retry on failures)  [15% - 55%]     │
│  Step 3: Preprocess (filter invalid, smooth, normalize)    [55% - 65%]     │
│  Step 4: Apply limb isolation (filter to active segments)  [65% - 70%]     │
│  Step 5: Extract features (angles, distances)              [70% - 80%]     │
│  Step 6: DTW comparison with coach reference               [80% - 90%]     │
│  Step 7: Generate corrections                              [90% - 100%]    │
└──────────────────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: RESULTS (Display to user + upload to server)                      │
│                                                                              │
│  • Overall similarity score (0-100%)                                        │
│  • Per-segment scores (e.g., Torso: 85%, Left Leg: 72%)                    │
│  • Angle correction cards with specific feedback                            │
│  • Upload result to server (background)                                     │
│  • Delete temp video file                                                   │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
lib/features/pose_detection/
├── pose_detection.dart                    # Feature barrel export
├── data/
│   ├── pose_repository.dart               # API calls + local cache coordination
│   └── models/
│       ├── landmark_model.dart            # Single landmark point (x, y, z, confidence)
│       ├── landmark_frame_model.dart      # One frame of landmarks + timestamp
│       ├── feature_frame_model.dart       # Extracted angles/distances for one frame
│       ├── exercise_form_model.dart       # Coach reference form data
│       ├── pose_config_model.dart         # Limb isolation + tracked angles config
│       ├── tracked_angle_model.dart       # Single tracked angle definition
│       ├── comparison_result_model.dart   # Full comparison result
│       ├── segment_score_model.dart       # Per-segment score
│       └── correction_model.dart          # Single angle correction
├── services/
│   ├── pose_detection_service.dart        # MLKit wrapper for landmark extraction
│   ├── landmark_preprocessor.dart         # Smoothing, filtering, normalization
│   ├── limb_isolation_service.dart        # Filter landmarks to active segments
│   ├── feature_extractor.dart             # Calculate joint angles and distances
│   ├── dtw_comparison_service.dart        # Dynamic Time Warping comparison
│   ├── correction_generator.dart          # Generate feedback from deviations
│   ├── setup_validation_service.dart      # Pre-recording environment checks
│   └── video_frame_extractor.dart         # Extract frames from MP4 at target FPS
└── presentation/
    ├── providers/
    │   ├── pose_recording_provider.dart   # Camera + recording state
    │   ├── pose_processing_provider.dart  # Processing pipeline state
    │   ├── pose_result_provider.dart      # Result display + upload state
    │   ├── form_download_provider.dart    # Offline form sync state
    │   └── pose_config_provider.dart      # Exercise pose config state
    ├── screens/
    │   ├── setup_guidance_screen.dart     # Pre-recording camera setup
    │   ├── recording_screen.dart          # Video capture
    │   ├── processing_screen.dart         # Analysis progress
    │   ├── result_screen.dart             # Score + corrections display
    │   └── form_history_screen.dart       # Past results list
    └── widgets/
        ├── setup_checklist.dart           # Lighting, distance, angle checks
        ├── recording_overlay.dart         # Timer, rep counter, body-in-frame
        ├── processing_progress.dart       # Animated progress indicator
        ├── score_gauge.dart               # Circular/radial score display
        ├── segment_score_card.dart        # Per-limb score breakdown
        ├── correction_card.dart           # Individual correction feedback
        ├── angle_indicator.dart           # Visual angle deviation display
        └── limb_selector.dart             # Toggle segments on/off
```

---

## Data Models (Freezed)

### Core Landmark Models

```dart
// landmark_model.dart
@freezed
abstract class LandmarkPoint with _$LandmarkPoint {
  const factory LandmarkPoint({
    required double x,          // Normalized by image width  — usually 0.0-1.0 but can exceed for out-of-frame landmarks
    required double y,          // Normalized by image height — usually 0.0-1.0 but can exceed for out-of-frame landmarks
    required double z,          // Depth estimate
    required double confidence, // 0.0-1.0
  }) = _LandmarkPoint;

  factory LandmarkPoint.fromJson(Map<String, dynamic> json) =>
      _$LandmarkPointFromJson(json);
}
// NOTE: On Android, the camera sensor is landscape (e.g. 1920×1080) while
// the phone is held portrait.  MLKit returns coordinates in the *rotated*
// (upright) space.  PoseDetectionService._poseToLandmarkFrame() swaps
// imageWidth/imageHeight for 90°/270° rotations so that normalization
// produces correct 0–1 values.  The server schema allows [-1.0, 3.0] as a
// safety net for edge cases.

// landmark_frame_model.dart
@freezed
abstract class LandmarkFrame with _$LandmarkFrame {
  const factory LandmarkFrame({
    required int timestampMs,
    required Map<String, LandmarkPoint> landmarks,
    // Key = MLKit landmark name: "LEFT_SHOULDER", "LEFT_KNEE", etc.
  }) = _LandmarkFrame;

  factory LandmarkFrame.fromJson(Map<String, dynamic> json) =>
      _$LandmarkFrameFromJson(json);
}
```

### Feature Models

```dart
// feature_frame_model.dart
@freezed
abstract class FeatureFrame with _$FeatureFrame {
  const factory FeatureFrame({
    required int timestampMs,
    required Map<String, double> angles,    // "kneeFlexion": 92.5
    @Default({}) Map<String, double> distances, // Optional distance metrics
  }) = _FeatureFrame;

  factory FeatureFrame.fromJson(Map<String, dynamic> json) =>
      _$FeatureFrameFromJson(json);
}
```

### Config Models

```dart
// pose_config_model.dart
@freezed
abstract class PoseConfig with _$PoseConfig {
  const factory PoseConfig({
    required String exerciseId,
    required List<String> activeSegments,      // ["TORSO", "LEFT_LEG", "RIGHT_LEG"]
    required List<String> recommendedAngles,   // ["SIDE_LEFT"]
    required List<TrackedAngle> trackedAngles,
    @Default(0.5) double minLandmarkConfidence,
    String? setupInstructions,
  }) = _PoseConfig;

  factory PoseConfig.fromJson(Map<String, dynamic> json) =>
      _$PoseConfigFromJson(json);
}

// tracked_angle_model.dart
@freezed
abstract class TrackedAngle with _$TrackedAngle {
  const factory TrackedAngle({
    required String name,          // "kneeFlexion"
    required List<String> landmarks, // ["LEFT_HIP", "LEFT_KNEE", "LEFT_ANKLE"]
    required double idealMin,      // 80.0
    required double idealMax,      // 100.0
  }) = _TrackedAngle;

  factory TrackedAngle.fromJson(Map<String, dynamic> json) =>
      _$TrackedAngleFromJson(json);
}
```

### Exercise Form Model (Coach Reference)

```dart
// exercise_form_model.dart
@freezed
abstract class ExerciseFormModel with _$ExerciseFormModel {
  const factory ExerciseFormModel({
    required String id,
    required String exerciseId,
    required String coachId,
    required String cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    required List<LandmarkFrame> landmarkFrames,
    required List<FeatureFrame> featureFrames,
    List<LandmarkFrame>? normalizedFrames,
    required int version,
    required bool isActive,
    double? avgLandmarkConfidence,
    String? recordingQuality,
    String? coachName,
    DateTime? createdAt,
  }) = _ExerciseFormModel;

  factory ExerciseFormModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFormModelFromJson(json);
}
```

### Comparison Result Models

```dart
// comparison_result_model.dart
@freezed
abstract class ComparisonResult with _$ComparisonResult {
  const factory ComparisonResult({
    String? id,                               // null if not yet saved to server
    required String exerciseFormId,
    String? workoutSessionId,
    String? routineExerciseId,
    required double overallScore,             // 0.0 - 1.0
    required Map<String, double> segmentScores, // { "TORSO": 0.85, "LEFT_LEG": 0.72 }
    required List<Correction> corrections,
    required String cameraAngle,
    required int durationMs,
    required int frameRate,
    required int totalFrames,
    double? avgLandmarkConfidence,
    List<LandmarkFrame>? clientLandmarkFrames,
    List<FeatureFrame>? clientFeatureFrames,
    DateTime? createdAt,
  }) = _ComparisonResult;

  factory ComparisonResult.fromJson(Map<String, dynamic> json) =>
      _$ComparisonResultFromJson(json);
}

// correction_model.dart
@freezed
abstract class Correction with _$Correction {
  const factory Correction({
    required String angleName,     // "kneeFlexion"
    required String segment,       // "LEFT_LEG"
    required double avgDeviation,  // 12.5 degrees
    required double maxDeviation,  // 25.0 degrees
    required String direction,     // "too_shallow", "too_deep", "too_forward"
    required String message,       // Human-readable correction
  }) = _Correction;

  factory Correction.fromJson(Map<String, dynamic> json) =>
      _$CorrectionFromJson(json);
}
```

---

## Services — Detailed Design

### 1. `PoseDetectionService` — MLKit Wrapper

Wraps `google_mlkit_pose_detection` for **live** camera frame processing.

> **Implementation Status**: ✅ Implemented in `/lib/features/coach_pose/services/pose_detection_service.dart`

```dart
/// Responsibilities:
/// - Initialize MLKit PoseDetector (mode=single, model=base)
/// - Process live camera frames one at a time (skips if busy)
/// - Warm up the detector with a synthetic image on startup
/// - Convert MLKit Pose → LandmarkFrame with rotation-aware normalization
/// - Auto-recreate detector on timeout (handles GPU deadlocks)
/// - Resource cleanup
///
/// NOTE: Uses PoseDetectionMode.single intentionally. The `stream` mode
/// enables GPU acceleration (MediaPipe GPU delegate) which deadlocks with
/// CameraX on many Android devices (especially Mali GPUs). `single` mode
/// uses CPU-only TFLite inference — slower per frame (~50-100ms) but reliable.
/// Since we only process every 10th frame during setup and every 3rd during
/// recording, this is fast enough.
class PoseDetectionService {
  PoseDetectionService() { _initDetector(); }

  late PoseDetector _poseDetector;

  void _initDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.base,
      ),
    );
  }

  /// Warm up the detector by processing a tiny synthetic image.
  Future<void> warmUp();

  /// Process a single camera frame → LandmarkFrame?
  /// Returns null if busy or no pose detected.
  Future<LandmarkFrame?> processFrame(
    CameraImage image,
    InputImageRotation rotation,
    int timestampMs,
  );

  /// Convert MLKit Pose → LandmarkFrame with rotation-aware normalization.
  ///
  /// IMPORTANT: MLKit returns pixel coordinates in the *rotated* (upright)
  /// coordinate space.  On Android the camera sensor is typically landscape
  /// (e.g. 1920×1080) while the phone is held portrait (rotation 90°/270°).
  /// We swap imageWidth/imageHeight for these rotations so normalization
  /// divides by the correct dimension, keeping x/y values in the ~0–1 range.
  /// Without this swap, lower-body y-values exceed 1.5 (e.g. 1700/1080 ≈ 1.57)
  /// and fail server-side validation.
  LandmarkFrame _poseToLandmarkFrame(
    Pose pose, int timestampMs,
    double imageWidth, double imageHeight, {
    InputImageRotation rotation = InputImageRotation.rotation0deg,
  });

  Future<void> dispose() => _poseDetector.close();
}
```

### 2. `LandmarkPreprocessor` — Smoothing & Normalization

```dart
/// Responsibilities:
/// - Filter out frames with low overall confidence
/// - Apply moving average smoothing across frames (reduces jitter)
/// - Procrustes normalization (center at hip midpoint, scale, align)
/// - Interpolate missing frames (if a frame was skipped)
class LandmarkPreprocessor {
  /// Remove frames where fewer than 80% of required landmarks are above confidence threshold
  List<LandmarkFrame> filterLowConfidence(
    List<LandmarkFrame> frames, {
    required double minConfidence,
    required List<String> requiredLandmarks,
  });

  /// Moving average smoothing (window size = 5 by default)
  /// Smooths x, y, z independently per landmark
  List<LandmarkFrame> smooth(
    List<LandmarkFrame> frames, {
    int windowSize = 5,
  });

  /// Procrustes normalization:
  /// 1. Center: Translate so hip midpoint is at (0, 0)
  /// 2. Scale: Normalize by torso length (shoulder-to-hip distance)
  /// 3. Optional: Rotate to align torso with vertical axis
  List<LandmarkFrame> normalize(List<LandmarkFrame> frames);

  /// Full preprocessing pipeline
  List<LandmarkFrame> preprocess(
    List<LandmarkFrame> raw, {
    required double minConfidence,
    required List<String> requiredLandmarks,
  }) {
    final filtered = filterLowConfidence(raw,
      minConfidence: minConfidence,
      requiredLandmarks: requiredLandmarks,
    );
    final smoothed = smooth(filtered);
    return normalize(smoothed);
  }
}
```

### 3. `LimbIsolationService` — Body Segment Filtering

This is key for handling bad angles and focused analysis.

```dart
/// Maps BodySegment enums to specific MLKit landmark names.
/// Filters landmark frames to only include landmarks from active segments.
class LimbIsolationService {
  /// Mapping from body segment to MLKit landmark names
  static const Map<String, List<String>> segmentLandmarks = {
    'HEAD_NECK': [
      'NOSE', 'LEFT_EYE', 'RIGHT_EYE', 'LEFT_EAR', 'RIGHT_EAR',
    ],
    'LEFT_ARM': [
      'LEFT_SHOULDER', 'LEFT_ELBOW', 'LEFT_WRIST',
      'LEFT_PINKY', 'LEFT_INDEX', 'LEFT_THUMB',
    ],
    'RIGHT_ARM': [
      'RIGHT_SHOULDER', 'RIGHT_ELBOW', 'RIGHT_WRIST',
      'RIGHT_PINKY', 'RIGHT_INDEX', 'RIGHT_THUMB',
    ],
    'TORSO': [
      'LEFT_SHOULDER', 'RIGHT_SHOULDER',
      'LEFT_HIP', 'RIGHT_HIP',
    ],
    'LEFT_LEG': [
      'LEFT_HIP', 'LEFT_KNEE', 'LEFT_ANKLE',
      'LEFT_HEEL', 'LEFT_FOOT_INDEX',
    ],
    'RIGHT_LEG': [
      'RIGHT_HIP', 'RIGHT_KNEE', 'RIGHT_ANKLE',
      'RIGHT_HEEL', 'RIGHT_FOOT_INDEX',
    ],
    'FULL_BODY': [], // Special: means ALL landmarks, no filtering
  };

  /// Get the union of all landmark names for the given active segments
  Set<String> getActiveLandmarks(List<String> activeSegments) {
    if (activeSegments.contains('FULL_BODY')) {
      return {}; // Empty = no filtering, use all
    }
    final landmarks = <String>{};
    for (final segment in activeSegments) {
      landmarks.addAll(segmentLandmarks[segment] ?? []);
    }
    return landmarks;
  }

  /// Filter a LandmarkFrame to only include landmarks from active segments
  LandmarkFrame filterFrame(LandmarkFrame frame, Set<String> activeLandmarks) {
    if (activeLandmarks.isEmpty) return frame; // FULL_BODY: no filter
    final filtered = Map<String, LandmarkPoint>.fromEntries(
      frame.landmarks.entries.where((e) => activeLandmarks.contains(e.key)),
    );
    return frame.copyWith(landmarks: filtered);
  }

  /// Filter all frames
  List<LandmarkFrame> filterFrames(
    List<LandmarkFrame> frames,
    List<String> activeSegments,
  ) {
    final active = getActiveLandmarks(activeSegments);
    return frames.map((f) => filterFrame(f, active)).toList();
  }
}
```

### 4. `FeatureExtractor` — Joint Angles & Distances

```dart
/// Responsibilities:
/// - Calculate joint angles from 3-point landmark chains
/// - Calculate distance ratios between landmark pairs
/// - Process each frame into a FeatureFrame
/// - Only compute features for tracked angles defined in PoseConfig
class FeatureExtractor {
  /// Calculate the angle at point B formed by vectors BA and BC
  /// Returns angle in degrees (0-180)
  double calculateAngle(LandmarkPoint a, LandmarkPoint b, LandmarkPoint c) {
    final ba = (a.x - b.x, a.y - b.y);
    final bc = (c.x - b.x, c.y - b.y);
    final dot = ba.$1 * bc.$1 + ba.$2 * bc.$2;
    final magBA = sqrt(ba.$1 * ba.$1 + ba.$2 * ba.$2);
    final magBC = sqrt(bc.$1 * bc.$1 + bc.$2 * bc.$2);
    if (magBA == 0 || magBC == 0) return 0;
    final cosAngle = (dot / (magBA * magBC)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  /// Extract features for a single frame based on tracked angles
  FeatureFrame extractFrame(LandmarkFrame frame, List<TrackedAngle> trackedAngles) {
    final angles = <String, double>{};
    for (final tracked in trackedAngles) {
      final [name1, name2, name3] = tracked.landmarks;
      final p1 = frame.landmarks[name1];
      final p2 = frame.landmarks[name2];
      final p3 = frame.landmarks[name3];
      if (p1 != null && p2 != null && p3 != null) {
        angles[tracked.name] = calculateAngle(p1, p2, p3);
      }
    }
    return FeatureFrame(timestampMs: frame.timestampMs, angles: angles);
  }

  /// Extract features for all frames
  List<FeatureFrame> extractAll(
    List<LandmarkFrame> frames,
    List<TrackedAngle> trackedAngles,
  ) => frames.map((f) => extractFrame(f, trackedAngles)).toList();
}
```

### 5. `DTWComparisonService` — Dynamic Time Warping

```dart
/// Responsibilities:
/// - Compute DTW distance between coach and client feature sequences
/// - Support per-segment DTW (compare only angles belonging to a segment)
/// - Compute overall score from DTW distance
/// - Compute per-segment scores
class DTWComparisonService {
  /// Core DTW algorithm
  /// Compares two sequences of feature frames on specified angle names
  /// Returns normalized DTW distance (lower = more similar)
  double computeDTW(
    List<FeatureFrame> reference,
    List<FeatureFrame> client, {
    required List<String> angleNames,
  }) {
    final n = reference.length;
    final m = client.length;
    // Allocate cost matrix
    final cost = List.generate(n + 1, (_) => List.filled(m + 1, double.infinity));
    cost[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final dist = _frameDistance(reference[i - 1], client[j - 1], angleNames);
        cost[i][j] = dist + min(cost[i - 1][j], min(cost[i][j - 1], cost[i - 1][j - 1]));
      }
    }

    // Normalize by path length
    return cost[n][m] / (n + m);
  }

  /// Euclidean distance between two feature frames for specified angles
  double _frameDistance(FeatureFrame a, FeatureFrame b, List<String> angleNames) {
    double sumSq = 0;
    int count = 0;
    for (final name in angleNames) {
      final va = a.angles[name];
      final vb = b.angles[name];
      if (va != null && vb != null) {
        sumSq += pow(va - vb, 2);
        count++;
      }
    }
    return count > 0 ? sqrt(sumSq / count) : double.infinity;
  }

  /// Convert DTW distance to similarity score (0.0 - 1.0)
  /// Uses a sigmoid-like mapping where 0 distance = 1.0 score
  double distanceToScore(double distance, {double sensitivity = 0.05}) {
    return exp(-sensitivity * distance);
  }

  /// Full comparison: overall + per-segment scores
  ComparisonScores compare({
    required List<FeatureFrame> reference,
    required List<FeatureFrame> client,
    required List<TrackedAngle> trackedAngles,
    required Map<String, List<String>> segmentToAngles,
  }) {
    // Overall DTW
    final allAngleNames = trackedAngles.map((t) => t.name).toList();
    final overallDist = computeDTW(reference, client, angleNames: allAngleNames);
    final overallScore = distanceToScore(overallDist);

    // Per-segment DTW
    final segmentScores = <String, double>{};
    for (final entry in segmentToAngles.entries) {
      if (entry.value.isNotEmpty) {
        final dist = computeDTW(reference, client, angleNames: entry.value);
        segmentScores[entry.key] = distanceToScore(dist);
      }
    }

    return ComparisonScores(
      overallScore: overallScore,
      segmentScores: segmentScores,
    );
  }
}
```

### 6. `CorrectionGenerator` — Actionable Feedback

```dart
/// Responsibilities:
/// - Compare angle values between reference and client at DTW-aligned frames
/// - Identify which tracked angles deviated significantly
/// - Determine direction of deviation (too much / too little)
/// - Generate human-readable correction messages
class CorrectionGenerator {
  /// Generate corrections based on angle deviations
  List<Correction> generate({
    required List<FeatureFrame> reference,
    required List<FeatureFrame> client,
    required List<TrackedAngle> trackedAngles,
    required PoseConfig config,
    double deviationThreshold = 10.0, // Degrees — angles under this are "good"
  }) {
    final corrections = <Correction>[];

    for (final tracked in trackedAngles) {
      // Collect deviations across all frames for this angle
      final deviations = <double>[];
      final minFrames = min(reference.length, client.length);

      for (int i = 0; i < minFrames; i++) {
        final refAngle = reference[i].angles[tracked.name];
        final clientAngle = client[i].angles[tracked.name];
        if (refAngle != null && clientAngle != null) {
          deviations.add(clientAngle - refAngle);
        }
      }

      if (deviations.isEmpty) continue;

      final avgDev = deviations.reduce((a, b) => a + b) / deviations.length;
      final maxDev = deviations.map((d) => d.abs()).reduce(max);

      // Only report if deviation exceeds threshold
      if (avgDev.abs() < deviationThreshold) continue;

      // Determine which segment this angle belongs to
      final segment = _inferSegment(tracked, config.activeSegments);

      // Determine direction
      final direction = _inferDirection(tracked.name, avgDev);

      // Generate message
      final message = _generateMessage(tracked.name, avgDev, maxDev, direction);

      corrections.add(Correction(
        angleName: tracked.name,
        segment: segment,
        avgDeviation: avgDev.abs(),
        maxDeviation: maxDev,
        direction: direction,
        message: message,
      ));
    }

    // Sort by severity (largest average deviation first)
    corrections.sort((a, b) => b.avgDeviation.compareTo(a.avgDeviation));
    return corrections;
  }

  String _inferDirection(String angleName, double avgDev) {
    // Angle-specific direction names
    final directionMap = {
      'kneeFlexion': avgDev > 0 ? 'too_deep' : 'too_shallow',
      'hipHinge': avgDev > 0 ? 'too_deep' : 'too_shallow',
      'torsoLean': avgDev > 0 ? 'too_forward' : 'too_upright',
      'elbowFlexion': avgDev > 0 ? 'too_bent' : 'too_straight',
      'shoulderAbduction': avgDev > 0 ? 'too_wide' : 'too_narrow',
    };
    return directionMap[angleName] ?? (avgDev > 0 ? 'too_much' : 'too_little');
  }

  String _generateMessage(String angleName, double avgDev, double maxDev, String direction) {
    final readableName = _humanReadableName(angleName);
    final directionText = direction.replaceAll('_', ' ');
    return 'Your $readableName was $directionText — '
           'average ${avgDev.abs().toStringAsFixed(1)}° off, '
           'max ${maxDev.toStringAsFixed(1)}° off ideal range.';
  }

  String _humanReadableName(String angleName) {
    final names = {
      'kneeFlexion': 'knee bend',
      'hipHinge': 'hip hinge angle',
      'torsoLean': 'torso lean',
      'elbowFlexion': 'elbow bend',
      'shoulderAbduction': 'shoulder angle',
      'ankleFlexion': 'ankle flexion',
      'spineAngle': 'spine angle',
    };
    return names[angleName] ?? angleName;
  }
}
```

### 7. `SetupValidationService` — Pre-Recording Checks

```dart
/// Responsibilities:
/// - Check ambient lighting from camera exposure data
/// - Check if the required body landmarks are visible (using sparse MLKit)
/// - Validate camera angle matches the recommended angle
/// - Check if the user is at the correct distance from camera
class SetupValidationService {
  /// Run all setup checks on a single camera frame
  Future<SetupValidationResult> validate(
    InputImage image,
    PoseConfig config,
  ) async {
    final pose = await _poseDetector.processImage(image);
    return SetupValidationResult(
      hasGoodLighting: _checkLighting(image),
      isFullBodyVisible: _checkBodyVisibility(pose, config),
      isCorrectDistance: _checkDistance(pose),
      isCorrectAngle: _checkAngle(pose, config),
    );
  }

  bool _checkLighting(InputImage image) {
    // Analyze average brightness from image metadata
    // Returns true if within acceptable range
  }

  bool _checkBodyVisibility(List<Pose> poses, PoseConfig config) {
    if (poses.isEmpty) return false;
    final pose = poses.first;
    final activeLandmarks = LimbIsolationService()
        .getActiveLandmarks(config.activeSegments);
    // Check that 80%+ of active landmarks have confidence > minConfidence
    int visible = 0;
    int total = 0;
    for (final landmark in pose.landmarks.values) {
      final name = _mlkitLandmarkName(landmark.type);
      if (activeLandmarks.isEmpty || activeLandmarks.contains(name)) {
        total++;
        if (landmark.likelihood > config.minLandmarkConfidence) visible++;
      }
    }
    return total > 0 && (visible / total) >= 0.8;
  }

  bool _checkDistance(List<Pose> poses) {
    // Measure body bounding box as percentage of frame
    // Should fill 60-90% of frame height
  }

  bool _checkAngle(List<Pose> poses, PoseConfig config) {
    // For side-view exercises, check shoulder depth difference
    // For front-view exercises, check shoulder symmetry
  }
}
```

---

## Local Database (Drift) — Offline Cache

### New Drift Tables

Add these to `app_database.dart`:

```dart
/// Cached coach reference forms for offline comparison
class CachedExerciseForms extends Table {
  TextColumn get id => text()();               // Server ID
  TextColumn get exerciseId => text()();
  TextColumn get coachId => text()();
  TextColumn get cameraAngle => text()();
  IntColumn get durationMs => integer()();
  IntColumn get frameRate => integer()();
  IntColumn get totalFrames => integer()();
  TextColumn get landmarkFramesJson => text()();  // JSON string
  TextColumn get featureFramesJson => text()();   // JSON string
  TextColumn get normalizedFramesJson => text().nullable()();
  IntColumn get version => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  RealColumn get avgLandmarkConfidence => real().nullable()();
  TextColumn get recordingQuality => text().nullable()();
  TextColumn get coachName => text().nullable()();
  DateTimeColumn get serverCreatedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached pose configs for exercises
class CachedPoseConfigs extends Table {
  TextColumn get exerciseId => text()();
  TextColumn get activeSegmentsJson => text()();   // JSON array
  TextColumn get recommendedAnglesJson => text()(); // JSON array
  TextColumn get trackedAnglesJson => text()();     // JSON array of TrackedAngle
  RealColumn get minLandmarkConfidence => real().withDefault(const Constant(0.5))();
  TextColumn get setupInstructions => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

/// Locally stored comparison results (pending upload or already uploaded)
class LocalComparisonResults extends Table {
  TextColumn get localId => text()();           // Local UUID
  TextColumn get serverId => text().nullable()(); // Set after upload
  TextColumn get exerciseFormId => text()();
  TextColumn get workoutSessionId => text().nullable()();
  TextColumn get routineExerciseId => text().nullable()();
  RealColumn get overallScore => real()();
  TextColumn get segmentScoresJson => text()();
  TextColumn get correctionsJson => text()();
  TextColumn get cameraAngle => text()();
  IntColumn get durationMs => integer()();
  IntColumn get frameRate => integer()();
  IntColumn get totalFrames => integer()();
  RealColumn get avgLandmarkConfidence => real().nullable()();
  TextColumn get clientLandmarkFramesJson => text().nullable()();
  TextColumn get clientFeatureFramesJson => text().nullable()();
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {localId};
}
```

### Offline Strategy

```
1. PROGRAM DOWNLOAD:
   User opens program → formDownloadProvider calls GET /api/pose/download/program/:id
   → Response cached into CachedExerciseForms + CachedPoseConfigs tables
   → Subsequent opens read from Drift first

2. DELTA SYNC:
   On app open or pull-to-refresh → send "since" param with last cachedAt
   → Only get new/updated forms

3. RESULT UPLOAD:
   After comparison → save to LocalComparisonResults (isUploaded = false)
   → Background upload via POST /api/pose/results
   → On success → set isUploaded = true, store serverId
   → On failure → stays in queue, retried on next sync
```

---

## Riverpod Providers

### `pose_recording_provider.dart`

```dart
/// Manages camera + recording lifecycle
/// States: Initial → SetupChecking → Ready → Recording → Recorded → Processing
@riverpod
class PoseRecording extends _$PoseRecording {
  @override
  PoseRecordingState build() => const PoseRecordingState.initial();

  Future<void> initCamera();
  Future<void> startRecording();
  Future<void> stopRecording();
  void dispose();
}

// State definition (Freezed)
@freezed
abstract class PoseRecordingState with _$PoseRecordingState {
  const factory PoseRecordingState.initial() = _Initial;
  const factory PoseRecordingState.setupChecking({
    required SetupValidationResult checks,
  }) = _SetupChecking;
  const factory PoseRecordingState.ready() = _Ready;
  const factory PoseRecordingState.recording({
    required Duration elapsed,
  }) = _Recording;
  const factory PoseRecordingState.recorded({
    required String videoPath,
  }) = _Recorded;
  const factory PoseRecordingState.error({
    required String message,
  }) = _Error;
}
```

### `pose_processing_provider.dart`

```dart
/// Manages the post-recording processing pipeline
/// Runs all processing in an Isolate to avoid UI jank
@riverpod
class PoseProcessing extends _$PoseProcessing {
  @override
  PoseProcessingState build() => const PoseProcessingState.idle();

  /// Run the full processing pipeline
  Future<void> process({
    required String videoPath,
    required ExerciseFormModel referenceForm,
    required PoseConfig config,
    String? workoutSessionId,
    String? routineExerciseId,
  });
}

@freezed
abstract class PoseProcessingState with _$PoseProcessingState {
  const factory PoseProcessingState.idle() = _Idle;
  const factory PoseProcessingState.processing({
    required double progress,   // 0.0 - 1.0
    required String stage,      // "Detecting poses...", "Comparing...", etc.
  }) = _Processing;
  const factory PoseProcessingState.complete({
    required ComparisonResult result,
  }) = _Complete;
  const factory PoseProcessingState.error({
    required String message,
  }) = _Error;
}
```

### `form_download_provider.dart`

```dart
/// Manages offline form data sync
@riverpod
class FormDownload extends _$FormDownload {
  @override
  FormDownloadState build() => const FormDownloadState.idle();

  /// Download all forms for a program
  Future<void> downloadProgramForms(String programId);

  /// Get cached form for an exercise (offline-first)
  Future<ExerciseFormModel?> getCachedForm(String exerciseId, String cameraAngle);

  /// Get cached pose config for an exercise
  Future<PoseConfig?> getCachedConfig(String exerciseId);

  /// Check if forms are cached for a program
  Future<bool> hasCachedForms(String programId);
}
```

---

## Screen Flow & Navigation

### Routes

```dart
// Add to router_provider.dart
GoRoute(
  path: '/pose/setup/:exerciseId',
  builder: (context, state) => SetupGuidanceScreen(
    exerciseId: state.pathParameters['exerciseId']!,
    workoutSessionId: state.uri.queryParameters['sessionId'],
    routineExerciseId: state.uri.queryParameters['routineExerciseId'],
  ),
),
GoRoute(
  path: '/pose/record/:exerciseId',
  builder: (context, state) => RecordingScreen(
    exerciseId: state.pathParameters['exerciseId']!,
  ),
),
GoRoute(
  path: '/pose/processing',
  builder: (context, state) => const ProcessingScreen(),
),
GoRoute(
  path: '/pose/result',
  builder: (context, state) => const ResultScreen(),
),
GoRoute(
  path: '/pose/history/:exerciseId',
  builder: (context, state) => FormHistoryScreen(
    exerciseId: state.pathParameters['exerciseId']!,
  ),
),
```

### Screen Transitions

```
WorkoutSessionScreen (existing)
    → "Check Form" button on an exercise
    → SetupGuidanceScreen
        Shows camera preview + checklist
        All checks pass → "Start Recording"
    → RecordingScreen
        Video capture with timer
        "Stop" → video saved to temp
    → ProcessingScreen
        Animated progress (0-100%)
        "Analyzing your form..."
    → ResultScreen
        Score gauge + segment breakdown + corrections
        "Done" → back to WorkoutSessionScreen
        "View History" → FormHistoryScreen
```

---

## Processing Pipeline — Isolate Architecture

All heavy computation runs in a Dart Isolate to prevent UI jank:

```dart
/// The main processing function that runs inside an Isolate
/// Called by PoseProcessingProvider
Future<ComparisonResult> runProcessingPipeline({
  required String videoPath,
  required ExerciseFormModel referenceForm,
  required PoseConfig config,
  required Function(double progress, String stage) onProgress,
}) async {
  // Step 1: Extract frames from video (15 FPS target)
  onProgress(0.05, 'Extracting video frames...');
  final frames = await VideoFrameExtractor.extract(videoPath, targetFPS: 15);

  // Step 2: Run MLKit pose detection on all frames
  onProgress(0.15, 'Detecting poses...');
  final poseService = PoseDetectionService();
  final rawLandmarks = await poseService.detectPosesBatch(
    frames,
    onProgress: (p) => onProgress(0.15 + p * 0.40, 'Detecting poses...'),
  );
  poseService.dispose();

  // Step 3: Preprocess — filter, smooth, normalize
  onProgress(0.55, 'Preprocessing...');
  final preprocessor = LandmarkPreprocessor();
  final requiredLandmarks = LimbIsolationService()
      .getActiveLandmarks(config.activeSegments)
      .toList();
  final preprocessed = preprocessor.preprocess(
    rawLandmarks,
    minConfidence: config.minLandmarkConfidence,
    requiredLandmarks: requiredLandmarks.isEmpty
        ? _allLandmarkNames
        : requiredLandmarks,
  );

  // Step 4: Apply limb isolation
  onProgress(0.65, 'Isolating body segments...');
  final isolationService = LimbIsolationService();
  final isolated = isolationService.filterFrames(
    preprocessed,
    config.activeSegments,
  );

  // Step 5: Extract features (joint angles)
  onProgress(0.70, 'Extracting features...');
  final extractor = FeatureExtractor();
  final clientFeatures = extractor.extractAll(isolated, config.trackedAngles);

  // Step 6: DTW comparison
  onProgress(0.80, 'Comparing with reference...');
  final dtwService = DTWComparisonService();
  final segmentToAngles = _mapSegmentToAngles(config);
  final scores = dtwService.compare(
    reference: referenceForm.featureFrames,
    client: clientFeatures,
    trackedAngles: config.trackedAngles,
    segmentToAngles: segmentToAngles,
  );

  // Step 7: Generate corrections
  onProgress(0.90, 'Generating feedback...');
  final correctionGenerator = CorrectionGenerator();
  final corrections = correctionGenerator.generate(
    reference: referenceForm.featureFrames,
    client: clientFeatures,
    trackedAngles: config.trackedAngles,
    config: config,
  );

  onProgress(1.0, 'Complete!');

  return ComparisonResult(
    exerciseFormId: referenceForm.id,
    overallScore: scores.overallScore,
    segmentScores: scores.segmentScores,
    corrections: corrections,
    cameraAngle: referenceForm.cameraAngle,
    durationMs: (frames.length / 15 * 1000).round(),
    frameRate: 15,
    totalFrames: clientFeatures.length,
    avgLandmarkConfidence: _avgConfidence(rawLandmarks),
    clientFeatureFrames: clientFeatures,
  );
}
```

### Performance Estimates

| Recording Duration | Frames (15 FPS) | Step 2 (MLKit) | Total Processing |
|-------------------|------------------|-----------------|------------------|
| 5 seconds | 75 | ~5s | ~8-12s |
| 10 seconds | 150 | ~10-15s | ~15-23s |
| 30 seconds | 450 | ~30-45s | ~40-60s |

---

## Limb Isolation — Detailed Behavior

### How It Works End-to-End

1. **Coach creates exercise** → also sets `PoseConfig` with `activeSegments`
2. **Coach records form** → app filters landmarks to active segments before upload
3. **Client downloads form** → gets filtered landmarks + pose config
4. **Client records attempt** → app filters their landmarks to the same segments
5. **DTW only compares on active segment features** → angles outside active segments are ignored
6. **Corrections only generated for active segment angles**

### Example Configurations

| Exercise | Active Segments | Tracked Angles | Recommended Camera |
|----------|----------------|----------------|-------------------|
| Barbell Squat | `TORSO`, `LEFT_LEG`, `RIGHT_LEG` | kneeFlexion, hipHinge, torsoLean, ankleFlexion | `SIDE_LEFT` or `SIDE_RIGHT` |
| Bicep Curl | `LEFT_ARM`, `RIGHT_ARM`, `TORSO` | elbowFlexion, shoulderStability | `FRONT` or `ANGLE_45_LEFT` |
| Deadlift | `TORSO`, `LEFT_LEG`, `RIGHT_LEG`, `LEFT_ARM`, `RIGHT_ARM` | hipHinge, kneeFlexion, torsoLean, spineAngle | `SIDE_LEFT` or `SIDE_RIGHT` |
| Lateral Raise | `LEFT_ARM`, `RIGHT_ARM`, `TORSO` | shoulderAbduction, elbowAngle, torsoLean | `FRONT` |
| Plank | `TORSO`, `LEFT_ARM`, `RIGHT_ARM`, `LEFT_LEG`, `RIGHT_LEG` | spineAngle, hipAngle, shoulderAngle | `SIDE_LEFT` |

### Handling Bad Angles / Obstructed Views

```
IF a required landmark from an active segment has low confidence:
  → LandmarkPreprocessor filters out that frame entirely
  → If >50% of frames are filtered: show warning "Too many obstructed frames"

IF user records from wrong angle:
  → SetupValidationService warns during setup phase
  → But comparison still works (just less accurate)

IF user manually overrides limb isolation (UI toggle):
  → LimbSelector widget allows disabling segments
  → Disabled segments excluded from DTW + corrections
  → Use case: "My right side was blocked, only check my left side"
```

---

## Implementation Order

### Phase 1: Foundation (Week 1-2)

1. [ ] Create feature folder structure under `/lib/features/pose_detection/`
2. [ ] Create all Freezed data models (landmark, feature, config, result, correction)
3. [ ] Run `dart run build_runner build --delete-conflicting-outputs`
4. [ ] Create `PoseRepository` with API methods (matching server endpoints)
5. [ ] Add Drift tables (`CachedExerciseForms`, `CachedPoseConfigs`, `LocalComparisonResults`)
6. [ ] Run build_runner again for Drift generation
7. [ ] Create barrel export `pose_detection.dart`

### Phase 2: Core Services (Week 2-3)

8. [ ] Implement `LimbIsolationService` (segment-to-landmark mapping + filtering)
9. [ ] Implement `FeatureExtractor` (angle calculation from 3-point chains)
10. [ ] Implement `LandmarkPreprocessor` (smoothing, filtering, Procrustes normalization)
11. [ ] Implement `PoseDetectionService` (MLKit wrapper with batch processing)
12. [ ] Implement `DTWComparisonService` (DTW algorithm + score calculation)
13. [ ] Implement `CorrectionGenerator` (deviation analysis + message generation)
14. [ ] Implement `VideoFrameExtractor` (extract frames from MP4)
15. [ ] Implement `SetupValidationService` (lighting, distance, angle, visibility checks)

### Phase 3: Offline Caching (Week 3)

16. [ ] Implement form download + cache in `PoseRepository`
17. [ ] Implement `formDownloadProvider` (download + cache + delta sync)
18. [ ] Implement result upload queue (save locally → upload in background)

### Phase 4: Providers (Week 3-4)

19. [ ] Implement `poseRecordingProvider` (camera + recording state machine)
20. [ ] Implement `poseProcessingProvider` (Isolate pipeline orchestration)
21. [ ] Implement `poseResultProvider` (result display + upload)
22. [ ] Implement `poseConfigProvider` (read from cache/API)

### Phase 5: Screens & Widgets (Week 4-5)

23. [ ] Create `SetupGuidanceScreen` + `SetupChecklist` widget
24. [ ] Create `RecordingScreen` + `RecordingOverlay` widget
25. [ ] Create `ProcessingScreen` + `ProcessingProgress` widget
26. [ ] Create `ResultScreen` + `ScoreGauge`, `SegmentScoreCard`, `CorrectionCard` widgets
27. [ ] Create `FormHistoryScreen`
28. [ ] Create `LimbSelector` widget (toggle body segments on/off)
29. [ ] Add routes to `router_provider.dart`
30. [ ] Add "Check Form" entry point to `WorkoutSessionScreen`

### Phase 6: Coach Recording Flow (Week 5-6)

31. [ ] Add coach-specific recording screens (reuse client screens with mode flag)
32. [ ] Implement form upload flow in `PoseRepository`
33. [ ] Implement pose config management UI for coaches

### Phase 7: Integration Testing (Week 6)

34. [ ] Test full coach flow: record → process → upload
35. [ ] Test full client flow: download → record → compare → result → upload
36. [ ] Test offline flow: cached forms → record without network → queue upload
37. [ ] Performance test on lower-end devices
38. [ ] Verify limb isolation filtering at every stage

---

## Future Enhancements

- [ ] Unity 3D replay visualization (send landmark frames to Unity via FlutterUnityBridge)
- [ ] Rep detection and counting (segment recording into individual reps)
- [ ] Progress over time charts (plot scores per exercise over sessions)
- [ ] Side-by-side video replay (coach vs client skeleton overlay)
- [ ] Live preview mode with lightweight pose skeleton overlay during recording
- [ ] Voice feedback during recording ("Bend your knees deeper")
- [ ] Export comparison data as shareable report
- [ ] Coach notification when client completes a form check

---

*Last updated: February 6, 2026*
