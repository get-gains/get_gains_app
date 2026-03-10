# Workout Feature Documentation

> **Created**: January 29-30, 2026  
> **Updated**: March 9, 2026  
> **Status**: Implemented

---

## Overview

This feature allows users to:

- View assigned workout routines
- Start workout sessions with **form recording** for each exercise
- Compare exercise form against coach's reference (side-by-side skeleton, similarity score)
- Log sets, reps, and weight from the comparison results screen
- Navigate exercise-by-exercise through the routine recording flow
- Track workout progress and completion
- Mark exercises as done

---

## Workout Session Flow

### Record-First Workflow (as of Feb 19, 2026)

When a user presses **"Start Workout"** on a routine:

1. **Session created** — `workoutSessionProvider.startSession()` creates a server-side workout session
2. **First exercise → recording screen** — `RoutineDetailScreen._startWorkout()` navigates to `ClientUnityRecordingScreen` with workout context (`workoutSessionId`, `routineExerciseId`, `routineExercises`, `currentExerciseIndex: 0`)
3. **Record** — User records their exercise form via device camera + MLKit pose detection
4. **DTW comparison** — On-device comparison against coach's reference form
5. **Results + set logging** — Side-by-side skeleton replay (coach cyan vs user green), overall similarity score, segment breakdown, corrections, and a **set logger** with auto-detected reps + weight input
6. **Log & next** — User logs the set → navigates to the next exercise's recording screen
7. **Final exercise** — After logging the last exercise's set, navigates to `WorkoutSessionScreen` for session completion

---

## Acceptance Criteria

| Criteria                                                     | Status |
| ------------------------------------------------------------ | ------ |
| Exercises can be logged with sets, reps, and weight          | ✅     |
| Exercises can be marked as done                              | ✅     |
| Exercises will be seen as performed in the routines screen   | ✅     |
| Exercises contribute to routine completion/consistency score | ✅     |

---

## Flutter App Implementation

### Folder Structure

```
lib/features/workout/
├── workout.dart                          # Feature barrel export
├── data/
│   ├── data.dart                         # Data layer barrel export
│   ├── workout_repository.dart           # Repository with CRUD operations
│   └── models/
│       ├── models.dart                   # Models barrel export
│       ├── exercise_model.dart           # Exercise & RoutineExercise models
│       ├── routine_model.dart            # Routine model
│       ├── workout_session_model.dart    # Workout session model
│       └── performed_set_model.dart      # Performed set & editable set models
└── presentation/
    ├── presentation.dart                 # Presentation layer barrel export
    ├── providers/
    │   ├── providers.dart                # Providers barrel export
    │   ├── workout_session_provider.dart # Manages workout session state
    │   └── exercise_log_provider.dart    # Manages per-exercise set logging
    ├── screens/
    │   ├── screens.dart                  # Screens barrel export
    │   ├── routine_list_screen.dart      # Lists available routines
    │   └── workout_session_screen.dart   # Active workout UI
    └── widgets/
        ├── widgets.dart                  # Widgets barrel export
        ├── exercise_tab_bar.dart         # Horizontal exercise navigation
        ├── exercise_log_card.dart        # Exercise details & set inputs
        └── set_input_row.dart            # Individual set input with +/- controls
```

### Data Models

#### ExerciseModel

```dart
@freezed
class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    required String id,
    required String name,
    required String description,
    required MuscleGroup primaryMuscleGroup,
    @Default([]) List<String> equipmentNeeded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciseModel;
}
```

#### RoutineModel

```dart
@freezed
class RoutineModel with _$RoutineModel {
  const factory RoutineModel({
    required String id,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,
    @Default([]) List<RoutineExerciseModel> exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoutineModel;
}
```

#### WorkoutSessionModel

```dart
@freezed
class WorkoutSessionModel with _$WorkoutSessionModel {
  const factory WorkoutSessionModel({
    required String id,
    required String userId,
    String? assignedProgramId,
    String? routineId,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,
    @Default([]) List<PerformedSetModel> performedSets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WorkoutSessionModel;
}
```

#### PerformedSetModel

