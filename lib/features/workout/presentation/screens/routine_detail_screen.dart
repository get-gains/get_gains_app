import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../client_pose/data/client_pose_repository.dart';
import '../../../guidance/guidance.dart';
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

  // Guidance tour GlobalKeys
  final _exerciseCardKey = GlobalKey(
    debugLabel: 'routine_detail_exercise_card',
  );
  final _analyzeFormKey = GlobalKey(debugLabel: 'routine_detail_analyze_form');
  final _prescriptionKey = GlobalKey(debugLabel: 'routine_detail_prescription');
  final _startWorkoutKey = GlobalKey(
    debugLabel: 'routine_detail_start_workout',
  );
  bool _tourTriggered = false;

  @override
  void initState() {
    super.initState();
    // Only short-circuit if the passed routine already has exercises populated.
    // The today endpoint returns a skeleton RoutineModel with exercises: [] so
    // we must still fetch from the local cache in that case.
    if (widget.routine != null && widget.routine!.exercises.isNotEmpty) {
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
        .startSession(routineModelId: routine.id, routine: routine);

    if (!mounted) return;

    final sessionState = ref.read(workoutSessionProvider);
    if (sessionState is WorkoutSessionActive && routine.exercises.isNotEmpty) {
      // When resuming, use the provider's calculated exercise index
      // (which accounts for already-completed exercises).
      final isResuming = sessionState.session.performedSets.isNotEmpty;
      final resolvedStartIndex = isResuming
          ? sessionState.currentExerciseIndex.clamp(
              0,
              routine.exercises.length - 1,
            )
          : startIndex.clamp(0, routine.exercises.length - 1);

      // Pre-cache reference forms for all exercises so they're available
      // offline if connectivity drops during the workout.
      final exerciseIds = routine.exercises.map((e) => e.exerciseId).toList();
      ref.read(clientPoseRepositoryProvider).preCacheExerciseForms(exerciseIds);

      final targetExercise = routine.exercises[resolvedStartIndex];
      final completedSets = sessionState.session
          .setsForExercise(targetExercise.id)
          .length;
      final nextSetNumber = completedSets + 1;

      // If all exercises are completed, go to the session screen instead
      // of back to recording.
      if (sessionState.isAllExercisesCompleted) {
        context.go(AppRoutes.workoutSession, extra: {'readOnly': true});
        return;
      }

      context.go(
        '/client/exercise/${targetExercise.exerciseId}/unity-record',
        extra: {
          'workoutSessionId': sessionState.session.id,
          'routineExerciseId': targetExercise.id,
          'routineExercises': routine.exercises,
          'currentExerciseIndex': resolvedStartIndex,
          'currentSetNumber': nextSetNumber,
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
      backgroundColor: AppColors.surface2Dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? AppColors.surface2Dark : AppColors.surfaceLight;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start From Exercise',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foregroundLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick the exercise you want to start with',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Exercise list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: routine.exercises.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final routineExercise = routine.exercises[index];
                      final exerciseName =
                          routineExercise.exercise?.name ??
                          'Exercise ${index + 1}';
                      final prescription =
                          '${routineExercise.sets} × '
                          '${routineExercise.repsMin}–${routineExercise.repsMax} reps'
                          '${routineExercise.restSeconds > 0 ? ' · ${routineExercise.restSeconds}s rest' : ''}';

                      return AppCard.flat(
                        onTap: () => Navigator.of(context).pop(index),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Numbered tile
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTextStyles.numericBody.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name + prescription
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exerciseName,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.foregroundDark
                                            : AppColors.foregroundLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      prescription,
                                      style: AppTextStyles.numericBody.copyWith(
                                        color: isDark
                                            ? AppColors.mutedForegroundDark
                                            : AppColors.mutedForegroundLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ],
                          ),
                        ),
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

        // Trigger guidance tour on first visit with exercises
        if (!_tourTriggered && routine.exercises.isNotEmpty) {
          _tourTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final repo = ref.read(guidanceRepositoryProvider);
            if (!repo.isCompleted(GuidanceRepository.kRoutineDetail)) {
              ref
                  .read(tourProvider.notifier)
                  .startTour(
                    GuidanceRepository.kRoutineDetail,
                    kRoutineDetailTourSteps,
                  );
            }
          });
        }

        final sessionState = ref.watch(workoutSessionProvider);
        final todaySession = ref.watch(
          todayCompletedSessionProvider(routine.id),
        );
        final bool isCompletedToday =
            (sessionState is WorkoutSessionCompleted &&
                sessionState.routine?.id == routine.id) ||
            (todaySession.value?.isCompleted ?? false);

        return TourOrchestrator(
          tourKeys: {
            'routine_detail_exercise_card': _exerciseCardKey,
            'routine_detail_analyze_form': _analyzeFormKey,
            'routine_detail_prescription': _prescriptionKey,
            'routine_detail_start_workout': _startWorkoutKey,
          },
          child: Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AppCard.flat(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompletedToday) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Workout Complete',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        _StartWorkoutButton(
                          key: _startWorkoutKey,
                          routine: routine,
                          onStart: () => _pickStartExerciseAndWorkout(routine),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: CustomScrollView(
              slivers: [
                // App Bar — vibrant gradient hero
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  actions: [
                    InfoIconButton(
                      content: kRoutineDetailHelp,
                      onTapOverride: () {
                        ref
                            .read(tourProvider.notifier)
                            .startTour(
                              GuidanceRepository.kRoutineDetail,
                              kRoutineDetailTourSteps,
                            );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _RoutineHeroHeader(
                      routine: routine,
                      isDark: isDark,
                    ),
                  ),
                ),

                // Routine Info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                          const SizedBox(height: 16),
                        ],

                        // Section header
                        Text(
                          'Exercises',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
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
                      exerciseCardKey: _exerciseCardKey,
                      analyzeFormKey: _analyzeFormKey,
                      prescriptionKey: _prescriptionKey,
                    ),
                  ),

                // Bottom spacing to account for persistent bottom bar
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Extracted sliver that watches both active session and today's history.
class _ExerciseListSliver extends ConsumerWidget {
  const _ExerciseListSliver({
    required this.routine,
    this.exerciseCardKey,
    this.analyzeFormKey,
    this.prescriptionKey,
  });

  final RoutineModel routine;
  final GlobalKey? exerciseCardKey;
  final GlobalKey? analyzeFormKey;
  final GlobalKey? prescriptionKey;

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
          exerciseCardKey: index == 0 ? exerciseCardKey : null,
          analyzeFormKey: index == 0 ? analyzeFormKey : null,
          prescriptionKey: index == 0 ? prescriptionKey : null,
        );
      }, childCount: routine.exercises.length),
    );
  }
}

