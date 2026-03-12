# Client Pose Feature Documentation

> **Created**: February 18, 2026
> **Updated**: March 12, 2026
> **Status**: Implemented

---

## Overview

The Client Pose feature lets authenticated users compare their exercise form against a coach's recorded reference form using on-device MLKit pose detection and DTW comparison. As of February 19, 2026 the comparison can be visualised via a **3D Unity avatar skeleton** (new) or the original **2D flat skeleton overlay** (legacy, still accessible).

The feature now integrates directly into the **workout session flow**: pressing "Start Workout" on a routine navigates to the recording screen for the first exercise, and after each set the user proceeds to the next exercise — all without returning to the rep/weight logger until the recording + comparison phase is complete.

**Pipeline:**

1. Fetch the coach's active reference form + pose config from the server
2. Show the reference form as an animated skeleton (3D Unity or 2D fallback)
3. Capture the user via device camera + MLKit pose detection
4. DTW-compare the client's normalised landmark sequence against the reference (client frames are trimmed to reference length before comparison)
5. Aggregate per-angle DTW scores into body-segment keys (`LEFT_LEG`, `TORSO`, `LEFT_ARM`, etc.) matching the server's `BodySegmentEnum`
6. Display **side-by-side skeleton comparison** (coach cyan vs user green), score + per-segment breakdown + correction messages
7. (Workout mode) Log reps + weight for the exercise set (shown above fold, before breakdown), then navigate to next exercise
8. Upload result to server with segment-keyed `segmentScores`

---

## Acceptance Criteria

| Criteria                                                     | Status |
| ------------------------------------------------------------ | ------ |
| View coach's reference form as animated skeleton             | ✅     |
| View coach's reference form in Unity 3D avatar               | ✅     |
| Record own form via device camera                            | ✅     |
| Live rep counter during recording                            | ✅     |
| On-device DTW comparison after recording                     | ✅     |
| Score circle + segment breakdown + corrections               | ✅     |
| **Side-by-side skeleton replay (coach vs user)**             | ✅     |
| **Workout mode: record → compare → log set → next exercise** | ✅     |
| Upload comparison result to server                           | ✅     |
| **Offline recording** — reference forms cached; results queued for sync | ✅ |
| **Offline history** — first-page history cached in Drift     | ✅     |
| Error shown (not infinite spinner) when server times out     | ✅     |
| Error shown when camera is unavailable                       | ✅     |

---

## Folder Structure

```
lib/features/client_pose/
├── client_pose.dart                          # Feature barrel export
├── data/
│   ├── client_pose_repository.dart           # API: download form, submit result
│   └── models/
│       ├── models.dart
│       ├── body_segment.dart                 # BodySegment enum (matches server BodySegmentEnum)
│       └── comparison_result_model.dart      # ComparisonResultModel, CorrectionModel
├── services/
│   ├── form_comparison_service.dart          # On-device DTW comparison
│   └── rep_counter.dart                      # Real-time rep detection
└── presentation/
    ├── providers/
    │   ├── client_recording_provider.dart    # Full recording + comparison state machine
    │   └── client_recording_provider.g.dart  # Riverpod generated
    ├── screens/
    │   ├── screens.dart                      # Barrel export
    │   ├── view_form_screen.dart             # Reference form viewer (2D skeleton)
    │   ├── client_recording_screen.dart      # Legacy 2D recording + compare
    │   └── client_unity_recording_screen.dart # 3D Unity recording + compare ← NEW
    └── widgets/
        ├── pose_skeleton_painter.dart        # 2D CustomPainter skeleton
        └── pose_playback_widget.dart         # Animated 2D skeleton with controls
```

---

## Screens

### `ViewFormScreen` (`/client/exercise/:id/view-form`)

Fetches and displays the coach's active reference form for an exercise.

- Calls `ClientPoseRepository.downloadExerciseForm(exerciseId)` directly via `FutureBuilder`
- Renders each form version as a `_FormPlaybackCard` with animated `PosePlaybackWidget`
- Shows metadata: coach name, duration, frame rate, total frames, camera angle
- "Compare My Form" navigates to `ClientUnityRecordingScreen` (`/client/exercise/:id/unity-record`)

