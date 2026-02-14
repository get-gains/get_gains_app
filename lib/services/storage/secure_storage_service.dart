import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/logger.dart';

part 'secure_storage_service.g.dart';

/// Secure Storage Service
///
/// Provides secure key-value storage for sensitive data like JWT tokens.
/// Uses flutter_secure_storage which encrypts data using:
/// - Android: AES encryption with KeyStore
/// - iOS: Keychain
///
/// Usage:
/// ```dart
/// final storage = ref.read(secureStorageServiceProvider);
/// await storage.saveAccessToken('jwt_token');
/// final token = await storage.getAccessToken();
/// ```
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: _androidOptions);

  final FlutterSecureStorage _storage;

  // Android options - data will be encrypted using custom ciphers
  static const AndroidOptions _androidOptions = AndroidOptions();

  // ============== Token Management ==============

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: token);
      AppLogger.debug('Access token saved', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error(
        'Failed to save access token',
        tag: 'SecureStorage',
        error: e,
      );
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: StorageKeys.accessToken);
    } catch (e) {
      AppLogger.error(
        'Failed to read access token',
        tag: 'SecureStorage',
        error: e,
      );
      return null;
    }
  }

  /// Delete access token
  Future<void> deleteAccessToken() async {
    try {
      await _storage.delete(key: StorageKeys.accessToken);
      AppLogger.debug('Access token deleted', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error(
        'Failed to delete access token',
        tag: 'SecureStorage',
        error: e,
      );
      rethrow;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.refreshToken, value: token);
      AppLogger.debug('Refresh token saved', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error(
        'Failed to save refresh token',
        tag: 'SecureStorage',
        error: e,
      );
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: StorageKeys.refreshToken);
    } catch (e) {
      AppLogger.error(
        'Failed to read refresh token',
        tag: 'SecureStorage',
        error: e,
      );
      return null;
    }
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: StorageKeys.refreshToken);
      AppLogger.debug('Refresh token deleted', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error(
        'Failed to delete refresh token',
        tag: 'SecureStorage',
        error: e,
      );
      rethrow;
    }
  }

  /// Save token expiry timestamp
  Future<void> saveTokenExpiry(DateTime expiry) async {
    try {
      await _storage.write(
        key: StorageKeys.tokenExpiry,
        value: expiry.toIso8601String(),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to save token expiry',
        tag: 'SecureStorage',
        error: e,
      );
      rethrow;
    }
  }

  /// Get token expiry timestamp
  Future<DateTime?> getTokenExpiry() async {
    try {
      final value = await _storage.read(key: StorageKeys.tokenExpiry);
      if (value == null) return null;
      return DateTime.tryParse(value);
    } catch (e) {
      AppLogger.error(
        'Failed to read token expiry',
        tag: 'SecureStorage',
        error: e,
      );
      return null;
    }
  }

  /// Check if access token is expired
  ///
  /// Checks stored expiry first, then falls back to decoding the JWT
  /// token's `exp` claim. Returns true only if we can confirm the token
  /// is expired. If no expiry info is available, returns false
  /// (assumes valid — the server will reject if truly expired).
  Future<bool> isTokenExpired() async {
    // First try stored expiry
    final expiry = await getTokenExpiry();
    if (expiry != null) {
      return DateTime.now().isAfter(expiry);
    }

    // Fall back to decoding JWT exp claim
    final token = await getAccessToken();
    if (token != null) {
      final jwtExpiry = getExpiryFromJwt(token);
      if (jwtExpiry != null) {
        // Persist it so future checks are fast
        await saveTokenExpiry(jwtExpiry);
        return DateTime.now().isAfter(jwtExpiry);
      }
    }

    // No expiry info available — assume not expired
    // (server will return 401 if it is, triggering refresh)
    return false;
  }

  /// Extract the expiry [DateTime] from a JWT access token's `exp` claim.
  /// Returns null if the token is malformed or has no `exp`.
  static DateTime? getExpiryFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64-decode the payload (part[1])
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims =
          json.decode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      return null;
    } catch (e) {
      AppLogger.warning(
        'Failed to decode JWT expiry',
        tag: 'SecureStorage',
        error: e,
      );
      return null;
    }
  }

  /// Save both tokens at once (used after login/refresh)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiry,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      if (expiry != null) saveTokenExpiry(expiry),
    ]);
    AppLogger.info('All tokens saved successfully', tag: 'SecureStorage');
  }

  /// Clear all tokens (used on logout)
  Future<void> clearTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      _storage.delete(key: StorageKeys.tokenExpiry),
    ]);
    AppLogger.info('All tokens cleared', tag: 'SecureStorage');
  }

  // ============== User Data ==============

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: StorageKeys.userId);
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: StorageKeys.userEmail, value: email);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: StorageKeys.userEmail);
  }

  // ============== Recovery Token Methods (Password Reset) ==============

  /// Save recovery access token (from password reset deep link)
  Future<void> saveRecoveryToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.recoveryAccessToken, value: token);
      AppLogger.debug('Recovery access token saved', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error(
        'Failed to save recovery access token',
        tag: 'SecureStorage',
        error: e,
      );
      rethrow;
    }
  }

  /// Get the stored recovery access token
  Future<String?> getRecoveryToken() async {
    try {
      return await _storage.read(key: StorageKeys.recoveryAccessToken);
    } catch (e) {
      AppLogger.error(
        'Failed to read recovery access token',
        tag: 'SecureStorage',
        error: e,
      );
      return null;
    }
  }

  /// Save recovery refresh token
  Future<void> saveRecoveryRefreshToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.recoveryRefreshToken, value: token);
      AppLogger.debug('Recovery refresh token saved', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error(
        'Failed to save recovery refresh token',
        tag: 'SecureStorage',
        error: e,
      );
      rethrow;
    }
  }

  /// Get recovery refresh token
  Future<String?> getRecoveryRefreshToken() async {
    try {
      return await _storage.read(key: StorageKeys.recoveryRefreshToken);
    } catch (e) {
      AppLogger.error(
        'Failed to read recovery refresh token',
        tag: 'SecureStorage',
        error: e,
      );
      return null;
    }
  }

  /// Clear recovery tokens after password reset is complete
  Future<void> clearRecoveryTokens() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.recoveryAccessToken),
      _storage.delete(key: StorageKeys.recoveryRefreshToken),
    ]);
    AppLogger.debug('Recovery tokens cleared', tag: 'SecureStorage');
  }

  // ============== General Operations ==============

  /// Write a generic key-value pair
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value by key
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Delete a value by key
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Check if a key exists
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  /// Clear all stored data (use with caution)
  Future<void> clearAll() async {
    await _storage.deleteAll();
    AppLogger.warning('All secure storage cleared', tag: 'SecureStorage');
  }

  /// Check if user is authenticated (has valid access token or refresh token)
  ///
  /// Returns true if:
  /// - Access token exists and is not expired, OR
  /// - Access token is expired but a refresh token exists (session recoverable)
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null) return false;

    final isExpired = await isTokenExpired();
    if (!isExpired) return true;

    // Access token expired — check if we can recover via refresh
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      AppLogger.debug(
        'Access token expired but refresh token exists — session recoverable',
        tag: 'SecureStorage',
      );
      return true;
    }

    return false;
  }
}

/// Provider for SecureStorageService
@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService();
}
