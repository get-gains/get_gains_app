/// API Configuration Constants
///
/// Contains base URLs and API endpoint paths.
/// Environment-specific configurations should be handled via .env file.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // Base URL - Loaded from .env file
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String loginGoogle = '/auth/login/google';
  static const String register = '/auth/register';
  static const String googleSignIn = '/auth/google';
  static const String googleLink = '/auth/google/link';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String sendRecoveryEmail = '/auth/send-recovery-email';
  static const String resetPassword = '/auth/reset-password';

  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';

  // Workout Endpoints
  static const String workouts = '/workouts';
  static const String exercises = '/exercises';
  static const String routines = '/routines';
  static const String workoutSessions = '/workout-sessions';
  static const String performedSets = '/performed-sets';

  // Sync Endpoints
  static const String sync = '/sync';
  static const String syncStatus = '/sync/status';

  // Subscription Endpoints
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscriptionStatus = '/subscriptions/status';
  static const String subscriptionHistory = '/subscriptions/history';
  static const String subscriptionVerify = '/subscriptions/verify';
}
