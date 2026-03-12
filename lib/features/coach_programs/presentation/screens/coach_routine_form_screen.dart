import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../data/models/program_request_models.dart';
import '../providers/coach_routine_provider.dart';
import 'add_exercise_sheet.dart';
import 'edit_exercise_sheet.dart';

/// Create / Edit Routine Form Screen
///
/// When [routineId] is null, creates a new routine.
/// When [routineId] is provided, loads and edits the existing routine.
class CoachRoutineFormScreen extends ConsumerStatefulWidget {
  const CoachRoutineFormScreen({super.key, this.routineId});

  final String? routineId;

  bool get isEditing => routineId != null;

  @override
  ConsumerState<CoachRoutineFormScreen> createState() =>
      _CoachRoutineFormScreenState();
}

class _CoachRoutineFormScreenState
    extends ConsumerState<CoachRoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final Set<MuscleGroup> _selectedMuscleGroups = {};
  bool _isLoading = false;
  bool _hasLoadedExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      // Defer load to after the first build so ref.watch() establishes
      // a subscription before the auto-dispose provider can be collected.
      Future.microtask(_loadExisting);
    }
  }

  Future<void> _loadExisting() async {
    final notifier = ref.read(
      routineDetailProvider(widget.routineId!).notifier,
    );
    await notifier.load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pre-fill form when editing and data is loaded
    if (widget.isEditing && !_hasLoadedExisting) {
      final detailState = ref.watch(routineDetailProvider(widget.routineId!));
      if (detailState is RoutineDetailLoaded) {
        final routine = detailState.routine;
        _nameController.text = routine.name;
        _descriptionController.text = routine.description;
        _durationController.text = routine.estimatedDurationMinutes.toString();
        _selectedMuscleGroups
          ..clear()
          ..addAll(routine.muscleGroupsTargeted);
        _hasLoadedExisting = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Routine' : 'Create Routine'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildForm(isDark),
    );
  }

  Widget _buildForm(bool isDark) {
    // Show loading while fetching existing routine data
    if (widget.isEditing && !_hasLoadedExisting) {
      final detailState = ref.watch(routineDetailProvider(widget.routineId!));
      if (detailState is RoutineDetailLoading ||
          detailState is RoutineDetailInitial) {
        return const Center(child: CircularProgressIndicator());
      }
      if (detailState is RoutineDetailError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(detailState.error.message),
              const SizedBox(height: 16),
              AppButton(label: 'Retry', onPressed: _loadExisting),
            ],
          ),
        );
      }
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Routine Name',
              hint: 'e.g. Push Day, Upper Body A',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Routine name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe this routine...',
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _durationController,
              label: 'Estimated Duration (minutes)',
              hint: '45',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Duration is required';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed < 1 || parsed > 300) {
                  return 'Enter a valid duration (1-300 minutes)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Muscle group selection
            Text('Muscle Groups Targeted', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values.map((mg) {
                final isSelected = _selectedMuscleGroups.contains(mg);
                return FilterChip(
                  label: Text(mg.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMuscleGroups.add(mg);
                      } else {
                        _selectedMuscleGroups.remove(mg);
                      }
                    });
                  },
                  selectedColor: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.2)
                      : AppColors.primaryLight.withValues(alpha: 0.15),
                  checkmarkColor: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Exercise list (only when editing)
            if (widget.isEditing) ...[
              _buildExerciseSection(isDark, theme),
              const SizedBox(height: 32),
            ],

            AppButton.primary(
              label: widget.isEditing ? 'Save Changes' : 'Create Routine',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Exercise management (edit mode only)
  // ──────────────────────────────────────────────────────

  Widget _buildExerciseSection(bool isDark, ThemeData theme) {
    final detailState = ref.watch(routineDetailProvider(widget.routineId!));
    final List<RoutineExerciseModel> exercises;
    if (detailState is RoutineDetailLoaded) {
      exercises = [...detailState.routine.exercises]
        ..sort((a, b) => a.orderInRoutine.compareTo(b.orderInRoutine));
    } else {
      exercises = [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Exercises', style: theme.textTheme.titleSmall),
            ),
            TextButton.icon(
              onPressed: () => _showAddExerciseSheet(exercises.length),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (exercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1Dark : AppColors.mutedLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No exercises yet. Tap "Add" to start building this routine.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...exercises.map(
            (re) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildExerciseCard(re, isDark, theme),
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseCard(
    RoutineExerciseModel exercise,
    bool isDark,
    ThemeData theme,
  ) {
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
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit exercise',
                onPressed: () => _editExercise(exercise),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: isDark ? AppColors.error : AppColors.errorLight,
                tooltip: 'Remove exercise',
                onPressed: () => _confirmRemoveExercise(exercise),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Prescription stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface0Dark : AppColors.mutedLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _prescriptionStat('Sets', '${exercise.sets}', isDark, theme),
                _prescriptionStat(
                  'Reps',
                  '${exercise.repsMin}-${exercise.repsMax}',
                  isDark,
                  theme,
                ),
                _prescriptionStat(
                  'Rest',
                  '${exercise.restSeconds}s',
                  isDark,
                  theme,
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

  Widget _prescriptionStat(
    String label,
    String value,
    bool isDark,
    ThemeData theme,
  ) {
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

  Future<void> _showAddExerciseSheet(int currentCount) async {
    final result = await showAddExerciseSheet(
      context: context,
      routineId: widget.routineId!,
      nextOrder: currentCount + 1,
    );
    if (result == true && mounted) {
      ref.read(routineDetailProvider(widget.routineId!).notifier).load();
    }
  }

  Future<void> _editExercise(RoutineExerciseModel exercise) async {
    final result = await showEditExerciseSheet(
      context: context,
      routineId: widget.routineId!,
      exercise: exercise,
    );
    if (result == true && mounted) {
      ref.read(routineDetailProvider(widget.routineId!).notifier).load();
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
          .read(routineDetailProvider(widget.routineId!).notifier)
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      final duration = int.parse(_durationController.text.trim());

      if (widget.isEditing) {
        success = await ref
            .read(coachRoutinesProvider.notifier)
            .updateRoutine(
              widget.routineId!,
              UpdateRoutineRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                estimatedDurationMinutes: duration,
                muscleGroupsTargeted: _selectedMuscleGroups.toList(),
              ),
            );
      } else {
        success = await ref
            .read(coachRoutinesProvider.notifier)
            .createRoutine(
              CreateRoutineRequest(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                estimatedDurationMinutes: duration,
                muscleGroupsTargeted: _selectedMuscleGroups.toList(),
              ),
            );
      }

      if (mounted) {
        if (success) {
          AppToast.success(
            context,
            widget.isEditing ? 'Routine updated' : 'Routine created',
          );
          context.pop();
        } else {
          AppToast.error(
            context,
            widget.isEditing
                ? 'Failed to update routine'
                : 'Failed to create routine',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
