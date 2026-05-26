import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../services/api/api_client.dart';
import '../../auth/services/user_preferences_service.dart';
import 'models/notification_model.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  NotificationRepository({
    required ApiClient apiClient,
    required UserPreferencesService prefs,
  })  : _apiClient = apiClient,
        _prefs = prefs;

  final ApiClient _apiClient;
  final UserPreferencesService _prefs;

  static const _cacheKey = 'notifications_cache';

  Future<Result<NotificationListResponse, AppError>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
    String? after,
  }) async {
    AppLogger.debug(
      'Fetching notifications (offset: $offset)',
      tag: 'NotificationRepo',
    );

    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (unreadOnly) 'unreadOnly': 'true',
      if (after != null) 'after': after,
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.notifications,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final notifications = (data['notifications'] as List)
              .map(
                (n) =>
                    NotificationModel.fromJson(n as Map<String, dynamic>),
              )
              .toList();
          final total = data['total'] as int;
          final unreadCount = data['unreadCount'] as int;

          _cacheNotifications(notifications);

          return Success(
            NotificationListResponse(
              notifications: notifications,
              total: total,
              unreadCount: unreadCount,
            ),
          );
        } catch (e) {
          AppLogger.error(
            'Failed to parse notifications',
            tag: 'NotificationRepo',
            error: e,
          );
          return Failure(
            DatabaseError(message: 'Failed to parse notifications: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<int, AppError>> getUnreadCount() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.notificationUnreadCount,
    );

    return result.when(
      success: (data) => Success(data['count'] as int),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<NotificationModel, AppError>> markAsRead(
    String notificationId,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiConstants.notificationMarkRead(notificationId),
    );

    return result.when(
      success: (data) {
        final notification = NotificationModel.fromJson(
          data['notification'] as Map<String, dynamic>,
        );
        _updateCachedNotification(notification);
        return Success(notification);
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<int, AppError>> markAllAsRead() async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiConstants.notificationReadAll,
    );

    return result.when(
      success: (data) {
        _markAllCachedAsRead();
        return Success(data['count'] as int);
      },
      failure: (error) => Failure(error),
    );
  }

  List<NotificationModel> getCachedNotifications() {
    final raw = _prefs.readRaw(_cacheKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(
        'Failed to parse cached notifications',
        tag: 'NotificationRepo',
        error: e,
      );
      return [];
    }
  }

  void _cacheNotifications(List<NotificationModel> notifications) {
    final json = jsonEncode(notifications.map((n) => n.toJson()).toList());
    _prefs.cacheRaw(_cacheKey, json);
  }

  void _updateCachedNotification(NotificationModel updated) {
    final cached = getCachedNotifications();
    final index = cached.indexWhere((n) => n.id == updated.id);
    if (index != -1) {
      cached[index] = updated;
      _cacheNotifications(cached);
    }
  }

  void _markAllCachedAsRead() {
    final cached = getCachedNotifications();
    final updated = cached
        .map(
          (n) => n.isRead
              ? n
              : n.copyWith(isRead: true, readAt: DateTime.now()),
        )
        .toList();
    _cacheNotifications(updated);
  }
}

class NotificationListResponse {
  const NotificationListResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });

  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
}

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepository(
    apiClient: ref.watch(apiClientProvider),
    prefs: ref.watch(userPreferencesServiceProvider),
  );
}
