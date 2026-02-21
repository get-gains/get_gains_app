import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../data/models/user_model.dart';

part 'user_preferences_service.g.dart';

/// Hive box name for user preferences
const String _userPrefsBoxName = 'user_preferences';

/// Storage keys for user preferences
class UserPrefsKeys {
  UserPrefsKeys._();

  static const String cachedUser = 'cached_user';
  static const String isGoogleUser = 'is_google_user';
  static const String pendingGoogleProfile = 'pending_google_profile';
  static const String lastLoginMethod = 'last_login_method';
  static const String rememberEmail = 'remember_email';
}

/// Login methods for tracking
enum LoginMethod { emailPassword, google }

/// Pending Google Profile
///
/// Stores partial user data from Google sign-in until profile is completed.
class PendingGoogleProfile {
  const PendingGoogleProfile({
    required this.email,
    required this.supabaseId,
    required this.accessToken,
    required this.refreshToken,
    this.displayName,
  });

  final String email;
  final String supabaseId;
  final String accessToken;
  final String refreshToken;
  final String? displayName;

  Map<String, dynamic> toJson() => {
    'email': email,
    'supabaseId': supabaseId,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'displayName': displayName,
  };

  factory PendingGoogleProfile.fromJson(Map<String, dynamic> json) {
    return PendingGoogleProfile(
      email: json['email'] as String,
      supabaseId: json['supabaseId'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      displayName: json['displayName'] as String?,
    );
  }
}

/// User Preferences Service
///
/// Manages user data persistence using Hive (fast, lightweight NoSQL database).
/// Used for:
/// - Caching user data for offline access
/// - Storing login method preferences
/// - Managing pending Google profile completion
///
/// Note: Sensitive data like tokens should use SecureStorageService instead.
/// This service is for non-sensitive user metadata and preferences.
///
/// Usage:
/// ```dart
/// final prefs = ref.read(userPreferencesServiceProvider);
///
/// // Cache user after login
/// await prefs.cacheUser(user);
///
/// // Get cached user when offline
/// final cachedUser = await prefs.getCachedUser();
/// ```
class UserPreferencesService {
  UserPreferencesService({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  /// Initialize Hive and open the user preferences box
  /// Call this in main() before runApp()
  static Future<Box<dynamic>> init() async {
    await Hive.initFlutter();
    return Hive.openBox(_userPrefsBoxName);
  }

  // ============== User Caching ==============

  /// Cache user data for offline access
  ///
  /// Stores the complete user model in Hive.
  /// This allows showing user info even when offline.
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonString = jsonEncode(user.toJson());
      await _box.put(UserPrefsKeys.cachedUser, jsonString);
      AppLogger.debug('User cached successfully', tag: 'UserPrefs');
    } catch (e) {
      AppLogger.error('Failed to cache user', tag: 'UserPrefs', error: e);
    }
  }

