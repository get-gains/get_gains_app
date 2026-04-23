# Get Gains App - Feature Index

> **Purpose**: Central navigation hub for all Flutter app features and documentation.

---

## Overview

**Get Gains App** is a Flutter mobile application for fitness tracking with offline-first architecture. It syncs with the Get Gains Server backend.

### Technology Stack

| Technology                 | Version | Purpose                  |
| -------------------------- | ------- | ------------------------ |
| **Flutter**                | 3.x     | UI framework             |
| **Dart SDK**               | ^3.9.0  | Programming language     |
| **Riverpod**               | ^3.0.3  | State management         |
| **Drift**                  | ^2.29.0 | Local SQLite database    |
| **Dio**                    | ^5.9.0  | HTTP client              |
| **go_router**              | ^17.0.1 | Navigation               |
| **flutter_secure_storage** | ^10.0.0 | Secure token storage     |
| **google_sign_in**         | ^6.2.2  | Google OAuth             |
| **hive**                   | ^2.2.3  | User preferences (NoSQL) |
| **hive_flutter**           | ^1.1.0  | Flutter Hive integration |

### Architecture Approach

- **Simplified Clean Architecture** with feature-based organization
- **Riverpod** for dependency injection and state management
- **Offline-first** with local database and sync queue
- **Repository pattern** for data access abstraction

---

## Documentation Structure

| Document                                                                                   | Purpose                                                               |
| ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- |
| [CONTEXT.md](CONTEXT.md)                                                                   | Core infrastructure, patterns, conventions                            |
| [FEATURE_INDEX.md](FEATURE_INDEX.md)                                                       | This file - navigation hub                                            |
| [features/AUTH_PRESENTATION.md](features/AUTH_PRESENTATION.md)                             | Auth screens (login, register, complete-profile)                      |
| [features/REGISTER.md](features/REGISTER.md)                                               | Registration data layer & flows                                       |
| [features/VERIFY_RESET_FLOW.md](features/VERIFY_RESET_FLOW.md)                             | Email verification & password reset deep-link flows                   |
| [features/HOME.md](features/HOME.md)                                                       | Home dashboard screen & widgets                                       |
| [features/PROFILE.md](features/PROFILE.md)                                                 | Profile viewing and management documentation                          |
| [features/PROGRAM.md](features/PROGRAM.md)                                                 | Coach programs, routines, exercises, assignments                      |
| [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md)                           | Standalone workout — exercises, routines, programs, sessions          |
| [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)                                 | Workout session flow, set logging, record-first workflow              |
| [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md)                       | Coach exercise list, create exercise, record reference form           |
| [features/CLIENT_POSE.md](features/CLIENT_POSE.md)                                         | Client form recording, DTW comparison, offline cache                  |
| [features/POSE_DETECTION.md](features/POSE_DETECTION.md)                                   | Pose detection pipeline (MLKit, landmarks, DTW)                       |
| [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md)                     | Coach discovery, settings & missing links data layer                  |
| [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md)                       | Coaches & Subscription presentation layer (screens, routes)           |
| [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md)                     | Coach client progress — sessions, stats, forms, presentation          |
| [features/SUBSCRIPTION.md](features/SUBSCRIPTION.md)                                       | In-app purchases, subscription management, access control             |
| [features/SUBSCRIPTION_DEFINITIONS.md](features/SUBSCRIPTION_DEFINITIONS.md)               | Subscription-aware stats, session history, upgrade prompts, UI gating |
| [features/GAINS_COINS.md](features/GAINS_COINS.md)                                         | Gains Coins economy, cosmetics shop, inventory, leaderboard           |
| [features/GUIDANCE.md](features/GUIDANCE.md)                                               | In-app spotlight tours, contextual help, onboarding                   |

---

## Feature Categories

### Core Infrastructure _(Documented in [CONTEXT.md](CONTEXT.md))_

| Topic              | Description               | CONTEXT.md Section          |
| ------------------ | ------------------------- | --------------------------- |
| Project Structure  | Folder organization       | Architecture Overview       |
| Riverpod Providers | State management patterns | Key Implementation Patterns |
| Freezed Models     | Immutable data models     | Creating Models             |
| API Client         | Dio HTTP client           | Making API Calls            |
| Result Type        | Error handling            | Using Result Type           |
| Drift Database     | Local SQLite              | Database Operations         |
| Secure Storage     | JWT token management      | Secure Storage              |
| Navigation         | go_router setup           | Navigation                  |

### Home Dashboard

