import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/standalone_request_models.dart';
import '../providers/standalone_exercise_provider.dart';
import '../providers/standalone_routine_provider.dart';

/// Shows a bottom sheet to add an exercise to a standalone routine.
///
/// Returns `true` if exercise was successfully added, `false`/`null` otherwise.
Future<bool?> showStandaloneAddExerciseSheet({
  required BuildContext context,
  required String routineId,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddExerciseSheetContent(routineId: routineId),
  );
}

class _AddExerciseSheetContent extends ConsumerStatefulWidget {
  const _AddExerciseSheetContent({required this.routineId});

  final String routineId;

  @override
  ConsumerState<_AddExerciseSheetContent> createState() =>
      _AddExerciseSheetContentState();
}

class _AddExerciseSheetContentState
    extends ConsumerState<_AddExerciseSheetContent> {
  String? _selectedExerciseId;
  final _setsController = TextEditingController(text: '3');
  final _repsMinController = TextEditingController(text: '8');
  final _repsMaxController = TextEditingController(text: '12');
  final _restController = TextEditingController(text: '90');
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure exercises list is loaded
    final exercisesState = ref.read(standaloneExercisesProvider);
    if (exercisesState is StandaloneExercisesInitial) {
      Future.microtask(
        () => ref
            .read(standaloneExercisesProvider.notifier)
            .loadExercises(),
      );
    }
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
    final exercises = ref.watch(standaloneExercisesListProvider);
    final isLoadingExercises = ref.watch(standaloneExercisesLoadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Exercise', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Exercise picker
            if (isLoadingExercises)
              const Center(child: CircularProgressIndicator())
            else if (exercises.isEmpty)
              Text(
                'No exercises available. Create one first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              )
            else ...[
              Text('Exercise', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedExerciseId,
                decoration: InputDecoration(
                  hintText: 'Select an exercise',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: exercises.map((exercise) {
                  return DropdownMenuItem(
                    value: exercise.id,
                    child: Text(exercise.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedExerciseId = value),
              ),
              const SizedBox(height: 16),

              // Sets & Reps
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

              AppTextField(
                controller: _restController,
                label: 'Rest (seconds)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _notesController,
                label: 'Notes (optional)',
                hint: 'e.g. Slow eccentric',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              AppButton.primary(
                label: 'Add Exercise',
                onPressed: _isLoading || _selectedExerciseId == null
                    ? null
                    : _submit,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedExerciseId == null) return;

    final sets = int.tryParse(_setsController.text.trim());
    final repsMin = int.tryParse(_repsMinController.text.trim());
    final repsMax = int.tryParse(_repsMaxController.text.trim());
    final rest = int.tryParse(_restController.text.trim());

    if (sets == null || repsMin == null || repsMax == null || rest == null) {
      AppToast.warning(context, 'Please enter valid numbers');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(
            standaloneRoutineDetailProvider(widget.routineId).notifier,
          )
          .addExercise(
            AddStandaloneRoutineExerciseRequest(
              exerciseId: _selectedExerciseId!,
              sets: sets,
              repsMin: repsMin,
              repsMax: repsMax,
              restSeconds: rest,
              orderInRoutine: 999, // Server will reorder
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );

      if (mounted) {
        if (success) {
          AppToast.success(context, 'Exercise added');
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
