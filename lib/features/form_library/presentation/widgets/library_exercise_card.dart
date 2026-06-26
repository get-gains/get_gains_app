import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../data/models/library_exercise_model.dart';

class LibraryExerciseCard extends ConsumerWidget {
  const LibraryExerciseCard({
    super.key,
    required this.exercise,
  });

  final LibraryExerciseModel exercise;

  IconData _muscleGroupIcon(String muscle) {
    final upper = muscle.toUpperCase();
    switch (upper) {
      case 'CHEST':
        return Icons.fitness_center;
      case 'BACK':
      case 'LATS':
      case 'UPPER_BACK':
      case 'LOWER_BACK':
        return Icons.accessibility_new;
      case 'SHOULDERS':
        return Icons.arrow_upward;
      case 'BICEPS':
      case 'TRICEPS':
      case 'FOREARMS':
      case 'ARMS':
        return Icons.front_hand;
      case 'QUADS':
      case 'HAMSTRINGS':
      case 'CALVES':
      case 'GLUTES':
      case 'LEGS':
        return Icons.directions_walk;
      case 'ABS':
      case 'OBLIQUES':
      case 'CORE':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.clientViewForm.replaceAll(':id', exercise.id),
          extra: {'fromLibrary': true},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon header with gradient background
            Container(
              height: 96,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.3),
                    primary.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  exercise.targetMuscles.isNotEmpty
                      ? _muscleGroupIcon(exercise.targetMuscles.first)
                      : Icons.fitness_center,
                  size: 40,
                  color: primary,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (exercise.coachName.isNotEmpty)
                    Text(
                      exercise.coachName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (exercise.targetMuscles.isNotEmpty)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exercise.targetMuscles.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
