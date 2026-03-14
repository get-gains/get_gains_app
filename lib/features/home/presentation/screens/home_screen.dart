// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../services/api/api_client.dart';
import '../../../../widgets/widgets.dart';
import '../../../gains_coins/presentation/widgets/coin_balance_widget.dart';
import '../../../profile/profile.dart';
import '../../../subscription/subscription.dart';
import '../../../workout/data/models/models.dart';
import '../providers/home_providers.dart';
import '../widgets/widgets.dart';

final isCoachProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  final currentUserId = authState.userId;

  if (!authState.isAuthenticated || currentUserId == null) {
    return false;
  }

  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.get<Map<String, dynamic>>('/auth/me');

  return result.when(
    success: (data) {
      final user = data['user'];
      if (user is! Map<String, dynamic>) return false;

      final responseUserId = user['id'] as String?;
      if (responseUserId != null && responseUserId != currentUserId) {
        return false;
      }

      final isCoach = data['isCoach'];
      if (isCoach is bool) return isCoach;

      final userIsCoach = user['isCoach'];
      if (userIsCoach is bool) return userIsCoach;

      return false;
    },
    failure: (_) => false,
  );
});

/// Main home screen / dashboard
///
/// Displays:
/// - Welcome header with user greeting
/// - Quick action to start workout
/// - Today's workout / active routine
/// - Weekly progress overview
/// - Recent workout history
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingShown = false;

  @override
  Widget build(BuildContext context) {
    // ── Onboarding check ──────────────────────────────────────────
    // Show the setup sheet once when the profile hasn't been created.
    ref.listen<bool>(needsOnboardingProvider, (previous, needsOnboarding) {
      if (needsOnboarding && !_onboardingShown) {
        _onboardingShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showOnboardingSheet(context);
        });
      }
    });

    // Also check on first build (listen only fires on change)
    final needsOnboarding = ref.watch(needsOnboardingProvider);
    if (needsOnboarding && !_onboardingShown) {
      _onboardingShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showOnboardingSheet(context);
      });
    }

    final authState = ref.watch(authStateProvider);
    final isCoachAsync = ref.watch(isCoachProvider);
    final homeStatusAsync = ref.watch(homeStatusProvider);
    final todayAsync = ref.watch(activeTodayProvider);
    final weeklyAsync = ref.watch(unifiedWeeklyStatsProvider);
    final recentAsync = ref.watch(recentActivityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Extract name from email or use default
    final email = authState.email ?? '';
    final userName = email.isNotEmpty ? email.split('@').first : 'Athlete';
    final greeting = _getGreeting();
    final isCoach = isCoachAsync.asData?.value ?? false;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                title: Column(
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
                actions: [
                  CoinBalanceWidget(
                    compact: true,
                    onTap: () => context.push(AppRoutes.coinHistory),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => showProfileSheet(context),
                      child: AppAvatar(name: userName, size: AppAvatarSize.sm),
                    ),
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Quick Actions Section ────────────────────
                    _SectionHeader(title: 'Quick Actions', isDark: isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.fitness_center,
                            title: 'Start Workout',
                            subtitle: 'Begin your training',
                            gradient: LinearGradient(
                              colors: [
                                isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight,
                                isDark
                                    ? AppColors.primaryDark.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppColors.primaryLight.withValues(
                                        alpha: 0.7,
                                      ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.push(AppRoutes.routines),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.history,
                            title: 'History',
                            subtitle: 'View past workouts',
                            gradient: LinearGradient(
                              colors: [
                                isDark
                                    ? AppColors.secondaryDark
                                    : AppColors.secondaryLight,
                                isDark
                                    ? AppColors.secondaryDark.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppColors.secondaryLight.withValues(
                                        alpha: 0.7,
                                      ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.push(AppRoutes.workoutHistory),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Shop & Wardrobe quick actions
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.storefront_rounded,
                            title: 'Shop',
                            subtitle: 'Cosmetics & gear',
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFD700),
                                const Color(0xFFFFD700).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.push(AppRoutes.shop),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.checkroom_rounded,
                            title: 'Wardrobe',
                            subtitle: 'Equip cosmetics',
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF8B5CF6),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.push(AppRoutes.inventory),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Leaderboard quick action
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.leaderboard_rounded,
                            title: 'Leaderboard',
                            subtitle: 'Class rankings',
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6),
                                const Color(0xFF3B82F6).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.push(AppRoutes.leaderboard),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Progress quick action
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.trending_up_rounded,
                            title: 'Progress',
                            subtitle: 'Track your gains',
                            gradient: LinearGradient(
                              colors: [
                                isDark
                                    ? AppColors.accentDark
                                    : const Color(0xFF22C55E),
                                isDark
                                    ? AppColors.accentDark.withValues(
                                        alpha: 0.7,
                                      )
                                    : const Color(
                                        0xFF22C55E,
                                      ).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.push(AppRoutes.progress),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Coach-only quick action (M-CF1-1)
                    if (isCoach) ...[
                      Row(
                        children: [
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.sports,
                              title: 'Coach Tools',
                              subtitle: 'Programs, exercises & clients',
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF3B82F6),
                                  const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => context.push(AppRoutes.coachHub),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 24),

                    // ── Home Status CTA (M-CL1 / M-CL7) ────────
                    // First gated section = prominent (compact: false),
                    // all subsequent coach sections use compact mode.
                    homeStatusAsync.when(
                      data: (status) {
                        switch (status) {
                          case HomeStatus.noCoach:
                            return _FindCoachCta(isDark: isDark);
                          case HomeStatus.noSubscription:
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: SubscriptionGatedWidget(
                                requiredTier: SubscriptionTiers.basic,
                                feature: SubscriptionFeature.coachWorkout,
                                compact:
                                    false, // Prominent: first gated section
                                child: const SizedBox.shrink(),
                              ),
                            );
                          case HomeStatus.waitingForProgram:
                            return _WaitingForProgramCard(isDark: isDark);
                          case HomeStatus.restDay:
                          case HomeStatus.hasRoutine:
                            return const SizedBox.shrink();
                        }
                      },
                      loading: () => _buildStatusSkeleton(isDark),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // ── Today's Focus Section (M-CL2) ───────────
                    _SectionHeader(
                      title: 'Today\'s Focus',
                      isDark: isDark,
                      action: TextButton(
                        onPressed: () => context.push(AppRoutes.routines),
                        child: const Text('See All'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    todayAsync.when(
                      data: (today) {
                        if (today.isRestDay) {
                          return WorkoutSummaryCard(
                            routineName: 'Rest Day 🧘',
                            description:
                                'No routine scheduled today. Recovery is part of the process!',
                            exerciseCount: 0,
                            estimatedMinutes: 0,
                            isPlaceholder: true,
                            onStartPressed: () =>
                                context.push(AppRoutes.routines),
                          );
                        }
                        if (today.hasRoutine) {
                          final details = today.today!;
                          return WorkoutSummaryCard(
                            routineName: today.displayName,
                            description:
                                '${details.programName} · Day ${details.dayNumber}',
                            exerciseCount: today.exerciseCount,
                            estimatedMinutes: today.estimatedMinutes,
                            isPlaceholder: false,
                            completedToday: today.completedToday,
                            onStartPressed: today.completedToday
                                ? null
                                : () => context.push(AppRoutes.routines),
                          );
                        }
                        // No active programs at all — show Start a Program CTA
                        return _StartProgramCta(isDark: isDark);
                      },
                      loading: () => _buildTodaySkeleton(isDark),
                      error: (_, __) => _StartProgramCta(isDark: isDark),
                    ),

                    const SizedBox(height: 24),

                    // ── Weekly Progress Section (M-CL3) ─────────
                    _SectionHeader(title: 'This Week', isDark: isDark),
                    const SizedBox(height: 12),
                    weeklyAsync.when(
                      data: (stats) => WeeklyProgressCard(
                        workoutsCompleted: stats.workoutsCompleted,
                        workoutsGoal: 4, // TODO: make configurable
                        totalMinutes: stats.totalMinutes,
                        streakDays: stats.streakDays,
                      ),
                      loading: () => const WeeklyProgressCard(
                        workoutsCompleted: 0,
                        workoutsGoal: 4,
                        totalMinutes: 0,
                        streakDays: 0,
                      ),
                      error: (_, __) => const WeeklyProgressCard(
                        workoutsCompleted: 0,
                        workoutsGoal: 4,
                        totalMinutes: 0,
                        streakDays: 0,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Recent Activity Section (M-CL4) ─────────
                    _SectionHeader(
                      title: 'Recent Activity',
                      isDark: isDark,
                      action: TextButton(
                        onPressed: () => context.push(AppRoutes.workoutHistory),
                        child: const Text('See All'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    recentAsync.when(
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return AppEmptyState.compact(
                            icon: Icons.history,
                            title: 'No Recent Workouts',
                            description:
                                'Your completed workouts will appear here.',
                          );
                        }
                        return Column(
                          children: sessions
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: RecentActivityCard(session: s),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => AppEmptyState.compact(
                        icon: Icons.history,
                        title: 'No Recent Workouts',
                        description:
                            'Your completed workouts will appear here.',
                      ),
                      error: (_, __) => AppEmptyState.compact(
                        icon: Icons.history,
                        title: 'No Recent Workouts',
                        description:
                            'Your completed workouts will appear here.',
                      ),
                    ),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.push(AppRoutes.routines);
              break;
            case 2:
              context.push(AppRoutes.progress);
              break;
            case 3:
              context.push(AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(isCoachProvider);
    ref.invalidate(homeStatusProvider);
    ref.invalidate(todayRoutineProvider);
    ref.invalidate(activeTodayProvider);
    ref.invalidate(unifiedWeeklyStatsProvider);
    ref.invalidate(recentActivityProvider);
    ref.invalidate(hasSubscribedCoachProvider);
    // Wait for the key providers to re-fetch
    await Future.wait<void>([
      ref.read(homeStatusProvider.future).then((_) {}),
      ref.read(unifiedWeeklyStatsProvider.future).then((_) {}),
    ]);
  }

  /// Loading skeleton for the today's workout section (T040).
  Widget _buildTodaySkeleton(bool isDark) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// Loading skeleton for the home status CTA section (T040).
  Widget _buildStatusSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// CTA shown when user has no active programs at all (T038).
class _StartProgramCta extends StatelessWidget {
  const _StartProgramCta({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Start a Program',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Create a standalone workout program or find a coach to get personalized training.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Browse Workouts',
                icon: Icons.arrow_forward,
                onPressed: () => context.push(AppRoutes.routines),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CTA card shown when user has no subscribed coach (M-CL7).
class _FindCoachCta extends StatelessWidget {
  const _FindCoachCta({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_search,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Find a Coach',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Get personalized workout programs from a certified coach to reach your fitness goals.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: 'Discover Coaches',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.push(AppRoutes.discoverCoaches),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card shown when user has a coach but no program yet.
class _WaitingForProgramCard extends StatelessWidget {
  const _WaitingForProgramCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waiting for Program',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your coach hasn\'t assigned a program yet. Check back soon!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.action,
  });

  final String title;
  final bool isDark;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center,
                label: 'Workouts',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Progress',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
