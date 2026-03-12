# Coach Programs Feature

> **Purpose**: Full-stack coach program flow — creating programs & routines, building exercise prescriptions, assigning routines to program day-slots, managing client program assignments, and the complete presentation layer (screens, bottom sheets, routing).

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
    ├── providers/
    │   ├── providers.dart                       ← Providers barrel
    │   ├── coach_program_provider.dart          ← Programs list + detail notifiers
    │   ├── coach_routine_provider.dart          ← Routines list + detail notifiers
    │   └── coach_assignment_provider.dart       ← Client assignment notifier
    └── screens/
        ├── screens.dart                         ← Screens barrel
        ├── coach_programs_screen.dart           ← Programs list (paginated, pull-to-refresh)
        ├── coach_program_detail_screen.dart     ← Program detail with day-slot routine tree
        ├── coach_program_form_screen.dart       ← Create / edit program form
        ├── coach_routines_screen.dart           ← Routines list (paginated, muscle group chips)
        ├── coach_routine_detail_screen.dart     ← Routine detail with exercise prescriptions
        ├── coach_routine_form_screen.dart       ← Create / edit routine form
        ├── client_assignments_screen.dart       ← Client program assignments management
        ├── assign_routine_sheet.dart            ← Bottom sheet: assign routine to a day-slot
        ├── add_exercise_sheet.dart              ← Bottom sheet: add exercise to a routine
        └── assign_program_sheet.dart            ← Bottom sheet: assign program to a client
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

## Presentation Layer

### Routing

All routes are defined in `router_provider.dart` under the `AppRoutes` class:

| Constant | Path | Screen | Parameters |
|----------|------|--------|------------|
| `coachPrograms` | `/coach/programs` | `CoachProgramsScreen` | — |
| `coachCreateProgram` | `/coach/programs/create` | `CoachProgramFormScreen` | — |
| `coachProgramDetail` | `/coach/programs/:id` | `CoachProgramDetailScreen` | `id` (path) |
| `coachEditProgram` | `/coach/programs/:id/edit` | `CoachProgramFormScreen` | `id` (path) |
| `coachRoutines` | `/coach/routines` | `CoachRoutinesScreen` | — |
| `coachCreateRoutine` | `/coach/routines/create` | `CoachRoutineFormScreen` | — |
| `coachRoutineDetail` | `/coach/routines/:id` | `CoachRoutineDetailScreen` | `id` (path) |
| `coachEditRoutine` | `/coach/routines/:id/edit` | `CoachRoutineFormScreen` | `id` (path) |
| `clientAssignments` | `/coach/clients/:userId/programs` | `ClientAssignmentsScreen` | `userId` (path), `name?` (query) |

> **Route ordering**: Static paths (e.g. `/coach/programs/create`) are defined **before** parameterized paths (e.g. `/coach/programs/:id`) to prevent GoRouter from matching `:id` against `create`.

### Navigation Flow

```
CoachProgramsScreen (list)
├── FAB → CoachProgramFormScreen (create mode)
├── Card tap → CoachProgramDetailScreen
│   ├── Edit icon → CoachProgramFormScreen (edit mode, programId passed)
│   ├── FAB → showAssignRoutineSheet → assigns routine to day-slot
│   ├── Routine name tap → CoachRoutineDetailScreen
│   └── Remove routine → showAppConfirmSheet → removes day-slot
├── Popup "Edit" → CoachProgramFormScreen (edit mode)
├── Popup "Delete" → showAppConfirmSheet → deletes program
└── AppBar action → CoachRoutinesScreen (list)
    ├── FAB → CoachRoutineFormScreen (create mode)
    ├── Card tap → CoachRoutineDetailScreen
    │   ├── Edit icon → CoachRoutineFormScreen (edit mode, routineId passed)
    │   ├── FAB → showAddExerciseSheet → adds exercise with prescription
    │   └── Remove exercise → showAppConfirmSheet → removes exercise
    ├── Popup "Edit" → CoachRoutineFormScreen (edit mode)
    └── Popup "Delete" → showAppConfirmSheet → deletes routine

ClientAssignmentsScreen
├── FAB → showAssignProgramSheet → assigns program to client
├── Popup "Toggle active" → updateAssignment
└── Popup "Delete" → showAppConfirmSheet → deletes assignment
```

