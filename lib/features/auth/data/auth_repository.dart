import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/storage/secure_storage_service.dart';
import '../data/models/models.dart';
import '../services/google_sign_in_service.dart';
import '../services/user_preferences_service.dart';

part 'auth_repository.g.dart';

/// Auth Repository
///
/// Handles all authentication-related data operations.
/// Coordinates between:
/// - API client (server communication)
/// - Secure storage (JWT tokens)
/// - User preferences (cached user data)
/// - Google Sign-In service
///
/// Implements offline-compatible patterns:
/// - Caches user data in SharedPreferences
/// - Stores tokens securely
/// - Manages pending Google profile completion
///
/// Usage:
/// ```dart
/// final authRepo = ref.read(authRepositoryProvider);
///
/// // Email/Password Registration
/// final result = await authRepo.registerWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
///
/// // Google Sign-In (New User)
/// final googleResult = await authRepo.signInWithGoogle();
/// if (googleResult.isSuccess) {
///   // Show profile completion screen
///   // Then call completeGoogleSignUp()
/// }
/// ```
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required UserPreferencesService userPreferences,
    required GoogleSignInService googleSignInService,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage,
       _userPreferences = userPreferences,
       _googleSignInService = googleSignInService;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final UserPreferencesService _userPreferences;
  final GoogleSignInService _googleSignInService;

  // ============== Email/Password Registration ==============

  /// Register a new user with email and password
  ///
  /// Creates a new user account with:
  /// - Email/password authentication via Supabase
  /// - User profile in database
  ///
  /// On success:
  /// - Stores JWT tokens in secure storage
  /// - Caches user data in preferences
  /// - Returns complete AuthResponse
  ///
  /// Server endpoint: POST /auth/register
  Future<Result<AuthResponse, AppError>> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    AppLogger.debug('Registering user with email: $email', tag: 'AuthRepo');

    final request = RegisterRequest(
      email: email,
      password: password,
      name: name,
      nickname: nickname,
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: request.toJson(),
    );

    return result.when(
      success: (data) async {
        try {
          final response = AuthResponseX.fromApiResponse(data);

          // Store tokens securely
          await _secureStorage.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );

          // Store user info
          await _secureStorage.saveUserId(response.user.id);
          await _secureStorage.saveUserEmail(response.user.email);

          // Cache user for offline access
          await _userPreferences.cacheUser(response.user);
          await _userPreferences.setLastLoginMethod(LoginMethod.emailPassword);
          await _userPreferences.setIsGoogleUser(false);

          AppLogger.info('User registered successfully', tag: 'AuthRepo');
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to process register response',
            tag: 'AuthRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to process registration',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error('Registration failed', tag: 'AuthRepo', error: error);
        return Failure(_mapToAuthError(error));
      },
    );
  }

  // ============== Google Sign-In (New User) ==============

  /// Sign in with Google (for new users)
  ///
  /// This is the first step of Google sign-up:
  /// 1. Opens Google sign-in flow
  /// 2. Gets Google ID token
  /// 3. Sends to server for Supabase authentication
  /// 4. Returns partial user data (no profile yet)
  ///
  /// After this, call completeGoogleSignUp() to create the full profile.
  ///
  /// Server endpoint: POST /auth/google
  Future<Result<GoogleSignInResponse, AppError>> signInWithGoogle() async {
    AppLogger.debug('Starting Google sign-in flow', tag: 'AuthRepo');

    // Step 1: Get Google ID token
    final googleResult = await _googleSignInService.signIn();

    return googleResult.when(
      success: (googleData) async {
        // Step 2: Send ID token to server
        final request = GoogleSignInRequest(idToken: googleData.idToken);

        final result = await _apiClient.post<Map<String, dynamic>>(
          ApiConstants.googleSignIn,
          data: request.toJson(),
        );

        return result.when(
          success: (data) async {
            try {
              final response = GoogleSignInResponseX.fromApiResponse(data);

              // Save pending profile for completion
              await _userPreferences.savePendingGoogleProfile(
                PendingGoogleProfile(
                  email: response.user.email,
                  supabaseId: response.user.supabaseId,
                  accessToken: response.accessToken,
                  refreshToken: response.refreshToken,
                  displayName: googleData.displayName,
                ),
              );

              // Store tokens temporarily (will be used for /google/link call)
              await _secureStorage.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
              );

              AppLogger.info(
                'Google sign-in successful, pending profile completion',
                tag: 'AuthRepo',
              );
              return Success(response);
            } catch (e) {
              AppLogger.error(
                'Failed to process Google sign-in response',
                tag: 'AuthRepo',
                error: e,
              );
              return Failure(
                UnknownError(
                  message: 'Failed to process Google sign-in',
                  originalError: e,
                ),
              );
            }
          },
          failure: (error) {
            AppLogger.error(
              'Google sign-in API call failed',
              tag: 'AuthRepo',
              error: error,
            );
            return Failure(_mapToAuthError(error));
          },
        );
      },
      failure: (error) {
        return Failure(error);
      },
    );
  }

  /// Complete Google sign-up by creating user profile
  ///
  /// This is the second step of Google sign-up:
  /// 1. Uses pending profile data from signInWithGoogle()
  /// 2. Creates full user profile with name/nickname
  /// 3. Returns complete AuthResponse
  ///
  /// Requires valid tokens from prior signInWithGoogle() call.
  ///
  /// Server endpoint: POST /auth/google/link (protected)
  Future<Result<AuthResponse, AppError>> completeGoogleSignUp({
    required String name,
    required String nickname,
  }) async {
    AppLogger.debug('Completing Google sign-up', tag: 'AuthRepo');

    // Get pending profile
    final pendingProfile = await _userPreferences.getPendingGoogleProfile();
    if (pendingProfile == null) {
      return const Failure(
        AuthError(
          message:
              'No pending Google profile found. Please sign in with Google first.',
          code: 'NO_PENDING_PROFILE',
        ),
      );
    }

    final request = CreateUserFromGoogleRequest(
      email: pendingProfile.email,
      name: name,
      nickname: nickname,
      supabaseId: pendingProfile.supabaseId,
    );

    // This endpoint requires authentication (uses stored tokens)
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.googleLink,
      data: request.toJson(),
    );

    return result.when(
      success: (data) async {
        try {
          // The response from /google/link returns the created user
          // We need to construct AuthResponse using existing tokens
          final userData = (data['data'] as Map<String, dynamic>);
          final user = UserModel.fromJson(userData);

          final response = AuthResponse(
            accessToken: pendingProfile.accessToken,
            refreshToken: pendingProfile.refreshToken,
            user: user,
          );

          // Store user info
          await _secureStorage.saveUserId(user.id);
          await _secureStorage.saveUserEmail(user.email);

          // Cache user for offline access
          await _userPreferences.cacheUser(user);
          await _userPreferences.setLastLoginMethod(LoginMethod.google);
          await _userPreferences.setIsGoogleUser(true);

          // Clear pending profile
          await _userPreferences.clearPendingGoogleProfile();

          AppLogger.info(
            'Google sign-up completed successfully',
            tag: 'AuthRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to process Google link response',
            tag: 'AuthRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to complete Google sign-up',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Google link API call failed',
          tag: 'AuthRepo',
          error: error,
        );
        return Failure(_mapToAuthError(error));
      },
    );
  }

  /// Cancel pending Google sign-up
  ///
  /// Clears pending profile and tokens if user decides not to complete sign-up.
  Future<void> cancelGoogleSignUp() async {
    await _userPreferences.clearPendingGoogleProfile();
    await _secureStorage.clearTokens();
    await _googleSignInService.signOut();
    AppLogger.debug('Google sign-up cancelled', tag: 'AuthRepo');
  }

  /// Check if there's a pending Google profile to complete
  Future<bool> hasPendingGoogleProfile() async {
    return await _userPreferences.hasPendingGoogleProfile();
  }

  /// Get pending Google profile data
  Future<PendingGoogleProfile?> getPendingGoogleProfile() async {
    return await _userPreferences.getPendingGoogleProfile();
  }

  // ============== Password Recovery ==============

  /// Send password recovery email
  ///
  /// Sends an email with a recovery link to reset password.
  /// The link contains a token that authenticates the user for password reset.
  ///
  /// Server endpoint: POST /auth/send-recovery-email
  Future<Result<void, AppError>> sendRecoveryEmail({
    required String email,
  }) async {
    AppLogger.debug('Sending recovery email to: $email', tag: 'AuthRepo');

    final request = SendRecoveryEmailRequest(email: email);

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.sendRecoveryEmail,
      data: request.toJson(),
    );

    return result.when(
      success: (_) {
        AppLogger.info('Recovery email sent successfully', tag: 'AuthRepo');
        return const Success(null);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to send recovery email',
          tag: 'AuthRepo',
          error: error,
        );
        return Failure(_mapToAuthError(error));
      },
    );
  }

  // ============== Utility Methods ==============

  /// Get cached user data (for offline access)
  Future<UserModel?> getCachedUser() async {
    return await _userPreferences.getCachedUser();
  }

  /// Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    return await _secureStorage.isAuthenticated();
  }

  /// Clear all auth data (logout)
  Future<void> clearAuthData() async {
    await _secureStorage.clearTokens();
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'user_email');
    await _userPreferences.clearAll();
    await _googleSignInService.signOut();
    AppLogger.info('Auth data cleared', tag: 'AuthRepo');
  }

  /// Map AppError to appropriate AuthError
  AppError _mapToAuthError(AppError error) {
    if (error is NetworkError) {
      switch (error.statusCode) {
        case 401:
          return AuthError.invalidCredentials();
        case 409:
          return const AuthError(
            message: 'Email already exists',
            code: 'EMAIL_EXISTS',
          );
        case 400:
          return ValidationError(
            message: error.message,
            code: 'VALIDATION_ERROR',
          );
        default:
          return error;
      }
    }
    return error;
  }
}

/// Provider for AuthRepository
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
    userPreferences: ref.watch(userPreferencesServiceProvider),
    googleSignInService: ref.watch(googleSignInServiceProvider),
  );
}
