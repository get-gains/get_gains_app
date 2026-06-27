import 'dart:async';
import 'dart:convert';

import 'package:cuid2/cuid2.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/app_error.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../api/api_client.dart';
import '../connectivity/connectivity_service.dart';
import '../database/app_database.dart';
import '../storage/secure_storage_service.dart';

part 'outbox_service.g.dart';

/// Generates a collision-resistant unique ID for new outbox entries.
final _cuidGenerator = cuidConfig();

class OutboxService {
  final AppDatabase _db;
  final ApiClient _api;
  final ConnectivityService _connectivity;
  final SecureStorageService _storage;
  bool _isDraining = false;

  OutboxService(
    this._db,
    this._api,
    this._connectivity,
    this._storage,
  );

  String newId() => _cuidGenerator.gen();

  Future<String> enqueue({
    required String entityType,
    required String operation,
    required String payload,
    String? parentOutboxId,
  }) async {
    final id = _cuidGenerator.gen();
    await _db.insertOutboxEntry(
      OutboxEntriesCompanion.insert(
        id: id,
        entityType: entityType,
        operation: operation,
        payload: payload,
        parentOutboxId: Value(parentOutboxId),
        createdAt: DateTime.now(),
      ),
    );
    AppLogger.debug('Enqueued outbox entry id=$id entityType=$entityType operation=$operation', tag: 'Outbox');

    if (await _connectivity.isConnected() && await _storage.isAuthenticated()) {
      unawaited(drain());
    }

    return id;
  }

  Future<void> drain() async {
    if (_isDraining) return;
    if (!await _connectivity.isConnected()) return;
    if (!await _storage.isAuthenticated()) return;

    _isDraining = true;
    AppLogger.debug('Starting outbox drain', tag: 'Outbox');

    try {
      while (true) {
        final entries = await _db.getPendingOutboxEntries(limit: 50);
        if (entries.isEmpty) break;

        OutboxEntry? next;
        for (final entry in entries) {
          if (entry.parentOutboxId != null) {
            final parent =
                await _db.getOutboxEntryById(entry.parentOutboxId!);
            if (parent == null || parent.status != 'synced') {
              continue;
            }
          }
          next = entry;
          break;
        }

        if (next == null) break;

        await _processRow(next);

        if (!await _connectivity.isConnected()) break;
        if (!await _storage.isAuthenticated()) break;
      }
    } finally {
      _isDraining = false;
    }

    AppLogger.debug('Outbox drain finished', tag: 'Outbox');
  }

  Future<void> _processRow(OutboxEntry entry) async {
    AppLogger.debug('Processing outbox row id=${entry.id} entityType=${entry.entityType} operation=${entry.operation}', tag: 'Outbox');

    final body = jsonDecode(entry.payload) as Map<String, dynamic>;

    String path = _resolvePath(entry.entityType, entry.operation, body);
    String method = _resolveMethod(entry.operation);

    final result = await _sendRequest(method, path, body);

    result.when(
      success: (_) async {
        await _db.updateOutboxStatus(
          entry.id,
          status: 'synced',
          syncedAt: DateTime.now(),
        );
        AppLogger.debug('Outbox row synced id=${entry.id}', tag: 'Outbox');
      },
      failure: (error) async {
        await _db.incrementRetryCount(entry.id);
        await _db.updateOutboxStatus(
          entry.id,
          status: 'failed',
          lastError: error.message,
        );
        AppLogger.warning('Outbox row failed id=${entry.id} error=${error.message}', tag: 'Outbox');
      },
    );
  }

  Future<Result<dynamic, AppError>> _sendRequest(
    String method,
    String path,
    Map<String, dynamic> data,
  ) {
    switch (method) {
      case 'POST':
        return _api.post(path, data: data);
      case 'PUT':
        return _api.put(path, data: data);
      case 'PATCH':
        return _api.patch(path, data: data);
      case 'DELETE':
        return _api.delete(path);
      default:
        return _api.post(path, data: data);
    }
  }

  String _resolvePath(
    String entityType,
    String operation,
    Map<String, dynamic> payload,
  ) {
    const base = '';

    switch (entityType) {
      case 'workout_session':
        if (operation == 'complete') {
          return '$base/workout/sessions/${payload['sessionId'] ?? payload['id']}/complete';
        }
        return '$base/workout/sessions';

      case 'standalone_session':
        if (operation == 'complete') {
          return '$base/standalone/sessions/${payload['sessionId'] ?? payload['id']}/complete';
        }
        return '$base/standalone/sessions';

      case 'set_log':
        if (operation == 'create') {
          return '$base/workout/sets';
        }
        if (operation == 'update') {
          return '$base/workout/sets/${payload['id']}';
        }
        return '$base/workout/sets';

      case 'standalone_set_log':
        if (operation == 'create') {
          return '$base/standalone/sessions/${payload['session_id'] ?? payload['sessionId']}/sets';
        }
        if (operation == 'update' || operation == 'delete') {
          return '$base/standalone/sessions/${payload['session_id'] ?? payload['sessionId']}/sets/${payload['id']}';
        }
        return '$base/standalone/sessions/${payload['session_id'] ?? payload['sessionId']}/sets';

      case 'standalone_exercise':
        if (operation == 'update') {
          return '$base/standalone/exercises/${payload['id']}';
        }
        return '$base/standalone/exercises';

      case 'standalone_routine':
        if (operation == 'update') {
          return '$base/standalone/routines/${payload['id']}';
        }
        return '$base/standalone/routines';

      case 'standalone_program':
        if (operation == 'update' || operation == 'delete') {
          return '$base/standalone/programs/${payload['id']}';
        }
        if (operation == 'activate') {
          return '$base/standalone/programs/${payload['id']}/activate';
        }
        if (operation == 'deactivate') {
          return '$base/standalone/programs/${payload['id']}/deactivate';
        }
        return '$base/standalone/programs';

      case 'standalone_program_routine':
        if (operation == 'update' || operation == 'delete') {
          return '$base/standalone/programs/${payload['program_id'] ?? payload['programId']}/routines/${payload['id']}';
        }
        return '$base/standalone/programs/${payload['program_id'] ?? payload['programId']}/routines';

      case 'standalone_routine_exercise':
        if (operation == 'update' || operation == 'delete') {
          return '$base/standalone/routines/${payload['routine_id'] ?? payload['routineId']}/exercises/${payload['id']}';
        }
        return '$base/standalone/routines/${payload['routine_id'] ?? payload['routineId']}/exercises';

      default:
        AppLogger.warning('Unknown entity type in outbox: $entityType', tag: 'Outbox');
        return '$base/$entityType';
    }
  }

  String _resolveMethod(String operation) {
    switch (operation) {
      case 'create':
        return 'POST';
      case 'update':
        return 'PATCH';
      case 'delete':
        return 'DELETE';
      case 'complete':
        return 'POST';
      case 'activate':
      case 'deactivate':
        return 'POST';
      default:
        return 'POST';
    }
  }
}

@Riverpod(keepAlive: true)
OutboxService outboxService(Ref ref) {
  return OutboxService(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
}
