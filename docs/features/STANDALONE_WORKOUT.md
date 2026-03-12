# Standalone Workout Feature Documentation

> **Created**: March 1, 2026
> **Status**: Data layer complete — presentation layer pending

---

## Overview

The **Standalone Workout** feature allows users to build and manage their own training content independently of a coach. Unlike the coach-assigned workout flow, everything here is user-owned:

- **Exercises** — Create and manage a personal exercise library (alongside public/coach exercises)
- **Routines** — Build custom routines from any exercises
- **Programs** — Organise routines into a cycling program (day 1, day 2, … day N, repeat)
- **Self-assignment** — Activate a program to start the day-cycling loop
- **Today's routine** — Server resolves which routine to do today based on active program + start date
- **Sessions** — Start/complete workout sessions tied to a routine
- **Weekly stats** — Aggregated workout stats (same shape as coach-assigned flow)

---

## Architecture

### Offline-First Strategy

| Operation          | Strategy                                             |
| ------------------ | ---------------------------------------------------- |
| Exercise CRUD      | Save locally → sync to server → SyncQueue on failure |
| Routine CRUD       | Save locally → sync to server → SyncQueue on failure |
| Program CRUD       | Save locally → sync to server → SyncQueue on failure |
| Program activation | Server-only (requires day-cycling setup)             |
| Today's routine    | Server-only (day-cycling logic)                      |
| Sessions           | Server-only (create/complete)                        |
| Weekly stats       | Server-only (aggregation)                            |

---

## Folder Structure

```
lib/features/standalone_workout/
├── standalone_workout.dart               # Feature barrel export
└── data/
    ├── data.dart                         # Data layer barrel export
    ├── standalone_workout_repository.dart # Offline-first repository
    └── models/
        ├── models.dart                   # Models barrel export
        ├── standalone_exercise_model.dart # Exercise + list response
        ├── standalone_routine_model.dart  # Routine summary + list response
        ├── standalone_program_model.dart  # Program hierarchy models
        ├── standalone_today_model.dart    # Day-cycling today model
        ├── standalone_session_model.dart  # Session summary + re-exports
        └── standalone_request_models.dart # All CRUD request bodies
```

> **Presentation layer** (`presentation/providers/`, `presentation/screens/`) — **not yet implemented**.

---

## Data Models

### Exercise

```dart
@freezed
abstract class StandaloneExerciseModel with _$StandaloneExerciseModel {
  const factory StandaloneExerciseModel({
    required String id,
    required String name,
    required String description,
    required MuscleGroup primaryMuscleGroup,
    @Default([]) List<String> equipmentNeeded,
    String? userId,      // null for coach/public exercises
    String? coachId,
    @Default(false) bool isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StandaloneExerciseModel;
}

class StandaloneExerciseListResponse {
  final List<StandaloneExerciseModel> exercises;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;
}
```

### Routine

```dart
// List item — lightweight summary
@freezed
abstract class StandaloneRoutineSummaryModel with _$StandaloneRoutineSummaryModel {
  const factory StandaloneRoutineSummaryModel({
    required String id,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,
    @Default(0) int exerciseCount,
    String? userId,
  }) = _StandaloneRoutineSummaryModel;
}
// Full detail → reuses RoutineModel from workout feature
```

### Program Hierarchy

```dart
// List item
StandaloneProgramSummaryModel { id, name, description, userId, routineCount, createdAt, updatedAt }

// Full detail with routine tree
StandaloneProgramDetailModel {
  id, name, description, userId,
  List<StandaloneProgramRoutineSlotModel> routines,  // sorted by dayNumber
  createdAt, updatedAt,
}

// Day-slot inside a program
StandaloneProgramRoutineSlotModel {
  id, programId, routineId, dayNumber,
  RoutineModel routine,  // fully nested
}

// Raw junction record (returned from assign/update endpoints)
StandaloneProgramRoutineModel { id, programId, routineId, dayNumber, createdAt, updatedAt }

// User's self-assignment record
StandaloneAssignedProgramModel {
  id, userId, programId, startDate, endDate?, isActive,
  StandaloneAssignmentProgramInfo program,  // { id, name, description }
}
```