| Feature                | Description                                              | Status      | Documentation                        |
| ---------------------- | -------------------------------------------------------- | ----------- | ------------------------------------ |
| Home Screen            | Dashboard with greeting, quick actions, weekly progress  | ✅ Complete | [features/HOME.md](features/HOME.md) |
| Quick Actions          | Start Workout, History, Coach Tools, Clients (coach)     | ✅ Complete | [features/HOME.md](features/HOME.md) |
| Today's Focus          | Dynamic routine from `GET /workout/today`                | ✅ Complete | [features/HOME.md](features/HOME.md) |
| Weekly Progress        | Dynamic stats from `GET /workout/stats/weekly`           | ✅ Complete | [features/HOME.md](features/HOME.md) |
| Recent Activity        | Dynamic workout history from `GET /workout/sessions`     | ✅ Complete | [features/HOME.md](features/HOME.md) |
| Home Status            | Composite provider (no coach / waiting / rest / routine) | ✅ Complete | [features/HOME.md](features/HOME.md) |
| Subscribed Coach Check | CTA: Find Coach / Waiting for Program                    | ✅ Complete | [features/HOME.md](features/HOME.md) |
| Bottom Navigation      | Home, Workouts, Progress, Profile tabs                   | ✅ Complete | [features/HOME.md](features/HOME.md) |

**Primary Files:**

- `/lib/features/home/home.dart` - Feature barrel export
- `/lib/features/home/presentation/providers/home_providers.dart` - All home data providers
- `/lib/features/home/presentation/screens/home_screen.dart` - Main dashboard
- `/lib/features/home/presentation/widgets/quick_action_card.dart` - Quick action card
- `/lib/features/home/presentation/widgets/workout_summary_card.dart` - Today's routine card
- `/lib/features/home/presentation/widgets/weekly_progress_card.dart` - Weekly stats card

### Authentication & User Management

| Feature              | Description                                               | Status      | Documentation                                                    |
| -------------------- | --------------------------------------------------------- | ----------- | ---------------------------------------------------------------- |
| Registration         | Email/password + Google sign-up                           | ✅ Complete | [features/REGISTER.md](features/REGISTER.md)                     |
| Login                | Email/password + Google login screens                     | ✅ Complete | [features/AUTH_PRESENTATION.md](features/AUTH_PRESENTATION.md)   |
| Password Reset       | Forgot password → email → deep link → reset form          | ✅ Complete | [features/VERIFY_RESET_FLOW.md](features/VERIFY_RESET_FLOW.md)   |
| Email Verification   | Check email screen + verified deep-link screen            | ✅ Complete | [features/VERIFY_RESET_FLOW.md](features/VERIFY_RESET_FLOW.md)   |
| Profile Management   | View profile, stats, achievements, sign out               | ✅ Complete | [features/PROFILE.md](features/PROFILE.md)                       |
| Profile Data Layer   | Fitness profile CRUD, avatar upload, offline cache        | ✅ Complete | [features/PROFILE.md](features/PROFILE.md)                       |
| Profile Editing UI   | Edit avatar, bio, body metrics, training prefs, equipment | ✅ Complete | [features/PROFILE.md](features/PROFILE.md)                       |
| Connectivity Service | Network status monitoring for offline-first               | ✅ Complete | [features/PROFILE.md](features/PROFILE.md)                       |

**Primary Files:**

- `/lib/features/auth/auth.dart` - Feature barrel export
- `/lib/features/auth/data/auth_repository.dart` - Auth data operations
- `/lib/features/auth/services/google_sign_in_service.dart` - Google OAuth
- `/lib/features/auth/services/user_preferences_service.dart` - User caching + raw cache helpers
- `/lib/features/auth/presentation/providers/register_provider.dart` - Registration state
- `/lib/providers/auth_state_provider.dart` - App-wide auth state
- `/lib/providers/router_provider.dart` - Route guards
- `/lib/providers/deep_link_provider.dart` - Incoming deep link handling
- `/lib/features/profile/profile.dart` - Profile feature export
- `/lib/features/profile/data/user_profile_repository.dart` - Fitness profile CRUD + multipart upload + caching
- `/lib/features/profile/presentation/providers/profile_provider.dart` - Account-level profile fetching
- `/lib/features/profile/presentation/screens/profile_screen.dart` - Profile display UI (offline-ready)
- `/lib/features/profile/presentation/screens/edit_profile_screen.dart` - Edit profile form
- `/lib/services/connectivity/connectivity_service.dart` - Connectivity monitoring + isOnlineProvider

### Workout Session

| Feature              | Description                                                          | Status      | Documentation                                                |
| -------------------- | -------------------------------------------------------------------- | ----------- | ------------------------------------------------------------ |
| Routine List         | Browse assigned routines                                             | ✅ Complete | [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)   |
| Workout Session      | Start session, navigate exercises, log sets, complete               | ✅ Complete | [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)   |
| Record-First Flow    | Record form → compare → log set → next exercise                     | ✅ Complete | [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)   |
| Set Logging          | Auto-detected reps + weight input with +/- controls                 | ✅ Complete | [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)   |
| Workout History      | Paginated completed session list                                     | ✅ Complete | [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)   |
| Progress / Stats     | Weekly stats, summary grid, recent workouts                         | ✅ Complete | [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)   |
| Workout Sync         | Auto-sync sessions/sets on connectivity restore                     | ✅ Complete | [features/WORKOUT_FEATURE.md](features/WORKOUT_FEATURE.md)   |

