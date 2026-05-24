// lib/features/home/presentation/widgets/home_greeting_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../gains_coins/presentation/widgets/coin_balance_widget.dart';
import '../../../guidance/guidance.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/profile.dart';
import '../../../subscription/subscription.dart';

/// Compact greeting strip displayed at the top of the home screen.
///
/// Shows greeting text, user display name, coin balance, notification bell, and avatar.
class HomeGreetingBar extends ConsumerWidget {
  const HomeGreetingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(profileProvider);
    final email = authState.email ?? '';
    final emailPrefix = email.isNotEmpty ? email.split('@').first : 'Athlete';
    final userName = profileAsync.asData?.value.name.isNotEmpty == true
        ? profileAsync.asData!.value.name
        : emailPrefix;
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          CoinBalanceWidget(
            compact: true,
            onTap: () => context.push(AppRoutes.coinHistory),
          ),
          const SizedBox(width: 4),
          _NotificationBell(),
          InfoIconButton(
            content: kHomeHelp,
            onTapOverride: () {
              ref.read(tourProvider.notifier).startTour('home', kHomeTourSteps);
            },
          ),
          GestureDetector(
            onTap: () => showProfileSheet(context),
            child: AppAvatar(name: userName, size: AppAvatarSize.sm),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = ref.watch(notificationPollProvider);

    final icon = Icon(
      Icons.notifications_outlined,
      color: isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
    );

    if (unreadCount == 0) {
      return IconButton(
        icon: icon,
        onPressed: () => context.push(AppRoutes.notifications),
      );
    }

    return IconButton(
      icon: Badge(
        label: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: icon,
      ),
      onPressed: () => context.push(AppRoutes.notifications),
    );
  }
}
