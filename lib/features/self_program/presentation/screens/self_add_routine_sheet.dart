import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../../coach_programs/data/models/program_model.dart';
import '../providers/self_program_builder_provider.dart';

/// Shows a bottom sheet to add an inline routine to a program.
///
/// Returns `true` if a routine was added, `null`/`false` otherwise.
Future<bool?> showSelfAddRoutineSheet({
  required BuildContext context,
  required String programId,
  required int nextOrder,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (ctx) => _SelfAddRoutineSheet(
      programId: programId,
      nextOrder: nextOrder,
    ),
  );
}

class _SelfAddRoutineSheet extends ConsumerStatefulWidget {
  const _SelfAddRoutineSheet({
    required this.programId,
    required this.nextOrder,
  });

  final String programId;
  final int nextOrder;

  @override
  ConsumerState<_SelfAddRoutineSheet> createState() => _SelfAddRoutineSheetState();
}

class _SelfAddRoutineSheetState extends ConsumerState<_SelfAddRoutineSheet> {
  // Inline form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final Set<DayOfWeek> _selectedDays = {};

  bool _isSaving = false;

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
          const AppBottomSheetHeader(title: 'Build New Routine'),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: _buildInlineTab(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
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
          hint: '45',
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
          label: 'Add Routine',
          icon: Icons.add,
          isFullWidth: true,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveInline,
        ),
      ],
    );
  }

  Future<void> _saveInline() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Routine name is required')));
      return;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 45;

    setState(() => _isSaving = true);

    final success = await ref
        .read(selfProgramBuilderProvider.notifier)
        .addRoutineInline(
          name: name,
          description: _descriptionController.text.trim(),
          estimatedDurationMinutes: duration,
          daysOfWeek: _selectedDays.toList(),
          orderInProgram: widget.nextOrder,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add routine')));
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
