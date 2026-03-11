// lib/features/subscription/presentation/widgets/subscription_status_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/subscription_provider.dart';

/// Displays the current subscription status
///
/// Shows:
/// - Whether user is subscribed
/// - Plan name and tier
/// - Expiration date
/// - Renewal status
class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({super.key, this.onTap});

  /// Called when the card is tapped (e.g., to show upgrade options)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(currentSubscriptionProvider);
    final isSubscribed = ref.watch(isSubscribedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isSubscribed || subscription == null) {
      return _buildFreeCard(context, isDark);
    }

    return _buildSubscribedCard(context, subscription, isDark);
  }

  Widget _buildFreeCard(BuildContext context, bool isDark) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.secondaryDark
                    : AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upgrade to unlock premium features',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribedCard(
    BuildContext context,
    SubscriptionModel subscription,
    bool isDark,
  ) {
    final daysRemaining = subscription.daysRemaining;
    final willExpire = subscription.willExpire;

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.7)
                        : AppColors.primaryLight.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatPlanName(subscription.plan.name),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppBadge(
                        label: 'Active',
                        variant: AppBadgeVariant.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    willExpire
                        ? 'Expires in $daysRemaining days'
                        : 'Renews in $daysRemaining days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: willExpire
                          ? AppColors.warning
                          : isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPlanName(String name) {
    // Convert snake_case to Title Case
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
