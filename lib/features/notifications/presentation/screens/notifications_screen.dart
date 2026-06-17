import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/app_navigation.dart';
import '../../data/models/notification_model.dart';
import '../../data/notification_repository.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Notifications',
        actions: [
          AppTopBarAction(
            icon: Icons.done_all,
            onPressed: () => _markAllAsRead(ref),
          ),
        ],
      ),
      body: _NotificationList(isDark: isDark),
    );
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    final repo = ref.read(notificationRepositoryProvider);
    final result = await repo.markAllAsRead();
    result.when(
      success: (_) {
        ref.invalidate(notificationListProvider);
        ref.read(notificationPollProvider.notifier).reset();
        AppLogger.debug('All notifications marked as read', tag: 'NotifScreen');
      },
      failure: (error) {
        AppLogger.error(
          'Failed to mark all as read',
          tag: 'NotifScreen',
          error: error,
        );
      },
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(
      notificationListProvider(page: 0),
    );

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Failed to load notifications',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
      data: (state) {
        if (state.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.notifications.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          ),
          itemBuilder: (context, index) {
            final notification = state.notifications[index];
            return _NotificationTile(
              notification: notification,
              isDark: isDark,
              onTap: () => _handleTap(context, ref, notification),
            );
          },
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    if (!notification.isRead) {
      ref
          .read(notificationRepositoryProvider)
          .markAsRead(notification.id)
          .then((result) {
        if (result.isSuccess) {
          ref.invalidate(notificationListProvider);
        }
      });
    }

    switch (notification.type) {
      case NotificationType.programAssigned:
        context.push(AppRoutes.programs);
      case NotificationType.coachSubscribed:
        final clientId = notification.data['clientId'] as String?;
        if (clientId != null) {
          context.push('/coach/clients/$clientId/progress');
        }
      case NotificationType.subscriptionExpiring:
        context.push('/settings');
      case NotificationType.rosterRemoved:
      case NotificationType.missionRaffleWon:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = notification.isRead
        ? Colors.transparent
        : (isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.5)
            : AppColors.surfaceLight.withValues(alpha: 0.5));

    return InkWell(
      onTap: onTap,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon() {
    switch (notification.type) {
      case NotificationType.programAssigned:
        return const Icon(Icons.assignment, size: 24);
      case NotificationType.coachSubscribed:
        return const Icon(Icons.person_add, size: 24);
      case NotificationType.rosterRemoved:
        return const Icon(Icons.person_remove, size: 24);
      case NotificationType.subscriptionExpiring:
        return const Icon(Icons.warning_amber, size: 24);
      case NotificationType.missionRaffleWon:
        return const Icon(Icons.emoji_events, size: 24);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}
