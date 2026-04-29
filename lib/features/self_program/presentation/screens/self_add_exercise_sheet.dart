import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_pose/presentation/providers/exercise_list_provider.dart';
import '../../../workout/data/models/exercise_model.dart';
import '../providers/self_program_builder_provider.dart';

/// Shows a bottom sheet to add an exercise to a program routine.
///
/// Flow:
///   1. Browse / search the exercise library.
///   2. Select an exercise → fill in prescription (sets, reps, rest).
///   3. Save → calls `addExercise` on the program builder provider.
///
///
/// Returns `true` if an exercise was added, `null`/`false` otherwise.
Future<bool?> showSelfAddExerciseSheet({
  required BuildContext context,
  
  required String programId,
  required String aprId,
  required int nextOrder,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (ctx) => _SelfAddExerciseSheet(
      
      programId: programId,
      aprId: aprId,
      nextOrder: nextOrder,
    ),
  );
}

class _SelfAddExerciseSheet extends ConsumerStatefulWidget {
  const _SelfAddExerciseSheet({
    
    required this.programId,
    required this.aprId,
    required this.nextOrder,
  });

  
  final String programId;
  final String aprId;
  final int nextOrder;

  @override
  ConsumerState<_SelfAddExerciseSheet> createState() => _SelfAddExerciseSheetState();
}

class _SelfAddExerciseSheetState extends ConsumerState<_SelfAddExerciseSheet> {
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
        // Create Custom Exercise affordance
        _CreateCustomExerciseTile(
          isDark: isDark,
          onTap: _onCreateCustomExercise,
        ),
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

  Future<void> _onCreateCustomExercise() async {
    final created = await context.push<ExerciseModel>(AppRoutes.exerciseCreate);
    if (created == null || !mounted) return;
    // Refresh library so the new exercise is visible in the list.
    ref.invalidate(exerciseListProvider);
    // Auto-select the new exercise → jump straight to prescription form.
    setState(() => _selectedExercise = created);
  }

  Future<void> _saveExercise() async {
    if (_selectedExercise == null) return;

    final sets = int.tryParse(_setsController.text.trim()) ?? 3;
    final repsMin = int.tryParse(_repsMinController.text.trim()) ?? 8;
    final repsMax = int.tryParse(_repsMaxController.text.trim()) ?? 12;
    final rest = int.tryParse(_restController.text.trim()) ?? 60;

    setState(() => _isSaving = true);

    final success = await ref
        .read(selfProgramBuilderProvider.notifier)
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

/// Prominent tile at the top of the exercise picker that lets the user jump
/// to the exercise-creation flow.
class _CreateCustomExerciseTile extends StatelessWidget {
  const _CreateCustomExerciseTile({
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
              color: accent.withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(Icons.add, size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Custom Exercise',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      Text(
                        "Add a movement that's not in the library",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
