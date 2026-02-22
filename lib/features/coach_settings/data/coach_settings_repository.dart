import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import 'models/models.dart';

part 'coach_settings_repository.g.dart';

/// Coach Settings Repository (ML-5)
///
/// Handles CRUD for coach settings — capacity, intake toggle, discoverability.
///
/// Endpoints:
/// - `GET /api/coach/settings` — fetch own settings
/// - `PATCH /api/coach/settings` — update settings
///
/// Usage:
/// ```dart
/// final settingsRepo = ref.read(coachSettingsRepositoryProvider);
///
/// // Get current settings
/// final settings = await settingsRepo.getSettings();
///
/// // Update settings
/// final updated = await settingsRepo.updateSettings(
///   UpdateCoachSettingsRequest(maxClients: 20, acceptingClients: false),
/// );
/// ```
class CoachSettingsRepository {
  CoachSettingsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============== Get Settings ==============

  /// Fetch the authenticated coach's settings.
  ///
  /// `GET /coach/settings`
  Future<Result<CoachSettingsModel, AppError>> getSettings() async {
    AppLogger.debug('Fetching coach settings', tag: 'CoachSettingsRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.coachSettings,
    );

    return result.when(
      success: (data) {
        try {
          final settings = CoachSettingsModel.fromJson(
            data['settings'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Fetched coach settings: maxClients=${settings.maxClients}, '
            'accepting=${settings.acceptingClients}, '
            'discoverable=${settings.isDiscoverable}',
            tag: 'CoachSettingsRepo',
          );
          return Success(settings);
        } catch (e) {
          AppLogger.error(
            'Failed to parse coach settings',
            tag: 'CoachSettingsRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse coach settings',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch coach settings',
          tag: 'CoachSettingsRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  // ============== Update Settings ==============

  /// Update the authenticated coach's settings.
  ///
  /// `PATCH /coach/settings`
  /// Only non-null fields in [request] are sent to the server.
  Future<Result<CoachSettingsModel, AppError>> updateSettings(
    UpdateCoachSettingsRequest request,
  ) async {
    AppLogger.debug('Updating coach settings', tag: 'CoachSettingsRepo');

    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiConstants.coachSettings,
      data: request.toJsonNonNull(),
    );

    return result.when(
      success: (data) {
        try {
          final settings = CoachSettingsModel.fromJson(
            data['settings'] as Map<String, dynamic>,
          );
          AppLogger.info(
            'Updated coach settings: maxClients=${settings.maxClients}, '
            'accepting=${settings.acceptingClients}, '
            'discoverable=${settings.isDiscoverable}',
            tag: 'CoachSettingsRepo',
          );
          return Success(settings);
        } catch (e) {
          AppLogger.error(
            'Failed to parse updated coach settings',
            tag: 'CoachSettingsRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse updated settings',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to update coach settings',
          tag: 'CoachSettingsRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }
}

/// Coach Settings Repository Provider
@Riverpod(keepAlive: true)
CoachSettingsRepository coachSettingsRepository(Ref ref) {
  return CoachSettingsRepository(apiClient: ref.watch(apiClientProvider));
}
