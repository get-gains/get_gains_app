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

| Document                                                                     | Purpose                                                               |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| [CONTEXT.md](CONTEXT.md)                                                     | Core infrastructure, patterns, conventions                            |
| [FEATURE_INDEX.md](FEATURE_INDEX.md)                                         | This file - navigation hub                                            |
| [features/REGISTER.md](features/REGISTER.md)                                 | Registration feature documentation                                    |
| [features/HOME.md](features/HOME.md)                                         | Home dashboard screen & widgets                                       |
| [features/POSE_DETECTION.md](features/POSE_DETECTION.md)                     | Pose detection, form analysis, on-device ML                           |
| [features/PROFILE.md](features/PROFILE.md)                                   | Profile viewing and management documentation                          |
| [features/PROGRAM.md](features/PROGRAM.md)                                   | Coach programs, routines, exercises, assignments                      |
| [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md)       | Coach discovery, settings & missing links data layer                  |
| [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md)         | Coaches & Subscription presentation layer (screens, routes)           |
| [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md)       | Coach client progress — sessions, stats, forms, presentation          |
| [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md)             | Standalone workout — exercises, routines, programs, sessions          |
| [features/SUBSCRIPTION_DEFINITIONS.md](features/SUBSCRIPTION_DEFINITIONS.md) | Subscription-aware stats, session history, upgrade prompts, UI gating |

### Recent Changes (specs/002-fix-client-flow)

| Change                    | Files Affected                                      | Description                                                                                |
| ------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Segment score aggregation | `form_comparison_service.dart`, `body_segment.dart` | Angle-level DTW scores aggregated into body-segment keys matching server `BodySegmentEnum` |
| Frame trimming            | `client_recording_provider.dart`                    | Client recording frames trimmed to reference length before DTW comparison                  |
| DTW defensive guard       | `form_comparison_service.dart`                      | Defensive trim inside `compare()` if client frames exceed reference                        |
| View Form removed         | `routine_detail_screen.dart`                        | Standalone "View Form" button removed from exercise cards                                  |
| Log Set above fold        | `client_unity_recording_screen.dart`                | Set logger moved above segment breakdown in results view                                   |
| Persistent Start Workout  | `routine_detail_screen.dart`                        | Start Workout button moved to `Scaffold.bottomNavigationBar`                               |
| Nullable assign-program   | `program_request_models.dart`                       | `endDate`/`notes` omitted from JSON when null via `@JsonKey(includeIfNull: false)`         |

### Recent Changes (form comparison & post-processing loading)

| Change | Files Affected | Description |
| --- | --- | --- |
| Post-processing loading (client) | `client_recording_provider.dart`, `client_recording_screen.dart`, `client_unity_recording_screen.dart` | `ClientRecordingProcessing` now has `progress` (0–1) and `message`; UI shows full-screen overlay with percentage and step message (e.g. "Detecting pose...", "Comparing to reference...") |
| Post-processing loading (coach) | `form_recording_provider.dart`, `form_recording_screen.dart` | `FormRecordingState.processingMessage` added; `_ProcessingOverlay` shows step message and prominent percentage during processing/upload |
| Comparison improvements | `landmark_preprocessor.dart`, `client_recording_provider.dart`, `form_comparison_service.dart` | Torso alignment (`normalizeForComparison`), best-offset temporal alignment, reference pipeline consistency (`processBatch` with `skipSmooth`), scoring curve 60° |
| Client recording pipeline | `client_recording_provider.dart`, client screens | Capture-only during recording (no live MLKit/rep counter); REC elapsed timer; rep badge removed; results show "Form analyzed" |

### Recent Changes (offline-first-recording)

| Change | Files Affected | Description |
| --- | --- | --- |
| Subscription gate offline fix | `subscription_guard.dart` | Gate shows `child` when subscription state is not loaded (offline optimistic access) |
| Retry interceptor offline fix | `interceptors.dart` | `connectionError` excluded from retry — no 42 s delay when offline |
| Form download caching | `client_pose_repository.dart`, `app_database.dart` | `CachedExerciseForms` Drift table; `downloadExerciseForm()` caches on success, falls back on failure |
| Proactive form pre-caching | `routine_detail_screen.dart`, `client_unity_recording_screen.dart` | All routine forms pre-cached when workout starts |
| Pose result queuing | `client_pose_repository.dart`, `workout_sync_service.dart` | `submitResult()` queues to SyncQueue offline; `_syncPendingPoseResults()` uploads on reconnect |
| History offline cache | `client_pose_repository.dart` | `getHistory()` caches first page in `CachedApiResponses`; served from cache when offline |
| API response cache table | `app_database.dart` | `CachedApiResponses` Drift table (schema v4) for generic key-value response caching |
| Today's routine + stats caching | `workout_repository.dart` | `getTodayRoutine()` / `getUnifiedWeeklyStats()` cached in `CachedApiResponses` |
| Recent activity local fallback | `home_providers.dart` | `recentActivityProvider` falls back to local Drift session history when offline |
| Profile offline cache | `profile_provider.dart` | `profileProvider` reads Hive cache when server unreachable |

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

