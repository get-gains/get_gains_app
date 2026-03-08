# Home Feature Documentation

> **Created**: February 18, 2026
> **Updated**: March 9, 2026 — `completedToday` flag on WorkoutSummaryCard
> **Status**: Data layer complete; presentation wiring next

---

## Overview

The Home feature is the main dashboard screen displayed after successful authentication. It provides a contextual greeting, quick-access actions, a snapshot of today's scheduled workout, weekly progress stats, and recent activity. It also conditionally renders Coach Tools for users with the `isCoach` flag.

---

## Acceptance Criteria

| Criteria                                                  | Status        |
| --------------------------------------------------------- | ------------- |
| Authenticated users land on Home after login              | ✅            |
| Dynamic greeting (morning / afternoon / evening)          | ✅            |
| Username derived from email prefix                        | ✅            |
| Quick Actions: Start Workout, History                     | ✅            |
| Coach Tools quick action visible only to coaches          | ✅            |
| Today's Focus section with real routine from server       | ✅ Data layer |
| Weekly Progress card with real stats from server          | ✅ Data layer |
| Recent Activity from workout history                      | ✅ Data layer |
| Home status (no coach / waiting / rest day / has routine) | ✅ Data layer |
| Pull-to-refresh invalidates coach status check            | ✅            |
| Bottom navigation bar (Home, Workouts, Progress, Profile) | ✅            |

---

## Folder Structure

```
lib/features/home/
├── home.dart                              # Feature barrel export
└── presentation/
    ├── presentation.dart                  # Presentation barrel export
    ├── providers/
    │   ├── providers.dart                 # Providers barrel export
    │   └── home_providers.dart            # All home data providers
    ├── screens/
    │   └── home_screen.dart               # Main dashboard screen
    └── widgets/
        ├── widgets.dart                   # Widgets barrel export
        ├── quick_action_card.dart         # Gradient tappable action card
        ├── weekly_progress_card.dart      # Weekly goal + stats card
        └── workout_summary_card.dart      # Today's Focus routine card
```

---

## Screens

### `HomeScreen` (`home_screen.dart`)

`ConsumerStatefulWidget` — the root dashboard screen.

**Providers consumed:**

| Provider                     | Type                                          | Purpose                                                                      |
| ---------------------------- | --------------------------------------------- | ---------------------------------------------------------------------------- |
| `authStateProvider`          | `AuthState`                                   | Reads email for username + auth guard                                        |
| `isCoachProvider`            | `FutureProvider<bool>`                        | Conditional Coach Tools visibility                                           |
| `todayRoutineProvider`       | `FutureProvider<TodayRoutineModel>`           | Today's scheduled routine from server                                        |
| `weeklyStatsProvider`        | `FutureProvider<WeeklyStatsModel>`            | Aggregated weekly workout statistics                                         |
| `recentActivityProvider`     | `FutureProvider<List<WorkoutSessionSummary>>` | Last 5 completed sessions                                                    |
| `homeStatusProvider`         | `FutureProvider<HomeStatus>`                  | Composite status: `noCoach` / `waitingForProgram` / `restDay` / `hasRoutine` |
| `hasSubscribedCoachProvider` | `FutureProvider<bool>`                        | Whether user has at least one subscribed coach                               |

**`isCoachProvider`** — `FutureProvider.autoDispose<bool>` defined at the top of the file. Calls `GET /auth/me` and reads `data['isCoach']` or `user['isCoach']`. Returns `false` on any failure or unauthenticated state.

**Layout sections (top → bottom):**

