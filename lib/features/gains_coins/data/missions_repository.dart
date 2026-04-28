import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart' show ApiClient, apiClientProvider;
import 'models/mission_list_item_model.dart';

part 'missions_repository.g.dart';

/// Fetches active missions from GET /api/missions.
class MissionsRepository {
  MissionsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<List<MissionListItemModel>, AppError>> fetchActiveMissions() async {
    AppLogger.debug('Fetching missions from server', tag: 'MissionsRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.missions,
    );

    return result.when(
      success: (data) {
        try {
          final raw = data['missions'] as List<dynamic>? ?? [];
          final missions = raw
              .map(
                (e) =>
                    MissionListItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          return Success(missions);
        } catch (e, st) {
          AppLogger.error(
            'Failed to parse missions',
            tag: 'MissionsRepo',
            error: e,
            stackTrace: st,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse missions: $e'),
          );
        }
      },
      failure: Failure.new,
    );
  }
}

@Riverpod(keepAlive: false)
MissionsRepository missionsRepository(Ref ref) {
  return MissionsRepository(apiClient: ref.watch(apiClientProvider));
}
