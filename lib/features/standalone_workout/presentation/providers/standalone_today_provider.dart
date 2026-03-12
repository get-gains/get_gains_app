import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_today_provider.g.dart';

// ──────────────────────────────────────────────────────────
// Today's Workout Provider (Server-Only)
// ──────────────────────────────────────────────────────────

/// Fetches today's workout from the server day-cycling logic.
/// Returns rest day or the resolved routine for today.
@riverpod
Future<StandaloneTodayModel> standaloneToday(Ref ref) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getTodayRoutine();
  return result.when(
    success: (today) => today,
    failure: (error) {
      AppLogger.warning('Failed to fetch today routine', error: error);
      throw error;
    },
  );
}

/// Fetches today's workout for a specific assigned program.
@riverpod
Future<StandaloneTodayModel> standaloneTodayForProgram(
  Ref ref,
  String assignedProgramId,
) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getTodayRoutine(
    assignedProgramId: assignedProgramId,
  );
  return result.when(
    success: (today) => today,
    failure: (error) {
      AppLogger.warning(
        'Failed to fetch today routine for program',
        error: error,
      );
      throw error;
    },
  );
}
