/// Secure Storage Keys
///
/// Contains keys used for storing sensitive data in flutter_secure_storage.
/// All JWT tokens and sensitive credentials should use these keys.
library;

class StorageKeys {
  StorageKeys._();

  // Auth Tokens
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';

  // User Data
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';

  // App Settings (sensitive)
  static const String biometricEnabled = 'biometric_enabled';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
}
