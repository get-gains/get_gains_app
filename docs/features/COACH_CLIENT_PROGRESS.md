# Coach Client Progress Feature

> **Status**: ✅ Complete — Data Layer + Presentation Layer  
> **Last Updated**: March 1, 2026  
> **Covers**: Coach visibility into client workout sessions, weekly stats, exercise history, detailed performance report, and form analysis results

---

## Overview

### Purpose

The Coach Client Progress feature provides the mobile data layer for coaches to view detailed workout data, progress metrics, and form analysis results for their subscribed clients. This connects to the server-side Coach Client Progress endpoints (`GET /api/coach/clients/:userId/...`).

The feature integrates with the existing Coach Hub (`coach_programs`) where coaches manage clients and programs. Coaches can drill into any client's sessions, weekly stats, exercise trends, and form comparison results.

### What's Included

- **Freezed Models**: Immutable data classes for all 6 endpoint response shapes
- **Repository**: `CoachClientProgressRepository` with typed methods for every endpoint
- **Riverpod Providers**: Stateful notifiers with loading/loaded/error states + pagination
- **API Constants**: Endpoint path added to `ApiConstants`
- **Barrel Exports**: Full feature export chain
- **Screens**: 5 screens — Client Progress, Session Detail, Exercise History, Performance Dashboard, Form Review
- **Route Definitions**: 5 routes added to `router_provider.dart`
- **Coach Hub Integration**: Performance Dashboard tile in Coach Hub, "View Progress" in roster popup menu

### Dependencies

| Package               | Version | Purpose              |
| --------------------- | ------- | -------------------- |
| `freezed_annotation`  | ^3.1.0  | Immutable models     |
| `json_annotation`     | ^4.9.0  | JSON serialization   |
| `riverpod_annotation` | ^3.0.3  | Provider code-gen    |
| `dio`                 | ^5.9.0  | HTTP (via ApiClient) |

### Server Endpoints Consumed

| Endpoint                                               | Method | Repository Method            |
| ------------------------------------------------------ | ------ | ---------------------------- |
| `/coach/clients/:userId/sessions`                      | GET    | `getClientSessions()`        |
| `/coach/clients/:userId/sessions/:sessionId`           | GET    | `getClientSessionDetail()`   |
| `/coach/clients/:userId/stats/weekly`                  | GET    | `getClientWeeklyStats()`     |
| `/coach/clients/:userId/exercises/:exerciseId/history` | GET    | `getClientExerciseHistory()` |
| `/coach/performance/detailed`                          | GET    | `getDetailedPerformance()`   |
| `/coach/clients/:userId/form-results`                  | GET    | `getClientFormResults()`     |

See [Server COACH_CLIENT_PROGRESS.md](../../../../get-gains-server/docs/features/COACH_CLIENT_PROGRESS.md) for full endpoint contracts.

---

## Architecture

### Feature Structure

```
lib/features/coach_client_progress/
├── coach_client_progress.dart          # Feature barrel export
├── data/
│   ├── data.dart                       # Data barrel export
│   ├── coach_client_progress_repository.dart   # Repository + provider
│   ├── coach_client_progress_repository.g.dart # Generated
│   └── models/
│       ├── models.dart                 # Models barrel export
│       ├── client_session_model.dart   # Session summary + detail + sets
│       ├── weekly_stats_model.dart     # Weekly stats + delta
│       ├── exercise_history_model.dart # Exercise history + sets + summary
│       ├── detailed_performance_model.dart # Performance entry + summary
│       ├── form_result_model.dart      # Form result + corrections + exercise form
│       └── *.freezed.dart / *.g.dart   # Generated files
└── presentation/
    ├── presentation.dart               # Presentation barrel
    ├── providers/
    │   ├── client_progress_providers.dart   # All 6 notifiers
    │   └── client_progress_providers.g.dart # Generated
    └── screens/
        ├── screens.dart                     # Screens barrel export
        ├── client_progress_screen.dart      # Tabbed client detail (Overview / Sessions / Form Results)
        ├── session_detail_screen.dart       # Session with expandable exercise groups
        ├── exercise_history_screen.dart     # Exercise progress over time
        ├── performance_dashboard_screen.dart # All-client performance report
        └── form_review_screen.dart          # Form result detail with scores & corrections
```

