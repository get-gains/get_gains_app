# Coaches Feature (Client-Facing) & Missing Links Data Layer

## Overview

This feature provides the **client-facing data layer** for coach discovery, profile viewing, and subscription management. It addresses the Missing Links (ML-1 through ML-5) identified in the server-side subscription flow audit.

### Missing Links Summary

| ID | Description | Flutter Impact | Status |
|----|-------------|----------------|--------|
| **ML-1** | Single coach profile endpoint | New `CoachDetailModel` + `getCoachProfile()` repo method + `CoachProfileNotifier` | ✅ Data layer complete |
| **ML-2** | `requireSubscription()` on subscribe route | Server-side only — client receives 403 on free-tier | ✅ No client changes needed |
| **ML-3** | Webhook evicts clients on EXPIRED/REVOKED | Server-side only — client list auto-updates on next fetch | ✅ No client changes needed |
| **ML-4** | Roster surfaces `subscriptionExpiresAt` | New `RosterClientModel` + `CoachClientModel` with expiry field + roster/client list providers | ✅ Data layer complete |
| **ML-5** | `CoachSettings` model + capacity enforcement | New `coach_settings` feature with model, repo, provider | ✅ Data layer complete |

---

## Architecture

### New Feature: `coaches` (Client-Facing)

```
lib/features/coaches/
├── coaches.dart                              # Feature barrel export
├── data/
│   ├── data.dart                             # Data layer barrel
│   ├── models/
│   │   ├── models.dart                       # Models barrel
│   │   └── coach_model.dart                  # CoachSummaryModel, CoachDetailModel
│   └── coach_repository.dart                 # Discovery, profile, subscribe/unsubscribe
└── presentation/
    ├── presentation.dart                     # Presentation barrel
    └── providers/
        ├── providers.dart                    # Providers barrel
        ├── coach_discovery_provider.dart     # Discover/search public coaches
        ├── coach_profile_provider.dart       # Single coach detail (ML-1)
        └── subscribed_coaches_provider.dart  # User's subscribed coaches list
```

### New Feature: `coach_settings` (Coach-Facing, ML-5)

```
lib/features/coach_settings/
├── coach_settings.dart                       # Feature barrel export
├── data/
│   ├── data.dart                             # Data layer barrel
│   ├── models/
│   │   ├── models.dart                       # Models barrel
│   │   └── coach_settings_model.dart         # CoachSettingsModel, UpdateCoachSettingsRequest
│   └── coach_settings_repository.dart        # GET/PATCH coach settings
└── presentation/
    ├── presentation.dart                     # Presentation barrel
    └── providers/
        ├── providers.dart                    # Providers barrel
        └── coach_settings_provider.dart      # Settings state + toggles
```

### Updated: `coach_programs` (Coach-Facing, ML-4)

```
lib/features/coach_programs/
├── data/
│   ├── models/
│   │   └── coach_client_model.dart           # NEW: RosterClientModel, CoachClientModel
│   └── coach_program_repository.dart         # UPDATED: +getClassRoster, +removeClient, +getClients
└── presentation/
    └── providers/
        ├── coach_roster_provider.dart        # NEW: Class roster with expiry data
        └── coach_client_list_provider.dart   # NEW: Full client list with assignments
```

### Updated: `core/constants`

```
lib/core/constants/
└── api_constants.dart                        # UPDATED: +coachClass, +coachSettings, +discoverCoaches, +subscribedCoaches
```

---

## Models

### `CoachSummaryModel` — Coach list item

Returned from discovery (`GET /user/coaches`) and subscribed coaches (`GET /user/coaches/subscribed`).

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Coach ID |
| `name` | `String` | Display name |
| `email` | `String` | Email address |
| `avatarUrl` | `String?` | Profile image URL |
| `bio` | `String?` | Coach bio |
| `yearsExperience` | `int` | Years of coaching experience |
| `certifications` | `List<String>` | Professional certifications |
| `awards` | `List<String>` | Awards and recognitions |
| `specialties` | `List<String>` | Training specialties |
| `isVerified` | `bool` | Platform-verified coach |
| `createdAt` | `DateTime?` | Profile creation date |
| `subscribedAt` | `DateTime?` | When the client subscribed (only on subscribed list) |

### `CoachDetailModel` — Single coach profile (ML-1)

Returned from `GET /user/coaches/:coachId`. Extends the summary with detail-view fields.

| Extra Field | Type | Description |
|-------------|------|-------------|
| `socialLinks` | `List<String>` | Coach's social media links |

### `RosterClientModel` — Class roster client (ML-4)

Returned from `GET /coach/class`. Lightweight client with subscription expiry.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Client user ID |
| `email` | `String` | Client email |
| `name` | `String?` | Client name |
| `nickname` | `String?` | Client nickname |
| `subscribedAt` | `DateTime` | When the client subscribed to this coach |
| `subscriptionExpiresAt` | `DateTime?` | **ML-4**: When the client's platform subscription expires |

