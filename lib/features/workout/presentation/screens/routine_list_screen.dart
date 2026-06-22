import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../../../core/access/access_gated.dart';
import '../../../../core/access/access_guard.dart';
import '../../../subscription/subscription.dart';
import '../../data/models/models.dart';
import '../providers/routine_list_provider.dart';

/// Routine List Screen
///
/// Displays available workout routines for the user to start.
class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routinesAsync = ref.watch(routineListProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Routines'), centerTitle: true),
      body: AccessGated(
        requires: const AccessRequirement(
          requireTier: SubscriptionTier.premium,
        ),
        feature: SubscriptionFeature.coachRoutines,
        compact: true,
        child: routinesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: AppEmptyState(
              icon: Icons.error_outline,
              title: 'Error',
              description: 'Failed to load routines.',
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(routineListProvider),
            ),
          ),
          data: (routines) {
            if (routines.isEmpty) {
              return Center(
                child: AppEmptyState(
                  icon: Icons.fitness_center,
                  title: 'No Routines',
                  description:
                      'You don\'t have any routines yet.\n'
                      'Routines will appear here when assigned by your coach.',
                  actionLabel: 'Refresh',
                  onAction: () => ref.invalidate(routineListProvider),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(routineListProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  return _RoutineCard(
                    routine: routine,
                    onTap: () => context.push(
                      '/routines/${routine.id}',
                      extra: routine,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.onTap});

  final RoutineModel routine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard.elevated(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    routine.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppBadge(
                  label: '${routine.estimatedDurationMinutes} min',
                  variant: AppBadgeVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              routine.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${routine.totalExercises} exercises',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${routine.totalSets} sets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: routine.muscleGroupsTargeted
                  .take(4)
                  .map(
                    (muscle) => AppBadge(
                      label: muscle.displayName,
                      variant: AppBadgeVariant.outline,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: 'View Exercises',
              icon: Icons.arrow_forward,
              isFullWidth: true,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
