# Coach Pose Recording Flow - Implementation Plan

> **Status**: 🚧 In Progress  
> **Branch**: `subtask/GG-41-coach-pose-recording-flow`  
> **Last Updated**: March 13, 2026  
> **Covers**: Coach exercise list, create exercise, record reference form, view exercise info  
> **Depends On**: [CONTEXT.md](../CONTEXT.md), [POSE_DETECTION.md](POSE_DETECTION.md), [Server POSE_DETECTION.md](../../get-gains-server/docs/features/POSE_DETECTION.md)

---

## Overview

### Purpose

This document covers the **Coach's Flow** for the Pose Detection feature — the first half of the full pose detection system. The Coach Flow allows coaches to:

1. **Browse exercises** — View the exercise library with search and filter
2. **Create exercises** — Add new exercises with target muscles and equipment
3. **Record reference forms** — Use the device camera + MLKit to capture pose landmarks for an exercise
4. **View exercise info** — See exercise details, active forms, and form history

The **Client Flow** (downloading forms, comparing, scoring) is deferred to a separate task.

### User Journey

```
Home Screen (Coach Badge visible)
    │
    ▼
┌─────────────────────────┐
│   Exercise List Screen  │ ← Browse/search/filter exercises
│   [+ Create Exercise]   │
└────────┬────────────────┘
         │
    ┌────┴──────────────────────┐
    │                           │
    ▼                           ▼
┌──────────────┐      ┌──────────────────────┐
│ Create       │      │ Exercise Detail      │
│ Exercise     │      │ Screen               │
│ Screen       │      │ - Info               │
│              │      │ - Active Form(s)     │
│              │      │ - [Record New Form]  │
└──────────────┘      └────────┬─────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Form Recording       │
                    │ Screen               │
                    │ - Camera preview     │
                    │ - Setup guidance     │
                    │ - Recording controls │
                    │ - MLKit processing   │
                    │ - Upload to server   │
                    └──────────────────────┘
```

### Scope (Coach Flow Only)

| In Scope | Out of Scope (Client Flow) |
|----------|---------------------------|
| Exercise CRUD | Form download/caching |
| Coach form recording | DTW comparison |
| MLKit landmark extraction | Score calculation |
| Feature extraction | Correction generation |
| Form upload to server | Client result display |
| Pose config management | Offline-first form sync |
| Exercise detail + form history | Workout session integration |

---

## Architecture

### New Files

```
lib/features/coach_pose/
├── coach_pose.dart                          # Feature barrel export
├── data/
│   ├── data.dart                            # Data barrel
│   ├── coach_pose_repository.dart           # API calls for exercises + forms
│   └── models/
│       ├── models.dart                      # Models barrel
│       ├── exercise_model.dart              # Exercise model (reuse/extend from workout)
│       ├── exercise_form_model.dart         # Coach reference form model
│       ├── pose_config_model.dart           # Per-exercise pose configuration
│       ├── landmark_models.dart             # LandmarkPoint, LandmarkFrame
│       └── feature_frame_model.dart         # Extracted feature angles per frame
├── services/
│   ├── services.dart                        # Services barrel
│   ├── pose_detection_service.dart          # MLKit wrapper
│   ├── landmark_preprocessor.dart           # Smoothing, normalization
│   ├── feature_extractor.dart               # Joint angle calculation
│   └── setup_validation_service.dart        # Pre-recording checks
└── presentation/
    ├── presentation.dart                    # Presentation barrel
    ├── providers/
    │   ├── providers.dart                   # Providers barrel
    │   ├── exercise_list_provider.dart      # Exercise list + search state
    │   ├── exercise_detail_provider.dart    # Single exercise + forms
    │   ├── create_exercise_provider.dart    # Create exercise form state
    │   └── form_recording_provider.dart     # Recording pipeline state
    ├── screens/
    │   ├── screens.dart                     # Screens barrel
    │   ├── exercise_list_screen.dart        # Browse exercises
    │   ├── create_exercise_screen.dart      # Create new exercise
    │   ├── exercise_detail_screen.dart      # View exercise + forms
    │   └── form_recording_screen.dart       # Record reference form
    └── widgets/
        ├── widgets.dart                     # Widgets barrel
        ├── exercise_card.dart               # Exercise list item
        ├── form_card.dart                   # Form history list item
        ├── muscle_group_selector.dart       # Multi-select muscle groups
        ├── camera_preview_overlay.dart      # Setup guidance overlay
        └── recording_controls.dart          # Start/stop/timer controls
```

### API Endpoints Used

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/api/workout/exercises` | GET | List exercises with search/filter | Auth |
| `/api/workout/exercises` | POST | Create new exercise | Coach |
| `/api/workout/exercises/:id` | GET | Get exercise details | Auth |
| `/api/pose/forms` | POST | Upload recorded form | Coach |
| `/api/pose/exercises/:exerciseId/forms` | GET | List forms for exercise | Coach |
| `/api/pose/forms/:formId` | GET | Get form details | Coach |
| `/api/pose/forms/:formId` | DELETE | Delete a form | Coach |
| `/api/pose/forms/:formId/activate` | PATCH | Activate a specific form | Coach |
| `/api/pose/exercises/:exerciseId/config` | GET | Get pose config | Coach |
| `/api/pose/exercises/:exerciseId/config` | PUT | Upsert pose config | Coach |

---

## Implementation Phases

### Phase 1: Data Layer — Models & Repository ✅ Target

**Models to create:**
- `ExerciseModel` — Reuses workout exercise model pattern
- `ExerciseFormModel` — Coach form metadata (without heavy JSON payloads for list views)
- `ExerciseFormDetailModel` — Full form with landmark/feature data
- `PoseConfigModel` — Active segments, tracked angles
- `LandmarkPoint`, `LandmarkFrame` — Core pose data structures
- `FeatureFrame` — Extracted joint angles per frame

**Repository methods:**
```dart
class CoachPoseRepository {
  // Exercises
  Future<Result<List<ExerciseModel>, AppError>> getExercises({String? search, String? muscleGroup});
  Future<Result<ExerciseModel, AppError>> getExercise(String id);
  Future<Result<ExerciseModel, AppError>> createExercise(CreateExerciseRequest request);