```dart
@freezed
class PerformedSetModel with _$PerformedSetModel {
  const factory PerformedSetModel({
    required String id,
    required String workoutSessionId,
    required String routineExerciseId,
    required int setNumber,
    required int repsCompleted,
    double? weightKg,
    int? rpe,
    String? notes,
    @Default(false) bool isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PerformedSetModel;
}
```

### Database Tables (Drift)

Added to `lib/services/database/app_database.dart`:

| Table              | Description                                                              |
| ------------------ | ------------------------------------------------------------------------ |
| `Exercises`        | Exercise library with muscle groups and equipment                        |
| `Routines`         | Workout routines with duration and target muscles                        |
| `RoutineExercises` | Junction table linking routines to exercises with sets/reps prescription |
| `WorkoutSessions`  | User workout sessions with start/end times                               |
| `PerformedSets`    | Individual sets logged by users                                          |

### Routes

Added to `lib/providers/router_provider.dart`:

| Route              | Screen                 | Description                     |
| ------------------ | ---------------------- | ------------------------------- |
| `/routines`        | `RoutineListScreen`    | View available workout routines |
| `/workout-session` | `WorkoutSessionScreen` | Active workout logging screen   |

### API Constants

Added to `lib/core/constants/api_constants.dart`:

```dart
static const String routines = '/workout/routines';
static const String workoutSessions = '/workout/sessions';
static const String performedSets = '/workout/sets';
```

---

## Backend Implementation (Express.js)

### Files Created

| File                                    | Description                                      |
| --------------------------------------- | ------------------------------------------------ |
| `src/schemas/workout.schema.ts`         | Zod validation schemas for all workout endpoints |
| `src/controllers/workout.controller.ts` | Controller with all workout operations           |
| `src/routes/workout.routes.ts`          | Express router with protected routes             |

### API Endpoints

All routes are prefixed with `/api/workout` and require authentication.

#### Exercises

| Method | Endpoint     | Description                   |
| ------ | ------------ | ----------------------------- |
| GET    | `/exercises` | List exercises with filtering |

#### Routines

| Method | Endpoint               | Description                       |
| ------ | ---------------------- | --------------------------------- |
| GET    | `/routines`            | List user's assigned routines     |
| GET    | `/routines/:routineId` | Get single routine with exercises |

#### Workout Sessions

| Method | Endpoint                        | Description                 |
| ------ | ------------------------------- | --------------------------- |
| POST   | `/sessions`                     | Start a new workout session |
| GET    | `/sessions/active`              | Get user's active session   |
| GET    | `/sessions`                     | Get workout history         |
| GET    | `/sessions/:sessionId`          | Get single session details  |
| POST   | `/sessions/:sessionId/complete` | Complete a workout session  |

#### Performed Sets

| Method | Endpoint       | Description                  |
| ------ | -------------- | ---------------------------- |
| POST   | `/sets`        | Log a new set                |
| PUT    | `/sets/:setId` | Update an existing set       |
| DELETE | `/sets/:setId` | Delete a set                 |
| POST   | `/sets/sync`   | Batch sync sets from offline |

### Prisma Schema

The following models already existed in `prisma/schema.prisma`:

- `Exercise`
- `Routine`
- `RoutineExercise`
- `WorkoutSession`
- `PerformedSet`

---

## Home Screen Feature

### Folder Structure

```
lib/features/home/
├── home.dart                             # Feature barrel export
└── presentation/
    ├── presentation.dart                 # Presentation layer barrel export
    ├── screens/
    │   └── home_screen.dart              # Main dashboard screen
    └── widgets/
        ├── widgets.dart                  # Widgets barrel export
        ├── quick_action_card.dart        # Gradient action cards
        ├── workout_summary_card.dart     # Today's workout card
        └── weekly_progress_card.dart     # Weekly stats & progress
```

### Features

- **Welcome Header**: Personalized greeting based on time of day
- **Quick Actions**: Gradient cards for "Start Workout" and "History"
- **Today's Focus**: Shows assigned routine or placeholder
- **Weekly Progress**: Progress bar, stats (streak, time, workouts), day indicators
- **Bottom Navigation**: Home, Workouts, Progress, Profile tabs

