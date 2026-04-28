// lib/features/coach_programs/presentation/screens/coach_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';

/// Coach Hub Screen (M-CF1-2 / M-CF2-1)
///
/// Central hub for coach tools providing navigation to:
/// - Programs management
/// - Routines management
/// - Exercise library & form recording
/// - Client roster
/// - Coach settings
class CoachHubScreen extends ConsumerWidget {
  const CoachHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Coach Tools',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HubTile(
                    icon: Icons.people_outlined,
                    activeIcon: Icons.people,
                    title: 'Clients',
                    subtitle: 'Manage roster & training programs',
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    isDark: isDark,
                    onTap: () => context.push(AppRoutes.coachRoster),
                  ),
                  const SizedBox(height: 12),
                  _HubTile(
                    icon: Icons.insights_outlined,
                    activeIcon: Icons.insights,
                    title: 'Performance',
                    subtitle: 'Client progress & adherence dashboard',
                    color: const Color(0xFF20B2AA),
                    isDark: isDark,
                    onTap: () =>
                        context.push(AppRoutes.coachPerformanceDashboard),
                  ),
                  const SizedBox(height: 12),
                  _HubTile(
                    icon: Icons.fitness_center_outlined,
                    activeIcon: Icons.fitness_center,
                    title: 'Routines',
                    subtitle: 'Build reusable workout routines',
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                    onTap: () => context.push(AppRoutes.coachRoutines),
                  ),
                  const SizedBox(height: 12),
                  _HubTile(
                    icon: Icons.sports_gymnastics_outlined,
                    activeIcon: Icons.sports_gymnastics,
                    title: 'Exercises',
                    subtitle: 'Exercise library & form recording',
                    color: const Color(0xFFA855F7),
                    isDark: isDark,
                    onTap: () => context.push(AppRoutes.coachExercises),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single hub navigation tile.
class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
      ),
    );
  }
}