---

### `ClientUnityRecordingScreen` (`/client/exercise/:id/unity-record`) ← PRIMARY

The main comparison screen that embeds Unity for 3D avatar visualisation. Supports two modes:

- **Standalone mode** — accessed from "Compare My Form" on the exercise detail; shows Try Again / Done buttons after comparison
- **Workout mode** — accessed from "Start Workout" on the routine detail; shows side-by-side skeleton replay, set logger (auto-detected reps + weight input), and navigates to the next exercise after logging

**Constructor params (workout mode extras via `go_router` `extra` map):**

| Param                  | Type                          | Description                                      |
| ---------------------- | ----------------------------- | ------------------------------------------------ |
| `exerciseId`           | `String`                      | Path param — the exercise whose form to compare  |
| `workoutSessionId`     | `String?`                     | Active workout session ID (enables workout mode) |
| `routineExerciseId`    | `String?`                     | Routine exercise ID for set logging              |
| `routineExercises`     | `List<RoutineExerciseModel>?` | All exercises in the routine (for navigation)    |
| `currentExerciseIndex` | `int`                         | Zero-based index of the current exercise         |

**Phases** (driven by `clientRecordingProvider` state):

| State                                                   | UI                                                                                                                                                                    |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ClientRecordingInitial` / `ClientRecordingLoadingForm` | Spinner                                                                                                                                                               |
| `ClientRecordingReady`                                  | Unity 3D (looping reference) + camera preview + Start button                                                                                                          |
| `ClientRecordingActive`                                 | Unity 3D (live client pose) + PiP camera + REC badge + rep counter                                                                                                    |
| `ClientRecordingProcessing`                             | Spinner + "Analyzing your form…"                                                                                                                                      |
| `ClientRecordingComplete`                               | **Side-by-side skeleton comparison** (coach cyan + user green) + Score circle + segment breakdown + corrections + set logger (workout) or Try Again/Done (standalone) |
| `ClientRecordingError`                                  | `AppEmptyState` with error message                                                                                                                                    |

**Workout mode results view:**

- Two `PosePlaybackWidget` instances in a `Row` — coach skeleton (cyan, left) and user skeleton (green, right)
- Overall similarity score circle
- **Set Logger card** (above fold): auto-filled reps from `RepCounter`, weight text field (numeric input), prescribed sets info, "Record Again" and "Log & Next Exercise" / "Log & Finish" buttons
- Rep count card
- Per-segment DTW breakdown
- Correction messages

**Results screen — data sources (all real, no placeholders):**

| UI element                         | Data source                                       | Where data comes from                                                                                                                      |
| ---------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Coach skeleton (cyan, left)        | `ClientRecordingComplete.referenceLandmarkFrames` | Coach's `LandmarkFrame` records downloaded from server (`GET /pose/download/exercise/:id`) — the coach's actual recorded MLKit coordinates |
| User skeleton (green, right)       | `ClientRecordingComplete.clientLandmarkFrames`    | User's own frames captured by device camera + MLKit during the recording session, normalised by `LandmarkPreprocessor`                     |
| Similarity score circle (e.g. 76%) | `ClientRecordingComplete.result.overallScore`     | DTW comparison of coach vs user `FeatureFrame` sequences via `FormComparisonService.compare()`                                             |
| Segment breakdown bars             | `ClientRecordingComplete.result.segmentScores`    | Per-angle DTW scores (torso lean, hip flexion, elbow flexion, etc.)                                                                        |
| Correction messages                | `ClientRecordingComplete.result.corrections`      | Generated by `FormComparisonService` from angles that scored below threshold                                                               |
| Reps completed                     | `ClientRecordingComplete.repCount`                | `RepCounter.countRep()` incremented on each detected rep cycle during recording                                                            |

**Navigation in workout mode:**

- `_logSetAndContinue()` → calls `workoutSessionProvider.logSet()` with `routineExerciseIdOverride` → `_navigateToNextExercise()`
- If more exercises remain → navigates to the next exercise's recording screen with updated `currentExerciseIndex`
- If last exercise → navigates to `WorkoutSessionScreen` for session completion

**Unity integration:**

- On `scene_loaded` event from Unity → sends reference frames via `LoadPoseFrames` JSON message → sets camera angle + cyan skeleton colour
- During recording → streams each detected `LandmarkFrame` to Unity in real time (green skeleton colour)
- Toggle button in AppBar switches between Unity 3D ↔ 2D skeleton (`PosePlaybackWidget`)

**Key methods:**

| Method                          | Description                                                             |
| ------------------------------- | ----------------------------------------------------------------------- |
| `_sendReferenceFramesToUnity()` | Encodes reference frames as JSON and sends `LoadPoseFrames` to Unity    |
| `_sendLiveFrameToUnity(frame)`  | Streams one live landmark frame to Unity per MLKit detection            |
| `_onStartRecording()`           | Starts provider recording + image stream + sets Unity skeleton to green |
| `_onStopRecording()`            | Stops image stream + triggers DTW comparison                            |
| `_onTryAgain()`                 | Resets provider + reloads reference skeleton in Unity                   |

**5-second Unity fallback:** if `scene_loaded` never fires (e.g. Unity build absent), `_isUnityLoaded` is set to `true` after 5 seconds so the UI doesn't stay blank.

---

### `ClientRecordingScreen` (`/client/exercise/:id/compare`) ← LEGACY

Original 2D recording screen (still registered, accessible via route). Same pipeline as `ClientUnityRecordingScreen` but without the Unity embed — uses a split-view `PosePlaybackWidget` (coach skeleton, top) + `CameraPreview` (client, bottom).

---

## Provider: `ClientRecording` (family)

`@riverpod class ClientRecording extends _$ClientRecording` — family key: `exerciseId: String`.

### State Machine

```
ClientRecordingInitial
  ↓ loadReferenceForm()
