import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../providers/standalone_program_provider.dart';
import '../providers/standalone_routine_provider.dart';

/// Shows a bottom sheet to assign a standalone routine to a program day-slot.
///
/// Returns `true` if a routine was successfully assigned, `false`/`null` otherwise.
Future<bool?> showStandaloneAssignRoutineSheet({
  required BuildContext context,
  required String programId,
  required List<int> existingDayNumbers,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AssignRoutineSheetContent(
      programId: programId,
      existingDayNumbers: existingDayNumbers,
    ),
  );
}

class _AssignRoutineSheetContent extends ConsumerStatefulWidget {
  const _AssignRoutineSheetContent({
    required this.programId,
    required this.existingDayNumbers,
  });

  final String programId;
  final List<int> existingDayNumbers;

  @override
  ConsumerState<_AssignRoutineSheetContent> createState() =>
      _AssignRoutineSheetContentState();
}

class _AssignRoutineSheetContentState
    extends ConsumerState<_AssignRoutineSheetContent> {
  final _dayController = TextEditingController();
  String? _selectedRoutineId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Suggest next day number
    final maxDay = widget.existingDayNumbers.isEmpty
        ? 0
        : widget.existingDayNumbers.reduce((a, b) => a > b ? a : b);
    _dayController.text = '${maxDay + 1}';

    // Ensure routines list is loaded
    final routinesState = ref.read(standaloneRoutinesProvider);
    if (routinesState is StandaloneRoutinesInitial) {
      Future.microtask(
        () => ref.read(standaloneRoutinesProvider.notifier).loadRoutines(),
      );
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final routinesState = ref.watch(standaloneRoutinesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Assign Routine to Day', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Choose a routine and assign it to a day number in this program.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 20),

          // Routine selector
          Text('Select Routine', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildRoutineDropdown(routinesState, isDark, theme),
          const SizedBox(height: 16),

          // Day number input
          AppTextField(
            controller: _dayController,
            label: 'Day Number',
            hint: '1',
            keyboardType: TextInputType.number,
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
                  label: 'Assign',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineDropdown(
    StandaloneRoutinesState state,
    bool isDark,
    ThemeData theme,
  ) {
    if (state is StandaloneRoutinesLoading ||
        state is StandaloneRoutinesInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    final routines = state is StandaloneRoutinesLoaded
        ? state.routines
        : <StandaloneRoutineSummaryModel>[];

    if (routines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface1Dark : AppColors.mutedLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No routines available. Create a routine first.',
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
          value: _selectedRoutineId,
          isExpanded: true,
          hint: Text(
            'Choose a routine...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          dropdownColor: isDark ? AppColors.surface2Dark : AppColors.cardLight,
          items: routines.map((r) {
            return DropdownMenuItem(
              value: r.id,
              child: Text(r.name, style: theme.textTheme.bodyMedium),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedRoutineId = value);
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedRoutineId == null) {
      AppToast.warning(context, 'Please select a routine');
      return;
    }

    final dayNumber = int.tryParse(_dayController.text.trim());
    if (dayNumber == null || dayNumber < 1) {
      AppToast.warning(context, 'Enter a valid day number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(standaloneProgramDetailProvider(widget.programId).notifier)
          .assignRoutine(
            AssignStandaloneRoutineRequest(
              routineId: _selectedRoutineId!,
              dayNumber: dayNumber,
            ),
          );

      if (mounted) {
        if (success) {
          AppToast.success(context, 'Routine assigned to Day $dayNumber');
          Navigator.of(context).pop(true);
        } else {
          AppToast.error(context, 'Failed to assign routine');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
