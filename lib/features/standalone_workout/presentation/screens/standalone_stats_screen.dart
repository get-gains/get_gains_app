import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../providers/standalone_stats_provider.dart';

class StandaloneStatsScreen extends ConsumerWidget {
  const StandaloneStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(standaloneStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Progress',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to session history
            },
            tooltip: 'History',
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          description: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(standaloneStatsProvider),
        ),
        data: (stats) {
          if (stats.totalWorkouts == 0) {
            return AppEmptyState(
              icon: Icons.fitness_center,
              title: 'No Workouts Yet',
              description:
                  'Complete your first workout to see your progress here.',
            );
          }

          final primaryColor =
              isDark ? AppColors.primaryDark : AppColors.primaryLight;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Streak card
              _StatsBanner(
                icon: Icons.local_fire_department,
                value: '${stats.streakDays}',
                label: 'Day Streak',
                color: AppColors.primaryDark,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fitness_center,
                      value: '${stats.workoutsThisWeek}',
                      label: 'This Week',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.repeat,
                      value: '${stats.totalSets}',
                      label: 'Total Sets',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer,
                      value: '${stats.totalDurationMinutes}',
                      label: 'Minutes',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.done_all,
                      value: '${stats.totalWorkouts}',
                      label: 'All Time',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Share section
              Text(
                'Share Your Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: AppTextStyles.fontFamilySans,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              AppCard.elevated(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show off your gains',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Share workout stats with friends',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamilyMono,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamilySans,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilyMono,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
