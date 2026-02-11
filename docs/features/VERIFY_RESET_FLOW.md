# Email Verification & Password Reset Flows — Flutter App Implementation

> **Status**: 🔮 Ready for Implementation  
> **Last Updated**: February 11, 2026  
> **Covers**: Deep link setup, email verification screen, forgot password screen, reset password screen, deep link handling  
> **Depends On**: [CONTEXT.md](../CONTEXT.md), [REGISTER.md](REGISTER.md), [Server VERIFY_RESET_FLOW.md](../../get-gains-server/docs/features/VERIFY_RESET_FLOW.md), [Web VERIFY_RESET_FLOW.md](../../get-gains-web/docs/features/VERIFY_RESET_FLOW.md)

---

## Overview

### Purpose

This document details the **Flutter app** changes required to support:

1. **Email Verification Flow** — After registration, user sees a "Check your email" screen. After verifying via the web app deep link, they see a "Verified!" screen and can log in.
2. **Forgot Password Flow** — User taps "Forgot password" on login → enters email → receives reset email → web app deep links back with tokens → app shows reset password form → on success, logout → back to login.

### Current State

| Component | Status | Notes |
|-----------|--------|-------|
| `RegisterNotifier` | ✅ Exists | Has `RegisterEmailVerificationPending` state |
| `PasswordRecoveryNotifier` | ✅ Exists | Has `sendRecoveryEmail()` method |
| `AuthRepository.sendRecoveryEmail()` | ✅ Exists | Calls `POST /auth/send-recovery-email` |
| `ResetPasswordRequest` model | ✅ Exists | Has `accessToken` and `newPassword` fields |
| `AuthRepository.resetPassword()` | ❌ Missing | No method to call `POST /auth/reset-password` |
| `/check-email` route | ✅ Exists | Route exists but screen is already implemented (`CheckEmailScreen`) |
| `/forgot-password` route | ⚠️ Placeholder | Route exists but renders `_PlaceholderScreen` |
| `/reset-password` route | ⚠️ Placeholder | Route exists but renders `_PlaceholderScreen` |
| Deep link handling | ❌ Missing | No `app_links` package, no intent filters, no URL scheme |
| Android Manifest | ❌ No deep link config | No intent filters for `getgains://` scheme |
| iOS Info.plist | ❌ No deep link config | No custom URL scheme for `getgains://` |
| Deep link provider | ❌ Missing | No provider to listen for incoming deep links |

### What Gets Created/Modified

| File | Action | Purpose |
|------|--------|---------|
| `pubspec.yaml` | **Modify** | Add `app_links` package |
| `android/app/src/main/AndroidManifest.xml` | **Modify** | Add deep link intent filter for `getgains://` |
| `ios/Runner/Info.plist` | **Modify** | Add `getgains` URL scheme |
| `lib/core/constants/api_constants.dart` | **Modify** | Add `checkEmailVerified` endpoint |
| `lib/features/auth/data/auth_repository.dart` | **Modify** | Add `resetPassword()` and `checkEmailVerified()` methods |
| `lib/features/auth/data/models/auth_request_models.dart` | **Modify** | Simplify `ResetPasswordRequest` (remove `accessToken` from body) |
| `lib/providers/deep_link_provider.dart` | **Create** | Listen for incoming deep links |
| `lib/providers/router_provider.dart` | **Modify** | Add `/email-verified` route, update redirect logic, handle deep link params |
| `lib/features/auth/presentation/screens/forgot_password_screen.dart` | **Create** | Forgot password email input screen |
| `lib/features/auth/presentation/screens/reset_password_screen.dart` | **Create** | New password + confirm password screen |
| `lib/features/auth/presentation/screens/email_verified_screen.dart` | **Create** | "Email verified!" confirmation screen |
| `lib/features/auth/presentation/providers/reset_password_provider.dart` | **Create** | Reset password state management |

---

## Architecture

### Email Verification Flow (App's Role)