**Primary Files:**

- `/lib/features/workout/data/workout_repository.dart` - All workout API methods + offline-first patterns
- `/lib/features/workout/presentation/providers/workout_session_provider.dart` - Manages workout session state
- `/lib/features/workout/presentation/providers/exercise_log_provider.dart` - Per-exercise set logging
- `/lib/features/workout/presentation/screens/routine_list_screen.dart` - Available routines
- `/lib/features/workout/presentation/screens/workout_session_screen.dart` - Active workout UI
- `/lib/services/sync/workout_sync_service.dart` - Dedicated workout sync

### Client Pose & Form Comparison

| Feature                 | Description                                                          | Status      | Documentation                                      |
| ----------------------- | -------------------------------------------------------------------- | ----------- | -------------------------------------------------- |
| View Reference Form     | Animated 2D skeleton playback of coach's form                        | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Unity 3D Recording      | Record + compare with 3D Unity avatar skeleton                       | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| 2D Recording (legacy)   | Camera + 2D skeleton recording + compare                             | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Capture-only recording  | Raw frame capture during recording; no live MLKit or rep counter     | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Post-processing loading | Full-screen overlay with percentage and step message                 | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| DTW Comparison          | On-device similarity scoring; torso alignment, temporal best-offset  | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Score + Corrections     | Result display with segment breakdown                                | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Offline Form Cache      | Forms cached in Drift; proactively pre-cached on workout start       | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Offline Result Queue    | Results queued in SyncQueue when offline; synced on reconnect        | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Offline History Cache   | First-page history cached in CachedApiResponses for offline browsing | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |

**Primary Files:**

- `/lib/features/client_pose/client_pose.dart` - Feature barrel export
- `/lib/features/client_pose/data/client_pose_repository.dart` - API: download form, submit result
- `/lib/features/client_pose/presentation/providers/client_recording_provider.dart` - State machine
- `/lib/features/client_pose/presentation/screens/client_unity_recording_screen.dart` - 3D Unity screen
- `/lib/features/client_pose/presentation/screens/view_form_screen.dart` - Reference form viewer
- `/lib/features/client_pose/presentation/screens/client_recording_screen.dart` - Legacy 2D screen

### Coach Pose Recording _(Documented in [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md))_

| Feature                | Description                                                    | Status         | Documentation                                                          |
| ---------------------- | -------------------------------------------------------------- | -------------- | ---------------------------------------------------------------------- |
| Exercise Library       | Browse/search/filter coach exercises                           | ✅ Complete    | [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md)  |
| Create Exercise        | Add new exercises with muscles & equipment                     | ✅ Complete    | [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md)  |
| Record Reference Form  | Camera + MLKit to capture pose landmarks                       | ✅ Complete    | [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md)  |
| Exercise Detail        | View exercise info, active forms, form history                 | ✅ Complete    | [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md)  |
| View / 3D Preview Form | Coach can review recorded reference forms in 2D and 3D        | ✅ Complete    | [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md)  |

**Primary Files:**

- `/lib/features/coach_pose/coach_pose.dart` - Feature barrel export
- `/lib/features/coach_pose/data/` - Models, repository
- `/lib/features/coach_pose/presentation/` - Screens, providers, services

### Coach Programs _(Documented in [features/PROGRAM.md](features/PROGRAM.md))_

| Feature                   | Description                                    | Status      | Documentation                                                          |
| ------------------------- | ---------------------------------------------- | ----------- | ---------------------------------------------------------------------- |
| Programs CRUD             | Create, list, update, delete programs          | ✅ Complete | [features/PROGRAM.md](features/PROGRAM.md)                             |
| Routines CRUD             | Create, list, update, delete routines          | ✅ Complete | [features/PROGRAM.md](features/PROGRAM.md)                             |
| ProgramRoutine Junctions  | Assign/reorder/remove routines in programs     | ✅ Complete | [features/PROGRAM.md](features/PROGRAM.md)                             |
| RoutineExercise Junctions | Add/update/remove exercises in routines        | ✅ Complete | [features/PROGRAM.md](features/PROGRAM.md)                             |
| Program Assignments       | Assign programs to clients, manage assignments | ✅ Complete | [features/PROGRAM.md](features/PROGRAM.md)                             |
| Class Roster              | Coach roster with client subscription expiry   | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md)   |
| Client List               | Full client list with assignments + expiry     | ✅ Complete | [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md) |

**Primary Files:**