### Data Flow

```
Coach Hub Screen
    │
    ▼  (tap client row)
CoachClientProgressRepository ← apiClientProvider
    │
    ├── getClientSessions(userId)          → ClientSessionsNotifier
    ├── getClientSessionDetail(userId, id) → ClientSessionDetailNotifier
    ├── getClientWeeklyStats(userId)       → ClientWeeklyStatsNotifier
    ├── getClientExerciseHistory(userId, exerciseId)
    │                                      → ClientExerciseHistoryNotifier
    ├── getDetailedPerformance()           → DetailedPerformanceNotifier
    └── getClientFormResults(userId)       → ClientFormResultsNotifier
```

### Authorization

All endpoints require `authenticateSupabaseUser` + `requireCoach` middleware on the server. The mobile app's `AuthInterceptor` automatically attaches the JWT token. The server verifies the coach–client relationship via `SubscribedCoach` before returning data.

---

## Data Models

### ClientSessionSummary

List-view summary of a workout session.

| Field               | Type        | Description                       |
| ------------------- | ----------- | --------------------------------- |
| `id`                | `String`    | Session CUID                      |
| `assignedProgramId` | `String?`   | Program CUID (null if standalone) |
| `programName`       | `String?`   | Program name                      |
| `startedAt`         | `DateTime`  | Session start time                |
| `completedAt`       | `DateTime?` | Session end (null if active)      |
| `durationMinutes`   | `int?`      | Duration in minutes               |
| `totalSets`         | `int`       | Number of sets performed          |
| `uniqueExercises`   | `int`       | Number of distinct exercises      |
| `notes`             | `String?`   | Session notes                     |

### ClientSessionDetail

Full session view with exercises grouped with their sets.

| Field             | Type                         | Description               |
| ----------------- | ---------------------------- | ------------------------- |
| `id`              | `String`                     | Session CUID              |
| `userId`          | `String`                     | Client CUID               |
| `exercises`       | `List<SessionExerciseGroup>` | Sets grouped by exercise  |
| `totalSets`       | `int`                        | Total sets                |
| `totalReps`       | `int`                        | Total reps                |
| `totalVolume`     | `double`                     | Sum of reps × weightKg    |
| `durationMinutes` | `int?`                       | Duration (null if active) |
| ...               |                              | Other session metadata    |

### ClientWeeklyStats

Weekly aggregates with previous-week deltas.

| Field                     | Type                | Description                 |
| ------------------------- | ------------------- | --------------------------- |
| `weekStart` / `weekEnd`   | `DateTime`          | Monday–Sunday UTC window    |
| `sessionsCompleted`       | `int`               | Sessions in the week        |
| `totalSets` / `totalReps` | `int`               | Aggregate counts            |
| `totalVolume`             | `double`            | Volume in kg                |
| `totalMinutes`            | `int`               | Total workout time          |
| `averageSessionDuration`  | `int`               | Average minutes per session |
| `delta`                   | `WeeklyStatsDelta?` | Change from previous week   |

### ClientExerciseHistoryResponse

Exercise progress over time (most-recent-first).

| Field      | Type                         | Description                       |
| ---------- | ---------------------------- | --------------------------------- |
| `exercise` | `ExerciseInfo`               | Exercise name + muscle group      |
| `history`  | `List<ExerciseHistoryEntry>` | Per-session sets + summary        |
| `total`    | `int`                        | Total sessions with this exercise |

### ClientPerformanceEntry

One client row in the detailed performance report.

| Field                   | Type      | Description                    |
| ----------------------- | --------- | ------------------------------ |
| `id` / `name` / `email` | `String`  | Client identity                |
| `status`                | `String`  | `'good'` or `'falling_behind'` |
| `sessionsThisWeek`      | `int`     | Sessions in last 7 days        |
| `totalVolume`           | `double`  | Volume in last 7 days          |
| `adherenceRate`         | `int?`    | % (null if no routine days)    |
| `activeProgramName`     | `String?` | Current program                |

