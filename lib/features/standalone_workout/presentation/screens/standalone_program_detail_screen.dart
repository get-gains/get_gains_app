import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/standalone_program_provider.dart';
import '../providers/standalone_session_provider.dart';

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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Program')),
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          description: error.toString(),
        ),
        data: (program) {
          final routines = program.routines;
          if (routines.isEmpty) {
            return AppEmptyState(
              icon: Icons.fitness_center,
              title: 'No Routines',
              description: 'Add routines to your program first.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Text(
                program.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: AppTextStyles.fontFamilySans,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (program.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  program.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
              ],
              const SizedBox(height: 24),

              // Routines
              ...routines.asMap().entries.map((entry) {
                final routine = entry.value;
                return _RoutineBlock(
                  routine: routine,
                  isDark: isDark,
                  onPerform: () => _performWorkout(routine),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performWorkout(StandaloneProgramRoutine routine) async {
    final notifier = ref.read(standaloneSessionProvider.notifier);
    await notifier.startSession(routine.id);
    final session = ref.read(standaloneSessionProvider).value;
    if (session != null && mounted) {
      context.push('/standalone/session/${session.id}');
    }
  }
}

class _RoutineBlock extends StatelessWidget {
  const _RoutineBlock({
    required this.routine,
    required this.isDark,
    required this.onPerform,
  });

  final StandaloneProgramRoutine routine;
  final bool isDark;
  final VoidCallback onPerform;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Exercise list
            if (routine.exercises.isNotEmpty)
              ...routine.exercises.map((e) {
                final lastStat = e.lastWeight != null
                    ? '${e.lastWeight?.toStringAsFixed(1)}kg × ${e.lastReps}'
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.exerciseName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${e.sets}×${e.repsMin}-${e.repsMax}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                      if (lastStat != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          lastStat,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamilyMono,
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Perform Workout',
                icon: Icons.play_arrow,
                onPressed: onPerform,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
