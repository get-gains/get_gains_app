import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/coach_client_model.dart';
import '../../data/models/program_model.dart';
import '../providers/coach_roster_provider.dart';

/// Coach Roster Screen (ML-4)
///
/// Displays the coach's class roster — all subscribed clients.
/// Shows `subscriptionExpiresAt` (ML-4) so coaches can see when
/// a client's platform subscription expires.
///
/// Highlights clients whose subscription is expiring within 7 days.
class CoachRosterScreen extends ConsumerStatefulWidget {
  const CoachRosterScreen({super.key});

  @override
  ConsumerState<CoachRosterScreen> createState() => _CoachRosterScreenState();
}

class _CoachRosterScreenState extends ConsumerState<CoachRosterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(coachRosterProvider.notifier).loadRoster());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachRosterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expiringCount = ref.watch(expiringClientsProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Roster'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (expiringCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppBadge(
                label: '$expiringCount expiring',
                variant: AppBadgeVariant.warning,
              ),
            ),
        ],
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(CoachRosterState state, bool isDark) {
    return switch (state) {
      CoachRosterInitial() ||
      CoachRosterLoading() => const Center(child: CircularProgressIndicator()),
      CoachRosterError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(height: 12),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () =>
                  ref.read(coachRosterProvider.notifier).loadRoster(),
            ),
          ],
        ),
      ),
      CoachRosterLoaded(:final clients, :final pagination) =>
        clients.isEmpty
            ? _buildEmpty()
            : _buildList(clients, pagination, isDark),
    };
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.people_outline,
      title: 'No Clients Yet',
      description:
          'Clients will appear here when they subscribe to you. '
          'Make sure you\'re discoverable in Coach Settings.',
      actionLabel: 'Coach Settings',
      onAction: () => context.push(AppRoutes.coachSettings),
    );
  }

  Widget _buildList(
    List<RosterClientModel> clients,
    PaginationMeta pagination,
    bool isDark,
  ) {
    // Sort: expiring soon first, then by subscribedAt descending
    final sorted = [...clients]
      ..sort((a, b) {
        final aExpiring = a.isExpiringSoon;
        final bExpiring = b.isExpiringSoon;
        if (aExpiring != bExpiring) return aExpiring ? -1 : 1;
        return b.subscribedAt.compareTo(a.subscribedAt);
      });

    return RefreshIndicator(
      onRefresh: () => ref.read(coachRosterProvider.notifier).loadRoster(),
      child: Column(
        children: [
          // Stats header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppStatsCard(
                    label: 'Total Clients',
                    value: '${pagination.total}',
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatsCard(
                    label: 'Expiring Soon',
                    value: '${sorted.where((c) => c.isExpiringSoon).length}',
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
          ),
          // Client list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: sorted.length + (pagination.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= sorted.length) {
                  Future.microtask(
                    () => ref.read(coachRosterProvider.notifier).loadMore(),
                  );
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final client = sorted[index];
                return _RosterClientCard(
                  client: client,
                  isDark: isDark,
                  onTap: () => context.push(
                    '${AppRoutes.clientAssignments.replaceFirst(':userId', client.id)}?name=${Uri.encodeComponent(client.displayName)}',
                  ),
                  onRemove: () => _confirmRemoveClient(client),
                  onViewProgress: () => context.push(
                    AppRoutes.clientProgress.replaceFirst(':userId', client.id),
                    extra: client.displayName,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveClient(RosterClientModel client) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Remove Client',
      message:
          'Remove "${client.displayName}" from your class? '
          'This will also remove their program assignments.',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(coachRosterProvider.notifier)
          .removeClient(client.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Client removed');
        } else {
          AppToast.error(context, 'Failed to remove client');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Roster Client Card
// ──────────────────────────────────────────────────────────

class _RosterClientCard extends StatelessWidget {
  const _RosterClientCard({
    required this.client,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
    required this.onViewProgress,
  });

  final RosterClientModel client;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onViewProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.interactive(
      onTap: onTap,
      borderColor: client.isExpiringSoon
          ? (isDark ? AppColors.warning : AppColors.warningMuted)
          : null,
      child: Row(
        children: [
          AppAvatar(name: client.displayName, size: AppAvatarSize.md),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.displayName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  client.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Subscription expiry badge (ML-4)
                    if (client.subscriptionExpiresAt != null)
                      _ExpiryBadge(
                        daysUntilExpiry: client.daysUntilExpiry ?? 0,
                        isExpiringSoon: client.isExpiringSoon,
                        isDark: isDark,
                      )
                    else
                      AppBadge(
                        label: 'No expiry data',
                        variant: AppBadgeVariant.secondary,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'Joined ${_formatDate(client.subscribedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            onSelected: (value) {
              if (value == 'remove') onRemove();
              if (value == 'progress') onViewProgress();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'progress',
                child: Row(
                  children: [
                    Icon(Icons.insights_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('View Progress'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_remove_outlined,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ──────────────────────────────────────────────────────────
// Expiry Badge (ML-4)
// ──────────────────────────────────────────────────────────

class _ExpiryBadge extends StatelessWidget {
  const _ExpiryBadge({
    required this.daysUntilExpiry,
    required this.isExpiringSoon,
    required this.isDark,
  });

  final int daysUntilExpiry;
  final bool isExpiringSoon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (daysUntilExpiry <= 0) {
      return const AppBadge(label: 'Expired', variant: AppBadgeVariant.error);
    }

    if (isExpiringSoon) {
      return AppBadge(
        label: '${daysUntilExpiry}d left',
        variant: AppBadgeVariant.warning,
      );
    }

    return AppBadge(
      label: '${daysUntilExpiry}d left',
      variant: AppBadgeVariant.success,
    );
  }
}
