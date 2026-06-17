// lib/features/gains_coins/presentation/screens/mission_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../../subscription/presentation/widgets/profile_sheet.dart';
import '../../data/models/mission_list_item_model.dart';
import '../providers/missions_provider.dart';
import '../widgets/partner_detail_dialog.dart';

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

  void _showPartnerDialog(BuildContext context) {
    if (mission.partner == null) return;
    showDialog(
      context: context,
      builder: (_) => PartnerDetailDialog(partner: mission.partner!),
    );
  }

  void _redeemCoupon(BuildContext context) {
    showProfileSheet(context);
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
          // Closed banner
          if (mission.isClosed)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'This mission has ended',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          if (mission.isClosed) const SizedBox(height: 16),

          // Partner chip
          if (mission.partner != null)
            InkWell(
              onTap: () => _showPartnerDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: AppBadge(
                label: mission.partner!.name,
                variant: AppBadgeVariant.primary,
                size: AppBadgeSize.sm,
              ),
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
          _RewardCard(mission: mission, onRedeem: () => _redeemCoupon(context)),

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

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.mission, required this.onRedeem});

  final MissionListItemModel mission;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _rewardColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _rewardIcon(),
                color: _rewardColor(),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.rewardTitle ?? _defaultRewardTitle(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RewardBody(
                    mission: mission,
                    isDark: isDark,
                    onRedeem: onRedeem,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _defaultRewardTitle() {
    return switch (mission.rewardType) {
      'COINS' => 'Gains Coins',
      'RAFFLE' => 'Raffle Entry',
      'COUPON' => 'Premium Coupon',
      _ => 'Reward',
    };
  }

  IconData _rewardIcon() {
    return switch (mission.rewardType) {
      'COINS' => Icons.stars_rounded,
      'RAFFLE' => Icons.card_giftcard,
      'COUPON' => Icons.local_offer,
      _ => Icons.card_giftcard,
    };
  }

  Color _rewardColor() {
    return switch (mission.rewardType) {
      'COINS' => const Color(0xFFFFD700),
      'RAFFLE' => AppColors.primaryLight,
      'COUPON' => AppColors.success,
      _ => AppColors.primaryLight,
    };
  }
}

class _RewardBody extends StatelessWidget {
  const _RewardBody({
    required this.mission,
    required this.isDark,
    required this.onRedeem,
  });

  final MissionListItemModel mission;
  final bool isDark;
  final VoidCallback onRedeem;

  TextStyle? _mutedStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        );
  }

  @override
  Widget build(BuildContext context) {
    switch (mission.rewardType) {
      case 'COINS':
        return Text(
          '${mission.rewardCoins} Gains Coins',
          style: _mutedStyle(context),
        );
      case 'RAFFLE':
        final raffle = mission.raffle;
        if (raffle == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              raffle.isWinner
                  ? 'You won! Rank #${raffle.winnerRank}'
                  : '${raffle.entryCount} ticket${raffle.entryCount == 1 ? '' : 's'} entered',
              style: _mutedStyle(context),
            ),
            if (mission.isClosed && !raffle.isWinner)
              Text(
                'Raffle closed',
                style: _mutedStyle(context),
              ),
          ],
        );
      case 'COUPON':
        final coupon = mission.coupon;
        if (coupon == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coupon.claimed
                  ? '${coupon.discountPercent}% off Premium claimed'
                  : '${coupon.discountPercent}% off Premium when completed',
              style: _mutedStyle(context),
            ),
            if (coupon.claimed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppButton(
                  onPressed: onRedeem,
                  label: 'Redeem Coupon',
                  size: AppButtonSize.sm,
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
