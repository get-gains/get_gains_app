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

class StandaloneProgramPaginationState {
  const StandaloneProgramPaginationState({
    this.offset = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final int offset;
  final bool hasMore;
  final bool isLoadingMore;

  StandaloneProgramPaginationState copyWith({
    int? offset,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return StandaloneProgramPaginationState(
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

@riverpod
class StandaloneProgramPaginationNotifier
    extends _$StandaloneProgramPaginationNotifier {
  @override
  StandaloneProgramPaginationState build() =>
      const StandaloneProgramPaginationState();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await _repo.getPrograms(
      limit: 20,
      offset: state.offset,
    );

    result.when(
      success: (data) {
        state = state.copyWith(
          offset: state.offset + data.programs.length,
          hasMore: data.hasMore,
          isLoadingMore: false,
        );
        ref.invalidate(standaloneProgramListProvider);
      },
      failure: (_) {
        state = state.copyWith(isLoadingMore: false);
      },
    );
  }

  Future<void> reset() async {
    state = const StandaloneProgramPaginationState();
    ref.invalidate(standaloneProgramListProvider);
  }
}
