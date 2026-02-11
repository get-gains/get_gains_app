import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../workout/data/models/exercise_model.dart';

/// A card displaying exercise summary for the exercise list.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.trailing,
  });

  final ExerciseModel exercise;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface1Dark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Muscle group icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _muscleGroupIcon(exercise.primaryMuscleGroup),
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exercise.primaryMuscleGroup.displayName,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (exercise.equipmentNeeded.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.build_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                exercise.equipmentNeeded.join(', '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else
                  Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _muscleGroupIcon(MuscleGroup group) {
    return switch (group) {
      MuscleGroup.chest => Icons.fitness_center,
      MuscleGroup.shoulders => Icons.accessibility_new,
      MuscleGroup.biceps ||
      MuscleGroup.triceps ||
      MuscleGroup.forearms => Icons.front_hand,
      MuscleGroup.abs || MuscleGroup.obliques => Icons.rectangle_outlined,
      MuscleGroup.quads ||
      MuscleGroup.hamstrings ||
      MuscleGroup.calves ||
      MuscleGroup.glutes => Icons.directions_walk,
      MuscleGroup.upperBack ||
      MuscleGroup.lats ||
      MuscleGroup.lowerBack ||
      MuscleGroup.traps => Icons.airline_seat_flat,
    };
  }
}
