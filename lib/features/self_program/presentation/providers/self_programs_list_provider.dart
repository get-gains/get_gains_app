import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../coach_programs/data/models/program_model.dart';
import '../../data/self_program_repository.dart';

part 'self_programs_list_provider.g.dart';

@riverpod
class SelfProgramsList extends _$SelfProgramsList {
  @override
  FutureOr<List<ClientProgramModel>> build() async {
    return _fetchPrograms();
  }

  Future<List<ClientProgramModel>> _fetchPrograms() async {
    final repo = ref.read(selfProgramRepositoryProvider);
    final result = await repo.getSelfPrograms();

    return result.when(
      success: (data) => data.programs,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchPrograms);
  }

  Future<void> deleteProgram(String programId) async {
    final repo = ref.read(selfProgramRepositoryProvider);
    final result = await repo.deleteProgram(programId);

    result.when(
      success: (_) {
        // Optimistic update
        if (state.hasValue) {
          final updated = state.value!.where((p) => p.id != programId).toList();
          state = AsyncValue.data(updated);
        } else {
          refresh();
        }
      },
      failure: (error) {
        // Do nothing on UI for now, let it be
      },
    );
  }
}
