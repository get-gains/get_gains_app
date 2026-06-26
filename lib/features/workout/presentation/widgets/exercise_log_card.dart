import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../../client_pose/data/client_pose_repository.dart';
import '../../../client_pose/presentation/widgets/pose_view_widget.dart';
import '../../../coach_pose/data/models/landmark_models.dart';
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
    this.readOnly = false,
  });

  final RoutineExerciseModel routineExercise;
  final List<PerformedSetModel> completedSets;
  final VoidCallback onSetCompleted;

  /// When true, hides all input controls and shows completed sets as read-only.
  final bool readOnly;

  @override
  ConsumerState<ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends ConsumerState<ExerciseLogCard> {
  @override
  void initState() {
    super.initState();
    // Initialize the exercise log provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(exerciseLogProvider.notifier)
          .initializeForExercise(
            widget.routineExercise,
            existingSets: widget.completedSets,
          );
    });
  }

  @override
  void didUpdateWidget(covariant ExerciseLogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final exerciseChanged =
        oldWidget.routineExercise.id != widget.routineExercise.id;
    final completedSetsChanged =
        oldWidget.completedSets.length != widget.completedSets.length;

    if (exerciseChanged || completedSetsChanged) {
      ref
          .read(exerciseLogProvider.notifier)
          .initializeForExercise(
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
          AppCard.elevated(
            padding: const EdgeInsets.all(16),
            child: _ExerciseHeader(
              name: exercise?.name ?? 'Exercise',
              description: exercise?.description ?? '',
              muscleGroup: exercise?.primaryMuscleGroup,
            ),
          ),

          const SizedBox(height: 12),

          // Prescription info
          _PrescriptionInfo(
            sets: widget.routineExercise.sets,
            repsMin: widget.routineExercise.repsMin,
            repsMax: widget.routineExercise.repsMax,
            restSeconds: widget.routineExercise.restSeconds,
            notes: widget.routineExercise.notes,
          ),

          const SizedBox(height: 12),

          // Coach form preview (collapsible inline card)
          _FormPreviewCard(
            exerciseId: widget.routineExercise.exerciseId,
            exerciseName: exercise?.name ?? 'Exercise',
          ),

          const SizedBox(height: 24),

          // Read-only summary when coming from recording flow
          if (widget.readOnly) ..._buildReadOnlySets(context),

          // Set logging area
          if (!widget.readOnly && exerciseLogState != null) ...[
            // Progress indicator
            _SetProgressIndicator(
              completed: exerciseLogState.completedSetsCount,
              total: exerciseLogState.routineExercise.sets,
            ),

            const SizedBox(height: 16),

            // Set input rows
            ...List.generate(exerciseLogState.sets.length, (index) {
              final set = exerciseLogState.sets[index];
              return SetInputRow(
                setNumber: set.setNumber,
                reps: set.reps,
                weight: set.weight,
                rpe: set.rpe,
                isCompleted: set.isCompleted,
                isActive: index == exerciseLogState.currentSetIndex,
                targetReps:
                    '${widget.routineExercise.repsMin}-${widget.routineExercise.repsMax}',
                onRepsChanged: (reps) {
                  ref
                      .read(exerciseLogProvider.notifier)
                      .updateSet(index, reps: reps);
                },
                onWeightChanged: (weight) {
                  ref
                      .read(exerciseLogProvider.notifier)
                      .updateSet(index, weight: weight);
                },
                onRpeChanged: (rpe) {
                  ref
                      .read(exerciseLogProvider.notifier)
                      .updateSet(index, rpe: rpe);
                },
                onComplete: () async {
                  ref.read(exerciseLogProvider.notifier).selectSet(index);
                  final logged = await ref
                      .read(exerciseLogProvider.notifier)
                      .completeCurrentSet();
                  if (logged) widget.onSetCompleted();
                },
                onTap: () {
                  ref.read(exerciseLogProvider.notifier).selectSet(index);
                },
              );
            }),

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
                  final logged = await ref
                      .read(exerciseLogProvider.notifier)
                      .completeCurrentSet();
                  if (logged) widget.onSetCompleted();
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

  List<Widget> _buildReadOnlySets(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sets = widget.completedSets;

    if (sets.isEmpty) {
      return [
        Row(
          children: [
            const SizedBox(width: 8),
            Text(
              'No sets logged',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ];
    }

    return [
      Text(
        'Logged Sets',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...sets.map(
        (s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: AppColors.success.withValues(alpha: 0.7),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Text(
                'Set ${s.setNumber}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${s.repsCompleted} reps',
                style: AppTextStyles.numericBody.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              if (s.weightKg != null && s.weightKg! > 0) ...[
                const SizedBox(width: 16),
                Text(
                  '${s.weightKg!.toStringAsFixed(1)} kg',
                  style: AppTextStyles.numericBody.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
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
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: primaryColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
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
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sets Progress',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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

/// Inline coach form preview card — collapsible card that loads and displays
/// the coach's reference skeleton for visual comparison during a workout.
class _FormPreviewCard extends ConsumerStatefulWidget {
  const _FormPreviewCard({
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;
  final String exerciseName;

  @override
  ConsumerState<_FormPreviewCard> createState() => _FormPreviewCardState();
}

class _FormPreviewCardState extends ConsumerState<_FormPreviewCard> {
  List<LandmarkFrame>? _landmarkFrames;
  bool _isLoading = false;
  bool _isExpanded = false;
  String? _cameraAngle;
  String? _formError;

  Future<void> _loadAndExpand() async {
    if (_isLoading) return;

    if (_landmarkFrames != null) {
      setState(() => _isExpanded = !_isExpanded);
      return;
    }

    setState(() {
      _isLoading = true;
      _isExpanded = true;
    });

    try {
      final repo = ref.read(clientPoseRepositoryProvider);
      final result = await repo.downloadExerciseForm(widget.exerciseId);

      if (!mounted) return;

      result.when(
        success: (data) {
          final forms = data['forms'] as List?;
          final formsBlobs =
              data['formsBlobs'] as Map<String, dynamic>? ?? {};

          if (forms == null || forms.isEmpty) {
            setState(() {
              _formError = 'No reference form available';
              _isLoading = false;
            });
            return;
          }

          final firstForm = forms.first as Map<String, dynamic>;
          final formId = firstForm['id'] as String?;
          _cameraAngle = firstForm['camera_angle'] as String?;

          if (formId != null && formsBlobs.containsKey(formId)) {
            final blob = formsBlobs[formId] as Map<String, dynamic>;
            final rawFrames = blob['landmarkFrames'] as List<dynamic>?;

            final frames = rawFrames?.map((f) {
              return LandmarkFrame.fromJson(f as Map<String, dynamic>);
            }).toList();

            setState(() {
              _landmarkFrames = frames;
              _isLoading = false;
            });
          } else {
            setState(() {
              _formError = 'No form data available';
              _isLoading = false;
            });
          }
        },
        failure: (error) {
          if (!mounted) return;
          setState(() {
            _formError = error.message;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = 'Failed to load form';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard.elevated(
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _loadAndExpand,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coach Form Preview',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_cameraAngle != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatAngleLabel(_cameraAngle!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  if (_isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_landmarkFrames != null && _landmarkFrames!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 160,
                    child: PoseViewWidget(
                      landmarkFrames: _landmarkFrames!,
                      mode: PoseViewMode.raw2D,
                      color: Colors.cyanAccent,
                      backgroundColor: const Color(0xFF0F0F1A),
                      showControls: false,
                      mirrorX: true,
                    ),
                  ),
                ),
              )
            else if (!_isLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Loading preview...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _formatAngleLabel(String angle) {
    return angle
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
