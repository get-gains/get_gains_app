import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/app_dialog.dart';
import '../../../../widgets/app_toast.dart';
import '../../../workout/data/models/models.dart';
import '../../../workout/presentation/widgets/exercise_tab_bar.dart';
import '../../../workout/presentation/widgets/set_input_row.dart';
import '../../../gains_coins/presentation/providers/coin_balance_provider.dart';
import '../../data/models/standalone_request_models.dart';
import '../../data/standalone_workout_repository.dart';

/// Standalone Workout Screen
///
/// Set-logging screen for user-built (free-tier) workouts.
/// No 3D pose recording, no Unity — just reps, weight, and RPE.
class StandaloneWorkoutScreen extends ConsumerStatefulWidget {
  const StandaloneWorkoutScreen({
    super.key,
    required this.session,
    required this.exercises,
    required this.routineName,
  });

  final WorkoutSessionModel session;
  final List<RoutineExerciseModel> exercises;
  final String routineName;

  @override
  ConsumerState<StandaloneWorkoutScreen> createState() =>
      _StandaloneWorkoutScreenState();
}

class _SetState {
  _SetState({
    required this.setNumber,
    this.reps = 0,
    this.weight = 0,
    this.rpe,
    this.isCompleted = false,
    this.isSubmitting = false,
  });

  int setNumber;
  int reps;
  double weight;
  int? rpe;
  bool isCompleted;
  bool isSubmitting;
}

