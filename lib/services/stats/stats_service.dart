import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/app_error.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../api/api_client.dart';
import '../connectivity/connectivity_service.dart';
import '../database/app_database.dart';

part 'stats_service.g.dart';

class StatsData {
  final int workoutsCompleted;
  final int totalMinutes;
  final int streakDays;
  final int totalSets;
  final int totalWorkouts;
  final String source;

  const StatsData({
    required this.workoutsCompleted,
    required this.totalMinutes,
    required this.streakDays,
    required this.totalSets,
    required this.totalWorkouts,
    required this.source,
  });
}

class StatsService {
  final AppDatabase _db;
  final ApiClient _api;
  final ConnectivityService _connectivity;

  StatsService(this._db, this._api, this._connectivity);

  Future<StatsData> getWeeklyStats(String userId) async {
    if (await _connectivity.isConnected()) {
      final result = await _api
          .get<Map<String, dynamic>>('/api/stats/weekly')
          .timeout(const Duration(seconds: 5));

      final serverStats = result.when(
        success: (data) => _parseServerStats(data),
        failure: (_) => null,
      );

      if (serverStats != null) {
        return serverStats;
      }
    }

    AppLogger.debug('Using local fallback for stats', tag: 'Stats');
    return _computeLocalStats(userId);
  }

  StatsData _parseServerStats(Map<String, dynamic> data) {
    final stats = data['stats'] as Map<String, dynamic>? ?? data;
    return StatsData(
      workoutsCompleted: (stats['workoutsCompleted'] as num?)?.toInt() ?? 0,
      totalMinutes: (stats['totalMinutes'] as num?)?.toInt() ?? 0,
      streakDays: (stats['streakDays'] as num?)?.toInt() ?? 0,
      totalSets: (stats['totalSets'] as num?)?.toInt() ?? 0,
      totalWorkouts: (stats['totalWorkouts'] as num?)?.toInt() ?? 0,
      source: 'server',
    );
  }

  Future<StatsData> _computeLocalStats(String userId) async {
    final completedCount = await _db.countCompletedSessions(userId);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final sessions = await _db.getCompletedSessionsInRange(
      userId,
      weekStartDay,
      now,
    );

    int totalMinutes = 0;
    for (final s in sessions) {
      if (s.startedAt != null && s.completedAt != null) {
        totalMinutes +=
            s.completedAt!.difference(s.startedAt!).inMinutes;
      }
    }

    int streakDays = 0;
    final dates = <DateTime>{};
    for (final s in sessions) {
      if (s.startedAt != null) {
        dates.add(DateTime(
          s.startedAt!.year,
          s.startedAt!.month,
          s.startedAt!.day,
        ));
      }
    }
    if (dates.isNotEmpty) {
      streakDays = dates.length;
    }

    return StatsData(
      workoutsCompleted: sessions.length,
      totalMinutes: totalMinutes,
      streakDays: streakDays,
      totalSets: 0,
      totalWorkouts: completedCount,
      source: 'local',
    );
  }
}

@Riverpod(keepAlive: true)
StatsService statsService(Ref ref) {
  return StatsService(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(connectivityServiceProvider),
  );
}
