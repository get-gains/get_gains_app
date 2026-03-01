import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_request_models.dart';
import '../providers/coach_assignment_provider.dart';
import '../providers/coach_program_provider.dart';

/// Shows a bottom sheet to assign a program to a client.
///
/// Returns `true` if a program was successfully assigned.
Future<bool?> showAssignProgramSheet({
  required BuildContext context,
  required String userId,
  String? userName,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _AssignProgramSheetContent(userId: userId, userName: userName),
  );
}

class _AssignProgramSheetContent extends ConsumerStatefulWidget {
  const _AssignProgramSheetContent({required this.userId, this.userName});

  final String userId;
  final String? userName;

  @override
  ConsumerState<_AssignProgramSheetContent> createState() =>
      _AssignProgramSheetContentState();
}

class _AssignProgramSheetContentState
    extends ConsumerState<_AssignProgramSheetContent> {
  String? _selectedProgramId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure programs list is loaded
    final programsState = ref.read(coachProgramsProvider);
    if (programsState is CoachProgramsInitial) {
      Future.microtask(
        () => ref.read(coachProgramsProvider.notifier).loadPrograms(),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final programsState = ref.watch(coachProgramsProvider);

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
            Text('Assign Program', style: theme.textTheme.headlineSmall),
            if (widget.userName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Assign a program to ${widget.userName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Program selector
            Text('Select Program', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildProgramDropdown(programsState, isDark, theme),
            const SizedBox(height: 16),

            // Start date
            _DatePickerField(
              label: 'Start Date',
              value: _startDate,
              onChanged: (date) => setState(() => _startDate = date),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // End date (optional)
            _DatePickerField(
              label: 'End Date (optional)',
              value: _endDate,
              onChanged: (date) => setState(() => _endDate = date),
              isDark: isDark,
              firstDate: _startDate,
            ),
            const SizedBox(height: 12),

            // Notes
            AppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'e.g. Focus on form this cycle',
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
      ),
    );
  }

  Widget _buildProgramDropdown(
    CoachProgramsState state,
    bool isDark,
    ThemeData theme,
  ) {
    if (state is CoachProgramsLoading || state is CoachProgramsInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    final programs = state is CoachProgramsLoaded
        ? state.programs
        : <ProgramSummaryModel>[];

    if (programs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface1Dark : AppColors.mutedLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No programs available. Create a program first.',
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
          value: _selectedProgramId,
          isExpanded: true,
          hint: Text(
            'Choose a program...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
          dropdownColor: isDark ? AppColors.surface2Dark : AppColors.cardLight,
          items: programs.map((p) {
            return DropdownMenuItem(
              value: p.id,
              child: Text(p.name, style: theme.textTheme.bodyMedium),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedProgramId = value);
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedProgramId == null) {
      AppToast.warning(context, 'Please select a program');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(clientAssignmentsProvider(widget.userId).notifier)
          .assignProgram(
            AssignProgramRequest(
              userId: widget.userId,
              programId: _selectedProgramId!,
              startDate: DateTime.utc(
                _startDate.year,
                _startDate.month,
                _startDate.day,
              ).toIso8601String(),
              endDate: _endDate != null
                  ? DateTime.utc(
                      _endDate!.year,
                      _endDate!.month,
                      _endDate!.day,
                    ).toIso8601String()
                  : null,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );

      if (mounted) {
        if (success) {
          AppToast.success(context, 'Program assigned');
          Navigator.of(context).pop(true);
        } else {
          AppToast.error(context, 'Failed to assign program');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Date Picker Field
// ──────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.firstDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool isDark;
  final DateTime? firstDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate:
                  firstDate ??
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.inputDark : AppColors.inputLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 12),
                Text(
                  value != null
                      ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
                      : 'Not set',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: value != null
                        ? null
                        : (isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
