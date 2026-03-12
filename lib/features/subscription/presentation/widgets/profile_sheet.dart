// lib/features/subscription/presentation/widgets/profile_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/subscription_provider.dart';
import 'plan_card.dart';
import 'subscription_status_card.dart';

/// Profile bottom sheet showing user info and subscription
///
/// Opened by tapping the avatar in the home screen.
/// Shows:
/// - User avatar and name
/// - Current subscription status
/// - Available plans for upgrade
/// - Logout option
class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key});

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  bool _showPlans = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final isSubscribed = ref.watch(isSubscribedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final email = authState.email ?? '';
    final userName = email.isNotEmpty ? email.split('@').first : 'User';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User info
            _buildUserInfo(context, userName, email, isDark),
            const SizedBox(height: 24),

            // Subscription status
            if (subscriptionState is SubscriptionLoaded) ...[
              // Show status card for subscribed users, or upgrade prompt for free users
              if (isSubscribed) ...[
                SubscriptionStatusCard(
                  onTap: () => setState(() => _showPlans = !_showPlans),
                ),
                const SizedBox(height: 16),

                // Plans section (for managing subscription)
                if (_showPlans) ...[
                  _buildPlansSection(context, subscriptionState, isDark),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                // Free user - show upgrade button prominently
                _buildFreeUserSection(context, subscriptionState, isDark),
                const SizedBox(height: 16),
              ],
            ] else if (subscriptionState is SubscriptionLoading) ...[
              const Center(child: AppCircularProgress()),
              const SizedBox(height: 16),
            ] else if (subscriptionState is SubscriptionError) ...[
              _buildErrorState(context, subscriptionState, isDark),
              const SizedBox(height: 16),
            ],

            // Menu items
            _buildMenuItems(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    String userName,
    String email,
    bool isDark,
  ) {
    return Row(
      children: [
        AppAvatar(name: userName, size: AppAvatarSize.xl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFreeUserSection(
    BuildContext context,
    SubscriptionLoaded state,
    bool isDark,
  ) {
    final plans = state.plans;
    final hasPlans = plans.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Free tier badge
        AppCard(
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
                    Icons.person_outline,
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
                      Row(
                        children: [
                          Text(
                            'Free Plan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          AppBadge(
                            label: 'Current',
                            variant: AppBadgeVariant.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Basic features included',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Upgrade button
        if (hasPlans) ...[
          AppButton.primary(
            label: 'Upgrade to Premium',
            icon: Icons.workspace_premium,
            isFullWidth: true,
            onPressed: () => setState(() => _showPlans = true),
          ),

          // Show plans if expanded
          if (_showPlans) ...[
            const SizedBox(height: 16),
            _buildPlansSection(context, state, isDark),
          ],
        ] else ...[
          // No plans available
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Premium plans coming soon!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlansSection(
    BuildContext context,
    SubscriptionLoaded state,
    bool isDark,
  ) {
    final plans = state.plans;
    final currentPlanId = state.status.subscription?.plan.id;

    if (plans.isEmpty) {
      return const AppEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Plans Available',
        description: 'Check back later for subscription options.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Plans',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...plans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlanCard(
              plan: plan,
              isCurrentPlan: plan.id == currentPlanId,
              isRecommended: plan.tierLevel == 2, // Premium is recommended
              isLoading: state.purchaseInProgress,
              onPurchase: () => _handlePurchase(plan),
            ),
          ),
        ),

        // Error message
        if (state.purchaseError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.purchaseError!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Restore purchases
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: state.purchaseInProgress
                ? null
                : () => ref
                      .read(subscriptionProvider.notifier)
                      .restorePurchases(),
            child: const Text('Restore Purchases'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    SubscriptionError state,
    bool isDark,
  ) {
    return AppErrorState(
      title: 'Failed to Load',
      description: state.error.message,
      retryLabel: 'Retry',
      onRetry: () => ref.read(subscriptionProvider.notifier).load(),
    );
  }

  Widget _buildMenuItems(BuildContext context, bool isDark) {
    return Column(
      children: [
        const Divider(),
        AppListTile(
          leading: const Icon(Icons.settings_outlined),
          title: 'Settings',
          onTap: () {
            Navigator.of(context).pop();
            // Navigate to settings
          },
        ),
        AppListTile(
          leading: const Icon(Icons.help_outline),
          title: 'Help & Support',
          onTap: () {
            // Show help
          },
        ),
        const Divider(),
        AppListTile(
          leading: Icon(Icons.logout, color: AppColors.error),
          title: 'Sign Out',
          titleStyle: TextStyle(color: AppColors.error),
          onTap: () => _handleLogout(context),
        ),
      ],
    );
  }

  Future<void> _handlePurchase(PlanModel plan) async {
    final success = await ref
        .read(subscriptionProvider.notifier)
        .purchase(plan.productId);

    if (success && mounted) {
      AppToast.success(context, 'Purchase initiated');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Sign Out?',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Shows the profile sheet
///
/// Call this when the user taps their avatar in the home screen.
Future<void> showProfileSheet(BuildContext context) {
  return showAppBottomSheet(
    context: context,
    builder: (context) => const ProfileSheet(),
  );
}