**Extension helpers on `StandaloneProgramDetailModel`:**

| Getter            | Returns                          |
| ----------------- | -------------------------------- |
| `cycleLengthDays` | Max `dayNumber` across all slots |

### Today's Workout

```dart
@freezed
abstract class StandaloneTodayModel with _$StandaloneTodayModel {
  const factory StandaloneTodayModel({
    @Default(false) bool isRestDay,
    StandaloneTodayDetails? today,
    String? message,
  }) = _StandaloneTodayModel;
}

@freezed
abstract class StandaloneTodayDetails with _$StandaloneTodayDetails {
  const factory StandaloneTodayDetails({
    required String programRoutineId,
    required int dayNumber,
    required String assignedProgramId,
    required String programName,
    required RoutineModel routine,
  }) = _StandaloneTodayDetails;
}
```

**Extension helpers on `StandaloneTodayModel`:**

| Getter             | Returns                                   |
| ------------------ | ----------------------------------------- |
| `hasRoutine`       | `true` when `today != null && !isRestDay` |
| `displayName`      | Routine name, "Rest Day", or message      |
| `exerciseCount`    | Count from `today.routine.exercises`      |
| `estimatedMinutes` | `today.routine.estimatedDurationMinutes`  |

### Sessions

```dart
// Summary for history lists
@freezed
abstract class StandaloneSessionSummary with _$StandaloneSessionSummary {
  const factory StandaloneSessionSummary({
    required String id,
    required String userId,
    String? assignedProgramId,
    String? routineId,
    required DateTime startedAt,
    DateTime? completedAt,
    @Default(0) int totalSets,
    String? routineName,
  }) = _StandaloneSessionSummary;
}

class StandaloneSessionListResponse {
  final List<StandaloneSessionSummary> sessions;
  final int total, limit, offset;
  final bool hasMore;
}
```

**`standalone_session_model.dart` also re-exports:**

- `WorkoutSessionModel` (full session with performed sets)
- `WeeklyStatsModel` (weekly aggregated stats)

---

## Request Models

| Class                                    | Endpoint                                         |
| ---------------------------------------- | ------------------------------------------------ |
| `CreateStandaloneExerciseRequest`        | `POST /standalone/exercises`                     |
| `UpdateStandaloneExerciseRequest`        | `PATCH /standalone/exercises/:id`                |
| `CreateStandaloneRoutineRequest`         | `POST /standalone/routines`                      |
| `UpdateStandaloneRoutineRequest`         | `PATCH /standalone/routines/:id`                 |
| `AddStandaloneRoutineExerciseRequest`    | `POST /standalone/routines/:id/exercises`        |
| `UpdateStandaloneRoutineExerciseRequest` | `PATCH /standalone/routines/:id/exercises/:reId` |
| `CreateStandaloneProgramRequest`         | `POST /standalone/programs`                      |
| `UpdateStandaloneProgramRequest`         | `PATCH /standalone/programs/:id`                 |
| `AssignStandaloneRoutineRequest`         | `POST /standalone/programs/:id/routines`         |
| `UpdateStandaloneProgramRoutineRequest`  | `PATCH /standalone/programs/:id/routines/:prId`  |
| `ActivateStandaloneProgramRequest`       | `POST /standalone/programs/:id/activate`         |
| `StartStandaloneSessionRequest`          | `POST /standalone/sessions`                      |

---

## Database Tables (Drift — Schema v2)

Three new tables added in migration `from < 2`:

| Table                        | Description                                                                                                    |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `StandalonePrograms`         | User-owned training programs (`remoteId`, `userId`, `name`, `description`, `isSynced`)                         |
| `StandaloneProgramRoutines`  | Day-slot junction linking a routine to a program on a specific `dayNumber`; cascades on program/routine delete |
| `StandaloneAssignedPrograms` | Tracks the user's self-assigned program with `isActive`, `startDate`, `endDate`                                |

