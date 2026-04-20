import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../providers/coach_routine_provider.dart';

/// Coach Routine Detail Screen
///
/// Displays a single routine template's metadata.
/// Exercise management is now handled in the program builder (Phase 3).
class CoachRoutineDetailScreen extends ConsumerStatefulWidget {
  const CoachRoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  ConsumerState<CoachRoutineDetailScreen> createState() =>
      _CoachRoutineDetailScreenState();
}

class _CoachRoutineDetailScreenState
    extends ConsumerState<CoachRoutineDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(routineDetailProvider(widget.routineId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineDetailProvider(widget.routineId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(state),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state is RoutineDetailLoaded)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Routine',
              onPressed: () => context.push(
                AppRoutes.coachEditRoutine.replaceFirst(
                  ':id',
                  widget.routineId,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildTitle(RoutineDetailState state) {
    if (state is RoutineDetailLoaded) {
      return Text(state.routine.name);
    }
    return const Text('Routine');
  }

  Widget _buildBody(RoutineDetailState state, bool isDark) {
    return switch (state) {
      RoutineDetailInitial() || RoutineDetailLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      RoutineDetailError(:final error) => Center(
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
              onPressed: () => ref
                  .read(routineDetailProvider(widget.routineId).notifier)
                  .load(),
            ),
          ],
        ),
      ),
      RoutineDetailLoaded(:final routine) => _buildDetail(routine, isDark),
    };
  }

  Widget _buildDetail(RoutineSummaryModel routine, bool isDark) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(routineDetailProvider(widget.routineId).notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (routine.description.isNotEmpty) ...[
            Text(
              routine.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Stats
          Row(
            children: [
              AppBadge(
                label: '${routine.estimatedDurationMinutes} min',
                variant: AppBadgeVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info note
          AppCard.elevated(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a routine template. Exercises are managed '
                    'when you add this template to a client\'s program.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
