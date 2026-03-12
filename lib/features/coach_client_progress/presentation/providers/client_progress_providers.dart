import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_client_progress_repository.dart';
import '../../data/models/models.dart';
import '../../../coach_programs/data/models/program_model.dart';

part 'client_progress_providers.g.dart';

// ══════════════════════════════════════════════════════════
//  1. Client Sessions List
// ══════════════════════════════════════════════════════════

sealed class ClientSessionsState {
  const ClientSessionsState();
}

class ClientSessionsInitial extends ClientSessionsState {
  const ClientSessionsInitial();
}

class ClientSessionsLoading extends ClientSessionsState {
  const ClientSessionsLoading();
}

class ClientSessionsLoaded extends ClientSessionsState {
  const ClientSessionsLoaded({
    required this.sessions,
    required this.pagination,
  });

  final List<ClientSessionSummary> sessions;
  final PaginationMeta pagination;
}

class ClientSessionsError extends ClientSessionsState {
  const ClientSessionsError(this.error);
  final AppError error;
}

/// Manages a paginated list of workout sessions for a specific client.
@riverpod
class ClientSessionsNotifier extends _$ClientSessionsNotifier {
  @override
  ClientSessionsState build() => const ClientSessionsInitial();

  CoachClientProgressRepository get _repo =>
      ref.read(coachClientProgressRepositoryProvider);