/// Primary routine action button based on today's completion state.
class _StartWorkoutButton extends ConsumerWidget {
  const _StartWorkoutButton({
    super.key,
    required this.routine,
    required this.onStart,
  });

  final RoutineModel routine;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(workoutSessionProvider);
    final todaySession = ref.watch(todayCompletedSessionProvider(routine.id));

    // Check if there's an active (in-progress) session for this routine
    final bool hasActiveSession =
        sessionState is WorkoutSessionActive &&
        sessionState.routine?.id == routine.id;

    final bool isCompletedToday =
        (sessionState is WorkoutSessionCompleted &&
            sessionState.routine?.id == routine.id) ||
        (todaySession.value?.isCompleted ?? false);

    if (hasActiveSession) {
      final setsLogged =
          (sessionState as WorkoutSessionActive).session.performedSets.length;
      return AppButton.primary(
        label: 'Resume Workout ($setsLogged sets logged)',
        icon: Icons.play_arrow,
        isFullWidth: true,
        onPressed: onStart,
      );
    }

    if (isCompletedToday) {
      return AppButton.secondary(
        label: 'Routine Done',
        icon: Icons.check_circle_outline,
        isFullWidth: true,
        onPressed: null,
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

/// Stat chip widget (used in _RoutineHeroHeader).
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

/// Exercise card inside routine detail — block-based dark/vibrant design.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.routineExercise,
    required this.index,
    this.completedSets = 0,
    this.onTap,
    this.exerciseCardKey,
    this.analyzeFormKey,
    this.prescriptionKey,
  });