| Feature              | Description                                               | Status                       | Documentation                                |
| -------------------- | --------------------------------------------------------- | ---------------------------- | -------------------------------------------- |
| Registration         | Email/password + Google sign-up                           | ✅ Data/Services             | [features/REGISTER.md](features/REGISTER.md) |
| Login                | Email/password + Google login                             | 🔮 Not Implemented           | -                                            |
| Password Reset       | Recovery via email                                        | ⚠️ Partial (send email only) | [features/REGISTER.md](features/REGISTER.md) |
| Profile Management   | View profile, stats, achievements, sign out               | ✅ View + Edit               | [features/PROFILE.md](features/PROFILE.md)   |
| Profile Data Layer   | Fitness profile CRUD, avatar upload, offline cache        | ✅ Complete                  | [features/PROFILE.md](features/PROFILE.md)   |
| Profile Editing UI   | Edit avatar, bio, body metrics, training prefs, equipment | ✅ Complete                  | [features/PROFILE.md](features/PROFILE.md)   |
| Connectivity Service | Network status monitoring for offline-first               | ✅ Complete                  | [features/PROFILE.md](features/PROFILE.md)   |

**Primary Files:**

- `/lib/features/auth/auth.dart` - Feature barrel export
- `/lib/features/auth/data/auth_repository.dart` - Auth data operations
- `/lib/features/auth/services/google_sign_in_service.dart` - Google OAuth
- `/lib/features/auth/services/user_preferences_service.dart` - User caching + raw cache helpers
- `/lib/features/auth/presentation/providers/register_provider.dart` - Registration state
- `/lib/providers/auth_state_provider.dart` - App-wide auth state
- `/lib/providers/router_provider.dart` - Route guards
- `/lib/features/profile/profile.dart` - Profile feature export
- `/lib/features/profile/data/user_profile_repository.dart` - Fitness profile CRUD + multipart upload + caching
- `/lib/features/profile/data/models/user_profile_model.dart` - Fitness profile model
- `/lib/features/profile/data/models/profile_request_models.dart` - Create/Update request models
- `/lib/features/profile/presentation/providers/profile_provider.dart` - Account-level profile fetching
- `/lib/features/profile/presentation/providers/user_profile_provider.dart` - Fitness profile notifier + derived providers
- `/lib/features/profile/presentation/providers/edit_profile_provider.dart` - Edit form state + save logic
- `/lib/features/profile/presentation/screens/profile_screen.dart` - Profile display UI (offline-ready)
- `/lib/features/profile/presentation/screens/edit_profile_screen.dart` - Edit profile form (online-only)
- `/lib/services/connectivity/connectivity_service.dart` - Connectivity monitoring + isOnlineProvider

### Client Pose & Form Comparison

| Feature               | Description                                                          | Status      | Documentation                                      |
| --------------------- | -------------------------------------------------------------------- | ----------- | -------------------------------------------------- |
| View Reference Form   | Animated 2D skeleton playback of coach's form                        | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Unity 3D Recording    | Record + compare with 3D Unity avatar skeleton                       | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| 2D Recording (legacy) | Camera + 2D skeleton recording + compare                             | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Capture-only recording | Raw frame capture during recording; no live MLKit or rep counter   | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Post-processing loading | Full-screen overlay with percentage and step message (client)     | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| DTW Comparison        | On-device similarity scoring; torso alignment, temporal best-offset  | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Score + Corrections   | Result display with segment breakdown                                | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Offline Form Cache    | Forms cached in Drift; proactively pre-cached on workout start       | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Offline Result Queue  | Results queued in SyncQueue when offline; synced on reconnect        | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| Offline History Cache | First-page history cached in CachedApiResponses for offline browsing | ✅ Complete | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |

**Primary Files:**

