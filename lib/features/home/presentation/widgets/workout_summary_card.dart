// lib/features/home/presentation/widgets/workout_summary_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';

/// Card showing today's workout/routine summary
class WorkoutSummaryCard extends StatelessWidget {
  const WorkoutSummaryCard({
    super.key,
    required this.routineName,
    required this.description,
    required this.exerciseCount,
    required this.estimatedMinutes,
    this.isPlaceholder = false,
    this.completedToday = false,
    this.muscleGroups = const [],
    this.onStartPressed,
  });

  final String routineName;
  final String description;
  final int exerciseCount;
  final int estimatedMinutes;
  final bool isPlaceholder;
  final bool completedToday;
  final List<String> muscleGroups;
  final VoidCallback? onStartPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iconColor = completedToday
        ? AppColors.success
        : (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final iconBg = completedToday
        ? AppColors.success.withValues(alpha: 0.12)
        : iconColor.withValues(alpha: 0.1);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPlaceholder
                        ? Icons.hourglass_empty
                        : completedToday
                        ? Icons.check_circle_outline
                        : Icons.fitness_center,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              routineName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (completedToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Done',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!isPlaceholder) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$estimatedMinutes min',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.format_list_numbered,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$exerciseCount exercises',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (muscleGroups.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: muscleGroups
                    .map(
                      (muscle) => AppBadge(
                        label: muscle,
                        variant: AppBadgeVariant.secondary,
                        size: AppBadgeSize.sm,
                      ),
                    )
                    .toList(),
              ),
            ],
            // Only render a CTA when there's something actionable.
            if (!isPlaceholder && completedToday) ...[ 
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton.secondary(
                  label: 'Routine Done',
                  icon: Icons.check_circle_outline,
                  onPressed: null,
                ),
              ),
            ] else if (!isPlaceholder && onStartPressed != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: 'Start Workout',
                  icon: Icons.play_arrow,
                  onPressed: onStartPressed,
                ),
              ),
            ],
            // isPlaceholder with null onStartPressed → no button (rest day).
          ],
        ),
      ),
    );
  }
}