---

## Bug Fixes & Improvements

### Start Workout → Recording Flow (Feb 19, 2026)

- **Change**: "Start Workout" now navigates to the first exercise's `ClientUnityRecordingScreen` instead of directly to `WorkoutSessionScreen`
- **Files modified**: `routine_detail_screen.dart` (`_startWorkout`), `router_provider.dart` (`clientUnityRecord` route), `client_unity_recording_screen.dart` (workout mode), `workout_session_provider.dart` (`logSet` override), `client_recording_provider.dart` (landmark frames in complete state)
- **Workout context**: Passed via `go_router` `extra` map with `workoutSessionId`, `routineExerciseId`, `routineExercises`, `currentExerciseIndex`
- **Set logging**: `logSet()` now accepts optional `routineExerciseIdOverride` so the recording screen can log sets for a specific exercise without relying on `currentExerciseIndex`

### GG-70: Exercise Not Marked Finished (Mar 9, 2026)

Multiple issues preventing exercises from being correctly marked as done during a workout session.

**Bugs fixed:**

1. **`_calculateCurrentExerciseIndex` off-by-one** — Returned `exercises.length - 1` when all exercises were complete; now returns `exercises.length` so `isAllExercisesCompleted` evaluates correctly.
2. **`logSet` did not auto-advance** — After logging the final set of an exercise, the exercise index was not recalculated. Now `_calculateCurrentExerciseIndex` is called after each logged set and the PageView auto-scrolls to the next exercise.
3. **`WorkoutSessionCompleted` lost routine context** — Added optional `RoutineModel? routine` field so the completion dialog can show a per-exercise breakdown (checkmark + sets count).
4. **Completion dialog per-exercise breakdown** — On session complete, the dialog lists each exercise with a green checkmark and the number of sets performed.
5. **Removed redundant Finish button** — The `TextButton('Finish')` in the AppBar was removed; session is completed via the auto-triggered dialog when all exercises are done.

**Files modified:** `workout_session_provider.dart`, `workout_session_screen.dart`

---

### Routine Detail Screen — Completion Indicators & Do Again (Mar 9, 2026)

Added live and history-based exercise completion indicators to `RoutineDetailScreen`.

- **`_ExerciseListSliver`** (`ConsumerWidget`) — Watches both the active `workoutSessionProvider` and `todayCompletedSessionProvider` (local DB history) to show per-exercise completion (green checkmark + "N/M sets"). Priority: active session → just-completed session → today's history.
- **`_StartWorkoutButton`** (`ConsumerWidget`) — Shows a green "Workout Done Today" banner with a "Do Again" outline button when a completed session exists for today, otherwise shows "Start Workout".
- **`_ExerciseCard`** — Accepts `completedSets` parameter; when > 0, renders a green checkmark badge with set count.
- **`todayCompletedSessionProvider(routineId)`** — Riverpod `FutureProvider` that queries local Drift DB for today's completed session for that routine, providing persistent indicators even after the app restarts.

**Files modified:** `routine_detail_screen.dart`, `workout_session_provider.dart`

---

### Routine Detail Screen — View Form Removed & UI Polish (Mar 9, 2026)

Removed the standalone "View Form" button from exercise cards on the routine detail page. Users must start a workout to access form comparison. Also improved visual hierarchy:

- **`_ExerciseCard`** — Removed `onViewForm` callback and "View Form" `OutlinedButton`. Exercise cards now show only exercise info (name, sets×reps, muscle group, completion status). Changed order number container from rounded rectangle to circle shape.
- **`_ExerciseListSliver`** — Removed `onViewForm` parameter and callback forwarding.
- **`_StartWorkoutButton`** — Moved from `CustomScrollView` sliver to `Scaffold.bottomNavigationBar` wrapped in `SafeArea`, making it persistently visible without scrolling.
- **`_navigateToViewForm`** method — Removed entirely from `_RoutineDetailScreenState`.
- **Scaffold restructure** — `FutureBuilder` now wraps the `Scaffold` (instead of being inside it) so the `bottomNavigationBar` has access to the loaded routine.

