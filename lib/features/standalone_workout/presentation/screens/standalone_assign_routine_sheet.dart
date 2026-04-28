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
  required List<DayOfWeek> assignedDays,
  DayOfWeek? initialDay,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AssignRoutineSheetContent(
      programId: programId,
      assignedDays: assignedDays,
      initialDay: initialDay,
    ),
  );
}

class _AssignRoutineSheetContent extends ConsumerStatefulWidget {
  const _AssignRoutineSheetContent({
    required this.programId,
    required this.assignedDays,
    this.initialDay,
  });

  final String programId;
  final List<DayOfWeek> assignedDays;
  final DayOfWeek? initialDay;

  @override
  ConsumerState<_AssignRoutineSheetContent> createState() =>
      _AssignRoutineSheetContentState();
}

class _AssignRoutineSheetContentState
    extends ConsumerState<_AssignRoutineSheetContent> {
  String? _selectedRoutineId;
  DayOfWeek? _selectedDay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final initialDay = widget.initialDay;
    if (initialDay != null && !widget.assignedDays.contains(initialDay)) {
      _selectedDay = initialDay;
    }

    // Ensure routines list is loaded
    final routinesState = ref.read(standaloneRoutinesProvider);
    if (routinesState is StandaloneRoutinesInitial) {
      Future.microtask(
        () => ref.read(standaloneRoutinesProvider.notifier).loadRoutines(),
      );
    }
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Assign Routine to Day', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Pick a day of the week and choose a routine for that day.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 20),

          // Day of week chip selector
          Text('Select Day', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          _buildDaySelector(isDark, theme),
          const SizedBox(height: 20),

          // Routine selector
          Text('Select Routine', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildRoutineDropdown(routinesState, isDark, theme),
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

  Widget _buildDaySelector(bool isDark, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DayOfWeek.values.map((day) {
        final isAssigned = widget.assignedDays.contains(day);
        final isSelected = _selectedDay == day;

        return GestureDetector(
          onTap: isAssigned ? null : () => setState(() => _selectedDay = day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : isAssigned
                  ? (isDark ? AppColors.surface1Dark : AppColors.mutedLight)
                  : (isDark ? AppColors.inputDark : AppColors.inputLight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isAssigned
                    ? Colors.transparent
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day.shortName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : isAssigned
                        ? (isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight)
                        : null,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isAssigned) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Taken',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
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
    if (_selectedDay == null) {
      AppToast.warning(context, 'Please select a day');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(standaloneProgramDetailProvider(widget.programId).notifier)
          .assignRoutine(
            AssignStandaloneRoutineRequest(
              routineId: _selectedRoutineId!,
              dayOfWeek: _selectedDay!,
            ),
          );

      if (mounted) {
        if (success) {
          AppToast.success(
            context,
            'Routine assigned to ${_selectedDay!.displayName}',
          );
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
