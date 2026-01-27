# Get Gains App - Feature Index

> **Purpose**: Central navigation hub for all Flutter app features and documentation.

---

## Overview

**Get Gains App** is a Flutter mobile application for fitness tracking with offline-first architecture. It syncs with the Get Gains Server backend.

### Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.x | UI framework |
| **Dart SDK** | ^3.9.0 | Programming language |
| **Riverpod** | ^3.0.3 | State management |
| **Drift** | ^2.29.0 | Local SQLite database |
| **Dio** | ^5.9.0 | HTTP client |
| **go_router** | ^17.0.1 | Navigation |
| **flutter_secure_storage** | ^10.0.0 | Secure token storage |
| **google_sign_in** | ^6.2.2 | Google OAuth |
| **hive** | ^2.2.3 | User preferences (NoSQL) |
| **hive_flutter** | ^1.1.0 | Flutter Hive integration |

### Architecture Approach

- **Simplified Clean Architecture** with feature-based organization
- **Riverpod** for dependency injection and state management
- **Offline-first** with local database and sync queue
- **Repository pattern** for data access abstraction

---

## Documentation Structure

| Document | Purpose |
|----------|---------|
| [CONTEXT.md](CONTEXT.md) | Core infrastructure, patterns, conventions |
| [FEATURE_INDEX.md](FEATURE_INDEX.md) | This file - navigation hub |
| [features/REGISTER.md](features/REGISTER.md) | Registration feature documentation |

---

## Feature Categories

### Core Infrastructure *(Documented in [CONTEXT.md](CONTEXT.md))*

| Topic | Description | CONTEXT.md Section |
|-------|-------------|-------------------|
| Project Structure | Folder organization | Architecture Overview |
| Riverpod Providers | State management patterns | Key Implementation Patterns |
| Freezed Models | Immutable data models | Creating Models |
| API Client | Dio HTTP client | Making API Calls |
| Result Type | Error handling | Using Result Type |
| Drift Database | Local SQLite | Database Operations |
| Secure Storage | JWT token management | Secure Storage |
| Navigation | go_router setup | Navigation |

### Authentication & User Management

| Feature | Description | Status | Documentation |
|---------|-------------|--------|---------------|
| Registration | Email/password + Google sign-up | ✅ Data/Services | [features/REGISTER.md](features/REGISTER.md) |
| Login | Email/password + Google login | 🔮 Not Implemented | - |
| Password Reset | Recovery via email | ⚠️ Partial (send email only) | [features/REGISTER.md](features/REGISTER.md) |
| Profile Management | User profile editing | 🔮 Not Implemented | - |

**Primary Files:**
- `/lib/features/auth/auth.dart` - Feature barrel export
- `/lib/features/auth/data/auth_repository.dart` - Auth data operations
- `/lib/features/auth/services/google_sign_in_service.dart` - Google OAuth
- `/lib/features/auth/services/user_preferences_service.dart` - User caching
- `/lib/features/auth/presentation/providers/register_provider.dart` - Registration state
- `/lib/providers/auth_state_provider.dart` - App-wide auth state
- `/lib/providers/router_provider.dart` - Route guards

### Future Domain Features *(Needs Implementation)*

| Feature | Description | Status |
|---------|-------------|--------|
| Workouts | Workout management | 🔮 Not Implemented |
| Exercises | Exercise library | 🔮 Not Implemented |
| Progress Tracking | User progress stats | 🔮 Not Implemented |
| Sync | Offline sync queue | 🔮 Not Implemented |

---

## App Routes Summary

| Route | Screen | Auth Required | Notes |
|-------|--------|---------------|-------|
| `/` | Splash | No | Initial loading |
| `/login` | Login | No | Public |
| `/register` | Register | No | Public |
| `/forgot-password` | Forgot Password | No | Public |
| `/reset-password` | Reset Password | Semi* | Has recovery token |
| `/complete-profile` | Complete Profile | Semi* | Has Google tokens |
| `/home` | Home | Yes | Main screen |
| `/profile` | Profile | Yes | User profile |
| `/settings` | Settings | Yes | App settings |

*Semi-authenticated: Has temporary tokens but not full profile

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

| Looking for... | Go to... |
|----------------|----------|
| Project architecture | [CONTEXT.md](CONTEXT.md) |
| Creating providers | [CONTEXT.md](CONTEXT.md) → Creating Riverpod Providers |
| Data models | [CONTEXT.md](CONTEXT.md) → Creating Models |
| API calls | [CONTEXT.md](CONTEXT.md) → Making API Calls |
| Error handling | [CONTEXT.md](CONTEXT.md) → Using Result Type |
| Registration flow | [features/REGISTER.md](features/REGISTER.md) |
| Google sign-in | [features/REGISTER.md](features/REGISTER.md) → Google Sign-Up Flow |
| Route guards | [features/REGISTER.md](features/REGISTER.md) → Router Guard |
| Server endpoints | [Server AUTH.md](../../get-gains-server/docs/features/AUTH.md) |

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

| Status | Meaning |
|--------|---------|
| ✅ Complete | Full implementation with documentation |
| ✅ Data/Services | Backend ready, needs presentation layer |
| 🚧 Partial | Some implementation exists |
| ⚠️ Needs Docs | Feature exists but undocumented |
| 🔮 Not Implemented | Future feature |

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

*Last updated: January 27, 2026*
