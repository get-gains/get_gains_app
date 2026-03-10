import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../../data/models/program_request_models.dart';
import '../providers/coach_routine_provider.dart';

/// Shows a bottom sheet to edit an exercise's prescription within a routine.
///
/// Returns `true` if the exercise was successfully updated, `false`/`null` otherwise.
Future<bool?> showEditExerciseSheet({
  required BuildContext context,
  required String routineId,
  required RoutineExerciseModel exercise,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _EditExerciseSheetContent(routineId: routineId, exercise: exercise),
  );
}

class _EditExerciseSheetContent extends ConsumerStatefulWidget {
  const _EditExerciseSheetContent({
    required this.routineId,
    required this.exercise,
  });

  final String routineId;
  final RoutineExerciseModel exercise;

  @override
  ConsumerState<_EditExerciseSheetContent> createState() =>
      _EditExerciseSheetContentState();
}

class _EditExerciseSheetContentState
    extends ConsumerState<_EditExerciseSheetContent> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsMinController;
  late final TextEditingController _repsMaxController;
  late final TextEditingController _restController;
  late final TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(text: '${widget.exercise.sets}');
    _repsMinController = TextEditingController(
      text: '${widget.exercise.repsMin}',
    );
    _repsMaxController = TextEditingController(
      text: '${widget.exercise.repsMax}',
    );
    _restController = TextEditingController(
      text: '${widget.exercise.restSeconds}',
    );
    _notesController = TextEditingController(text: widget.exercise.notes ?? '');
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
    final exerciseName = widget.exercise.exercise?.name ?? 'Exercise';

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
            Text('Edit Exercise', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              exerciseName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 20),

            // Prescription row: Sets / Min Reps / Max Reps
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
                    label: 'Save',
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

  Future<void> _submit() async {
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
          .updateExercise(
            widget.exercise.id,
            UpdateRoutineExerciseRequest(
              sets: sets,
              repsMin: repsMin,
              repsMax: repsMax,
              restSeconds: rest,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );

      if (mounted) {
        if (success) {
          AppToast.success(context, 'Exercise updated');
          Navigator.of(context).pop(true);
        } else {
          AppToast.error(context, 'Failed to update exercise');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