- `/lib/features/coach_programs/coach_programs.dart` - Feature barrel export
- `/lib/features/coach_programs/data/coach_program_repository.dart` - All API calls
- `/lib/features/coach_programs/presentation/providers/coach_program_provider.dart` - Programs list + detail
- `/lib/features/coach_programs/presentation/providers/coach_routine_provider.dart` - Routines list + detail
- `/lib/features/coach_programs/presentation/providers/coach_assignment_provider.dart` - Client assignments
- `/lib/features/coach_programs/presentation/providers/coach_roster_provider.dart` - Class roster

### Coach Discovery & Subscription _(Documented in [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md))_

| Feature               | Description                           | Status      | Documentation                                                        |
| --------------------- | ------------------------------------- | ----------- | -------------------------------------------------------------------- |
| Coach Discovery       | Browse/search public coaches          | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |
| Coach Profile         | Single coach detail with social links | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |
| Subscribed Coaches    | List user's subscribed coaches        | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |
| Subscribe/Unsubscribe | Coach subscription management         | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |

**Primary Files:**

- `/lib/features/coaches/coaches.dart` - Feature barrel export
- `/lib/features/coaches/data/coach_repository.dart` - Discovery, profile, subscribe API calls
- `/lib/features/coaches/presentation/screens/coach_discovery_screen.dart` - Browse/search screen
- `/lib/features/coaches/presentation/screens/coach_profile_screen.dart` - Full profile screen
- `/lib/features/coaches/presentation/screens/subscribed_coaches_screen.dart` - My coaches screen

### Coach Settings _(Documented in [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md))_

| Feature              | Description                                    | Status      | Documentation                                                        |
| -------------------- | ---------------------------------------------- | ----------- | -------------------------------------------------------------------- |
| Coach Settings CRUD  | Max clients, accepting toggle, discoverability | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |

**Primary Files:**

- `/lib/features/coach_settings/data/coach_settings_repository.dart` - GET/PATCH settings
- `/lib/features/coach_settings/presentation/screens/coach_settings_screen.dart` - Settings UI

### Coach Client Progress _(Documented in [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md))_

| Feature                     | Description                                                 | Status      | Documentation                                                          |
| --------------------------- | ----------------------------------------------------------- | ----------- | ---------------------------------------------------------------------- |
| Client Session List         | Paginated list of client workout sessions                   | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Session Detail       | Full session with exercises + sets grouped                  | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Weekly Stats         | Weekly aggregates with previous-week deltas                 | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Exercise History     | Per-exercise progress over time (best set, volume)          | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Detailed Performance Report | All-clients report with volume, adherence, session duration | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Form Results         | Form comparison history with segment scores and corrections | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |

**Primary Files:**

- `/lib/features/coach_client_progress/coach_client_progress.dart` - Feature barrel export
- `/lib/features/coach_client_progress/data/coach_client_progress_repository.dart` - All 6 API calls
- `/lib/features/coach_client_progress/presentation/providers/client_progress_providers.dart` - All 6 notifiers
- `/lib/features/coach_client_progress/presentation/screens/client_progress_screen.dart` - Tabbed client detail
- `/lib/features/coach_client_progress/presentation/screens/performance_dashboard_screen.dart` - All-client report

### Standalone Workout _(Documented in [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md))_

| Feature            | Description                                                     | Status        | Documentation                                                    |
| ------------------ | --------------------------------------------------------------- | ------------- | ---------------------------------------------------------------- |
| Exercise CRUD      | Create/update/delete personal exercises + browse public library | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Routine CRUD       | Build custom routines from any exercises                        | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Program CRUD       | Organise routines into a day-cycling program                    | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Self-assignment    | Activate / deactivate a standalone program                      | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Today's Routine    | Server day-cycling resolution (`GET /standalone/today`)         | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Session Lifecycle  | Start / complete sessions, view history                         | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Weekly Stats       | Aggregated weekly stats (`GET /standalone/stats/weekly`)        | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Presentation Layer | Screens, providers, routes for all standalone flows             | ✅ Complete   | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |

**Primary Files:**

- `/lib/features/standalone_workout/standalone_workout.dart` - Feature barrel export
- `/lib/features/standalone_workout/data/standalone_workout_repository.dart` - Offline-first repository
- `/lib/features/standalone_workout/data/models/` - Exercise, routine, program, session models

### Subscription _(Documented in [features/SUBSCRIPTION.md](features/SUBSCRIPTION.md))_