### ClientFormResult

Form comparison result with segment scores and corrections.

| Field           | Type                      | Description               |
| --------------- | ------------------------- | ------------------------- |
| `id`            | `String`                  | Result CUID               |
| `overallScore`  | `double`                  | 0.0–1.0 similarity score  |
| `segmentScores` | `Map<String, dynamic>`    | Per-segment scores        |
| `corrections`   | `List<FormCorrection>`    | Textual correction items  |
| `exerciseForm`  | `FormResultExerciseForm?` | Exercise + coach metadata |

---

## Repository API

### CoachClientProgressRepository

```dart
// Singleton provider
final repo = ref.read(coachClientProgressRepositoryProvider);

// 1. Client sessions (paginated)
final sessions = await repo.getClientSessions(
  userId,
  limit: 20,
  offset: 0,
  status: 'completed',      // 'completed' | 'active' | 'all'
  startDate: DateTime(...),  // optional filter
  endDate: DateTime(...),    // optional filter
);

// 2. Session detail
final detail = await repo.getClientSessionDetail(userId, sessionId);

// 3. Weekly stats
final stats = await repo.getClientWeeklyStats(userId, weekOf: DateTime(...));

// 4. Exercise history
final history = await repo.getClientExerciseHistory(userId, exerciseId, limit: 20);

// 5. Detailed performance (all clients)
final performance = await repo.getDetailedPerformance(limit: 50, offset: 0);

// 6. Form results (paginated, optional exercise filter)
final forms = await repo.getClientFormResults(
  userId,
  exerciseId: exerciseId, // optional
  limit: 20,
  offset: 0,
);
```

All methods return `Result<T, AppError>`. Use `result.when(success: ..., failure: ...)`.

---

## Riverpod Providers

All providers are generated via `riverpod_annotation` and follow sealed-class state patterns.

| Provider                                | State Class                  | Description             |
| --------------------------------------- | ---------------------------- | ----------------------- |
| `clientSessionsNotifierProvider`        | `ClientSessionsState`        | Paginated session list  |
| `clientSessionDetailNotifierProvider`   | `ClientSessionDetailState`   | Single session view     |
| `clientWeeklyStatsNotifierProvider`     | `ClientWeeklyStatsState`     | Weekly stats + deltas   |
| `clientExerciseHistoryNotifierProvider` | `ClientExerciseHistoryState` | Exercise progress       |
| `detailedPerformanceNotifierProvider`   | `DetailedPerformanceState`   | All-client report       |
| `clientFormResultsNotifierProvider`     | `ClientFormResultsState`     | Form comparison results |

### State Pattern

Each notifier follows: `Initial → Loading → Loaded(data) | Error(AppError)`

```dart
// Usage example
final state = ref.watch(clientSessionsNotifierProvider);

switch (state) {
  case ClientSessionsInitial():
    // show placeholder
  case ClientSessionsLoading():
    // show spinner
  case ClientSessionsLoaded(:final sessions, :final pagination):
    // render list, check pagination.hasMore for load-more
  case ClientSessionsError(:final error):
    // show error with retry
}
```

### Pagination

`ClientSessionsNotifier`, `DetailedPerformanceNotifier`, and `ClientFormResultsNotifier` support `loadMore()` which appends to the existing list when `pagination.hasMore` is true.

---

## Integration Points

### Coach Hub Connection

The Coach Hub (`coach_hub_screen.dart`) has a **Performance** tile under "Client Management" that navigates to `AppRoutes.coachPerformanceDashboard`. From the performance dashboard, coaches can tap any client row to navigate to their detailed progress screen.

The coach roster (`coach_roster_screen.dart`) adds a **"View Progress"** option in each client's popup menu, navigating to `AppRoutes.clientProgress` with the client's userId and displayName.