class _StandaloneWorkoutScreenState
    extends ConsumerState<StandaloneWorkoutScreen> {
  final PageController _pageController = PageController();
  late final WorkoutSessionModel _session;
  late final List<List<_SetState>> _exerciseSets;
  int _currentExerciseIndex = 0;
  bool _isCompleting = false;

  int get _totalSets =>
      widget.exercises.fold<int>(0, (sum, e) => sum + e.sets);

  int get _completedSets {
    int count = 0;
    for (final sets in _exerciseSets) {
      count += sets.where((s) => s.isCompleted).length;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _exerciseSets = widget.exercises.map((exercise) {
      return List.generate(
        exercise.sets,
        (i) => _SetState(
          setNumber: i + 1,
          reps: exercise.repsMin,
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _allExercisesCompleted {
    for (int i = 0; i < widget.exercises.length; i++) {
      final completed = _exerciseSets[i].where((s) => s.isCompleted).length;
      if (completed < widget.exercises[i].sets) return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
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
    if (index == _currentExerciseIndex) return;
    setState(() {
      _currentExerciseIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _logSet(int exerciseIndex, int setIndex) async {
    final setData = _exerciseSets[exerciseIndex][setIndex];
    if (setData.reps <= 0 || setData.isCompleted || setData.isSubmitting) {
      return;
    }

    setState(() {
      setData.isSubmitting = true;
    });

    final exercise = widget.exercises[exerciseIndex];
    final repo = ref.read(standaloneWorkoutRepositoryProvider);

    final result = await repo.logSet(
      _session.id,
      LogStandaloneSetRequest(
        routineExerciseId: exercise.id,
        setNumber: setData.setNumber,
        reps: setData.reps,
        weight: setData.weight.toDouble(),
      ),
    );

    result.when(
      success: (_) {
        setState(() {
          setData.isCompleted = true;
          setData.isSubmitting = false;
        });

        final completedInExercise = _exerciseSets[exerciseIndex]
            .where((s) => s.isCompleted)
            .length;
        if (completedInExercise >= exercise.sets) {
          final nextIncomplete = widget.exercises.indexWhere(
            (ex) {
              final idx = widget.exercises.indexOf(ex);
              final completed =
                  _exerciseSets[idx].where((s) => s.isCompleted).length;
              return completed < ex.sets;
            },
            exerciseIndex + 1,
          );
          if (nextIncomplete >= 0) {
            _onExerciseChanged(nextIncomplete);
          }
        }
      },
      failure: (error) {
        setState(() {
          setData.isSubmitting = false;
        });
        AppToast.error(context, 'Failed to log set: ${error.message}');
      },
    );
  }

  Future<void> _completeWorkout() async {
    if (!_allExercisesCompleted) {
      AppToast.error(
        context,
        'Complete all exercise sets before finishing your workout.',
      );
      return;
    }

    final notes = await _showNotesDialog();
    if (!mounted) return;

    setState(() => _isCompleting = true);

    final standaloneRepo = ref.read(standaloneWorkoutRepositoryProvider);
    final result = await standaloneRepo.completeSession(
      _session.id,
      feedback: notes,
    );

    result.when(
      success: (_) async {
        if (mounted) {
          ref.read(coinBalanceProvider.notifier).refresh();
          AppToast.success(context, 'Workout complete!');
          context.go(AppRoutes.home);
        }
      },
      failure: (error) {
        if (mounted) {
          AppToast.error(
            context,
            'Failed to complete workout: ${error.message}',
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isCompleting = false);
    }
  }

  Widget _buildQuickCompleteButton(
    BuildContext context,
    int exerciseIndex,
    List<_SetState> sets,
  ) {
    final firstIncompleteIndex = sets.indexWhere((s) => !s.isCompleted);
    if (firstIncompleteIndex >= 0) {
      return AppButton.primary(
        label: 'Complete Set ${firstIncompleteIndex + 1}',
        icon: Icons.check,
        isFullWidth: true,
        isLoading: sets[firstIncompleteIndex].isSubmitting,
        onPressed: () {
          HapticFeedback.mediumImpact();
          _logSet(exerciseIndex, firstIncompleteIndex);
        },
      );
    }
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success),
        const SizedBox(width: 8),
        Text(
          'All sets completed!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();

    final result = await showAppDialog<String>(
      context: context,
      builder: (ctx) => AppDialogContent(
        icon: Icons.edit_note,
        iconColor: AppColors.primaryDark,
        title: 'Workout Notes',
        contentWidget: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
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
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Felt strong on bench, lower back tight on squat…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsDirection: Axis.vertical,
        actions: [
          AppDialogAction(
            label: 'Save & Finish',
            onPressed: () {
              final text = controller.text;
              Navigator.pop(ctx, text);
            },
            isPrimary: true,
            expanded: true,
          ),
          AppDialogAction(
            label: 'Skip',
            onPressed: () {
              Navigator.pop(ctx, null);
            },
            expanded: true,
          ),
        ],
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: _buildAppBar(context, isDark),
        body: Column(
          children: [
            ExerciseTabBar(
              exercises: widget.exercises,
              currentIndex: _currentExerciseIndex,
              session: _session,
              onTap: _onExerciseChanged,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.exercises.length,
                onPageChanged: (index) {
                  setState(() => _currentExerciseIndex = index);
                },
                itemBuilder: (context, index) {
                  return _buildExercisePage(context, index, isDark);
                },
              ),
            ),
            _buildBottomActions(context, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.go(AppRoutes.home);
          }
        },
      ),
      title: Text(
        widget.routineName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _WorkoutProgressBlock(
          completedSets: _completedSets,
          totalSets: _totalSets,
          duration: _session.duration,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildExercisePage(
    BuildContext context,
    int exerciseIndex,
    bool isDark,
  ) {
    final exercise = widget.exercises[exerciseIndex];
    final sets = _exerciseSets[exerciseIndex];
    final completedCount = sets.where((s) => s.isCompleted).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard.elevated(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise?.name ?? 'Exercise',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (exercise.exercise?.description case final desc?
                    when desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    desc,
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
            ),
          ),

          const SizedBox(height: 12),

          _PrescriptionInfo(
            sets: exercise.sets,
            repsMin: exercise.repsMin,
            repsMax: exercise.repsMax,
            restSeconds: exercise.restSeconds,
            notes: exercise.notes,
          ),

          const SizedBox(height: 24),

          _SetProgressIndicator(
            completed: completedCount,
            total: exercise.sets,
          ),

          const SizedBox(height: 16),

          ...List.generate(sets.length, (setIndex) {
            final set = sets[setIndex];
            return SetInputRow(
              setNumber: set.setNumber,
              reps: set.reps,
              weight: set.weight,
              rpe: set.rpe,
              isCompleted: set.isCompleted,
              isActive: !set.isCompleted &&
                  sets.indexWhere((s) => !s.isCompleted) == setIndex,
              targetReps: '${exercise.repsMin}-${exercise.repsMax}',
              onRepsChanged: (reps) {
                setState(() => set.reps = reps);
              },
              onWeightChanged: (weight) {
                setState(() => set.weight = weight);
              },
              onRpeChanged: (rpe) {
                setState(() => set.rpe = rpe);
              },
              onComplete: () => _logSet(exerciseIndex, setIndex),
              onTap: () {},
            );
          }),

          const SizedBox(height: 24),

          _buildQuickCompleteButton(context, exerciseIndex, sets),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isDark) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        divider,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentExerciseIndex > 0)
                  Expanded(
                    child: AppButton.outline(
                      label: 'Previous',
                      icon: Icons.arrow_back,
                      onPressed: () {
                        _onExerciseChanged(_currentExerciseIndex - 1);
                      },
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: 16),

                Expanded(
                  child: _allExercisesCompleted
                      ? AppButton.primary(
                          label: 'Finish Workout',
                          icon: Icons.check,
                          isLoading: _isCompleting,
                          onPressed: _completeWorkout,
                        )
                      : AppButton.primary(
                          label: 'Next',
                          icon: Icons.arrow_forward,
                          iconPosition: IconPosition.trailing,
                          onPressed: () {
                            final nextIndex = _currentExerciseIndex + 1;
                            if (nextIndex < widget.exercises.length) {
                              _onExerciseChanged(nextIndex);
                            }
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

    return AppCard.elevated(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoChip(icon: Icons.repeat, label: '$sets sets'),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: primaryColor),
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
  const _SetProgressIndicator({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

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
    final trackColor =
        isDark ? AppColors.surface2Dark : AppColors.surface2Light;

    return Container(
      height: 56,
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            '$completedSets/$totalSets sets',
            style: AppTextStyles.numericBody.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
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
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
