import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/models/models.dart';

part 'login_provider.g.dart';

/// Login State
///
/// Represents the current state of the login process.
sealed class LoginState {
  const LoginState();
}

/// Initial state - no login in progress
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Loading state - login in progress
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Success state - login completed
class LoginSuccess extends LoginState {
  const LoginSuccess(this.response);
  final AuthResponse response;
}

/// Google sign-in pending profile completion
///
/// User authenticated with Google but doesn't have a profile yet.
/// Navigate to the complete-profile screen.
class LoginGooglePendingProfile extends LoginState {
  const LoginGooglePendingProfile({
    required this.email,
    required this.supabaseId,
    this.suggestedName,
  });
  final String email;
  final String supabaseId;
  final String? suggestedName;
}

/// Error state - login failed
class LoginError extends LoginState {
  const LoginError(this.error);
  final AppError error;
}

/// Login Provider
///
/// Manages login state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
///
/// Supports two login flows:
///
/// **Email/Password Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
/// );
/// ```
///
/// **Google Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithGoogle();
/// ```
@riverpod
class LoginNotifier extends _$LoginNotifier {
  late AuthRepository _authRepository;
  late AuthStateNotifier _authStateNotifier;

  @override
  LoginState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _authStateNotifier = ref.watch(authStateProvider.notifier);
    return const LoginInitial();
  }

  /// Login with email and password
  ///
  /// Authenticates an existing user with email/password.
  /// On success, updates auth state and navigates to home.
  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const LoginLoading();

    final result = await _authRepository.loginWithEmailPassword(
      email: email,
      password: password,
    );

    result.when(
      success: (response) async {
        // Update app-wide auth state
        await _authStateNotifier.setAuthenticated(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          userId: response.user.id,
          email: response.user.email,
        );

        state = LoginSuccess(response);
      },
      failure: (error) {
        state = LoginError(error);
      },
    );
  }

  /// Login with Google
  ///
  /// Authenticates an existing Google user.
  /// If user is not registered, automatically falls back to
  /// the registration flow and navigates to profile completion.
  Future<void> loginWithGoogle() async {
    state = const LoginLoading();

    final result = await _authRepository.loginWithGoogle();

    result.when(
      success: (loginResult) async {
        switch (loginResult) {
          case GoogleLoginExistingUser(:final response):
            // Existing user — set auth state and navigate home
            await _authStateNotifier.setAuthenticated(
              accessToken: response.accessToken,
              refreshToken: response.refreshToken,
              userId: response.user.id,
              email: response.user.email,
            );
            state = LoginSuccess(response);

          case GoogleLoginNewUser(:final response, :final suggestedName):
            // New user — navigate to complete profile screen
            state = LoginGooglePendingProfile(
              email: response.user.email,
              supabaseId: response.user.supabaseId,
              suggestedName: suggestedName,
            );
        }
      },
      failure: (error) {
        state = LoginError(error);
      },
    );
  }

  void reset() {
    state = const LoginInitial();
  }
}
