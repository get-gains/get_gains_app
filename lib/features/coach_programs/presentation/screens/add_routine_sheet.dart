import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../providers/coach_routine_provider.dart';
import '../providers/program_builder_provider.dart';

/// Shows a bottom sheet to add a routine to a client's program.
///
/// Two paths:
///   - **From Template** — pick from the coach's routine template library.
///   - **Build New** — create an inline routine with name/description/duration.
///
/// Returns `true` if a routine was added, `null`/`false` otherwise.
Future<bool?> showAddRoutineSheet({
  required BuildContext context,
  required String clientId,
  required String programId,
  required int nextOrder,
}) async {
  return showAppBottomSheet<bool>(
    context: context,
    builder: (ctx) => _AddRoutineSheet(
      clientId: clientId,
      programId: programId,
      nextOrder: nextOrder,
    ),
  );
}

class _AddRoutineSheet extends ConsumerStatefulWidget {
  const _AddRoutineSheet({
    required this.clientId,
    required this.programId,
    required this.nextOrder,
  });

  final String clientId;
  final String programId;
  final int nextOrder;

  @override
  ConsumerState<_AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends ConsumerState<_AddRoutineSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Inline form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final Set<DayOfWeek> _selectedDays = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load routine templates
    Future.microtask(
      () => ref.read(coachRoutinesProvider.notifier).loadRoutines(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          const AppBottomSheetHeader(title: 'Add Routine'),
          TabBar(
            controller: _tabController,
            labelColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            unselectedLabelColor: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
            indicatorColor: isDark
                ? AppColors.primaryDark
                : AppColors.primaryLight,
            tabs: const [
              Tab(text: 'From Template'),
              Tab(text: 'Build New'),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: TabBarView(
              controller: _tabController,
              children: [_buildTemplateTab(isDark), _buildInlineTab(isDark)],
            ),
          ),
        ],
      ),
    );
  }

  // ── Template Tab ─────────────────────────────────────

  Widget _buildTemplateTab(bool isDark) {
    final routinesState = ref.watch(coachRoutinesProvider);

    return switch (routinesState) {
      CoachRoutinesInitial() || CoachRoutinesLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      CoachRoutinesError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppButton(
              label: 'Retry',
              size: AppButtonSize.sm,
              onPressed: () =>
                  ref.read(coachRoutinesProvider.notifier).loadRoutines(),
            ),
          ],
        ),
      ),
      CoachRoutinesLoaded(:final routines) =>
        routines.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No routine templates yet.\nSwitch to "Build New" to create one inline.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final template = routines[index];
                  return _TemplateRoutineRow(
                    template: template,
                    isDark: isDark,
                    onSelect: () => _pickTemplate(template),
                  );
                },
              ),
    };
  }

  Future<void> _pickTemplate(RoutineSummaryModel template) async {
    // Show a day-of-week picker before adding
    final days = await _showDayPicker();
    if (days == null || !mounted) return;

    setState(() => _isSaving = true);

    final success = await ref
        .read(programBuilderProvider(widget.clientId).notifier)
        .addRoutineFromTemplate(
          sourceRoutineId: template.id,
          daysOfWeek: days,
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

  // ── Inline Tab ───────────────────────────────────────

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
        .read(programBuilderProvider(widget.clientId).notifier)
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

  // ── Day Picker Dialog ────────────────────────────────

  Future<List<DayOfWeek>?> _showDayPicker() async {
    final selected = <DayOfWeek>{};

    return showDialog<List<DayOfWeek>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Select Days'),
          content: _DayOfWeekSelector(
            selectedDays: selected,
            isDark: Theme.of(ctx).brightness == Brightness.dark,
            onChanged: (days) => setDialogState(() {
              selected
                ..clear()
                ..addAll(days);
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(selected.toList()),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Template Routine Row ───────────────────────────────

class _TemplateRoutineRow extends StatelessWidget {
  const _TemplateRoutineRow({
    required this.template,
    required this.isDark,
    required this.onSelect,
  });

  final RoutineSummaryModel template;
  final bool isDark;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard.elevated(
        onTap: onSelect,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: theme.textTheme.titleSmall),
                  if (template.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${template.estimatedDurationMinutes} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ],
        ),
      ),
    );
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
