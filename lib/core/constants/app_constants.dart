/// General Application Constants
///
/// Contains app-wide configuration values, feature flags, and defaults.
library;

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Get Gains';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'get_gains.db';
  static const int databaseVersion = 2;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheValidity = Duration(hours: 1);
  static const Duration syncInterval = Duration(minutes: 15);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 50;

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableBiometricAuth = true;
  static const bool enableUnityIntegration = true;
}
