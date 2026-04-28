// lib/features/home/presentation/widgets/weekly_progress_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';

/// Card showing weekly workout progress
class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({
    super.key,
    required this.workoutsCompleted,
    required this.workoutsGoal,
    required this.totalMinutes,
    required this.streakDays,
    this.completedWeekdays,
  });

  final int workoutsCompleted;
  final int workoutsGoal;
  final int totalMinutes;
  final int streakDays;

  /// Local weekday indices (1=Mon … 7=Sun) that had a completed workout.
  /// When null, falls back to filling the first [workoutsCompleted] days.
  final Set<int>? completedWeekdays;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = workoutsGoal > 0 ? workoutsCompleted / workoutsGoal : 0.0;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Goal',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$workoutsCompleted / $workoutsGoal workouts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: isDark
                    ? AppColors.surface2Dark
                    : AppColors.surface2Light,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department,
                    value: '$streakDays',
                    label: 'Day Streak',
                    iconColor: Colors.orange,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer,
                    value: _formatMinutes(totalMinutes),
                    label: 'Total Time',
                    iconColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.fitness_center,
                    value: '$workoutsCompleted',
                    label: 'Workouts',
                    iconColor: isDark
                        ? AppColors.secondaryDark
                        : AppColors.secondaryLight,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Day indicators
            Row(
              children: List.generate(7, (index) {
                // index 0 = Monday … index 6 = Sunday
                // DateTime.weekday: 1=Mon … 7=Sun
                final weekday = index + 1;
                final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final isCompleted = completedWeekdays != null
                    ? completedWeekdays!.contains(weekday)
                    : index < workoutsCompleted;
                final isToday = weekday == DateTime.now().weekday;

                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _DayIndicator(
                      label: dayLabels[index],
                      isCompleted: isCompleted,
                      isToday: isToday,
                      isDark: isDark,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _DayIndicator extends StatelessWidget {
  const _DayIndicator({
    required this.label,
    required this.isCompleted,
    required this.isToday,
    required this.isDark,
  });

  final String label;
  final bool isCompleted;
  final bool isToday;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final backgroundColor = isCompleted
        ? primaryColor
        : (isDark ? AppColors.surface2Dark : AppColors.surface2Light);
    final textColor = isCompleted
        ? Colors.white
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday && !isCompleted
            ? Border.all(color: primaryColor, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
