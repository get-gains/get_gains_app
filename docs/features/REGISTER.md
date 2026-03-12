# Auth Feature - Registration

> **Status**: ✅ Data/Services Implemented  
> **Last Updated**: January 27, 2026  
> **Covers**: Email/Password Registration, Google Sign-Up, Offline User Caching

---

## Overview

### Purpose

The Registration feature provides user account creation for the Get Gains application:

- **Email/Password Registration**: Traditional registration with form validation
- **Google Sign-Up**: OAuth-based registration using Google accounts
- **Offline Support**: User data caching for offline access
- **Route Protection**: Auth guards to prevent unauthorized access

### Scope

**This document covers:**
- Email/password registration flow
- Google OAuth sign-up flow (2-step process)
- JWT token management (secure storage)
- User data caching (Hive)
- Route guard configuration
- Password recovery email sending

**Not Included:**
- Login flows (separate feature)
- Password reset (authenticated endpoint)
- Profile editing
- Presentation layer (screens/widgets)

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `google_sign_in` | ^6.2.2 | Google OAuth client |
| `hive` | ^2.2.3 | User data caching (NoSQL) |
| `hive_flutter` | ^1.1.0 | Flutter Hive integration |
| `flutter_secure_storage` | ^10.0.0 | JWT token storage |
| `dio` | ^5.9.0 | HTTP client |
| `riverpod_annotation` | ^3.0.3 | State management |
| `freezed_annotation` | ^3.1.0 | Immutable models |

### Entry Points

| File | Description |
|------|-------------|
| `lib/features/auth/auth.dart` | Feature barrel export |
| `lib/features/auth/data/auth_repository.dart` | Main repository for auth operations |
| `lib/features/auth/presentation/providers/register_provider.dart` | Registration state management |
| `lib/features/auth/services/google_sign_in_service.dart` | Google OAuth service |
| `lib/features/auth/services/user_preferences_service.dart` | Offline user caching |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    RegisterNotifier                              │   │
│  │  - registerWithEmailPassword()                                   │   │
│  │  - signInWithGoogle()                                            │   │
│  │  - completeGoogleSignUp()                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
└──────────────────────────────┼──────────────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      AuthRepository                              │   │
│  │  Coordinates: API calls, token storage, user caching             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│         │                    │                    │                     │
│         ▼                    ▼                    ▼                     │
│  ┌─────────────┐    ┌─────────────────┐   ┌────────────────────┐       │
│  │  ApiClient  │    │ SecureStorage   │   │ UserPreferences    │       │
│  │  (Dio)      │    │ (Tokens)        │   │ (User Cache)       │       │
│  └─────────────┘    └─────────────────┘   └────────────────────┘       │
│         │                                          │                    │
└─────────┼──────────────────────────────────────────┼────────────────────┘
          ▼                                          ▼
┌─────────────────┐                        ┌─────────────────┐
│  Express Server │                        │ Hive            │
│  (Backend API)  │                        │ (Local Storage) │
└─────────────────┘                        └─────────────────┘
```

### Component Relationships

| Component | Depends On | Used By |
|-----------|------------|---------|
| `RegisterNotifier` | AuthRepository, AuthStateNotifier | Presentation screens |
| `AuthRepository` | ApiClient, SecureStorage, UserPrefs, GoogleSignIn | RegisterNotifier |
| `GoogleSignInService` | google_sign_in package | AuthRepository |
| `UserPreferencesService` | hive package | AuthRepository |
| `SecureStorageService` | flutter_secure_storage | AuthRepository, AuthInterceptor |

---

## Request Flows

### Email/Password Registration Flow

```
User fills form
    │
    ▼
┌─────────────────────────┐
│  RegisterNotifier       │
│  registerWithEmail...() │
└─────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│  AuthRepository.registerWithEmailPassword()
│  1. Create RegisterRequest              │
│  2. POST /auth/register                 │
│  3. Parse AuthResponse                  │
│  4. Save tokens (SecureStorage)         │
│  5. Cache user (UserPreferences)        │
│  6. Return Success/Failure              │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────┐
│  AuthStateNotifier      │
│  setAuthenticated()     │
│  → Updates app-wide auth│
└─────────────────────────┘
    │
    ▼
Router redirects to /home
```

### Google Sign-Up Flow (2 Steps)

**Step 1: Google Sign-In**
```
User taps "Sign in with Google"
    │
    ▼
┌─────────────────────────┐
│  RegisterNotifier       │
│  signInWithGoogle()     │
└─────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│  AuthRepository.signInWithGoogle()      │
│  1. GoogleSignInService.signIn()        │
│     → Opens Google OAuth UI             │
│     → Returns idToken                   │
│  2. POST /auth/google (with idToken)    │
│  3. Parse GoogleSignInResponse          │
│  4. Save pending profile (UserPrefs)    │
│  5. Save temp tokens (SecureStorage)    │
│  6. Return Success                      │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  State: RegisterGooglePending   │
│  { email, supabaseId }          │
│  → Show profile completion form │
└─────────────────────────────────┘
```

**Step 2: Complete Profile**
```
User fills name/nickname form
    │
    ▼
