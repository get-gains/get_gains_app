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
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            clientId: dotenv.env['GOOGLE_CLIENT_ID'],
            scopes: ['email', 'profile'],
          );

  final GoogleSignIn _googleSignIn;

  /// Sign in with Google
  ///
  /// Opens the Google sign-in flow and returns the ID token
  /// needed for server authentication.
  Future<Result<GoogleSignInResult, AppError>> signIn() async {
    try {
      AppLogger.debug('Starting Google sign-in flow', tag: 'GoogleSignIn');

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
            code: 'GOOGLE_SIGN_IN_CANCELLED',
          ),
        );
      }

      // Get authentication details
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        AppLogger.error('Failed to get Google ID token', tag: 'GoogleSignIn');
        return const Failure(
          AuthError(
            message: 'Failed to authenticate with Google',
            code: 'GOOGLE_NO_ID_TOKEN',
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
    } catch (e) {
      AppLogger.error('Google sign-in failed', tag: 'GoogleSignIn', error: e);
      return Failure(
        AuthError(
          message: 'Google sign-in failed: ${e.toString()}',
          code: 'GOOGLE_SIGN_IN_ERROR',
          originalError: e,
        ),
      );
    }
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