ClientRecordingLoadingForm  ← 15s timeout → ClientRecordingError
  ↓ success
ClientRecordingReady
  ↓ startRecording()
ClientRecordingActive  ← processFrame() on each MLKit frame
  ↓ stopRecordingAndCompare()
ClientRecordingProcessing
  ↓ DTW compare + upload
ClientRecordingComplete
  ↓ resetForNewAttempt()
ClientRecordingReady
```

**`loadReferenceForm()` timeout:** a 15-second `Future.timeout` wraps the API call — if the server does not respond in time, the state transitions to `ClientRecordingError` with a user-readable message instead of hanging indefinitely.

### State Classes

| Class                        | Key Fields                                                                                                                       |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `ClientRecordingInitial`     | —                                                                                                                                |
| `ClientRecordingLoadingForm` | —                                                                                                                                |
| `ClientRecordingReady`       | `exerciseName`, `referenceFrames`, `referenceFeatureFrames`, `poseConfig`, `formId`, `cameraAngle`, `coachName?`                 |
| `ClientRecordingActive`      | All of Ready + `clientLandmarkFrames`, `clientFeatureFrames`, `repCount`, `recordingDurationMs`                                  |
| `ClientRecordingProcessing`  | —                                                                                                                                |
| `ClientRecordingComplete`    | `result: ComparisonResultModel`, `repCount`, `uploadSuccess`, `referenceLandmarkFrames`, `clientLandmarkFrames`, `exerciseName?` |
| `ClientRecordingError`       | `message: String`                                                                                                                |

---

## Offline-First Behaviour

### Reference Form Caching

Forms are cached in the `CachedExerciseForms` Drift table keyed by `exerciseId`. The cache is populated proactively:

1. **On workout start** (`_startWorkout()` in `RoutineDetailScreen`) — `preCacheExerciseForms()` is called for **all** exercises in the routine before navigation, while the device is still known-online.
2. **On recording screen init** — remaining exercises (not the current one) are pre-cached in the background.
3. **On each form download** (`downloadExerciseForm()`) — the server response is always written to cache on success.

If the device is offline when `loadReferenceForm()` runs, `downloadExerciseForm()` falls back to the `CachedExerciseForms` table automatically.

### Result Queuing

`submitResult()` queues to the local `SyncQueue` (`entityTable: 'pose_results'`) when `POST /pose/results` fails. `WorkoutSyncService._syncPendingPoseResults()` processes the queue when connectivity is restored.

### History Caching

`getHistory()` caches the first page (`offset == 0`) in `CachedApiResponses` under key `'pose_history'` (or `'pose_history_$exerciseId'` for filtered queries). On network failure the cached page is returned so history is still browsable offline.

---

## Repository: `ClientPoseRepository`

| Method | Endpoint | Offline-first? | Description |
| --- | --- | --- | --- |
| `downloadExerciseForm(exerciseId)` | `GET /pose/download/exercise/:id` | ✅ Cache | Returns exercise name, forms (landmark + feature frames), poseConfig |
| `preCacheExerciseForms(exerciseIds)` | *(calls downloadExerciseForm)* | ✅ Fire-forget | Pre-caches multiple forms; called on workout start and recording init |
| `submitResult(...)` | `POST /pose/results` | ✅ Queue | Uploads DTW result; queued to SyncQueue when offline |
| `getHistory({exerciseId, limit, offset})` | `GET /pose/results` | ✅ Cache | Fetches comparison history; first page cached in CachedApiResponses |
| `getPoseConfig(exerciseId)` | `GET /pose/exercises/:id/config` | ❌ | Fetches limb isolation config |

---

## Routes

| Route constant                | Path                                | Screen                                 |
| ----------------------------- | ----------------------------------- | -------------------------------------- |
| `AppRoutes.clientViewForm`    | `/client/exercise/:id/view-form`    | `ViewFormScreen`                       |
| `AppRoutes.clientUnityRecord` | `/client/exercise/:id/unity-record` | `ClientUnityRecordingScreen` ← primary |
| `AppRoutes.clientCompareForm` | `/client/exercise/:id/compare`      | `ClientRecordingScreen` (legacy 2D)    |

---

## Unity Message Contract (pose-related methods)

| Constant                 | Value                | Direction       | Description                              |
| ------------------------ | -------------------- | --------------- | ---------------------------------------- |
| `methodLoadPoseFrames`   | `'LoadPoseFrames'`   | Flutter → Unity | Send JSON with `frames[]`, `fps`, `loop` |
| `methodPlayPose`         | `'PlayPose'`         | Flutter → Unity | Resume playback                          |
| `methodPausePose`        | `'PausePose'`        | Flutter → Unity | Pause playback                           |
| `methodSetSkeletonColor` | `'SetSkeletonColor'` | Flutter → Unity | Hex colour string                        |
| `methodSetCameraAngle`   | `'SetCameraAngle'`   | Flutter → Unity | `FRONT`, `SIDE_LEFT`, etc.               |
| `unityEventSceneLoaded`  | `'scene_loaded'`     | Unity → Flutter | Scene ready — send reference frames      |
| `unityEventPoseReady`    | `'pose_ready'`       | Unity → Flutter | Frames loaded                            |

Reference form uses **cyan** (`#00FFFF`); live client pose uses **green** (`#00FF88`).

---

## Reference Form Source

The skeleton animation in `ViewFormScreen` and `ClientUnityRecordingScreen` is the **coach's recorded 2D MLKit landmark frames** stored on the server — it is **not** a video. The server returns an array of `LandmarkFrame` objects (one per captured frame ≈15 fps), each containing normalised `x/y/z` coordinates for up to 33 MediaPipe pose landmarks. The app renders these frame-by-frame as a stick-figure skeleton (`PosePlaybackWidget`) or streams them into Unity (`LoadPoseFrames`) for 3D avatar rendering.

---

## Known TODOs

| Location                            | TODO                                                                    |
| ----------------------------------- | ----------------------------------------------------------------------- |
| `ClientUnityRecordingScreen`        | Offline cache reference frames in Drift (see `POSE_DETECTION.md`)       |
| `ClientPoseRepository.submitResult` | Include `clientLandmarkFrames` in upload when server storage is ready   |
| `client_recording_provider.dart`    | Show upload failure as non-blocking toast instead of silently ignoring  |
| General                             | Limb isolation / poseConfig filtering not yet applied during comparison |

---

_Last updated: February 19, 2026_
