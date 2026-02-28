import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../../workout/data/models/routine_model.dart';
import '../providers/standalone_routine_provider.dart';
import 'standalone_add_exercise_sheet.dart';

/// Standalone Routine Detail Screen
///
/// Displays a routine's exercises with sets/reps. Allows editing
/// the routine, adding/removing exercises.
class StandaloneRoutineDetailScreen extends ConsumerStatefulWidget {
  const StandaloneRoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  ConsumerState<StandaloneRoutineDetailScreen> createState() =>
      _StandaloneRoutineDetailScreenState();
}

class _StandaloneRoutineDetailScreenState
    extends ConsumerState<StandaloneRoutineDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(standaloneRoutineDetailProvider(widget.routineId).notifier)
          .load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standaloneRoutineDetailProvider(widget.routineId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(state),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state is StandaloneRoutineDetailLoaded)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Routine',
              onPressed: () => context.push(
                AppRoutes.standaloneEditRoutine.replaceFirst(
                  ':id',
                  widget.routineId,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, isDark),
      floatingActionButton: state is StandaloneRoutineDetailLoaded
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExerciseSheet(),
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

  Widget _buildTitle(StandaloneRoutineDetailState state) {
    if (state is StandaloneRoutineDetailLoaded) {
      return Text(state.routine.name);
    }
    return const Text('Routine');
  }

  Widget _buildBody(StandaloneRoutineDetailState state, bool isDark) {
    return switch (state) {
      StandaloneRoutineDetailInitial() || StandaloneRoutineDetailLoading() =>
        const Center(child: CircularProgressIndicator()),
      StandaloneRoutineDetailError(:final error) => Center(
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
                  .read(
                    standaloneRoutineDetailProvider(widget.routineId).notifier,
                  )
                  .load(),
            ),
          ],
        ),
      ),
      StandaloneRoutineDetailLoaded(:final routine) => _buildDetail(
        routine,
        isDark,
      ),
    };
  }

  Widget _buildDetail(RoutineModel routine, bool isDark) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(standaloneRoutineDetailProvider(widget.routineId).notifier)
          .load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Routine info header
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

          // Stats row
          Row(
            children: [
              AppBadge(
                label: '${routine.exercises.length} exercises',
                variant: AppBadgeVariant.primary,
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: '${routine.estimatedDurationMinutes} min',
                variant: AppBadgeVariant.info,
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: '${routine.totalSets} sets',
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
              children: routine.muscleGroupsTargeted.map((mg) {
                return AppBadge(
                  label: mg.name,
                  variant: AppBadgeVariant.secondary,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // Exercise list
          if (routine.exercises.isEmpty)
            AppEmptyState.compact(
              icon: Icons.fitness_center_outlined,
              title: 'No Exercises',
              description: 'Tap "Add Exercise" to build this routine.',
            )
          else
            ...routine.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final re = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoutineExerciseCard(
                  index: index + 1,
                  routineExercise: re,
                  isDark: isDark,
                  onRemove: () => _confirmRemoveExercise(re),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAddExerciseSheet() async {
    final result = await showStandaloneAddExerciseSheet(
      context: context,
      routineId: widget.routineId,
    );
    if (result == true && mounted) {
      ref
          .read(standaloneRoutineDetailProvider(widget.routineId).notifier)
          .load();
    }
  }

  Future<void> _confirmRemoveExercise(RoutineExerciseModel re) async {
    final exerciseName = re.exercise?.name ?? 'Exercise';
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Remove Exercise',
      message: 'Remove "$exerciseName" from this routine?',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.remove_circle_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(standaloneRoutineDetailProvider(widget.routineId).notifier)
          .removeExercise(re.id);
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
// Routine Exercise Card
// ──────────────────────────────────────────────────────────

class _RoutineExerciseCard extends StatelessWidget {
  const _RoutineExerciseCard({
    required this.index,
    required this.routineExercise,
    required this.isDark,
    required this.onRemove,
  });

  final int index;
  final RoutineExerciseModel routineExercise;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exerciseName = routineExercise.exercise?.name ?? 'Exercise';

    return AppCard.elevated(
      child: Row(
        children: [
          // Index badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                  : AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${routineExercise.sets} sets × '
                  '${routineExercise.repsMin}-${routineExercise.repsMax} reps · '
                  '${routineExercise.restSeconds}s rest',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                if (routineExercise.notes != null &&
                    routineExercise.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    routineExercise.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