| Feature                    | Description                                          | Status      | Documentation                                                          |
| -------------------------- | ---------------------------------------------------- | ----------- | ---------------------------------------------------------------------- |
| In-App Purchase            | Google Play integration via `in_app_purchase`        | ✅ Complete | [features/SUBSCRIPTION.md](features/SUBSCRIPTION.md)                  |
| Subscription State         | Watch subscription tier, status, expiry              | ✅ Complete | [features/SUBSCRIPTION.md](features/SUBSCRIPTION.md)                  |
| Subscription Guard         | Access-control widget wrapping gated features        | ✅ Complete | [features/SUBSCRIPTION.md](features/SUBSCRIPTION.md)                  |
| Upgrade Prompt             | Contextual CTA when user hits a gated feature        | ✅ Complete | [features/SUBSCRIPTION.md](features/SUBSCRIPTION.md)                  |
| Subscription-Aware Stats   | Unified stats separating standalone vs coach source  | ✅ Complete | [features/SUBSCRIPTION_DEFINITIONS.md](features/SUBSCRIPTION_DEFINITIONS.md) |
| Session History Gating     | History distinguishes workout source                 | ✅ Complete | [features/SUBSCRIPTION_DEFINITIONS.md](features/SUBSCRIPTION_DEFINITIONS.md) |

**Primary Files:**

- `/lib/features/subscription/subscription.dart` - Feature barrel export
- `/lib/features/subscription/data/subscription_repository.dart` - API repository
- `/lib/features/subscription/services/in_app_purchase_service.dart` - Flutter IAP wrapper
- `/lib/features/subscription/presentation/providers/subscription_provider.dart` - Main state notifier
- `/lib/features/subscription/presentation/providers/subscription_guard.dart` - Access control guards
- `/lib/features/subscription/presentation/widgets/upgrade_prompt.dart` - Upgrade CTA widget

### Gains Coins & Economy _(Documented in [features/GAINS_COINS.md](features/GAINS_COINS.md))_

| Feature               | Description                                                 | Status      | Documentation                                      |
| --------------------- | ----------------------------------------------------------- | ----------- | -------------------------------------------------- |
| Coin Balance          | View current balance, lifetime earned/spent                 | ✅ Complete | [features/GAINS_COINS.md](features/GAINS_COINS.md) |
| Transaction History   | Paginated list of earn/spend transactions                   | ✅ Complete | [features/GAINS_COINS.md](features/GAINS_COINS.md) |
| Post-workout Reward   | Animated reward screen after session completion             | ✅ Complete | [features/GAINS_COINS.md](features/GAINS_COINS.md) |
| Cosmetics Shop        | Browse cosmetics by slot; purchase with coins               | ✅ Complete | [features/GAINS_COINS.md](features/GAINS_COINS.md) |
| Inventory             | Owned cosmetics + equip to avatar slots                     | ✅ Complete | [features/GAINS_COINS.md](features/GAINS_COINS.md) |
| Leaderboard           | Global ranking by coin balance                              | ✅ Complete | [features/GAINS_COINS.md](features/GAINS_COINS.md) |

**Primary Files:**

- `/lib/features/gains_coins/gains_coins.dart` - Feature barrel export
- `/lib/features/gains_coins/data/coins_repository.dart` - Balance + transaction history (offline-first)
- `/lib/features/gains_coins/data/cosmetics_repository.dart` - Shop catalog, inventory, equip/unequip
- `/lib/features/gains_coins/data/shop_repository.dart` - Purchase operations
- `/lib/features/gains_coins/data/leaderboard_repository.dart` - Leaderboard data
- `/lib/features/gains_coins/presentation/screens/shop_screen.dart` - Cosmetics shop catalog
- `/lib/features/gains_coins/presentation/screens/inventory_screen.dart` - Owned + equipped cosmetics
- `/lib/features/gains_coins/presentation/screens/leaderboard_screen.dart` - Global rankings

### Guidance & Onboarding _(Documented in [features/GUIDANCE.md](features/GUIDANCE.md))_

| Feature              | Description                                                           | Status      | Documentation                                  |
| -------------------- | --------------------------------------------------------------------- | ----------- | ---------------------------------------------- |
| Spotlight Tours      | Step-by-step coach-mark overlays for first-time users                 | ✅ Complete | [features/GUIDANCE.md](features/GUIDANCE.md)   |
| Tour Persistence     | Completed tours stored in Hive; not shown again                       | ✅ Complete | [features/GUIDANCE.md](features/GUIDANCE.md)   |
| Contextual Help      | Per-screen help sheet with metric/component explanations              | ✅ Complete | [features/GUIDANCE.md](features/GUIDANCE.md)   |
| RPE Scale Reference  | Rate of Perceived Exertion scale in set-logging help                  | ✅ Complete | [features/GUIDANCE.md](features/GUIDANCE.md)   |
| Segment Explanations | Body-segment score explanations in form results help                  | ✅ Complete | [features/GUIDANCE.md](features/GUIDANCE.md)   |

**Primary Files:**

- `/lib/features/guidance/guidance.dart` - Feature barrel export
- `/lib/features/guidance/data/guidance_repository.dart` - Hive-backed tour-completion flags
- `/lib/features/guidance/data/guidance_content.dart` - Static tour steps and help content
- `/lib/features/guidance/presentation/widgets/tour_orchestrator.dart` - Wraps screens to drive tours
- `/lib/features/guidance/presentation/widgets/info_icon_button.dart` - Per-screen help icon

