import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_programs/data/models/program_model.dart';
import '../providers/self_program_builder_provider.dart';

/// Shows a bottom sheet to edit an exercise's prescription within a program routine.
///
/// Pre-fills with the current values from [exercise] and saves via the
/// [ProgramBuilderNotifier.updateExercise] method.
///
/// Returns `true` if the exercise was updated, `null`/`false` otherwise.
Future<bool?> showSelfEditExerciseSheet({
  required BuildContext context,
  
  required String programId,
  required String aprId,
  required ProgramRoutineExerciseModel exercise,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (ctx) => _SelfEditExerciseSheet(
      
      programId: programId,
      aprId: aprId,
      exercise: exercise,
    ),
  );
}

class _SelfEditExerciseSheet extends ConsumerStatefulWidget {
  const _SelfEditExerciseSheet({
    
    required this.programId,
    required this.aprId,
    required this.exercise,
  });

  
  final String programId;
  final String aprId;
  final ProgramRoutineExerciseModel exercise;

  @override
  ConsumerState<_SelfEditExerciseSheet> createState() => _SelfEditExerciseSheetState();
}

class _SelfEditExerciseSheetState extends ConsumerState<_SelfEditExerciseSheet> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsMinController;
  late final TextEditingController _repsMaxController;
  late final TextEditingController _restController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.exercise.sets.toString(),
    );
    _repsMinController = TextEditingController(
      text: widget.exercise.repsMin.toString(),
    );
    _repsMaxController = TextEditingController(
      text: widget.exercise.repsMax.toString(),
    );
    _restController = TextEditingController(
      text: widget.exercise.restSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsMinController.dispose();
    _repsMaxController.dispose();
    _restController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exerciseName = widget.exercise.exercise?.name ?? 'Exercise';

    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomSheetHeader(
            title: 'Edit Exercise',
            onClose: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Exercise name preview
                AppCard.elevated(
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exerciseName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Prescription',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
                ),
                const SizedBox(height: 12),

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
                        label: 'Reps Min',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _repsMaxController,
                        label: 'Reps Max',
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
                const SizedBox(height: 24),
                AppButton(
                  label: 'Save Changes',
                  icon: Icons.check,
                  isFullWidth: true,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final sets = int.tryParse(_setsController.text.trim());
    final repsMin = int.tryParse(_repsMinController.text.trim());
    final repsMax = int.tryParse(_repsMaxController.text.trim());
    final rest = int.tryParse(_restController.text.trim());

    setState(() => _isSaving = true);

    final success = await ref
        .read(selfProgramBuilderProvider.notifier)
        .updateExercise(
          widget.aprId,
          widget.exercise.id,
          sets: sets,
          repsMin: repsMin,
          repsMax: repsMax,
          restSeconds: rest,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update exercise')),
        );
      }
    }
  }
}
