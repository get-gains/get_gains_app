// lib/features/subscription/presentation/widgets/profile_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../gains_coins/presentation/providers/missions_provider.dart';
import '../../../home/presentation/screens/home_screen.dart' show isCoachProvider;
import '../../../profile/profile.dart';
import '../providers/subscription_provider.dart';
import 'plan_card.dart';
import 'subscription_status_card.dart';

/// Profile bottom sheet showing user info and subscription.
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
    final fitnessProfileAsync = ref.watch(userProfileProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final isSubscribed = ref.watch(isSubscribedProvider);
    final coachStatus = ref.watch(isCoachProvider).asData?.value;
    final isCoach = coachStatus != null && coachStatus.isCoach;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final email = authState.email ?? '';
    final userName = email.isNotEmpty ? email.split('@').first : 'User';
    final fitnessProfile = fitnessProfileAsync.asData?.value;
    final avatarUrl = fitnessProfile?.avatarUrl;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserInfo(context, userName, email, avatarUrl, isDark),
            const SizedBox(height: 24),

            if (subscriptionState is SubscriptionLoaded) ...[
              if (isSubscribed) ...[
                SubscriptionStatusCard(
                  onTap: () => setState(() => _showPlans = !_showPlans),
                ),
                const SizedBox(height: 16),
                if (_showPlans) ...[
                  _buildPlansSection(context, subscriptionState, isDark),
                  const SizedBox(height: 16),
                ],
              ] else ...[
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

            _buildMenuItems(context, isDark, isCoach),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    String userName,
    String email,
    String? avatarUrl,
    bool isDark,
  ) {
    return Row(
      children: [
        AppAvatar(name: userName, imageUrl: avatarUrl, size: AppAvatarSize.xl),
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

  List<Package> _getPackages(SubscriptionLoaded state) {
    return state.currentOffering?.availablePackages ?? [];
  }

  Widget _buildCouponCta(BuildContext context) {
    final offerTagAsync = ref.watch(activeCouponOfferTagProvider);

    return offerTagAsync.when(
      data: (offerTag) {
        if (offerTag == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mission reward available',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You earned a 20% off Premium coupon. Redeem it now.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 12),
                  AppButton.primary(
                    label: 'Redeem 20% Off',
                    icon: Icons.local_offer,
                    isFullWidth: true,
                    onPressed: () => ref
                        .read(subscriptionProvider.notifier)
                        .purchaseDiscountedOption(offerTag),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFreeUserSection(
    BuildContext context,
    SubscriptionLoaded state,
    bool isDark,
  ) {
    final packages = _getPackages(state);
    final hasPackages = packages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        _buildCouponCta(context),

        if (hasPackages) ...[
          AppButton.primary(
            label: 'Upgrade to Premium',
            icon: Icons.workspace_premium,
            isFullWidth: true,
            onPressed: () => setState(() => _showPlans = true),
          ),
          if (_showPlans) ...[
            const SizedBox(height: 16),
            _buildPlansSection(context, state, isDark),
          ],
        ] else ...[
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
    final packages = _getPackages(state);

    if (packages.isEmpty) {
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
        ...packages.map(
          (package) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlanCard(
              package: package,
              isLoading: state.purchaseInProgress,
              onPurchase: () => _handlePurchase(package),
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

  Widget _buildMenuItems(BuildContext context, bool isDark, bool isCoach) {
    return Column(
      children: [
        const Divider(),
        AppListTile(
          leading: const Icon(Icons.settings_outlined),
          title: 'Settings',
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        if (!isCoach)
          AppListTile(
            leading: const Icon(Icons.card_membership),
            title: 'Redeem Coach Invite',
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.redeemInvite);
            },
          ),
        AppListTile(
          leading: const Icon(Icons.help_outline),
          title: 'Help & Support',
          onTap: () {},
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

  Future<void> _handlePurchase(Package package) async {
    await ref.read(subscriptionProvider.notifier).purchase(package);
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

/// Shows the profile sheet.
Future<void> showProfileSheet(BuildContext context) {
  return showAppBottomSheet(
    context: context,
    builder: (context) => const ProfileSheet(),
  );
}
