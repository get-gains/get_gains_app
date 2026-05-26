import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_session_provider.g.dart';

@riverpod
class StandaloneSessionNotifier extends _$StandaloneSessionNotifier {
  @override
  Future<StandaloneSession?> build() async {
    final repo = ref.read(standaloneWorkoutRepositoryProvider);
    final result = await repo.getActiveSession();
    return result.when(
      success: (data) => data,
      failure: (error) {
        AppLogger.debug('No active session', tag: 'StandaloneSession');
        return null;
      },
    );
  }

  Future<void> startSession(String programRoutineId) async {
    state = const AsyncLoading();
    final repo = ref.read(standaloneWorkoutRepositoryProvider);
    final result = await repo.startSession(
      StartStandaloneSessionRequest(programRoutineId: programRoutineId),
    );
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }

  Future<void> logSet(LogStandaloneSetRequest request) async {
    final current = state.value;
    if (current == null) return;
    final repo = ref.read(standaloneWorkoutRepositoryProvider);
    final result = await repo.logSet(current.id, request);
    result.when(
      success: (set) {
        final updated = current.copyWith(
          performedSets: [...current.performedSets, set],
        );
        state = AsyncData(updated);
      },
      failure: (error) {
        AppLogger.error('Failed to log set', tag: 'StandaloneSession', error: error);
      },
    );
  }

  Future<void> completeSession({String? feedback}) async {
    final current = state.value;
    if (current == null) return;
    final repo = ref.read(standaloneWorkoutRepositoryProvider);
    final result = await repo.completeSession(current.id, feedback: feedback);
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(standaloneWorkoutRepositoryProvider);
    final result = await repo.getActiveSession();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }
}

@riverpod
Future<StandaloneSessionListResponse> standaloneSessionHistory(
  Ref ref, {
  int limit = 20,
  int offset = 0,
}) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getSessionHistory(limit: limit, offset: offset);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
}
