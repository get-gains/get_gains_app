import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../home/data/models/today_status_model.dart';
import '../../../workout/data/models/models.dart';
import '../../../workout/data/workout_repository.dart';

part 'home_providers.g.dart';

// ──────────────────────────────────────────────────────────
// Today Status (Unified)
// ──────────────────────────────────────────────────────────

/// Fetches subscription state + both workout sources from `GET /api/today`.
///
/// Always resolves — never throws SubscriptionRequiredError.
/// Invalidate with `ref.invalidate(todayStatusProvider)` to force refresh.
@riverpod
Future<TodayStatusModel> todayStatus(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getTodayStatus();
  return result.when(
    success: (model) => model,
    failure: (error) => throw error,
  );
}

// ──────────────────────────────────────────────────────────
// Home State (Composite)
// ──────────────────────────────────────────────────────────

/// Enum describing the client's current home-screen status.
enum HomeStatus {
  /// User has no subscribed coach → show "Find a Coach" CTA.
  noCoach,

  /// User has a coach but no active subscription → show upgrade CTA.
  noSubscription,

  /// User had a coach + active subscription that has since expired,
  /// AND the coach had already assigned a routine for today.
  /// Show the routine card (read-only) + a "Renew" banner.
  lapsedSubscription,

  /// User has a coach but no active program → show "Waiting for program".
  waitingForProgram,

  /// Today is a rest day within the active program.
  restDay,

  /// There is a routine scheduled for today → show routine card.
  hasRoutine,

  /// Free user with no standalone program → "Build Your First Program" CTA.
  noStandaloneProgram,

  /// Free user with active standalone program → show program routine list.
  hasStandaloneProgram,
}

/// Derives [HomeStatus] from [todayStatusProvider].
///
/// Forks on `isSubscribed`:
/// - Free users: standalone program status drives the home screen.
/// - Paid users: coach program status drives the home screen.
@riverpod
Future<HomeStatus> homeStatus(Ref ref) async {
  final s = await ref.watch(todayStatusProvider.future);

  // ── Free tier path ──
  if (!s.isSubscribed) {
    if (s.hasCoach) {
      return HomeStatus.lapsedSubscription;
    }
    if (s.standalone.hasActiveProgram) {
      return HomeStatus.hasStandaloneProgram;
    }
    return HomeStatus.noStandaloneProgram;
  }

  // ── Paid tier path ──
  if (!s.hasCoach) return HomeStatus.noCoach;
  if (s.coachToday == null) return HomeStatus.waitingForProgram;
  if (s.coachToday!.isRestDay) return HomeStatus.restDay;
  return HomeStatus.hasRoutine;
}

// ──────────────────────────────────────────────────────────
// Active Today (coach first, standalone fallback)
// ──────────────────────────────────────────────────────────

/// Resolves today's routine as [TodayRoutineModel].
///
/// Prefers coach today when subscribed; returns rest day for standalone (free
/// users see standalone program info elsewhere).
@riverpod
Future<TodayRoutineModel> activeToday(Ref ref) async {
  final s = await ref.watch(todayStatusProvider.future);
  if (s.isSubscribed && s.coachToday != null) {
    return s.coachToday!.toRoutineModel();
  }
  return const TodayRoutineModel(isRestDay: true);
}

// ──────────────────────────────────────────────────────────
// Weekly Stats (Unified)
// ──────────────────────────────────────────────────────────

/// Fetches unified weekly workout statistics from `GET /api/stats/weekly`.
@riverpod
Future<UnifiedWeeklyStats> unifiedWeeklyStats(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getUnifiedWeeklyStats();
  return result.when(
    success: (model) => model,
    failure: (error) => throw error,
  );
}

// ──────────────────────────────────────────────────────────
// Weekly Stats (Legacy)
// ──────────────────────────────────────────────────────────

/// @deprecated Use [unifiedWeeklyStatsProvider] instead.
@riverpod
Future<WeeklyStatsModel> weeklyStats(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getWeeklyStats();
  return result.when(
    success: (model) => model,
    failure: (error) => throw error,
  );
}

// ──────────────────────────────────────────────────────────
// Recent Activity
// ──────────────────────────────────────────────────────────

/// Fetches recent completed workout sessions (limit 5).
@riverpod
Future<List<WorkoutSessionSummary>> recentActivity(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getSessionHistory(limit: 5, offset: 0);

  if (result is Success<WorkoutHistoryResponse, AppError>) {
    return result.value.sessions;
  }

  AppLogger.warning(
    'Session history unavailable — loading from local DB',
    tag: 'HomeProviders',
  );
  final userId = ref.read(authStateProvider).userId;
  if (userId != null) {
    final localResult = await repo.getLocalSessionHistory(
      userId: userId,
      limit: 5,
      offset: 0,
    );
    if (localResult is Success<WorkoutHistoryResponse, AppError>) {
      return localResult.value.sessions;
    }
  }
  return const [];
}