**New CRUD methods on `AppDatabase`:**

| Method                                       | Description                                  |
| -------------------------------------------- | -------------------------------------------- |
| `getStandalonePrograms(userId)`              | All programs for a user, newest first        |
| `getStandaloneProgramById(id)`               | Single program by local ID                   |
| `getStandaloneProgramByRemoteId(remoteId)`   | Single program by server ID                  |
| `upsertStandaloneProgram(companion)`         | Insert or replace                            |
| `deleteStandaloneProgram(id)`                | Delete (cascades to program routines)        |
| `deleteAllStandalonePrograms(userId)`        | Bulk delete                                  |
| `getStandaloneProgramRoutines(programId)`    | Day-slots ordered by `dayNumber`             |
| `upsertStandaloneProgramRoutine(companion)`  | Insert or replace                            |
| `deleteStandaloneProgramRoutine(id)`         | Delete single slot                           |
| `getActiveStandaloneAssignment(userId)`      | Single active assignment (`isActive = true`) |
| `getStandaloneAssignments(userId)`           | All assignments, newest first                |
| `upsertStandaloneAssignment(companion)`      | Insert or replace                            |
| `deactivateAllStandaloneAssignments(userId)` | Sets `isActive = false` for all              |

---

## API Constants

Added to `lib/core/constants/api_constants.dart`:

```dart
static const String standaloneExercises    = '/standalone/exercises';
static const String standaloneRoutines     = '/standalone/routines';
static const String standalonePrograms     = '/standalone/programs';
static const String standaloneActiveProgram= '/standalone/programs/active';
static const String standaloneToday        = '/standalone/today';
static const String standaloneSessions     = '/standalone/sessions';
static const String standaloneActiveSession= '/standalone/sessions/active';
static const String standaloneWeeklyStats  = '/standalone/stats/weekly';
```

---

## Repository Reference

**Provider:** `standaloneWorkoutRepositoryProvider` (`@Riverpod(keepAlive: true)`)

### Exercise Operations

| Method                                                  | Description               | Strategy                         |
| ------------------------------------------------------- | ------------------------- | -------------------------------- |
| `getExercisesLocal()`                                   | Load from Drift           | Local-only                       |
| `syncExercises({muscleGroup?, search?, limit, offset})` | Fetch + cache from server | Server → cache                   |
| `createExercise(request)`                               | Create + sync             | Local first → server → SyncQueue |
| `updateExercise({exerciseId, request})`                 | Update on server          | Server-only                      |
| `deleteExercise(exerciseId)`                            | Delete on server          | Server-only                      |

### Routine Operations

| Method                                                           | Description                    | Strategy                         |
| ---------------------------------------------------------------- | ------------------------------ | -------------------------------- |
| `getRoutinesLocal()`                                             | Load from Drift with exercises | Local-only                       |
| `syncRoutines({limit, offset})`                                  | Fetch paginated list           | Server                           |
| `getRoutineDetail(routineId)`                                    | Fetch + cache full routine     | Server → cache                   |
| `createRoutine(request)`                                         | Create + sync                  | Local first → server → SyncQueue |
| `updateRoutine({routineId, request})`                            | Update on server               | Server-only                      |
| `deleteRoutine(routineId)`                                       | Delete on server               | Server-only                      |
| `addRoutineExercise({routineId, request})`                       | Add exercise to routine        | Server-only                      |
| `updateRoutineExercise({routineId, routineExerciseId, request})` | Update prescription            | Server-only                      |
| `removeRoutineExercise({routineId, routineExerciseId})`          | Remove from routine            | Server-only                      |

### Program Operations