**Extension helpers**: `displayName`, `daysUntilExpiry`, `isExpiringSoon` (≤7 days).

### `CoachClientModel` — Full client with assignments (ML-4)

Returned from `GET /coach/clients`. Extends roster fields with program data.

| Extra Field | Type | Description |
|-------------|------|-------------|
| `assignedPrograms` | `List<ClientAssignedProgram>` | Programs assigned to this client |
| `isAssigned` | `bool` | Whether the client has any active assignment |

### `CoachSettingsModel` — Coach settings (ML-5)

Returned from `GET /coach/settings` and `PATCH /coach/settings`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | `String` | — | Settings record ID |
| `coachId` | `String` | — | Owning coach ID |
| `maxClients` | `int` | `40` | Hard cap on active client count |
| `acceptingClients` | `bool` | `true` | Manual intake on/off switch |
| `isDiscoverable` | `bool` | `true` | Appear in public coach search |

---

## Repository Methods

### `CoachRepository` — Client-facing coach operations

| Method | API | Description |
|--------|-----|-------------|
| `discoverCoaches({search, specialty, limit, offset})` | `GET /user/coaches` | Browse public coaches |
| `getCoachProfile(coachId)` | `GET /user/coaches/:coachId` | **ML-1**: Fetch single coach detail |
| `getSubscribedCoaches({limit, offset})` | `GET /user/coaches/subscribed` | List user's subscribed coaches |
| `subscribeToCoach(coachId)` | `POST /user/coaches/:coachId` | Subscribe (server guards ML-2 + ML-5) |
| `unsubscribeFromCoach(coachId)` | `DELETE /user/coaches/:coachId` | Unsubscribe from a coach |

### `CoachProgramRepository` — New methods (coach-facing)

| Method | API | Description |
|--------|-----|-------------|
| `getClassRoster({limit, offset})` | `GET /coach/class` | **ML-4**: Roster with `subscriptionExpiresAt` |
| `removeClientFromClass(clientId)` | `DELETE /coach/class/:clientId` | Remove a client from class |
| `getClients({limit, offset, isAssigned})` | `GET /coach/clients` | **ML-4**: Full client list with assignments + expiry |

### `CoachSettingsRepository` — ML-5

| Method | API | Description |
|--------|-----|-------------|
| `getSettings()` | `GET /coach/settings` | Fetch coach's settings |
| `updateSettings(request)` | `PATCH /coach/settings` | Update settings (partial) |

---

## Providers

### Coach Discovery

| Provider | Type | Description |
|----------|------|-------------|
| `coachDiscoveryNotifierProvider` | `Notifier<CoachDiscoveryState>` | Search/browse public coaches |
| `coachDiscoveryLoadingProvider` | `bool` | Loading state |
| `discoveredCoachesListProvider` | `List<CoachSummaryModel>` | Current coach list |
| `coachDiscoveryPaginationProvider` | `CoachPaginationMeta?` | Pagination info |
| `coachDiscoveryErrorProvider` | `AppError?` | Error state |

### Coach Profile (ML-1)

| Provider | Type | Description |
|----------|------|-------------|
| `coachProfileNotifierProvider(coachId)` | `Family Notifier<CoachProfileState>` | Single coach detail |

### Subscribed Coaches

| Provider | Type | Description |
|----------|------|-------------|
| `subscribedCoachesNotifierProvider` | `Notifier<SubscribedCoachesState>` | User's subscribed coaches |
| `subscribedCoachesLoadingProvider` | `bool` | Loading state |
| `subscribedCoachesListProvider` | `List<CoachSummaryModel>` | Subscribed coaches list |
| `isSubscribedToCoachProvider(coachId)` | `bool` | Check if subscribed to specific coach |
| `subscribedCoachCountProvider` | `int` | Total subscribed count |

### Coach Roster (ML-4)

| Provider | Type | Description |
|----------|------|-------------|
| `coachRosterNotifierProvider` | `Notifier<CoachRosterState>` | Class roster management |
| `coachRosterLoadingProvider` | `bool` | Loading state |
| `rosterClientsListProvider` | `List<RosterClientModel>` | Roster clients |
| `rosterClientCountProvider` | `int` | Total roster count |
| `expiringClientsProvider` | `List<RosterClientModel>` | Clients expiring within 7 days |

### Coach Client List (ML-4)

| Provider | Type | Description |
|----------|------|-------------|
| `coachClientListNotifierProvider` | `Notifier<CoachClientListState>` | Full client list with assignments |
| `coachClientListLoadingProvider` | `bool` | Loading state |
| `coachClientsListProvider` | `List<CoachClientModel>` | Client list |
| `unassignedClientsProvider` | `List<CoachClientModel>` | Clients with no programs |
| `expiringClientsFullProvider` | `List<CoachClientModel>` | Clients expiring within 7 days |

