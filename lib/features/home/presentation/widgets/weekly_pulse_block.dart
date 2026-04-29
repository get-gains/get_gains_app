// lib/features/home/presentation/widgets/weekly_pulse_block.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../providers/home_providers.dart';

/// Compact 2-column block: streak (left) + weekly volume/sessions (right).
///
/// @param weeklyKey [GlobalKey] forwarded for tour anchoring.
class WeeklyPulseBlock extends ConsumerWidget {
  const WeeklyPulseBlock({super.key, this.weeklyKey});

  final GlobalKey? weeklyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyAsync = ref.watch(unifiedWeeklyStatsProvider);
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    Widget content = weeklyAsync.when(
      data: (stats) => _PulseRow(
        streak: stats.streakDays,
        totalMinutes: stats.totalMinutes,
        workoutsCompleted: stats.workoutsCompleted,
        workoutsGoal: 4,
        primary: primary,
        secondaryText: secondaryText,
        isDark: isDark,
      ),
      loading: () => _PulseRow(
        streak: 0,
        totalMinutes: 0,
        workoutsCompleted: 0,
        workoutsGoal: 4,
        primary: primary,
        secondaryText: secondaryText,
        isDark: isDark,
      ),
      error: (_, __) => _PulseRow(
        streak: 0,
        totalMinutes: 0,
        workoutsCompleted: 0,
        workoutsGoal: 4,
        primary: primary,
        secondaryText: secondaryText,
        isDark: isDark,
      ),
    );

    if (weeklyKey != null) {
      content = KeyedSubtree(key: weeklyKey, child: content);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({
    required this.streak,
    required this.totalMinutes,
    required this.workoutsCompleted,
    required this.workoutsGoal,
    required this.primary,
    required this.secondaryText,
    required this.isDark,
  });

  final int streak;
  final int totalMinutes;
  final int workoutsCompleted;
  final int workoutsGoal;
  final Color primary;
  final Color secondaryText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress =
        workoutsGoal > 0 ? (workoutsCompleted / workoutsGoal).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        // Streak card
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Streak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$streak',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Weekly sessions card
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: primary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'This Week',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$workoutsCompleted / $workoutsGoal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.surface3Dark
                        : AppColors.surface3Light,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMinutes(totalMinutes),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m total';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h total' : '${h}h ${m}m total';
  }
}
