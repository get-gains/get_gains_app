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
| **Profile Provider** | ✅ Complete | Fetches user data from API |
| **Profile Repository** | ❌ Not Created | API calls handled directly in provider |
| **Edit Profile Screen** | 🔮 Not Implemented | Planned for future |
| **Edit Profile Provider** | 🔮 Not Implemented | Planned for future |
| **Avatar Upload** | 🔮 Not Implemented | Planned for future |
| **Stats Integration** | 🔮 Not Implemented | Placeholder UI exists |
| **Achievements System** | 🔮 Not Implemented | Placeholder UI exists |

---

## Architecture

### File Structure

```
lib/features/profile/
├── profile.dart                          # Feature barrel export
└── presentation/
    ├── presentation.dart                 # Presentation layer export
    ├── providers/
    │   ├── profile_provider.dart         # Profile data fetching
    │   └── profile_provider.g.dart       # Generated provider code
    └── screens/
        └── profile_screen.dart           # Profile display UI
```

### Missing Components (To Be Created)

```
lib/features/profile/
├── data/                                 # Data layer (recommended)
│   ├── data.dart
│   ├── models/
│   │   └── profile_update_request.dart  # Edit request model
│   └── profile_repository.dart          # Data access abstraction
└── presentation/
    ├── providers/
    │   └── edit_profile_provider.dart   # Edit state management
    └── screens/
        └── edit_profile_screen.dart     # Edit profile UI
```

### Architecture Patterns

Following the [simplified clean architecture](../CONTEXT.md#architecture-overview) approach:

1. **Provider Layer**: State management with Riverpod
2. **Screen Layer**: UI widgets and user interaction
3. **API Layer**: HTTP communication via shared ApiClient
4. **Repository Layer**: (Recommended) Abstract data access for testability

**Current Implementation Note**: The feature currently bypasses the repository pattern and calls ApiClient directly from the provider. This works but is not ideal for:
- Unit testing (harder to mock)
- Separation of concerns
- Reusability across multiple providers

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

**Note**: This model is shared with the auth feature. The profile feature does not define separate models currently. When editing is implemented, consider creating a `ProfileUpdateRequest` model.

---

## Providers

### ProfileProvider

**Location**: `lib/features/profile/presentation/providers/profile_provider.dart`

```dart
@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  @override
  Future<UserModel> build() async {
    final apiClient = ref.watch(apiClientProvider);
    final result = await apiClient.get<Map<String, dynamic>>(
      ApiConstants.userProfile, // '/users/profile'
    );
    return result.when(
      success: (data) {
        final userMap = data['user'] as Map<String, dynamic>? ?? data;
        AppLogger.debug('Profile loaded', tag: 'Profile');
        return UserModel.fromJson(userMap);
      },
      failure: (error) {
        AppLogger.error('Profile load failed', tag: 'Profile', error: error);
        throw Exception(error.message);
      },
    );
  }
}
```

**Provider Type**: `AsyncNotifier` (stateful async provider)

**Lifecycle**: `keepAlive: true` - remains in memory after first load

**Usage**:

```dart
// Watch profile data (rebuilds on change)
final profileAsync = ref.watch(profileProvider);

// Handle states
profileAsync.when(
  data: (user) => Text(user.name),
  loading: () => CircularProgressIndicator(),
  error: (error, stackTrace) => Text('Error: $error'),
);

// Refresh profile data
ref.invalidate(profileProvider);
// or
ref.refresh(profileProvider.future);
```

**Dependencies**:
- `apiClientProvider` - HTTP client for API calls
- `ApiConstants.userProfile` - Endpoint path constant

**State Management**:
- Automatically caches successful API response
- Persists across navigation (keepAlive)
- Provides built-in loading/error states

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

### Phase 1: Profile Editing

**Status**: 🔮 Not Implemented

**Description**: Allow users to edit their name and nickname.

**Components to Add**:

1. **Edit Profile Screen** (`edit_profile_screen.dart`)
   - Text fields for name and nickname
   - Form validation
   - Save button
   - Cancel button

2. **Edit Profile Provider** (`edit_profile_provider.dart`)
   - State management for edit form
   - API integration for PATCH /users/profile
   - Success/error handling

3. **Profile Update Request Model** (`profile_update_request.dart`)
   - Freezed model for API request payload

4. **Profile Repository** (`profile_repository.dart`)
   - Abstract data operations
   - `getProfile()` method
   - `updateProfile()` method

**Server API** (Already Implemented):

```typescript
// PATCH /api/users/profile
// Body: { name?: string, nickname?: string }
// Response: { data: { user: {...} }, errors: [] }
```

**UI Flow**:

```
User on ProfileScreen
  ↓
Taps "Edit" button (to be added)
  ↓
Navigates to EditProfileScreen
  ↓
Form displays with current name/nickname
  ↓
User edits fields
  ↓
Taps "Save"
  ↓
EditProfileProvider calls updateProfile()
  ↓
API: PATCH /users/profile
  ↓
[Success] Navigate back to ProfileScreen
  ↓
ProfileProvider invalidated (refetches data)
  ↓
Updated profile displayed
```

### Phase 2: Avatar Upload

**Status**: 🔮 Not Implemented

**Description**: Allow users to upload and update their profile avatar.

**Backend Changes Required**:
- Add `avatarUrl` field to Prisma User model (already in UserProfile)
- Add file upload endpoint
- Add avatar storage (S3, Cloudinary, etc.)

**Components to Add**:
- Avatar picker widget
- Image cropper
- Upload progress indicator
- Avatar display in profile screen

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

**Status**: 🔮 Not Implemented

**Description**: Add more detailed user profile information.

**Fields to Add** (from UserProfile in schema.prisma):
- Bio
- Height/Weight
- Date of Birth
- Sex
- Equipment Available
- Injury History
- Experience Level
- Days Available
- Session Duration Preference

**UI Considerations**:
- Multi-page edit form or tabs
- Unit preference toggle (metric/imperial)
- Equipment selector (multi-select)
- Experience level picker

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
├── profile.dart
└── presentation/
    ├── presentation.dart
    ├── providers/
    │   └── profile_provider.dart
    └── screens/
        └── profile_screen.dart
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
// Watch profile
final profileAsync = ref.watch(profileProvider);

// Refresh profile
ref.invalidate(profileProvider);
ref.refresh(profileProvider.future);

// Read profile value (no rebuild)
final user = ref.read(profileProvider).value;
```

### Navigation

```dart
// Navigate to profile
context.push(AppRoutes.profile);

// From profile back to home
context.pop();
```

---

*Last updated: February 14, 2026*