- `/lib/features/client_pose/client_pose.dart` - Feature barrel export
- `/lib/features/client_pose/data/client_pose_repository.dart` - API: download form, submit result
- `/lib/features/client_pose/presentation/providers/client_recording_provider.dart` - State machine
- `/lib/features/client_pose/presentation/screens/client_unity_recording_screen.dart` - 3D Unity screen
- `/lib/features/client_pose/presentation/screens/view_form_screen.dart` - Reference form viewer
- `/lib/features/client_pose/presentation/screens/client_recording_screen.dart` - Legacy 2D screen

### Pose Detection & Form Analysis _(Documented in [features/POSE_DETECTION.md](features/POSE_DETECTION.md))_

| Feature               | Description                           | Status             | Documentation                                            |
| --------------------- | ------------------------------------- | ------------------ | -------------------------------------------------------- |
| Camera Setup Guidance | Lighting, distance, angle validation  | 🔮 Not Implemented | [features/POSE_DETECTION.md](features/POSE_DETECTION.md) |
| MLKit Pose Detection  | On-device landmark extraction         | 🔮 Not Implemented | [features/POSE_DETECTION.md](features/POSE_DETECTION.md) |
| Limb Isolation        | Per-exercise body segment filtering   | 🔮 Not Implemented | [features/POSE_DETECTION.md](features/POSE_DETECTION.md) |
| DTW Comparison        | On-device form similarity scoring     | 🔮 Not Implemented | [features/POSE_DETECTION.md](features/POSE_DETECTION.md) |
| Correction Generation | Angle-specific feedback messages      | 🔮 Not Implemented | [features/POSE_DETECTION.md](features/POSE_DETECTION.md) |
| Offline Form Caching  | Download & cache coach forms in Drift | 🔮 Not Implemented | [features/POSE_DETECTION.md](features/POSE_DETECTION.md) |
| Result Upload         | Persist comparison results to server  | 🔮 Not Implemented | [features/POSE_DETECTION.md](features/POSE_DETECTION.md) |

**Primary Files (To Be Created):**

- `/lib/features/pose_detection/` - Feature root
- `/lib/features/pose_detection/data/` - Models, repository
- `/lib/features/pose_detection/services/` - MLKit, DTW, feature extraction
- `/lib/features/pose_detection/presentation/` - Screens, providers, widgets

### Coach Programs _(Documented in [features/PROGRAM.md](features/PROGRAM.md))_

| Feature                   | Description                                    | Status           | Documentation                                                          |
| ------------------------- | ---------------------------------------------- | ---------------- | ---------------------------------------------------------------------- |
| Programs CRUD             | Create, list, update, delete programs          | ✅ Data/Services | [features/PROGRAM.md](features/PROGRAM.md)                             |
| Routines CRUD             | Create, list, update, delete routines          | ✅ Data/Services | [features/PROGRAM.md](features/PROGRAM.md)                             |
| ProgramRoutine Junctions  | Assign/reorder/remove routines in programs     | ✅ Data/Services | [features/PROGRAM.md](features/PROGRAM.md)                             |
| RoutineExercise Junctions | Add/update/remove exercises in routines        | ✅ Data/Services | [features/PROGRAM.md](features/PROGRAM.md)                             |
| Program Assignments       | Assign programs to clients, manage assignments | ✅ Data/Services | [features/PROGRAM.md](features/PROGRAM.md)                             |
| Class Roster (ML-4)       | Coach roster with client subscription expiry   | ✅ Complete      | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md)   |
| Client List (ML-4)        | Full client list with assignments + expiry     | ✅ Data/Services | [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md) |

**Primary Files:**

- `/lib/features/coach_programs/coach_programs.dart` - Feature barrel export
- `/lib/features/coach_programs/data/coach_program_repository.dart` - All API calls
- `/lib/features/coach_programs/data/models/program_model.dart` - Program, routine summary, assignment models
- `/lib/features/coach_programs/data/models/coach_client_model.dart` - Roster/client models with subscription expiry (ML-4)
- `/lib/features/coach_programs/data/models/program_request_models.dart` - Request models
- `/lib/features/coach_programs/presentation/providers/coach_program_provider.dart` - Programs list + detail
- `/lib/features/coach_programs/presentation/providers/coach_routine_provider.dart` - Routines list + detail
- `/lib/features/coach_programs/presentation/providers/coach_assignment_provider.dart` - Client assignments
- `/lib/features/coach_programs/presentation/providers/coach_roster_provider.dart` - Class roster with expiry (ML-4)
- `/lib/features/coach_programs/presentation/providers/coach_client_list_provider.dart` - Full client list (ML-4)