  /// Load the first page of sessions.
  Future<void> loadSessions(
    String userId, {
    int limit = 20,
    int offset = 0,
    String status = 'completed',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const ClientSessionsLoading();

    final result = await _repo.getClientSessions(
      userId,
      limit: limit,
      offset: offset,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );

    result.when(
      success: (data) {
        state = ClientSessionsLoaded(
          sessions: data.sessions,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load client sessions',
          tag: 'ClientProgress',
        );
        state = ClientSessionsError(error);
      },
    );
  }

  /// Load more sessions and append to the existing list.
  Future<void> loadMore(
    String userId, {
    String status = 'completed',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final current = state;
    if (current is! ClientSessionsLoaded || !current.pagination.hasMore) {
      return;
    }

    final result = await _repo.getClientSessions(
      userId,
      limit: current.pagination.limit,
      offset: current.pagination.offset + current.pagination.limit,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );

    result.when(
      success: (data) {
        state = ClientSessionsLoaded(
          sessions: [...current.sessions, ...data.sessions],
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error('Failed to load more sessions', tag: 'ClientProgress');
        // Keep the existing data but log the error
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  2. Client Session Detail
// ══════════════════════════════════════════════════════════

sealed class ClientSessionDetailState {
  const ClientSessionDetailState();
}

class ClientSessionDetailInitial extends ClientSessionDetailState {
  const ClientSessionDetailInitial();
}

class ClientSessionDetailLoading extends ClientSessionDetailState {
  const ClientSessionDetailLoading();
}

class ClientSessionDetailLoaded extends ClientSessionDetailState {
  const ClientSessionDetailLoaded(this.session);
  final ClientSessionDetail session;
}

class ClientSessionDetailError extends ClientSessionDetailState {
  const ClientSessionDetailError(this.error);
  final AppError error;
}

/// Manages the full detail view for a single client workout session.
@riverpod
class ClientSessionDetailNotifier extends _$ClientSessionDetailNotifier {
  @override
  ClientSessionDetailState build() => const ClientSessionDetailInitial();

  CoachClientProgressRepository get _repo =>
      ref.read(coachClientProgressRepositoryProvider);

  Future<void> loadSessionDetail(String userId, String sessionId) async {
    state = const ClientSessionDetailLoading();

    final result = await _repo.getClientSessionDetail(userId, sessionId);

    result.when(
      success: (session) {
        state = ClientSessionDetailLoaded(session);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load session detail $sessionId',
          tag: 'ClientProgress',
        );
        state = ClientSessionDetailError(error);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  3. Client Weekly Stats
// ══════════════════════════════════════════════════════════

sealed class ClientWeeklyStatsState {
  const ClientWeeklyStatsState();
}

class ClientWeeklyStatsInitial extends ClientWeeklyStatsState {
  const ClientWeeklyStatsInitial();
}

class ClientWeeklyStatsLoading extends ClientWeeklyStatsState {
  const ClientWeeklyStatsLoading();
}

class ClientWeeklyStatsLoaded extends ClientWeeklyStatsState {
  const ClientWeeklyStatsLoaded(this.stats);
  final ClientWeeklyStats stats;
}

class ClientWeeklyStatsError extends ClientWeeklyStatsState {
  const ClientWeeklyStatsError(this.error);
  final AppError error;
}

/// Manages weekly aggregated stats for a client (with deltas).
@riverpod
class ClientWeeklyStatsNotifier extends _$ClientWeeklyStatsNotifier {
  @override
  ClientWeeklyStatsState build() => const ClientWeeklyStatsInitial();

  CoachClientProgressRepository get _repo =>
      ref.read(coachClientProgressRepositoryProvider);

  Future<void> loadWeeklyStats(String userId, {DateTime? weekOf}) async {
    state = const ClientWeeklyStatsLoading();

    final result = await _repo.getClientWeeklyStats(userId, weekOf: weekOf);

    result.when(
      success: (stats) {
        state = ClientWeeklyStatsLoaded(stats);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load weekly stats for $userId',
          tag: 'ClientProgress',
        );
        state = ClientWeeklyStatsError(error);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  4. Client Exercise History
// ══════════════════════════════════════════════════════════

sealed class ClientExerciseHistoryState {
  const ClientExerciseHistoryState();
}

class ClientExerciseHistoryInitial extends ClientExerciseHistoryState {
  const ClientExerciseHistoryInitial();
}

class ClientExerciseHistoryLoading extends ClientExerciseHistoryState {
  const ClientExerciseHistoryLoading();
}

class ClientExerciseHistoryLoaded extends ClientExerciseHistoryState {
  const ClientExerciseHistoryLoaded(this.response);
  final ClientExerciseHistoryResponse response;
}

class ClientExerciseHistoryError extends ClientExerciseHistoryState {
  const ClientExerciseHistoryError(this.error);
  final AppError error;
}

/// Manages exercise-level progress over time for a client.
@riverpod
class ClientExerciseHistoryNotifier extends _$ClientExerciseHistoryNotifier {
  @override
  ClientExerciseHistoryState build() => const ClientExerciseHistoryInitial();

  CoachClientProgressRepository get _repo =>
      ref.read(coachClientProgressRepositoryProvider);

  Future<void> loadExerciseHistory(
    String userId,
    String exerciseId, {
    int limit = 20,
  }) async {
    state = const ClientExerciseHistoryLoading();

    final result = await _repo.getClientExerciseHistory(
      userId,
      exerciseId,
      limit: limit,
    );

    result.when(
      success: (response) {
        state = ClientExerciseHistoryLoaded(response);
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load exercise history for $exerciseId',
          tag: 'ClientProgress',
        );
        state = ClientExerciseHistoryError(error);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  5. Detailed Performance Report
// ══════════════════════════════════════════════════════════

sealed class DetailedPerformanceState {
  const DetailedPerformanceState();
}

class DetailedPerformanceInitial extends DetailedPerformanceState {
  const DetailedPerformanceInitial();
}

class DetailedPerformanceLoading extends DetailedPerformanceState {
  const DetailedPerformanceLoading();
}

class DetailedPerformanceLoaded extends DetailedPerformanceState {
  const DetailedPerformanceLoaded({
    required this.performance,
    required this.summary,
    required this.pagination,
  });

  final List<ClientPerformanceEntry> performance;
  final PerformanceSummary summary;
  final PaginationMeta pagination;
}

class DetailedPerformanceError extends DetailedPerformanceState {
  const DetailedPerformanceError(this.error);
  final AppError error;
}

/// Manages the enhanced performance report for all of a coach's clients.
@riverpod
class DetailedPerformanceNotifier extends _$DetailedPerformanceNotifier {
  @override
  DetailedPerformanceState build() => const DetailedPerformanceInitial();

  CoachClientProgressRepository get _repo =>
      ref.read(coachClientProgressRepositoryProvider);

  /// Load the first page of the detailed performance report.
  Future<void> loadPerformance({int limit = 50, int offset = 0}) async {
    state = const DetailedPerformanceLoading();

    final result = await _repo.getDetailedPerformance(
      limit: limit,
      offset: offset,
    );

    result.when(
      success: (data) {
        state = DetailedPerformanceLoaded(
          performance: data.performance,
          summary: data.summary,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load detailed performance',
          tag: 'ClientProgress',
        );
        state = DetailedPerformanceError(error);
      },
    );
  }

  /// Load more clients and append to existing list.
  Future<void> loadMore() async {
    final current = state;
    if (current is! DetailedPerformanceLoaded || !current.pagination.hasMore) {
      return;
    }

    final result = await _repo.getDetailedPerformance(
      limit: current.pagination.limit,
      offset: current.pagination.offset + current.pagination.limit,
    );

    result.when(
      success: (data) {
        state = DetailedPerformanceLoaded(
          performance: [...current.performance, ...data.performance],
          summary: data.summary,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load more performance data',
          tag: 'ClientProgress',
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  6. Client Form Results
// ══════════════════════════════════════════════════════════

sealed class ClientFormResultsState {
  const ClientFormResultsState();
}

class ClientFormResultsInitial extends ClientFormResultsState {
  const ClientFormResultsInitial();
}

class ClientFormResultsLoading extends ClientFormResultsState {
  const ClientFormResultsLoading();
}

class ClientFormResultsLoaded extends ClientFormResultsState {
  const ClientFormResultsLoaded({
    required this.results,
    required this.pagination,
  });

  final List<ClientFormResult> results;
  final PaginationMeta pagination;
}

class ClientFormResultsError extends ClientFormResultsState {
  const ClientFormResultsError(this.error);
  final AppError error;
}

/// Manages paginated form comparison results for a client.
@riverpod
class ClientFormResultsNotifier extends _$ClientFormResultsNotifier {
  @override
  ClientFormResultsState build() => const ClientFormResultsInitial();

  CoachClientProgressRepository get _repo =>
      ref.read(coachClientProgressRepositoryProvider);

  /// Load form results for a client, optionally filtered by exercise.
  Future<void> loadFormResults(
    String userId, {
    String? exerciseId,
    int limit = 20,
    int offset = 0,
  }) async {
    state = const ClientFormResultsLoading();

    final result = await _repo.getClientFormResults(
      userId,
      exerciseId: exerciseId,
      limit: limit,
      offset: offset,
    );

    result.when(
      success: (data) {
        state = ClientFormResultsLoaded(
          results: data.results,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load form results for $userId',
          tag: 'ClientProgress',
        );
        state = ClientFormResultsError(error);
      },
    );
  }

  /// Load more form results and append to existing list.
  Future<void> loadMore(String userId, {String? exerciseId}) async {
    final current = state;
    if (current is! ClientFormResultsLoaded || !current.pagination.hasMore) {
      return;
    }

    final result = await _repo.getClientFormResults(
      userId,
      exerciseId: exerciseId,
      limit: current.pagination.limit,
      offset: current.pagination.offset + current.pagination.limit,
    );

    result.when(
      success: (data) {
        state = ClientFormResultsLoaded(
          results: [...current.results, ...data.results],
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Failed to load more form results',
          tag: 'ClientProgress',
        );
      },
    );
  }
}
