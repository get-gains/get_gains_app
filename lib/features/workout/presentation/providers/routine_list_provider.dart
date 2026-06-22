import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

part 'routine_list_provider.g.dart';

@riverpod
Future<List<RoutineModel>> routineList(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);

  final syncResult = await repo.syncRoutines();
  return syncResult.when(
    success: (routines) => routines,
    failure: (_) async {
      final localResult = await repo.getRoutines();
      return localResult.valueOrNull ?? [];
    },
  );
}
