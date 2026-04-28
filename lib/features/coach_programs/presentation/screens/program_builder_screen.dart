import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../providers/program_builder_provider.dart';
import 'add_routine_sheet.dart';
import 'add_exercise_sheet.dart';
import 'edit_exercise_sheet.dart';
import 'edit_routine_sheet.dart';

/// Program Builder Wizard Screen
///
/// A 4-step wizard that creates/edits a client-specific training program:
///   Step 0 — Program Meta (name + description)
///   Step 1 — Routines (add/reorder/edit/delete)
///   Step 2 — Exercises per routine (add/edit/delete)
///   Step 3 — Review & Activate (read-only preview + date pickers)
///
/// Accepts [clientId] (required) and optional [programId] for edit mode.
class ProgramBuilderScreen extends ConsumerStatefulWidget {
  const ProgramBuilderScreen({
    super.key,
    required this.clientId,
    this.programId,
    this.clientName,
  });

  final String clientId;
  final String? programId;
  final String? clientName;

  @override
  ConsumerState<ProgramBuilderScreen> createState() =>
      _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _hasInitialised = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    final notifier = ref.read(programBuilderProvider(widget.clientId).notifier);
    if (widget.programId != null) {
      await notifier.loadExistingProgram(widget.programId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programBuilderProvider(widget.clientId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prefill controllers when program loads for the first time.
    if (!_hasInitialised && state is ProgramBuilderLoaded) {
      _nameController.text = state.program.name;
      _descriptionController.text = state.program.description;
      _hasInitialised = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.programId != null ? 'Edit Program' : 'Build Program',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(ProgramBuilderState state, bool isDark) {
    return switch (state) {
      ProgramBuilderInitial() => _buildMetaStep(null, isDark),
      ProgramBuilderLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ProgramBuilderError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () {
                if (widget.programId != null) {
                  ref
                      .read(programBuilderProvider(widget.clientId).notifier)
                      .loadExistingProgram(widget.programId!);
                }
              },
            ),
          ],
        ),
      ),
      ProgramBuilderLoaded(:final program, :final currentStep) => _buildStepper(
        program,
        currentStep,
        isDark,
      ),
    };
  }

  // ── Stepper ──────────────────────────────────────────

  Widget _buildStepper(
    ClientProgramModel program,
    int currentStep,
    bool isDark,
  ) {
    return Column(
      children: [
        // Step indicator
        _StepIndicator(
          currentStep: currentStep,
          labels: const ['Details', 'Routines', 'Exercises', 'Review'],
          isDark: isDark,
        ),
        // Step content
        Expanded(
          child: switch (currentStep) {
            0 => _buildMetaStep(program, isDark),
            1 => _buildRoutinesStep(program, isDark),
            2 => _buildExercisesStep(program, isDark),
            3 => _buildReviewStep(program, isDark),
            _ => _buildMetaStep(program, isDark),
          },
        ),
      ],
    );
  }

  // ── Step 0: Program Meta ─────────────────────────────

