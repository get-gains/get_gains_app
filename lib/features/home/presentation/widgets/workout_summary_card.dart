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
    this.muscleGroups = const [],
    this.onStartPressed,
  });

  final String routineName;
  final String description;
  final int exerciseCount;
  final int estimatedMinutes;
  final bool isPlaceholder;
  final List<String> muscleGroups;
  final VoidCallback? onStartPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    color:
                        (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPlaceholder
                        ? Icons.hourglass_empty
                        : Icons.fitness_center,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routineName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isPlaceholder
                  ? AppButton.secondary(
                      label: 'View Routines',
                      icon: Icons.arrow_forward,
                      onPressed: onStartPressed,
                    )
                  : AppButton.primary(
                      label: 'Start Workout',
                      icon: Icons.play_arrow,
                      onPressed: onStartPressed,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
