import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';
import '../../../main.dart';
import '../data/models/user_model.dart';

part 'user_preferences_service.g.dart';

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
/// Manages user data persistence using SharedPreferences.
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
  UserPreferencesService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  // ============== User Caching ==============

  /// Cache user data for offline access
  ///
  /// Stores the complete user model in SharedPreferences.
  /// This allows showing user info even when offline.
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonString = jsonEncode(user.toJson());
      await _prefs.setString(UserPrefsKeys.cachedUser, jsonString);
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
      final jsonString = _prefs.getString(UserPrefsKeys.cachedUser);
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
    await _prefs.remove(UserPrefsKeys.cachedUser);
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
      await _prefs.setString(UserPrefsKeys.pendingGoogleProfile, jsonString);
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
      final jsonString = _prefs.getString(UserPrefsKeys.pendingGoogleProfile);
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
    return _prefs.containsKey(UserPrefsKeys.pendingGoogleProfile);
  }

  /// Clear pending Google profile
  ///
  /// Called after profile completion or when user cancels.
  Future<void> clearPendingGoogleProfile() async {
    await _prefs.remove(UserPrefsKeys.pendingGoogleProfile);
    AppLogger.debug('Pending Google profile cleared', tag: 'UserPrefs');
  }

  // ============== Login Preferences ==============

  /// Save last login method
  Future<void> setLastLoginMethod(LoginMethod method) async {
    await _prefs.setString(UserPrefsKeys.lastLoginMethod, method.name);
  }

  /// Get last login method
  LoginMethod? getLastLoginMethod() {
    final value = _prefs.getString(UserPrefsKeys.lastLoginMethod);
    if (value == null) return null;

    return LoginMethod.values.firstWhere(
      (m) => m.name == value,
      orElse: () => LoginMethod.emailPassword,
    );
  }

  /// Set whether user logged in with Google
  Future<void> setIsGoogleUser(bool isGoogle) async {
    await _prefs.setBool(UserPrefsKeys.isGoogleUser, isGoogle);
  }

  /// Check if user logged in with Google
  bool isGoogleUser() {
    return _prefs.getBool(UserPrefsKeys.isGoogleUser) ?? false;
  }

  /// Save remembered email for login
  Future<void> setRememberedEmail(String? email) async {
    if (email == null) {
      await _prefs.remove(UserPrefsKeys.rememberEmail);
    } else {
      await _prefs.setString(UserPrefsKeys.rememberEmail, email);
    }
  }

  /// Get remembered email
  String? getRememberedEmail() {
    return _prefs.getString(UserPrefsKeys.rememberEmail);
  }

  // ============== Clear All ==============

  /// Clear all user preferences
  ///
  /// Called on logout to remove all cached user data.
  Future<void> clearAll() async {
    await Future.wait([
      clearCachedUser(),
      clearPendingGoogleProfile(),
      _prefs.remove(UserPrefsKeys.isGoogleUser),
      _prefs.remove(UserPrefsKeys.lastLoginMethod),
      // Note: We keep remembered email as a convenience feature
    ]);
    AppLogger.info('All user preferences cleared', tag: 'UserPrefs');
  }
}

/// Provider for UserPreferencesService
@Riverpod(keepAlive: true)
UserPreferencesService userPreferencesService(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserPreferencesService(prefs: prefs);
}
