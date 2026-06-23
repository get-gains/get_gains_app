// lib/features/workout/presentation/providers/session_detail_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

part 'session_detail_provider.g.dart';

// ──────────────────────────────────────────────────────────
// Legacy wrapper kept for backward-compat during migration
// ──────────────────────────────────────────────────────────

/// Full session detail including routine name (local DB path).
class SessionDetail {
  const SessionDetail({required this.session, this.routineName});

  final WorkoutSessionModel session;
  final String? routineName;
}

// ──────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────

/// Loads full session detail by its ID.
///
/// Lookup strategy:
/// 1. Try local Drift DB (coach sessions synced locally — instant, offline-ok)
/// 2. If local returns null, call `GET /sessions/:id` (standalone from server)
///
/// Returns [UnifiedSessionDetail] on success, null if not found, throws on error.
@riverpod
Future<UnifiedSessionDetail?> sessionDetail(
  Ref ref,
  String sessionId,
) async {
  final repo = ref.watch(workoutRepositoryProvider);

  // ── 1. Try local DB (coach sessions synced to Drift) ──
  final localResult = await repo.getWorkoutSession(sessionId);
  final localSession = localResult.when(
    success: (s) => s,
    failure: (_) => null,
  );
  if (localSession != null) {
      // Build exercise groups from performed sets
      final exerciseGroups = <String, List<UnifiedSet>>{};
      final exerciseNames = <String, String>{};
      final exerciseVolumes = <String, double>{};

      for (final ps in localSession.performedSets) {
        final name = ps.exerciseNameSnapshot ?? 'Exercise';
        final exId = ps.assignedProgramRoutineExerciseId;
        exerciseNames[exId] = name;
        exerciseGroups.putIfAbsent(exId, () => []);
        final vol = ps.repsCompleted * (ps.weightKg ?? 0);
        exerciseGroups[exId]!.add(
          UnifiedSet(
            id: ps.id,
            setNumber: ps.setNumber,
            repsCompleted: ps.repsCompleted,
            weightKg: ps.weightKg,
            rpe: ps.rpe?.toDouble(),
          ),
        );
        exerciseVolumes[exId] = (exerciseVolumes[exId] ?? 0) + vol;
      }

      final exercises = exerciseGroups.entries.map((e) {
        return UnifiedExerciseGroup(
          exerciseId: e.key,
          exerciseName: exerciseNames[e.key] ?? 'Exercise',
          sets: e.value,
          totalVolumeKg: exerciseVolumes[e.key] ?? 0,
        );
      }).toList();

      String? routineName;
      if (localSession.routineId != null) {
        final routineResult = await repo.getRoutineById(localSession.routineId!);
        routineResult.when(
          success: (r) => routineName = r?.name,
          failure: (_) {},
        );
      }

      final duration = localSession.completedAt?.difference(localSession.startedAt);

      return UnifiedSessionDetail(
        id: sessionId,
        source: 'coach',
        routineName: routineName ?? 'Workout',
        programName: null,
        startedAt: localSession.startedAt,
        completedAt: localSession.completedAt,
        durationMinutes: duration?.inMinutes,
        notes: localSession.notes,
        exercises: exercises,
        totalSets: localSession.completedSetsCount,
        totalReps: localSession.performedSets
            .fold(0, (s, ps) => s + ps.repsCompleted),
        totalVolumeKg: localSession.totalVolume,
      );
  }

  // ── 2. Fallback: fetch from server (standalone sessions & coach not in DB) ──
  AppLogger.info(
    'Local session not found — fetching from server: $sessionId',
    tag: 'SessionDetailProvider',
  );

  final result = await repo.getSessionDetail(sessionId);

  return result.when(
    success: (detail) => detail,
    failure: (error) {
      AppLogger.warning(
        'Server session detail fetch failed: ${error.message}',
        tag: 'SessionDetailProvider',
      );
      throw error;
    },
  );
}
