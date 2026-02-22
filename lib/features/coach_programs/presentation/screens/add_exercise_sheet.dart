import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/coach_pose.dart';
import '../../../coach_pose/presentation/providers/exercise_list_provider.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_request_models.dart';
import '../providers/coach_routine_provider.dart';

/// Shows a bottom sheet to add an exercise from the global library to a routine.
///
/// Returns `true` if an exercise was successfully added, `false`/`null` otherwise.
Future<bool?> showAddExerciseSheet({
  required BuildContext context,
  required String routineId,
  required int nextOrder,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _AddExerciseSheetContent(routineId: routineId, nextOrder: nextOrder),
  );
}

class _AddExerciseSheetContent extends ConsumerStatefulWidget {
  const _AddExerciseSheetContent({
    required this.routineId,
    required this.nextOrder,
  });

  final String routineId;
  final int nextOrder;

  @override
  ConsumerState<_AddExerciseSheetContent> createState() =>
      _AddExerciseSheetContentState();
}

class _AddExerciseSheetContentState
    extends ConsumerState<_AddExerciseSheetContent> {
  final _setsController = TextEditingController(text: '3');
  final _repsMinController = TextEditingController(text: '8');
  final _repsMaxController = TextEditingController(text: '12');
  final _restController = TextEditingController(text: '90');
  final _notesController = TextEditingController();
  String? _selectedExerciseId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure exercise list is loaded
    Future.microtask(() {
      final exerciseState = ref.read(exerciseListProvider);
      if (exerciseState.exercises.isEmpty && !exerciseState.isLoading) {
        ref.read(exerciseListProvider.notifier).loadExercises();
      }
    });
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsMinController.dispose();
    _repsMaxController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final exerciseState = ref.watch(exerciseListProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Exercise', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Select an exercise from the library and set the prescription.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 20),

            // Exercise selector
            Text('Exercise', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildExerciseDropdown(exerciseState, isDark, theme),
            const SizedBox(height: 16),

            // Prescription row 1: Sets
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _setsController,
                    label: 'Sets',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _repsMinController,
                    label: 'Min Reps',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _repsMaxController,
                    label: 'Max Reps',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rest seconds
            AppTextField(
              controller: _restController,
              label: 'Rest (seconds)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Notes
            AppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'e.g. Squeeze at top, slow eccentric',
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.primary(
                    label: 'Add',
                    onPressed: _isLoading ? null : _submit,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDropdown(
    ExerciseListState state,
    bool isDark,
    ThemeData theme,
  ) {
    if (state.isLoading && state.exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface1Dark : AppColors.mutedLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No exercises available. Create exercises first.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputDark : AppColors.inputLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedExerciseId,
          isExpanded: true,
          hint: Text(
            'Choose an exercise...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          dropdownColor: isDark ? AppColors.surface2Dark : AppColors.cardLight,
          items: state.exercises.map((e) {
            return DropdownMenuItem(
              value: e.id,
              child: Text(
                '${e.name} (${e.primaryMuscleGroup.displayName})',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedExerciseId = value);
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedExerciseId == null) {
      AppToast.warning(context, 'Please select an exercise');
      return;
    }

    final sets = int.tryParse(_setsController.text.trim());
    final repsMin = int.tryParse(_repsMinController.text.trim());
    final repsMax = int.tryParse(_repsMaxController.text.trim());
    final rest = int.tryParse(_restController.text.trim());

    if (sets == null || sets < 1) {
      AppToast.warning(context, 'Enter valid sets');
      return;
    }
    if (repsMin == null || repsMin < 1) {
      AppToast.warning(context, 'Enter valid min reps');
      return;
    }
    if (repsMax == null || repsMax < repsMin) {
      AppToast.warning(context, 'Max reps must be ≥ min reps');
      return;
    }
    if (rest == null || rest < 0) {
      AppToast.warning(context, 'Enter valid rest seconds');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(routineDetailProvider(widget.routineId).notifier)
          .addExercise(
            AddRoutineExerciseRequest(
              exerciseId: _selectedExerciseId!,
              sets: sets,
              repsMin: repsMin,
              repsMax: repsMax,
              restSeconds: rest,
              orderInRoutine: widget.nextOrder,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );

      if (mounted) {
        if (success) {
          AppToast.success(context, 'Exercise added to routine');
          Navigator.of(context).pop(true);
        } else {
          AppToast.error(context, 'Failed to add exercise');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
