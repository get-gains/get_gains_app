import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

part 'calendar_provider.g.dart';

/// Fetches workout sessions for a given month, grouped by local day.
///
/// Strategy (online-first with local fallback):
/// 1. Call `GET /sessions/calendar?month=YYYY-MM` — returns both
///    coach-assigned AND standalone sessions from the server.
/// 2. If the server call fails (offline, error), fall back to the local
///    Drift DB which contains only coach-assigned sessions.
///
/// This ensures standalone workouts (e.g. "Pullers", "uper") that are
/// stored exclusively on the server always appear on the calendar when
/// the user has connectivity.
@riverpod
Future<Map<DateTime, List<WorkoutSessionSummary>>> monthlyWorkoutDays(
  Ref ref,
  DateTime month,
) async {
  final auth = ref.watch(authStateProvider);
  final userId = auth.userId;

  if (userId == null) {
    AppLogger.warning(
      'No authenticated user — cannot load calendar',
      tag: 'CalendarProvider',
    );
    return {};
  }

  final repo = ref.watch(workoutRepositoryProvider);

  // ── 1. Try server first (includes standalone + coach sessions) ──
  final serverResult = await repo.getServerSessionsForMonth(month);

  final sessions = serverResult.when(
    success: (sessions) => sessions,
    failure: (error) {
      // Server unavailable — log and fall through to local DB
      AppLogger.warning(
        'Server calendar unavailable, using local DB: ${error.message}',
        tag: 'CalendarProvider',
      );
      return null;
    },
  );

  if (sessions != null) {
    return _groupByLocalDay(sessions);
  }

  // ── 2. Fallback: local DB (coach sessions only) ──
  AppLogger.info(
    'Falling back to local DB for calendar month ${month.year}-${month.month}',
    tag: 'CalendarProvider',
  );

  final localResult = await repo.getLocalSessionsForMonth(userId, month);

  return localResult.when(
    success: (localSessions) => _groupByLocalDay(localSessions),
    failure: (error) {
      AppLogger.warning(
        'Failed to load monthly workout data: ${error.message}',
        tag: 'CalendarProvider',
      );
      throw error;
    },
  );
}

/// Groups a flat list of sessions by their local calendar day.
///
/// Converts UTC [startedAt] timestamps to local time before extracting the
/// date so that sessions done in UTC+N timezones are grouped under the
/// correct local day.
Map<DateTime, List<WorkoutSessionSummary>> _groupByLocalDay(
  List<WorkoutSessionSummary> sessions,
) {
  final map = <DateTime, List<WorkoutSessionSummary>>{};
  for (final s in sessions) {
    final localStart = s.startedAt.toLocal();
    final day = DateTime(localStart.year, localStart.month, localStart.day);
    map.putIfAbsent(day, () => []).add(s);
  }
  return map;
}