  /// Get cached user data
  ///
  /// Returns the cached user model or null if not found.
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = _box.get(UserPrefsKeys.cachedUser) as String?;
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e) {
      AppLogger.error('Failed to get cached user', tag: 'UserPrefs', error: e);
      return null;
    }
  }

  /// Clear cached user data
  Future<void> clearCachedUser() async {
    await _box.delete(UserPrefsKeys.cachedUser);
    AppLogger.debug('Cached user cleared', tag: 'UserPrefs');
  }

  // ============== Google Profile Completion ==============

  /// Save pending Google profile
  ///
  /// Stores partial Google sign-in data until user completes profile.
  /// Used when user signs in with Google but hasn't set name/nickname yet.
  Future<void> savePendingGoogleProfile(PendingGoogleProfile profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await _box.put(UserPrefsKeys.pendingGoogleProfile, jsonString);
      AppLogger.debug('Pending Google profile saved', tag: 'UserPrefs');
    } catch (e) {
      AppLogger.error(
        'Failed to save pending Google profile',
        tag: 'UserPrefs',
        error: e,
      );
    }
  }

  /// Get pending Google profile
  ///
  /// Returns the pending profile or null if not found.
  Future<PendingGoogleProfile?> getPendingGoogleProfile() async {
    try {
      final jsonString =
          _box.get(UserPrefsKeys.pendingGoogleProfile) as String?;
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PendingGoogleProfile.fromJson(json);
    } catch (e) {
      AppLogger.error(
        'Failed to get pending Google profile',
        tag: 'UserPrefs',
        error: e,
      );
      return null;
    }
  }

  /// Check if there's a pending Google profile
  bool hasPendingGoogleProfile() {
    return _box.containsKey(UserPrefsKeys.pendingGoogleProfile);
  }

  /// Clear pending Google profile
  ///
  /// Called after profile completion or when user cancels.
  Future<void> clearPendingGoogleProfile() async {
    await _box.delete(UserPrefsKeys.pendingGoogleProfile);
    AppLogger.debug('Pending Google profile cleared', tag: 'UserPrefs');
  }

  // ============== Login Preferences ==============

  /// Save last login method
  Future<void> setLastLoginMethod(LoginMethod method) async {
    await _box.put(UserPrefsKeys.lastLoginMethod, method.name);
  }

  /// Get last login method
  LoginMethod? getLastLoginMethod() {
    final value = _box.get(UserPrefsKeys.lastLoginMethod) as String?;
    if (value == null) return null;

    return LoginMethod.values.firstWhere(
      (m) => m.name == value,
      orElse: () => LoginMethod.emailPassword,
    );
  }

  /// Set whether user logged in with Google
  Future<void> setIsGoogleUser(bool isGoogle) async {
    await _box.put(UserPrefsKeys.isGoogleUser, isGoogle);
  }

  /// Check if user logged in with Google
  bool isGoogleUser() {
    return _box.get(UserPrefsKeys.isGoogleUser) as bool? ?? false;
  }

  /// Save remembered email for login
  Future<void> setRememberedEmail(String? email) async {
    if (email == null) {
      await _box.delete(UserPrefsKeys.rememberEmail);
    } else {
      await _box.put(UserPrefsKeys.rememberEmail, email);
    }
  }

  /// Get remembered email
  String? getRememberedEmail() {
    return _box.get(UserPrefsKeys.rememberEmail) as String?;
  }

  // ============== Clear All ==============

  /// Clear all user preferences
  ///
  /// Called on logout to remove all cached user data.
  Future<void> clearAll() async {
    await Future.wait([
      clearCachedUser(),
      clearPendingGoogleProfile(),
      _box.delete(UserPrefsKeys.isGoogleUser),
      _box.delete(UserPrefsKeys.lastLoginMethod),
      // Note: We keep remembered email as a convenience feature
    ]);
    AppLogger.info('All user preferences cleared', tag: 'UserPrefs');
  }

  // ============== Generic Raw Cache Helpers ==============

  /// Store an arbitrary string value under [key].
  ///
  /// Used by non-auth features (e.g. profile caching) that need simple
  /// key-value persistence in the same Hive box.
  void cacheRaw(String key, String value) {
    _box.put(key, value);
  }

  /// Read a raw string value previously stored via [cacheRaw].
  String? readRaw(String key) {
    return _box.get(key) as String?;
  }

  /// Delete a raw cached value.
  void deleteRaw(String key) {
    _box.delete(key);
  }
}

/// Provider for the Hive box used by UserPreferencesService
/// Must be overridden in main() with the actual instance
final userPrefsBoxProvider = Provider<Box<dynamic>>((ref) {
  throw UnimplementedError(
    'User preferences box must be initialized in main()',
  );
});

/// Provider for UserPreferencesService
@Riverpod(keepAlive: true)
UserPreferencesService userPreferencesService(Ref ref) {
  final box = ref.watch(userPrefsBoxProvider);
  return UserPreferencesService(box: box);
}
