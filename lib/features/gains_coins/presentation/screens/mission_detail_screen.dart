// lib/features/gains_coins/presentation/screens/mission_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/mission_list_item_model.dart';
import '../providers/missions_provider.dart';

/// Full detail view for a single mission.
///
/// Displays title, partner, description, goal type, progress bar, reward info,
/// and dates. Opened via `/missions/:id` route.
///
/// @param missionId The server ID of the mission to display.
class MissionDetailScreen extends ConsumerWidget {
  const MissionDetailScreen({super.key, required this.missionId});

  final String missionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMissions = ref.watch(missionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: asyncMissions.when(
        data: (missions) {
          final mission = missions.cast<MissionListItemModel?>().firstWhere(
            (m) => m?.id == missionId,
            orElse: () => null,
          );

          if (mission == null) {
            return const Center(
              child: AppEmptyState.compact(
                icon: Icons.flag_outlined,
                title: 'Mission not found',
                description: 'This mission may have ended.',
              ),
            );
          }

          return _MissionDetail(mission: mission);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: AppEmptyState.compact(
            icon: Icons.error_outline,
            title: 'Could not load mission',
            description: e.toString(),
          ),
        ),
      ),
    );
  }
}

class _MissionDetail extends StatelessWidget {
  const _MissionDetail({required this.mission});

  final MissionListItemModel mission;

  String _goalLabel() {
    switch (mission.goalType) {
      case 'COMPLETE_WORKOUTS':
        return 'Workouts completed';
      case 'EARN_COINS':
        return 'Gains Coins earned';
      default:
        return 'Progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final progress = mission.displayProgress.clamp(0, mission.goalToReach);
    final ratio = mission.goalToReach > 0
        ? (progress / mission.goalToReach).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = ratio >= 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner chip
          if (mission.partner != null)
            AppBadge(
              label: mission.partner!.name,
              variant: AppBadgeVariant.primary,
              size: AppBadgeSize.sm,
            ),
          if (mission.partner != null) const SizedBox(height: 12),

          // Title
          Text(
            mission.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            mission.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

          // Progress block
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _goalLabel(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$progress / ${mission.goalToReach}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: isDark
                          ? AppColors.surface3Dark
                          : AppColors.surface3Light,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete
                            ? AppColors.success
                            : (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight),
                      ),
                    ),
                  ),
                  if (isComplete) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mission complete!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reward block
          if (mission.rewardCoins > 0)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFFFD700),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.rewardTitle ?? 'Reward',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${mission.rewardCoins} Gains Coins',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (mission.rewardDescription != null)
                            Text(
                              mission.rewardDescription!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Dates
          if (mission.endsAt != null) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ends ${_formatDate(mission.endsAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Max winners
          if (mission.maxWinners != null) ...[
            const SizedBox(height: 8),
            Text(
              'Limited to ${mission.maxWinners} winners',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
