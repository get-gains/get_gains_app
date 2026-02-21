# Coaches & Subscription — Presentation Layer

## Overview

This document covers the **presentation layer** (screens, routes, navigation) for the Coaches & Subscription feature, completing the Missing Links (ML-1 through ML-5) end-to-end.

The data layer (models, repositories, providers) was implemented previously. This layer adds **6 new screens** and **7 new routes** to make the feature fully usable.

---

## Screens Summary

| Screen | Feature | Route | ML | Description |
|--------|---------|-------|----|-------------|
| `CoachDiscoveryScreen` | `coaches` | `/coaches/discover` | — | Browse & search public coaches |
| `CoachProfileScreen` | `coaches` | `/coaches/:id` | ML-1 | Full coach profile with subscribe action |
| `SubscribedCoachesScreen` | `coaches` | `/coaches/subscribed` | — | User's subscribed coaches list |
| `CoachRosterScreen` | `coach_programs` | `/coach/roster` | ML-4 | Coach's class roster with subscription expiry |
| `CoachSettingsScreen` | `coach_settings` | `/coach/settings` | ML-5 | Coach capacity, intake, discoverability |
| *(Client Assignments)* | `coach_programs` | `/coach/clients/:userId/programs` | — | Pre-existing — linked from roster |

---

## New Routes

Added to `AppRoutes` in `router_provider.dart`:

```dart
// Coach-facing
static const String coachRoster = '/coach/roster';
static const String coachSettings = '/coach/settings';

// Client-facing
static const String discoverCoaches = '/coaches/discover';
static const String coachProfile = '/coaches/:id';
static const String subscribedCoaches = '/coaches/subscribed';
```

---

## File Structure

### `coaches` feature (client-facing)

```
lib/features/coaches/
├── coaches.dart                              # Barrel
├── data/                                     # (pre-existing)
│   ├── models/coach_model.dart
│   └── coach_repository.dart
└── presentation/
    ├── presentation.dart                     # Updated: exports screens
    ├── providers/                            # (pre-existing)
    │   ├── coach_discovery_provider.dart
    │   ├── coach_profile_provider.dart
    │   └── subscribed_coaches_provider.dart
    └── screens/                              # NEW
        ├── screens.dart                      # Barrel
        ├── coach_discovery_screen.dart       # Browse/search coaches
        ├── coach_profile_screen.dart         # ML-1: Full profile view
        └── subscribed_coaches_screen.dart    # User's subscribed coaches
```

### `coach_settings` feature (coach-facing, ML-5)

```
lib/features/coach_settings/
├── coach_settings.dart                       # Barrel
├── data/                                     # (pre-existing)
│   ├── models/coach_settings_model.dart
│   └── coach_settings_repository.dart
└── presentation/
    ├── presentation.dart                     # Updated: exports screens
    ├── providers/                            # (pre-existing)
    │   └── coach_settings_provider.dart
    └── screens/                              # NEW
        ├── screens.dart                      # Barrel
        └── coach_settings_screen.dart        # ML-5: Settings UI
```

### `coach_programs` feature (coach-facing, ML-4 roster)

```
lib/features/coach_programs/
└── presentation/
    └── screens/
        ├── screens.dart                      # Updated: exports roster screen
        └── coach_roster_screen.dart          # NEW — ML-4: Roster with expiry
```

---

## Screen Details

### 1. Coach Discovery Screen

**Route**: `/coaches/discover`  
**Provider**: `coachDiscoveryProvider`

- Search bar with submit/clear
- Paginated grid of coach cards (avatar, name, bio, specialties, verification badge)
- Pull-to-refresh
- Infinite scroll pagination
- Empty state when no results
- App bar action navigates to subscribed coaches

**Navigation**:
- Tapping a coach → `CoachProfileScreen`
- Toolbar "My Coaches" → `SubscribedCoachesScreen`

---

### 2. Coach Profile Screen (ML-1)

**Route**: `/coaches/:id`  
**Provider**: `coachProfileProvider(coachId)`

Uses the new `GET /user/coaches/:coachId` endpoint (ML-1) for extended data.

**Sections**:
- Header (avatar, name, email, verified badge)
- Subscribe/Unsubscribe button (server-enforced ML-2 + ML-5)
- About (bio)
- Stats row (experience, certifications count)
- Specialties badges
- Certifications list
- Awards list
- Social links (clickable, auto-detected icons)
- Member since date