---

## Workout Data Layer

| Feature                 | Description                                                                           | Status      |
| ----------------------- | ------------------------------------------------------------------------------------- | ----------- |
| Today's Routine         | `GET /workout/today` via `WorkoutRepository.getTodayRoutine()`                        | ✅ Complete |
| Weekly Stats            | `GET /workout/stats/weekly` via `WorkoutRepository.getWeeklyStats()`                  | ✅ Complete |
| Session History         | `GET /workout/sessions` via `WorkoutRepository.getSessionHistory()`                   | ✅ Complete |
| Server Session Start    | `POST /workout/sessions` via `WorkoutRepository.startServerSession()`                 | ✅ Complete |
| Server Session Complete | `POST /workout/sessions/:id/complete` via `WorkoutRepository.completeServerSession()` | ✅ Complete |
| Batch Set Sync          | `POST /workout/sets/sync` via `WorkoutRepository.batchSyncSets()`                     | ✅ Complete |
| Workout Sync Service    | Auto-syncs on connectivity restore; sessions → sets → completions                     | ✅ Complete |

**Primary Files:**

- `/lib/features/workout/data/workout_repository.dart` - All workout API methods + offline-first patterns
- `/lib/features/workout/data/models/today_routine_model.dart` - Today's routine model
- `/lib/features/workout/data/models/weekly_stats_model.dart` - Weekly stats model
- `/lib/features/workout/data/models/workout_history_model.dart` - Session history + pagination models
- `/lib/services/sync/workout_sync_service.dart` - Dedicated workout sync with correct endpoint mapping

---

## App Routes Summary