  // Forms
  Future<Result<List<ExerciseFormModel>, AppError>> getExerciseForms(String exerciseId, {bool activeOnly});
  Future<Result<ExerciseFormDetailModel, AppError>> getFormById(String formId);
  Future<Result<ExerciseFormModel, AppError>> uploadForm(UploadFormRequest request);
  Future<Result<void, AppError>> deleteForm(String formId);
  Future<Result<ExerciseFormModel, AppError>> activateForm(String formId);

  // Pose Config
  Future<Result<PoseConfigModel, AppError>> getPoseConfig(String exerciseId);
  Future<Result<PoseConfigModel, AppError>> upsertPoseConfig(String exerciseId, UpsertPoseConfigRequest request);
}
```

### Phase 2: Service Layer — MLKit & Processing

**Services to implement:**
1. `PoseDetectionService` — MLKit wrapper for live camera frame processing
2. `LandmarkPreprocessor` — Filter low confidence, smooth, normalize (Procrustes)
3. `FeatureExtractor` — Calculate joint angles from landmark triplets
4. `SetupValidationService` — Validate lighting, distance, body visibility

### Phase 3: Presentation Layer — Screens & Providers

**Screens:**
1. `ExerciseListScreen` — List with search bar, muscle group chips, FAB to create
2. `CreateExerciseScreen` — Form with name, description, target muscles, equipment
3. `ExerciseDetailScreen` — Tabbed view (Info, Forms, Config)
4. `FormRecordingScreen` — Camera preview → setup guidance → recording → processing → upload

**Providers:**
1. `ExerciseListProvider` — Async list with search/filter
2. `ExerciseDetailProvider` — Single exercise with forms
3. `CreateExerciseProvider` — Form validation and submission
4. `FormRecordingProvider` — Full recording pipeline state machine

### Phase 4: Integration & Testing

- Wire up routes in `router_provider.dart`
- Add coach detection to home screen
- Add "Coach Tools" quick action card
- End-to-end test: Create exercise → Record form → View in detail

---

## Recording State Machine

```
┌─────────┐     ┌─────────┐     ┌───────────┐     ┌────────────┐     ┌──────────┐
│  IDLE   │────▶│ SETUP   │────▶│ RECORDING │────▶│ PROCESSING │────▶│ COMPLETE │
│         │     │ GUIDANCE │     │           │     │            │     │          │
└─────────┘     └────┬────┘     └─────┬─────┘     └──────┬─────┘     └──────────┘
                     │                │                   │
                     │ Cancel         │ Cancel            │ Error
                     ▼                ▼                   ▼
                ┌─────────┐     ┌─────────┐         ┌─────────┐
                │  IDLE   │     │  IDLE   │         │  ERROR  │
                └─────────┘     └─────────┘         └─────────┘
```

**States:**
- `idle` — Initial, no recording in progress
- `setupGuidance` — Camera preview active, validating environment
- `recording` — Actively recording (raw frame capture only; no MLKit during recording)
- `processing` — Post-recording: MLKit batch → preprocess → extract features; **full-screen overlay with progress percentage (0–100%) and step message** (e.g. "Detecting pose...", "Analyzing form...", "Extracting angles...")
- `uploading` — Sending processed data to server; overlay shows "Uploading form..." and percentage
- `complete` — Form uploaded successfully
- `error` — Something went wrong (with retry option)

**Post-processing loading:** `FormRecordingState` includes `processingProgress` (0.0–1.0) and `processingMessage` (e.g. "Detecting pose...", "Analyzing form...", "Uploading form..."). The form recording screen shows a full-screen dark overlay with a circular progress indicator, the current step message, and the percentage so the coach knows what is happening.

---

## Route Integration

New routes added to `AppRoutes`:

```dart
// Coach Pose routes
static const String coachExercises = '/coach/exercises';
static const String createExercise = '/coach/exercises/create';
static const String exerciseDetail = '/coach/exercises/:id';
static const String recordForm = '/coach/exercises/:id/record';
```

---

## Testing Script

A backend script `scripts/make-coach.ts` is provided to promote any user to coach status for testing:

```bash
npx tsx scripts/make-coach.ts <userId>
```

This creates a `Coach` record linked to the user, enabling access to coach-only routes.

---

## Checklist

- [x] Implementation plan created
- [ ] Backend make-coach script
- [ ] Data models (freezed)
- [ ] Repository
- [ ] Services (MLKit, preprocessor, feature extractor)
- [ ] Providers (exercise list, detail, create, recording)
- [ ] Screens (exercise list, create, detail, recording)
- [ ] Widgets (exercise card, form card, camera overlay, recording controls)
- [ ] Routes registered
- [ ] Home screen coach button
- [ ] Code generation (`build_runner`)
- [ ] End-to-end smoke test
