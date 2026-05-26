import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_stats_provider.g.dart';

@riverpod
Future<StandaloneStats> standaloneStats(Ref ref) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getStats();
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
}

@riverpod
Future<StandaloneExerciseStat> standaloneExerciseStat(
  Ref ref,
  String exerciseId,
) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getExerciseStat(exerciseId);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
}
