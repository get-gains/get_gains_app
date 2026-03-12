import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/standalone_routine_provider.dart';

/// Standalone Routines List Screen
///
/// Displays user-created routines. Offline-first: shows cached → syncs server.
/// Supports pull-to-refresh, pagination, and navigation to detail/create.
class StandaloneRoutinesScreen extends ConsumerStatefulWidget {
  const StandaloneRoutinesScreen({super.key});

  @override
  ConsumerState<StandaloneRoutinesScreen> createState() =>
      _StandaloneRoutinesScreenState();
}

class _StandaloneRoutinesScreenState
    extends ConsumerState<StandaloneRoutinesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(standaloneRoutinesProvider.notifier).loadRoutines(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standaloneRoutinesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routines'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center_outlined),
            tooltip: 'Exercise Library',
            onPressed: () => context.push(AppRoutes.standaloneExercises),
          ),
        ],
      ),
      body: _buildBody(state, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.standaloneCreateRoutine),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Routine'),
      ),
    );
  }

  Widget _buildBody(StandaloneRoutinesState state, bool isDark) {
    return switch (state) {
      StandaloneRoutinesInitial() || StandaloneRoutinesLoading() =>
        const Center(child: CircularProgressIndicator()),
      StandaloneRoutinesError(:final error) => _buildError(error, isDark),
      StandaloneRoutinesLoaded(:final routines) =>
        routines.isEmpty
            ? _buildEmpty()
            : _buildList(state as StandaloneRoutinesLoaded, isDark),
    };
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.list_alt_outlined,
      title: 'No Routines Yet',
      description:
          'Create your first routine to start organizing your exercises.',
      actionLabel: 'Create Routine',
      onAction: () => context.push(AppRoutes.standaloneCreateRoutine),
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
                ref.read(standaloneRoutinesProvider.notifier).loadRoutines(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(StandaloneRoutinesLoaded loaded, bool isDark) {
    final routines = loaded.routines;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(standaloneRoutinesProvider.notifier).loadRoutines(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: routines.length + (loaded.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= routines.length) {
            Future.microtask(
              () => ref.read(standaloneRoutinesProvider.notifier).loadMore(),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final routine = routines[index];
          return _RoutineCard(
            routine: routine,
            isDark: isDark,
            onTap: () => context.push(
              AppRoutes.standaloneRoutineDetail.replaceFirst(':id', routine.id),
            ),
            onDelete: () => _confirmDelete(routine),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(StandaloneRoutineSummaryModel routine) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Delete Routine',
      message: 'Delete "${routine.name}"? This will not delete the exercises.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(standaloneRoutinesProvider.notifier)
          .deleteRoutine(routine.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Routine deleted');
        } else {
          AppToast.error(context, 'Failed to delete routine');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Routine Card
// ──────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final StandaloneRoutineSummaryModel routine;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.interactive(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routine.name,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
          if (routine.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              routine.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.fitness_center,
                label: '${routine.exerciseCount} exercises',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: '${routine.estimatedDurationMinutes} min',
                isDark: isDark,
              ),
            ],
          ),
          if (routine.muscleGroupsTargeted.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: routine.muscleGroupsTargeted.map((mg) {
                return AppBadge(
                  label: mg.name,
                  variant: AppBadgeVariant.secondary,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
      ],
    );
  }
}