### Coach Discovery & Subscription _(Documented in [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md))_

| Feature               | Description                           | Status      | Documentation                                                        |
| --------------------- | ------------------------------------- | ----------- | -------------------------------------------------------------------- |
| Coach Discovery       | Browse/search public coaches          | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |
| Coach Profile (ML-1)  | Single coach detail with social links | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |
| Subscribed Coaches    | List user's subscribed coaches        | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |
| Subscribe/Unsubscribe | Coach subscription management         | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |

**Primary Files:**

- `/lib/features/coaches/coaches.dart` - Feature barrel export
- `/lib/features/coaches/data/coach_repository.dart` - Discovery, profile, subscribe API calls
- `/lib/features/coaches/data/models/coach_model.dart` - CoachSummaryModel, CoachDetailModel
- `/lib/features/coaches/presentation/providers/coach_discovery_provider.dart` - Discover coaches
- `/lib/features/coaches/presentation/providers/coach_profile_provider.dart` - Single coach detail (ML-1)
- `/lib/features/coaches/presentation/providers/subscribed_coaches_provider.dart` - Subscribed coaches list
- `/lib/features/coaches/presentation/screens/coach_discovery_screen.dart` - Browse/search screen
- `/lib/features/coaches/presentation/screens/coach_profile_screen.dart` - Full profile screen (ML-1)
- `/lib/features/coaches/presentation/screens/subscribed_coaches_screen.dart` - My coaches screen

### Coach Settings _(Documented in [features/COACHES_MISSING_LINKS.md](features/COACHES_MISSING_LINKS.md))_

| Feature                    | Description                                    | Status      | Documentation                                                        |
| -------------------------- | ---------------------------------------------- | ----------- | -------------------------------------------------------------------- |
| Coach Settings CRUD (ML-5) | Max clients, accepting toggle, discoverability | ✅ Complete | [features/COACHES_PRESENTATION.md](features/COACHES_PRESENTATION.md) |

**Primary Files:**

- `/lib/features/coach_settings/coach_settings.dart` - Feature barrel export
- `/lib/features/coach_settings/data/coach_settings_repository.dart` - GET/PATCH settings
- `/lib/features/coach_settings/data/models/coach_settings_model.dart` - Settings model + update request
- `/lib/features/coach_settings/presentation/providers/coach_settings_provider.dart` - Settings state + toggles
- `/lib/features/coach_settings/presentation/screens/coach_settings_screen.dart` - Settings UI screen (ML-5)

### Coach Client Progress _(Documented in [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md))_

Coach-facing endpoints for viewing client workout data, progress metrics, and form analysis:

| Feature                     | Description                                                 | Status      | Documentation                                                          |
| --------------------------- | ----------------------------------------------------------- | ----------- | ---------------------------------------------------------------------- |
| Client Session List         | Paginated list of client workout sessions                   | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Session Detail       | Full session with exercises + sets grouped                  | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Weekly Stats         | Weekly aggregates with previous-week deltas                 | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Exercise History     | Per-exercise progress over time (best set, volume)          | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Detailed Performance Report | All-clients report with volume, adherence, session duration | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Client Form Results         | Form comparison history with segment scores and corrections | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |
| Presentation Layer          | 5 screens, routes, Coach Hub + Roster integration           | ✅ Complete | [features/COACH_CLIENT_PROGRESS.md](features/COACH_CLIENT_PROGRESS.md) |

**Primary Files:**

- `/lib/features/coach_client_progress/coach_client_progress.dart` - Feature barrel export
- `/lib/features/coach_client_progress/data/coach_client_progress_repository.dart` - All 6 API calls + provider
- `/lib/features/coach_client_progress/data/models/client_session_model.dart` - Session summary + detail + sets
- `/lib/features/coach_client_progress/data/models/weekly_stats_model.dart` - Weekly stats + delta
- `/lib/features/coach_client_progress/data/models/exercise_history_model.dart` - Exercise history + summary
- `/lib/features/coach_client_progress/data/models/detailed_performance_model.dart` - Performance entry + summary
- `/lib/features/coach_client_progress/data/models/form_result_model.dart` - Form result + corrections
- `/lib/features/coach_client_progress/presentation/providers/client_progress_providers.dart` - All 6 notifiers
- `/lib/features/coach_client_progress/presentation/screens/client_progress_screen.dart` - Tabbed client detail
- `/lib/features/coach_client_progress/presentation/screens/session_detail_screen.dart` - Session breakdown
- `/lib/features/coach_client_progress/presentation/screens/exercise_history_screen.dart` - Exercise progress timeline
- `/lib/features/coach_client_progress/presentation/screens/performance_dashboard_screen.dart` - All-client report
- `/lib/features/coach_client_progress/presentation/screens/form_review_screen.dart` - Form result detail