```
coach_programs/coach_hub_screen.dart
    │  Performance tile
    ▼
coach_client_progress/presentation/screens/performance_dashboard_screen.dart
    │  (client row → tap)
    ▼
coach_client_progress/presentation/screens/client_progress_screen.dart
    │
    ├── Overview Tab → ClientWeeklyStatsNotifier.loadWeeklyStats(userId)
    ├── Sessions Tab → ClientSessionsNotifier.loadSessions(userId)
    │   └── Session card → tap → SessionDetailScreen
    │       └── Exercise group → trending_up icon → ExerciseHistoryScreen
    └── Form Results Tab → ClientFormResultsNotifier.loadFormResults(userId)
        └── Form result card → tap → FormReviewScreen
```

Also reachable from the coach roster:

```
coach_programs/coach_roster_screen.dart
    │  (client popup → "View Progress")
    ▼
coach_client_progress/presentation/screens/client_progress_screen.dart
```

### Reused Models

- `PaginationMeta` from `coach_programs/data/models/program_model.dart` is reused for all paginated responses.
- `ApiConstants.coachClients` (`/coach/clients`) is the base path for all client-scoped endpoints.

---

## Error Handling

All repository methods catch JSON parsing errors and wrap them in `UnknownError`. Network/auth errors pass through from `ApiClient` as-is.

| Scenario             | Error Type     | Handling                     |
| -------------------- | -------------- | ---------------------------- |
| Network failure      | `NetworkError` | Retry prompt in UI           |
| 401 Unauthorized     | `AuthError`    | Auto-refresh via interceptor |
| 403 Not a coach      | `AuthError`    | Redirect to home             |
| 404 Client not found | `NetworkError` | Show not-found message       |
| JSON parse failure   | `UnknownError` | Log + generic error          |

---

## Presentation Layer

### Screens

| Screen                         | Route                                                  | Description                                                                                                                           |
| ------------------------------ | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| **ClientProgressScreen**       | `/coach/clients/:userId/progress`                      | Tabbed view: Overview (weekly stats with deltas), Sessions (paginated list), Form Results (paginated list)                            |
| **SessionDetailScreen**        | `/coach/clients/:userId/sessions/:sessionId`           | Full session breakdown — header, summary stats (volume/sets/reps), expandable exercise groups with sets table                         |
| **ExerciseHistoryScreen**      | `/coach/clients/:userId/exercises/:exerciseId/history` | Exercise progress timeline — highlight stats (max weight, best volume), per-session history with expandable sets, volume trend badges |
| **PerformanceDashboardScreen** | `/coach/performance`                                   | All-client performance overview — summary cards, filterable list (All/Good/Falling Behind), tap to navigate to client progress        |
| **FormReviewScreen**           | `/coach/clients/:userId/form-results/:resultId`        | Full form result — score hero with grade label, segment score bars, correction cards, technical metadata                              |

### Routes

```dart
// Added to AppRoutes in router_provider.dart
static const String clientProgress = '/coach/clients/:userId/progress';
static const String clientSessionDetail = '/coach/clients/:userId/sessions/:sessionId';
static const String clientExerciseHistory = '/coach/clients/:userId/exercises/:exerciseId/history';
static const String clientFormReview = '/coach/clients/:userId/form-results/:resultId';
static const String coachPerformanceDashboard = '/coach/performance';
```

### Coach Hub Changes

- Added **Performance** tile in "Client Management" section navigating to `coachPerformanceDashboard`
- Added **"View Progress"** popup menu item in `_RosterClientCard` navigating to `clientProgress`

### Widget Patterns Used

All screens follow the established conventions:

- `ConsumerStatefulWidget` with `Future.microtask` data loading in `initState`
- Exhaustive `switch` on sealed state classes (Initial/Loading/Loaded/Error)
- `AppCard`, `AppStatsCard`, `AppBadge`, `AppAvatar`, `AppEmptyState`, `AppTabs` from shared widget library
- `RefreshIndicator` for pull-to-refresh
- Infinite scroll via sentinel item at list end triggering `loadMore()`
- Dark/light mode support via `AppColors` dark/light pairs
