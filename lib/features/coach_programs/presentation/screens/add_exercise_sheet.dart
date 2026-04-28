import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/presentation/providers/exercise_list_provider.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../providers/program_builder_provider.dart';

/// Shows a bottom sheet to add an exercise to a program routine.
///
/// Flow:
///   1. Browse / search the exercise library.
///   2. Select an exercise → fill in prescription (sets, reps, rest).
///   3. Save → calls `addExercise` on the program builder provider.
///
/// Also offers a "Create New Exercise" button that pushes the
/// [CreateExerciseScreen]. On return, the library is refreshed.
///
/// Returns `true` if an exercise was added, `null`/`false` otherwise.
Future<bool?> showAddExerciseSheet({
  required BuildContext context,
  required String clientId,
  required String programId,
  required String aprId,
  required int nextOrder,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (ctx) => _AddExerciseSheet(
      clientId: clientId,
      programId: programId,
      aprId: aprId,
      nextOrder: nextOrder,
    ),
  );
}

class _AddExerciseSheet extends ConsumerStatefulWidget {
  const _AddExerciseSheet({
    required this.clientId,
    required this.programId,
    required this.aprId,
    required this.nextOrder,
  });

  final String clientId;
  final String programId;
  final String aprId;
  final int nextOrder;

  @override
  ConsumerState<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<_AddExerciseSheet> {
  // Step: library → prescription
  ExerciseModel? _selectedExercise;

  // Prescription form
  final _setsController = TextEditingController(text: '3');
  final _repsMinController = TextEditingController(text: '8');
  final _repsMaxController = TextEditingController(text: '12');
  final _restController = TextEditingController(text: '60');

  bool _isSaving = false;

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

    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomSheetHeader(
            title: _selectedExercise == null
                ? 'Select Exercise'
                : 'Set Prescription',
            onClose: () => Navigator.of(context).pop(),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _selectedExercise == null
                ? _buildExerciseLibrary(isDark)
                : _buildPrescriptionForm(isDark),
          ),
        ],
      ),
    );
  }

  // ── Exercise Library ─────────────────────────────────

  Widget _buildExerciseLibrary(bool isDark) {
    final exerciseState = ref.watch(exerciseListProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  hint: 'Search exercises...',
                  prefixIcon: Icons.search,
                  size: AppTextFieldSize.sm,
                  onChanged: (value) =>
                      ref.read(exerciseListProvider.notifier).search(value),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
                onPressed: _createNewExercise,
              ),
            ],
          ),
        ),
        // Muscle group filter
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChipItem(
                label: 'All',
                isSelected: exerciseState.selectedMuscleGroup == null,
                isDark: isDark,
                onTap: () => ref
                    .read(exerciseListProvider.notifier)
                    .filterByMuscleGroup(null),
              ),
              ...MuscleGroup.values.map(
                (mg) => _FilterChipItem(
                  label: mg.displayName,
                  isSelected: exerciseState.selectedMuscleGroup == mg,
                  isDark: isDark,
                  onTap: () => ref
                      .read(exerciseListProvider.notifier)
                      .filterByMuscleGroup(mg),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Exercise list
        Expanded(
          child: exerciseState.isLoading && exerciseState.exercises.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : exerciseState.exercises.isEmpty
              ? Center(
                  child: Text(
                    exerciseState.errorMessage ?? 'No exercises found.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: exerciseState.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exerciseState.exercises[index];
                    return _ExerciseLibraryRow(
                      exercise: exercise,
                      isDark: isDark,
                      onSelect: () =>
                          setState(() => _selectedExercise = exercise),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _createNewExercise() async {
    // Close the bottom sheet, push the create screen.
    Navigator.of(context).pop();
    // ignore: use_build_context_synchronously
    GoRouter.of(context).push(AppRoutes.createExercise);
    // When the user pops back, they can re-open "Add Exercise" with the
    // new exercise in the library (auto-refreshed by ExerciseListNotifier).
  }

  // ── Prescription Form ────────────────────────────────

  Widget _buildPrescriptionForm(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Selected exercise preview
        AppCard.elevated(
          child: Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedExercise!.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      _selectedExercise!.primaryMuscleGroup.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedExercise = null),
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
          label: 'Add Exercise',
          icon: Icons.add,
          isFullWidth: true,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveExercise,
        ),
      ],
    );
  }

  Future<void> _saveExercise() async {
    if (_selectedExercise == null) return;

    final sets = int.tryParse(_setsController.text.trim()) ?? 3;
    final repsMin = int.tryParse(_repsMinController.text.trim()) ?? 8;
    final repsMax = int.tryParse(_repsMaxController.text.trim()) ?? 12;
    final rest = int.tryParse(_restController.text.trim()) ?? 60;

    setState(() => _isSaving = true);

    final success = await ref
        .read(programBuilderProvider(widget.clientId).notifier)
        .addExercise(
          widget.aprId,
          exerciseId: _selectedExercise!.id,
          sets: sets,
          repsMin: repsMin,
          repsMax: repsMax,
          restSeconds: rest,
          orderInRoutine: widget.nextOrder,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add exercise')));
      }
    }
  }
}

// ── Internal Widgets ───────────────────────────────────

class _ExerciseLibraryRow extends StatelessWidget {
  const _ExerciseLibraryRow({
    required this.exercise,
    required this.isDark,
    required this.onSelect,
  });

  final ExerciseModel exercise;
  final bool isDark;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onSelect,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isDark
            ? AppColors.surface2Dark
            : AppColors.surface2Light,
        child: Icon(
          Icons.fitness_center,
          size: 18,
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
      ),
      title: Text(exercise.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        exercise.primaryMuscleGroup.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark
            ? AppColors.mutedForegroundDark
            : AppColors.mutedForegroundLight,
      ),
      dense: true,
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
          fontFamily: AppTextStyles.fontFamilySans,
        ),
        onSelected: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
