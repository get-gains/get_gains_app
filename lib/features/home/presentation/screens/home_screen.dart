// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../services/api/api_client.dart';
import '../../../../widgets/widgets.dart';
import '../../../guidance/guidance.dart';
import '../../../profile/profile.dart';
import '../../../form_library/presentation/widgets/featured_forms_strip.dart';
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
      bool? parseBool(dynamic value) {
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final normalized = value.trim().toLowerCase();
          if (normalized == 'true' || normalized == '1') return true;
          if (normalized == 'false' || normalized == '0') return false;
        }
        return null;
      }

      final user = data['user'];
      if (user is! Map<String, dynamic>) return false;

      final topLevelIsCoach = parseBool(data['isCoach'] ?? data['is_coach']);
      if (topLevelIsCoach != null) return topLevelIsCoach;

      final nestedIsCoach = parseBool(user['isCoach'] ?? user['is_coach']);
      if (nestedIsCoach != null) return nestedIsCoach;

      return false;
    },
    failure: (_) => false,
  );
});

/// Main home screen — dark block-based dashboard.
///
/// Client layout: greeting → today hero → weekly pulse → recent activity → launch dock.
/// Coach layout: greeting → coach pulse → coach tools → my workout → launch dock.
/// Floating mission badges overlay the entire scroll via a [Stack].
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingShown = false;
  bool _tourTriggered = false;

  // Tour GlobalKeys — re-attached to new blocks per plan §6
  final _todaysFocusKey = GlobalKey(debugLabel: 'home_todays_focus');
  final _weeklyProgressKey = GlobalKey(debugLabel: 'home_weekly_progress');
  final _quickActionsKey = GlobalKey(debugLabel: 'home_quick_action_start');
  final _quickActionsHistoryKey = GlobalKey(
    debugLabel: 'home_quick_action_history',
  );
  final _recentActivityKey = GlobalKey(debugLabel: 'home_recent_activity');

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(needsOnboardingProvider, (previous, needsOnboarding) {
      if (needsOnboarding && !_onboardingShown) {
        _onboardingShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showOnboardingSheet(context);
        });
      }
      if (previous == true && !needsOnboarding) {
        _maybeStartTour();
      }
    });

    final needsOnboarding = ref.watch(needsOnboardingProvider);
    if (needsOnboarding && !_onboardingShown) {
      _onboardingShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showOnboardingSheet(context);
      });
    }

    if (!needsOnboarding && !_tourTriggered) {
      _maybeStartTour();
    }

    final isCoachAsync = ref.watch(isCoachProvider);
    final isCoach = isCoachAsync.asData?.value ?? false;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final topInset = mediaQuery.padding.top;
    const bottomNavHeight = 72.0;

    return TourOrchestrator(
      tourKeys: {
        'home_todays_focus': _todaysFocusKey,
        'home_weekly_progress': _weeklyProgressKey,
        'home_quick_action_start': _quickActionsKey,
        'home_quick_action_history': _quickActionsHistoryKey,
        'home_recent_activity': _recentActivityKey,
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  slivers: [
                    // Greeting bar replaces SliverAppBar
                    const SliverToBoxAdapter(
                      child: HomeGreetingBar(),
                    ),

                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Role-based hero block ──────────────────
                          if (isCoach) ...[
                            const CoachPulseBlock(),
                            const SizedBox(height: 16),
                            const CoachToolsBlock(),
                            const SizedBox(height: 16),
                            // Coach's own workout (collapsed today block)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "My Workout",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TodayHeroBlock(
                              todayKey: _todaysFocusKey,
                              isCoach: true,
                            ),
                          ] else ...[
                            TodayHeroBlock(
                              todayKey: _todaysFocusKey,
                              isCoach: false,
                            ),
                          ],

                          const SizedBox(height: 20),

                          // ── Weekly pulse ───────────────────────────
                          WeeklyPulseBlock(weeklyKey: _weeklyProgressKey),

                          const SizedBox(height: 20),

                          // ── Featured form library ──────────────
                          const FeaturedFormsStrip(),

                          const SizedBox(height: 20),

                          // ── Recent activity ────────────────────────
                          RecentActivityStrip(activityKey: _recentActivityKey),

                          const SizedBox(height: 24),

                          // ── Progress shortcut ──────────────────────
                          _ProgressShortcut(dockKey: _quickActionsHistoryKey),

                          const SizedBox(height: 24),

                          // ── Launch dock (demoted quick actions) ────
                          LaunchDock(
                            dockKey: _quickActionsKey,
                            isCoach: isCoach,
                          ),

                          // Bottom padding so content isn't behind nav bar
                          SizedBox(height: bottomNavHeight + 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Floating mission badges overlay ────────────────────
            FloatingMissionLayer(
              screenSize: screenSize,
              bottomNavHeight: bottomNavHeight,
              topInset: topInset,
            ),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                context.push(AppRoutes.myProgram);
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
      ),
    );
  }

  void _maybeStartTour() {
    if (_tourTriggered) return;
    _tourTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = ref.read(guidanceRepositoryProvider);
      if (!repo.isCompleted(GuidanceRepository.kHome)) {
        ref.read(tourProvider.notifier).startTour('home', kHomeTourSteps);
      }
    });
  }

  Future<void> _onRefresh() async {
    ref.invalidate(isCoachProvider);
    ref.invalidate(todayStatusProvider);
    ref.invalidate(activeTodayProvider);
    ref.invalidate(homeStatusProvider);
    ref.invalidate(unifiedWeeklyStatsProvider);
    ref.invalidate(recentActivityProvider);
    await Future.wait<void>([
      ref.read(homeStatusProvider.future).then((_) {}),
      ref.read(unifiedWeeklyStatsProvider.future).then((_) {}),
    ]);
  }
}

/// Tappable card that navigates to the progress screen.
class _ProgressShortcut extends StatelessWidget {
  const _ProgressShortcut({this.dockKey});

  final GlobalKey? dockKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    Widget card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard.interactive(
        onTap: () => context.push(AppRoutes.progress),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.trending_up_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Progress',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Track your strength gains over time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );

    if (dockKey != null) {
      card = KeyedSubtree(key: dockKey!, child: card);
    }

    return card;
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
                label: 'My Program',
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
