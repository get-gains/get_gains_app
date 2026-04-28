import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/exercise_list_provider.dart';
import '../widgets/exercise_card.dart';
import '../widgets/muscle_group_chips.dart';

/// Exercise list screen for coaches.
///
/// Displays searchable, filterable list of exercises.
/// FAB navigates to create exercise screen.
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(exerciseListProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.surface1Dark
                    : AppColors.inputLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                ref.read(exerciseListProvider.notifier).search(value);
              },
            ),
          ),

          // Muscle group filter chips
          MuscleGroupChips(
            selectedMuscleGroup: state.selectedMuscleGroup,
            onSelected: (group) {
              ref
                  .read(exerciseListProvider.notifier)
                  .filterByMuscleGroup(group);
            },
          ),
          const SizedBox(height: 8),

          // Exercise list
          Expanded(child: _buildContent(state, isDark)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createExercise),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Exercise'),
      ),
    );
  }

  Widget _buildContent(ExerciseListState state, bool isDark) {
    if (state.isLoading && state.exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(exerciseListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.exercises.isEmpty) {
      return AppEmptyState.compact(
        icon: Icons.fitness_center,
        title: 'No Exercises Found',
        description: state.searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Create your first exercise to get started',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(exerciseListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        itemCount: state.exercises.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= state.exercises.length) {
            // Load more indicator
            if (!state.isLoading) {
              Future.microtask(
                () => ref.read(exerciseListProvider.notifier).loadMore(),
              );
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final exercise = state.exercises[index];
          return ExerciseCard(
            exercise: exercise,
            onTap: () {
              context.push(
                AppRoutes.exerciseDetail.replaceFirst(':id', exercise.id),
                extra: exercise,
              );
            },
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push(
                    AppRoutes.editExercise.replaceFirst(':id', exercise.id),
                    extra: exercise,
                  );
                } else if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Exercise?'),
                      content: Text(
                        'Are you sure you want to delete "${exercise.name}"? '
                        'This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? AppColors.error
                                : AppColors.errorLight,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await ref
                        .read(exerciseListProvider.notifier)
                        .deleteExercise(exercise.id);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 20,
                        color: isDark ? AppColors.error : AppColors.errorLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.error
                              : AppColors.errorLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
