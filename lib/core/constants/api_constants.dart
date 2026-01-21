/// API Configuration Constants
///
/// Contains base URLs and API endpoint paths.
/// Environment-specific configurations should be handled via build flavors.
library;

class ApiConstants {
  ApiConstants._();

  // Base URLs - Configure based on environment
  static const String baseUrl = 'http://localhost:3000/api';
  static const String prodBaseUrl = 'https://api.getgains.com/api';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';

  // Workout Endpoints
  static const String workouts = '/workouts';
  static const String exercises = '/exercises';

  // Sync Endpoints
  static const String sync = '/sync';
  static const String syncStatus = '/sync/status';
}
