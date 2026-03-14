import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../client_pose/data/client_pose_repository.dart';
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

  Future<void> _startWorkout(RoutineModel routine, {int startIndex = 0}) async {
    await ref
        .read(workoutSessionProvider.notifier)
        .startSession(routineModelId: routine.id);

    if (!mounted) return;

    final sessionState = ref.read(workoutSessionProvider);
    if (sessionState is WorkoutSessionActive && routine.exercises.isNotEmpty) {
      final safeStartIndex =
          startIndex.clamp(0, routine.exercises.length - 1) as int;

      // Pre-cache reference forms for all exercises so they're available
      // offline if connectivity drops during the workout.
      final exerciseIds = routine.exercises.map((e) => e.exerciseId).toList();
      ref.read(clientPoseRepositoryProvider).preCacheExerciseForms(exerciseIds);

      final firstExercise = routine.exercises[safeStartIndex];
      context.go(
        '/client/exercise/${firstExercise.exerciseId}/unity-record',
        extra: {
          'workoutSessionId': sessionState.session.id,
          'routineExerciseId': firstExercise.id,
          'routineExercises': routine.exercises,
          'currentExerciseIndex': safeStartIndex,
          'currentSetNumber': 1,
        },
      );
    } else {
      // Fallback if no exercises or session failed
      context.go(AppRoutes.workoutSession);
    }
  }

  Future<void> _pickStartExerciseAndWorkout(RoutineModel routine) async {
    if (routine.exercises.isEmpty) {
      await _startWorkout(routine);
      return;
    }

    if (routine.exercises.length == 1) {
      await _startWorkout(routine, startIndex: 0);
      return;
    }

    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Start From Exercise',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: routine.exercises.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final routineExercise = routine.exercises[index];
                      final exerciseName =
                          routineExercise.exercise?.name ??
                          'Exercise ${index + 1}';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isDark
                              ? AppColors.primaryDark.withValues(alpha: 0.2)
                              : AppColors.primaryLight.withValues(alpha: 0.12),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(exerciseName),
                        subtitle: Text(
                          '${routineExercise.sets} sets x ${routineExercise.repsMin}-${routineExercise.repsMax} reps',
                        ),
                        onTap: () => Navigator.of(context).pop(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedIndex == null) return;
    await _startWorkout(routine, startIndex: selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<RoutineModel?>(
      future: _routineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            body: const Center(child: CircularProgressIndicator()),
          );
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

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _StartWorkoutButton(
                routine: routine,
                onStart: () => _pickStartExerciseAndWorkout(routine),
              ),
            ),
          ),
          body: CustomScrollView(
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
                  sliver: _ExerciseListSliver(
                    routine: routine,
                    onExerciseTap: (index) =>
                        _startWorkout(routine, startIndex: index),
                  ),
                ),

              // Bottom spacing to account for persistent bottom bar
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }
}

/// Extracted sliver that watches both active session and today's history.
class _ExerciseListSliver extends ConsumerWidget {
  const _ExerciseListSliver({required this.routine, this.onExerciseTap});

  final RoutineModel routine;
  final void Function(int index)? onExerciseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(workoutSessionProvider);
    final todaySession = ref.watch(todayCompletedSessionProvider(routine.id));

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final exercise = routine.exercises[index];
        int completedSets = 0;

        if (sessionState is WorkoutSessionActive) {
          // Active workout — use live data
          completedSets = sessionState.session
              .setsForExercise(exercise.id)
              .length;
        } else if (sessionState is WorkoutSessionCompleted &&
            sessionState.routine?.id == routine.id &&
            sessionState.session.performedSets.isNotEmpty) {
          // Just finished — use the completed session data
          completedSets = sessionState.session
              .setsForExercise(exercise.id)
              .length;
        } else {
          // No active session — check today's history
          final history = todaySession.value;
          if (history != null) {
            completedSets = history.setsForExercise(exercise.id).length;
          }
        }

        return _ExerciseCard(
          routineExercise: exercise,
          index: index,
          completedSets: completedSets,
          onTap: onExerciseTap,
        );
      }, childCount: routine.exercises.length),
    );
  }
}

/// Button that shows "Workout Done Today" or "Start Workout" based on history.
class _StartWorkoutButton extends ConsumerWidget {
  const _StartWorkoutButton({required this.routine, required this.onStart});

  final RoutineModel routine;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(workoutSessionProvider);
    final todaySession = ref.watch(todayCompletedSessionProvider(routine.id));

    final bool isCompletedToday =
        (sessionState is WorkoutSessionCompleted &&
            sessionState.routine?.id == routine.id) ||
        (todaySession.value?.isCompleted ?? false);

    if (isCompletedToday) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Workout Done Today',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppButton.outline(
            label: 'Do Again',
            icon: Icons.replay,
            isFullWidth: true,
            onPressed: onStart,
          ),
        ],
      );
    }

    return AppButton.primary(
      label: 'Start Workout',
      icon: Icons.play_arrow,
      isFullWidth: true,
      onPressed: onStart,
    );
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
    this.completedSets = 0,
    this.onTap,
  });

  final RoutineExerciseModel routineExercise;
  final int index;
  final int completedSets;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exercise = routineExercise.exercise;
    final exerciseName = exercise?.name ?? 'Exercise ${index + 1}';
    final isExerciseComplete = completedSets >= routineExercise.sets;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.elevated(
        onTap: onTap == null ? null : () => onTap!(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise header
              Row(
                children: [
                  // Order number / completion indicator
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isExerciseComplete
                          ? AppColors.success.withValues(alpha: 0.2)
                          : isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.2)
                          : AppColors.primaryLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isExerciseComplete
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.success,
                            )
                          : Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
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
                  // Muscle group badge + set progress
                  if (completedSets > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$completedSets/${routineExercise.sets}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExerciseComplete
                              ? AppColors.success
                              : isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

              // Analyze Form action
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.clientViewForm.replaceFirst(
                        ':id',
                        routineExercise.exerciseId,
                      ),
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('Analyze Form'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
