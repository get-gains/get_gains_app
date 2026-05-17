import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/models.dart';

/// Exercise Tab Bar
///
/// Horizontal scrollable tab bar showing all exercises in a routine.
/// Indicates completion status for each exercise.
class ExerciseTabBar extends StatelessWidget {
  const ExerciseTabBar({
    super.key,
    required this.exercises,
    required this.currentIndex,
    required this.session,
    required this.onTap,
  });

  final List<RoutineExerciseModel> exercises;
  final int currentIndex;
  final WorkoutSessionModel session;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final completedSets = session.setsForExercise(exercise.id);
          final isCompleted = completedSets.length >= exercise.sets;
          final isActive = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ExerciseTab(
              index: index + 1,
              name: exercise.exercise?.name ?? 'Exercise ${index + 1}',
              isActive: isActive,
              isCompleted: isCompleted,
              completedSets: completedSets.length,
              totalSets: exercise.sets,
              onTap: () => onTap(index),
            ),
          );
        },
      ),
    );
  }
}

class _ExerciseTab extends StatelessWidget {
  const _ExerciseTab({
    required this.index,
    required this.name,
    required this.isActive,
    required this.isCompleted,
    required this.completedSets,
    required this.totalSets,
    required this.onTap,
  });

  final int index;
  final String name;
  final bool isActive;
  final bool isCompleted;
  final int completedSets;
  final int totalSets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isCompleted) {
      backgroundColor = AppColors.success.withValues(alpha: 0.2);
      textColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (isActive) {
      backgroundColor = primaryColor.withValues(alpha: 0.2);
      textColor = primaryColor;
      borderColor = primaryColor;
    } else {
      backgroundColor = Colors.transparent;
      textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted)
              Icon(Icons.check_circle, size: 18, color: textColor)
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: textColor),
                ),
                child: Center(
                  child: Text(
                    index.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              name.length > 12 ? '${name.substring(0, 12)}...' : name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              '$completedSets/$totalSets',
              style: AppTextStyles.numericBody.copyWith(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