```
┌────────────────────────────────────────────────────────────────────┐
│                    FLUTTER APP: Registration                        │
│                                                                     │
│   1. User registers (POST /auth/register)                          │
│   2. Server returns RegisterResponse (no tokens)                   │
│   3. RegisterNotifier → RegisterEmailVerificationPending state     │
│   4. Router navigates to /check-email?email=user@example.com       │
└────────────────────────────┬───────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                    CHECK EMAIL SCREEN                               │
│                                                                     │
│   "Check your email"                                               │
│   "We sent a verification link to user@example.com"               │
│                                                                     │
│   [ Open Email App ]   ← Opens default email app                  │
│   [ Resend Email ]     ← Calls POST /auth/register again          │
│                          (or a dedicated resend endpoint)           │
│                                                                     │
│   "Already verified? Log in"  ← Navigate to /login                │
│                                                                     │
│   (Optional: polls POST /auth/check-email-verified every 5s)      │
└────────────────────────────────────────────────────────────────────┘
                             │
                    User verifies via email → web app → deep link
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                    DEEP LINK RECEIVED                               │
│                    getgains://auth/email-verified                   │
│                                                                     │
│   DeepLinkProvider captures the link                               │
│   → Router navigates to /email-verified                            │
└────────────────────────────┬───────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                    EMAIL VERIFIED SCREEN                            │
│                                                                     │
│   ✅ "Email Verified!"                                             │
│   "Your email has been verified. You can now log in."              │
│                                                                     │
│   [ Log In ]  ← Navigate to /login                                │
└────────────────────────────────────────────────────────────────────┘
```

### Password Reset Flow (App's Role)

```
┌────────────────────────────────────────────────────────────────────┐
│                    LOGIN SCREEN                                     │
│                                                                     │
│   User taps "Forgot password?"                                     │
│   → Navigate to /forgot-password                                   │
└────────────────────────────┬───────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                    FORGOT PASSWORD SCREEN                           │
│                                                                     │
│   "Reset your password"                                            │
│   [ Email input ]                                                  │
│   [ Send Reset Link ]  ← Calls POST /auth/send-recovery-email     │
│                                                                     │
│   On success:                                                       │
│   → Show "Check your email" message                                │
│   → "We sent a reset link to user@example.com"                    │
│   → [ Back to Login ]                                              │
└────────────────────────────────────────────────────────────────────┘
                             │
                    User clicks reset link in email
                    → Web app exchanges code → deep link
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                    DEEP LINK RECEIVED                               │
│   getgains://auth/reset-password?access_token=xxx&refresh_token=x │
│                                                                     │
│   DeepLinkProvider captures the link                               │
│   → Stores tokens temporarily in SecureStorage                     │
│   → Router navigates to /reset-password                            │
└────────────────────────────┬───────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                    RESET PASSWORD SCREEN                            │
│                                                                     │
│   "Set new password"                                               │
│   [ New Password input ]                                           │
│   [ Confirm Password input ]                                       │
│   [ Reset Password ]                                               │
│                                                                     │
│   On submit:                                                        │
│   1. POST /auth/reset-password                                     │
│      Authorization: Bearer <access_token from deep link>           │
│      Body: { newPassword }                                          │
│   2. On success:                                                    │
│      → Clear all stored tokens (logout)                            │
│      → Show success message                                        │
│      → Navigate to /login                                          │
│   3. On error:                                                      │
│      → Show error message (expired link, etc.)                     │
└────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Steps

### Step 1: Add `app_links` Package

**File**: `pubspec.yaml`

Add to dependencies:

```yaml
dependencies:
  # ... existing dependencies
  app_links: ^6.3.3
```

Then run:
```bash
flutter pub get
```

---

### Step 2: Configure Android Deep Links

**File**: `android/app/src/main/AndroidManifest.xml`

Add an intent filter inside the `<activity>` tag (the main Flutter activity):

```xml
<activity
    android:name=".MainActivity"
    ... existing attributes ... >

    <!-- Existing launcher intent filter -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Deep link intent filter for getgains:// scheme -->
    <intent-filter android:autoVerify="false">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="getgains" />
    </intent-filter>
</activity>
```

---

### Step 3: Configure iOS Deep Links

**File**: `ios/Runner/Info.plist`

Add the `getgains` URL scheme inside the `<dict>` root:

```xml
<!-- Get Gains Deep Link URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
    <!-- Existing Google Sign-In scheme -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
    <!-- Get Gains custom scheme -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.getgains.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>getgains</string>
        </array>
    </dict>
