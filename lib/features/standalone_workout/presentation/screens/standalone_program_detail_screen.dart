import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_toast.dart';
import '../../data/helpers/model_conversion.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';
import '../providers/standalone_program_provider.dart';

class StandaloneProgramDetailScreen extends ConsumerStatefulWidget {
  const StandaloneProgramDetailScreen({
    super.key,
    required this.programId,
  });

  final String programId;

  @override
  ConsumerState<StandaloneProgramDetailScreen> createState() =>
      _StandaloneProgramDetailScreenState();
}

class _StandaloneProgramDetailScreenState
    extends ConsumerState<StandaloneProgramDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programAsync = ref.watch(
      standaloneProgramDetailProvider(widget.programId),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Program'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(
              '${AppRoutes.standaloneProgramBuilder}?programId=${widget.programId}',
            ),
            tooltip: 'Edit Program',
          ),
        ],
      ),
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          description: error.toString(),
          actionLabel: 'Retry',
          onAction: () =>
              ref.invalidate(standaloneProgramDetailProvider(widget.programId)),
        ),
        data: (program) {
          final routines = program.routines;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Program header
              AppCard.elevated(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: AppTextStyles.fontFamilySans,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (program.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        program.description,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AppBadge(
                          label: '${routines.length} routines',
                          variant: AppBadgeVariant.info,
                        ),
                        const SizedBox(width: 8),
                        if (program.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Routines header
              Row(
                children: [
                  Text(
                    'Routines',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: AppTextStyles.fontFamilySans,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Routine'),
                    onPressed: () => _showAddRoutineDialog(program),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (routines.isEmpty)
                AppEmptyState(
                  icon: Icons.fitness_center,
                  title: 'No Routines',
                  description:
                      'Add routines to your program to get started.',
                  actionLabel: 'Add Routine',
                  onAction: () => _showAddRoutineDialog(program),
                )
              else
                ...routines.asMap().entries.map((entry) {
                  final routine = entry.value;
                  return _RoutineBlock(
                    routine: routine,
                    isDark: isDark,
                    programId: program.id,
                    onPerform: () => _performWorkout(program, routine),
                    onAddExercise: () =>
                        _showAddExerciseDialog(program, routine.routineId),
                    onDeleteRoutine: () =>
                        _deleteRoutine(program, routine.id),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performWorkout(
    StandaloneProgramDetail program,
    StandaloneProgramRoutine routine,
  ) async {
    final userId = ref.read(authStateProvider).userId;
    if (userId == null || userId.isEmpty) {
      AppToast.error(context, 'User not authenticated');
      return;
    }

    final repo = ref.read(standaloneWorkoutRepositoryProvider);

    final activeResult = await repo.resumeActiveSession();
    activeResult.when(
      success: (resumeData) {
        if (resumeData != null && mounted) {
          context.push(
            AppRoutes.standaloneWorkout,
            extra: <String, dynamic>{
              'session': resumeData.session,
              'exercises': resumeData.exercises,
              'routineName': resumeData.routineName,
            },
          );
          return;
        }

        _startNewSession(repo, userId, routine);
      },
      failure: (_) {
        _startNewSession(repo, userId, routine);
      },
    );
  }

  Future<void> _startNewSession(
    StandaloneWorkoutRepository repo,
    String userId,
    StandaloneProgramRoutine routine,
  ) async {
    final result = await repo.startWorkoutSession(
      userId: userId,
      programRoutineId: routine.id,
    );

    result.when(
      success: (session) {
        if (mounted) {
          context.push(
            AppRoutes.standaloneWorkout,
            extra: <String, dynamic>{
              'session': session,
              'exercises': routine.exercises
                  .map((e) => e.toRoutineExerciseModel())
                  .toList(),
              'routineName': routine.routineName,
            },
          );
        }
      },
      failure: (error) {
        if (mounted) {
          AppToast.error(context, 'Failed to start workout: ${error.message}');
        }
      },
    );
  }

  Future<void> _showAddRoutineDialog(StandaloneProgramDetail program) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _AddRoutineDialog(),
    );

    if (result != null && mounted) {
      final repo = ref.read(standaloneWorkoutRepositoryProvider);
      final createResult = await repo.createRoutine(
        name: result['name']!,
        description: result['description']!,
      );
      createResult.when(
        success: (routineId) async {
          final addResult = await repo.addProgramRoutine(
            widget.programId,
            AddProgramRoutineRequest(
              routineId: routineId,
              orderInProgram: program.routines.length + 1,
            ),
          );
          addResult.when(
            success: (_) {
              ref.invalidate(
                  standaloneProgramDetailProvider(widget.programId));
              ref.invalidate(standaloneProgramListProvider);
              AppToast.success(context, 'Routine added');
            },
            failure: (error) {
              AppToast.error(
                  context, 'Failed to add routine: ${error.message}');
            },
          );
        },
        failure: (error) {
          AppToast.error(
              context, 'Failed to create routine: ${error.message}');
        },
      );
    }
  }

  Future<void> _showAddExerciseDialog(
    StandaloneProgramDetail program,
    String routineId,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _AddExerciseDialog(),
    );

    if (result != null && mounted) {
      final repo = ref.read(standaloneWorkoutRepositoryProvider);
      final routineExercises = program.routines
          .firstWhere((r) => r.routineId == routineId)
          .exercises;

      final createExerciseResult = await repo.createExercise(
        name: result['name'] as String,
        description: result['name'] as String,
      );
      createExerciseResult.when(
        success: (exerciseId) async {
          final addResult = await repo.addRoutineExercise(
            routineId,
            AddRoutineExerciseRequest(
              exerciseId: exerciseId,
              sets: result['sets'] as int,
              repsMin: result['repsMin'] as int,
              repsMax: result['repsMax'] as int,
              restSeconds: result['rest'] as int,
              orderInRoutine: routineExercises.length + 1,
            ),
          );

          addResult.when(
            success: (_) {
              ref.invalidate(
                  standaloneProgramDetailProvider(widget.programId));
              ref.invalidate(standaloneProgramListProvider);
              AppToast.success(context, 'Exercise added');
            },
            failure: (error) {
              AppToast.error(
                  context, 'Failed to add exercise: ${error.message}');
            },
          );
        },
        failure: (error) {
          AppToast.error(
              context, 'Failed to create exercise: ${error.message}');
        },
      );
    }
  }

  Future<void> _deleteRoutine(
    StandaloneProgramDetail program,
    String routineId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine?'),
        content:
            const Text('This will also remove all exercises in this routine.'),
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
      final repo = ref.read(standaloneWorkoutRepositoryProvider);
      final result = await repo.deleteProgramRoutine(program.id, routineId);
      result.when(
        success: (_) {
          ref.invalidate(standaloneProgramDetailProvider(widget.programId));
          ref.invalidate(standaloneProgramListProvider);
          AppToast.success(context, 'Routine deleted');
        },
        failure: (error) {
          AppToast.error(context, 'Failed to delete routine: ${error.message}');
        },
      );
    }
  }
}

class _RoutineBlock extends StatelessWidget {
  const _RoutineBlock({
    required this.routine,
    required this.isDark,
    required this.programId,
    required this.onPerform,
    required this.onAddExercise,
    required this.onDeleteRoutine,
  });

  final StandaloneProgramRoutine routine;
  final bool isDark;
  final String programId;
  final VoidCallback onPerform;
  final VoidCallback onAddExercise;
  final VoidCallback onDeleteRoutine;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    size: 22,
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
                            .titleMedium
                            ?.copyWith(
                              fontFamily: AppTextStyles.fontFamilySans,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (routine.routineDescription.isNotEmpty)
                        Text(
                          routine.routineDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      color: AppColors.error, size: 20),
                  onPressed: onDeleteRoutine,
                  tooltip: 'Delete Routine',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Exercise list
            if (routine.exercises.isNotEmpty)
              ...routine.exercises.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 44),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.exerciseName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${e.sets}x${e.repsMin}-${e.repsMax}',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight,
                                ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    label: 'Add Exercise',
                    icon: Icons.add,
                    onPressed: onAddExercise,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton.primary(
                    label: 'Perform Workout',
                    icon: Icons.play_arrow,
                    onPressed: onPerform,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRoutineDialog extends StatefulWidget {
  const _AddRoutineDialog();

  @override
  State<_AddRoutineDialog> createState() => _AddRoutineDialogState();
}

class _AddRoutineDialogState extends State<_AddRoutineDialog> {
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
                hintText: 'e.g. Push Day, Leg Day',
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

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
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