| Route                                          | Screen                      | Auth Required | Notes                                                        |
| ---------------------------------------------- | --------------------------- | ------------- | ------------------------------------------------------------ |
| `/`                                            | Splash                      | No            | Initial loading                                              |
| `/login`                                       | Login                       | No            | Public                                                       |
| `/register`                                    | Register                    | No            | Public                                                       |
| `/check-email`                                 | Check Email                 | No            | Post-registration email prompt                               |
| `/forgot-password`                             | Forgot Password             | No            | Public                                                       |
| `/reset-password`                              | Reset Password              | Semi\*        | Has recovery token                                           |
| `/email-verified`                              | Email Verified              | No            | Deep-link landing after email verification                   |
| `/complete-profile`                            | Complete Profile            | Semi\*        | Has Google tokens                                            |
| `/home`                                        | Home                        | Yes           | Main screen — [features/HOME.md](features/HOME.md)           |
| `/profile`                                     | Profile                     | Yes           | User profile                                                 |
| `/profile/edit`                                | Edit Profile                | Yes           | Edit avatar, bio, metrics                                    |
| `/settings`                                    | Settings                    | Yes           | App settings                                                 |
| `/routines`                                    | Routine List                | Yes           | Coach-assigned routines                                      |
| `/routines/:id`                                | Routine Detail              | Yes           | Routine with exercises                                       |
| `/workout-session`                             | Workout Session             | Yes           | Active workout UI                                            |
| `/programs`                                    | Programs                    | Yes           | User-side program list                                       |
| `/create-program`                              | Create Program              | Yes           | Create new program                                           |
| `/program-details`                             | Program Details             | Yes           | Program detail view                                          |
| `/calendar`                                    | Calendar                    | Yes           | Calendar view                                                |
| `/coach/hub`                                   | Coach Hub                   | Yes           | Coach tools hub                                              |
| `/coach/exercises`                             | Coach Exercise Library      | Yes           | Browse/search exercises                                      |
| `/coach/exercises/create`                      | Create Exercise             | Yes           | New exercise form                                            |
| `/coach/exercises/:id`                         | Exercise Detail             | Yes           | Exercise info + forms                                        |
| `/coach/exercises/:id/record`                  | Form Recording              | Yes           | Record reference form (MLKit)                                |
| `/coach/exercises/:id/forms/:formId/view`      | Coach View Form             | Yes           | 2D skeleton playback of reference form                       |
| `/coach/exercises/:id/forms/:formId/3d-preview`| Coach 3D Preview            | Yes           | 3D Unity preview of reference form                           |
| `/coach/programs`                              | Coach Programs              | Yes           | Coach program list                                           |
| `/coach/programs/create`                       | Create Coach Program        | Yes           | New program                                                  |
| `/coach/programs/:id`                          | Coach Program Detail        | Yes           | Program detail + routines                                    |
| `/coach/programs/:id/edit`                     | Edit Coach Program          | Yes           | Edit program                                                 |
| `/coach/routines`                              | Coach Routines              | Yes           | Coach routine list                                           |
| `/coach/routines/create`                       | Create Routine              | Yes           | New routine                                                  |
| `/coach/routines/:id`                          | Coach Routine Detail        | Yes           | Routine detail + exercises                                   |
| `/coach/routines/:id/edit`                     | Edit Routine                | Yes           | Edit routine                                                 |
| `/coach/clients/:userId/programs`              | Client Assignments          | Yes           | Assign programs to client                                    |
| `/coach/roster`                                | Coach Roster                | Yes           | Client roster with expiry info                               |
| `/coach/settings`                              | Coach Settings              | Yes           | Capacity & discoverability settings                          |
| `/coach/clients/:userId/progress`              | Client Progress             | Yes           | Tabbed client detail                                         |
| `/coach/clients/:userId/sessions/:sessionId`   | Client Session Detail       | Yes           | Session breakdown                                            |
| `/coach/clients/:userId/exercises/:exerciseId/history` | Exercise History    | Yes           | Exercise progress timeline                                   |
| `/coach/performance`                           | Performance Dashboard       | Yes           | All-clients volume/adherence report                          |
| `/workout/history`                             | Workout History             | Yes           | Paginated session history                                    |
| `/progress`                                    | Progress & Stats            | Yes           | Weekly stats, summary, recent workouts                       |
| `/client/exercise/:id/view-form`               | View Form                   | Yes           | See [features/CLIENT_POSE.md](features/CLIENT_POSE.md)       |
| `/client/exercise/:id/unity-record`            | Unity 3D Record             | Yes           | Primary compare route                                        |
| `/client/exercise/:id/3d-preview`              | Client 3D Preview           | Yes           | 3D preview of reference form                                 |
| `/client/exercise/:id/compare`                 | 2D Record (legacy)          | Yes           | Legacy compare route                                         |
| `/coaches/discover`                            | Coach Discovery             | Yes           | Browse/search public coaches                                 |
| `/coaches/:id`                                 | Coach Profile               | Yes           | View coach profile, subscribe/unsubscribe                    |
| `/coaches/subscribed`                          | Subscribed Coaches          | Yes           | User's subscribed coaches list                               |
| `/standalone/exercises`                        | Standalone Exercises        | Yes           | Personal exercise library                                    |
| `/standalone/exercises/create`                 | Create Exercise             | Yes           | New personal exercise                                        |
| `/standalone/exercises/:id/edit`               | Edit Exercise               | Yes           | Edit personal exercise                                       |
| `/standalone/routines`                         | Standalone Routines         | Yes           | Personal routine list                                        |
| `/standalone/routines/create`                  | Create Routine              | Yes           | New routine                                                  |
| `/standalone/routines/:id`                     | Routine Detail              | Yes           | Routine detail                                               |
| `/standalone/routines/:id/edit`                | Edit Routine                | Yes           | Edit routine                                                 |
| `/standalone/programs`                         | Standalone Programs         | Yes           | Personal program list                                        |
| `/standalone/programs/create`                  | Create Program              | Yes           | New program                                                  |
| `/standalone/programs/:id`                     | Program Detail              | Yes           | Program detail                                               |
| `/standalone/programs/:id/edit`                | Edit Program                | Yes           | Edit program                                                 |
| `/standalone/today`                            | Today's Standalone Routine  | Yes           | Day-cycling today routine                                    |
| `/standalone/sessions`                         | Standalone Session History  | Yes           | Session history                                              |
| `/coins/reward`                                | Coin Reward                 | Yes           | Post-workout reward display                                  |
| `/coins/history`                               | Coin History                | Yes           | Paginated transaction list                                   |
| `/shop`                                        | Shop                        | Yes           | Cosmetics catalog                                            |
| `/shop/cosmetic`                               | Cosmetic Detail             | Yes           | Single item detail + buy                                     |
| `/inventory`                                   | Inventory                   | Yes           | Owned + equipped cosmetics                                   |
| `/leaderboard`                                 | Leaderboard                 | Yes           | Global coin rankings                                         |

\*Semi-authenticated: Has temporary tokens but not full profile

---

## Quick Start Guide

### How to Navigate Documentation

1. **New to the codebase?** Start with [CONTEXT.md](CONTEXT.md) for patterns
2. **Working on auth?** See [features/AUTH_PRESENTATION.md](features/AUTH_PRESENTATION.md) and [features/REGISTER.md](features/REGISTER.md)
3. **Adding a new feature?** Follow the folder structure in CONTEXT.md

### Common Workflows

#### Adding a New Feature

1. Create feature folder: `/lib/features/<feature_name>/`
2. Create data models in `data/models/`
3. Create repository in `data/`
4. Create providers in `presentation/providers/`
5. Create screens in `presentation/screens/`
6. Add routes in `/lib/providers/router_provider.dart`
7. Run `dart run build_runner build --delete-conflicting-outputs`

