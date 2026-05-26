import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_program_provider.g.dart';

@riverpod
Future<StandaloneProgramListResponse> standaloneProgramList(
  Ref ref,
) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getPrograms();
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
}

@riverpod
Future<StandaloneProgramDetail> standaloneProgramDetail(
  Ref ref,
  String programId,
) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getProgram(programId);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
}

@riverpod
Future<StandaloneProgramDetail?> standaloneActiveProgram(
  Ref ref,
) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getActiveProgram();
  return result.when(
    success: (data) => data,
    failure: (error) {
      AppLogger.debug(
        'No active standalone program',
        tag: 'StandaloneProgram',
      );
      return null;
    },
  );
}
