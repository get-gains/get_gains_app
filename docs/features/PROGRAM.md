# Coach Programs Feature

> **Purpose**: Complete data layer for the coach program flow — creating programs & routines, building exercise prescriptions, assigning routines to program day-slots, and managing client program assignments.

---

## Overview

The coach program flow enables coaches to:

1. **Create reusable Routines** (e.g. "Push Day", "Pull Day")
2. **Build Routines** by adding exercises from the global library with prescriptions (sets, reps, rest)
3. **Create Programs** (e.g. "Push Pull Legs") and assign routines to day-slots
4. **Assign Programs** to clients with start/end dates
5. **Manage** all entities (update, delete, reorder)

All three nodes — **Program**, **Routine**, **Exercise** — are reusable:
- A program can be assigned to many clients
- A routine can be reused across programs
- An exercise can be reused across routines

```
Coach creates Program (e.g. Push Pull Legs)
  → Coach creates Routine (e.g. Push)
    → Coach picks an Exercise (e.g. Bench Press)
      → Exercise is added to Routine with prescription (sets/reps/rest)
        → Routine is assigned to Program on a day number
          → Program is assigned to a specific Client
            → Client performs the workout
              → Client logs sets (reps + weight + RPE)
```

---

## Architecture

```
lib/features/coach_programs/
├── coach_programs.dart                          ← Feature barrel export
├── data/
│   ├── data.dart                                ← Data layer barrel
│   ├── coach_program_repository.dart            ← All API calls
│   └── models/
│       ├── models.dart                          ← Models barrel
│       ├── program_model.dart                   ← Program, Routine summary, Assignment, Pagination models
│       └── program_request_models.dart          ← Create/Update request models
└── presentation/
    ├── presentation.dart                        ← Presentation layer barrel
    └── providers/
        ├── providers.dart                       ← Providers barrel
        ├── coach_program_provider.dart          ← Programs list + detail notifiers
        ├── coach_routine_provider.dart          ← Routines list + detail notifiers
        └── coach_assignment_provider.dart       ← Client assignment notifier
```

### Shared Models (from `workout` feature)

The following existing models are **reused** rather than duplicated:

| Model | Location | Used For |
|-------|----------|----------|
| `MuscleGroup` (enum) | `workout/data/models/exercise_model.dart` | Routine target muscles |
| `ExerciseModel` | `workout/data/models/exercise_model.dart` | Global exercise library |
| `RoutineExerciseModel` | `workout/data/models/exercise_model.dart` | Exercise slot in a routine |
| `RoutineModel` | `workout/data/models/routine_model.dart` | Full routine with exercises |

> **Note**: `RoutineModel` was extended with an optional `coachId` field to support coach ownership without breaking existing client-side usage.

---

## Models Reference

### ProgramSummaryModel

Lightweight program info returned by list endpoints.

```dart
ProgramSummaryModel({
  required String id,
  required String name,
  required String description,
  int routineCount,            // number of day-slots
  int assignedClientCount,     // number of clients assigned
  DateTime? createdAt,
  DateTime? updatedAt,
})
```

### ProgramDetailModel

Full program with nested routine/exercise tree.

```dart
ProgramDetailModel({
  required String id,
  required String name,
  required String description,
  required String coachId,
  List<ProgramRoutineSlotModel> routines,  // day-slots
  DateTime? createdAt,
  DateTime? updatedAt,
})
```

#### ProgramRoutineSlotModel (nested)

```dart
ProgramRoutineSlotModel({
  required String id,           // ProgramRoutine junction ID
  required int dayNumber,       // day in the cycle (1-based)
  required RoutineModel routine, // full routine with exercises
})
```

### RoutineSummaryModel

Routine with exercise/program counts for list views.

```dart
RoutineSummaryModel({
  required String id,
  required String coachId,
  required String name,
  required String description,
  required int estimatedDurationMinutes,
  List<MuscleGroup> muscleGroupsTargeted,
  int exerciseCount,
  int programCount,
  DateTime? createdAt,
  DateTime? updatedAt,
})
```

