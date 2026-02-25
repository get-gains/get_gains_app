import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../coaches/data/coach_repository.dart';
import '../../../coaches/data/models/models.dart';
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
// Weekly Stats
// ──────────────────────────────────────────────────────────

/// Fetches aggregated weekly workout statistics from
/// `GET /api/workout/stats/weekly`.
///
/// Returns workouts completed, total minutes, and streak days
/// for the current week.
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
  } catch (_) {
    // If the today-routine call fails (e.g. no active program),
    // treat as waiting for program assignment.
    return HomeStatus.waitingForProgram;
  }
}