### Coach Settings (ML-5)

| Provider | Type | Description |
|----------|------|-------------|
| `coachSettingsNotifierProvider` | `Notifier<CoachSettingsState>` | Settings state + CRUD |
| `coachSettingsLoadingProvider` | `bool` | Loading state |
| `currentCoachSettingsProvider` | `CoachSettingsModel?` | Current settings |
| `isAcceptingClientsProvider` | `bool` | Intake toggle |
| `isCoachDiscoverableProvider` | `bool` | Discovery visibility |
| `coachMaxClientsProvider` | `int` | Max capacity |

---

## Usage

### Import Features

```dart
// Client-facing coach discovery
import 'package:get_gains_app/features/coaches/coaches.dart';

// Coach settings (ML-5)
import 'package:get_gains_app/features/coach_settings/coach_settings.dart';

// Coach roster/client models (ML-4, already part of coach_programs)
import 'package:get_gains_app/features/coach_programs/coach_programs.dart';
```

### Discover Coaches

```dart
// Load coaches
ref.read(coachDiscoveryNotifierProvider.notifier).loadCoaches(search: 'yoga');

// Watch results
final coaches = ref.watch(discoveredCoachesListProvider);
final isLoading = ref.watch(coachDiscoveryLoadingProvider);
```

### View Coach Profile (ML-1)

```dart
// Load a single coach's full profile
ref.read(coachProfileNotifierProvider('coach-id').notifier).load();

// Watch state
final state = ref.watch(coachProfileNotifierProvider('coach-id'));
switch (state) {
  case CoachProfileLoaded(:final coach):
    // Access coach.socialLinks, coach.bio, etc.
  case CoachProfileError(:final error):
    // Handle error
  default:
    // Loading or initial
}
```

### Subscribe to a Coach

```dart
// Subscribe — server enforces ML-2 (subscription guard) + ML-5 (capacity)
final success = await ref
    .read(subscribedCoachesNotifierProvider.notifier)
    .subscribeToCoach('coach-id');

if (!success) {
  // Check error — could be 403 (no subscription) or 409 (full/not accepting)
}
```

### Coach Roster with Expiry (ML-4)

```dart
// Load roster
ref.read(coachRosterNotifierProvider.notifier).loadRoster();

// Watch clients with expiry info
final clients = ref.watch(rosterClientsListProvider);
for (final client in clients) {
  print('${client.displayName} expires in ${client.daysUntilExpiry} days');
  if (client.isExpiringSoon) {
    // Show warning badge
  }
}

// Get only expiring clients
final expiring = ref.watch(expiringClientsProvider);
```

### Coach Settings (ML-5)

```dart
// Load settings
ref.read(coachSettingsNotifierProvider.notifier).load();

// Toggle intake
await ref.read(coachSettingsNotifierProvider.notifier).toggleAcceptingClients();

// Toggle discoverability
await ref.read(coachSettingsNotifierProvider.notifier).toggleDiscoverability();

// Set max clients
await ref.read(coachSettingsNotifierProvider.notifier).setMaxClients(20);

// Watch convenience providers
final accepting = ref.watch(isAcceptingClientsProvider);
final discoverable = ref.watch(isCoachDiscoverableProvider);
final maxClients = ref.watch(coachMaxClientsProvider);
```

---

## Server-Side Error Handling

The following errors are returned by the server and should be handled in the UI:

| Status | Scenario | Server Message |
|--------|----------|----------------|
| `403` | Free-tier user tries to subscribe to a coach (ML-2) | `"Active subscription required"` |
| `404` | Coach ID not found | `"Coach not found"` |
| `409` | Already subscribed to this coach | `"Already subscribed to this coach"` |
| `409` | Coach not accepting clients (ML-5) | `"This coach is not accepting new clients at this time"` |
| `409` | Coach at max capacity (ML-5) | `"This coach has reached their maximum client capacity"` |

All errors flow through the `Result<T, AppError>` pattern — the `NetworkError` subclass captures status codes and server messages for UI display.

---

## API Constants Added

| Constant | Value | Used By |
|----------|-------|---------|
| `ApiConstants.coachClass` | `/coach/class` | Roster endpoints |
| `ApiConstants.coachSettings` | `/coach/settings` | Settings endpoints |
| `ApiConstants.discoverCoaches` | `/user/coaches` | Discovery + profile + subscribe |
| `ApiConstants.subscribedCoaches` | `/user/coaches/subscribed` | Subscribed coaches list |

---

## Code Generation

After pulling these changes, run build_runner to generate freezed/riverpod code:

```bash
cd get_gains_app
fvm dart run build_runner build --delete-conflicting-outputs
```