### AssignedProgramModel

Program assignment linking a program to a client.

```dart
AssignedProgramModel({
  required String id,
  required String userId,
  required String programId,
  required DateTime startDate,
  DateTime? endDate,
  bool isActive,
  String? notes,
  AssignmentProgramInfo? program,  // { id, name, description?, routineCount? }
  AssignmentUserInfo? user,        // { id, email, name?, nickname? }
  DateTime? createdAt,
  DateTime? updatedAt,
})
```

### PaginationMeta

Standard pagination info returned by list endpoints.

```dart
PaginationMeta({
  required int total,
  required int limit,
  required int offset,
  bool hasMore,
})
```

---

## Request Models

| Model | Endpoint | Fields |
|-------|----------|--------|
| `CreateProgramRequest` | `POST /coach/programs` | `name`, `description` |
| `UpdateProgramRequest` | `PATCH /coach/programs/:id` | `name?`, `description?` |
| `CreateRoutineRequest` | `POST /coach/routines` | `name`, `description`, `estimatedDurationMinutes`, `muscleGroupsTargeted[]` |
| `UpdateRoutineRequest` | `PATCH /coach/routines/:id` | `name?`, `description?`, `estimatedDurationMinutes?`, `muscleGroupsTargeted[]?` |
| `AssignRoutineRequest` | `POST /coach/programs/:id/routines` | `routineId`, `dayNumber` |
| `UpdateProgramRoutineRequest` | `PATCH /coach/programs/:id/routines/:jid` | `dayNumber` |
| `AddRoutineExerciseRequest` | `POST /coach/programs/routines/:id/exercises` | `exerciseId`, `sets`, `repsMin`, `repsMax`, `restSeconds`, `orderInRoutine`, `notes?` |
| `UpdateRoutineExerciseRequest` | `PATCH /coach/programs/routines/:id/exercises/:jid` | `sets?`, `repsMin?`, `repsMax?`, `restSeconds?`, `orderInRoutine?`, `notes?` |
| `AssignProgramRequest` | `POST /coach/assign-program` | `userId`, `programId`, `startDate`, `endDate?`, `notes?` |
| `UpdateAssignmentRequest` | `PATCH /coach/assign-program/:id` | `startDate?`, `endDate?`, `notes?`, `isActive?` |

---

## API Endpoints Mapping

### Programs CRUD

| Method | Path | Repository Method | Returns |
|--------|------|-------------------|---------|
| `GET` | `/coach/programs` | `getPrograms()` | `List<ProgramSummaryModel>` + pagination |
| `POST` | `/coach/programs` | `createProgram()` | `ProgramSummaryModel` |
| `GET` | `/coach/programs/:programId` | `getProgramById()` | `ProgramDetailModel` (full tree) |
| `PATCH` | `/coach/programs/:programId` | `updateProgram()` | `ProgramSummaryModel` |
| `DELETE` | `/coach/programs/:programId` | `deleteProgram()` | `void` |

### Routines CRUD

| Method | Path | Repository Method | Returns |
|--------|------|-------------------|---------|
| `GET` | `/coach/routines` | `getRoutines()` | `List<RoutineSummaryModel>` + pagination |
| `POST` | `/coach/routines` | `createRoutine()` | `RoutineModel` |
| `GET` | `/coach/routines/:routineId` | `getRoutineById()` | `RoutineModel` (with exercises) |
| `PATCH` | `/coach/routines/:routineId` | `updateRoutine()` | `RoutineModel` |
| `DELETE` | `/coach/routines/:routineId` | `deleteRoutine()` | `void` |

### ProgramRoutine Junctions (day-slots)

| Method | Path | Repository Method | Returns |
|--------|------|-------------------|---------|
| `POST` | `/coach/programs/:id/routines` | `assignRoutineToProgram()` | `ProgramRoutineModel` |
| `PATCH` | `/coach/programs/:id/routines/:jid` | `updateProgramRoutine()` | `ProgramRoutineModel` |
| `DELETE` | `/coach/programs/:id/routines/:jid` | `removeProgramRoutine()` | `void` |