### Screens

#### CoachProgramsScreen

**Purpose**: Paginated list of all programs owned by the coach.

**Provider**: `coachProgramsProvider` (with convenience selectors: `coachProgramsLoadingProvider`, `coachProgramsListProvider`, `coachProgramsPaginationProvider`)

**Features**:
- Pull-to-refresh via `RefreshIndicator`
- Infinite scroll via `ScrollController` triggering `loadMore()`
- FAB to create a new program
- AppBar action to navigate to Routines list
- Each card shows: program name, description, routine count, assigned client count
- Popup menu per card: Edit / Delete with confirmation

#### CoachProgramDetailScreen

**Purpose**: Full program view showing the day-slot routine tree.

**Provider**: `programDetailProvider(programId)` (family)

**Features**:
- Sorted day-slot cards showing day number, routine name, description
- Exercise preview per slot (first 3 exercises shown + "+N more" overflow)
- Stats badges: total days, total unique routines
- FAB to assign a routine to a new day-slot via `showAssignRoutineSheet`
- Tap routine name → navigates to routine detail
- Remove routine via confirm sheet
- Edit program via AppBar action

**Extension used**: `ProgramDetailModelX.totalDays`, `.cycleLengthDays` for computed stats.

#### CoachProgramFormScreen

**Purpose**: Dual-mode form for creating or editing a program.

**Provider**: `programDetailProvider(programId)` when editing (loads existing data)

**Fields**: Name (required), Description (required)

**Mode detection**: `programId` constructor param — `null` = create, non-null = edit (pre-fills form from provider state).

#### CoachRoutinesScreen

**Purpose**: Paginated list of all routines owned by the coach.

**Provider**: `coachRoutinesProvider` (with convenience selectors: `coachRoutinesLoadingProvider`, `coachRoutinesListProvider`, `coachRoutinesPaginationProvider`)

**Features**:
- Pull-to-refresh and infinite scroll
- FAB to create a new routine
- Each card shows: routine name, description, exercise/program/duration counts, muscle group chips
- Popup menu per card: Edit / Delete with confirmation

#### CoachRoutineDetailScreen

**Purpose**: Single routine detail showing all exercise prescriptions.

**Provider**: `routineDetailProvider(routineId)` (family)

**Features**:
- Ordered exercise cards with numbered circles
- Prescription stats per exercise: sets, rep range, rest seconds
- Notes display if present
- Muscle group badge
- Stats badges: total exercises, estimated duration
- FAB to add exercise via `showAddExerciseSheet`
- Remove exercise via confirm sheet

#### CoachRoutineFormScreen

**Purpose**: Dual-mode form for creating or editing a routine.

**Provider**: `routineDetailProvider(routineId)` when editing

**Fields**: Name (required), Description (required), Estimated Duration in minutes (required), Muscle Groups Targeted (multi-select `FilterChip` grid over all `MuscleGroup.values`)

**Extension used**: `MuscleGroupX.displayName` for human-readable chip labels.

#### ClientAssignmentsScreen

**Purpose**: View and manage all program assignments for a specific client.

**Provider**: `clientAssignmentsProvider(userId)` (family)

**Params**: `userId` (required path param), `userName` (optional query param for display)

**Features**:
- Assignment cards sorted: active first, then by start date descending
- Active/Inactive badge per card
- Shows: program name, date range, notes, routine count
- Popup menu: Toggle active status / Delete with confirmation
- FAB to assign a new program via `showAssignProgramSheet`

### Bottom Sheets

All bottom sheets use `showAppBottomSheet` from the design system, ensuring consistent styling and swipe-to-dismiss behavior.

#### showAssignRoutineSheet

**Purpose**: Assign an existing routine to a specific day-slot in a program.

