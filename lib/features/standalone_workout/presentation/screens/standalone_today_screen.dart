import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/app_empty_state.dart';
import '../../../../widgets/app_toast.dart';
import '../../data/helpers/model_conversion.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';
import '../providers/standalone_program_provider.dart';

/// Standalone Today Screen
///
/// Shows today's workout from the user's active standalone program.
/// Displays the routine with exercises and a "Start Workout" button.
class StandaloneTodayScreen extends ConsumerStatefulWidget {
  const StandaloneTodayScreen({super.key});

  @override
  ConsumerState<StandaloneTodayScreen> createState() =>
      _StandaloneTodayScreenState();
}

class _StandaloneTodayScreenState
    extends ConsumerState<StandaloneTodayScreen> {
  Future<void> _startSession(StandaloneProgramDetail program) async {
    final userId = ref.read(authStateProvider).userId;
    if (userId == null || userId.isEmpty) {
      AppToast.error(context, 'User not authenticated');
      return;
    }

    final routines = program.routines;
    if (routines.isEmpty) {
      AppToast.error(context, 'No routines in this program');
      return;
    }

    final firstRoutine = routines.first;
    final repo = ref.read(standaloneWorkoutRepositoryProvider);

    final result = await repo.startWorkoutSession(
      userId: userId,
      programRoutineId: firstRoutine.routineId,
    );

    result.when(
      success: (session) {
        if (mounted) {
          context.push(
            AppRoutes.standaloneWorkout,
            extra: <String, dynamic>{
              'session': session,
              'exercises': firstRoutine.exercises
                  .map((e) => e.toRoutineExerciseModel())
                  .toList(),
              'routineName': program.name,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programAsync = ref.watch(standaloneActiveProgramProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Today',
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
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          description: error.toString(),
          actionLabel: 'Go Back',
          onAction: () => context.pop(),
        ),
        data: (program) {
          if (program == null) {
            return AppEmptyState(
              icon: Icons.fitness_center,
              title: 'No Active Program',
              description:
                  'Build your first workout program to get started.',
              actionLabel: 'Build Program',
              onAction: () =>
                  context.push(AppRoutes.standaloneProgramBuilder),
            );
          }

          final routines = program.routines;
          if (routines.isEmpty) {
            return AppEmptyState(
              icon: Icons.fitness_center,
              title: 'No Routines',
              description:
                  'This program has no routines yet. Edit it to add workouts.',
              actionLabel: 'Edit Program',
              onAction: () => context.push(
                '${AppRoutes.standaloneProgramBuilder}?programId=${program.id}',
              ),
            );
          }

          final primaryColor =
              isDark ? AppColors.primaryDark : AppColors.primaryLight;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Program header
              AppCard.elevated(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.today,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontFamily: AppTextStyles.fontFamilySans,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (program.description.isNotEmpty)
                            Text(
                              program.description,
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
              ),

              const SizedBox(height: 24),

              Text(
                'Today\'s Workout',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: AppTextStyles.fontFamilySans,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              ...routines.asMap().entries.map((entry) {
                final routine = entry.value;
                return _RoutineBlock(
                  routine: routine,
                  isDark: isDark,
                  onStart: () => _startSession(program),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _RoutineBlock extends StatelessWidget {
  const _RoutineBlock({
    required this.routine,
    required this.isDark,
    required this.onStart,
  });

  final StandaloneProgramRoutine routine;
  final bool isDark;
  final VoidCallback onStart;

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
              ],
            ),
            const SizedBox(height: 14),

            if (routine.exercises.isNotEmpty)
              ...routine.exercises.map((e) {
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
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Start Workout',
                icon: Icons.play_arrow,
                onPressed: onStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
