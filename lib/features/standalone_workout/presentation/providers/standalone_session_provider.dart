import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../workout/data/models/workout_session_model.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';

part 'standalone_session_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes — Session Lifecycle
// ──────────────────────────────────────────────────────────

sealed class StandaloneSessionState {
  const StandaloneSessionState();
}

class StandaloneSessionInitial extends StandaloneSessionState {
  const StandaloneSessionInitial();
}

class StandaloneSessionLoading extends StandaloneSessionState {
  const StandaloneSessionLoading();
}

class StandaloneSessionActive extends StandaloneSessionState {
  const StandaloneSessionActive({required this.session});
  final WorkoutSessionModel session;
}

class StandaloneSessionCompleted extends StandaloneSessionState {
  const StandaloneSessionCompleted({required this.session});
  final WorkoutSessionModel session;
}

class StandaloneSessionError extends StandaloneSessionState {
  const StandaloneSessionError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Session Lifecycle Notifier (Server-Only)
// ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class StandaloneSessionNotifier extends _$StandaloneSessionNotifier {
  static const _tag = 'StandaloneSessionNotifier';

  @override
  StandaloneSessionState build() {
    // Check for an active session on initialization
    _checkActiveSession();
    return const StandaloneSessionInitial();
  }

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  /// Check if there's an active session and restore it.
  Future<void> _checkActiveSession() async {
    final result = await _repo.getActiveSession();
    result.when(
      success: (session) {
        if (session != null) {
          state = StandaloneSessionActive(session: session);
          AppLogger.info('Restored active session: ${session.id}', tag: _tag);
        }
      },
      failure: (error) {
        AppLogger.warning(
          'Failed to check active session',
          tag: _tag,
          error: error,
        );
      },
    );
  }

  /// Start a new workout session.
  Future<bool> startSession({String? assignedProgramId}) async {
    state = const StandaloneSessionLoading();
    final result = await _repo.startSession(
      assignedProgramId: assignedProgramId,
    );
    return result.when(
      success: (session) {
        state = StandaloneSessionActive(session: session);
        AppLogger.info('Session started: ${session.id}', tag: _tag);
        return true;
      },
      failure: (error) {
        state = StandaloneSessionError(error);
        AppLogger.error('Start session failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Complete the current active session.
  Future<bool> completeSession({String? notes}) async {
    final current = state;
    if (current is! StandaloneSessionActive) return false;

    state = const StandaloneSessionLoading();
    final result = await _repo.completeSession(
      sessionId: current.session.id,
      notes: notes,
    );
    return result.when(
      success: (session) {
        state = StandaloneSessionCompleted(session: session);
        AppLogger.info('Session completed: ${session.id}', tag: _tag);
        return true;
      },
      failure: (error) {
        // Restore the active state on failure
        state = StandaloneSessionActive(session: current.session);
        AppLogger.error('Complete session failed', tag: _tag, error: error);
        return false;
      },
    );
  }

  /// Reset session state (e.g., after navigating away from completion).
  void reset() {
    state = const StandaloneSessionInitial();
  }
}

// ──────────────────────────────────────────────────────────
// Session History Provider (Server-Only, Paginated)
// ──────────────────────────────────────────────────────────

sealed class StandaloneSessionHistoryState {
  const StandaloneSessionHistoryState();
}

class StandaloneSessionHistoryInitial extends StandaloneSessionHistoryState {
  const StandaloneSessionHistoryInitial();
}

class StandaloneSessionHistoryLoading extends StandaloneSessionHistoryState {
  const StandaloneSessionHistoryLoading();
}

class StandaloneSessionHistoryLoaded extends StandaloneSessionHistoryState {
  const StandaloneSessionHistoryLoaded({
    required this.sessions,
    this.total = 0,
    this.hasMore = false,
    this.offset = 0,
    this.limit = 20,
  });

  final List<StandaloneSessionSummary> sessions;
  final int total;
  final bool hasMore;
  final int offset;
  final int limit;
}

class StandaloneSessionHistoryError extends StandaloneSessionHistoryState {
  const StandaloneSessionHistoryError(this.error);
  final AppError error;
}

@riverpod
class StandaloneSessionHistoryNotifier
    extends _$StandaloneSessionHistoryNotifier {
  static const _tag = 'StandaloneSessionHistoryNotifier';

  @override
  StandaloneSessionHistoryState build() =>
      const StandaloneSessionHistoryInitial();

  StandaloneWorkoutRepository get _repo =>
      ref.read(standaloneWorkoutRepositoryProvider);

  /// Load session history.
  Future<void> loadHistory({int limit = 20, int offset = 0}) async {
    state = const StandaloneSessionHistoryLoading();
    final result = await _repo.getSessionHistory(limit: limit, offset: offset);
    result.when(
      success: (response) {
        state = StandaloneSessionHistoryLoaded(
          sessions: response.sessions,
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        state = StandaloneSessionHistoryError(error);
        AppLogger.error('Load session history failed', tag: _tag, error: error);
      },
    );
  }

  /// Load more sessions (pagination).
  Future<void> loadMore() async {
    final current = state;
    if (current is! StandaloneSessionHistoryLoaded || !current.hasMore) return;

    final nextOffset = current.offset + current.limit;
    final result = await _repo.getSessionHistory(
      limit: current.limit,
      offset: nextOffset,
    );

    result.when(
      success: (response) {
        state = StandaloneSessionHistoryLoaded(
          sessions: [...current.sessions, ...response.sessions],
          total: response.total,
          hasMore: response.hasMore,
          offset: response.offset,
          limit: response.limit,
        );
      },
      failure: (error) {
        AppLogger.warning('Load more history failed', tag: _tag, error: error);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Session Detail Provider (Server-Only)
// ──────────────────────────────────────────────────────────

@riverpod
Future<WorkoutSessionModel> standaloneSessionDetail(
  Ref ref,
  String sessionId,
) async {
  final repo = ref.watch(standaloneWorkoutRepositoryProvider);
  final result = await repo.getSessionDetail(sessionId);
  return result.when(
    success: (session) => session,
    failure: (error) => throw error,
  );
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

@riverpod
bool standaloneSessionIsActive(Ref ref) {
  final state = ref.watch(standaloneSessionProvider);
  return state is StandaloneSessionActive;
}

@riverpod
WorkoutSessionModel? standaloneActiveSession(Ref ref) {
  final state = ref.watch(standaloneSessionProvider);
  if (state is StandaloneSessionActive) return state.session;
  return null;
}
