import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_error_codes.dart';
import '../../core/utils/logger.dart';
import '../../features/workout/data/workout_repository.dart';
import '../api/api_client.dart';
import '../database/app_database.dart';
import '../connectivity/connectivity_service.dart';

part 'workout_sync_service.g.dart';

/// Workout Sync Service
///
/// Handles bidirectional synchronization of workout data between the
/// local Drift database and the remote server. Replaces the generic
/// [SyncService] URL-mapping approach with correct per-entity routing:
///
/// - **Sessions**: `POST /api/workout/sessions` (create),
///   `POST /api/workout/sessions/:id/complete` (complete)
/// - **Sets**: `POST /api/workout/sets/sync` (batch upsert)
///
/// ## Sync Triggers
/// - On connectivity restoration (automatic via [startListening])
/// - On demand via [syncAll]
///
/// ## Flow
/// 1. Read unsynced local sessions (no `remoteId`)
/// 2. POST each to server → store returned `remoteId` locally
/// 3. Read unsynced local sets → batch-POST via `/sets/sync`
/// 4. Read completed-but-not-synced sessions → POST complete
class WorkoutSyncService {
  WorkoutSyncService({
    required AppDatabase database,
    required ApiClient apiClient,
    required ConnectivityService connectivityService,
    required WorkoutRepository workoutRepository,
  }) : _db = database,
       _apiClient = apiClient,
       _connectivity = connectivityService,
       _workoutRepo = workoutRepository;

  final AppDatabase _db;
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;
  final WorkoutRepository _workoutRepo;

