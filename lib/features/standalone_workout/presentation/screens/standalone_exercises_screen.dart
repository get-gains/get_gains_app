import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/models/standalone_request_models.dart';
import '../providers/standalone_exercise_provider.dart';

/// Standalone Exercises Library Screen
///
/// Displays the user's personal exercises along with public/coach exercises.
/// Supports search, muscle group filtering, pagination, and CRUD operations.
/// Offline-first: shows cached exercises immediately, then syncs from server.
class StandaloneExercisesScreen extends ConsumerStatefulWidget {
  const StandaloneExercisesScreen({super.key});

  @override
  ConsumerState<StandaloneExercisesScreen> createState() =>
      _StandaloneExercisesScreenState();
}

class _StandaloneExercisesScreenState
    extends ConsumerState<StandaloneExercisesScreen> {
  MuscleGroup? _selectedMuscleGroup;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(standaloneExercisesProvider.notifier).loadExercises(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standaloneExercisesProvider);
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppTextField.search(
              controller: _searchController,
              hint: 'Search exercises...',
              onSubmitted: (_) => _applyFilters(),
              onClear: () {
                _searchController.clear();
                _applyFilters();
              },
            ),
          ),

          // Muscle group filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedMuscleGroup == null,
                  onTap: () {
                    setState(() => _selectedMuscleGroup = null);
                    _applyFilters();
                  },
                  isDark: isDark,
                ),
                ...MuscleGroup.values.map(
                  (mg) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: mg.name,
                      isSelected: _selectedMuscleGroup == mg,
                      onTap: () {
                        setState(() => _selectedMuscleGroup = mg);
                        _applyFilters();
                      },
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(child: _buildBody(state, isDark)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.standaloneCreateExercise),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Exercise'),
      ),
    );
  }

  void _applyFilters() {
    ref
        .read(standaloneExercisesProvider.notifier)
        .loadExercises(
          muscleGroup: _selectedMuscleGroup,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  Widget _buildBody(StandaloneExercisesState state, bool isDark) {
    return switch (state) {
      StandaloneExercisesInitial() || StandaloneExercisesLoading() =>
        const Center(child: CircularProgressIndicator()),
      StandaloneExercisesError(:final error) => _buildError(error, isDark),
      StandaloneExercisesLoaded(:final exercises) =>
        exercises.isEmpty
            ? _buildEmpty()
            : _buildList(state as StandaloneExercisesLoaded, isDark),
    };
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.fitness_center_outlined,
      title: 'No Exercises Found',
      description:
          _searchController.text.isNotEmpty || _selectedMuscleGroup != null
          ? 'Try adjusting your search or filters.'
          : 'Create your first personal exercise to get started.',
      actionLabel: 'Create Exercise',
      onAction: () => context.push(AppRoutes.standaloneCreateExercise),
    );
  }

  Widget _buildError(AppError error, bool isDark) {
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
            error.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: () =>
                ref.read(standaloneExercisesProvider.notifier).loadExercises(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(StandaloneExercisesLoaded loaded, bool isDark) {
    final exercises = loaded.exercises;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(standaloneExercisesProvider.notifier).loadExercises(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: exercises.length + (loaded.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= exercises.length) {
            Future.microtask(
              () => ref.read(standaloneExercisesProvider.notifier).loadMore(),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final exercise = exercises[index];
          return _ExerciseCard(
            exercise: exercise,
            isDark: isDark,
            onTap: () => context.push(
              AppRoutes.standaloneExerciseEdit.replaceFirst(':id', exercise.id),
            ),
            onDelete: () => _confirmDelete(exercise),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(StandaloneExerciseModel exercise) async {
    if (!exercise.isPersonal) {
      AppToast.warning(context, 'You can only delete your own exercises');
      return;
    }

    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Delete Exercise',
      message: 'Delete "${exercise.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(standaloneExercisesProvider.notifier)
          .deleteExercise(exercise.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Exercise deleted');
        } else {
          AppToast.error(context, 'Failed to delete exercise');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Exercise Card
// ──────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final StandaloneExerciseModel exercise;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.interactive(
      onTap: onTap,
      child: Row(
        children: [
          // Muscle group icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.15)
                  : AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fitness_center,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Name & details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AppBadge(
                      label: exercise.primaryMuscleGroup.name,
                      variant: AppBadgeVariant.secondary,
                    ),
                    if (exercise.isPersonal) ...[
                      const SizedBox(width: 6),
                      AppBadge(
                        label: 'Personal',
                        variant: AppBadgeVariant.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Delete (only personal)
          if (exercise.isPersonal)
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
    );
  }
}

// ──────────────────────────────────────────────────────────
// Filter Chip
// ──────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
              : (isDark ? AppColors.surface2Dark : AppColors.surface3Light),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight),
          ),
        ),
      ),
    );
  }
}
