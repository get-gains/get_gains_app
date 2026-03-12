import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../coach_programs/data/models/program_model.dart';
import 'models/models.dart';

part 'coach_client_progress_repository.g.dart';

/// Repository for coach-facing client progress endpoints.
///
/// Provides access to:
/// - Client session list & detail
/// - Client weekly stats (with deltas)
/// - Client exercise history (per-exercise progress over time)
/// - Detailed performance report (all clients, volume + adherence)
/// - Client form comparison results
class CoachClientProgressRepository {
  CoachClientProgressRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const _tag = 'CoachClientProgressRepo';

  // ──────────────────────────────────────────────────
  // 1. Client Sessions (List)
  // ──────────────────────────────────────────────────

  /// Fetches a paginated list of workout sessions for a specific client.
  ///
  /// [userId] - CUID of the client.
  /// [limit] - Page size (1-100, default 20).
  /// [offset] - Pagination offset (default 0).
  /// [status] - Filter: 'completed', 'active', or 'all' (default 'completed').
  /// [startDate] - Optional ISO datetime filter (session start >=).
  /// [endDate] - Optional ISO datetime filter (session start <=).
  Future<
    Result<
      ({List<ClientSessionSummary> sessions, PaginationMeta pagination}),
      AppError
    >
  >
  getClientSessions(
    String userId, {
    int limit = 20,
    int offset = 0,
    String status = 'completed',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'status': status,
    };
    if (startDate != null) {
      queryParams['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toUtc().toIso8601String();
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.coachClients}/$userId/sessions',
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final sessions = (data['sessions'] as List<dynamic>)
              .map(
                (e) => ClientSessionSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          final pagination = PaginationMeta.fromJson(
            data['pagination'] as Map<String, dynamic>,
          );
          return Success((sessions: sessions, pagination: pagination));
        } catch (e) {
          AppLogger.error(
            'Failed to parse client sessions response: $e',
            tag: _tag,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse client sessions',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch client sessions', tag: _tag);
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // 2. Client Session Detail
  // ──────────────────────────────────────────────────

  /// Fetches full detail for a specific client workout session.
  ///
  /// [userId] - CUID of the client.
  /// [sessionId] - CUID of the session.
  Future<Result<ClientSessionDetail, AppError>> getClientSessionDetail(
    String userId,
    String sessionId,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.coachClients}/$userId/sessions/$sessionId',
    );

    return result.when(
      success: (data) {
        try {
          final session = ClientSessionDetail.fromJson(
            data['session'] as Map<String, dynamic>,
          );
          return Success(session);
        } catch (e) {
          AppLogger.error(
            'Failed to parse session detail response: $e',
            tag: _tag,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse session detail',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error(
          'Failed to fetch session detail for $sessionId',
          tag: _tag,
        );
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // 3. Client Weekly Stats
  // ──────────────────────────────────────────────────

  /// Fetches weekly aggregated stats for a client with previous-week deltas.
  ///
  /// [userId] - CUID of the client.
  /// [weekOf] - Optional ISO datetime to determine the target week
  ///            (defaults to current week on the server).
  Future<Result<ClientWeeklyStats, AppError>> getClientWeeklyStats(
    String userId, {
    DateTime? weekOf,
  }) async {
    final queryParams = <String, dynamic>{};
    if (weekOf != null) {
      queryParams['weekOf'] = weekOf.toUtc().toIso8601String();
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.coachClients}/$userId/stats/weekly',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return result.when(
      success: (data) {
        try {
          final stats = ClientWeeklyStats.fromJson(
            data['stats'] as Map<String, dynamic>,
          );
          return Success(stats);
        } catch (e) {
          AppLogger.error(
            'Failed to parse weekly stats response: $e',
            tag: _tag,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse weekly stats',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch weekly stats', tag: _tag);
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // 4. Client Exercise History
  // ──────────────────────────────────────────────────

  /// Fetches exercise-level progress over time for a specific client/exercise.
  ///
  /// [userId] - CUID of the client.
  /// [exerciseId] - CUID of the exercise.
  /// [limit] - Max sessions to return (1-100, default 20).
  Future<Result<ClientExerciseHistoryResponse, AppError>>
  getClientExerciseHistory(
    String userId,
    String exerciseId, {
    int limit = 20,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.coachClients}/$userId/exercises/$exerciseId/history',
      queryParameters: {'limit': limit},
    );

    return result.when(
      success: (data) {
        try {
          final response = ClientExerciseHistoryResponse.fromJson(data);
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse exercise history response: $e',
            tag: _tag,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse exercise history',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch exercise history', tag: _tag);
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // 5. Detailed Performance Report
  // ──────────────────────────────────────────────────

  /// Fetches the enhanced performance report for all of a coach's clients.
  ///
  /// Includes volume, adherence rate, session duration, and status per client.
  ///
  /// [limit] - Page size (1-100, default 50).
  /// [offset] - Pagination offset (default 0).
  Future<
    Result<
      ({
        List<ClientPerformanceEntry> performance,
        PerformanceSummary summary,
        PaginationMeta pagination,
      }),
      AppError
    >
  >
  getDetailedPerformance({int limit = 50, int offset = 0}) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.coachPerformanceDetailed,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.when(
      success: (data) {
        try {
          final performance = (data['performance'] as List<dynamic>)
              .map(
                (e) =>
                    ClientPerformanceEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          final summary = PerformanceSummary.fromJson(
            data['summary'] as Map<String, dynamic>,
          );
          final pagination = PaginationMeta.fromJson(
            data['pagination'] as Map<String, dynamic>,
          );
          return Success((
            performance: performance,
            summary: summary,
            pagination: pagination,
          ));
        } catch (e) {
          AppLogger.error(
            'Failed to parse detailed performance response: $e',
            tag: _tag,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse detailed performance',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch detailed performance', tag: _tag);
        return Failure(error);
      },
    );
  }

  // ──────────────────────────────────────────────────
  // 6. Client Form Results
  // ──────────────────────────────────────────────────

  /// Fetches paginated form comparison results for a client.
  ///
  /// [userId] - CUID of the client.
  /// [exerciseId] - Optional filter to a specific exercise.
  /// [limit] - Page size (1-100, default 20).
  /// [offset] - Pagination offset (default 0).
  Future<
    Result<
      ({List<ClientFormResult> results, PaginationMeta pagination}),
      AppError
    >
  >
  getClientFormResults(
    String userId, {
    String? exerciseId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
    if (exerciseId != null) {
      queryParams['exerciseId'] = exerciseId;
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.coachClients}/$userId/form-results',
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final results = (data['results'] as List<dynamic>)
              .map((e) => ClientFormResult.fromJson(e as Map<String, dynamic>))
              .toList();
          final pagination = PaginationMeta.fromJson(
            data['pagination'] as Map<String, dynamic>,
          );
          return Success((results: results, pagination: pagination));
        } catch (e) {
          AppLogger.error(
            'Failed to parse form results response: $e',
            tag: _tag,
          );
          return Failure(
            UnknownError(
              message: 'Failed to parse form results',
              originalError: e,
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.error('Failed to fetch form results', tag: _tag);
        return Failure(error);
      },
    );
  }
}

/// Provides a singleton [CoachClientProgressRepository] instance.
@Riverpod(keepAlive: true)
CoachClientProgressRepository coachClientProgressRepository(Ref ref) {
  return CoachClientProgressRepository(apiClient: ref.watch(apiClientProvider));
}
