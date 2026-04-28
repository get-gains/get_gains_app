import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import 'models/models.dart';

part 'coach_repository.g.dart';

/// Coach Repository (Client-Facing)
///
/// Handles coach discovery, profile viewing, and subscription management
/// from the **client** perspective. All endpoints live under `/user/coaches`.
///
/// Addresses Missing Links:
/// - ML-1: [getCoachProfile] fetches a single coach's public profile
/// - ML-2: [subscribeToCoach] — server enforces `requireSubscription()`;
///   a 403 is returned to free-tier users (no client-side guard needed)
/// - ML-5: [subscribeToCoach] — server enforces capacity checks;
///   a 409 is returned when the coach is full or not accepting clients
///
/// Usage:
/// ```dart
/// final coachRepo = ref.read(coachRepositoryProvider);
///
/// // Discover coaches
/// final coaches = await coachRepo.discoverCoaches();
///
/// // View a single coach profile (ML-1)
/// final profile = await coachRepo.getCoachProfile('coach-id');
///
/// // Subscribe to a coach (guarded by ML-2 + ML-5 server-side)
/// final result = await coachRepo.subscribeToCoach('coach-id');
/// ```
class CoachRepository {
  CoachRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============== Discovery ==============

  /// Discover public coaches with optional search/pagination.
  ///
  /// `GET /user/coaches` — public, no auth required.
  Future<Result<CoachListResponse, AppError>> discoverCoaches({
    String? search,
    String? specialty,
    int limit = 50,
    int offset = 0,
  }) async {
    AppLogger.debug(
      'Discovering coaches: search=$search, specialty=$specialty',
      tag: 'CoachRepo',
    );

    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (search != null && search.isNotEmpty) 'search': search,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.discoverCoaches,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final response = CoachListResponse.fromJson(data);
          AppLogger.info(
            'Discovered ${response.coaches.length} coaches '
            '(total: ${response.pagination.total})',
            tag: 'CoachRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse discover coaches response',
            tag: 'CoachRepo',
            error: e,
          );
          return Failure(
            UnknownError(message: 'Failed to parse coaches', originalError: e),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to discover coaches',
          tag: 'CoachRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  // ============== Coach Profile (ML-1) ==============

  /// Fetch a single coach's full public profile.
  ///
  /// `GET /user/coaches/:coachId` — public, no auth required.
  /// Returns extended fields (e.g. `socialLinks`) not present in the list.
  Future<Result<CoachDetailModel, AppError>> getCoachProfile(
    String coachId,
  ) async {
    AppLogger.debug('Fetching coach profile: $coachId', tag: 'CoachRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.discoverCoaches}/$coachId',
    );

    return result.when(
      success: (data) {
        try {
          final coachData = data['coach'] as Map<String, dynamic>?;
          if (coachData == null) {
            throw StateError('Response missing coach data');
          }
          final coach = CoachDetailModel.fromJson(coachData);
          AppLogger.info(
            'Fetched coach profile: ${coach.name}',
            tag: 'CoachRepo',
          );
          return Success(coach);
        } catch (e) {
          AppLogger.error(
            'Failed to parse coach profile',
            tag: 'CoachRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse coach profile',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch coach profile: $coachId',
          tag: 'CoachRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  // ============== Subscribed Coaches ==============

  /// Get the current user's subscribed coaches.
  ///
  /// `GET /user/coaches/subscribed` — requires auth.
  Future<Result<CoachListResponse, AppError>> getSubscribedCoaches({
    int limit = 50,
    int offset = 0,
  }) async {
    AppLogger.debug('Fetching subscribed coaches', tag: 'CoachRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.subscribedCoaches,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        try {
          final response = CoachListResponse.fromJson(data);
          AppLogger.info(
            'Fetched ${response.coaches.length} subscribed coaches',
            tag: 'CoachRepo',
          );
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse subscribed coaches',
            tag: 'CoachRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse subscribed coaches',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch subscribed coaches',
          tag: 'CoachRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  // ============== Subscribe / Unsubscribe ==============

  /// Subscribe to a coach.
  ///
  /// `POST /user/coaches/:coachId` — requires auth + platform subscription.
  ///
  /// Server-side guards (ML-2 + ML-5):
  /// - Returns 403 if user has no active platform subscription
  /// - Returns 409 if coach is not accepting clients
  /// - Returns 409 if coach has reached max client capacity
  /// - Returns 409 if already subscribed
  Future<Result<CoachSummaryModel, AppError>> subscribeToCoach(
    String coachId,
  ) async {
    AppLogger.debug('Subscribing to coach: $coachId', tag: 'CoachRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.discoverCoaches}/$coachId',
    );

    return result.when(
      success: (data) {
        try {
          final coachData = data['coach'] as Map<String, dynamic>?;
          if (coachData == null) {
            throw StateError('Response missing coach data');
          }
          final coach = CoachSummaryModel.fromJson(coachData);
          AppLogger.info(
            'Subscribed to coach: ${coach.name}',
            tag: 'CoachRepo',
          );
          return Success(coach);
        } catch (e) {
          AppLogger.error(
            'Failed to parse subscribe response',
            tag: 'CoachRepo',
            error: e,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse subscribe response',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to subscribe to coach: $coachId',
          tag: 'CoachRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }

  /// Unsubscribe from a coach.
  ///
  /// `DELETE /user/coaches/:coachId` — requires auth.
  Future<Result<void, AppError>> unsubscribeFromCoach(String coachId) async {
    AppLogger.debug('Unsubscribing from coach: $coachId', tag: 'CoachRepo');

    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.discoverCoaches}/$coachId',
    );

    return result.when(
      success: (_) {
        AppLogger.info('Unsubscribed from coach: $coachId', tag: 'CoachRepo');
        return const Success(null);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to unsubscribe from coach: $coachId',
          tag: 'CoachRepo',
          error: error,
        );
        return Failure(error);
      },
    );
  }
}

/// Coach Repository Provider
@Riverpod(keepAlive: true)
CoachRepository coachRepository(Ref ref) {
  return CoachRepository(apiClient: ref.watch(apiClientProvider));
}