  Widget _buildMetaStep(ClientProgramModel? program, bool isDark) {
    final isCreating = program == null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isCreating ? 'Program Details' : 'Edit Program Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Give this program a name and description.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          controller: _nameController,
          label: 'Program Name',
          hint: 'e.g. 12-Week Strength Builder',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Briefly describe the program goals...',
          maxLines: 3,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: isCreating ? 'Create Program' : 'Save & Continue',
          icon: Icons.arrow_forward,
          iconPosition: IconPosition.trailing,
          isFullWidth: true,
          onPressed: () => _saveMetaStep(isCreating),
        ),
      ],
    );
  }

  Future<void> _saveMetaStep(bool isCreating) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    final notifier = ref.read(programBuilderProvider(widget.clientId).notifier);

    bool success;
    if (isCreating) {
      success = await notifier.createProgram(
        name: name,
        description: _descriptionController.text.trim(),
      );
    } else {
      success = await notifier.updateProgram(
        name: name,
        description: _descriptionController.text.trim(),
      );
      if (success) notifier.goToStep(1);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save program')));
    }
  }

  // ── Step 1: Routines ─────────────────────────────────

  Widget _buildRoutinesStep(ClientProgramModel program, bool isDark) {
    final sortedRoutines = [...program.routines]
      ..sort((a, b) => a.orderInProgram.compareTo(b.orderInProgram));

    return Column(
      children: [
        Expanded(
          child: sortedRoutines.isEmpty
              ? AppEmptyState.compact(
                  icon: Icons.calendar_today,
                  title: 'No Routines Yet',
                  description:
                      'Add routines from your template library or create new ones.',
                  actionLabel: 'Add routine',
                  onAction: () => _showAddRoutineSheet(program),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: sortedRoutines.length,
                  onReorder: (oldIndex, newIndex) => _reorderRoutine(
                    program,
                    sortedRoutines,
                    oldIndex,
                    newIndex,
                  ),
                  itemBuilder: (context, index) {
                    final routine = sortedRoutines[index];
                    return _RoutineCard(
                      key: ValueKey(routine.id),
                      routine: routine,
                      isDark: isDark,
                      onEdit: () => _showEditRoutineSheet(program, routine),
                      onDelete: () => _confirmDeleteRoutine(program, routine),
                    );
                  },
                ),
        ),
        // Bottom action bar
        _BottomActionBar(
          isDark: isDark,
          leading: AppButton.ghost(
            label: 'Back',
            icon: Icons.arrow_back,
            onPressed: () => ref
                .read(programBuilderProvider(widget.clientId).notifier)
                .goToStep(0),
          ),
          trailing: AppButton(
            label: 'Next: Exercises',
            icon: Icons.arrow_forward,
            iconPosition: IconPosition.trailing,
            isFullWidth: true,
            disabled: sortedRoutines.isEmpty,
            onPressed: () => ref
                .read(programBuilderProvider(widget.clientId).notifier)
                .goToStep(2),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          center: AppButton.outline(
            label: 'Add Routine',
            icon: Icons.add,
            isFullWidth: true,
            onPressed: () => _showAddRoutineSheet(program),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddRoutineSheet(ClientProgramModel program) async {
    final added = await showAddRoutineSheet(
      context: context,
      clientId: widget.clientId,
      programId: program.id,
      nextOrder: program.routines.length + 1,
    );
    if (added == true) {
      // Builder provider state already refreshed on success.
    }
  }

  Future<void> _showEditRoutineSheet(
    ClientProgramModel program,
    ProgramRoutineModel routine,
  ) async {
    await showEditRoutineSheet(
      context: context,
      clientId: widget.clientId,
      programId: program.id,
      routine: routine,
    );
  }

  Future<void> _confirmDeleteRoutine(
    ClientProgramModel program,
    ProgramRoutineModel routine,
  ) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Delete Routine',
      message:
          'Remove "${routine.name}" and all its exercises from this program?',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(programBuilderProvider(widget.clientId).notifier)
          .deleteRoutine(routine.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete routine')),
        );
      }
    }
  }

  void _reorderRoutine(
    ClientProgramModel program,
    List<ProgramRoutineModel> sortedRoutines,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final routine = sortedRoutines[oldIndex];
    // New order is 1-based
    final newOrder = newIndex + 1;
    ref
        .read(programBuilderProvider(widget.clientId).notifier)
        .updateRoutine(routine.id, orderInProgram: newOrder);
  }

  // ── Step 2: Exercises ────────────────────────────────

  Widget _buildExercisesStep(ClientProgramModel program, bool isDark) {
    final sortedRoutines = [...program.routines]
      ..sort((a, b) => a.orderInProgram.compareTo(b.orderInProgram));

    return Column(
      children: [
        Expanded(
          child: sortedRoutines.isEmpty
              ? AppEmptyState.compact(
                  icon: Icons.fitness_center,
                  title: 'No Routines',
                  description:
                      'Go back to the Routines step and add routines first.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: sortedRoutines.length,
                  itemBuilder: (context, index) {
                    final routine = sortedRoutines[index];
                    return _ExpandableRoutineExerciseCard(
                      routine: routine,
                      isDark: isDark,
                      onAddExercise: () =>
                          _showAddExerciseSheet(program, routine),
                      onEditExercise: (ex) =>
                          _showEditExerciseSheet(program, routine, ex),
                      onDeleteExercise: (ex) =>
                          _confirmDeleteExercise(program, routine, ex),
                    );
                  },
                ),
        ),
        _BottomActionBar(
          isDark: isDark,
          leading: AppButton.ghost(
            label: 'Back',
            icon: Icons.arrow_back,
            onPressed: () => ref
                .read(programBuilderProvider(widget.clientId).notifier)
                .goToStep(1),
          ),
          trailing: AppButton(
            label: 'Next: Review',
            icon: Icons.arrow_forward,
            iconPosition: IconPosition.trailing,
            onPressed: () => ref
                .read(programBuilderProvider(widget.clientId).notifier)
                .goToStep(3),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddExerciseSheet(
    ClientProgramModel program,
    ProgramRoutineModel routine,
  ) async {
    await showAddExerciseSheet(
      context: context,
      clientId: widget.clientId,
      programId: program.id,
      aprId: routine.id,
      nextOrder: routine.exercises.length + 1,
    );
  }

  Future<void> _showEditExerciseSheet(
    ClientProgramModel program,
    ProgramRoutineModel routine,
    ProgramRoutineExerciseModel exercise,
  ) async {
    await showEditExerciseSheet(
      context: context,
      clientId: widget.clientId,
      programId: program.id,
      aprId: routine.id,
      exercise: exercise,
    );
  }

  Future<void> _confirmDeleteExercise(
    ClientProgramModel program,
    ProgramRoutineModel routine,
    ProgramRoutineExerciseModel exercise,
  ) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Delete Exercise',
      message:
          'Remove "${exercise.exercise?.name ?? 'this exercise'}" from ${routine.name}?',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(programBuilderProvider(widget.clientId).notifier)
          .deleteExercise(routine.id, exercise.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete exercise')),
        );
      }
    }
  }

  // ── Step 3: Review & Activate ────────────────────────

  Widget _buildReviewStep(ClientProgramModel program, bool isDark) {
    final sortedRoutines = [...program.routines]
      ..sort((a, b) => a.orderInProgram.compareTo(b.orderInProgram));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Review Program',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Check everything looks good, then activate.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 20),

              // Program summary card
              AppCard.elevated(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            program.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        AppBadge(
                          label: program.isActive ? 'Active' : 'Draft',
                          variant: program.isActive
                              ? AppBadgeVariant.success
                              : AppBadgeVariant.secondary,
                        ),
                      ],
                    ),
                    if (program.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        program.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AppBadge(
                          label: '${program.routineCount} routines',
                          variant: AppBadgeVariant.info,
                        ),
                        const SizedBox(width: 8),
                        AppBadge(
                          label: '${program.totalExerciseCount} exercises',
                          variant: AppBadgeVariant.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date pickers
              _DatePickerRow(
                label: 'Start Date',
                date: program.startDate,
                isDark: isDark,
                onPick: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 8),
              _DatePickerRow(
                label: 'End Date',
                date: program.endDate,
                isDark: isDark,
                onPick: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 20),

              // Routines preview
              ...sortedRoutines.map(
                (routine) =>
                    _ReviewRoutineCard(routine: routine, isDark: isDark),
              ),
            ],
          ),
        ),
        _BottomActionBar(
          isDark: isDark,
          leading: AppButton.ghost(
            label: 'Back',
            icon: Icons.arrow_back,
            onPressed: () => ref
                .read(programBuilderProvider(widget.clientId).notifier)
                .goToStep(2),
          ),
          trailing: AppButton(
            label: program.isActive ? 'Save Changes' : 'Activate Program',
            icon: program.isActive ? Icons.check : Icons.rocket_launch,
            onPressed: () => _activateProgram(program),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;

    final dateStr = picked.toIso8601String();
    final notifier = ref.read(programBuilderProvider(widget.clientId).notifier);
    if (isStart) {
      await notifier.updateProgram(startDate: dateStr);
    } else {
      await notifier.updateProgram(endDate: dateStr);
    }
  }

  Future<void> _activateProgram(ClientProgramModel program) async {
    final notifier = ref.read(programBuilderProvider(widget.clientId).notifier);

    final success = await notifier.updateProgram(isActive: true);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              program.isActive ? 'Program updated!' : 'Program activated!',
            ),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to activate program')),
        );
      }
    }
  }
}

