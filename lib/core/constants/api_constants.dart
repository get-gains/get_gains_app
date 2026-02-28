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
  static const String checkEmailVerified = '/auth/check-email-verified';

  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';

  // Profile Endpoints (fitness profile / onboarding)
  static const String profile = '/profile';

  // Workout Endpoints
  static const String workouts = '/workout';
  static const String exercises = '/workout/exercises';
  static const String routines = '/workout/routines';
  static const String workoutSessions = '/workout/sessions';
  static const String performedSets = '/workout/sets';
  static const String performedSetsSync = '/workout/sets/sync';
  static const String todayWorkout = '/workout/today';
  static const String weeklyStats = '/workout/stats/weekly';
  static const String activeSession = '/workout/sessions/active';

  // Coach Program Endpoints
  static const String coachPrograms = '/coach/programs';
  static const String coachRoutines = '/coach/routines';
  static const String coachAssignProgram = '/coach/assign-program';
  static const String coachClients = '/coach/clients';
  static const String coachClass = '/coach/class';
  static const String coachSettings = '/coach/settings';

  // Standalone Workout Endpoints
  static const String standaloneExercises = '/standalone/exercises';
  static const String standaloneRoutines = '/standalone/routines';
  static const String standalonePrograms = '/standalone/programs';
  static const String standaloneActiveProgram = '/standalone/programs/active';
  static const String standaloneToday = '/standalone/today';
  static const String standaloneSessions = '/standalone/sessions';
  static const String standaloneActiveSession = '/standalone/sessions/active';
  static const String standaloneWeeklyStats = '/standalone/stats/weekly';

  // Coach Discovery Endpoints (Client-Facing)
  static const String discoverCoaches = '/user/coaches';
  static const String subscribedCoaches = '/user/coaches/subscribed';

  // Sync Endpoints
  static const String sync = '/sync';
  static const String syncStatus = '/sync/status';

  // Subscription Endpoints
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscriptionStatus = '/subscriptions/status';
  static const String subscriptionHistory = '/subscriptions/history';
  static const String subscriptionVerify = '/subscriptions/verify';
}
