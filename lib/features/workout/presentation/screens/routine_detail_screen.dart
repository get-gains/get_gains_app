import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';
import '../providers/workout_session_provider.dart';

/// Routine Detail Screen
///
/// Shows the exercises inside a routine with options to:
/// - View coach's reference form for each exercise
/// - Compare form (record + compare against coach)
/// - Start the full workout session
class RoutineDetailScreen extends ConsumerStatefulWidget {
  const RoutineDetailScreen({super.key, required this.routineId, this.routine});

  final String routineId;
  final RoutineModel? routine;

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  late Future<RoutineModel?> _routineFuture;

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _routineFuture = Future.value(widget.routine);
    } else {
      _loadRoutine();
    }
  }

  void _loadRoutine() {
    final repo = ref.read(workoutRepositoryProvider);
    _routineFuture = repo
        .getRoutineByModelId(widget.routineId)
        .then((result) => result.valueOrNull);
  }

  Future<void> _startWorkout(RoutineModel routine) async {
    await ref
        .read(workoutSessionProvider.notifier)
        .startSession(routineModelId: routine.id);

    if (!mounted) return;

    final sessionState = ref.read(workoutSessionProvider);
    if (sessionState is WorkoutSessionActive && routine.exercises.isNotEmpty) {
      final firstExercise = routine.exercises.first;
      context.go(
        '/client/exercise/${firstExercise.exerciseId}/unity-record',
        extra: {
          'workoutSessionId': sessionState.session.id,
          'routineExerciseId': firstExercise.id,
          'routineExercises': routine.exercises,
          'currentExerciseIndex': 0,
          'currentSetNumber': 1,
        },
      );
    } else {
      // Fallback if no exercises or session failed
      context.go(AppRoutes.workoutSession);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: FutureBuilder<RoutineModel?>(
        future: _routineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final routine = snapshot.data;
          if (routine == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Routine')),
              body: AppEmptyState(
                icon: Icons.error_outline,
                title: 'Routine Not Found',
                description: 'This routine could not be loaded.',
                actionLabel: 'Go Back',
                onAction: () => context.pop(),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    routine.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                          isDark
                              ? AppColors.primaryDark.withValues(alpha: 0.7)
                              : AppColors.primaryLight.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Routine Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (routine.description.isNotEmpty) ...[
                        Text(
                          routine.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.fitness_center,
                            label: '${routine.totalExercises} exercises',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.repeat,
                            label: '${routine.totalSets} sets',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.timer_outlined,
                            label: '${routine.estimatedDurationMinutes} min',
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Muscle groups
                      if (routine.muscleGroupsTargeted.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: routine.muscleGroupsTargeted
                              .map(
                                (m) => AppBadge(
                                  label: m.displayName,
                                  variant: AppBadgeVariant.outline,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Section header
                      Text(
                        'Exercises',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Exercise List
              if (routine.exercises.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.fitness_center,
                    title: 'No Exercises',
                    description: 'This routine has no exercises yet.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final exercise = routine.exercises[index];
                      return _ExerciseCard(
                        routineExercise: exercise,
                        index: index,
                        onViewForm: () => _navigateToViewForm(exercise),
                      );
                    }, childCount: routine.exercises.length),
                  ),
                ),

              // Bottom padding + start button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppButton.primary(
                    label: 'Start Workout',
                    icon: Icons.play_arrow,
                    isFullWidth: true,
                    onPressed: () => _startWorkout(routine),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  void _navigateToViewForm(RoutineExerciseModel routineExercise) {
    final exerciseId =
        routineExercise.exercise?.id ?? routineExercise.exerciseId;
    context.push('/client/exercise/$exerciseId/view-form');
  }
}

/// Stat chip widget
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
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

/// Exercise card inside routine detail
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.routineExercise,
    required this.index,
    required this.onViewForm,
  });

  final RoutineExerciseModel routineExercise;
  final int index;
  final VoidCallback onViewForm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exercise = routineExercise.exercise;
    final exerciseName = exercise?.name ?? 'Exercise ${index + 1}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.elevated(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise header
              Row(
                children: [
                  // Order number
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
                        '${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Exercise name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${routineExercise.sets} sets x '
                          '${routineExercise.repsMin}-${routineExercise.repsMax} reps'
                          '${routineExercise.restSeconds > 0 ? ' • ${routineExercise.restSeconds}s rest' : ''}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Muscle group badge
                  if (exercise != null)
                    AppBadge(
                      label: exercise.primaryMuscleGroup.displayName,
                      variant: AppBadgeVariant.outline,
                    ),
                ],
              ),

              // Notes
              if (routineExercise.notes != null &&
                  routineExercise.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  routineExercise.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: 'View Form',
                      icon: Icons.visibility,
                      onPressed: onViewForm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