┌─────────────────────────┐
│  RegisterNotifier       │
│  completeGoogleSignUp() │
└─────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│  AuthRepository.completeGoogleSignUp()  │
│  1. Get pending profile from UserPrefs  │
│  2. POST /auth/google/link (protected)  │
│  3. Parse user response                 │
│  4. Cache user (UserPreferences)        │
│  5. Clear pending profile               │
│  6. Return AuthResponse                 │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────┐
│  AuthStateNotifier      │
│  setAuthenticated()     │
└─────────────────────────┘
    │
    ▼
Router redirects to /home
```

---

## Implementation Details

### Models

#### UserModel
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    required String nickname,
    required String supabaseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;
}
```

#### RegisterRequest
```dart
@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) = _RegisterRequest;
}
```

#### AuthResponse
```dart
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) = _AuthResponse;
}
```

### Register Provider States

| State | Description |
|-------|-------------|
| `RegisterInitial` | No registration in progress |
| `RegisterLoading` | API call in progress |
| `RegisterSuccess(AuthResponse)` | Registration completed |
| `RegisterGooglePendingProfile` | Google sign-in done, needs profile |
| `RegisterError(AppError)` | Registration failed |

### Key Repository Methods

```dart
// Email/password registration
Future<Result<AuthResponse, AppError>> registerWithEmailPassword({
  required String email,
  required String password,
  required String name,
  required String nickname,
});

// Step 1: Google sign-in
Future<Result<GoogleSignInResponse, AppError>> signInWithGoogle();

// Step 2: Complete Google profile
Future<Result<AuthResponse, AppError>> completeGoogleSignUp({
  required String name,
  required String nickname,
});

// Cancel pending Google sign-up
Future<void> cancelGoogleSignUp();

// Password recovery
Future<Result<void, AppError>> sendRecoveryEmail({required String email});
```

---

## API Reference

### Server Endpoints Used

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `POST` | `/auth/register` | Email/password registration | No |
| `POST` | `/auth/google` | Google sign-in (new user) | No |
| `POST` | `/auth/google/link` | Complete Google profile | Yes |
| `POST` | `/auth/send-recovery-email` | Send recovery email | No |

### Request/Response Examples

**POST /auth/register**

Request:
```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "name": "John Doe",
  "nickname": "johnd"
}
```

Response (201):
```json
{
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "John Doe",
      "nickname": "johnd",
      "supabaseId": "supabase-uuid"
    }
  },
  "errors": []
}
```

**POST /auth/google**

Request:
```json
{
  "idToken": "google-id-token..."
}
```

Response (200):
```json
{
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "user": {
      "email": "user@gmail.com",
      "supabaseId": "supabase-uuid"
    }
  },
  "errors": []
}
```

**POST /auth/google/link** (Protected)

Request:
```json
{
  "email": "user@gmail.com",
  "name": "John Doe",
  "nickname": "johnd",
  "supabaseId": "supabase-uuid"
}
```

---

## Configuration

### Environment Variables

Add to `.env`:
```
API_BASE_URL=http://your-server-url/api
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

> **Important:** `GOOGLE_CLIENT_ID` must be the **Web application** OAuth client ID, NOT the Android client ID.

### Google Cloud Console Setup

For Google Sign-In to work, you need **two** OAuth 2.0 client IDs in the same Google Cloud project:

1. **Web application** client ID → used as `GOOGLE_CLIENT_ID` in `.env` and on the server
2. **Android** client ID → matched automatically by Google Play Services

#### Android OAuth Client Setup

1. Go to [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials)
2. Create an OAuth 2.0 Client ID of type **Android**
3. Set package name: `com.getgains.app`
4. Set SHA-1 certificate fingerprint (get it via Gradle):
   ```bash
   cd android && ./gradlew signingReport
   ```
5. You need to register SHA-1 for **both** debug and release signing keys

> **Common error:** `ApiException: 10` (DEVELOPER_ERROR) means the SHA-1 fingerprint
> or package name doesn't match what's registered in Google Cloud Console.

### iOS Configuration

Update `ios/Runner/Info.plist`:
```xml
<!-- Google Sign-In URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

### Android Configuration

No additional Gradle or manifest changes are needed for `google_sign_in` 6.x on Android.
The plugin uses Google Play Services directly and resolves the Android OAuth client
by matching the app's package name + SHA-1 fingerprint in Google Cloud Console.

---

## Router Guard

### Route Categories