</array>
```

> **Note**: If `CFBundleURLTypes` already exists (for Google Sign-In), add the new `<dict>` entry to the existing `<array>`.

---

### Step 4: Create Deep Link Provider

**File**: `lib/providers/deep_link_provider.dart` (create)

```dart
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/utils/logger.dart';
import '../services/storage/secure_storage_service.dart';

part 'deep_link_provider.g.dart';

/// Deep Link Event
///
/// Represents an incoming deep link with parsed path and query parameters.
class DeepLinkEvent {
  const DeepLinkEvent({
    required this.path,
    this.queryParameters = const {},
  });

  /// The path of the deep link (e.g., '/auth/email-verified')
  final String path;

  /// Query parameters from the deep link URL
  final Map<String, String> queryParameters;

  @override
  String toString() => 'DeepLinkEvent(path: $path, params: $queryParameters)';
}

/// Deep Link Provider
///
/// Listens for incoming deep links and exposes them as a stream.
/// The router watches this provider to handle navigation on deep link events.
///
/// Supported deep links:
/// - getgains://auth/email-verified → Navigate to /email-verified
/// - getgains://auth/reset-password?access_token=xxx&refresh_token=xxx → Store tokens, navigate to /reset-password
@Riverpod(keepAlive: true)
class DeepLinkNotifier extends _$DeepLinkNotifier {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  @override
  DeepLinkEvent? build() {
    _appLinks = AppLinks();

    // Listen for incoming deep links (while app is running)
    _subscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        AppLogger.error('Deep link stream error', tag: 'DeepLink', error: error);
      },
    );

    // Check for initial deep link (app was launched from a deep link)
    _checkInitialLink();

    // Clean up subscription on dispose
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return null;
  }

  /// Check if the app was launched from a deep link
  Future<void> _checkInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.info('Initial deep link: $initialUri', tag: 'DeepLink');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      AppLogger.error('Failed to get initial deep link', tag: 'DeepLink', error: e);
    }
  }

  /// Handle an incoming deep link URI
  Future<void> _handleDeepLink(Uri uri) async {
    AppLogger.info('Deep link received: $uri', tag: 'DeepLink');

    // Parse the deep link
    // URI format: getgains://auth/email-verified
    // URI format: getgains://auth/reset-password?access_token=xxx&refresh_token=xxx
    final path = '/${uri.host}${uri.path}'; // e.g., /auth/email-verified
    final queryParams = uri.queryParameters;

    // If this is a reset password deep link, store the tokens
    if (path == '/auth/reset-password') {
      final accessToken = queryParams['access_token'];
      final refreshToken = queryParams['refresh_token'];

      if (accessToken != null) {
        final secureStorage = ref.read(secureStorageServiceProvider);
        // Store as recovery tokens (separate from regular auth tokens)
        await secureStorage.saveRecoveryToken(accessToken);
        if (refreshToken != null) {
          await secureStorage.saveRecoveryRefreshToken(refreshToken);
        }
        AppLogger.info('Recovery tokens stored from deep link', tag: 'DeepLink');
      }
    }

    state = DeepLinkEvent(
      path: path,
      queryParameters: queryParams,
    );
  }

  /// Clear the current deep link event (after it's been handled)
  void clearDeepLink() {
    state = null;
  }
}
```

---

### Step 5: Update Secure Storage Service

**File**: `lib/services/storage/secure_storage_service.dart`

Add methods for recovery tokens:

```dart
// ============== Recovery Token Methods (Password Reset) ==============

/// Key for storing the recovery access token from deep link
static const String _recoveryTokenKey = 'recovery_access_token';
static const String _recoveryRefreshTokenKey = 'recovery_refresh_token';

/// Save recovery access token (from password reset deep link)
Future<void> saveRecoveryToken(String token) async {
  await write(key: _recoveryTokenKey, value: token);
}

/// Get the stored recovery access token
Future<String?> getRecoveryToken() async {
  return await read(key: _recoveryTokenKey);
}

/// Save recovery refresh token
Future<void> saveRecoveryRefreshToken(String token) async {
  await write(key: _recoveryRefreshTokenKey, value: token);
}

/// Get recovery refresh token
Future<String?> getRecoveryRefreshToken() async {
  return await read(key: _recoveryRefreshTokenKey);
}

