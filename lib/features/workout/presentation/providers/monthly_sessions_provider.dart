import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

part 'monthly_sessions_provider.g.dart';

/// Fetches completed sessions for a given month from the server.
///
/// Uses the existing calendar endpoint (`GET /sessions/calendar?month=YYYY-MM`)
/// which returns both coach and standalone sessions with totalSets and source.
/// Falls back to local Drift when the server is unreachable.
@riverpod
Future<List<WorkoutSessionSummary>> monthlySessions(
  Ref ref,
  String month,
) async {
  final [yearStr, monthStr] = month.split('-');
  final date = DateTime(int.parse(yearStr), int.parse(monthStr));
  final repo = ref.watch(workoutRepositoryProvider);

  final result = await repo.getServerSessionsForMonth(date);
  return result.when(
    success: (sessions) => sessions,
    failure: (error) async {
      AppLogger.warning(
        'Server monthly sessions failed, using local fallback',
        tag: 'MonthlySessions',
      );
      final userId = ref.read(authStateProvider).userId;
      if (userId == null) throw error;
      final localResult = await repo.getLocalSessionsForMonth(userId, date);
      return localResult.when(
        success: (sessions) => sessions,
        failure: (localError) => throw localError,
      );
    },
  );
}
