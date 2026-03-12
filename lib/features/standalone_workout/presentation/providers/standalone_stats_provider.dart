import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/weekly_stats_model.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_stats_provider.g.dart';

// ──────────────────────────────────────────────────────────
// Weekly Stats Provider (Server-Only)
// ──────────────────────────────────────────────────────────

/// Fetches aggregated weekly workout stats from the server.
@riverpod
Future<WeeklyStatsModel> standaloneWeeklyStats(Ref ref) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getWeeklyStats();
  return result.when(
    success: (stats) => stats,
    failure: (error) {
      AppLogger.warning('Failed to fetch weekly stats', error: error);
      throw error;
    },
  );
}

/// Fetches weekly stats for a specific week.
@riverpod
Future<WeeklyStatsModel> standaloneWeeklyStatsForWeek(
  Ref ref,
  DateTime weekOf,
) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getWeeklyStats(weekOf: weekOf);
  return result.when(
    success: (stats) => stats,
    failure: (error) {
      AppLogger.warning('Failed to fetch weekly stats for week', error: error);
      throw error;
    },
  );
}
