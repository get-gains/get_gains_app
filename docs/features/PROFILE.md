# User Profile - Feature Documentation

> **Purpose**: Complete documentation for the user profile viewing and editing feature in the Get Gains Flutter application.

---

## Table of Contents

1. [Overview](#overview)
2. [Feature Status](#feature-status)
3. [Architecture](#architecture)
4. [Data Models](#data-models)
5. [Providers](#providers)
6. [Screens & UI](#screens--ui)
7. [API Integration](#api-integration)
8. [User Flows](#user-flows)
9. [Error Handling](#error-handling)
10. [Testing Considerations](#testing-considerations)
11. [Future Enhancements](#future-enhancements)

---

## Overview

The Profile feature allows users to view and manage their personal information within the Get Gains app. It provides a centralized location for users to review their account details, view stats, track achievements, and sign out.

### Current Capabilities

- ✅ **Profile Viewing**: Display user information (name, nickname, email, member since)
- ✅ **Pull-to-Refresh**: Refresh profile data from server
- ✅ **Stats Display**: Placeholder sections for workouts and streaks (future implementation)
- ✅ **Achievements Grid**: Visual achievement badges (placeholder data)
- ✅ **Sign Out**: Logout functionality with redirect to login screen
- ⚠️ **Profile Editing**: NOT YET IMPLEMENTED (see [Future Enhancements](#future-enhancements))

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| State Management | Riverpod 3.x (`@riverpod` annotation) | Profile data fetching & caching |
| HTTP Client | Dio 5.x via ApiClient | Server communication |
| Navigation | go_router 17.x | Screen routing |
| UI Framework | Flutter Material Design | Native UI components |
| Date Formatting | intl package | Member since date display |

---

## Feature Status

| Component | Status | Notes |
|-----------|--------|-------|
| **Profile Screen** | ✅ Complete | Display-only, no editing |
| **Account Profile Provider** | ✅ Complete | Fetches `UserModel` from API |
| **Fitness Profile Data Layer** | ✅ Complete | Models, repository, providers with offline caching |
| **Fitness Profile Provider** | ✅ Complete | Async notifier with create/update/refresh/clear |
| **Fitness Profile Repository** | ✅ Complete | Multipart upload, network-first with local fallback |
| **Avatar Upload (Data Layer)** | ✅ Complete | Multipart form-data via repository |
| **Connectivity Service** | ✅ Complete | Reactive online/offline monitoring |
| **Offline Profile Display** | ✅ Complete | Hive-backed local cache fallback |
| **Online-only Edit Guard** | ✅ Complete | `canEditProfileProvider` gates mutations |
| **Edit Profile Screen** | 🔮 Not Implemented | Presentation layer planned |
| **Stats Integration** | 🔮 Not Implemented | Placeholder UI exists |
| **Achievements System** | 🔮 Not Implemented | Placeholder UI exists |

---

## Architecture

### File Structure

```
lib/features/profile/
├── profile.dart                          # Feature barrel export
├── data/
│   ├── data.dart                         # Data layer barrel export
│   ├── models/
│   │   ├── models.dart                   # Models barrel export
│   │   ├── user_profile_model.dart       # Freezed model (Sex, ExperienceLevel, UserProfileModel)
│   │   ├── profile_request_models.dart   # Create & Update request models
│   │   └── *.freezed.dart / *.g.dart     # Generated code
│   └── user_profile_repository.dart      # Network-first repo with local cache + multipart upload
└── presentation/
    ├── presentation.dart                 # Presentation layer export
    ├── providers/
    │   ├── profile_provider.dart         # Account-level UserModel fetching
    │   ├── user_profile_provider.dart    # Fitness profile notifier + derived providers
    │   └── *.g.dart                      # Generated provider code
    └── screens/
        └── profile_screen.dart           # Profile display UI

lib/services/connectivity/
└── connectivity_service.dart             # ConnectivityService + isOnlineProvider
```

### Missing Components (To Be Created)

```
lib/features/profile/
└── presentation/
    ├── providers/
    │   └── edit_profile_provider.dart   # Edit form state management (future)
    └── screens/
        ├── edit_profile_screen.dart     # Edit profile UI (future)
        └── onboarding_screen.dart       # Profile onboarding UI (future)
```

### Architecture Patterns

Following the [simplified clean architecture](../CONTEXT.md#architecture-overview) approach:

1. **Model Layer**: Freezed data models + request models
2. **Repository Layer**: Data access abstraction with caching and multipart upload
3. **Provider Layer**: State management with Riverpod async notifiers
4. **Screen Layer**: UI widgets and user interaction (display-only for now)

**Two Profile Concepts**:

| Concept | Provider | Model | API Endpoint | Purpose |
|---|---|---|---|---|
| **Account profile** | `profileProvider` | `UserModel` | `GET /users/profile` | Name, email, nickname |
| **Fitness profile** | `userProfileNotifierProvider` | `UserProfileModel?` | `GET/POST/PATCH /profile` | Bio, avatar, height, weight, equipment, etc. |

**Offline-first Strategy**:
- `UserProfileRepository.getProfile()` fetches from the server first, then falls back to a Hive-cached copy on network failure.
- `createProfile()` and `updateProfile()` are **online-only** — gated behind `ConnectivityService.isConnected()`.
- The `canEditProfileProvider` combines profile-loaded state with connectivity state so the UI can disable edit controls when offline.

---

## Data Models

### UserModel (Shared from Auth Feature)

**Location**: `lib/features/auth/data/models/user_model.dart`

```dart
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    required String nickname,
    required String supabaseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
}
```

**Field Descriptions**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Database user ID (cuid) |
| `email` | String | Yes | User's email address (unique) |
| `name` | String | Yes | Full name (1-100 chars) |
| `nickname` | String | Yes | Display nickname (1-50 chars) |
| `supabaseId` | String | Yes | Supabase auth user ID |
| `createdAt` | DateTime? | No | Account creation timestamp |
| `updatedAt` | DateTime? | No | Last update timestamp |

**Note**: This model is shared with the auth feature and is used by the account-level `profileProvider`.

### UserProfileModel (Fitness Profile)

**Location**: `lib/features/profile/data/models/user_profile_model.dart`

```dart
enum Sex {
  @JsonValue('MALE') male,
  @JsonValue('FEMALE') female,
}

enum ExperienceLevel {
  @JsonValue('BEGINNER') beginner,
  @JsonValue('INTERMEDIATE') intermediate,
  @JsonValue('ADVANCED') advanced,
}

@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String id,
    required String userId,
    String? bio,
    String? avatarUrl,
    double? heightCm,
    double? weightKg,
    String? unitPreference,
    Sex? sex,
    DateTime? dateOfBirth,
    @Default([]) List<String> equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,
    required int daysAvailable,
    required int sessionDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}
```

**Notes**:
- `avatarUrl` is a **presigned URL** generated by the server on each GET. The server stores S3 object keys internally.
- `daysAvailable` and `sessionDurationMinutes` are required by the server during creation and always present in responses.

### CreateUserProfileRequest (Onboarding)

**Location**: `lib/features/profile/data/models/profile_request_models.dart`

```dart
@freezed
abstract class CreateUserProfileRequest with _$CreateUserProfileRequest {
  const factory CreateUserProfileRequest({
    required int daysAvailable,
    required int sessionDurationMinutes,
    String? bio,
    double? heightCm,
    double? weightKg,
    String? unitPreference,
    Sex? sex,
    DateTime? dateOfBirth,
    @Default([]) List<String> equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,
    @JsonKey(includeToJson: false, includeFromJson: false)
    String? avatarFilePath,
  }) = _CreateUserProfileRequest;
}
```

**Key Point**: `avatarFilePath` is excluded from JSON serialisation. The repository uses it to attach the file as a `MultipartFile` in the `multipart/form-data` request.

### UpdateUserProfileRequest (Editing)

```dart
@freezed
abstract class UpdateUserProfileRequest with _$UpdateUserProfileRequest {
  const factory UpdateUserProfileRequest({
    String? bio,
    double? heightCm,
    double? weightKg,
    String? unitPreference,
    Sex? sex,
    DateTime? dateOfBirth,
    List<String>? equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,
    int? daysAvailable,
    int? sessionDurationMinutes,
    @JsonKey(includeToJson: false, includeFromJson: false)
    String? avatarFilePath,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default(false) bool removeAvatar,
  }) = _UpdateUserProfileRequest;
}
```

**Avatar management**:
- Provide `avatarFilePath` → uploads a new avatar (replaces existing).
- Set `removeAvatar: true` → server deletes avatar from S3 without replacement.
- Leave both unset → avatar unchanged.

---

## Repository

### UserProfileRepository

**Location**: `lib/features/profile/data/user_profile_repository.dart`

The repository wraps `/api/profile` endpoints with **multipart upload support** and **local caching**.

**Provider**: `userProfileRepositoryProvider` (keepAlive)

**Dependencies**:
- `apiClientProvider` — HTTP client
- `userPreferencesServiceProvider` — Hive-based local cache

#### Key Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getProfile()` | `Result<UserProfileModel?, AppError>` | Network-first fetch with Hive fallback |
| `getCachedProfile()` | `UserProfileModel?` | Direct local cache read (no network) |
| `createProfile(request)` | `Result<UserProfileModel, AppError>` | Multipart POST, caches result |
| `updateProfile(request)` | `Result<UserProfileModel, AppError>` | Multipart PATCH, caches result |
| `hasProfile()` | `Result<bool, AppError>` | Convenience onboarding check |
| `clearCache()` | `void` | Removes cached profile (call on logout) |

#### Multipart Upload Flow

Both `createProfile` and `updateProfile` build `FormData` internally:

```dart
// Profile fields serialised as form fields
final formData = FormData.fromMap({
  'daysAvailable': '5',
  'sessionDurationMinutes': '60',
  'bio': 'Fitness enthusiast',
  'equipment': '["dumbbells","barbell"]',  // JSON-encoded array
  // ... other non-null fields
});

// Avatar file attached when avatarFilePath is provided
if (avatarFilePath != null) {
  formData.fields.add(MapEntry('avatar', await MultipartFile.fromFile(avatarFilePath)));
}

// Remove avatar flag
if (removeAvatar) {
  formData.fields.add(MapEntry('removeAvatar', 'true'));
}
```

#### Offline-first Caching Flow

```
getProfile() called
  ↓
GET /api/profile (network)
  ├─ Success → cache to Hive → return profile
  └─ Failure → read Hive cache
      ├─ Cache hit → return cached profile
      └─ Cache miss → return original error
```

---

## Providers

### ProfileProvider (Account Level)

**Location**: `lib/features/profile/presentation/providers/profile_provider.dart`

Fetches the `UserModel` (name, email, nickname) from `GET /users/profile`.

**Provider Type**: `AsyncNotifier` (keepAlive)

```dart
final profileAsync = ref.watch(profileProvider);
profileAsync.when(
  data: (user) => Text(user.name),
  loading: () => CircularProgressIndicator(),
  error: (error, stackTrace) => Text('Error: $error'),
);
```

### UserProfileNotifier (Fitness Profile)

**Location**: `lib/features/profile/presentation/providers/user_profile_provider.dart`

Manages the `UserProfileModel?` fitness profile with create/update/refresh/clear operations.

**Provider Type**: `AsyncNotifier<UserProfileModel?>` (keepAlive)

**States**:
- `AsyncLoading` → initial fetch in progress
- `AsyncData(null)` → no profile (onboarding required)
- `AsyncData(UserProfileModel)` → profile exists
- `AsyncError` → network failure with no local cache

#### Key Methods

| Method | Returns | Online Required |
|--------|---------|:---------------:|
| `build()` | `UserProfileModel?` | No (has cache fallback) |
| `createProfile(request)` | `UserProfileModel` | ✅ Yes |
| `updateProfile(request)` | `UserProfileModel` | ✅ Yes |
| `refresh()` | `void` | No (degrades gracefully) |
| `clear()` | `void` | No |

#### Usage

```dart
// Watch fitness profile
final profileAsync = ref.watch(userProfileNotifierProvider);

// Create during onboarding (online only)
await ref.read(userProfileNotifierProvider.notifier).createProfile(
  CreateUserProfileRequest(
    daysAvailable: 5,
    sessionDurationMinutes: 60,
    avatarFilePath: '/path/to/photo.jpg',  // optional
  ),
);

// Update with new avatar (online only)
await ref.read(userProfileNotifierProvider.notifier).updateProfile(
  UpdateUserProfileRequest(
    weightKg: 75.0,
    avatarFilePath: '/path/to/new_photo.jpg',
  ),
);

// Update removing avatar (online only)
await ref.read(userProfileNotifierProvider.notifier).updateProfile(
  UpdateUserProfileRequest(removeAvatar: true),
);

// Clear on logout
ref.read(userProfileNotifierProvider.notifier).clear();
```

### Derived Convenience Providers

| Provider | Type | Description |
|----------|------|-------------|
| `needsOnboardingProvider` | `bool` | `true` when profile is `null` (onboarding required) |
| `isProfileLoadedProvider` | `bool` | `true` when profile fetch completed (regardless of result) |
| `canEditProfileProvider` | `bool` | `true` when profile is loaded **and** device is online |

### Connectivity Providers

**Location**: `lib/services/connectivity/connectivity_service.dart`

| Provider | Type | Description |
|----------|------|-------------|
| `connectivityServiceProvider` | `ConnectivityService` | Singleton service (keepAlive) |
| `isOnlineProvider` | `Stream<bool>` | Reactive connectivity stream |

---

## Screens & UI

### ProfileScreen

**Location**: `lib/features/profile/presentation/screens/profile_screen.dart`

**Purpose**: Display current user profile with pull-to-refresh and error handling.

#### Screen Composition

```
ProfileScreen (ConsumerWidget)
├── Scaffold
    └── SafeArea
        └── RefreshIndicator
            └── profileProvider.when()
                ├── data → _ProfileContent
                ├── loading → _ProfileLoading
                └── error → _ProfileError
```

#### UI Components

##### 1. _ProfileContent

Displays user information in a scrollable layout:

**Sections**:

1. **Header**:
   - Back button
   - "Profile" title

2. **Avatar & Name Block** (Centered):
   - `AppAvatar` (XXL size) - displays initials from name
   - User's full name (headlineSmall, bold)
   - Nickname (titleMedium, muted color)

3. **Info Card** (`AppCard`):
   - Email with envelope icon
   - Member since date with calendar icon (formatted as "Jan 2026")

4. **Stats Card** (Placeholder):
   - Workouts this week: `—`
   - Current streak: `—`
   - Icons: `fitness_center_outlined`, `local_fire_department_outlined`

5. **Achievements Grid**:
   - 3 columns with 6 placeholder achievements
   - Each tile: icon, title, locked state
   - Icons: fitness_center, repeat, calendar_today, etc.

6. **Sign Out Button**:
   - Outlined button with logout icon
   - Red/destructive color scheme
   - Calls `authStateProvider.notifier.logout()`
   - Navigates to login screen on success

**Styling**:

```dart
// Avatar
AppAvatar(
  name: user.name,
  size: AppAvatarSize.xxl, // 96px diameter
)

// Name typography
Theme.of(context).textTheme.headlineSmall?.copyWith(
  fontWeight: FontWeight.bold,
  fontFamily: AppTextStyles.fontFamilySans, // Poppins
)

// Nickname typography
Theme.of(context).textTheme.titleMedium?.copyWith(
  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  fontFamily: AppTextStyles.fontFamilySans,
)

// Card padding
EdgeInsets.all(20) // Standard card padding from design system

// Section spacing
SizedBox(height: 24) // Between major sections

// Info row internal spacing
SizedBox(height: 16) // Between rows in cards
```

##### 2. _ProfileLoading

Centered loading indicator with "Loading profile..." text.

##### 3. _ProfileError

Uses `AppEmptyState.fullPage()` with:
- Icon: `Icons.person_off_outlined`
- Title: "Couldn't load profile"
- Description: Error message
- Action: "Retry" button → invalidates provider

#### Placeholder Data

**Achievements** (`_PlaceholderAchievement`):

```dart
const List<_PlaceholderAchievement> _placeholderAchievements = [
  _PlaceholderAchievement(id: '1', icon: Icons.fitness_center, title: 'First rep', unlocked: false),
  _PlaceholderAchievement(id: '2', icon: Icons.repeat, title: '10 workouts', unlocked: false),
  _PlaceholderAchievement(id: '3', icon: Icons.calendar_today, title: 'Week warrior', unlocked: false),
  _PlaceholderAchievement(id: '4', icon: Icons.wb_sunny_outlined, title: 'Early bird', unlocked: false),
  _PlaceholderAchievement(id: '5', icon: Icons.trending_up, title: 'Strong start', unlocked: false),
  _PlaceholderAchievement(id: '6', icon: Icons.local_fire_department_outlined, title: 'Consistency', unlocked: false),
];
```

All achievements are currently `unlocked: false` (displayed with lock icon and 60% opacity).

**Stats**:
- Workouts this week: Hardcoded `—`
- Current streak: Hardcoded `—`

**TODO**: Replace with API-backed data when backend endpoints are ready.

#### Design System Compliance

Follows [DESIGN_STYLE.md](../DESIGN_STYLE.md):

| Element | Compliance |
|---------|------------|
| Colors | ✅ Uses AppColors tokens (primary, textSecondary, border, etc.) |
| Typography | ✅ Uses AppTextStyles.fontFamilySans (Poppins) |
| Spacing | ✅ Follows 4px base unit (16, 20, 24, 32 spacing) |
| Border Radius | ✅ Cards use 16px radius (radius-lg) |
| Shadows | ✅ AppCard applies appropriate elevation |
| Dark Mode | ✅ Respects theme brightness with isDark checks |

---

## API Integration

### Endpoints Used

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| `GET` | `/users/profile` | Fetch current user profile | Yes (JWT) |

**Base URL**: Configured in `.env` via `API_BASE_URL`

**Full Path**: `{baseUrl}/api/users/profile`

### Request Flow

```
ProfileProvider.build()
  ↓
ref.watch(apiClientProvider)
  ↓
apiClient.get<Map<String, dynamic>>('/users/profile')
  ↓
AuthInterceptor (auto-attaches JWT from SecureStorage)
  ↓
Server: GET /api/users/profile
  ↓
Server Response: { data: { user: {...} }, errors: [] }
  ↓
ApiClient unwraps response (returns data field only)
  ↓
UserModel.fromJson(data['user'])
  ↓
Provider updates state with UserModel
```

### Server Response Format

**Success** (200):

```json
{
  "data": {
    "user": {
      "id": "cm6v8xqz30000hj3r9b8xqz30",
      "email": "john.doe@example.com",
      "name": "John Doe",
      "nickname": "johnd",
      "supabaseId": "123e4567-e89b-12d3-a456-426614174000",
      "createdAt": "2026-01-15T10:30:00.000Z",
      "updatedAt": "2026-02-14T08:45:00.000Z"
    }
  },
  "errors": []
}
```

**Error** (401 Unauthorized):

```json
{
  "data": null,
  "errors": [
    {
      "field": "authentication",
      "message": "Invalid or expired token"
    }
  ]
}
```

**Error** (500 Internal Server Error):

```json
{
  "data": null,
  "errors": [
    {
      "field": "server",
      "message": "Internal server error"
    }
  ]
}
```

### Error Handling

ApiClient automatically:
1. Unwraps `data` field on success
2. Parses `errors` array on failure
3. Returns `Result<T, AppError>`

ProfileProvider:
1. Catches failures via `.when(failure: ...)`
2. Logs error with AppLogger
3. Throws `Exception(error.message)` to propagate to UI

UI Layer:
1. `AsyncValue.error` state triggered
2. `_ProfileError` widget displays error message
3. User can tap "Retry" to invalidate provider and refetch

---

## User Flows

### 1. View Profile (Happy Path)

```
User taps "Profile" in navigation
  ↓
Router navigates to /profile
  ↓
ProfileScreen builds
  ↓
ref.watch(profileProvider) triggered
  ↓
[First load] Provider state: AsyncLoading
  ↓
_ProfileLoading widget displays
  ↓
API call to GET /users/profile
  ↓
[Success] Provider state: AsyncData<UserModel>
  ↓
_ProfileContent widget displays with user data
  ↓
User scrolls and views profile information
```

### 2. Refresh Profile

```
User pulls down on profile screen
  ↓
RefreshIndicator triggers onRefresh callback
  ↓
ref.refresh(profileProvider.future) called
  ↓
Provider re-executes build() method
  ↓
API call to GET /users/profile
  ↓
[Success] UI updates with refreshed data
  ↓
RefreshIndicator completes animation
```

### 3. Profile Load Error

```
ProfileScreen builds
  ↓
ref.watch(profileProvider) triggered
  ↓
API call fails (network error, 401, 500, etc.)
  ↓
Provider state: AsyncError
  ↓
_ProfileError widget displays:
  - "Couldn't load profile"
  - Error message
  - "Retry" button
  ↓
User taps "Retry"
  ↓
ref.invalidate(profileProvider) called
  ↓
Provider re-executes (back to AsyncLoading)
  ↓
[If successful] _ProfileContent displays
[If failed again] _ProfileError displays
```

### 4. Sign Out

```
User scrolls to bottom of profile screen
  ↓
User taps "Sign out" button
  ↓
Consumer calls: await ref.read(authStateProvider.notifier).logout()
  ↓
AuthStateNotifier:
  - Calls secureStorageService.clearTokens()
  - Sets state to AuthState.unauthenticated()
  ↓
Router redirect triggered (authStateProvider changed)
  ↓
User redirected to login screen (/login)
```

### 5. Cached Profile Display

```
User navigates to profile screen (2nd+ time)
  ↓
ProfileProvider already has cached data (keepAlive: true)
  ↓
_ProfileContent displays immediately (no loading state)
  ↓
No API call unless user manually refreshes
```

---

## Error Handling

### Error Types

| Error Type | Cause | Handling |
|------------|-------|----------|
| `NetworkError` | No internet, server unreachable | Display error message, show retry button |
| `AuthError` (401) | Token expired/invalid | Auto-handled by AuthInterceptor (token refresh), or logout if refresh fails |
| `ServerError` (500) | Server internal error | Display generic error, show retry button |
| `UnknownError` | Unexpected exceptions | Display generic error, log to console |

### Error Display

All errors use `_ProfileError` widget:

```dart
_ProfileError(
  message: 'Error message from exception',
  onRetry: () => ref.invalidate(profileProvider),
)
```

Internally uses `AppEmptyState.fullPage()`:
- Large icon (person_off_outlined)
- Primary message: "Couldn't load profile"
- Secondary message: Error details
- Action button: "Retry"

### Logging

All profile operations are logged via `AppLogger`:

```dart
// Success
AppLogger.debug('Profile loaded', tag: 'Profile');

// Error
AppLogger.error('Profile load failed', tag: 'Profile', error: error);
```

Logs include:
- Tag: "Profile" for filtering
- Error object for stack trace
- Contextual information

---

## Testing Considerations

### Unit Testing

**Profile Provider Tests** (to be created):

```dart
// test/features/profile/providers/profile_provider_test.dart

testWidgets('ProfileProvider fetches user successfully', (tester) async {
  // Mock ApiClient
  final mockApiClient = MockApiClient();
  when(mockApiClient.get<Map<String, dynamic>>(any))
      .thenAnswer((_) async => Success({
        'user': {
          'id': '123',
          'email': 'test@example.com',
          'name': 'Test User',
          'nickname': 'tester',
          'supabaseId': 'sb-123',
        }
      }));

  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(mockApiClient),
    ],
  );

  final profile = await container.read(profileProvider.future);

  expect(profile.name, 'Test User');
  expect(profile.email, 'test@example.com');
});

testWidgets('ProfileProvider handles API error', (tester) async {
  final mockApiClient = MockApiClient();
  when(mockApiClient.get<Map<String, dynamic>>(any))
      .thenAnswer((_) async => Failure(NetworkError('Connection timeout')));

  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(mockApiClient),
    ],
  );

  expect(
    () => container.read(profileProvider.future),
    throwsException,
  );
});
```

### Widget Testing

**ProfileScreen Tests** (to be created):

```dart
// test/features/profile/presentation/screens/profile_screen_test.dart

testWidgets('ProfileScreen displays loading state', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith((ref) => AsyncValue.loading()),
      ],
      child: MaterialApp(home: ProfileScreen()),
    ),
  );

  expect(find.text('Loading profile...'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('ProfileScreen displays user data', (tester) async {
  final testUser = UserModel(
    id: '123',
    email: 'test@example.com',
    name: 'Test User',
    nickname: 'tester',
    supabaseId: 'sb-123',
    createdAt: DateTime(2026, 1, 15),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith((ref) => AsyncValue.data(testUser)),
      ],
      child: MaterialApp(home: ProfileScreen()),
    ),
  );

  expect(find.text('Test User'), findsOneWidget);
  expect(find.text('tester'), findsOneWidget);
  expect(find.text('test@example.com'), findsOneWidget);
  expect(find.text('Jan 2026'), findsOneWidget);
});

testWidgets('ProfileScreen handles error state', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(
          (ref) => AsyncValue.error('API Error', StackTrace.current),
        ),
      ],
      child: MaterialApp(home: ProfileScreen()),
    ),
  );

  expect(find.text('Couldn't load profile'), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
});

testWidgets('ProfileScreen retry button invalidates provider', (tester) async {
  // ... test retry button functionality
});

testWidgets('ProfileScreen sign out button logs out user', (tester) async {
  // ... test sign out functionality
});
```

### Integration Testing

**Profile Flow Tests** (to be created):

```dart
// integration_test/profile_test.dart

testWidgets('User can view and refresh profile', (tester) async {
  // 1. Log in user
  // 2. Navigate to profile
  // 3. Verify profile data displayed
  // 4. Pull to refresh
  // 5. Verify API called and UI updated
});

testWidgets('User can sign out from profile', (tester) async {
  // 1. Log in user
  // 2. Navigate to profile
  // 3. Tap sign out button
  // 4. Verify redirected to login
  // 5. Verify tokens cleared
});
```

---

## Future Enhancements

### Phase 1: Profile Editing (Presentation Layer)

**Status**: 🔮 Presentation Not Implemented — **Data layer complete**

**Description**: UI for editing fitness profile fields and account info.

**Data layer already provides**:
- `UserProfileNotifier.updateProfile()` with multipart support
- `canEditProfileProvider` to disable controls when offline
- `UpdateUserProfileRequest` model with all optional fields

**Components to Add**:

1. **Edit Profile Screen** (`edit_profile_screen.dart`)
   - Form fields for all fitness profile data
   - Avatar picker (camera/gallery) → passes `avatarFilePath`
   - "Remove avatar" option → sets `removeAvatar: true`
   - Disable save button when `canEditProfileProvider` is `false`
   - Upload progress indicator

2. **Edit Profile Provider** (`edit_profile_provider.dart`)
   - Form state management (dirty tracking, validation)
   - Calls `userProfileNotifierProvider.notifier.updateProfile()`

**UI Flow**:

```
User on ProfileScreen
  ↓
Taps "Edit" button → check canEditProfileProvider
  ├─ Online → Navigate to EditProfileScreen
  └─ Offline → Show "Editing requires internet" message
  ↓
Form displays with current profile data
  ↓
User edits fields / picks new avatar
  ↓
Taps "Save" (disabled if offline)
  ↓
userProfileNotifier.updateProfile(
  UpdateUserProfileRequest(
    weightKg: 75.0,
    avatarFilePath: pickedFile?.path,
    removeAvatar: wantsToRemove,
  ),
)
  ↓
Multipart PATCH /api/profile
  ↓
[Success] Navigate back, profile updated + cached
[Failure] Show error, form state preserved
```

### Phase 2: Onboarding Screen

**Status**: 🔮 Presentation Not Implemented — **Data layer complete**

**Description**: First-time onboarding flow for new users.

**Data layer already provides**:
- `UserProfileNotifier.createProfile()` with multipart avatar upload
- `needsOnboardingProvider` to detect first-time users
- `CreateUserProfileRequest` with required `daysAvailable` and `sessionDurationMinutes`

**Components to Add**:
- Multi-step onboarding wizard
- Avatar picker for initial profile photo
- Experience level selector
- Equipment multi-select
- Availability picker

### Phase 3: Stats Integration

**Status**: 🔮 Not Implemented

**Description**: Replace placeholder stats with real workout data.

**Backend Changes Required**:
- Workout tracking endpoints (may already exist)
- Stats aggregation endpoint

**Components to Add**:
- Stats provider (fetches workout stats)
- Update ProfileScreen to display real data

**Metrics to Display**:
- Workouts this week (count)
- Current streak (days)
- Total workouts (all-time)
- Favorite exercises (most performed)

### Phase 4: Achievements System

**Status**: 🔮 Not Implemented

**Description**: Implement real achievement tracking and rewards.

**Backend Changes Required**:
- Achievement definitions table
- User achievement progress tracking
- Achievement unlock logic

**Components to Add**:
- Achievement provider
- Achievement detail screen
- Achievement notification system

**Achievement Types**:
- First workout
- Consistency streaks
- Exercise milestones
- Time-based goals

### Phase 5: Additional Profile Fields

**Status**: ✅ Data Layer Complete — Presentation Not Implemented

**Description**: Extended fitness profile fields.

**Already modelled** in `UserProfileModel` and both request models:
- Bio, Height/Weight, Date of Birth, Sex
- Equipment Available, Injury History
- Experience Level, Days Available, Session Duration
- Unit Preference

**Remaining work**: Build UI form fields, pickers, and validation in the edit/onboarding screens (Phase 1 & 2 above).

### Phase 6: Social Features

**Status**: 🔮 Not Implemented

**Description**: Social profile enhancements.

**Features**:
- Public/private profile toggle
- Share workout achievements
- Follow other users
- Activity feed
- Profile badges

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [CONTEXT.md](../CONTEXT.md) | Project architecture and patterns |
| [FEATURE_INDEX.md](../FEATURE_INDEX.md) | Feature navigation hub |
| [DESIGN_STYLE.md](../DESIGN_STYLE.md) | UI design system |
| [REGISTER.md](./REGISTER.md) | Registration feature (similar structure) |
| [Server AUTH.md](../../../get-gains-server/docs/features/AUTH.md) | Server auth endpoints |
| [Server FEATURE_INDEX.md](../../../get-gains-server/docs/FEATURE_INDEX.md) | Server feature list |

---

## Quick Reference

### File Paths

```
lib/features/profile/
├── profile.dart                          # Barrel export
├── data/
│   ├── data.dart
│   ├── models/
│   │   ├── models.dart
│   │   ├── user_profile_model.dart       # UserProfileModel + enums
│   │   └── profile_request_models.dart   # Create/Update request models
│   └── user_profile_repository.dart      # Multipart + caching repository
└── presentation/
    ├── presentation.dart
    ├── providers/
    │   ├── profile_provider.dart         # Account-level UserModel
    │   └── user_profile_provider.dart    # Fitness profile + derived providers
    └── screens/
        └── profile_screen.dart

lib/services/connectivity/
└── connectivity_service.dart             # ConnectivityService + isOnlineProvider
```

### Commands

```bash
# Generate provider code
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Test profile feature (when tests created)
flutter test test/features/profile/
```

### Provider Usage

```dart
// Watch account profile (UserModel)
final profileAsync = ref.watch(profileProvider);

// Watch fitness profile (UserProfileModel?)
final fitnessProfileAsync = ref.watch(userProfileNotifierProvider);

// Check if editing is allowed (profile loaded + online)
final canEdit = ref.watch(canEditProfileProvider);

// Check if onboarding is needed
final needsOnboarding = ref.watch(needsOnboardingProvider);

// Create profile (onboarding)
await ref.read(userProfileNotifierProvider.notifier).createProfile(
  CreateUserProfileRequest(
    daysAvailable: 5,
    sessionDurationMinutes: 60,
    avatarFilePath: '/path/to/avatar.jpg',
  ),
);

// Update profile with new avatar
await ref.read(userProfileNotifierProvider.notifier).updateProfile(
  UpdateUserProfileRequest(weightKg: 75.0, avatarFilePath: pickedPath),
);

// Clear on logout
ref.read(userProfileNotifierProvider.notifier).clear();
```

### Navigation

```dart
// Navigate to profile
context.push(AppRoutes.profile);

// From profile back to home
context.pop();
```

---

*Last updated: February 15, 2026*
