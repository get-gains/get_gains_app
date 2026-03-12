import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../providers/coach_routine_provider.dart';

/// Coach Routines List Screen
///
/// Displays all routines created by the authenticated coach.
/// Routines are reusable across programs.
class CoachRoutinesScreen extends ConsumerStatefulWidget {
  const CoachRoutinesScreen({super.key});

  @override
  ConsumerState<CoachRoutinesScreen> createState() =>
      _CoachRoutinesScreenState();
}

class _CoachRoutinesScreenState extends ConsumerState<CoachRoutinesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(coachRoutinesProvider.notifier).loadRoutines(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachRoutinesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routines'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.coachCreateRoutine),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Routine'),
      ),
    );
  }

  Widget _buildBody(CoachRoutinesState state, bool isDark) {
    return switch (state) {
      CoachRoutinesInitial() || CoachRoutinesLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      CoachRoutinesError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(height: 12),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () =>
                  ref.read(coachRoutinesProvider.notifier).loadRoutines(),
            ),
          ],
        ),
      ),
      CoachRoutinesLoaded(:final routines, :final pagination) =>
        routines.isEmpty
            ? _buildEmpty()
            : _buildList(routines, pagination, isDark),
    };
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.library_books_outlined,
      title: 'No Routines Yet',
      description:
          'Create your first routine, then assign it to programs for your clients.',
      actionLabel: 'Create Routine',
      onAction: () => context.push(AppRoutes.coachCreateRoutine),
    );
  }

  Widget _buildList(
    List<RoutineSummaryModel> routines,
    PaginationMeta pagination,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(coachRoutinesProvider.notifier).loadRoutines(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: routines.length + (pagination.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= routines.length) {
            Future.microtask(
              () => ref.read(coachRoutinesProvider.notifier).loadMore(),
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
              AppRoutes.coachRoutineDetail.replaceFirst(':id', routine.id),
            ),
            onDelete: () => _confirmDelete(routine),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(RoutineSummaryModel routine) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Delete Routine',
      message:
          'Are you sure you want to delete "${routine.name}"? It will be removed from all programs that use it.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(coachRoutinesProvider.notifier)
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

  final RoutineSummaryModel routine;
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
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push(
                      AppRoutes.coachEditRoutine.replaceFirst(
                        ':id',
                        routine.id,
                      ),
                    );
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
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

          // Stats row
          Row(
            children: [
              _InfoChip(
                icon: Icons.fitness_center,
                label: '${routine.exerciseCount} exercises',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.assignment_outlined,
                label: '${routine.programCount} programs',
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

          // Muscle group chips
          if (routine.muscleGroupsTargeted.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: routine.muscleGroupsTargeted
                  .map(
                    (mg) => AppBadge(
                      label: mg.displayName,
                      variant: AppBadgeVariant.secondary,
                      size: AppBadgeSize.sm,
                    ),
                  )
                  .toList(),
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