### Standalone Workout _(Documented in [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md))_

| Feature            | Description                                                     | Status             | Documentation                                                    |
| ------------------ | --------------------------------------------------------------- | ------------------ | ---------------------------------------------------------------- |
| Exercise CRUD      | Create/update/delete personal exercises + browse public library | ✅ Data layer      | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Routine CRUD       | Build custom routines from any exercises                        | ✅ Data layer      | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Program CRUD       | Organise routines into a day-cycling program                    | ✅ Data layer      | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Self-assignment    | Activate / deactivate a standalone program                      | ✅ Data layer      | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Today's Routine    | Server day-cycling resolution (`GET /standalone/today`)         | ✅ Data layer      | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Session Lifecycle  | Start / complete sessions, view history                         | ✅ Data layer      | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Weekly Stats       | Aggregated weekly stats (`GET /standalone/stats/weekly`)        | ✅ Data layer      | [features/STANDALONE_WORKOUT.md](features/STANDALONE_WORKOUT.md) |
| Presentation Layer | Providers, screens, routes                                      | 🔮 Not Implemented | —                                                                |

**Primary Files:**

- `/lib/features/standalone_workout/standalone_workout.dart` - Feature barrel export
- `/lib/features/standalone_workout/data/standalone_workout_repository.dart` - Offline-first repository + provider
- `/lib/features/standalone_workout/data/models/standalone_exercise_model.dart` - Exercise + list response
- `/lib/features/standalone_workout/data/models/standalone_routine_model.dart` - Routine summary + list response
- `/lib/features/standalone_workout/data/models/standalone_program_model.dart` - Program hierarchy models
- `/lib/features/standalone_workout/data/models/standalone_today_model.dart` - Day-cycling today model
- `/lib/features/standalone_workout/data/models/standalone_session_model.dart` - Session summary (re-exports WorkoutSessionModel, WeeklyStatsModel)
- `/lib/features/standalone_workout/data/models/standalone_request_models.dart` - 12 CRUD request models

---

### Future Domain Features _(Needs Implementation)_

| Feature                 | Description                                                  | Status        |
| ----------------------- | ------------------------------------------------------------ | ------------- |
| Workout History Screen  | Paginated completed session list                             | ✅ Complete   |
| Progress / Stats Screen | Weekly stats, summary grid, recent workouts                  | ✅ Complete   |
| Coach Hub Screen        | Central hub for coach tools (programs, routines, exercises)  | ✅ Complete   |
| Workout Sync            | Dedicated workout sync service (sessions, sets, completions) | ✅ Data layer |

### Workout Data Layer

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

| Route                               | Screen             | Auth Required | Notes                                                  |
| ----------------------------------- | ------------------ | ------------- | ------------------------------------------------------ |
| `/`                                 | Splash             | No            | Initial loading                                        |
| `/login`                            | Login              | No            | Public                                                 |
| `/register`                         | Register           | No            | Public                                                 |
| `/forgot-password`                  | Forgot Password    | No            | Public                                                 |
| `/reset-password`                   | Reset Password     | Semi\*        | Has recovery token                                     |
| `/complete-profile`                 | Complete Profile   | Semi\*        | Has Google tokens                                      |
| `/home`                             | Home               | Yes           | Main screen — [features/HOME.md](features/HOME.md)     |
| `/profile`                          | Profile            | Yes           | User profile                                           |
| `/settings`                         | Settings           | Yes           | App settings                                           |
| `/routines`                         | Routine List       | Yes           | —                                                      |
| `/routines/:id`                     | Routine Detail     | Yes           | —                                                      |
| `/workout-session`                  | Workout Session    | Yes           | —                                                      |
| `/client/exercise/:id/view-form`    | View Form          | Yes           | See [features/CLIENT_POSE.md](features/CLIENT_POSE.md) |
| `/client/exercise/:id/unity-record` | Unity 3D Record    | Yes           | Primary compare route                                  |
| `/client/exercise/:id/compare`      | 2D Record (legacy) | Yes           | Legacy compare route                                   |
| `/coaches/discover`                 | Coach Discovery    | Yes           | Browse/search public coaches                           |
| `/coaches/:id`                      | Coach Profile      | Yes           | View coach profile, subscribe/unsubscribe              |
| `/coaches/subscribed`               | Subscribed Coaches | Yes           | User's subscribed coaches list                         |
| `/coach/roster`                     | Coach Roster       | Yes           | Coach's client roster with expiry info                 |
| `/coach/settings`                   | Coach Settings     | Yes           | Coach capacity & discoverability settings              |
| `/coach/hub`                        | Coach Hub          | Yes           | Coach tools hub (programs, routines, exercises)        |
| `/workout/history`                  | Workout History    | Yes           | Paginated workout session history                      |
| `/progress`                         | Progress & Stats   | Yes           | Weekly stats, summary, recent workouts                 |

