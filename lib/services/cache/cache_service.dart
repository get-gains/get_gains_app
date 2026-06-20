import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';
import '../api/api_client.dart';
import '../database/app_database.dart';

part 'cache_service.g.dart';

class CacheService {
  final AppDatabase _db;
  final ApiClient _api;

  CacheService(this._db, this._api);

  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final row = await _db.getCachedAsset(key);
    if (row == null) return null;

    try {
      final json = jsonDecode(row.content) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      AppLogger.warning('Failed to decode cached asset', tag: 'Cache',
          data: {'key': key, 'error': e.toString()});
      return null;
    }
  }

  Future<String?> getRaw(String key) async {
    final row = await _db.getCachedAsset(key);
    return row?.content;
  }

  Future<void> put(String key, String content, {required String version}) async {
    await _db.putCachedAsset(
      key: key,
      version: version,
      content: content,
    );
    AppLogger.debug('Cached asset stored', tag: 'Cache', data: {'key': key});
  }

  Future<void> putJson(
    String key,
    Map<String, dynamic> json, {
    required String version,
  }) async {
    await put(key, jsonEncode(json), version: version);
  }

  Future<bool> isFresh(String key, String serverVersion) async {
    final row = await _db.getCachedAsset(key);
    if (row == null) return false;
    return row.version == serverVersion;
  }

  Future<void> remove(String key) async {
    await _db.deleteCachedAsset(key);
  }
}

@Riverpod(keepAlive: true)
CacheService cacheService(Ref ref) {
  return CacheService(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
  );
}
