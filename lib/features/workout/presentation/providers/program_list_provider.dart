import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

part 'program_list_provider.g.dart';

@riverpod
Future<List<AssignedProgramModel>> programList(Ref ref) async {
  final repo = ref.watch(workoutRepositoryProvider);

  final syncResult = await repo.syncPrograms();
  return syncResult.when(
    success: (programs) => programs,
    failure: (_) async {
      final localResult = await repo.getPrograms();
      return localResult.valueOrNull ?? [];
    },
  );
}
