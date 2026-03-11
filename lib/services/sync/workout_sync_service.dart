import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
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
      final poseResultsResult = await _syncPendingPoseResults();

      final result = WorkoutSyncResult(
        sessionsSynced: sessionsResult,
        setsSynced: setsResult,
        completionsSynced: completionsResult,
        poseResultsSynced: poseResultsResult,
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
  // Session Sync
  // ──────────────────────────────────────────────────────────

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
            if (payload['assignedProgramId'] != null)
              'assignedProgramId': payload['assignedProgramId'],
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
          failure: (error) {
            AppLogger.error(
              'Failed to sync session ${item.recordId}: ${error.message}',
              tag: _tag,
            );
            _db.incrementRetryCount(item.id);
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
        }

        // Resolve local routine exercise ID to remote ID
        final localReId = payload['routineExerciseId'] as int?;
        String? remoteReId;
        if (localReId != null) {
          final re = await _db.getRoutineExerciseById(localReId);
          remoteReId = re?.remoteId;
        }

        // Skip if we can't resolve IDs
        if (remoteSessionId == null || remoteReId == null) {
          AppLogger.warning(
            'Skipping set ${item.recordId} — unresolved IDs '
            '(session: $remoteSessionId, re: $remoteReId)',
            tag: _tag,
          );
          continue;
        }

        setsPayload.add({
          'localId': item.recordId,
          'workoutSessionId': remoteSessionId,
          'routineExerciseId': remoteReId,
          'setNumber': payload['setNumber'],
          'repsCompleted': payload['repsCompleted'],
          if (payload['weightKg'] != null) 'weightKg': payload['weightKg'],
          if (payload['rpe'] != null) 'rpe': payload['rpe'],
          if (payload['notes'] != null) 'notes': payload['notes'],
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

  // ──────────────────────────────────────────────────────────
  // Pose Result Sync
  // ──────────────────────────────────────────────────────────

  /// Sync locally-queued pose comparison results to the server.
  Future<int> _syncPendingPoseResults() async {
    final pendingItems = await _db.getPendingSyncItems();

    final poseItems = pendingItems
        .where(
          (item) =>
              item.entityTable == 'pose_results' && item.operation == 'create',
        )
        .toList();

    if (poseItems.isEmpty) return 0;

    int synced = 0;
    for (final item in poseItems) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        final result = await _apiClient.post<Map<String, dynamic>>(
          ApiConstants.poseResults,
          data: payload,
        );

        result.when(
          success: (_) {
            _db.removeFromSyncQueue(item.id);
            synced++;
            AppLogger.debug('Synced pose result: ${item.recordId}', tag: _tag);
          },
          failure: (error) {
            AppLogger.error(
              'Failed to sync pose result ${item.recordId}: ${error.message}',
              tag: _tag,
            );
            _db.incrementRetryCount(item.id);
          },
        );
      } catch (e) {
        AppLogger.error(
          'Error syncing pose result ${item.recordId}',
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
    required this.poseResultsSynced,
  });

  factory WorkoutSyncResult.empty() => WorkoutSyncResult(
    sessionsSynced: 0,
    setsSynced: 0,
    completionsSynced: 0,
    poseResultsSynced: 0,
  );

  final int sessionsSynced;
  final int setsSynced;
  final int completionsSynced;
  final int poseResultsSynced;

  int get total =>
      sessionsSynced + setsSynced + completionsSynced + poseResultsSynced;

  @override
  String toString() =>
      'WorkoutSyncResult(sessions: $sessionsSynced, '
      'sets: $setsSynced, completions: $completionsSynced, '
      'poseResults: $poseResultsSynced)';
}