| Method                                                         | Description                | Strategy                         |
| -------------------------------------------------------------- | -------------------------- | -------------------------------- |
| `getProgramsLocal(userId)`                                     | Load from Drift            | Local-only                       |
| `syncPrograms({limit, offset})`                                | Fetch + cache list         | Server → cache                   |
| `getProgramDetail(programId)`                                  | Fetch full tree            | Server-only                      |
| `createProgram(request, {userId})`                             | Create + sync              | Local first → server → SyncQueue |
| `updateProgram({programId, request})`                          | Update on server           | Server-only                      |
| `deleteProgram(programId)`                                     | Delete on server           | Server-only                      |
| `assignRoutine({programId, request})`                          | Add routine to program day | Server-only                      |
| `updateProgramRoutine({programId, programRoutineId, request})` | Change day number          | Server-only                      |
| `removeProgramRoutine({programId, programRoutineId})`          | Remove from program        | Server-only                      |

### Self-Assignment Operations

| Method                                   | Description                   | Notes                                           |
| ---------------------------------------- | ----------------------------- | ----------------------------------------------- |
| `activateProgram({programId, request?})` | Self-assign + start day cycle | Deactivates prior active assignment server-side |
| `deactivateProgram(programId)`           | Stop program                  | Sets `endDate` on server                        |
| `getActiveProgram()`                     | Get current active assignment | 404 → `Success(null)`                           |

### Today & Session Operations

| Method                                                     | Description                           | Strategy                                                           |
| ---------------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------------ |
| `getTodayRoutine({assignedProgramId?})`                    | Server day-cycling resolution         | Server-only; 404 → `Success(StandaloneTodayModel(message: '...'))` |
| `startSession({assignedProgramId?})`                       | Start session; 409 if one in progress | Server-only                                                        |
| `getActiveSession()`                                       | Get in-progress session               | Server-only; 404 → `Success(null)`                                 |
| `getSessionDetail(sessionId)`                              | Full session with performed sets      | Server-only                                                        |
| `getSessionHistory({limit, offset, startDate?, endDate?})` | Paginated past sessions               | Server-only                                                        |
| `completeSession({sessionId, notes?})`                     | Finish the session                    | Server-only                                                        |
| `getWeeklyStats({weekOf?})`                                | Aggregated weekly stats               | Server-only                                                        |

---

## Server API Reference

All routes are under `/api/standalone/` and require authentication.

### Exercises

| Method   | Endpoint                 | Description                                                                   |
| -------- | ------------------------ | ----------------------------------------------------------------------------- |
| `GET`    | `/exercises`             | List user's + public exercises (`muscleGroup?`, `search?`, `limit`, `offset`) |
| `POST`   | `/exercises`             | Create personal exercise                                                      |
| `PATCH`  | `/exercises/:exerciseId` | Update personal exercise                                                      |
| `DELETE` | `/exercises/:exerciseId` | Delete personal exercise                                                      |

### Routines

| Method   | Endpoint                               | Description                  |
| -------- | -------------------------------------- | ---------------------------- |
| `GET`    | `/routines`                            | List user's routines         |
| `POST`   | `/routines`                            | Create routine               |
| `GET`    | `/routines/:routineId`                 | Get routine with exercises   |
| `PATCH`  | `/routines/:routineId`                 | Update routine               |
| `DELETE` | `/routines/:routineId`                 | Delete routine               |
| `POST`   | `/routines/:routineId/exercises`       | Add exercise                 |
| `PATCH`  | `/routines/:routineId/exercises/:reId` | Update exercise prescription |
| `DELETE` | `/routines/:routineId/exercises/:reId` | Remove exercise              |

### Programs

| Method   | Endpoint                              | Description                    |
| -------- | ------------------------------------- | ------------------------------ |
| `GET`    | `/programs`                           | List user's programs           |
| `POST`   | `/programs`                           | Create program                 |
| `GET`    | `/programs/:programId`                | Get program with routine slots |
| `PATCH`  | `/programs/:programId`                | Update program                 |
| `DELETE` | `/programs/:programId`                | Delete program                 |
| `POST`   | `/programs/:programId/routines`       | Assign routine to day          |
| `PATCH`  | `/programs/:programId/routines/:prId` | Change day number              |
| `DELETE` | `/programs/:programId/routines/:prId` | Remove routine from program    |
| `POST`   | `/programs/:programId/activate`       | Self-assign program            |
| `POST`   | `/programs/:programId/deactivate`     | Stop program                   |
| `GET`    | `/programs/active`                    | Get active assignment          |