// ══════════════════════════════════════════════════════════
// INTERNAL WIDGETS
// ══════════════════════════════════════════════════════════

// ── Step Indicator ─────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.labels,
    required this.isDark,
  });

  final int currentStep;
  final List<String> labels;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(labels.length * 2 - 1, (index) {
          if (index.isEven) {
            final i = index ~/ 2;
            final isActive = i == currentStep;
            final isCompleted = i < currentStep;
            return GestureDetector(
              onTap: isCompleted || isActive ? null : null, // Navigation handled via buttons only
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                          : isCompleted
                          ? (isDark
                                ? AppColors.accentDark
                                : AppColors.accentLight)
                          : (isDark
                                ? AppColors.surface2Dark
                                : AppColors.surface2Light),
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.mutedForegroundDark
                                        : AppColors.mutedForegroundLight),
                              fontFamily: AppTextStyles.fontFamilySans,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive || isCompleted
                          ? (isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight)
                          : (isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight),
                      fontFamily: AppTextStyles.fontFamilySans,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          } else {
            final i = index ~/ 2;
            final isCompleted = i < currentStep;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 13.0),
                child: Container(
                  height: 2,
                  color: isCompleted
                      ? (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight)
                      : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}

// ── Bottom Action Bar ──────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.isDark,
    this.leading,
    this.trailing,
    this.center,
  });

  final bool isDark;
  final Widget? leading;
  final Widget? trailing;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (leading != null) leading!,
            if (center != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: center!,
                ),
              ),
            if (trailing != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: trailing!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Routine Card (Step 1) ──────────────────────────────

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    super.key,
    required this.routine,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgramRoutineModel routine;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Drag handle
                Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(routine.name, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: isDark ? AppColors.error : AppColors.errorLight,
                  ),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            // Day chips + duration
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (routine.daysOfWeek.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: routine.daysOfWeek.map((day) {
                        return Chip(
                          label: Text(
                            day.shortName,
                            style: const TextStyle(fontSize: 11),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (routine.estimatedDurationMinutes > 0)
                        Text(
                          '${routine.estimatedDurationMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      if (routine.estimatedDurationMinutes > 0 &&
                          routine.exercises.isNotEmpty)
                        Text(
                          '  ·  ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      if (routine.exercises.isNotEmpty)
                        Text(
                          '${routine.exercises.length} exercise${routine.exercises.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expandable Routine + Exercise Card (Step 2) ────────

class _ExpandableRoutineExerciseCard extends StatefulWidget {
  const _ExpandableRoutineExerciseCard({
    required this.routine,
    required this.isDark,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onDeleteExercise,
  });

  final ProgramRoutineModel routine;
  final bool isDark;
  final VoidCallback onAddExercise;
  final void Function(ProgramRoutineExerciseModel) onEditExercise;
  final void Function(ProgramRoutineExerciseModel) onDeleteExercise;

  @override
  State<_ExpandableRoutineExerciseCard> createState() =>
      _ExpandableRoutineExerciseCardState();
}

class _ExpandableRoutineExerciseCardState
    extends State<_ExpandableRoutineExerciseCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedExercises = [...widget.routine.exercises]
      ..sort((a, b) => a.orderInRoutine.compareTo(b.orderInRoutine));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.routine.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  AppBadge(
                    label: '${sortedExercises.length}',
                    variant: AppBadgeVariant.info,
                  ),
                ],
              ),
            ),

            // Exercises list
            if (_expanded) ...[
              const Divider(height: 16),
              if (sortedExercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No exercises yet. Tap "Add Exercise" below.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...sortedExercises.map(
                  (exercise) => _ExerciseRow(
                    exercise: exercise,
                    isDark: widget.isDark,
                    onEdit: () => widget.onEditExercise(exercise),
                    onDelete: () => widget.onDeleteExercise(exercise),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Exercise'),
                  onPressed: widget.onAddExercise,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Exercise Row ───────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgramRoutineExerciseModel exercise;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center,
            size: 16,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise?.name ?? 'Exercise',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${exercise.sets} sets × ${exercise.repsMin}-${exercise.repsMax} reps  ·  ${exercise.restSeconds}s rest',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Review Routine Card (Step 3) ───────────────────────

class _ReviewRoutineCard extends StatelessWidget {
  const _ReviewRoutineCard({required this.routine, required this.isDark});

  final ProgramRoutineModel routine;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedExercises = [...routine.exercises]
      ..sort((a, b) => a.orderInRoutine.compareTo(b.orderInRoutine));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(routine.name, style: theme.textTheme.titleMedium),
                ),
                if (routine.estimatedDurationMinutes > 0)
                  Text(
                    '${routine.estimatedDurationMinutes} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
              ],
            ),
            if (routine.daysOfWeek.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: routine.daysOfWeek.map((day) {
                  return Chip(
                    label: Text(
                      day.shortName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
            if (sortedExercises.isNotEmpty) ...[
              const Divider(height: 16),
              ...sortedExercises.map(
                (ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.exercise?.name ?? 'Exercise',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${ex.sets}×${ex.repsMin}-${ex.repsMax}  ${ex.restSeconds}s',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Date Picker Row ────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.isDark,
    required this.onPick,
  });

  final String label;
  final DateTime? date;
  final bool isDark;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(8),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                  Text(
                    date != null
                        ? '${date!.month}/${date!.day}/${date!.year}'
                        : 'Not set',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ],
        ),
      ),
    );
  }
}