### Where to Find Information

| Looking for...            | Go to...                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------ |
| Project architecture      | [CONTEXT.md](CONTEXT.md)                                                             |
| Creating providers        | [CONTEXT.md](CONTEXT.md) → Creating Riverpod Providers                               |
| Data models               | [CONTEXT.md](CONTEXT.md) → Creating Models                                           |
| API calls                 | [CONTEXT.md](CONTEXT.md) → Making API Calls                                          |
| Error handling            | [CONTEXT.md](CONTEXT.md) → Using Result Type                                         |
| Home dashboard            | [features/HOME.md](features/HOME.md)                                                 |
| Client pose recording     | [features/CLIENT_POSE.md](features/CLIENT_POSE.md)                                   |
| Coach pose recording      | [features/COACH_POSE_RECORDING.md](features/COACH_POSE_RECORDING.md)                 |
| Unity message contract    | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) → Unity Message Contract          |
| Registration flow         | [features/REGISTER.md](features/REGISTER.md)                                         |
| Google sign-in            | [features/REGISTER.md](features/REGISTER.md) → Google Sign-Up Flow                   |
| Email verification        | [features/VERIFY_RESET_FLOW.md](features/VERIFY_RESET_FLOW.md)                       |
| Route guards              | [features/REGISTER.md](features/REGISTER.md) → Router Guard                          |
| Profile viewing           | [features/PROFILE.md](features/PROFILE.md)                                           |
| Subscription gating       | [features/SUBSCRIPTION.md](features/SUBSCRIPTION.md)                                 |
| Coins & shop              | [features/GAINS_COINS.md](features/GAINS_COINS.md)                                   |
| Onboarding tours          | [features/GUIDANCE.md](features/GUIDANCE.md)                                         |
| Server endpoints          | [Server AUTH.md](../../get-gains-server/docs/features/AUTH.md)                       |

---

## Documentation Conventions

### Documentation Hierarchy

```
CONTEXT.md           → Core patterns, conventions (always check first)
FEATURE_INDEX.md     → Navigation hub (this file)
features/*.md        → Domain-specific feature documentation
```

### When to Create Feature Docs

**Create a new feature doc when:**

- Feature has multiple components (models, repository, providers)
- Feature involves complex flows (e.g., multi-step auth)
- Feature needs API reference documentation

**Don't create separate docs for:**

- Utilities already in CONTEXT.md
- Simple CRUD operations
- Single-file implementations

### Documentation Status Legend

| Status             | Meaning                                 |
| ------------------ | --------------------------------------- |
| ✅ Complete        | Full implementation with documentation  |
| ✅ Data/Services   | Backend ready, needs presentation layer |
| 🚧 Partial         | Some implementation exists              |
| ⚠️ Needs Docs      | Feature exists but undocumented         |
| 🔮 Not Implemented | Future feature                          |

---

## File Structure Reference

```
lib/
├── core/                           # App-wide utilities
│   ├── constants/
│   │   ├── api_constants.dart      # API endpoints
│   │   └── storage_keys.dart       # Storage keys
│   ├── utils/
│   │   ├── app_error.dart          # Error types
│   │   ├── logger.dart             # Logging
│   │   └── result.dart             # Result type
│   └── theme/                      # Theming
├── features/
│   ├── auth/                       # Auth data layer + screens
│   ├── client_pose/                # Client form recording + comparison
│   ├── coach_client_progress/      # Coach views of client data
│   ├── coach_pose/                 # Coach exercise library + form recording
│   ├── coach_programs/             # Coach programs, routines, assignments
│   ├── coach_settings/             # Coach capacity & discoverability
│   ├── coaches/                    # Coach discovery & subscription
│   ├── gains_coins/                # Coins, shop, inventory, leaderboard
│   ├── guidance/                   # Spotlight tours + contextual help
│   ├── home/                       # Dashboard
│   ├── profile/                    # User profile + editing
│   ├── programs/                   # User-side program screens (legacy)
│   ├── standalone_workout/         # Self-managed exercises/routines/programs
│   ├── subscription/               # IAP, tier gating, upgrade prompts
│   ├── unity/                      # Unity bridge
│   └── workout/                    # Coach-assigned workout sessions
├── providers/
│   ├── auth_state_provider.dart    # App-wide auth state
│   ├── deep_link_provider.dart     # Deep link handling
│   └── router_provider.dart        # Navigation + guards
├── services/
│   ├── api/
│   │   ├── api_client.dart         # Dio HTTP client
│   │   └── interceptors.dart       # Auth, retry, logging
│   ├── database/                   # Drift SQLite
│   ├── storage/
│   │   └── secure_storage_service.dart  # JWT tokens
│   └── sync/                       # Sync queue
└── main.dart
```

---

_Last updated: April 19, 2026_
