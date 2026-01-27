import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/models/models.dart';
import '../../services/user_preferences_service.dart';

part 'register_provider.g.dart';

/// Registration State
///
/// Represents the current state of the registration process.
sealed class RegisterState {
  const RegisterState();
}

/// Initial state - no registration in progress
class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

/// Loading state - registration in progress
class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

/// Success state - email verification required
///
/// User registered but needs to verify email before logging in.
class RegisterEmailVerificationPending extends RegisterState {
  const RegisterEmailVerificationPending({required this.email});
  final String email;
}

/// Success state - registration fully completed (with tokens)
///
/// Used for flows that don't require email verification (e.g., Google OAuth).
class RegisterSuccess extends RegisterState {
  const RegisterSuccess(this.response);
  final AuthResponse response;
}

/// Google sign-in pending profile completion
class RegisterGooglePendingProfile extends RegisterState {
  const RegisterGooglePendingProfile({
    required this.email,
    required this.supabaseId,
    this.suggestedName,
  });
  final String email;
  final String supabaseId;
  final String? suggestedName;
}

/// Error state - registration failed
class RegisterError extends RegisterState {
  const RegisterError(this.error);
  final AppError error;
}

/// Register Provider
///
/// Manages registration state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
/// - UserPreferencesService for offline data
///
/// Supports two registration flows:
///
/// **Email/Password Flow:**
/// ```dart
/// await ref.read(registerProvider.notifier).registerWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```
///
/// **Google Sign-In Flow (2 steps):**
/// ```dart
/// // Step 1: Google sign-in
/// await ref.read(registerProvider.notifier).signInWithGoogle();
/// // If state is RegisterGooglePendingProfile, show profile form
///
/// // Step 2: Complete profile
/// await ref.read(registerProvider.notifier).completeGoogleSignUp(
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```
@riverpod
class RegisterNotifier extends _$RegisterNotifier {
  late AuthRepository _authRepository;
  late AuthStateNotifier _authStateNotifier;

  @override
  RegisterState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _authStateNotifier = ref.watch(authStateProvider.notifier);

    // Check if there's a pending Google profile to complete
    _checkPendingGoogleProfile();

    return const RegisterInitial();
  }

  /// Check for pending Google profile on init
  Future<void> _checkPendingGoogleProfile() async {
    final pendingProfile = await _authRepository.getPendingGoogleProfile();
    if (pendingProfile != null) {
      state = RegisterGooglePendingProfile(
        email: pendingProfile.email,
        supabaseId: pendingProfile.supabaseId,
        suggestedName: pendingProfile.displayName,
      );
    }
  }

  /// Register with email and password
  ///
  /// Creates a new user account with email/password authentication.
  /// On success, navigates to check email screen for verification.
  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    state = const RegisterLoading();

    final result = await _authRepository.registerWithEmailPassword(
      email: email,
      password: password,
      name: name,
      nickname: nickname,
    );

    result.when(
      success: (response) {
        // Registration successful - email verification required
        // User will need to verify email before logging in
        state = RegisterEmailVerificationPending(email: response.user.email);
      },
      failure: (error) {
        state = RegisterError(error);
      },
    );
  }

  /// Start Google sign-in flow
  ///
  /// Initiates Google OAuth and gets initial tokens.
  /// If successful, state becomes RegisterGooglePendingProfile.
  /// User should then complete profile via completeGoogleSignUp().
  Future<void> signInWithGoogle() async {
    state = const RegisterLoading();

    final result = await _authRepository.signInWithGoogle();

    result.when(
      success: (response) {
        state = RegisterGooglePendingProfile(
          email: response.user.email,
          supabaseId: response.user.supabaseId,
        );
      },
      failure: (error) {
        state = RegisterError(error);
      },
    );
  }

  /// Complete Google sign-up
  ///
  /// Creates full user profile after Google sign-in.
  /// Requires prior successful signInWithGoogle() call.
  Future<void> completeGoogleSignUp({
    required String name,
    required String nickname,
  }) async {
    state = const RegisterLoading();

    final result = await _authRepository.completeGoogleSignUp(
      name: name,
      nickname: nickname,
    );

    result.when(
      success: (response) {
        // Update app-wide auth state
        _authStateNotifier.setAuthenticated(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          userId: response.user.id,
          email: response.user.email,
        );
        state = RegisterSuccess(response);
      },
      failure: (error) {
        state = RegisterError(error);
      },
    );
  }

  /// Cancel Google sign-up
  ///
  /// Clears pending profile and returns to initial state.
  Future<void> cancelGoogleSignUp() async {
    await _authRepository.cancelGoogleSignUp();
    state = const RegisterInitial();
  }

  /// Reset state to initial
  void reset() {
    state = const RegisterInitial();
  }

  /// Clear error state
  void clearError() {
    if (state is RegisterError) {
      state = const RegisterInitial();
    }
  }
}

/// Password Recovery Provider
///
/// Handles password recovery email sending.
///
/// Usage:
/// ```dart
/// final result = await ref.read(passwordRecoveryProvider.notifier).sendRecoveryEmail(
///   email: 'user@example.com',
/// );
/// ```
@riverpod
class PasswordRecoveryNotifier extends _$PasswordRecoveryNotifier {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  /// Send password recovery email
  Future<bool> sendRecoveryEmail({required String email}) async {
    state = const AsyncLoading();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.sendRecoveryEmail(email: email);

    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (error) {
        state = AsyncError(error, StackTrace.current);
        return false;
      },
    );
  }
}

/// Pending Google Profile Provider
///
/// Provides access to pending Google profile data.
/// Useful for pre-filling registration form with Google data.
@riverpod
Future<PendingGoogleProfile?> pendingGoogleProfile(Ref ref) async {
  final userPrefs = ref.watch(userPreferencesServiceProvider);
  return await userPrefs.getPendingGoogleProfile();
}
