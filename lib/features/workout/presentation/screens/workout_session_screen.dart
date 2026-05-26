import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../guidance/guidance.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/models/models.dart';
import '../providers/exercise_log_provider.dart';
import '../providers/workout_session_provider.dart';
import '../widgets/widgets.dart';

/// Workout Session Screen
///
/// Main screen for logging exercises during a workout session.
/// Shows current exercise, set logging controls, and progress.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    this.readOnly = false,
    this.nextSetNavigation,
  });

  /// When true (after recording flow), inputs are hidden and sets are
  /// shown read-only. The user taps "Finish Workout" to complete.
  final bool readOnly;

  /// Route extras used to launch the next recording set from the logger.
  final Map<String, dynamic>? nextSetNavigation;

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  final PageController _pageController = PageController();
  bool _isAutoRoutingToRecording = false;
  bool _tourTriggered = false;

  // Guidance GlobalKeys
  final _exerciseTabsKey = GlobalKey(
    debugLabel: 'workout_session_exercise_tabs',
  );
  final _setInputKey = GlobalKey(debugLabel: 'workout_session_set_input');
  final _progressKey = GlobalKey(debugLabel: 'workout_session_progress');
  final _finishButtonKey = GlobalKey(debugLabel: 'workout_session_finish');

  @override
  void initState() {
    super.initState();

    if (widget.readOnly) {
      final preferredIndex =
          widget.nextSetNavigation?['currentExerciseIndex'] as int?;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(workoutSessionProvider.notifier)
            .refreshActiveSession(preferredExerciseIndex: preferredIndex);
      });
    }
  }

  void _syncPageToCurrentExercise(int index, {required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;

      final currentPage = (_pageController.page ?? 0).round();
      if (currentPage == index) return;

      if (animate) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.jumpToPage(index);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSessionStateChange(
    WorkoutSessionState? previous,
    WorkoutSessionState next,
  ) {
    if (next is WorkoutSessionCompleted) {
      _goToCoinReward(next.session, next.routine);
    } else if (next is WorkoutSessionError) {
      AppToast.error(context, next.error.message);
    } else if (next is WorkoutSessionActive &&
        previous is WorkoutSessionActive) {
      // Auto-scroll PageView when exercise index advances after completing sets
      final newIndex = next.currentExerciseIndex;
      final oldIndex = previous.currentExerciseIndex;
      if (newIndex != oldIndex &&
          newIndex < (next.routine?.exercises.length ?? 0) &&
          _pageController.hasClients) {
        _syncPageToCurrentExercise(newIndex, animate: true);
      }
    }
  }

  void _goToCoinReward(WorkoutSessionModel session, RoutineModel? routine) {
    ref.invalidate(activeTodayProvider);

    final exerciseStatuses =
        routine?.exercises.map((exercise) {
          final sets = session.setsForExercise(exercise.id);
          return <String, dynamic>{
            'name': exercise.exercise?.name ?? 'Exercise',
            'completed': sets.length,
            'target': exercise.sets,
          };
        }).toList() ??
        const <Map<String, dynamic>>[];

    context.go(
      AppRoutes.coinReward,
      extra: <String, dynamic>{
        'setsCompleted': session.completedSetsCount,
        'sessionDurationMin': session.duration?.inMinutes ?? 0,
        'showWorkoutSummaryAfterCoins': true,
        'workoutSummary': <String, dynamic>{
          'durationText': _formatDuration(session.duration),
          'setsCompleted': session.completedSetsCount,
          'totalVolumeKg': session.totalVolume,
          'exerciseStatuses': exerciseStatuses,
        },
      },
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(workoutSessionProvider);
    if (state is! WorkoutSessionActive) return true;

    final shouldLeave = await showAppConfirmDialog(
      context: context,
      title: 'Leave Workout?',
      message:
          'Your progress will be saved. You can continue this workout later.',
      confirmLabel: 'Leave',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    return shouldLeave ?? false;
  }

  void _onExerciseChanged(int index) {
    ref.read(workoutSessionProvider.notifier).goToExercise(index);

    final state = ref.read(workoutSessionProvider);
    if (state is WorkoutSessionActive && state.currentExercise != null) {
      final completedSets = state.session.setsForExercise(
        state.routine!.exercises[index].id,
      );
      ref
          .read(exerciseLogProvider.notifier)
          .initializeForExercise(
            state.routine!.exercises[index],
            existingSets: completedSets,
          );
    }
  }

  bool _autoResumeRecordingIfNeeded(WorkoutSessionActive state) {
    if (widget.readOnly || _isAutoRoutingToRecording) return false;
    final routine = state.routine;
    if (routine == null || routine.exercises.isEmpty) return false;
    if (state.isAllExercisesCompleted) return false;

    int targetIndex = state.currentExerciseIndex.clamp(
      0,
      routine.exercises.length - 1,
    );

    bool isIncompleteAt(int index) {
      final exercise = routine.exercises[index];
      final completed = state.session.setsForExercise(exercise.id).length;
      return completed < exercise.sets;
    }

    if (!isIncompleteAt(targetIndex)) {
      final nextIncompleteFromCurrent = routine.exercises.indexWhere(
        (exercise) =>
            state.session.setsForExercise(exercise.id).length < exercise.sets,
        targetIndex + 1,
      );

      targetIndex = nextIncompleteFromCurrent >= 0
          ? nextIncompleteFromCurrent
          : routine.exercises.indexWhere(
              (exercise) =>
                  state.session.setsForExercise(exercise.id).length <
                  exercise.sets,
            );

      if (targetIndex < 0) return false;
    }

    final targetExercise = routine.exercises[targetIndex];
    final exerciseId = targetExercise.exercise?.id ?? targetExercise.exerciseId;
    if (exerciseId.isEmpty) return false;

    final completedSets = state.session
        .setsForExercise(targetExercise.id)
        .length;
    final nextSetNumber = completedSets + 1;
    if (nextSetNumber > targetExercise.sets) return false;

    _isAutoRoutingToRecording = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(
        '/client/exercise/$exerciseId/unity-record',
        extra: {
          'workoutSessionId': state.session.id,
          'routineExerciseId': targetExercise.id,
          'routineExercises': routine.exercises,
          'currentExerciseIndex': targetIndex,
          'currentSetNumber': nextSetNumber,
        },
      );
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for state changes
    ref.listen(workoutSessionProvider, _handleSessionStateChange);

    final sessionState = ref.watch(workoutSessionProvider);

    if (sessionState is WorkoutSessionActive &&
        sessionState.currentExerciseIndex <
            (sessionState.routine?.exercises.length ?? 0)) {
      _syncPageToCurrentExercise(
        sessionState.currentExerciseIndex,
        animate: false,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go(AppRoutes.home);
        }
      },
      child: TourOrchestrator(
        tourKeys: {
          'workout_session_exercise_tabs': _exerciseTabsKey,
          'workout_session_set_input': _setInputKey,
          'workout_session_progress': _progressKey,
          'workout_session_finish': _finishButtonKey,
        },
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          appBar: _buildAppBar(context, sessionState, isDark),
          body: _buildBody(context, sessionState, isDark),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WorkoutSessionState state,
    bool isDark,
  ) {
    if (state is! WorkoutSessionActive) {
      return AppBar(title: const Text('Workout'));
    }

    // Compute progress metrics for the chunky block
    final totalSets = state.routine?.exercises
            .fold<int>(0, (sum, e) => sum + e.sets) ??
        0;
    final completedSets = state.session.completedSetsCount;

    return AppBar(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          final navigator = GoRouter.of(context);
          final shouldPop = await _onWillPop();
          if (!mounted) return;
          if (shouldPop) {
            navigator.go(AppRoutes.home);
          }
        },
      ),
      title: Text(
        state.routine?.name ?? 'Workout',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      centerTitle: true,
      actions: [
        InfoIconButton(
          content: kWorkoutSessionHelp,
          onTapOverride: () {
            ref
                .read(tourProvider.notifier)
                .startTour('workout_session', kWorkoutSessionTourSteps);
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: KeyedSubtree(
          key: _progressKey,
          child: _WorkoutProgressBlock(
            completedSets: completedSets,
            totalSets: totalSets,
            duration: state.session.duration,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  void _maybeStartTour(WorkoutSessionActive state) {
    if (_tourTriggered || widget.readOnly) return;
    _tourTriggered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = ref.read(guidanceRepositoryProvider);
      if (!repo.isCompleted(GuidanceRepository.kWorkoutSession)) {
        ref
            .read(tourProvider.notifier)
            .startTour('workout_session', kWorkoutSessionTourSteps);
      }
    });
  }

  Widget _buildBody(
    BuildContext context,
    WorkoutSessionState state,
    bool isDark,
  ) {
    if (state is WorkoutSessionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is WorkoutSessionInitial) {
      // Still checking for an active session — show spinner while
      // _checkActiveSession() resolves.
      return const Center(child: CircularProgressIndicator());
    }

    if (state is WorkoutSessionError) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        description: state.error.message,
        actionLabel: 'Go Back',
        onAction: () => context.go(AppRoutes.home),
      );
    }

    if (state is! WorkoutSessionActive) {
      return const SizedBox.shrink();
    }

    if (state.routine == null || state.routine!.exercises.isEmpty) {
      return AppEmptyState(
        icon: Icons.fitness_center,
        title: 'No Exercises',
        description: 'This routine has no exercises.',
        actionLabel: 'Go Back',
        onAction: () => context.go(AppRoutes.home),
      );
    }

    if (_autoResumeRecordingIfNeeded(state)) {
      return const Center(child: CircularProgressIndicator());
    }

    _maybeStartTour(state);

    return Column(
      children: [
        // Exercise tabs/indicators
        KeyedSubtree(
          key: _exerciseTabsKey,
          child: ExerciseTabBar(
            exercises: state.routine!.exercises,
            currentIndex: state.currentExerciseIndex,
            session: state.session,
            onTap: _onExerciseChanged,
          ),
        ),

        // Exercise content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: state.routine!.exercises.length,
            onPageChanged: _onExerciseChanged,
            itemBuilder: (context, index) {
              final exercise = state.routine!.exercises[index];
              final completedSets = state.session.setsForExercise(exercise.id);
              final latestSetId = completedSets.isNotEmpty
                  ? completedSets.last.id
                  : 'none';

              final card = ExerciseLogCard(
                key: ValueKey(
                  '${exercise.id}-${completedSets.length}-$latestSetId',
                ),
                routineExercise: exercise,
                completedSets: completedSets,
                onSetCompleted: _onSetCompleted,
                readOnly: widget.readOnly,
              );

              // Attach tour key to the first exercise card
              if (index == 0) {
                return KeyedSubtree(key: _setInputKey, child: card);
              }
              return card;
            },
          ),
        ),

        // Bottom actions
        KeyedSubtree(
          key: _finishButtonKey,
          child: _buildBottomActions(context, state, isDark),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    WorkoutSessionActive state,
    bool isDark,
  ) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );

    if (widget.readOnly) {
      final canStartNextSet = widget.nextSetNavigation != null;
      final canFinishWorkout = state.isAllExercisesCompleted;

      final label = canStartNextSet
          ? 'Start Next Set'
          : canFinishWorkout
          ? 'Finish Workout'
          : 'Continue Workout';

      final icon = canStartNextSet
          ? Icons.videocam
          : canFinishWorkout
          ? Icons.check
          : Icons.play_arrow;

      final onPressed = canStartNextSet
          ? _startNextSet
          : canFinishWorkout
          ? _completeWorkout
          : _continueWorkout;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          divider,
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton.primary(
                label: label,
                icon: icon,
                isFullWidth: true,
                onPressed: onPressed,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        divider,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Previous exercise
                if (state.currentExerciseIndex > 0)
                  Expanded(
                    child: AppButton.outline(
                      label: 'Previous',
                      icon: Icons.arrow_back,
                      onPressed: () {
                        ref
                            .read(workoutSessionProvider.notifier)
                            .previousExercise();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: 16),

                // Next exercise or Finish
                Expanded(
                  child: state.isAllExercisesCompleted
                      ? AppButton.primary(
                          label: 'Finish Workout',
                          icon: Icons.check,
                          onPressed: _completeWorkout,
                        )
                      : AppButton.primary(
                          label: 'Next',
                          icon: Icons.arrow_forward,
                          iconPosition: IconPosition.trailing,
                          onPressed: () async {
                            final routine = state.routine;
                            if (routine != null &&
                                state.currentExerciseIndex <
                                    routine.exercises.length) {
                              final currentExercise =
                                  routine.exercises[state.currentExerciseIndex];
                              final currentCompletedSets = state.session
                                  .setsForExercise(currentExercise.id)
                                  .length;
                              final isCurrentExerciseCompleted =
                                  currentCompletedSets >= currentExercise.sets;

                              final nextIndex = state.currentExerciseIndex + 1;
                              if (isCurrentExerciseCompleted &&
                                  nextIndex < routine.exercises.length) {
                                await _goToRecordingForExercise(
                                  state: state,
                                  exerciseIndex: nextIndex,
                                );
                                return;
                              }
                            }

                            ref
                                .read(workoutSessionProvider.notifier)
                                .nextExercise();
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onSetCompleted() {
    // Refresh UI after set completion
    setState(() {});
  }

  Future<void> _goToRecordingForExercise({
    required WorkoutSessionActive state,
    required int exerciseIndex,
  }) async {
    final routine = state.routine;
    if (routine == null) return;
    if (exerciseIndex < 0 || exerciseIndex >= routine.exercises.length) return;

    final targetExercise = routine.exercises[exerciseIndex];
    final exerciseId = targetExercise.exercise?.id ?? targetExercise.exerciseId;
    if (exerciseId.isEmpty) {
      AppToast.error(context, 'Unable to start recording for this exercise.');
      return;
    }

    final completedSets = state.session.setsForExercise(targetExercise.id);
    final nextSetNumber = completedSets.length + 1;
    if (nextSetNumber > targetExercise.sets) {
      AppToast.error(
        context,
        'All sets are already completed for this exercise.',
      );
      return;
    }

    context.go(
      '/client/exercise/$exerciseId/unity-record',
      extra: {
        'workoutSessionId': state.session.id,
        'routineExerciseId': targetExercise.id,
        'routineExercises': routine.exercises,
        'currentExerciseIndex': exerciseIndex,
        'currentSetNumber': nextSetNumber,
      },
    );
  }

  void _startNextSet() {
    final next = widget.nextSetNavigation;
    if (next == null) return;

    final exerciseId = next['exerciseId'] as String?;
    if (exerciseId == null || exerciseId.isEmpty) {
      AppToast.error(context, 'Unable to start next set. Missing exercise.');
      return;
    }

    context.go(
      '/client/exercise/$exerciseId/unity-record',
      extra: {
        'workoutSessionId': next['workoutSessionId'],
        'routineExerciseId': next['routineExerciseId'],
        'routineExercises': next['routineExercises'],
        'currentExerciseIndex': next['currentExerciseIndex'],
        'currentSetNumber': next['currentSetNumber'],
      },
    );
  }

  void _continueWorkout() {
    context.go(AppRoutes.workoutSession);
  }

  Future<void> _completeWorkout() async {
    final state = ref.read(workoutSessionProvider);
    if (state is WorkoutSessionActive && !state.isAllExercisesCompleted) {
      AppToast.error(
        context,
        'Complete all exercise sets before finishing your workout.',
      );
      return;
    }

    final notes = await _showNotesDialog();
    await ref
        .read(workoutSessionProvider.notifier)
        .completeSession(notes: notes);
  }

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();

    try {
      return await showAppDialog<String>(
        context: context,
        builder: (ctx) => AppDialogContent(
          icon: Icons.edit_note,
          iconColor: AppColors.primaryDark,
          title: 'Workout Notes',
          contentWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How did it feel? Optional — totally fine to skip.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedForegroundDark,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: controller,
                maxLines: 4,
                hint: 'e.g. Felt strong on bench, lower back tight on squat…',
              ),
            ],
          ),
          actionsDirection: Axis.vertical,
          actions: [
            AppDialogAction(
              label: 'Save & Finish',
              onPressed: () => Navigator.pop(ctx, controller.text),
              isPrimary: true,
              expanded: true,
            ),
            AppDialogAction(
              label: 'Skip',
              onPressed: () => Navigator.pop(ctx, null),
              expanded: true,
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

class _WorkoutProgressBlock extends StatelessWidget {
  const _WorkoutProgressBlock({
    required this.completedSets,
    required this.totalSets,
    required this.duration,
    required this.isDark,
  });

  final int completedSets;
  final int totalSets;
  final Duration? duration;
  final bool isDark;

  String _formatDuration(Duration? d) {
    if (d == null) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;
    final trackColor = isDark ? AppColors.surface2Dark : AppColors.surface2Light;

    return Container(
      height: 56,
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            '$completedSets/$totalSets sets',
            style: AppTextStyles.numericBody.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: trackColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(duration),
            style: AppTextStyles.numericBody.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
