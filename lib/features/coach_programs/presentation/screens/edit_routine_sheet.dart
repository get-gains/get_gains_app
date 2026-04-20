import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../providers/program_builder_provider.dart';

/// Shows a bottom sheet to edit a routine's metadata within a program.
///
/// Allows editing name, description, duration, and day-of-week schedule.
///
/// Returns `true` if the routine was updated, `null`/`false` otherwise.
Future<bool?> showEditRoutineSheet({
  required BuildContext context,
  required String clientId,
  required String programId,
  required ProgramRoutineModel routine,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (ctx) => _EditRoutineSheet(
      clientId: clientId,
      programId: programId,
      routine: routine,
    ),
  );
}

class _EditRoutineSheet extends ConsumerStatefulWidget {
  const _EditRoutineSheet({
    required this.clientId,
    required this.programId,
    required this.routine,
  });

  final String clientId;
  final String programId;
  final ProgramRoutineModel routine;

  @override
  ConsumerState<_EditRoutineSheet> createState() => _EditRoutineSheetState();
}

class _EditRoutineSheetState extends ConsumerState<_EditRoutineSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final Set<DayOfWeek> _selectedDays;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descriptionController = TextEditingController(
      text: widget.routine.description,
    );
    _durationController = TextEditingController(
      text: widget.routine.estimatedDurationMinutes.toString(),
    );
    _selectedDays = Set<DayOfWeek>.from(widget.routine.daysOfWeek);
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

    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(title: 'Edit Routine'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Routine Name',
                  hint: 'e.g. Upper Body Push',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Brief description...',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _durationController,
                  label: 'Estimated Duration (min)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  'Days of Week',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
                ),
                const SizedBox(height: 8),
                _DayOfWeekSelector(
                  selectedDays: _selectedDays,
                  isDark: isDark,
                  onChanged: (days) => setState(() {
                    _selectedDays
                      ..clear()
                      ..addAll(days);
                  }),
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Routine name is required')));
      return;
    }

    final duration = int.tryParse(_durationController.text.trim());

    setState(() => _isSaving = true);

    final success = await ref
        .read(programBuilderProvider(widget.clientId).notifier)
        .updateRoutine(
          widget.routine.id,
          name: name,
          description: _descriptionController.text.trim(),
          estimatedDurationMinutes: duration,
          daysOfWeek: _selectedDays.toList(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update routine')),
        );
      }
    }
  }
}

// ── Day of Week Selector ───────────────────────────────

class _DayOfWeekSelector extends StatelessWidget {
  const _DayOfWeekSelector({
    required this.selectedDays,
    required this.isDark,
    required this.onChanged,
  });

  final Set<DayOfWeek> selectedDays;
  final bool isDark;
  final void Function(Set<DayOfWeek>) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DayOfWeek.values.map((day) {
        final isSelected = selectedDays.contains(day);
        return FilterChip(
          label: Text(day.shortName),
          selected: isSelected,
          selectedColor: isDark
              ? AppColors.primaryDark
              : AppColors.primaryLight,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight),
            fontSize: 13,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
          onSelected: (_) {
            final updated = Set<DayOfWeek>.from(selectedDays);
            if (isSelected) {
              updated.remove(day);
            } else {
              updated.add(day);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
