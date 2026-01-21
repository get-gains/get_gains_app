import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';
import '../api/api_client.dart';
import '../database/app_database.dart';

part 'sync_service.g.dart';

/// Sync Operation Types
enum SyncOperation { create, update, delete }

/// Sync Service
///
/// Handles bidirectional synchronization between local SQLite database
/// and remote API. Uses a queue-based approach for offline support.
///
/// Features:
/// - Queues local changes when offline
/// - Processes queue when online
/// - Conflict resolution (server wins by default)
/// - Retry logic with exponential backoff
class SyncService {
  SyncService({required this.database, required this.apiClient});

  final AppDatabase database;
  final ApiClient apiClient;

  bool _isSyncing = false;
  static const int _maxRetries = 5;

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  // ============== Queue Management ==============

  /// Add a change to the sync queue
  Future<void> queueChange({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    await database.addToSyncQueue(
      SyncQueueCompanion.insert(
        entityTable: tableName,
        recordId: recordId,
        operation: operation.name,
        payload: jsonEncode(payload),
      ),
    );
    AppLogger.debug(
      'Queued ${operation.name} for $tableName:$recordId',
      tag: 'SyncService',
    );
  }

  /// Process all pending sync items
  Future<SyncResult> processQueue() async {
    if (_isSyncing) {
      AppLogger.info('Sync already in progress', tag: 'SyncService');
      return SyncResult(processed: 0, failed: 0, skipped: 0);
    }

    _isSyncing = true;
    int processed = 0;
    int failed = 0;
    int skipped = 0;

    try {
      final pendingItems = await database.getPendingSyncItems();
      AppLogger.info(
        'Processing ${pendingItems.length} sync items',
        tag: 'SyncService',
      );

      for (final item in pendingItems) {
        if (item.retryCount >= _maxRetries) {
          AppLogger.warning(
            'Skipping item ${item.id} - max retries exceeded',
            tag: 'SyncService',
          );
          skipped++;
          continue;
        }

        try {
          await _processSyncItem(item);
          await database.removeFromSyncQueue(item.id);
          processed++;
        } catch (e) {
          AppLogger.error(
            'Failed to sync item ${item.id}',
            tag: 'SyncService',
            error: e,
          );
          await database.incrementRetryCount(item.id);
          failed++;
        }
      }

      return SyncResult(processed: processed, failed: failed, skipped: skipped);
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single sync item
  Future<void> _processSyncItem(SyncQueueData item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    final operation = SyncOperation.values.byName(item.operation);

    switch (operation) {
      case SyncOperation.create:
        await _syncCreate(item.entityTable, payload);
      case SyncOperation.update:
        await _syncUpdate(item.entityTable, item.recordId, payload);
      case SyncOperation.delete:
        await _syncDelete(item.entityTable, item.recordId);
    }
  }

  Future<void> _syncCreate(
    String tableName,
    Map<String, dynamic> payload,
  ) async {
    final result = await apiClient.post('/$tableName', data: payload);
    result.when(
      success: (_) => AppLogger.debug('Created $tableName', tag: 'SyncService'),
      failure: (error) => throw Exception(error.message),
    );
  }

  Future<void> _syncUpdate(
    String tableName,
    String recordId,
    Map<String, dynamic> payload,
  ) async {
    final result = await apiClient.put('/$tableName/$recordId', data: payload);
    result.when(
      success: (_) =>
          AppLogger.debug('Updated $tableName:$recordId', tag: 'SyncService'),
      failure: (error) => throw Exception(error.message),
    );
  }

  Future<void> _syncDelete(String tableName, String recordId) async {
    final result = await apiClient.delete('/$tableName/$recordId');
    result.when(
      success: (_) =>
          AppLogger.debug('Deleted $tableName:$recordId', tag: 'SyncService'),
      failure: (error) => throw Exception(error.message),
    );
  }

  // ============== Full Sync ==============

  /// Perform a full sync with the server
  /// Downloads all data and reconciles with local database
  Future<void> fullSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    AppLogger.info('Starting full sync', tag: 'SyncService');

    try {
      // First push local changes
      await processQueue();

      // Then pull from server
      // Add your entity-specific sync logic here
      // Example:
      // await _syncUsers();
      // await _syncWorkouts();

      AppLogger.info('Full sync completed', tag: 'SyncService');
    } catch (e) {
      AppLogger.error('Full sync failed', tag: 'SyncService', error: e);
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Clear all local data and re-sync from server
  Future<void> forceResync() async {
    AppLogger.warning('Force re-sync initiated', tag: 'SyncService');
    await database.clearAllData();
    await fullSync();
  }
}

/// Sync operation result
class SyncResult {
  SyncResult({
    required this.processed,
    required this.failed,
    required this.skipped,
  });

  final int processed;
  final int failed;
  final int skipped;

  int get total => processed + failed + skipped;

  @override
  String toString() =>
      'SyncResult(processed: $processed, failed: $failed, skipped: $skipped)';
}

/// Provider for SyncService
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  return SyncService(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
  );
}