### Today & Sessions

| Method | Endpoint                        | Description                                        |
| ------ | ------------------------------- | -------------------------------------------------- |
| `GET`  | `/today`                        | Day-cycle resolution → today's routine or rest day |
| `POST` | `/sessions`                     | Start session                                      |
| `GET`  | `/sessions/active`              | Get in-progress session                            |
| `GET`  | `/sessions`                     | List past sessions                                 |
| `GET`  | `/sessions/:sessionId`          | Session detail with performed sets                 |
| `POST` | `/sessions/:sessionId/complete` | Complete session                                   |
| `GET`  | `/stats/weekly`                 | Weekly stats aggregation                           |

---

## Usage Examples

### Load programs (offline-first)

```dart
// Show cached data immediately
final localResult = await repo.getProgramsLocal(userId);

// Trigger background refresh
final serverResult = await repo.syncPrograms();
```

### Activate a program

```dart
final result = await ref
    .read(standaloneWorkoutRepositoryProvider)
    .activateProgram(programId: programId);

result.when(
  success: (assignment) => // navigate to today screen,
  failure: (error) => // show error,
);
```

### Get today's routine

```dart
final result = await ref
    .read(standaloneWorkoutRepositoryProvider)
    .getTodayRoutine();

result.when(
  success: (today) {
    if (!today.hasRoutine) {
      // Show rest day or "no program" message
    } else {
      // Show today.today!.routine
    }
  },
  failure: (error) => // show error,
);
```

---

## Implementation Status

| Layer                                                | Status             |
| ---------------------------------------------------- | ------------------ |
| Models (`standalone_*_model.dart`, request models)   | ✅ Complete        |
| Drift tables (3 new tables, schema v2, CRUD methods) | ✅ Complete        |
| API constants                                        | ✅ Complete        |
| Repository (`StandaloneWorkoutRepository`)           | ✅ Complete        |
| Presentation providers                               | 🔮 Not Implemented |
| Screens & widgets                                    | 🔮 Not Implemented |
| Routes                                               | 🔮 Not Implemented |

---

## Primary Files

| File                                                                         | Description                                                                            |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `lib/features/standalone_workout/standalone_workout.dart`                    | Feature barrel export                                                                  |
| `lib/features/standalone_workout/data/standalone_workout_repository.dart`    | Full offline-first repository + `standaloneWorkoutRepositoryProvider`                  |
| `lib/features/standalone_workout/data/models/standalone_exercise_model.dart` | Exercise + list response                                                               |
| `lib/features/standalone_workout/data/models/standalone_routine_model.dart`  | Routine summary + list response                                                        |
| `lib/features/standalone_workout/data/models/standalone_program_model.dart`  | Program hierarchy (summary, detail, slot, junction, assignment)                        |
| `lib/features/standalone_workout/data/models/standalone_today_model.dart`    | Day-cycling today model with extension helpers                                         |
| `lib/features/standalone_workout/data/models/standalone_session_model.dart`  | Session summary + list response (re-exports `WorkoutSessionModel`, `WeeklyStatsModel`) |
| `lib/features/standalone_workout/data/models/standalone_request_models.dart` | All 12 CRUD request body models                                                        |
| `lib/services/database/app_database.dart`                                    | +3 tables, +14 CRUD methods, v1→v2 migration                                           |
| `lib/core/constants/api_constants.dart`                                      | +8 standalone endpoint constants                                                       |
| `lib/core/constants/app_constants.dart`                                      | `databaseVersion` bumped `1 → 2`                                                       |
