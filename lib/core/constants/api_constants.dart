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
  // Pose form uploads contain large landmark payloads; allow generous timeouts.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration sendTimeout = Duration(seconds: 120);

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

  /// Coach → client profile: GET /profile/clients/:userId
  static String clientProfile(String userId) => '/profile/clients/$userId';

  // Workout Endpoints
  static const String workouts = '/workout';
  static const String exercises = '/workout/exercises';
  static const String routines = '/workout/routines';
  static const String workoutSessions = '/workout/sessions';
  static const String performedSets = '/workout/sets';
  static const String performedSetsSync = '/workout/sets/sync';
  static const String todayWorkout = '/workout/today';
  static const String todayStatus = '/today';
  static const String weeklyStats = '/workout/stats/weekly';
  static const String activeSession = '/workout/sessions/active';

  // Coach Program Endpoints
  static const String coachPrograms = '/coach/programs';
  static const String coachRoutines = '/coach/routines';
  static const String coachAssignProgram = '/coach/assign-program';
  static const String coachClients = '/coach/clients';
  static const String coachClass = '/coach/class';
  static const String coachSettings = '/coach/settings';

  // Coach Client Progress Endpoints
  // Sessions:         GET /coach/clients/:userId/sessions
  // Session detail:   GET /coach/clients/:userId/sessions/:sessionId
  // Weekly stats:     GET /coach/clients/:userId/stats/weekly
  // Exercise history: GET /coach/clients/:userId/exercises/:exerciseId/history
  // Form results:     GET /coach/clients/:userId/form-results
  // (all built from coachClients base path)
  static const String coachPerformanceDetailed = '/coach/performance/detailed';

  // Standalone Workout Endpoints
  static const String standaloneExercises = '/standalone/exercises';
  static const String standaloneRoutines = '/standalone/routines';
  static const String standalonePrograms = '/standalone/programs';
  static const String standaloneActiveProgram = '/standalone/programs/active';
  static const String standaloneToday = '/standalone/today';
  static const String standaloneSessions = '/standalone/sessions';
  static const String standaloneActiveSession = '/standalone/sessions/active';
  static const String standaloneWeeklyStats = '/standalone/stats/weekly';

  // Unified Stats Endpoints
  static const String unifiedWeeklyStats = '/stats/weekly';

  // Unified Session History Endpoints
  static const String unifiedSessionHistory = '/sessions/history';

  // Coach Discovery Endpoints (Client-Facing)
  static const String discoverCoaches = '/user/coaches';
  static const String subscribedCoaches = '/user/coaches/subscribed';

  // Pose Detection Endpoints
  static const String poseResults = '/pose/results';

  // Sync Endpoints
  static const String sync = '/sync';
  static const String syncStatus = '/sync/status';

  // Subscription Endpoints
  static const String subscriptionStatus = '/subscriptions/status';

  // Coins Endpoints
  static const String coinBalance = '/coins/balance';
  static const String coinHistory = '/coins/history';

  // Shop Endpoints
  static const String shopCatalog = '/shop/catalog';
  static const String shopPurchase = '/shop/purchase';

  // Cosmetics Endpoints
  static const String cosmeticsInventory = '/cosmetics/inventory';
  static const String cosmeticsEquip = '/cosmetics/equip';
  static const String cosmeticsUnequip = '/cosmetics/unequip';
  static const String cosmeticsEquipped = '/cosmetics/equipped';

  // Leaderboard Endpoints
  static const String leaderboardClass = '/leaderboard/class';
  static const String leaderboardMyCoaches = '/leaderboard/my-coaches';
}
