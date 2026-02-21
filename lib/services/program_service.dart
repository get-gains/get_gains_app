import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_gains_app/services/api/api_client.dart' show ApiClient, apiClientProvider;

final programServiceProvider = Provider<ProgramService>((ref) {
  final api = ref.read(apiClientProvider);
  return ProgramService(api);
});

final programsProvider = FutureProvider<List<dynamic>>((ref) =>
  ref.read(programServiceProvider).getPrograms(),
);

final programRoutinesProvider =
    FutureProvider.family<List<dynamic>, String>((ref, programId) =>
  ref.read(programServiceProvider).getProgramRoutines(programId),
);

class ProgramService {
  final ApiClient api;

  ProgramService(this.api);

  Future<List<dynamic>> getPrograms() async {
    print('📡 Fetching programs...');
    final result = await api.get<List<dynamic>>('/programs');

    return result.when(
      success: (data) {
        print('✅ Programs loaded: $data');
        return data ?? [];
      },
      failure: (error) {
        print('❌ Error: ${error.message}');
        throw Exception(error.message);
      },
    );
  }

  Future<List<dynamic>> getProgramRoutines(String programId) async {
    final result = await api.get<List<dynamic>>('/programs/$programId/routines');

    return result.when(
      success: (data) => data,
      failure: (error) {
        throw Exception(error.message);
      },
    );
  }

  Future<void> createProgram({
    required String name,
    required String description,
  }) async {
    final result = await api.post(
      '/programs',
      data: {
        'name': name,
        'description': description,
      },
    );

    result.when(
      success: (_) {},
      failure: (error) {
        throw Exception(error.message);
      },
    );
  }
}