\*Semi-authenticated: Has temporary tokens but not full profile

---

## Quick Start Guide

### How to Navigate Documentation

1. **New to the codebase?** Start with [CONTEXT.md](CONTEXT.md) for patterns
2. **Working on auth?** See [features/REGISTER.md](features/REGISTER.md)
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

#### Using Auth Repository

```dart
// Access repository
final authRepo = ref.read(authRepositoryProvider);

// Email/password registration
final result = await authRepo.registerWithEmailPassword(
  email: 'user@example.com',
  password: 'Password123!',
  name: 'John Doe',
  nickname: 'johnd',
);

// Google sign-up (2 steps)
final googleResult = await authRepo.signInWithGoogle();
if (googleResult.isSuccess) {
  // Show profile completion form
  final completeResult = await authRepo.completeGoogleSignUp(
    name: 'John Doe',
    nickname: 'johnd',
  );
}
```

#### Using Register Provider

```dart
// Watch registration state
final state = ref.watch(registerNotifierProvider);

// Handle states
if (state is RegisterLoading) {
  // Show loading
} else if (state is RegisterSuccess) {
  // Navigate to home
} else if (state is RegisterGooglePendingProfile) {
  // Show profile form
} else if (state is RegisterError) {
  // Show error
}

// Trigger registration
ref.read(registerNotifierProvider.notifier).registerWithEmailPassword(
  email: email,
  password: password,
  name: name,
  nickname: nickname,
);
```

### Where to Find Information

| Looking for...        | Go to...                                                                    |
| --------------------- | --------------------------------------------------------------------------- |
| Project architecture  | [CONTEXT.md](CONTEXT.md)                                                    |
| Creating providers    | [CONTEXT.md](CONTEXT.md) → Creating Riverpod Providers                      |
| Data models           | [CONTEXT.md](CONTEXT.md) → Creating Models                                  |
| API calls             | [CONTEXT.md](CONTEXT.md) → Making API Calls                                 |
| Error handling        | [CONTEXT.md](CONTEXT.md) → Using Result Type                                |
| Home dashboard        | [features/HOME.md](features/HOME.md)                                        |
| Client pose recording | [features/CLIENT_POSE.md](features/CLIENT_POSE.md)                          |
| Reference form source | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) → Reference Form Source  |
| Unity 3D skeleton     | [features/CLIENT_POSE.md](features/CLIENT_POSE.md) → Unity Message Contract |
| Registration flow     | [features/REGISTER.md](features/REGISTER.md)                                |
| Google sign-in        | [features/REGISTER.md](features/REGISTER.md) → Google Sign-Up Flow          |
| Route guards          | [features/REGISTER.md](features/REGISTER.md) → Router Guard                 |
| Profile viewing       | [features/PROFILE.md](features/PROFILE.md)                                  |
| Profile editing plan  | [features/PROFILE.md](features/PROFILE.md) → Future Enhancements            |
| Server endpoints      | [Server AUTH.md](../../get-gains-server/docs/features/AUTH.md)              |

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
│   ├── home/
│   │   ├── home.dart               # Feature export
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── home_screen.dart
│   │       └── widgets/
│   │           ├── quick_action_card.dart
│   │           ├── weekly_progress_card.dart
│   │           └── workout_summary_card.dart
│   └── auth/
│       ├── auth.dart               # Feature export
│       ├── data/
│       │   ├── auth_repository.dart
│       │   └── models/
│       │       ├── auth_request_models.dart
│       │       ├── auth_response_models.dart
│       │       └── user_model.dart
│       ├── presentation/
│       │   └── providers/
│       │       └── register_provider.dart
│       └── services/
│           ├── google_sign_in_service.dart
│           └── user_preferences_service.dart
├── providers/
│   ├── auth_state_provider.dart    # App-wide auth state
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

_Last updated: March 13, 2026_
