import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/standalone_workout_repository.dart';
import '../providers/standalone_session_provider.dart';

class StandaloneSessionScreen extends ConsumerStatefulWidget {
  const StandaloneSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<StandaloneSessionScreen> createState() =>
      _StandaloneSessionScreenState();
}

class _StandaloneSessionScreenState
    extends ConsumerState<StandaloneSessionScreen> {
  final Map<String, List<_SetInput>> _setInputs = {};
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final repo = ref.read(standaloneWorkoutRepositoryProvider);
    final result = await repo.getSession(widget.sessionId);
    result.when(
      success: (session) {
        _initSetInputs(session);
      },
      failure: (_) {},
    );
  }

  void _initSetInputs(StandaloneSession session) {
    for (final exercise in session.exercises) {
      _setInputs[exercise.id] = List.generate(
        exercise.sets,
        (i) => _SetInput(
          setNumber: i + 1,
          reps: exercise.repsMin,
          weight: 0,
        ),
      );
    }
  }

  Future<void> _completeWorkout() async {
    setState(() => _completing = true);
    final notifier = ref.read(standaloneSessionProvider.notifier);
    await notifier.completeSession();
    setState(() => _completing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout complete!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionAsync = ref.watch(standaloneSessionProvider);
    final repo = ref.read(standaloneWorkoutRepositoryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          sessionAsync.value?.routineName ?? 'Workout',
          style: TextStyle(fontFamily: AppTextStyles.fontFamilySans),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('End Workout?'),
                content: const Text(
                  'Your progress will be lost if you leave now.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Stay'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.pop();
                    },
                    child: const Text('Leave'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          description: error.toString(),
          actionLabel: 'Go Back',
          onAction: () => context.pop(),
        ),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('No active session'));
          }

          if (session.completedAt != null) {
            return _buildCompletedView(session, isDark);
          }

          final exercises = session.exercises;
          if (exercises.isEmpty) {
            return const Center(child: Text('No exercises'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final inputs = _setInputs[exercise.id] ?? [];

                    return _ExerciseLogCard(
                      exercise: exercise,
                      setInputs: inputs,
                      isDark: isDark,
                      performedSets: session.performedSets
                          .where((s) => s.routineExerciseId == exercise.id)
                          .toList(),
                      onLogSet: (setInput) async {
                        await ref
                            .read(standaloneSessionProvider.notifier)
                            .logSet(
                              LogStandaloneSetRequest(
                                routineExerciseId: exercise.id,
                                setNumber: setInput.setNumber,
                                reps: setInput.reps,
                                weight: setInput.weight.toDouble(),
                              ),
                            );
                      },
                    );
                  },
                ),
              ),
              // Bottom action bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: _completing ? 'Completing...' : 'Finish Workout',
                      icon: Icons.check,
                      onPressed: _completing ? null : _completeWorkout,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompletedView(StandaloneSession session, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          const Text(
            'Workout Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${session.performedSets.length} sets logged',
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            label: 'Done',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _SetInput {
  _SetInput({required this.setNumber, this.reps = 8, this.weight = 0});
  final int setNumber;
  int reps;
  int weight;
}

class _ExerciseLogCard extends StatelessWidget {
  const _ExerciseLogCard({
    required this.exercise,
    required this.setInputs,
    required this.isDark,
    required this.performedSets,
    required this.onLogSet,
  });

  final StandaloneSessionExercise exercise;
  final List<_SetInput> setInputs;
  final bool isDark;
  final List<StandalonePerformedSet> performedSets;
  final void Function(_SetInput) onLogSet;

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.fitness_center, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontFamily: AppTextStyles.fontFamilySans,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${exercise.sets}×${exercise.repsMin}-${exercise.repsMax}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: primaryColor,
                        fontFamily: AppTextStyles.fontFamilyMono,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Set logging
            ...setInputs.map((input) {
              final loggedSet = performedSets
                  .where((s) => s.setNumber == input.setNumber)
                  .firstOrNull;
              final isLogged = loggedSet != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${input.setNumber}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamilyMono,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumberInput(
                        label: 'Reps',
                        value: isLogged ? loggedSet.reps : input.reps,
                        enabled: !isLogged,
                        onChanged: (v) => input.reps = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumberInput(
                        label: 'kg',
                        value: isLogged ? loggedSet.weight.toInt() : input.weight,
                        enabled: !isLogged,
                        onChanged: (v) => input.weight = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: AppButton.primary(
                        label: isLogged ? 'Done' : 'Log',
                        onPressed: isLogged ? null : () => onLogSet(input),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool enabled;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          isDense: true,
          filled: !enabled,
        ),
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamilyMono,
          fontWeight: FontWeight.w600,
        ),
        controller: TextEditingController(text: value.toString()),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }
}
