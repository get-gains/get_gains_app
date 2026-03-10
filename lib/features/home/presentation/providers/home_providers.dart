import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../coaches/data/coach_repository.dart';
import '../../../coaches/data/models/models.dart';
import '../../../standalone_workout/data/standalone_workout_repository.dart';
import '../../../workout/data/models/models.dart';
import '../../../workout/data/workout_repository.dart';

part 'home_providers.g.dart';

// ──────────────────────────────────────────────────────────
// Today's Routine
// ──────────────────────────────────────────────────────────

/// Fetches the user's scheduled routine for today from
/// `GET /api/workout/today`.
///
/// Auto-disposes when the home screen is no longer visible.
/// Call `ref.invalidate(todayRoutineProvider)` to force refresh.
@riverpod
Future<TodayRoutineModel> todayRoutine(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getTodayRoutine();
  return result.when(
    success: (model) => model,
    failure: (error) => throw error,
  );
}

// ──────────────────────────────────────────────────────────
// Active Today (with standalone fallback)
// ──────────────────────────────────────────────────────────

/// Resolves today's routine, transparently falling back to the standalone
/// workout program when the user has no active coach subscription.
///
/// - Has subscription → returns today from `GET /api/workout/today`
/// - No subscription (403) → falls back to `GET /api/standalone/today`
///   (converts [StandaloneTodayModel] fields into [TodayRoutineModel] so the
///   home screen does not need to know which path was taken).
///
/// The [homeStatusProvider] separately surfaces [HomeStatus.noSubscription]
/// so the CTA section can prompt the user to upgrade.
@riverpod
Future<TodayRoutineModel> activeToday(Ref ref) async {
  try {
    return await ref.watch(todayRoutineProvider.future);
  } on SubscriptionRequiredError {
    // Coach endpoint requires subscription — fall back to the user's own
    // standalone program so the home screen always shows something useful.
    AppLogger.info(
      'No subscription — falling back to standalone today',
      tag: 'HomeProviders',
    );
    final standaloneRepo = ref.watch(standaloneWorkoutRepositoryProvider);
    final result = await standaloneRepo.getTodayRoutine();
    return result.when(
      success: (model) => TodayRoutineModel(
        isRestDay: model.isRestDay,
        today: model.today != null
            ? TodayRoutineDetails(
                programRoutineId: model.today!.programRoutineId,
                dayNumber: model.today!.dayNumber,
                assignedProgramId: model.today!.assignedProgramId,
                programName: model.today!.programName,
                routine: model.today!.routine,
              )
            : null,
      ),
      failure: (error) => throw error,
    );
  }
}

// ──────────────────────────────────────────────────────────
// Weekly Stats (Unified)
// ──────────────────────────────────────────────────────────

/// Fetches unified weekly workout statistics from
/// `GET /api/stats/weekly`.
///
/// Returns combined totals and per-source breakdowns
/// (standalone / coach) for the current week.
/// Free users receive standalone-only sources;
/// subscribed users see both standalone and coach.
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
// Weekly Stats (Legacy — retained for backward compatibility)
// ──────────────────────────────────────────────────────────

/// Fetches aggregated weekly workout statistics from
/// `GET /api/workout/stats/weekly`.
///
/// Returns workouts completed, total minutes, and streak days
/// for the current week.
///
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

/// Fetches recent completed workout sessions (limit 5) for the
/// "Recent Activity" section on the home screen.
@riverpod
Future<List<WorkoutSessionSummary>> recentActivity(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getSessionHistory(limit: 5, offset: 0);
  return result.when(
    success: (response) => response.sessions,
    failure: (error) => throw error,
  );
}

// ──────────────────────────────────────────────────────────
// Has Subscribed Coach
// ──────────────────────────────────────────────────────────

/// Checks whether the current user has at least one subscribed coach.
///
/// Used on the home screen to determine whether to show:
/// - "Find a Coach" CTA (no coach)
/// - "Waiting for program" (coach but no program)
/// - Today's routine (coach + assigned program)
@riverpod
Future<bool> hasSubscribedCoach(Ref ref) async {
  final coachRepo = ref.watch(coachRepositoryProvider);
  final result = await coachRepo.getSubscribedCoaches(limit: 1, offset: 0);
  return result.when(
    success: (response) => response.coaches.isNotEmpty,
    failure: (_) => false,
  );
}

/// Fetches the user's subscribed coaches summary (first page).
///
/// Provides more detail than [hasSubscribedCoachProvider] when the
/// home screen needs coach name/avatar for display.
@riverpod
Future<List<CoachSummaryModel>> subscribedCoachesSummary(Ref ref) async {
  final coachRepo = ref.watch(coachRepositoryProvider);
  final result = await coachRepo.getSubscribedCoaches(limit: 10, offset: 0);
  return result.when(
    success: (response) => response.coaches,
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

  /// User has a coach but no active program → show "Waiting for program".
  waitingForProgram,

  /// Today is a rest day within the active program.
  restDay,

  /// There is a routine scheduled for today → show routine card.
  hasRoutine,
}

/// Determines the [HomeStatus] by combining coach subscription and
/// today's routine data.
///
/// The presentation layer watches this to decide which home-screen
/// section to render. This keeps all status derivation logic out of
/// the widget tree.
@riverpod
Future<HomeStatus> homeStatus(Ref ref) async {
  final hasCoach = await ref.watch(hasSubscribedCoachProvider.future);
  if (!hasCoach) return HomeStatus.noCoach;

  try {
    final today = await ref.watch(todayRoutineProvider.future);
    if (today.isRestDay) return HomeStatus.restDay;
    if (today.today != null) return HomeStatus.hasRoutine;
    return HomeStatus.waitingForProgram;
  } on SubscriptionRequiredError {
    // Coach endpoint blocked — user needs to subscribe.
    return HomeStatus.noSubscription;
  } catch (_) {
    // If the today-routine call fails (e.g. no active program),
    // treat as waiting for program assignment.
    return HomeStatus.waitingForProgram;
  }
}
