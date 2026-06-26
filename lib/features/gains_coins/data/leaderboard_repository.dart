import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../../services/cache/cache_service.dart';
import 'models/leaderboard_entry_model.dart';

part 'leaderboard_repository.g.dart';

class LeaderboardCoach {
  const LeaderboardCoach({
    required this.coachId,
    required this.coachName,
    required this.clientCount,
  });

  final String coachId;
  final String coachName;
  final int clientCount;

  factory LeaderboardCoach.fromJson(Map<String, dynamic> json) {
    return LeaderboardCoach(
      coachId: json['coachId'] as String,
      coachName: json['coachName'] as String,
      clientCount: json['clientCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'coachId': coachId,
    'coachName': coachName,
    'clientCount': clientCount,
  };
}

class ClassLeaderboardResponse {
  const ClassLeaderboardResponse({
    required this.coachId,
    required this.coachName,
    required this.entries,
    required this.currentUserRank,
    required this.totalClients,
    required this.lastUpdated,
  });

  final String coachId;
  final String coachName;
  final List<LeaderboardEntryModel> entries;
  final int? currentUserRank;
  final int totalClients;
  final DateTime lastUpdated;

  factory ClassLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return ClassLeaderboardResponse(
      coachId: json['coachId'] as String,
      coachName: json['coachName'] as String? ?? '',
      entries: (json['entries'] as List? ?? [])
          .map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentUserRank: json['currentUserRank'] as int?,
      totalClients: json['totalClients'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'coachId': coachId,
    'coachName': coachName,
    'entries': entries.map((e) => e.toJson()).toList(),
    'currentUserRank': currentUserRank,
    'totalClients': totalClients,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

class LeaderboardRepository {
  LeaderboardRepository({required ApiClient apiClient, required CacheService cache})
    : _apiClient = apiClient,
      _cache = cache;

  final ApiClient _apiClient;
  final CacheService _cache;

  static const _myCoachesCacheKey = 'leaderboard_my_coaches';
  static String _leaderboardCacheKey(String coachId) =>
      'leaderboard_class_$coachId';

  // ============== Coach List Operations ==============

  Future<Result<List<LeaderboardCoach>, AppError>> getCachedCoaches() async {
    try {
      AppLogger.debug('Fetching cached coaches for leaderboard', tag: 'LeaderboardRepo');
      final cached = await _cache.getRaw(_myCoachesCacheKey);
      if (cached == null) {
        return const Success([]);
      }

      final data = jsonDecode(cached) as Map<String, dynamic>;
      final coaches = (data['coaches'] as List? ?? [])
          .map((c) => LeaderboardCoach.fromJson(c as Map<String, dynamic>))
          .toList();

      return Success(coaches);
    } catch (e) {
      AppLogger.error('Failed to fetch cached coaches', tag: 'LeaderboardRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load cached coaches: $e'));
    }
  }

  Future<Result<List<LeaderboardCoach>, AppError>> syncCoaches() async {
    AppLogger.debug('Syncing coaches from server', tag: 'LeaderboardRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.leaderboardMyCoaches,
    );

    return result.when(
      success: (data) async {
        try {
          final coaches = (data['coaches'] as List? ?? [])
              .map((c) => LeaderboardCoach.fromJson(c as Map<String, dynamic>))
              .toList();

          await _cache.put(
            _myCoachesCacheKey,
            jsonEncode({'coaches': coaches.map((c) => c.toJson()).toList()}),
            version: DateTime.now().toIso8601String(),
          );

          AppLogger.info('Synced ${coaches.length} coaches for leaderboard', tag: 'LeaderboardRepo');
          return Success(coaches);
        } catch (e) {
          AppLogger.error('Failed to parse/cache coaches', tag: 'LeaderboardRepo', error: e);
          return Failure(DatabaseError(message: 'Failed to parse coaches: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }

  // ============== Leaderboard Operations ==============

  Future<Result<ClassLeaderboardResponse?, AppError>> getCachedLeaderboard(
    String coachId,
  ) async {
    try {
      AppLogger.debug('Fetching cached leaderboard for coach $coachId', tag: 'LeaderboardRepo');
      final cached = await _cache.getRaw(_leaderboardCacheKey(coachId));
      if (cached == null) {
        return const Success(null);
      }

      final data = jsonDecode(cached) as Map<String, dynamic>;
      return Success(ClassLeaderboardResponse.fromJson(data));
    } catch (e) {
      AppLogger.error('Failed to fetch cached leaderboard', tag: 'LeaderboardRepo', error: e);
      return Failure(DatabaseError(message: 'Failed to load cached leaderboard: $e'));
    }
  }

  Future<Result<ClassLeaderboardResponse, AppError>> syncLeaderboard(
    String coachId, {
    int limit = 50,
  }) async {
    AppLogger.debug('Syncing leaderboard for coach $coachId', tag: 'LeaderboardRepo');

    final result = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.leaderboardClass}/$coachId',
      queryParameters: {'limit': limit},
    );

    return result.when(
      success: (data) async {
        try {
          final leaderboard = ClassLeaderboardResponse.fromJson(data);

          await _cache.put(
            _leaderboardCacheKey(coachId),
            jsonEncode(leaderboard.toJson()),
            version: DateTime.now().toIso8601String(),
          );

          AppLogger.info(
            'Synced leaderboard for coach $coachId: ${leaderboard.entries.length} entries',
            tag: 'LeaderboardRepo',
          );
          return Success(leaderboard);
        } catch (e) {
          AppLogger.error('Failed to parse/cache leaderboard', tag: 'LeaderboardRepo', error: e);
          return Failure(DatabaseError(message: 'Failed to parse leaderboard: $e'));
        }
      },
      failure: (error) => Failure(error),
    );
  }
}

@Riverpod(keepAlive: true)
LeaderboardRepository leaderboardRepository(Ref ref) {
  return LeaderboardRepository(
    apiClient: ref.watch(apiClientProvider),
    cache: ref.watch(cacheServiceProvider),
  );
}