/// Clear recovery tokens after password reset is complete
Future<void> clearRecoveryTokens() async {
  await delete(key: _recoveryTokenKey);
  await delete(key: _recoveryRefreshTokenKey);
}
```

---

### Step 6: Update API Constants

**File**: `lib/core/constants/api_constants.dart`

Add new endpoint:

```dart
// Auth Endpoints
static const String checkEmailVerified = '/auth/check-email-verified';
```

---

### Step 7: Update Auth Repository

**File**: `lib/features/auth/data/auth_repository.dart`

Add the `resetPassword()` and `checkEmailVerified()` methods:

```dart
// ============== Password Reset ==============

/// Reset password using recovery access token
///
/// Called after user receives deep link from password reset email.
/// The recovery access token is sent as Bearer token in the Authorization header.
///
/// Server endpoint: POST /auth/reset-password
Future<Result<void, AppError>> resetPassword({
  required String newPassword,
  required String recoveryAccessToken,
}) async {
  AppLogger.debug('Resetting password', tag: 'AuthRepo');

  final result = await _apiClient.post<Map<String, dynamic>>(
    ApiConstants.resetPassword,
    data: {'newPassword': newPassword},
    options: Options(
      headers: {'Authorization': 'Bearer $recoveryAccessToken'},
    ),
  );

  return result.when(
    success: (_) {
      AppLogger.info('Password reset successfully', tag: 'AuthRepo');
      return const Success(null);
    },
    failure: (error) {
      AppLogger.error('Password reset failed', tag: 'AuthRepo', error: error);
      return Failure(_mapToAuthError(error));
    },
  );
}

// ============== Email Verification Status ==============

/// Check if user's email has been verified
///
/// Polls the server to check Supabase email verification status.
/// Used on the "Check Email" screen.
///
/// Server endpoint: POST /auth/check-email-verified
Future<Result<bool, AppError>> checkEmailVerified({
  required String email,
}) async {
  final result = await _apiClient.post<Map<String, dynamic>>(
    ApiConstants.checkEmailVerified,
    data: {'email': email},
  );

  return result.when(
    success: (data) {
      final verified = data['verified'] as bool? ?? false;
      return Success(verified);
    },
    failure: (error) {
      return Failure(_mapToAuthError(error));
    },
  );
}
```

> **Note**: The `resetPassword` method uses `Options` to pass the recovery token as a Bearer token, overriding the default auth interceptor. You'll need to import `package:dio/dio.dart` for `Options`.

---

### Step 8: Update Request Models

**File**: `lib/features/auth/data/models/auth_request_models.dart`

Simplify `ResetPasswordRequest` — remove `accessToken` since it's now sent via header:

```dart
/// Reset Password Request Model
///
/// Used to reset password with recovery token.
/// The recovery access token is sent in the Authorization header, not the body.
@freezed
abstract class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    required String newPassword,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}
```

Then run `dart run build_runner build --delete-conflicting-outputs` to regenerate.

---

### Step 9: Create Reset Password Provider

**File**: `lib/features/auth/presentation/providers/reset_password_provider.dart` (create)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../data/auth_repository.dart';
import '../../../../services/storage/secure_storage_service.dart';

part 'reset_password_provider.g.dart';

/// Reset Password State
sealed class ResetPasswordState {
  const ResetPasswordState();
}

class ResetPasswordInitial extends ResetPasswordState {
  const ResetPasswordInitial();
}

class ResetPasswordLoading extends ResetPasswordState {
  const ResetPasswordLoading();
}

class ResetPasswordSuccess extends ResetPasswordState {
  const ResetPasswordSuccess();
}

class ResetPasswordError extends ResetPasswordState {
  const ResetPasswordError(this.error);
  final AppError error;
}

class ResetPasswordTokenMissing extends ResetPasswordState {
  const ResetPasswordTokenMissing();
}

/// Reset Password Notifier
///
/// Manages the password reset flow after user arrives from deep link.
///
/// Flow:
/// 1. Deep link stores recovery token in SecureStorage
/// 2. User enters new password + confirm password
/// 3. This provider calls POST /auth/reset-password with Bearer token
/// 4. On success: clears all tokens, logs out, navigates to login
///
/// Usage:
/// ```dart
/// ref.read(resetPasswordNotifierProvider.notifier).resetPassword(
///   newPassword: 'NewPass123!',
/// );
/// ```
@riverpod
class ResetPasswordNotifier extends _$ResetPasswordNotifier {
  @override
  ResetPasswordState build() {
    // Check if recovery token exists
    _checkRecoveryToken();
    return const ResetPasswordInitial();
  }

