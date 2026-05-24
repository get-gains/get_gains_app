import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/notification_model.dart';
import '../../data/notification_repository.dart';

part 'notification_providers.g.dart';

@riverpod
Future<int> unreadNotificationCount(Ref ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final result = await repo.getUnreadCount();
  return result.when(
    success: (count) => count,
    failure: (_) => repo.getCachedNotifications().where((n) => !n.isRead).length,
  );
}

@Riverpod(keepAlive: true)
class NotificationPoll extends _$NotificationPoll {
  Timer? _timer;
  AppLifecycleListener? _lifecycleListener;

  @override
  int build() {
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycleListener?.dispose();
    });

    _startPolling();

    final cached =
        ref.read(notificationRepositoryProvider).getCachedNotifications();
    return cached.where((n) => !n.isRead).length;
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchUnreadCount();
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        _timer?.cancel();
        AppLogger.debug('Notification poll paused', tag: 'NotificationPoll');
      },
      onResume: () {
        _fetchUnreadCount();
        _startPolling();
        AppLogger.debug('Notification poll resumed', tag: 'NotificationPoll');
      },
    );

    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final repo = ref.read(notificationRepositoryProvider);
    final result = await repo.getUnreadCount();
    result.when(
      success: (count) {
        if (count != state) {
          state = count;
        }
      },
      failure: (_) {},
    );
  }

  void reset() {
    state = 0;
  }
}

@riverpod
Future<NotificationListState> notificationList(
  Ref ref, {
  int page = 0,
}) async {
  const limit = 20;
  final repo = ref.read(notificationRepositoryProvider);
  final result = await repo.getNotifications(
    limit: limit,
    offset: page * limit,
  );

  return result.when(
    success: (data) => NotificationListState(
      notifications: data.notifications,
      total: data.total,
      unreadCount: data.unreadCount,
      currentPage: page,
      hasMore: (page + 1) * limit < data.total,
    ),
    failure: (error) {
      AppLogger.error(
        'Failed to fetch notifications',
        tag: 'NotificationList',
        error: error,
      );
      throw error;
    },
  );
}

class NotificationListState {
  const NotificationListState({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.currentPage,
    required this.hasMore,
  });

  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int currentPage;
  final bool hasMore;
}
