import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/coach_model.dart';
import '../providers/subscribed_coaches_provider.dart';

/// Subscribed Coaches Screen
///
/// Displays the authenticated user's list of subscribed coaches.
/// Each entry includes the subscription date. Tapping a coach opens
/// their full profile. Users can unsubscribe from this screen.
class SubscribedCoachesScreen extends ConsumerStatefulWidget {
  const SubscribedCoachesScreen({super.key});

  @override
  ConsumerState<SubscribedCoachesScreen> createState() =>
      _SubscribedCoachesScreenState();
}

class _SubscribedCoachesScreenState
    extends ConsumerState<SubscribedCoachesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(subscribedCoachesProvider.notifier).loadCoaches(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscribedCoachesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Coaches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            tooltip: 'Find Coaches',
            onPressed: () => context.push(AppRoutes.discoverCoaches),
          ),
        ],
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(SubscribedCoachesState state, bool isDark) {
    return switch (state) {
      SubscribedCoachesInitial() || SubscribedCoachesLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      SubscribedCoachesError(:final error) => Center(
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
                  ref.read(subscribedCoachesProvider.notifier).loadCoaches(),
            ),
          ],
        ),
      ),
      SubscribedCoachesLoaded(:final coaches, :final pagination) =>
        coaches.isEmpty
            ? _buildEmpty()
            : _buildList(coaches, pagination, isDark),
    };
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.people_outline,
      title: 'No Coaches Yet',
      description:
          'Find and subscribe to coaches to get personalized training programs.',
      actionLabel: 'Find Coaches',
      onAction: () => context.push(AppRoutes.discoverCoaches),
    );
  }

  Widget _buildList(
    List<CoachSummaryModel> coaches,
    CoachPaginationMeta pagination,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(subscribedCoachesProvider.notifier).loadCoaches(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: coaches.length + (pagination.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= coaches.length) {
            Future.microtask(
              () => ref.read(subscribedCoachesProvider.notifier).loadMore(),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final coach = coaches[index];
          return _SubscribedCoachCard(
            coach: coach,
            isDark: isDark,
            onTap: () => context.push(
              AppRoutes.coachProfile.replaceFirst(':id', coach.id),
            ),
            onUnsubscribe: () => _confirmUnsubscribe(coach),
          );
        },
      ),
    );
  }

  Future<void> _confirmUnsubscribe(CoachSummaryModel coach) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Unsubscribe',
      message:
          'Are you sure you want to unsubscribe from "${coach.name}"? '
          'You will lose access to their programs.',
      confirmLabel: 'Unsubscribe',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(subscribedCoachesProvider.notifier)
          .unsubscribeFromCoach(coach.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Unsubscribed from ${coach.name}');
        } else {
          AppToast.error(context, 'Failed to unsubscribe');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Subscribed Coach Card
// ──────────────────────────────────────────────────────────

class _SubscribedCoachCard extends StatelessWidget {
  const _SubscribedCoachCard({
    required this.coach,
    required this.isDark,
    required this.onTap,
    required this.onUnsubscribe,
  });

  final CoachSummaryModel coach;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onUnsubscribe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.interactive(
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(
            imageUrl: coach.avatarUrl,
            name: coach.name,
            size: AppAvatarSize.lg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        coach.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (coach.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 18,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ],
                  ],
                ),
                if (coach.specialties.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    coach.specialties.take(3).join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (coach.subscribedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Since ${_formatDate(coach.subscribedAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ],
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
              if (value == 'unsubscribe') onUnsubscribe();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'unsubscribe',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_remove_outlined,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('Unsubscribe', style: TextStyle(color: Colors.red)),
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
