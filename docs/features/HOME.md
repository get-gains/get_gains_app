# Home Feature Documentation

> **Created**: February 18, 2026
> **Status**: Implemented (static/placeholder data)

---

## Overview

The Home feature is the main dashboard screen displayed after successful authentication. It provides a contextual greeting, quick-access actions, a snapshot of today's scheduled workout, weekly progress stats, and recent activity. It also conditionally renders Coach Tools for users with the `isCoach` flag.

---

## Acceptance Criteria

| Criteria | Status |
|----------|--------|
| Authenticated users land on Home after login | ✅ |
| Dynamic greeting (morning / afternoon / evening) | ✅ |
| Username derived from email prefix | ✅ |
| Quick Actions: Start Workout, History | ✅ |
| Coach Tools quick action visible only to coaches | ✅ |
| Today's Focus section with placeholder routine card | ✅ |
| Weekly Progress card with goal progress bar and stats | ✅ |
| Recent Activity empty state | ✅ |
| Pull-to-refresh invalidates coach status check | ✅ |
| Bottom navigation bar (Home, Workouts, Progress, Profile) | ✅ |

---

## Folder Structure

```
lib/features/home/
├── home.dart                              # Feature barrel export
└── presentation/
    ├── presentation.dart                  # Presentation barrel export
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

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateProvider` | `AuthState` | Reads email for username + auth guard |
| `isCoachProvider` | `FutureProvider<bool>` | Conditional Coach Tools visibility |

**`isCoachProvider`** — `FutureProvider.autoDispose<bool>` defined at the top of the file. Calls `GET /auth/me` and reads `data['isCoach']` or `user['isCoach']`. Returns `false` on any failure or unauthenticated state.

**Layout sections (top → bottom):**

| Section | Widget | Notes |
|---------|--------|-------|
| App Bar | `SliverAppBar` (floating) | Greeting text + username, notifications icon (TODO), profile avatar sheet |
| Quick Actions | `QuickActionCard` × 2 (+ optional Coach Tools) | Start Workout → `/routines`, History → TODO, Coach Tools → `/coach/exercises` |
| Today's Focus | `WorkoutSummaryCard` (placeholder) | Static placeholder; "See All" navigates to `/routines` |
| This Week | `WeeklyProgressCard` | Static zeros; will be driven by real data in future |
| Recent Activity | `AppEmptyState.compact` | Placeholder until workout history is implemented |
| Bottom Nav | `_BottomNavBar` | 4 tabs: Home (0), Workouts (1), Progress (2 — TODO), Profile (3) |

**Greeting logic (`_getGreeting`):**

| Hour range | Greeting |
|------------|----------|
| 00:00–11:59 | Good Morning |
| 12:00–16:59 | Good Afternoon |
| 17:00–23:59 | Good Evening |

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

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `icon` | `IconData` | ✅ | Leading icon |
| `title` | `String` | ✅ | Bold card title |
| `subtitle` | `String` | ✅ | Secondary description |
| `gradient` | `Gradient` | ✅ | Background gradient |
| `onTap` | `VoidCallback` | ✅ | Tap handler |

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

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `routineName` | `String` | ✅ | — | Routine title |
| `description` | `String` | ✅ | — | Short description |
| `exerciseCount` | `int` | ✅ | — | Number of exercises |
| `estimatedMinutes` | `int` | ✅ | — | Duration estimate |
| `isPlaceholder` | `bool` | ❌ | `false` | Renders placeholder state (hourglass icon, hides stats) |
| `muscleGroups` | `List<String>` | ❌ | `[]` | Muscle group chip list |
| `onStartPressed` | `VoidCallback?` | ❌ | `null` | Start button action |

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

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `workoutsCompleted` | `int` | ✅ | Workouts done this week |
| `workoutsGoal` | `int` | ✅ | Target workouts for the week |
| `totalMinutes` | `int` | ✅ | Cumulative minutes trained |
| `streakDays` | `int` | ✅ | Current consecutive-day streak |

Progress bar value = `workoutsCompleted / workoutsGoal` (clamped 0.0–1.0). Renders three stat items: Day Streak, Total Minutes, Workouts Done.

---

## Private Widgets (file-local)

| Widget | Description |
|--------|-------------|
| `_SectionHeader` | Row with bold title and optional trailing action widget |
| `_BottomNavBar` | Custom bottom navigation bar wrapping four `_NavItem`s |
| `_NavItem` | Single nav tab with active/inactive icon and label |

---

## Navigation

| Action | Destination |
|--------|-------------|
| Start Workout quick action | `AppRoutes.routines` |
| Coach Tools quick action | `AppRoutes.coachExercises` |
| Today's Focus "See All" | `AppRoutes.routines` |
| Bottom Nav index 1 (Workouts) | `AppRoutes.routines` |
| Bottom Nav index 2 (Progress) | TODO |
| Bottom Nav index 3 (Profile) | `AppRoutes.profile` |
| Profile avatar tap | `showProfileSheet(context)` (bottom sheet) |
| Notifications icon | TODO |

---

## Known TODOs

| Location | TODO |
|----------|------|
| `home_screen.dart` | Notifications tap handler |
| `home_screen.dart` | History quick action destination |
| `home_screen.dart` | Progress/Stats screen (bottom nav index 2) |
| `home_screen.dart` | `_onRefresh` — refresh all dashboard data from server |
| `WorkoutSummaryCard` | Connect to real assigned routine from workout repository |
| `WeeklyProgressCard` | Connect to real progress data from workout history |
| Recent Activity section | Implement with actual workout history list |

---

*Last updated: February 18, 2026*
