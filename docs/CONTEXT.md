# Get Gains App - Project Context

> **For AI Agents**: This document provides complete architectural context for the Get Gains Flutter application. Read this first before making changes.

## Quick Reference

| Aspect | Value |
|--------|-------|
| **Framework** | Flutter 3.x with Dart SDK ^3.9.0 |
| **State Management** | Riverpod 3.x (riverpod_annotation + riverpod_generator) |
| **Local Database** | Drift 2.x (SQLite) |
| **User Preferences** | Hive 2.x (NoSQL key-value storage) |
| **HTTP Client** | Dio 5.x |
| **Routing** | go_router 17.x |
| **Models** | freezed + json_serializable |
| **Secure Storage** | flutter_secure_storage (JWT tokens) |
| **Backend** | Express.js (separate repo) - JWT auth |
| **FVM** | Flutter Version Management, Stable |

---

## Architecture Overview

This project follows a **simplified clean architecture** with **Riverpod** as the central state management solution.

```
lib/
├── core/                    # App-wide utilities and configuration
│   ├── constants/           # API endpoints, storage keys, app config
│   ├── utils/               # Logger, Result type, AppError, extensions
│   └── theme/               # AppTheme, AppColors, AppTextStyles
├── models/                  # Data models (freezed + json_serializable)
├── providers/               # Riverpod providers (state management)
├── repositories/            # Data access layer (abstracts data sources)
├── services/
│   ├── api/                 # Dio HTTP client + interceptors
│   ├── database/            # Drift SQLite setup
│   ├── storage/             # Secure storage for tokens
│   └── sync/                # Local/remote sync logic
├── features/                # Feature modules (when needed)
│   └── [feature]/
│       ├── data/            # Models, datasources, repositories
│       ├── presentation/    # Screens, widgets, providers
│       └── services/        # Feature-specific services
├── widgets/                 # Shared widgets
└── main.dart                # App entry point with ProviderScope
```

---

## Essential Commands

### When using FLUTTER/DART commands

```bash
# Always USE the fvm prefix
fvm flutter
fvm dart
```


### Code Generation (REQUIRED after model/provider changes)

```bash
# Generate all code (freezed, json_serializable, riverpod, drift)
fvm dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on save)
fvm dart run build_runner watch --delete-conflicting-outputs
```

### Drift Database Commands

```bash
# Generate database code
fvm dart run build_runner build --delete-conflicting-outputs

# Generate migration (after schema changes)
# 1. Increment schemaVersion in app_database.dart
# 2. Add migration logic in migration strategy
# 3. Run build_runner
```

### Flutter Commands

```bash
# Get dependencies
fvm flutter pub get

# Run app
fvm flutter run

# Build APK
fvm flutter build apk --release

# Analyze code
fvm flutter analyze
```

---

## Key Implementation Patterns

### 1. Creating Riverpod Providers

All providers use `riverpod_annotation` for code generation:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'my_provider.g.dart';

// Simple provider
@riverpod
String greeting(GreetingRef ref) => 'Hello';

// Provider with keepAlive (singleton services)
@Riverpod(keepAlive: true)
MyService myService(MyServiceRef ref) => MyService();

// Notifier (stateful)
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;
  
  void increment() => state++;
}

// Async notifier
@riverpod
class UserData extends _$UserData {
  @override
  Future<User> build() async {
    return await ref.read(apiClientProvider).get('/user');
  }
}
```

### 2. Creating Models (freezed + json_serializable)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user_model.freezed.dart';
part 'user_model.g.dart';

// NOTE: In freezed 3.x, classes MUST be declared as 'abstract'
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? name,
    @Default(false) bool isActive,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
}
```

### 3. Server Response Format

The server always returns responses in a standard format:

```json
// Success response
{
  "data": { "user": { "id": "123", "email": "user@example.com" } },
  "errors": []
}

// Error response  
{
  "data": null,
  "errors": [{ "field": "email", "message": "Email already exists" }]
}
```

**The ApiClient automatically handles this format:**
- On success: Returns the unwrapped `data` field
- On error: Parses `errors` array and returns appropriate `AppError`

### 4. Making API Calls