  static const _tag = 'WorkoutSyncService';

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySub;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Start listening for connectivity changes and auto-sync when online.
  void startListening() {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) {
      if (online) {
        AppLogger.info('Online — triggering workout sync', tag: _tag);
        syncAll();
      }
    });
    AppLogger.debug('Workout sync listener started', tag: _tag);
  }

  /// Stop listening for connectivity changes.
  void stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    AppLogger.debug('Workout sync listener stopped', tag: _tag);
  }

  /// Run a full sync cycle: sessions → sets → completions.
  ///
  /// Returns a [WorkoutSyncResult] summarising what was processed.
  Future<WorkoutSyncResult> syncAll() async {
    if (_isSyncing) {
      AppLogger.info('Workout sync already in progress', tag: _tag);
      return WorkoutSyncResult.empty();
    }

    final isOnline = await _connectivity.isConnected();
    if (!isOnline) {
      AppLogger.info('Offline — skipping workout sync', tag: _tag);
      return WorkoutSyncResult.empty();
    }

    _isSyncing = true;
    AppLogger.info('Starting workout sync', tag: _tag);

    try {
      final sessionsResult = await _syncPendingSessions();
      final setsResult = await _syncPendingSets();
      final completionsResult = await _syncPendingCompletions();

      final result = WorkoutSyncResult(
        sessionsSynced: sessionsResult,
        setsSynced: setsResult,
        completionsSynced: completionsResult,
      );

      AppLogger.info('Workout sync complete: $result', tag: _tag);
      return result;
    } catch (e) {
      AppLogger.error('Workout sync failed', tag: _tag, error: e);
      return WorkoutSyncResult.empty();
    } finally {
      _isSyncing = false;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────

  /// Auto-create a session on the server and store the returned remoteId.
  ///
  /// Used as a fallback when sets/completions reference a session that
  /// was never synced (e.g. the create queue entry was lost or missing).
  ///
  /// If the server responds with 409 (active session already exists), it
  /// auto-completes the stale session and retries the create so the local
  /// session always receives a unique remote ID — never a duplicate.
  Future<String?> _autoCreateSession(WorkoutSession session) async {
    try {
      if (session.assignedProgramRoutineId == null) return null;

      // First attempt
      final first = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.workoutSessions,
        data: {'assignedProgramRoutineId': session.assignedProgramRoutineId},
      );

      String? remoteId;

      await first.when(
        success: (data) async {
          remoteId =
              (data['session'] as Map<String, dynamic>)['id'] as String;
        },
        failure: (error) async {
          if (error.code == ApiErrorCode.workoutSessionAlreadyActive) {
            remoteId = await _handle409AndRetry(session);
          } else {
            AppLogger.warning(
              'Could not auto-create session ${session.id}: ${error.message}',
              tag: _tag,
            );
          }
        },
      );

      final resolvedId = remoteId;
      if (resolvedId != null) {
        await _db.updateWorkoutSessionRemoteId(session.id, resolvedId);
        AppLogger.info(
          'Auto-created session ${session.id} → $resolvedId',
          tag: _tag,
        );
      }
      return remoteId;
    } catch (e) {
      AppLogger.error(
        'Error auto-creating session ${session.id}',
        tag: _tag,
        error: e,
      );
      return null;
    }
  }

  /// Handle 409: complete the old active session then retry the create.
  Future<String?> _handle409AndRetry(WorkoutSession session) async {
    final activeResult = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.workoutSessions}/active',
    );
    final activeData = activeResult.valueOrNull;
    final activeSession =
        activeData?['session'] as Map<String, dynamic>?;
    if (activeSession == null) return null;

    final oldRemoteId = activeSession['id'] as String;
    AppLogger.info(
      'Auto-completing stale server session $oldRemoteId before retry',
      tag: _tag,
    );

    try {
      await _apiClient.post(
        '${ApiConstants.workoutSessions}/$oldRemoteId/complete',
      );
    } catch (_) {
      // Best-effort
    }

    final retry = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.workoutSessions,
      data: {
        if (session.assignedProgramRoutineId != null)
          'assignedProgramRoutineId': session.assignedProgramRoutineId,
      },
    );

    return retry.when(
      success: (data) async =>
          (data['session'] as Map<String, dynamic>)['id'] as String,
      failure: (error) {
        AppLogger.warning(
          'Retry after 409 also failed: ${error.message}',
          tag: _tag,
        );
        return null;
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // Session Sync
  // ──────────────────────────────────────────────────────────

  /// Handle 409 for a sync-queue session create:
  /// completes the stale server session, retries the create,
  /// and stores the new remote ID on the local session.
  Future<String?> _handle409AndRetryForQueue(SyncQueueData item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    final aprId = payload['assignedProgramRoutineId'] as String?;
    if (aprId == null) return null;

    final activeResult = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.workoutSessions}/active',
    );
    final activeData = activeResult.valueOrNull;
    final activeSession =
        activeData?['session'] as Map<String, dynamic>?;
    if (activeSession == null) return null;

    final oldRemoteId = activeSession['id'] as String;
    AppLogger.info(
      'Auto-completing stale server session $oldRemoteId before retry (queue item ${item.id})',
      tag: _tag,
    );

    try {
      await _apiClient.post(
        '${ApiConstants.workoutSessions}/$oldRemoteId/complete',
      );
    } catch (_) {
      // Best-effort
    }

    final retry = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.workoutSessions,
      data: {'assignedProgramRoutineId': aprId},
    );

    return retry.when(
      success: (data) async {
        final remoteId =
            (data['session'] as Map<String, dynamic>)['id'] as String;
        final localId = int.tryParse(item.recordId);
        if (localId != null) {
          await _db.updateWorkoutSessionRemoteId(localId, remoteId);
        }
        AppLogger.debug(
          'Resolved 409 for session ${item.recordId} → $remoteId',
          tag: _tag,
        );
        return remoteId;
      },
      failure: (error) {
        AppLogger.warning(
          '409 retry for session ${item.recordId} also failed: ${error.message}',
          tag: _tag,
        );
        return null;
      },
    );
  }

  /// Sync locally-created sessions that have no `remoteId`.
  Future<int> _syncPendingSessions() async {
    final pendingItems = await _db.getPendingSyncItems();

    // Filter for session create operations
    final sessionCreates = pendingItems.where(
      (item) =>
          item.entityTable == 'workout_sessions' && item.operation == 'create',
    );

    int synced = 0;
    for (final item in sessionCreates) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        final result = await _apiClient.post<Map<String, dynamic>>(
          ApiConstants.workoutSessions,
          data: {
            if (payload['assignedProgramRoutineId'] != null)
              'assignedProgramRoutineId': payload['assignedProgramRoutineId'],
          },
        );

        result.when(
          success: (data) async {
            final sessionJson = data['session'] as Map<String, dynamic>;
            final remoteId = sessionJson['id'] as String;

            // Update local session with remote ID
            final localId = int.tryParse(item.recordId);
            if (localId != null) {
              await _db.updateWorkoutSessionRemoteId(localId, remoteId);
            }

            await _db.removeFromSyncQueue(item.id);
            synced++;
            AppLogger.debug(
              'Synced session ${item.recordId} → $remoteId',
              tag: _tag,
            );
          },
          failure: (error) async {
            if (error.code == ApiErrorCode.workoutSessionAlreadyActive) {
              // 409 — stale session on server. Complete it and retry.
              final resolved = await _handle409AndRetryForQueue(item);
              if (resolved != null) {
                await _db.removeFromSyncQueue(item.id);
                synced++;
              } else {
                await _db.incrementRetryCount(item.id);
              }
            } else {
              AppLogger.error(
                'Failed to sync session ${item.recordId}: ${error.message}',
                tag: _tag,
              );
              await _db.incrementRetryCount(item.id);
            }
          },
        );
      } catch (e) {
        AppLogger.error(
          'Error syncing session ${item.recordId}',
          tag: _tag,
          error: e,
        );
        await _db.incrementRetryCount(item.id);
      }
    }

    return synced;
  }

  // ──────────────────────────────────────────────────────────
  // Set Sync (Batch)
  // ──────────────────────────────────────────────────────────

  /// Batch-sync locally-recorded sets to the server.
  Future<int> _syncPendingSets() async {
    final pendingItems = await _db.getPendingSyncItems();

    // Filter for set create/update operations
    final setItems = pendingItems
        .where(
          (item) =>
              item.entityTable == 'performed_sets' &&
              (item.operation == 'create' || item.operation == 'update'),
        )
        .toList();

    if (setItems.isEmpty) return 0;

    // Build the batch payload
    final setsPayload = <Map<String, dynamic>>[];
    for (final item in setItems) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        // Resolve local session ID to remote ID
        final localSessionId = payload['workoutSessionId'] as int?;
        String? remoteSessionId;
        if (localSessionId != null) {
          final session = await _db.getWorkoutSessionById(localSessionId);
          remoteSessionId = session?.remoteId;

          // Auto-create session on server if no remoteId yet
          if (remoteSessionId == null && session != null) {
            remoteSessionId = await _autoCreateSession(session);
          }
        }

        // Read the APRE CUID directly from the payload.
        // v9 migration resolved all legacy int FKs; only APRE CUIDs remain.
        final apreId = payload['assignedProgramRoutineExerciseId'] as String?;
        if (apreId == null || apreId.isEmpty) {
          AppLogger.warning(
            'Skipping set ${item.recordId} — payload has no APRE CUID. Will retry.',
            tag: _tag,
          );
          await _db.incrementRetryCount(item.id);
          continue;
        }

        // Skip if we can't resolve session ID; bump retry for observability
        if (remoteSessionId == null) {
          AppLogger.warning(
            'Skipping set ${item.recordId} — unresolved session ID. Will retry.',
            tag: _tag,
          );
          await _db.incrementRetryCount(item.id);
          continue;
        }

        setsPayload.add({
          'localId': item.recordId,
          'workoutSessionId': remoteSessionId,
          'assignedProgramRoutineExerciseId': apreId,
          'set_number': payload['setNumber'],
          'reps': payload['repsCompleted'],
          'weight': (payload['weightKg'] as num?)?.toDouble() ?? 0,
          'overallScore': payload['overallScore'] != null
              ? ((payload['overallScore'] as num).toDouble() * 100).round()
              : 0,
          'completedAt': (payload['completedAt'] as String?) ??
              DateTime.now().toUtc().toIso8601String(),
          if (payload['recordedFramesKey'] != null)
            'recordedFramesKey': payload['recordedFramesKey'],
        });
      } catch (e) {
        AppLogger.error(
          'Error building set payload for ${item.recordId}',
          tag: _tag,
          error: e,
        );
      }
    }

    if (setsPayload.isEmpty) return 0;

    final syncResult = await _workoutRepo.batchSyncSets(sets: setsPayload);

    int synced = 0;
    syncResult.when(
      success: (batch) {
        // Remove successfully synced items from the queue
        for (final setResult in batch.results) {
          if (setResult.success && setResult.localId != null) {
            final matchingItem = setItems.where(
              (item) => item.recordId == setResult.localId,
            );
            for (final item in matchingItem) {
              _db.removeFromSyncQueue(item.id);
            }

            // Store remote ID on local set
            final localSetId = int.tryParse(setResult.localId!);
            if (localSetId != null && setResult.serverId != null) {
              _db.updatePerformedSetRemoteId(localSetId, setResult.serverId!);
            }

            synced++;
          }
        }
      },
      failure: (error) {
        AppLogger.error('Batch set sync failed: ${error.message}', tag: _tag);
        for (final item in setItems) {
          _db.incrementRetryCount(item.id);
        }
      },
    );

    return synced;
  }

  // ──────────────────────────────────────────────────────────
  // Session Completion Sync
  // ──────────────────────────────────────────────────────────

  /// Sync locally-completed sessions to the server.
  Future<int> _syncPendingCompletions() async {
    final pendingItems = await _db.getPendingSyncItems();

    // Filter for session complete operations
    final completions = pendingItems.where(
      (item) =>
          item.entityTable == 'workout_sessions' &&
          item.operation == 'complete',
    );

    int synced = 0;
    for (final item in completions) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        // Resolve local session ID to remote ID
        final localId = payload['sessionId'] as int?;
        String? remoteId;
        if (localId != null) {
          final session = await _db.getWorkoutSessionById(localId);
          remoteId = session?.remoteId;

          // Auto-create session on server if no remoteId yet
          if (remoteId == null && session != null) {
            remoteId = await _autoCreateSession(session);
          }
        }

        if (remoteId == null) {
          AppLogger.warning(
            'Skipping completion for session ${item.recordId} — no remote ID',
            tag: _tag,
          );
          continue;
        }

        final result = await _apiClient.post<Map<String, dynamic>>(
          '${ApiConstants.workoutSessions}/$remoteId/complete',
          data: {if (payload['notes'] != null) 'notes': payload['notes']},
        );

        result.when(
          success: (_) {
            _db.removeFromSyncQueue(item.id);
            synced++;
            AppLogger.debug('Synced session completion: $remoteId', tag: _tag);
          },
          failure: (error) {
            AppLogger.error(
              'Failed to sync completion for $remoteId: ${error.message}',
              tag: _tag,
            );
            _db.incrementRetryCount(item.id);
          },
        );
      } catch (e) {
        AppLogger.error(
          'Error syncing completion for ${item.recordId}',
          tag: _tag,
          error: e,
        );
        await _db.incrementRetryCount(item.id);
      }
    }

    return synced;
  }
}

/// Provider for [WorkoutSyncService].
@Riverpod(keepAlive: true)
WorkoutSyncService workoutSyncService(Ref ref) {
  final service = WorkoutSyncService(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    workoutRepository: ref.watch(workoutRepositoryProvider),
  );
  // Auto-start listening for connectivity changes
  service.startListening();
  ref.onDispose(() => service.stopListening());
  return service;
}

/// Summary of a workout sync cycle.
class WorkoutSyncResult {
  WorkoutSyncResult({
    required this.sessionsSynced,
    required this.setsSynced,
    required this.completionsSynced,
  });

  factory WorkoutSyncResult.empty() =>
      WorkoutSyncResult(sessionsSynced: 0, setsSynced: 0, completionsSynced: 0);

  final int sessionsSynced;
  final int setsSynced;
  final int completionsSynced;

  int get total => sessionsSynced + setsSynced + completionsSynced;

  @override
  String toString() =>
      'WorkoutSyncResult(sessions: $sessionsSynced, '
      'sets: $setsSynced, completions: $completionsSynced)';
}