  Future<void> _checkRecoveryToken() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final token = await secureStorage.getRecoveryToken();
    if (token == null) {
      state = const ResetPasswordTokenMissing();
    }
  }

  /// Reset password using the stored recovery token
  Future<void> resetPassword({required String newPassword}) async {
    state = const ResetPasswordLoading();

    final secureStorage = ref.read(secureStorageServiceProvider);
    final recoveryToken = await secureStorage.getRecoveryToken();

    if (recoveryToken == null) {
      state = const ResetPasswordError(
        AuthError(
          message: 'Recovery session expired. Please request a new password reset.',
          code: 'NO_RECOVERY_TOKEN',
        ),
      );
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.resetPassword(
      newPassword: newPassword,
      recoveryAccessToken: recoveryToken,
    );

    result.when(
      success: (_) async {
        AppLogger.info('Password reset successful, logging out', tag: 'ResetPW');

        // Clear recovery tokens
        await secureStorage.clearRecoveryTokens();

        // Logout the user (clear all auth state)
        await ref.read(authStateProvider.notifier).logout();

        state = const ResetPasswordSuccess();
      },
      failure: (error) {
        state = ResetPasswordError(error);
      },
    );
  }
}
```

---

### Step 10: Create Forgot Password Screen

**File**: `lib/features/auth/presentation/screens/forgot_password_screen.dart` (create)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/router_provider.dart';
import '../providers/register_provider.dart';

/// Forgot Password Screen
///
/// Simple screen with email input.
/// Calls POST /auth/send-recovery-email via PasswordRecoveryNotifier.
/// On success, shows confirmation message.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(passwordRecoveryNotifierProvider.notifier)
        .sendRecoveryEmail(email: _emailController.text.trim());

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(passwordRecoveryNotifierProvider);
    final isLoading = recoveryState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent
              ? _buildSuccessState()
              : _buildEmailForm(isLoading),
        ),
      ),
    );
  }

  Widget _buildEmailForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Reset your password',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'your@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : _onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Reset Link'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a password reset link to\n${_emailController.text.trim()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Back to Login'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('Didn\'t receive the email? Try again'),
        ),
      ],
    );
  }
}
```

---

### Step 11: Create Reset Password Screen

**File**: `lib/features/auth/presentation/screens/reset_password_screen.dart` (create)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/router_provider.dart';
import '../providers/reset_password_provider.dart';