```dart
// Use the ApiClient for all HTTP requests
// The response is already unwrapped from { data, errors } format
final result = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
  '/auth/register',
  data: {'email': 'user@example.com', 'password': '...'},
);

result.when(
  success: (data) {
    // 'data' is already the unwrapped content (e.g., { user: {...} })
    final user = UserModel.fromJson(data['user']);
    print(user.email);
  },
  failure: (error) {
    // Error message is parsed from { errors: [...] }
    print(error.message);
  },
);
```

### 5. Using Result Type (Error Handling)

```dart
Future<Result<User, AppError>> getUser(String id) async {
  final result = await apiClient.get<Map<String, dynamic>>('/users/$id');
  
  return result.when(
    success: (data) => Success(User.fromJson(data['user'])),
    failure: (error) => Failure(error),
  );
}

// Consuming
final result = await repository.getUser('123');
result.when(
  success: (user) => print(user.name),
  failure: (error) => print(error.message),
);
```

### 6. Database Operations (Drift)

```dart
// Add table in app_database.dart
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // ... more columns
}

// Add to @DriftDatabase annotation
@DriftDatabase(tables: [Users, SyncQueue, Workouts])

// Run build_runner, then use:
final db = ref.read(appDatabaseProvider);
await db.into(db.workouts).insert(WorkoutsCompanion.insert(name: 'Leg Day'));
```

### 7. Secure Storage (JWT Tokens)

```dart
final storage = ref.read(secureStorageServiceProvider);

// Save tokens after login
await storage.saveTokens(
  accessToken: response.accessToken,
  refreshToken: response.refreshToken,
  expiry: DateTime.now().add(Duration(hours: 1)),
);

// Tokens auto-attached to requests via AuthInterceptor
// Token refresh handled automatically on 401
```

### 8. User Preferences (Hive)

Hive is used for non-sensitive user data caching (faster than SharedPreferences).

```dart
// Initialization in main.dart
final userPrefsBox = await UserPreferencesService.init();
runApp(
  ProviderScope(
    overrides: [userPrefsBoxProvider.overrideWithValue(userPrefsBox)],
    child: const GetGainsApp(),
  ),
);

// Usage via UserPreferencesService
final prefs = ref.read(userPreferencesServiceProvider);

// Cache user for offline access
await prefs.cacheUser(user);
final cachedUser = await prefs.getCachedUser();

// Login preferences
await prefs.setLastLoginMethod(LoginMethod.google);
final method = prefs.getLastLoginMethod();
```

### 9. Navigation

```dart
// Navigate
context.go(AppRoutes.home);
context.push(AppRoutes.profile);
context.pop();

// With parameters
context.go('/workout/${workout.id}');
```

---

## File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Models | `snake_case.dart` | `user_model.dart` |
| Providers | `*_provider.dart` | `auth_state_provider.dart` |
| Screens | `*_screen.dart` | `login_screen.dart` |
| Widgets | `snake_case.dart` | `gradient_button.dart` |
| Services | `*_service.dart` | `sync_service.dart` |
| Repositories | `*_repository.dart` | `workout_repository.dart` |
| Generated | `*.g.dart`, `*.freezed.dart` | `user_model.g.dart` |

---

## Core Services Reference

### SecureStorageService
Location: `lib/services/storage/secure_storage_service.dart`

```dart
// Key methods
saveTokens(accessToken, refreshToken, expiry)
getAccessToken() → String?
getRefreshToken() → String?
isAuthenticated() → bool
clearTokens()
```

### ApiClient  
Location: `lib/services/api/api_client.dart`

```dart
// HTTP methods - all return Result<T, AppError>
get<T>(path, {queryParameters})
post<T>(path, {data, queryParameters})
put<T>(path, {data})
patch<T>(path, {data})
delete<T>(path)
uploadFile<T>(path, {filePath, fieldName})
```

### AppDatabase
Location: `lib/services/database/app_database.dart`

```dart
// Access via provider
final db = ref.read(appDatabaseProvider);

// CRUD operations available for each table
// See table-specific methods in the file
```

### SyncService
Location: `lib/services/sync/sync_service.dart`

```dart
// Queue local changes for sync
await syncService.queueChange(
  tableName: 'workouts',
  recordId: '123',
  operation: SyncOperation.create,
  payload: {...},
);

// Process pending sync queue
await syncService.processQueue();
```

---

## Error Types

All errors extend `AppError` from `lib/core/utils/app_error.dart`:

