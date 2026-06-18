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
  /// User has no subscribed coach (paid tier) → show "Find a Coach" CTA.
  noCoach,

  /// User has no coach + no standalone program → show "Build My Program" CTA.
  buildProgram,

  /// User has a coach but no active program → show "Waiting for program".
  waitingForProgram,

  /// Today is a rest day within the active program.
  restDay,

  /// There is a routine scheduled for today → show routine card.
  hasRoutine,
}

/// Derives [HomeStatus] from [todayStatusProvider].
///
/// Priority:
///   1. Subscribed user with coach → coach program flow
///   2. Any user with a self-built standalone program → standalone flow
///   3. Everything else → "Build My Program" CTA
@riverpod
Future<HomeStatus> homeStatus(Ref ref) async {
  final s = await ref.watch(todayStatusProvider.future);

  // Coach path: only when subscribed AND has an active coach
  if (s.hasCoach && s.isSubscribed) {
    if (s.coachToday == null) return HomeStatus.waitingForProgram;
    if (s.coachToday!.isRestDay) return HomeStatus.restDay;
    return HomeStatus.hasRoutine;
  }

  // Standalone path: any user with an active self-built program
  if (s.standalone.hasActiveProgram) {
    return HomeStatus.hasRoutine;
  }

  // Paid user with no coach → show coach discovery
  if (s.isSubscribed && !s.hasCoach) {
    return HomeStatus.noCoach;
  }

  // No standalone program available
  return HomeStatus.buildProgram;
}

// ──────────────────────────────────────────────────────────
// Active Today (coach first, standalone fallback)
// ──────────────────────────────────────────────────────────

/// Resolves today's routine as [TodayRoutineModel].
///
/// Prefers coach today when subscribed; falls back to standalone for free-tier
/// users. Returns a non-rest-day model when no program exists so the card
/// falls through to the "Build My Program" CTA in [TodayHeroBlock].
@riverpod
Future<TodayRoutineModel> activeToday(Ref ref) async {
  final s = await ref.watch(todayStatusProvider.future);

  // Coach flow (subscribed + has coach)
  if (s.hasCoach && s.isSubscribed && s.coachToday != null) {
    return s.coachToday!.toRoutineModel();
  }

  // Standalone flow — show the active program info
  if (s.standalone.hasActiveProgram && s.standalone.program != null) {
    return TodayRoutineModel(
      isRestDay: false,
      today: TodayRoutineDetails(
        programRoutineId: '',
        dayOfWeek: '',
        assignedProgramId: s.standalone.program!.id,
        programName: s.standalone.program!.name,
        routine: RoutineModel(
          id: s.standalone.program!.id,
          name: s.standalone.program!.name,
          description: '',
          estimatedDurationMinutes: 0,
          exercises: const [],
        ),
      ),
    );
  }

  // No program at all — return a non-rest-day model so the card
  // falls through to the "Build My Program" CTA in TodayHeroBlock.
  return const TodayRoutineModel(isRestDay: false);
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

/// Fetches recent completed workout sessions (limit 5) from the unified
/// session history endpoint (`GET /api/sessions/history`). Falls back to
/// the local database when the server is unreachable.
@riverpod
Future<List<WorkoutSessionSummary>> recentActivity(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getUnifiedSessionHistory(
    source: 'all',
    limit: 5,
    offset: 0,
  );

  if (result is Success<UnifiedSessionHistoryResponse, AppError>) {
    return result.value.sessions
        .map(
          (s) => WorkoutSessionSummary(
            id: s.id,
            userId: s.userId,
            assignedProgramId: s.assignedProgramId,
            routineId: s.routineId,
            startedAt: s.startedAt,
            completedAt: s.completedAt,
            notes: s.notes,
            totalSets: s.totalSets,
            routineName: s.routineName,
          ),
        )
        .toList();
  }

  AppLogger.warning(
    'Unified session history unavailable — loading from local DB',
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

// ──────────────────────────────────────────────────────────
// Monthly Insight
// ──────────────────────────────────────────────────────────

/// Fetches monthly training insight from `GET /api/stats/monthly-insight?month=YYYY-MM`.
/// Includes avg volume/session, trend %, 6-month sparkline, and top exercise weight gains.
@riverpod
Future<MonthlyInsight> monthlyInsight(Ref ref) async {
  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getMonthlyInsight(month);
  return result.when(
    success: (model) => model,
    failure: (error) => throw error,
  );
}