**Provider consumed**: `coachRoutinesProvider` (loads routine list for dropdown)  
**Provider mutated**: `programDetailProvider(programId).notifier.assignRoutine()`

**Fields**:
- Routine dropdown (populated from `coachRoutinesListProvider`)
- Day number text field (auto-suggests next available day number)

#### showAddExerciseSheet

**Purpose**: Add an exercise from the global library to a routine with a prescription.

**Provider consumed**: `exerciseListProvider` (from `coach_pose` feature)  
**Provider mutated**: `routineDetailProvider(routineId).notifier.addExercise()`

**Fields**:
- Exercise dropdown (populated from exercise library)
- Sets (default: 3)
- Reps Min (default: 8)
- Reps Max (default: 12)
- Rest Seconds (default: 90)
- Notes (optional)

**Validation**: All numeric fields required and must be > 0; repsMax ≥ repsMin.

#### showAssignProgramSheet

**Purpose**: Assign a program to a client with date range and notes.

**Provider consumed**: `coachProgramsProvider` (loads programs for dropdown)  
**Provider mutated**: `clientAssignmentsProvider(userId).notifier.assignProgram()`

**Fields**:
- Program dropdown (populated from `coachProgramsListProvider`)
- Start date picker (required)
- End date picker (optional)
- Notes (optional)

### Design System Components Used

| Component | Usage |
|-----------|-------|
| `AppButton` | Form submit/cancel actions, sheet confirm/cancel |
| `AppCard` | Program/routine/assignment list cards |
| `AppTextField` | All form text inputs (names, descriptions, numbers, notes) |
| `AppBadge` | Active/inactive assignment status |
| `AppEmptyState` | Empty list fallback with icon + message |
| `AppToast` | Success/error feedback on create, update, delete operations |
| `showAppBottomSheet` | All three bottom sheet invocations |
| `showAppConfirmSheet` | Delete confirmations (program, routine, exercise, assignment) |
| `AppColors` | Dark/light theme colors, coral primary for accents |
| `_InfoChip` (local) | Stats badges on list/detail screens (routines, clients, days, exercises, duration) |

### Screen → Provider Wiring

```
CoachProgramsScreen
  ├── watch: coachProgramsProvider (state switching)
  ├── watch: coachProgramsLoadingProvider
  ├── watch: coachProgramsListProvider
  └── watch: coachProgramsPaginationProvider

CoachProgramDetailScreen
  └── watch: programDetailProvider(programId)

CoachProgramFormScreen
  ├── watch: programDetailProvider(programId)  [edit mode only]
  ├── mutate: coachProgramsProvider.notifier.createProgram()
  └── mutate: coachProgramsProvider.notifier.updateProgram()

CoachRoutinesScreen
  ├── watch: coachRoutinesProvider
  ├── watch: coachRoutinesLoadingProvider
  ├── watch: coachRoutinesListProvider
  └── watch: coachRoutinesPaginationProvider

CoachRoutineDetailScreen
  └── watch: routineDetailProvider(routineId)

CoachRoutineFormScreen
  ├── watch: routineDetailProvider(routineId)  [edit mode only]
  ├── mutate: coachRoutinesProvider.notifier.createRoutine()
  └── mutate: coachRoutinesProvider.notifier.updateRoutine()

ClientAssignmentsScreen
  └── watch: clientAssignmentsProvider(userId)
```

---

## Relationship to Other Features

| Feature | Relationship |
|---------|-------------|
| **Workout** | Shares `ExerciseModel`, `RoutineExerciseModel`, `RoutineModel`, `MuscleGroup` |
| **Coach Pose** | Provides `exerciseListProvider` for exercise dropdown in `AddExerciseSheet` |
| **Subscription** | Coach features require active coach profile; client access to coach content may require subscription |
| **Profile** | Coach profile must exist before program creation |
| **Design System** | Uses `AppButton`, `AppCard`, `AppTextField`, `AppBadge`, `AppEmptyState`, `AppToast`, `showAppBottomSheet`, `showAppConfirmSheet`, `AppColors` |

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

*Last updated: February 24, 2026*
