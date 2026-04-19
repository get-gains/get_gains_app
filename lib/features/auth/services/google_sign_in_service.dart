import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';

part 'google_sign_in_service.g.dart';

/// Google Sign-In Result
///
/// Contains the Google ID token needed for server authentication.
class GoogleSignInResult {
  const GoogleSignInResult({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String idToken;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// Google Sign-In Service
///
/// Handles Google OAuth authentication on the client side.
/// Returns Google ID token to be sent to the Express server
/// for Supabase authentication.
///
/// Flow:
/// 1. User taps "Sign in with Google"
/// 2. GoogleSignInService.signIn() opens Google's OAuth flow
/// 3. User authenticates with Google
/// 4. Service returns GoogleSignInResult with ID token
/// 5. ID token is sent to server: POST /auth/google
/// 6. Server verifies token and returns Supabase JWT
///
/// Configuration requirements:
/// - `.env` must contain `GOOGLE_CLIENT_ID` set to the **Web** OAuth client ID
/// - Google Cloud Console must have an **Android** OAuth client with:
///   - Package name: `com.getgains.app`
///   - SHA-1 fingerprint of the signing certificate (debug & release)
/// - Both client IDs must be in the same Google Cloud project
///
/// Usage:
/// ```dart
/// final googleService = ref.read(googleSignInServiceProvider);
/// final result = await googleService.signIn();
/// result.when(
///   success: (data) => sendToServer(data.idToken),
///   failure: (error) => showError(error.message),
/// );
/// ```
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? _createGoogleSignIn();

  /// Creates [GoogleSignIn] with validated configuration.
  ///
  /// The `serverClientId` MUST be the **Web** OAuth client ID from Google
  /// Cloud Console (NOT the Android client ID). The Android client ID is
  /// resolved automatically by Google Play Services using the app's
  /// package name + SHA-1 fingerprint.
  static GoogleSignIn _createGoogleSignIn() {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'];

    if (clientId == null || clientId.isEmpty) {
      AppLogger.error(
        'GOOGLE_CLIENT_ID is not set in .env file. '
        'Google sign-in will fail.',
        tag: 'GoogleSignIn',
      );
    } else {
      // Log masked client ID for debugging (show first 8 chars only)
      final masked = clientId.length > 12
          ? '${clientId.substring(0, 8)}...${clientId.substring(clientId.length - 4)}'
          : '***';
      AppLogger.debug(
        'Initializing GoogleSignIn with serverClientId: $masked',
        tag: 'GoogleSignIn',
      );
    }

    return GoogleSignIn(
      // For Android: Uses serverClientId (Web Client ID) to get idToken.
      // The SHA-1 fingerprint must be registered in Google Cloud Console
      // as an Android OAuth client in the SAME project.
      // For iOS: Uses clientId from GoogleService-Info.plist
      // For Web: Uses clientId
      serverClientId: clientId,
      scopes: ['email', 'profile'],
    );
  }

  final GoogleSignIn _googleSignIn;

  /// Sign in with Google
  ///
  /// Opens the Google sign-in flow and returns the ID token
  /// needed for server authentication.
  Future<Result<GoogleSignInResult, AppError>> signIn() async {
    try {
      AppLogger.debug('Starting Google sign-in flow', tag: 'GoogleSignIn');

      // Validate configuration before attempting sign-in
      final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
      if (clientId == null || clientId.isEmpty) {
        AppLogger.error(
          'Cannot sign in: GOOGLE_CLIENT_ID not configured in .env',
          tag: 'GoogleSignIn',
        );
        return const Failure(
          AuthError(
            message:
                'Google sign-in is not configured. Please contact support.',
            transportCode: 'GOOGLE_NOT_CONFIGURED',
          ),
        );
      }

      // Sign out first to clear any cached account and force the
      // account picker to show every time (e.g. after hot restart).
      await _googleSignIn.signOut();

      // Start the sign-in flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        AppLogger.debug(
          'Google sign-in cancelled by user',
          tag: 'GoogleSignIn',
        );
        return const Failure(
          AuthError(
            message: 'Sign-in cancelled',
            transportCode: 'GOOGLE_SIGN_IN_CANCELLED',
          ),
        );
      }

      // Get authentication details
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        AppLogger.error(
          'Failed to get Google ID token. '
          'Ensure serverClientId is the Web client ID (not Android).',
          tag: 'GoogleSignIn',
        );
        return const Failure(
          AuthError(
            message: 'Failed to authenticate with Google',
            transportCode: 'GOOGLE_NO_ID_TOKEN',
          ),
        );
      }

      AppLogger.info('Google sign-in successful', tag: 'GoogleSignIn');

      return Success(
        GoogleSignInResult(
          idToken: auth.idToken!,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        ),
      );
    } on PlatformException catch (e) {
      final errorMessage = _mapPlatformError(e);
      AppLogger.error(
        'Google sign-in PlatformException: '
        'code=${e.code}, message=${e.message}',
        tag: 'GoogleSignIn',
        error: e,
      );
      return Failure(
        AuthError(
          message: errorMessage,
          transportCode: 'GOOGLE_SIGN_IN_ERROR',
          originalError: e,
        ),
      );
    } catch (e) {
      AppLogger.error('Google sign-in failed', tag: 'GoogleSignIn', error: e);
      return Failure(
        AuthError(
          message: 'Google sign-in failed: ${e.toString()}',
          transportCode: 'GOOGLE_SIGN_IN_ERROR',
          originalError: e,
        ),
      );
    }
  }

  /// Maps [PlatformException] from google_sign_in to user-friendly messages.
  ///
  /// Common Android error codes from `com.google.android.gms.common.api.ApiException`:
  /// - 10: DEVELOPER_ERROR — SHA-1 / package name mismatch in Google Cloud Console
  /// - 12501: SIGN_IN_CANCELLED — User cancelled the sign-in
  /// - 12502: SIGN_IN_CURRENTLY_IN_PROGRESS — Another sign-in already running
  /// - 7: NETWORK_ERROR — No internet connection
  String _mapPlatformError(PlatformException e) {
    final message = e.message ?? '';

    if (message.contains('ApiException: 10')) {
      AppLogger.error(
        'DEVELOPER_ERROR (ApiException: 10): '
        'The app\'s SHA-1 fingerprint or package name is not registered '
        'in Google Cloud Console. Ensure an Android OAuth client exists with '
        'package name "com.getgains.app" and the correct SHA-1 fingerprint. '
        'Run: ./gradlew signingReport to get the SHA-1.',
        tag: 'GoogleSignIn',
      );
      return 'Google sign-in configuration error. Please contact support.';
    }

    if (message.contains('ApiException: 12501') ||
        e.code == 'sign_in_cancelled') {
      return 'Sign-in cancelled';
    }

    if (message.contains('ApiException: 12502')) {
      return 'Sign-in already in progress. Please wait.';
    }

    if (message.contains('ApiException: 7') ||
        message.contains('NETWORK_ERROR')) {
      return 'No internet connection. Please check your network.';
    }

    return 'Google sign-in failed. Please try again.';
  }

  /// Sign out from Google
  ///
  /// Disconnects the user from Google sign-in.
  /// Should be called when the user logs out of the app.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      AppLogger.debug('Google sign-out successful', tag: 'GoogleSignIn');
    } catch (e) {
      AppLogger.error('Google sign-out failed', tag: 'GoogleSignIn', error: e);
    }
  }

  /// Disconnect from Google
  ///
  /// Revokes all access and disconnects completely.
  /// Use when user wants to remove app access from their Google account.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      AppLogger.debug('Google disconnect successful', tag: 'GoogleSignIn');
    } catch (e) {
      AppLogger.error(
        'Google disconnect failed',
        tag: 'GoogleSignIn',
        error: e,
      );
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current signed-in Google account (if any)
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

/// Provider for GoogleSignInService
@Riverpod(keepAlive: true)
GoogleSignInService googleSignInService(Ref ref) {
  return GoogleSignInService();
}
