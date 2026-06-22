import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_toast.dart';
import '../../data/models/models.dart';
import '../providers/standalone_program_builder_provider.dart';

/// Standalone Program Builder Screen
///
/// A 4-step wizard for free-tier users to build their own workout program:
///   Step 0 — Program Meta (name + description)
///   Step 1 — Routines (add/delete)
///   Step 2 — Exercises per routine (add/edit/delete)
///   Step 3 — Review & Activate
class StandaloneProgramBuilderScreen extends ConsumerStatefulWidget {
  const StandaloneProgramBuilderScreen({super.key, this.programId});

  final String? programId;

  @override
  ConsumerState<StandaloneProgramBuilderScreen> createState() =>
      _StandaloneProgramBuilderScreenState();
}

class _StandaloneProgramBuilderScreenState
    extends ConsumerState<StandaloneProgramBuilderScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _hasInitialised = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    if (widget.programId != null) {
      await ref
          .read(standaloneProgramBuilderProvider.notifier)
          .loadExistingProgram(widget.programId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standaloneProgramBuilderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_hasInitialised &&
        state is StandaloneProgramBuilderLoaded) {
      _nameController.text = state.program.name;
      _descriptionController.text = state.program.description;
      _hasInitialised = true;
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.programId != null ? 'Edit Program' : 'Build Program',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(StandaloneProgramBuilderState state, bool isDark) {
    return switch (state) {
      StandaloneProgramBuilderInitial() => _buildMetaStep(isDark),
      StandaloneProgramBuilderLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      StandaloneProgramBuilderError(:final error) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          description: error.message,
          actionLabel: 'Retry',
          onAction: () => _init(),
        ),
      StandaloneProgramBuilderLoaded(:final program, :final currentStep) =>
        _buildStepContent(program, currentStep, isDark),
    };
  }

  // ── Step Content Router ────────────────────────────────

  Widget _buildStepContent(
    StandaloneProgramDetail program,
    int step,
    bool isDark,
  ) {
    return switch (step) {
      0 => _buildMetaStep(isDark),
      1 => _buildRoutinesStep(program, isDark),
      2 => _buildExercisesStep(program, isDark),
      3 => _buildReviewStep(program, isDark),
      _ => _buildMetaStep(isDark),
    };
  }

  // ── Step 0: Program Meta ───────────────────────────────

  Widget _buildMetaStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Name Your Program',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: AppTextStyles.fontFamilySans,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Give it a name that helps you remember the focus.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Program Name',
              hintText: 'e.g. Push Day, Leg Day, Full Body',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What does this program focus on?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            label: 'Next',
            icon: Icons.arrow_forward,
            iconPosition: IconPosition.trailing,
            isFullWidth: true,
            onPressed: _onMetaSubmit,
          ),
        ],
      ),
    );
  }

  Future<void> _onMetaSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Please enter a program name');
      return;
    }

    final notifier = ref.read(standaloneProgramBuilderProvider.notifier);
    final success = await notifier.createProgram(
      name: name,
      description: _descriptionController.text.trim(),
    );

    if (success && mounted) {
      notifier.goToStep(1);
    }
  }

  // ── Step 1: Routines ───────────────────────────────────

  Widget _buildRoutinesStep(StandaloneProgramDetail program, bool isDark) {
    final routines = program.routines;

    return Column(
      children: [
        Expanded(
          child: routines.isEmpty
              ? AppEmptyState(
                  icon: Icons.fitness_center,
                  title: 'No Routines',
                  description:
                      'Add routines to your program. Each routine is a day\'s workout.',
                  actionLabel: 'Add Routine',
                  onAction: () => _showAddRoutineDialog(program),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routines.length + 1,
                  itemBuilder: (context, index) {
                    if (index == routines.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AppButton.outline(
                          label: 'Add Routine',
                          icon: Icons.add,
                          isFullWidth: true,
                          onPressed: () => _showAddRoutineDialog(program),
                        ),
                      );
                    }

                    final routine = routines[index];
                    final exerciseCount = routine.exercises.length;
                    final primaryColor =
                        isDark ? AppColors.primaryDark : AppColors.primaryLight;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard.elevated(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    routine.routineName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '$exerciseCount exercises',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () =>
                                  _deleteRoutine(program, routine.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildBottomNav(program, program.routines.isEmpty ? 1 : 1, isDark),
      ],
    );
  }

  Future<void> _showAddRoutineDialog(StandaloneProgramDetail program) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _BuilderAddRoutineDialog(),
    );

    if (result != null && mounted) {
      final notifier = ref.read(standaloneProgramBuilderProvider.notifier);
      final success = await notifier.createAndAddRoutine(
        name: result['name']!,
        description: result['description']!,
        orderInProgram: program.routines.length + 1,
      );
      if (success && mounted) {
        AppToast.success(context, 'Routine added');
      } else if (mounted) {
        AppToast.error(context, 'Failed to create routine');
      }
    }
  }

  Future<void> _deleteRoutine(
      StandaloneProgramDetail program, String routineId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: const Text('This will also remove all exercises in this routine.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(standaloneProgramBuilderProvider.notifier);
      final success = await notifier.deleteRoutine(routineId);
      if (success) {
        AppToast.success(context, 'Routine deleted');
      }
    }
  }

  // ── Step 2: Exercises ──────────────────────────────────

  Widget _buildExercisesStep(StandaloneProgramDetail program, bool isDark) {
    final routines = program.routines;
    if (routines.isEmpty) {
      return AppEmptyState(
        icon: Icons.fitness_center,
        title: 'No Routines',
        description: 'Add a routine first before adding exercises.',
        actionLabel: 'Go Back',
        onAction: () =>
            ref.read(standaloneProgramBuilderProvider.notifier).goToStep(1),
      );
    }

    final exerciseCount =
        routines.fold<int>(0, (sum, r) => sum + r.exercises.length);
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: AppTextStyles.fontFamilySans,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '$exerciseCount total',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: routines.length,
            itemBuilder: (context, rIndex) {
              final routine = routines[rIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          routine.routineName,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Exercise'),
                        onPressed: () =>
                            _showAddExerciseDialog(program, routine.routineId),
                      ),
                    ],
                  ),
                  if (routine.exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16),
                      child: Text(
                        'No exercises added yet',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...routine.exercises.map((ex) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard.elevated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ex.exerciseName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ),
                              Text(
                                '${ex.sets}x${ex.repsMin}-${ex.repsMax}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: primaryColor,
                                      fontFamily:
                                          AppTextStyles.fontFamilyMono,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteExercise(
                                  program,
                                  routine.id,
                                  ex.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),

        _buildBottomNav(program, 2, isDark),
      ],
    );
  }

  Future<void> _showAddExerciseDialog(
    StandaloneProgramDetail program,
    String routineId,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _BuilderAddExerciseDialog(),
    );

    if (result != null && mounted) {
      final notifier = ref.read(standaloneProgramBuilderProvider.notifier);
      final routineExercises = program.routines
          .firstWhere((r) => r.routineId == routineId)
          .exercises;

      final success = await notifier.createAndAddExercise(
        routineId: routineId,
        name: result['name'] as String,
        description: result['name'] as String,
        sets: result['sets'] as int,
        repsMin: result['repsMin'] as int,
        repsMax: result['repsMax'] as int,
        restSeconds: result['rest'] as int,
        orderInRoutine: routineExercises.length + 1,
      );
      if (success && mounted) {
        AppToast.success(context, 'Exercise added');
      } else if (mounted) {
        AppToast.error(context, 'Failed to create exercise');
      }
    }
  }

  Future<void> _deleteExercise(
    StandaloneProgramDetail program,
    String routineId,
    String exerciseId,
  ) async {
    final notifier = ref.read(standaloneProgramBuilderProvider.notifier);
    final success = await notifier.deleteExercise(routineId, exerciseId);
    if (success && mounted) {
      AppToast.success(context, 'Exercise removed');
    }
  }

  // ── Step 3: Review ─────────────────────────────────────

  Widget _buildReviewStep(StandaloneProgramDetail program, bool isDark) {
    final routines = program.routines;
    final totalExercises =
        routines.fold<int>(0, (sum, r) => sum + r.exercises.length);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program header
                AppCard.elevated(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontFamily: AppTextStyles.fontFamilySans,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (program.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          program.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AppBadge(
                            label: '${routines.length} routines',
                            variant: AppBadgeVariant.info,
                          ),
                          const SizedBox(width: 8),
                          AppBadge(
                            label: '$totalExercises exercises',
                            variant: AppBadgeVariant.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Routine list
                Text(
                  'Routines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: AppTextStyles.fontFamilySans,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),

                if (routines.isEmpty)
                  AppEmptyState(
                    icon: Icons.fitness_center,
                    title: 'No Routines',
                    description: 'Go back and add routines.',
                  )
                else
                  ...routines.asMap().entries.map((entry) {
                    final rIndex = entry.key;
                    final routine = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard.elevated(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${rIndex + 1}',
                                    style: TextStyle(
                                      fontFamily:
                                          AppTextStyles.fontFamilyMono,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    routine.routineName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                ),
                                AppBadge(
                                  label:
                                      '${routine.exercises.length} exercises',
                                  variant: AppBadgeVariant.info,
                                ),
                              ],
                            ),
                            if (routine.exercises.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...routine.exercises.map((ex) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 44, bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ex.exerciseName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        '${ex.sets}x${ex.repsMin}-${ex.repsMax}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontFamily:
                                                  AppTextStyles.fontFamilyMono,
                                              color: isDark
                                                  ? AppColors
                                                      .mutedForegroundDark
                                                  : AppColors
                                                      .mutedForegroundLight,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        _buildBottomNav(program, 3, isDark),
      ],
    );
  }

  // ── Bottom Navigation ──────────────────────────────────

  Widget _buildBottomNav(
    StandaloneProgramDetail program,
    int currentStep,
    bool isDark,
  ) {
    final notifier = ref.read(standaloneProgramBuilderProvider.notifier);
    final canGoNext =
        currentStep < 3 && (currentStep != 1 || program.routines.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep > 1)
              Expanded(
                child: AppButton.outline(
                  label: 'Back',
                  icon: Icons.arrow_back,
                  onPressed: () => notifier.goToStep(currentStep - 1),
                ),
              ),
            if (currentStep > 1) const SizedBox(width: 12),
            if (canGoNext)
              Expanded(
                child: AppButton.primary(
                  label: currentStep == 2 ? 'Review' : 'Next',
                  icon: Icons.arrow_forward,
                  iconPosition: IconPosition.trailing,
                  onPressed: () => notifier.goToStep(currentStep + 1),
                ),
              ),
            if (currentStep == 3)
              Expanded(
                child: AppButton.primary(
                  label: 'Finish',
                  icon: Icons.check,
                  onPressed: () {
                    AppToast.success(context, 'Program built!');
                    context.pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuilderAddRoutineDialog extends StatefulWidget {
  const _BuilderAddRoutineDialog();

  @override
  State<_BuilderAddRoutineDialog> createState() =>
      _BuilderAddRoutineDialogState();
}

class _BuilderAddRoutineDialogState extends State<_BuilderAddRoutineDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isNotEmpty) {
      Navigator.pop(context, {'name': name, 'description': desc});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Routine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                hintText: 'e.g. Upper Body, Leg Day',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _BuilderAddExerciseDialog extends StatefulWidget {
  const _BuilderAddExerciseDialog();

  @override
  State<_BuilderAddExerciseDialog> createState() =>
      _BuilderAddExerciseDialogState();
}

class _BuilderAddExerciseDialogState extends State<_BuilderAddExerciseDialog> {
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '8-12');
  final _restController = TextEditingController(text: '60');

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final sets = int.tryParse(_setsController.text) ?? 3;

    final repsParts = _repsController.text.trim().split('-');
    final repsMin = int.tryParse(repsParts[0]) ?? 8;
    final repsMax = repsParts.length > 1
        ? (int.tryParse(repsParts[1]) ?? repsMin)
        : repsMin;

    final rest = int.tryParse(_restController.text) ?? 60;

    if (name.isNotEmpty) {
      Navigator.pop(context, {
        'name': name,
        'sets': sets,
        'repsMin': repsMin,
        'repsMax': repsMax,
        'rest': rest,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Exercise'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g. Bench Press',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      hintText: '8-12',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rest (seconds)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