**Subscription flow**:
```
[User taps Subscribe]
  → POST /user/coaches/:coachId
  → Server checks:
    - ML-2: User has active platform subscription? (403 if not)
    - ML-5: Coach accepting? At capacity? (409 if not)
  → Success: Toast + list update
  → Failure: Descriptive error toast
```

**Unsubscription flow**:
```
[User taps Unsubscribe]
  → Confirm sheet
  → DELETE /user/coaches/:coachId
  → Success: Toast + list update
```

---

### 3. Subscribed Coaches Screen

**Route**: `/coaches/subscribed`  
**Provider**: `subscribedCoachesProvider`

- Lists coaches the user is subscribed to
- Each card shows: avatar, name, specialties, subscription date
- Unsubscribe via popup menu (with confirmation)
- Pull-to-refresh + pagination
- Empty state links to discovery

---

### 4. Coach Roster Screen (ML-4)

**Route**: `/coach/roster`  
**Provider**: `coachRosterProvider`

Displays subscribed clients with the new `subscriptionExpiresAt` field (ML-4).

**Key features**:
- Stats header (total clients, expiring count)
- Clients sorted: expiring-soon first, then by join date
- Expiry badges: `Expired` (red), `Xd left` (yellow if ≤7d, green otherwise)
- Warning border on cards for expiring-soon clients
- AppBar badge showing expiring count
- Remove client via popup menu (with confirmation)

**Navigation**:
- Tapping a client → `ClientAssignmentsScreen` (pre-existing)
- Empty state → `CoachSettingsScreen`

---

### 5. Coach Settings Screen (ML-5)

**Route**: `/coach/settings`  
**Provider**: `coachSettingsProvider`

**Controls**:
| Setting | UI Control | Description |
|---------|-----------|-------------|
| `acceptingClients` | Toggle switch | Pause/resume new client intake |
| `isDiscoverable` | Toggle switch | Show/hide in public search |
| `maxClients` | Slider (1–200) | Hard cap on client count |

**Quick actions**: Preset buttons for 20, 40, 100 max clients.

**All changes are persisted immediately** via `PATCH /coach/settings` — no save button needed. Toast on failure only.

---

## Design Patterns Used

- **ConsumerStatefulWidget** with `Future.microtask` in `initState` for initial data load
- **Sealed state classes** via switch expressions for exhaustive UI state handling
- **Pull-to-refresh** on all list screens
- **Infinite scroll** via loading sentinel at list end
- **AppToast** for all feedback (success/error)
- **AppCard.interactive** for tappable list items
- **showAppConfirmSheet** for all destructive actions
- **PopupMenuButton** for card-level actions
- **isDark** flag throughout for proper dark/light mode support
- **AppColors** tokens from design system (never hardcoded colors)

---

## Usage Examples

### Navigate to Coach Discovery

```dart
context.push(AppRoutes.discoverCoaches);
```

### Navigate to Coach Profile

```dart
context.push(AppRoutes.coachProfile.replaceFirst(':id', coachId));
```

### Navigate to Coach Roster

```dart
context.push(AppRoutes.coachRoster);
```

### Navigate to Coach Settings

```dart
context.push(AppRoutes.coachSettings);
```

---

## Missing Links Resolution

| ML | What | Resolution |
|----|------|-----------|
| **ML-1** | Single coach profile endpoint | `CoachProfileScreen` uses `GET /user/coaches/:coachId` via `coachProfileProvider` |
| **ML-2** | `requireSubscription()` on subscribe route | Server returns 403 → `CoachProfileScreen` shows descriptive error toast |
| **ML-3** | Webhook evicts clients on EXPIRED/REVOKED | Server-side only — `CoachRosterScreen` auto-refreshes on pull-to-refresh |
| **ML-4** | Roster surfaces `subscriptionExpiresAt` | `CoachRosterScreen` displays expiry badges, highlights expiring clients |
| **ML-5** | `CoachSettings` model + capacity enforcement | `CoachSettingsScreen` provides full CRUD for max clients, intake toggle, discoverability |

---

## Required After Changes

```bash
# Regenerate provider code (if any provider files were changed)
fvm dart run build_runner build --delete-conflicting-outputs
```

> **Note**: No new providers were created in this change — only screens. The generated `.g.dart` files for providers were created in the previous data layer work. However, the router provider itself uses `@Riverpod` annotation, so `build_runner` should be run to ensure `router_provider.g.dart` is up to date.