| Category | Routes | Access |
|----------|--------|--------|
| Public | `/login`, `/register`, `/forgot-password` | Anyone |
| Semi-Auth | `/reset-password`, `/complete-profile` | Has temp tokens |
| Protected | `/home`, `/profile`, `/settings`, etc. | Fully authenticated |

### Guard Logic

```dart
redirect: (context, state) {
  final isAuthenticated = authState.isAuthenticated;
  final location = state.uri.path;

  // Public routes accessible without auth
  final isPublicAuthRoute = ['/login', '/register', '/forgot-password']
      .contains(location);

  // Semi-auth routes (need tokens but not full profile)
  final isSemiAuthRoute = ['/reset-password', '/complete-profile']
      .contains(location);

  // Not authenticated → redirect to login
  if (!isAuthenticated && !isPublicAuthRoute && !isSemiAuthRoute) {
    return '/login';
  }

  // Authenticated on public route → redirect to home
  if (isAuthenticated && isPublicAuthRoute) {
    return '/home';
  }

  return null; // No redirect
}
```

---

## Offline Support

### Data Caching Strategy

| Data | Storage | Purpose |
|------|---------|---------|
| JWT Tokens | SecureStorage | API authentication |
| User Profile | Hive | Display offline |
| Pending Google Profile | Hive | Resume incomplete sign-up |
| Login Method | Hive | Remember user preference |

### UserPreferencesService Methods

```dart
// Cache user for offline access
await userPrefs.cacheUser(user);
final cachedUser = await userPrefs.getCachedUser();

// Pending Google profile management
await userPrefs.savePendingGoogleProfile(profile);
final pending = await userPrefs.getPendingGoogleProfile();
await userPrefs.clearPendingGoogleProfile();

// Login preferences
await userPrefs.setLastLoginMethod(LoginMethod.google);
await userPrefs.setIsGoogleUser(true);
```

---

## Error Handling

### Error Types

| Error | Code | Scenario |
|-------|------|----------|
| `AuthError` | `EMAIL_EXISTS` | Email already registered |
| `AuthError` | `INVALID_CREDENTIALS` | Wrong password |
| `AuthError` | `GOOGLE_SIGN_IN_CANCELLED` | User cancelled Google flow |
| `AuthError` | `NO_PENDING_PROFILE` | completeGoogleSignUp without signIn |
| `NetworkError` | `NO_CONNECTION` | No internet |
| `ValidationError` | `VALIDATION_ERROR` | Invalid form data |

### Error Mapping

```dart
AppError _mapToAuthError(AppError error) {
  if (error is NetworkError) {
    switch (error.statusCode) {
      case 401: return AuthError.invalidCredentials();
      case 409: return AuthError(message: 'Email already exists', code: 'EMAIL_EXISTS');
      case 400: return ValidationError(message: error.message);
      default: return error;
    }
  }
  return error;
}
```

---

## Usage Examples

### Email/Password Registration

```dart
class RegisterScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerNotifierProvider);

    ref.listen(registerNotifierProvider, (_, state) {
      if (state is RegisterSuccess) {
        // Router will auto-redirect to /home
      } else if (state is RegisterError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.message)),
        );
      }
    });

    return // ... form UI
  }

  void _onSubmit(WidgetRef ref, FormData data) {
    ref.read(registerNotifierProvider.notifier).registerWithEmailPassword(
      email: data.email,
      password: data.password,
      name: data.name,
      nickname: data.nickname,
    );
  }
}
```

### Google Sign-Up

```dart
// Step 1: Start Google flow
void _onGoogleSignIn(WidgetRef ref) {
  ref.read(registerNotifierProvider.notifier).signInWithGoogle();
}

// Step 2: Handle state change
ref.listen(registerNotifierProvider, (_, state) {
  if (state is RegisterGooglePendingProfile) {
    // Navigate to profile completion screen
    context.go('/complete-profile');
  }
});

// Step 3: Complete profile
void _onCompleteProfile(WidgetRef ref, String name, String nickname) {
  ref.read(registerNotifierProvider.notifier).completeGoogleSignUp(
    name: name,
    nickname: nickname,
  );
}
```

---

## Related Documentation

- [CONTEXT.md](../../docs/CONTEXT.md) - App architecture and patterns
- [AUTH.md (Server)](../../../get-gains-server/docs/features/AUTH.md) - Server auth endpoints
- [SecureStorageService](../../lib/services/storage/secure_storage_service.dart) - Token management
- [AuthStateProvider](../../lib/providers/auth_state_provider.dart) - App-wide auth state

---

## Checklist for Presentation Layer

When implementing the presentation layer, create:

- [ ] `RegisterScreen` - Email/password registration form
- [ ] `CompleteProfileScreen` - Google sign-up profile form
- [ ] `ForgotPasswordScreen` - Password recovery email form
- [ ] Form validation matching server schemas
- [ ] Loading states and error handling UI
- [ ] "Sign in with Google" button

---

*Last updated: January 27, 2026*
