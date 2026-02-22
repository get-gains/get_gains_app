import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../../workout/data/models/routine_model.dart';
import '../providers/coach_routine_provider.dart';
import 'add_exercise_sheet.dart';

/// Coach Routine Detail Screen
///
/// Displays a single routine with its full exercise prescription list.
/// Allows adding, updating, reordering, and removing exercises.
class CoachRoutineDetailScreen extends ConsumerStatefulWidget {
  const CoachRoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  ConsumerState<CoachRoutineDetailScreen> createState() =>
      _CoachRoutineDetailScreenState();
}

class _CoachRoutineDetailScreenState
    extends ConsumerState<CoachRoutineDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(routineDetailProvider(widget.routineId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineDetailProvider(widget.routineId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(state),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state is RoutineDetailLoaded)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Routine',
              onPressed: () => context.push(
                AppRoutes.coachEditRoutine.replaceFirst(
                  ':id',
                  widget.routineId,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, isDark),
      floatingActionButton: state is RoutineDetailLoaded
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExerciseSheet(state.routine),
              backgroundColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            )
          : null,
    );
  }

  Widget _buildTitle(RoutineDetailState state) {
    if (state is RoutineDetailLoaded) {
      return Text(state.routine.name);
    }
    return const Text('Routine');
  }

  Widget _buildBody(RoutineDetailState state, bool isDark) {
    return switch (state) {
      RoutineDetailInitial() || RoutineDetailLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      RoutineDetailError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(height: 12),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () => ref
                  .read(routineDetailProvider(widget.routineId).notifier)
                  .load(),
            ),
          ],
        ),
      ),
      RoutineDetailLoaded(:final routine) => _buildDetail(routine, isDark),
    };
  }

  Widget _buildDetail(RoutineModel routine, bool isDark) {
    final theme = Theme.of(context);
    final sortedExercises = [...routine.exercises]
      ..sort((a, b) => a.orderInRoutine.compareTo(b.orderInRoutine));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(routineDetailProvider(widget.routineId).notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Routine info
          if (routine.description.isNotEmpty) ...[
            Text(
              routine.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Stats
          Row(
            children: [
              AppBadge(
                label: '${routine.totalExercises} exercises',
                variant: AppBadgeVariant.primary,
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: '${routine.totalSets} total sets',
                variant: AppBadgeVariant.info,
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: '${routine.estimatedDurationMinutes} min',
                variant: AppBadgeVariant.secondary,
              ),
            ],
          ),

          // Muscle groups
          if (routine.muscleGroupsTargeted.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: routine.muscleGroupsTargeted
                  .map(
                    (mg) => AppBadge(
                      label: mg.displayName,
                      variant: AppBadgeVariant.secondary,
                      size: AppBadgeSize.sm,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),

          // Exercise list header
          Text('Exercises', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),

          if (sortedExercises.isEmpty)
            AppEmptyState.compact(
              icon: Icons.fitness_center,
              title: 'No Exercises',
              description:
                  'Tap "Add Exercise" to build this routine\'s exercise list.',
            )
          else
            ...sortedExercises.map(
              (re) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExerciseCard(
                  exercise: re,
                  isDark: isDark,
                  onRemove: () => _confirmRemoveExercise(re),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddExerciseSheet(RoutineModel routine) async {
    final result = await showAddExerciseSheet(
      context: context,
      routineId: widget.routineId,
      nextOrder: routine.exercises.length + 1,
    );
    if (result == true && mounted) {
      ref.read(routineDetailProvider(widget.routineId).notifier).load();
      // Also refresh routine list counts
      ref.read(coachRoutinesProvider.notifier).loadRoutines();
    }
  }

  Future<void> _confirmRemoveExercise(RoutineExerciseModel exercise) async {
    final exerciseName = exercise.exercise?.name ?? 'this exercise';
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Remove Exercise',
      message:
          'Remove "$exerciseName" from this routine? The exercise itself will remain in the library.',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.remove_circle_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(routineDetailProvider(widget.routineId).notifier)
          .removeExercise(exercise.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Exercise removed');
        } else {
          AppToast.error(context, 'Failed to remove exercise');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Exercise Prescription Card
// ──────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onRemove,
  });

  final RoutineExerciseModel exercise;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = exercise.exercise;

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.2)
                      : AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exercise.orderInRoutine}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex?.name ?? 'Exercise',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (ex != null)
                      Text(
                        ex.primaryMuscleGroup.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: isDark ? AppColors.error : AppColors.errorLight,
                tooltip: 'Remove exercise',
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Prescription details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface0Dark : AppColors.mutedLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PrescriptionStat(
                  label: 'Sets',
                  value: '${exercise.sets}',
                  isDark: isDark,
                ),
                _PrescriptionStat(
                  label: 'Reps',
                  value: '${exercise.repsMin}-${exercise.repsMax}',
                  isDark: isDark,
                ),
                _PrescriptionStat(
                  label: 'Rest',
                  value: '${exercise.restSeconds}s',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes,
                  size: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    exercise.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                      fontStyle: FontStyle.italic,
                    ),
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

class _PrescriptionStat extends StatelessWidget {
  const _PrescriptionStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
      ],
    );
  }
}
