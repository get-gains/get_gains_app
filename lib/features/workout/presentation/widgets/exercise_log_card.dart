import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/exercise_log_provider.dart';
import 'set_input_row.dart';

/// Exercise Log Card
///
/// Card for logging sets within a single exercise.
/// Shows exercise info, rep/weight inputs, and set history.
class ExerciseLogCard extends ConsumerStatefulWidget {
  const ExerciseLogCard({
    super.key,
    required this.routineExercise,
    required this.completedSets,
    required this.onSetCompleted,
  });

  final RoutineExerciseModel routineExercise;
  final List<PerformedSetModel> completedSets;
  final VoidCallback onSetCompleted;

  @override
  ConsumerState<ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends ConsumerState<ExerciseLogCard> {
  @override
  void initState() {
    super.initState();
    // Initialize the exercise log provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseLogProvider.notifier).initializeForExercise(
        widget.routineExercise,
        existingSets: widget.completedSets,
      );
    });
  }

  @override
  void didUpdateWidget(covariant ExerciseLogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routineExercise.id != widget.routineExercise.id) {
      ref.read(exerciseLogProvider.notifier).initializeForExercise(
        widget.routineExercise,
        existingSets: widget.completedSets,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseLogState = ref.watch(exerciseLogProvider);

    final exercise = widget.routineExercise.exercise;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          _ExerciseHeader(
            name: exercise?.name ?? 'Exercise',
            description: exercise?.description ?? '',
            muscleGroup: exercise?.primaryMuscleGroup,
          ),

          const SizedBox(height: 16),

          // Prescription info
          _PrescriptionInfo(
            sets: widget.routineExercise.sets,
            repsMin: widget.routineExercise.repsMin,
            repsMax: widget.routineExercise.repsMax,
            restSeconds: widget.routineExercise.restSeconds,
            notes: widget.routineExercise.notes,
          ),

          const SizedBox(height: 24),

          // Set logging area
          if (exerciseLogState != null) ...[
            // Progress indicator
            _SetProgressIndicator(
              completed: exerciseLogState.completedSetsCount,
              total: exerciseLogState.routineExercise.sets,
            ),

            const SizedBox(height: 16),

            // Set input rows
            ...List.generate(
              exerciseLogState.sets.length,
              (index) {
                final set = exerciseLogState.sets[index];
                return SetInputRow(
                  setNumber: set.setNumber,
                  reps: set.reps,
                  weight: set.weight,
                  rpe: set.rpe,
                  isCompleted: set.isCompleted,
                  isActive: index == exerciseLogState.currentSetIndex,
                  targetReps: '${widget.routineExercise.repsMin}-${widget.routineExercise.repsMax}',
                  onRepsChanged: (reps) {
                    ref.read(exerciseLogProvider.notifier).updateSet(
                      index,
                      reps: reps,
                    );
                  },
                  onWeightChanged: (weight) {
                    ref.read(exerciseLogProvider.notifier).updateSet(
                      index,
                      weight: weight,
                    );
                  },
                  onRpeChanged: (rpe) {
                    ref.read(exerciseLogProvider.notifier).updateSet(
                      index,
                      rpe: rpe,
                    );
                  },
                  onComplete: () async {
                    ref.read(exerciseLogProvider.notifier).selectSet(index);
                    await ref.read(exerciseLogProvider.notifier).completeCurrentSet();
                    widget.onSetCompleted();
                  },
                  onTap: () {
                    ref.read(exerciseLogProvider.notifier).selectSet(index);
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick complete button
            if (!exerciseLogState.isAllSetsCompleted)
              AppButton.primary(
                label: 'Complete Set ${exerciseLogState.currentSetIndex + 1}',
                icon: Icons.check,
                isFullWidth: true,
                isLoading: exerciseLogState.isSubmitting,
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(exerciseLogProvider.notifier).completeCurrentSet();
                  widget.onSetCompleted();
                },
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'All sets completed!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.name,
    required this.description,
    this.muscleGroup,
  });

  final String name;
  final String description;
  final MuscleGroup? muscleGroup;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (muscleGroup != null)
              AppBadge(
                label: muscleGroup!.displayName,
                variant: AppBadgeVariant.primary,
              ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
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
        ],
      ],
    );
  }
}

class _PrescriptionInfo extends StatelessWidget {
  const _PrescriptionInfo({
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.restSeconds,
    this.notes,
  });

  final int sets;
  final int repsMin;
  final int repsMax;
  final int restSeconds;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard.flat(
      backgroundColor: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.5)
          : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InfoChip(
                  icon: Icons.repeat,
                  label: '$sets sets',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.fitness_center,
                  label: '$repsMin-$repsMax reps',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '${restSeconds}s rest',
                ),
              ],
            ),
            if (notes != null && notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.notes,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _SetProgressIndicator extends StatelessWidget {
  const _SetProgressIndicator({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sets Progress',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '$completed / $total',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
    );
  }
}