### RoutineExercise Junctions (exercise prescriptions)

| Method | Path | Repository Method | Returns |
|--------|------|-------------------|---------|
| `POST` | `/coach/programs/routines/:id/exercises` | `addExerciseToRoutine()` | `RoutineExerciseModel` |
| `PATCH` | `/coach/programs/routines/:id/exercises/:jid` | `updateRoutineExercise()` | `RoutineExerciseModel` |
| `DELETE` | `/coach/programs/routines/:id/exercises/:jid` | `removeRoutineExercise()` | `void` |

### Program Assignments

| Method | Path | Repository Method | Returns |
|--------|------|-------------------|---------|
| `POST` | `/coach/assign-program` | `assignProgram()` | `AssignedProgramModel` |
| `GET` | `/coach/clients/:userId/programs` | `getClientPrograms()` | `List<AssignedProgramModel>` |
| `PATCH` | `/coach/assign-program/:id` | `updateAssignment()` | `AssignedProgramModel` |
| `DELETE` | `/coach/assign-program/:id` | `deleteAssignment()` | `void` |

---

## Providers Reference

### CoachProgramsNotifier

Manages the paginated list of coach programs.

```dart
// Watch the full state
final state = ref.watch(coachProgramsProvider);

// Or use convenience providers
final isLoading = ref.watch(coachProgramsLoadingProvider);
final programs = ref.watch(coachProgramsListProvider);
final pagination = ref.watch(coachProgramsPaginationProvider);
final error = ref.watch(coachProgramsErrorProvider);

// Actions
ref.read(coachProgramsProvider.notifier).loadPrograms();
ref.read(coachProgramsProvider.notifier).loadMore();
ref.read(coachProgramsProvider.notifier).createProgram(request);
ref.read(coachProgramsProvider.notifier).updateProgram(id, request);
ref.read(coachProgramsProvider.notifier).deleteProgram(id);
```

### ProgramDetailNotifier (family)

Manages a single program's detail view. One instance per program ID.

```dart
// Watch program detail
final state = ref.watch(programDetailProvider(programId));

// Actions
ref.read(programDetailProvider(programId).notifier).load();
ref.read(programDetailProvider(programId).notifier).assignRoutine(request);
ref.read(programDetailProvider(programId).notifier).updateProgramRoutine(jid, request);
ref.read(programDetailProvider(programId).notifier).removeProgramRoutine(jid);
```

### CoachRoutinesNotifier

Manages the paginated list of coach routines.

```dart
// Watch the full state
final state = ref.watch(coachRoutinesProvider);

// Or use convenience providers
final isLoading = ref.watch(coachRoutinesLoadingProvider);
final routines = ref.watch(coachRoutinesListProvider);
final pagination = ref.watch(coachRoutinesPaginationProvider);
final error = ref.watch(coachRoutinesErrorProvider);

// Actions
ref.read(coachRoutinesProvider.notifier).loadRoutines();
ref.read(coachRoutinesProvider.notifier).loadMore();
ref.read(coachRoutinesProvider.notifier).createRoutine(request);
ref.read(coachRoutinesProvider.notifier).updateRoutine(id, request);
ref.read(coachRoutinesProvider.notifier).deleteRoutine(id);
```

### RoutineDetailNotifier (family)

Manages a single routine's detail view with exercises. One instance per routine ID.

```dart
// Watch routine detail
final state = ref.watch(routineDetailProvider(routineId));

// Actions
ref.read(routineDetailProvider(routineId).notifier).load();
ref.read(routineDetailProvider(routineId).notifier).addExercise(request);
ref.read(routineDetailProvider(routineId).notifier).updateExercise(jid, request);
ref.read(routineDetailProvider(routineId).notifier).removeExercise(jid);
```

### ClientAssignmentsNotifier (family)

Manages program assignments for a specific client. One instance per user ID.