| Section         | Widget                                         | Notes                                                                         |
| --------------- | ---------------------------------------------- | ----------------------------------------------------------------------------- |
| App Bar         | `SliverAppBar` (floating)                      | Greeting text + username, notifications icon (TODO), profile avatar sheet     |
| Quick Actions   | `QuickActionCard` × 2 (+ optional Coach Tools) | Start Workout → `/routines`, History → TODO, Coach Tools → `/coach/exercises` |
| Today's Focus   | `WorkoutSummaryCard` (placeholder)             | Static placeholder; "See All" navigates to `/routines`                        |
| This Week       | `WeeklyProgressCard`                           | Static zeros; will be driven by real data in future                           |
| Recent Activity | `AppEmptyState.compact`                        | Placeholder until workout history is implemented                              |
| Bottom Nav      | `_BottomNavBar`                                | 4 tabs: Home (0), Workouts (1), Progress (2 — TODO), Profile (3)              |

**Greeting logic (`_getGreeting`):**

| Hour range  | Greeting       |
| ----------- | -------------- |
| 00:00–11:59 | Good Morning   |
| 12:00–16:59 | Good Afternoon |
| 17:00–23:59 | Good Evening   |

**Pull-to-refresh (`_onRefresh`):** Invalidates `isCoachProvider` and waits 1 second (placeholder; TODO: refresh all dashboard data).

---

## Widgets

### `QuickActionCard`

A gradient card for home screen quick actions.

```dart
QuickActionCard(
  icon: Icons.fitness_center,
  title: 'Start Workout',
  subtitle: 'Begin your training',
  gradient: LinearGradient(...),
  onTap: () => context.push(AppRoutes.routines),
)
```

| Property   | Type           | Required | Description           |
| ---------- | -------------- | -------- | --------------------- |
| `icon`     | `IconData`     | ✅       | Leading icon          |
| `title`    | `String`       | ✅       | Bold card title       |
| `subtitle` | `String`       | ✅       | Secondary description |
| `gradient` | `Gradient`     | ✅       | Background gradient   |
| `onTap`    | `VoidCallback` | ✅       | Tap handler           |

Renders as a full-width tappable `InkWell` with 16 px border radius and a soft drop shadow.

---

### `WorkoutSummaryCard`

Displays the assigned routine for today, or a placeholder if none is assigned.

```dart
WorkoutSummaryCard(
  routineName: 'Push Day A',
  description: 'Chest, shoulders, triceps',
  exerciseCount: 6,
  estimatedMinutes: 45,
  isPlaceholder: false,
  muscleGroups: ['Chest', 'Shoulders'],
  onStartPressed: () => ...,
)
```

| Property           | Type            | Required | Default | Description                                                          |
| ------------------ | --------------- | -------- | ------- | -------------------------------------------------------------------- |
| `routineName`      | `String`        | ✅       | —       | Routine title                                                        |
| `description`      | `String`        | ✅       | —       | Short description                                                    |
| `exerciseCount`    | `int`           | ✅       | —       | Number of exercises                                                  |
| `estimatedMinutes` | `int`           | ✅       | —       | Duration estimate                                                    |
| `isPlaceholder`    | `bool`          | ❌       | `false` | Renders placeholder state (hourglass icon, hides stats)              |
| `completedToday`   | `bool`          | ❌       | `false` | When true, shows "Workout Done Today ✓" disabled button instead of Start |
| `muscleGroups`     | `List<String>`  | ❌       | `[]`    | Muscle group chip list                                               |
| `onStartPressed`   | `VoidCallback?` | ❌       | `null`  | Start button action                                                  |

---

### `WeeklyProgressCard`

Displays weekly workout goal progress, day streak, and total training minutes.

```dart
WeeklyProgressCard(
  workoutsCompleted: 3,
  workoutsGoal: 4,
  totalMinutes: 135,
  streakDays: 5,
)
```

| Property            | Type  | Required | Description                    |
| ------------------- | ----- | -------- | ------------------------------ |
| `workoutsCompleted` | `int` | ✅       | Workouts done this week        |
| `workoutsGoal`      | `int` | ✅       | Target workouts for the week   |
| `totalMinutes`      | `int` | ✅       | Cumulative minutes trained     |
| `streakDays`        | `int` | ✅       | Current consecutive-day streak |

Progress bar value = `workoutsCompleted / workoutsGoal` (clamped 0.0–1.0). Renders three stat items: Day Streak, Total Minutes, Workouts Done.