- `NetworkError` - API/connectivity issues
- `DatabaseError` - SQLite/Drift errors
- `AuthError` - Authentication failures
- `ValidationError` - Form/data validation
- `CacheError` - Storage errors
- `UnknownError` - Unexpected errors

---

## Authentication Flow

1. User enters credentials → `AuthRepository.login()`
2. API returns JWT tokens → stored via `SecureStorageService`
3. `AuthStateNotifier` updates to `authenticated`
4. `AuthInterceptor` auto-attaches token to requests
5. On 401 → interceptor attempts token refresh
6. If refresh fails → `AuthStateNotifier.onAuthFailure()` → logout

---

## Adding a New Feature Checklist

1. [ ] Create feature folder under `lib/features/[feature_name]/`
2. [ ] Create models in `data/models/` with freezed annotations
3. [ ] Create repository in `data/repositories/`
4. [ ] Create providers in `presentation/providers/`
5. [ ] Create screens in `presentation/screens/`
6. [ ] Add routes in `lib/providers/router_provider.dart`
7. [ ] Run `dart run build_runner build --delete-conflicting-outputs`
8. [ ] Add database tables if needed (then run build_runner again)

---

## Dependencies Summary

```yaml
# State Management
flutter_riverpod: ^3.0.3
riverpod_annotation: ^3.0.3

# Models & Serialization
freezed_annotation: ^3.1.0
json_annotation: ^4.9.0

# Networking
dio: ^5.9.0

# Local Database
drift: ^2.29.0
sqlite3_flutter_libs: ^0.5.41
path_provider: ^2.1.5

# User Preferences (NoSQL)
hive: ^2.2.3
hive_flutter: ^1.1.0

# Routing
go_router: ^17.0.1

# Security
flutter_secure_storage: ^10.0.0

# Utilities
equatable: ^2.0.8

# Dev Dependencies (code generation)
build_runner: ^2.7.1
freezed: ^3.2.3
json_serializable: ^6.11.2
riverpod_generator: ^3.0.3
drift_dev: ^2.29.0
```

---

## Common Gotchas

1. **Always run build_runner** after modifying:
   - Any file with `@riverpod`, `@freezed`, or `@JsonSerializable`
   - Drift table definitions

2. **Freezed 3.x requires abstract classes**: All freezed model classes must be declared as `abstract class`. Custom factory methods should be moved to static extension methods (e.g., `MyModelX.fromApiResponse()`).

3. **Provider scope**: Use `keepAlive: true` for singleton services (database, storage, api client)

4. **Token refresh**: Handled automatically by `AuthInterceptor` - don't implement manually

5. **Result type**: Use `when()` for exhaustive handling, `valueOrNull` for quick access

6. **Database migrations**: Increment `schemaVersion` and add migration logic before deploying

7. **Query parameters are always strings in URLs** — the server's `validateRequest` middleware
   now correctly coerces URL query strings into their proper types (booleans, numbers, dates)
   via Zod before they reach controllers. The Flutter app sends query parameters as plain strings
   (standard HTTP behaviour) and does **not** need to change. Boolean flags like
   `?includeInactive=false` and pagination like `?limit=20&offset=0` will be interpreted
   correctly by the server. Do not attempt to serialize booleans or numbers specially on the
   app side.

8. **Multipart/form-data: always send numeric fields as strings** — when building
   `FormData` for multipart endpoints (e.g. profile create/update), convert all numeric
   values (`double`, `int`) to strings using `.toString()`. This is the standard
   HTTP multipart behaviour and avoids floating-point precision loss in transport.
   The server's Zod schemas use `z.preprocess(toNumber, z.number())` to coerce them
   back before they reach Prisma. Never attempt to embed raw Dart numbers inside
   `FormData` map values.

9. **FormData cannot be retried** — Dio's `FormData` is finalized (streams consumed)
   after the first send. The `RetryInterceptor` automatically skips retry for any
   request whose `data` is a `FormData` instance. If a multipart request fails with
   a transient error, the caller is responsible for rebuilding `FormData` and
   re-issuing the request (not relying on automatic retry).

---

## Contact / Resources

- Flutter docs: https://flutter.dev/docs
- Riverpod docs: https://riverpod.dev
- Drift docs: https://drift.simonbinder.eu
- go_router: https://pub.dev/packages/go_router