```dart
// Watch assignments for a client
final state = ref.watch(clientAssignmentsProvider(userId));

// Convenience: active assignments only
final active = ref.watch(clientActiveAssignmentsProvider(userId));

// Actions
ref.read(clientAssignmentsProvider(userId).notifier).load();
ref.read(clientAssignmentsProvider(userId).notifier).assignProgram(request);
ref.read(clientAssignmentsProvider(userId).notifier).updateAssignment(id, request);
ref.read(clientAssignmentsProvider(userId).notifier).deleteAssignment(id);
```

---

## State Patterns

All list notifiers use sealed state classes:

```dart
sealed class CoachProgramsState
├── CoachProgramsInitial     // not yet loaded
├── CoachProgramsLoading     // loading in progress
├── CoachProgramsLoaded      // { programs, pagination }
└── CoachProgramsError       // { error: AppError }

sealed class ProgramDetailState
├── ProgramDetailInitial
├── ProgramDetailLoading
├── ProgramDetailLoaded      // { program: ProgramDetailModel }
└── ProgramDetailError       // { error: AppError }

// Same pattern for CoachRoutinesState, RoutineDetailState, ClientAssignmentsState
```

**Pattern usage in widgets:**

```dart
final state = ref.watch(coachProgramsProvider);

return switch (state) {
  CoachProgramsInitial() => const SizedBox.shrink(),
  CoachProgramsLoading() => const CircularProgressIndicator(),
  CoachProgramsLoaded(:final programs) => ProgramListView(programs: programs),
  CoachProgramsError(:final error) => ErrorWidget(message: error.message),
};
```

---

## Usage Examples

### Creating a Complete Program

```dart
// 1. Create a routine
final routineCreated = await ref
    .read(coachRoutinesProvider.notifier)
    .createRoutine(const CreateRoutineRequest(
      name: 'Push Day',
      description: 'Chest, shoulders, triceps',
      estimatedDurationMinutes: 60,
      muscleGroupsTargeted: [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps],
    ));

// 2. Add exercises to the routine (via routine detail)
await ref
    .read(routineDetailProvider(routineId).notifier)
    .addExercise(const AddRoutineExerciseRequest(
      exerciseId: 'exercise-id-bench-press',
      sets: 4,
      repsMin: 8,
      repsMax: 12,
      restSeconds: 90,
      orderInRoutine: 1,
      notes: 'Control the eccentric',
    ));

// 3. Create a program
await ref
    .read(coachProgramsProvider.notifier)
    .createProgram(const CreateProgramRequest(
      name: 'Push Pull Legs',
      description: '3-day split program',
    ));

// 4. Assign the routine to a day in the program
await ref
    .read(programDetailProvider(programId).notifier)
    .assignRoutine(AssignRoutineRequest(
      routineId: routineId,
      dayNumber: 1,
    ));

// 5. Assign the program to a client
await ref
    .read(clientAssignmentsProvider(userId).notifier)
    .assignProgram(AssignProgramRequest(
      userId: clientUserId,
      programId: programId,
      startDate: DateTime.now().toIso8601String(),
    ));
```

### Loading and Displaying Programs

```dart
// In initState or on first load
ref.read(coachProgramsProvider.notifier).loadPrograms();

// In build method
final programs = ref.watch(coachProgramsListProvider);
final isLoading = ref.watch(coachProgramsLoadingProvider);
final pagination = ref.watch(coachProgramsPaginationProvider);

// Infinite scroll
if (pagination?.hasMore ?? false) {
  ref.read(coachProgramsProvider.notifier).loadMore();
}
```

---

## Relationship to Other Features

| Feature | Relationship |
|---------|-------------|
| **Workout** | Shares `ExerciseModel`, `RoutineExerciseModel`, `RoutineModel`, `MuscleGroup` |
| **Subscription** | Coach features require active coach profile; client access to coach content may require subscription |
| **Profile** | Coach profile must exist before program creation |

---

## Server Response Format

All endpoints follow the standard server envelope:

```json
{
  "data": { "program": { ... } },
  "errors": []
}
```

The `ApiClient` automatically unwraps the `data` field. Repository methods receive the inner payload directly.

---

*Last updated: February 21, 2026*