---

## Private Widgets (file-local)

| Widget           | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `_SectionHeader` | Row with bold title and optional trailing action widget |
| `_BottomNavBar`  | Custom bottom navigation bar wrapping four `_NavItem`s  |
| `_NavItem`       | Single nav tab with active/inactive icon and label      |

---

## Navigation

| Action                        | Destination                                |
| ----------------------------- | ------------------------------------------ |
| Start Workout quick action    | `AppRoutes.routines`                       |
| Coach Tools quick action      | `AppRoutes.coachExercises`                 |
| Today's Focus "See All"       | `AppRoutes.routines`                       |
| Bottom Nav index 1 (Workouts) | `AppRoutes.routines`                       |
| Bottom Nav index 2 (Progress) | TODO                                       |
| Bottom Nav index 3 (Profile)  | `AppRoutes.profile`                        |
| Profile avatar tap            | `showProfileSheet(context)` (bottom sheet) |
| Notifications icon            | TODO                                       |

---

## Home Data Providers (`home_providers.dart`)

All providers are auto-dispose and re-fetch on watch/invalidation.

| Provider                           | Return Type                   | Source                                         | Purpose                                        |
| ---------------------------------- | ----------------------------- | ---------------------------------------------- | ---------------------------------------------- |
| `todayRoutineProvider`             | `TodayRoutineModel`           | `GET /api/workout/today`                       | Today's scheduled routine with program context |
| `weeklyStatsProvider`              | `WeeklyStatsModel`            | `GET /api/workout/stats/weekly`                | Workouts completed, total minutes, streak      |
| `recentActivityProvider`           | `List<WorkoutSessionSummary>` | `GET /api/workout/sessions?limit=5`            | Recent completed sessions for history section  |
| `hasSubscribedCoachProvider`       | `bool`                        | `GET /api/user/coaches/subscribed?limit=1`     | Whether user has any subscribed coach          |
| `subscribedCoachesSummaryProvider` | `List<CoachSummaryModel>`     | `GET /api/user/coaches/subscribed?limit=10`    | Coach names/avatars for display                |
| `homeStatusProvider`               | `HomeStatus`                  | Combines `hasSubscribedCoach` + `todayRoutine` | Determines which home-screen section to show   |

### `HomeStatus` Enum

| Value               | Condition                         | UI Action                              |
| ------------------- | --------------------------------- | -------------------------------------- |
| `noCoach`           | No subscribed coach               | Show "Find a Coach" CTA                |
| `waitingForProgram` | Has coach, no active program      | Show "Waiting for program" message     |
| `restDay`           | Active program, today is rest day | Show rest-day card                     |
| `hasRoutine`        | Active program, routine scheduled | Show routine card with "Start Workout" |

---

## Known TODOs

| Location           | TODO                                                                       |
| ------------------ | -------------------------------------------------------------------------- |
| `home_screen.dart` | Wire `todayRoutineProvider` to replace hardcoded `WorkoutSummaryCard`      |
| `home_screen.dart` | Wire `weeklyStatsProvider` to replace hardcoded `WeeklyProgressCard` zeros |
| `home_screen.dart` | Wire `recentActivityProvider` to replace empty Recent Activity             |
| `home_screen.dart` | Wire `homeStatusProvider` to show coach discovery CTA / waiting / routine  |
| `home_screen.dart` | Add "Clients" quick action for coaches → `/coach/roster`                   |
| `home_screen.dart` | Change "Coach Tools" to navigate to coach hub instead of just exercises    |
| `home_screen.dart` | Wire notifications tap handler                                             |
| `home_screen.dart` | Wire History quick action → `/workout-history`                             |
| `home_screen.dart` | Progress/Stats screen (bottom nav index 2)                                 |
| `home_screen.dart` | `_onRefresh` — invalidate all home providers                               |
| `home_screen.dart` | Integrate `UpgradePrompt` for subscription guards                          |

---

_Last updated: February 25, 2026_