  final RoutineExerciseModel routineExercise;
  final int index;
  final int completedSets;
  final void Function(int index)? onTap;
  final GlobalKey? exerciseCardKey;
  final GlobalKey? analyzeFormKey;
  final GlobalKey? prescriptionKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exercise = routineExercise.exercise;
    final exerciseName = exercise?.name ?? 'Exercise ${index + 1}';
    final isExerciseComplete = completedSets >= routineExercise.sets;

    // Mono prescription line: "3 × 8–12 reps · 90s rest"
    final prescription =
        '${routineExercise.sets} × '
        '${routineExercise.repsMin}–${routineExercise.repsMax} reps'
        '${routineExercise.restSeconds > 0 ? ' · ${routineExercise.restSeconds}s rest' : ''}';

    return Padding(
      key: exerciseCardKey,
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.elevated(
        onTap: onTap == null ? null : () => onTap!(index),
        child: Container(
          decoration: isExerciseComplete
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise header row
                Row(
                  children: [
                    // 40×40 numbered tile — success tint when complete
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isExerciseComplete
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.primaryDark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: isExerciseComplete
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: AppColors.success,
                              )
                            : Text(
                                '${index + 1}',
                                style: AppTextStyles.numericBody.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Exercise name + prescription
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            key: prescriptionKey,
                            prescription,
                            style: AppTextStyles.numericBody.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Muscle-group badge
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Divider + action row
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Completed sets pill (left)
                    if (completedSets > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isExerciseComplete
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.primaryDark.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExerciseComplete
                                ? AppColors.success.withValues(alpha: 0.4)
                                : AppColors.primaryDark.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$completedSets/${routineExercise.sets} sets',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isExerciseComplete
                                ? AppColors.success
                                : AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Analyze Form ghost button (right)
                    AppButton.ghost(
                      key: analyzeFormKey,
                      label: 'Analyze Form',
                      icon: Icons.analytics_outlined,
                      onPressed: () => context.push(
                        AppRoutes.clientViewForm.replaceFirst(
                          ':id',
                          routineExercise.exerciseId,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vibrant gradient hero header for the Routine Detail SliverAppBar.
///
/// Shows: routine name, program context chip, stats strip (exercises/sets/min)
/// in JetBrains Mono, and muscle-group badges.
class _RoutineHeroHeader extends StatelessWidget {
  const _RoutineHeroHeader({
    required this.routine,
    required this.isDark,
  });

  final RoutineModel routine;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Vibrant gradient: primaryDark → slightly darker shade
    const gradientStart = AppColors.primaryDark;
    const gradientEnd = Color(0xFFC46524); // ~20% darker than E07D3B

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Routine name
              Text(
                routine.name,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Stats strip — three vibrant metric tiles
              Row(
                children: [
                  _HeroStatTile(
                    value: '${routine.totalExercises}',
                    label: 'Exercises',
                  ),
                  const SizedBox(width: 8),
                  _HeroStatTile(
                    value: '${routine.totalSets}',
                    label: 'Sets',
                  ),
                  const SizedBox(width: 8),
                  _HeroStatTile(
                    value: '~${routine.estimatedDurationMinutes}',
                    label: 'Min',
                  ),
                ],
              ),

              // Muscle-group badges
              if (routine.muscleGroupsTargeted.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small vibrant stat tile used in [_RoutineHeroHeader].
class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.numericBody.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
