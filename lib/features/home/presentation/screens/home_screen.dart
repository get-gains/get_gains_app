// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../subscription/subscription.dart';
import '../widgets/widgets.dart';

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
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Extract name from email or use default
    final email = authState.email ?? '';
    final userName = email.isNotEmpty ? email.split('@').first : 'Athlete';
    final greeting = _getGreeting();

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
                    // Quick Actions Section
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
                            onTap: () {
                              // TODO: Navigate to workout history
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Coach Tools Quick Action
                    QuickActionCard(
                      icon: Icons.sports,
                      title: 'Coach Tools',
                      subtitle: 'Exercise library & form recording',
                      gradient: LinearGradient(
                        colors: [
                          isDark
                              ? AppColors.accentDark
                              : const Color(0xFF22C55E),
                          isDark
                              ? AppColors.accentDark.withValues(alpha: 0.7)
                              : const Color(0xFF22C55E).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => context.push(AppRoutes.coachExercises),
                    ),

                    const SizedBox(height: 24),

                    // Today's Focus Section
                    _SectionHeader(
                      title: 'Today\'s Focus',
                      isDark: isDark,
                      action: TextButton(
                        onPressed: () => context.push(AppRoutes.routines),
                        child: const Text('See All'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    WorkoutSummaryCard(
                      routineName: 'No Routine Assigned',
                      description:
                          'Your coach will assign your workout routines. Check back soon!',
                      exerciseCount: 0,
                      estimatedMinutes: 0,
                      isPlaceholder: true,
                      onStartPressed: () => context.push(AppRoutes.routines),
                    ),

                    const SizedBox(height: 24),

                    // Weekly Progress Section
                    _SectionHeader(title: 'This Week', isDark: isDark),
                    const SizedBox(height: 12),
                    const WeeklyProgressCard(
                      workoutsCompleted: 0,
                      workoutsGoal: 4,
                      totalMinutes: 0,
                      streakDays: 0,
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity Section
                    _SectionHeader(title: 'Recent Activity', isDark: isDark),
                    const SizedBox(height: 12),
                    AppEmptyState.compact(
                      icon: Icons.history,
                      title: 'No Recent Workouts',
                      description: 'Your completed workouts will appear here.',
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
              // TODO: Progress/Stats screen
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
    // TODO: Refresh data from server
    await Future.delayed(const Duration(seconds: 1));
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
