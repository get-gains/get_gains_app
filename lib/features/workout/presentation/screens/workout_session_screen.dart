import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
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
      _showCompletionDialog(next.session, next.routine);
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
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _showCompletionDialog(
    WorkoutSessionModel session,
    RoutineModel? routine,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatDuration(session.duration)}'),
            Text('Sets completed: ${session.completedSetsCount}'),
            Text('Total volume: ${session.totalVolume.toStringAsFixed(1)} kg'),
            if (routine != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...routine.exercises.map((exercise) {
                final sets = session.setsForExercise(exercise.id);
                final done = sets.length >= exercise.sets;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: done ? AppColors.success : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercise.exercise?.name ?? 'Exercise',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${sets.length}/${exercise.sets}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: done ? AppColors.success : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.invalidate(activeTodayProvider);
              context.go(AppRoutes.home);
            },
            child: const Text('Done'),
          ),
        ],
      ),
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

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Workout?'),
        content: const Text(
          'Your progress will be saved. You can continue this workout later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for state changes
    ref.listen(workoutSessionProvider, _handleSessionStateChange);

    final sessionState = ref.watch(workoutSessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: _buildAppBar(context, sessionState, isDark),
        body: _buildBody(context, sessionState, isDark),
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

    return AppBar(
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
      title: Column(
        children: [
          Text(
            state.routine?.name ?? 'Workout',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            _formatDuration(state.session.duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: state.progress,
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
      ),
    );
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
        onAction: () => context.go(AppRoutes.routines),
      );
    }

    return Column(
      children: [
        // Exercise tabs/indicators
        ExerciseTabBar(
          exercises: state.routine!.exercises,
          currentIndex: state.currentExerciseIndex,
          session: state.session,
          onTap: _onExerciseChanged,
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

              return ExerciseLogCard(
                routineExercise: exercise,
                completedSets: completedSets,
                onSetCompleted: _onSetCompleted,
                readOnly: widget.readOnly,
              );
            },
          ),
        ),

        // Bottom actions
        _buildBottomActions(context, state, isDark),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    WorkoutSessionActive state,
    bool isDark,
  ) {
    if (widget.readOnly) {
      final canStartNextSet = widget.nextSetNavigation != null;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton.primary(
            label: canStartNextSet ? 'Start Next Set' : 'Finish Workout',
            icon: canStartNextSet ? Icons.videocam : Icons.check,
            isFullWidth: true,
            onPressed: canStartNextSet ? _startNextSet : _completeWorkout,
          ),
        ),
      );
    }

    return SafeArea(
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
                      onPressed: () {
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
    );
  }

  void _onSetCompleted() {
    // Refresh UI after set completion
    setState(() {});
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

  Future<void> _completeWorkout() async {
    final notes = await _showNotesDialog();
    await ref
        .read(workoutSessionProvider.notifier)
        .completeSession(notes: notes);
  }

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'How did the workout feel?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