**Files modified:** `routine_detail_screen.dart`

---

### Server `completedToday` Flag (Mar 9, 2026)

- `GET /api/workout/today` response now includes `completedToday: boolean` — `true` when the user has a completed `WorkoutSession` with `completedAt >= todayStart` for the current routine.
- `TodayRoutineModel` in Flutter gained `@Default(false) bool completedToday`.
- `WorkoutSummaryCard` on the home screen shows "Workout Done Today ✓" (disabled button) when `completedToday` is true.

**Files modified:** `workout.controller.ts` (server), `today_routine_model.dart`, `workout_summary_card.dart`, `home_screen.dart`

---

### Local DB Workout History (Mar 9, 2026)

The history screen previously fetched from the server API (`GET /workout/sessions`), but sync was failing with a 403 (subscription required). Switched to offline-first local DB reads.

- **`getLocalSessionHistory({userId, limit, offset})`** — New `WorkoutRepository` method that reads completed sessions from Drift and resolves routine names locally.
- **`getCompletedSessions(userId, {limit, offset})`** and **`countCompletedSessions(userId)`** — New paginated Drift queries.
- **Auto-cleanup** — `deleteOldCompletedSessions(days: 7)` deletes completed sessions older than 7 days (performed sets cascade-deleted). Called automatically at the start of `getLocalSessionHistory()`.
- **Sync trigger** — `completeSession()` now calls `workoutSyncService.syncAll()` on success.

**Files modified:** `app_database.dart`, `workout_repository.dart`, `workout_history_screen.dart`, `workout_session_provider.dart`

---

### `getActiveWorkoutSession` — Too Many Elements Fix (Mar 9, 2026)

- Multiple incomplete sessions could exist in the local DB, causing `getSingle()` to throw "Bad state: Too many elements".
- Added `..limit(1)` and `orderBy(startedAt desc)` to return only the most recent active session.

**Files modified:** `app_database.dart`

---

### WorkoutSessionScreen Initial State Loop (Feb 18, 2026)

- **Issue**: When navigating to `/workout-session` without an active session (i.e. `WorkoutSessionInitial` state), the screen showed "No Active Workout" with a "View Routines" button that sent users back to `/routines`, causing a loop instead of starting the session.
- **Solution**: `WorkoutSessionInitial` now automatically redirects to `/routines` via `WidgetsBinding.addPostFrameCallback` and shows a spinner during the redirect. Users select a routine → start workout from `RoutineDetailScreen` → `_startWorkout` calls `workoutSessionProvider.startSession()` → navigates to `/workout-session` with an active session already in place.

### AppColors Usage

- **Issue**: `AppColors.primary` is a method, not a static constant
- **Solution**: Changed to `isDark ? AppColors.primaryDark : AppColors.primaryLight`

### AppEmptyState Action

- **Issue**: Used `action` parameter with widget
- **Solution**: Changed to `actionLabel` + `onAction` callback pattern

### AppBadge Color

- **Issue**: Used `color` parameter
- **Solution**: Changed to `variant: AppBadgeVariant.primary`

### AuthState userName

- **Issue**: `userName` getter doesn't exist on AuthState
- **Solution**: Extract name from email: `email.split('@').first`

### Button Text Centering

- **Issue**: Button text not centered when `isFullWidth` is false
- **Solution**: Wrapped content in `IntrinsicWidth(child: Center(...))` in AppButton

---

## Commands Reference

### Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Regenerate Prisma Client

```bash
npx prisma generate
```

### Type Check Server

```bash
npx tsc --noEmit
```

---

## Future Enhancements

- [x] Add workout history screen (local DB, Mar 9 2026)
- [ ] Implement progress/stats screen
- [ ] Add rest timer between sets
- [ ] Add exercise demonstration videos/images
- [x] Implement offline sync queue processing (partial — sync trigger on complete, Mar 9 2026)
- [ ] Add workout notifications/reminders
- [ ] Fix server sync 403 — `POST /workout/sessions` requires subscription; relax or bypass for session sync
- [ ] Optimize `deleteOldCompletedSessions` to run once per day instead of every history page load