/// Reset Password Screen
///
/// Shown after user arrives from deep link with recovery token.
/// Provides new password + confirm password fields.
/// On success, logs out user and redirects to login.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(resetPasswordNotifierProvider.notifier).resetPassword(
          newPassword: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordNotifierProvider);

    // Listen for state changes
    ref.listen(resetPasswordNotifierProvider, (_, next) {
      if (next is ResetPasswordSuccess) {
        // Show success message then navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.login);
      } else if (next is ResetPasswordError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Token missing state
    if (state is ResetPasswordTokenMissing) {
      return _buildTokenMissingState();
    }

    final isLoading = state is ResetPasswordLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Set new password',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your new password below.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),

                // New Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Must contain at least 1 capital letter';
                    }
                    if (!RegExp(r'[!@#$%^&*()_+=\[\]{};:"|,.<>/?`~\\-]')
                        .hasMatch(value)) {
                      return 'Must contain at least 1 special character';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                FilledButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenMissingState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Invalid Reset Link',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This password reset link is invalid or has expired. Please request a new one.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go(AppRoutes.forgotPassword),
                child: const Text('Request New Link'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Step 12: Create Email Verified Screen

**File**: `lib/features/auth/presentation/screens/email_verified_screen.dart` (create)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/router_provider.dart';

/// Email Verified Screen
///
/// Shown after user verifies their email via the web app deep link.
/// Displays a success message and a button to navigate to login.
class EmailVerifiedScreen extends ConsumerWidget {
  const EmailVerifiedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon
              const Icon(
                Icons.verified_outlined,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Email Verified!',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Your email has been successfully verified.\nYou can now log in to your account.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Login Button
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Step 13: Update Router Provider

**File**: `lib/providers/router_provider.dart`

**Changes needed:**

1. Add `/email-verified` route constant
2. Add `/email-verified` to the public routes list
3. Replace placeholder screens with actual screens
4. Listen for deep link events and navigate accordingly
5. Add `emailVerified` route to `AppRoutes`

```dart
/// Route Paths — Add these new routes:
class AppRoutes {
  // ... existing routes ...
  static const String emailVerified = '/email-verified';
}
```

**Update the router's redirect function** to allow `/email-verified` as a public route:

```dart
// Public auth routes (accessible without authentication)
final isPublicAuthRoute =
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.checkEmail ||
    location == AppRoutes.forgotPassword ||
    location == AppRoutes.emailVerified ||  // ← ADD THIS
    location == AppRoutes.unityTest;
```

**Replace placeholder routes** with actual screens:

```dart
// Import the new screens
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/email_verified_screen.dart';

// Replace placeholder routes:
GoRoute(
  path: AppRoutes.forgotPassword,
  builder: (context, state) => const ForgotPasswordScreen(),
),
GoRoute(
  path: AppRoutes.resetPassword,
  builder: (context, state) => const ResetPasswordScreen(),
),
// Add new route:
GoRoute(
  path: AppRoutes.emailVerified,
  builder: (context, state) => const EmailVerifiedScreen(),
),
```

**Add deep link listener** to the router provider:

```dart
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refreshNotifier = _GoRouterRefreshStream(ref);

  // Create router instance first
  late final GoRouter routerInstance;

  routerInstance = GoRouter(
    // ... existing configuration ...
  );

  // Listen for deep links and navigate
  ref.listen(deepLinkNotifierProvider, (previous, next) {
    if (next != null) {
      AppLogger.info('Navigating from deep link: ${next.path}', tag: 'Router');

      switch (next.path) {
        case '/auth/email-verified':
          routerInstance.go(AppRoutes.emailVerified);
          break;
        case '/auth/reset-password':
          routerInstance.go(AppRoutes.resetPassword);
          break;
        default:
          AppLogger.warning('Unknown deep link path: ${next.path}', tag: 'Router');
      }

      // Clear the deep link after handling
      ref.read(deepLinkNotifierProvider.notifier).clearDeepLink();
    }
  });

  return routerInstance;
}
```

---

### Step 14: Update Auth Feature Barrel Export

**File**: `lib/features/auth/auth.dart`

Add exports for new screens:

```dart
// Screens
export 'presentation/screens/forgot_password_screen.dart';
export 'presentation/screens/reset_password_screen.dart';
export 'presentation/screens/email_verified_screen.dart';

// Providers
export 'presentation/providers/reset_password_provider.dart';
```

---

### Step 15: Run Code Generation

After all changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates:
- `deep_link_provider.g.dart`
- `reset_password_provider.g.dart`
- `auth_request_models.freezed.dart` + `auth_request_models.g.dart` (updated `ResetPasswordRequest`)

---

## Updated Route Table

| Route | Screen | Auth Required | Notes |
|-------|--------|---------------|-------|
| `/` | Splash | No | Initial loading |
| `/login` | Login | No | Public |
| `/register` | Register | No | Public |
| `/check-email` | Check Email | No | Public — shows after registration |
| `/email-verified` | Email Verified | No | Public — shows after deep link |
| `/forgot-password` | Forgot Password | No | Public — email input |
| `/reset-password` | Reset Password | Semi* | Has recovery token from deep link |
| `/complete-profile` | Complete Profile | Semi* | Has Google tokens |
| `/home` | Home | Yes | Main screen |
| `/profile` | Profile | Yes | User profile |
| `/settings` | Settings | Yes | App settings |

---

## Deep Link Reference

| Deep Link URL | Handled By | Navigation |
|---------------|------------|------------|
| `getgains://auth/email-verified` | `DeepLinkNotifier` | → `/email-verified` |
| `getgains://auth/reset-password?access_token=xxx&refresh_token=xxx` | `DeepLinkNotifier` | Store tokens → `/reset-password` |

---

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | **Modify** | Add `app_links: ^6.3.3` |
| `android/app/src/main/AndroidManifest.xml` | **Modify** | Add `getgains://` intent filter |
| `ios/Runner/Info.plist` | **Modify** | Add `getgains` URL scheme |
| `lib/core/constants/api_constants.dart` | **Modify** | Add `checkEmailVerified` endpoint |
| `lib/features/auth/data/auth_repository.dart` | **Modify** | Add `resetPassword()`, `checkEmailVerified()` |
| `lib/features/auth/data/models/auth_request_models.dart` | **Modify** | Simplify `ResetPasswordRequest` |
| `lib/services/storage/secure_storage_service.dart` | **Modify** | Add recovery token methods |
| `lib/providers/deep_link_provider.dart` | **Create** | Deep link listener |
| `lib/providers/router_provider.dart` | **Modify** | Add routes, deep link navigation, new imports |
| `lib/features/auth/presentation/screens/forgot_password_screen.dart` | **Create** | Forgot password screen |
| `lib/features/auth/presentation/screens/reset_password_screen.dart` | **Create** | Reset password screen |
| `lib/features/auth/presentation/screens/email_verified_screen.dart` | **Create** | Email verified screen |
| `lib/features/auth/presentation/providers/reset_password_provider.dart` | **Create** | Reset password state management |
| `lib/features/auth/auth.dart` | **Modify** | Export new screens and providers |

---

## Implementation Checklist

### Setup
- [ ] Add `app_links: ^6.3.3` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Configure Android deep link intent filter in `AndroidManifest.xml`
- [ ] Configure iOS URL scheme in `Info.plist`

### Data Layer
- [ ] Add `checkEmailVerified` to `ApiConstants`
- [ ] Add `resetPassword()` method to `AuthRepository`
- [ ] Add `checkEmailVerified()` method to `AuthRepository`
- [ ] Simplify `ResetPasswordRequest` model (remove `accessToken` field)
- [ ] Add recovery token methods to `SecureStorageService`

### Providers
- [ ] Create `DeepLinkNotifier` in `deep_link_provider.dart`
- [ ] Create `ResetPasswordNotifier` in `reset_password_provider.dart`

### Screens
- [ ] Create `ForgotPasswordScreen`
- [ ] Create `ResetPasswordScreen`
- [ ] Create `EmailVerifiedScreen`

### Router
- [ ] Add `emailVerified` to `AppRoutes`
- [ ] Add `/email-verified` to public routes in redirect logic
- [ ] Replace placeholder routes with actual screens
- [ ] Add deep link listener to router provider

### Exports & Code Gen
- [ ] Update `auth.dart` barrel exports
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`

### Testing
- [ ] Test registration → check email screen flow
- [ ] Test `getgains://auth/email-verified` deep link navigation
- [ ] Test `getgains://auth/reset-password?access_token=xxx` deep link + token storage
- [ ] Test forgot password → send email flow
- [ ] Test reset password → success → logout → login flow
- [ ] Test expired/invalid recovery token error state
- [ ] Test deep link when app is not running (cold start)
- [ ] Test deep link when app is in background (warm start)

---

## Error Handling

| Scenario | State | User Sees |
|----------|-------|-----------|
| Recovery token missing | `ResetPasswordTokenMissing` | "Invalid Reset Link" with "Request New Link" button |
| Recovery token expired | `ResetPasswordError` | Error snackbar with message |
| Password validation fails | Form validation | Inline field errors |
| Passwords don't match | Form validation | "Passwords do not match" |
| Network error during reset | `ResetPasswordError` | Error snackbar |
| Deep link received, no token params | Navigate to `/reset-password`, token check fails | "Invalid Reset Link" screen |

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [REGISTER.md](REGISTER.md) | Registration flow (email verification starts here) |
| [CONTEXT.md](../CONTEXT.md) | App architecture and patterns |
| [Server VERIFY_RESET_FLOW.md](../../get-gains-server/docs/features/VERIFY_RESET_FLOW.md) | Server-side implementation |
| [Web VERIFY_RESET_FLOW.md](../../get-gains-web/docs/features/VERIFY_RESET_FLOW.md) | Web app intermediary implementation |

---

*Last updated: February 11, 2026*
