import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../providers/coach_program_provider.dart';
import 'assign_routine_sheet.dart';

/// Coach Program Detail Screen
///
/// Displays a single program's full routine/exercise tree organized by day.
/// Allows assigning routines to day-slots, updating day numbers, and removing.
class CoachProgramDetailScreen extends ConsumerStatefulWidget {
  const CoachProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  ConsumerState<CoachProgramDetailScreen> createState() =>
      _CoachProgramDetailScreenState();
}

class _CoachProgramDetailScreenState
    extends ConsumerState<CoachProgramDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(programDetailProvider(widget.programId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programDetailProvider(widget.programId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(state),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state is ProgramDetailLoaded)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Program',
              onPressed: () => context.push(
                AppRoutes.coachEditProgram.replaceFirst(
                  ':id',
                  widget.programId,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, isDark),
      floatingActionButton: state is ProgramDetailLoaded
          ? FloatingActionButton.extended(
              onPressed: () => _showAssignRoutineSheet(state.program),
              backgroundColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Routine'),
            )
          : null,
    );
  }

  Widget _buildTitle(ProgramDetailState state) {
    if (state is ProgramDetailLoaded) {
      return Text(state.program.name);
    }
    return const Text('Program');
  }

  Widget _buildBody(ProgramDetailState state, bool isDark) {
    return switch (state) {
      ProgramDetailInitial() || ProgramDetailLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ProgramDetailError(:final error) => Center(
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
                  .read(programDetailProvider(widget.programId).notifier)
                  .load(),
            ),
          ],
        ),
      ),
      ProgramDetailLoaded(:final program) => _buildDetail(program, isDark),
    };
  }

  Widget _buildDetail(ProgramDetailModel program, bool isDark) {
    final theme = Theme.of(context);
    final routinesByDay = {
      for (final slot in program.routines) slot.dayOfWeek: slot,
    };

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(programDetailProvider(widget.programId).notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Program info header
          if (program.description.isNotEmpty) ...[
            Text(
              program.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Stats row
          Row(
            children: [
              AppBadge(
                label: '${DayOfWeek.values.length} days/week',
                variant: AppBadgeVariant.primary,
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: '${program.routines.length} assigned',
                variant: AppBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Day-slot list
          ...DayOfWeek.values.map((day) {
            final slot = routinesByDay[day];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: slot != null
                  ? _DaySlotCard(
                      slot: slot,
                      isDark: isDark,
                      programId: widget.programId,
                      onRemove: () => _confirmRemoveRoutine(slot),
                    )
                  : _RestDayCard(
                      day: day,
                      isDark: isDark,
                      onAssign: () =>
                          _showAssignRoutineSheet(program, preferredDay: day),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showAssignRoutineSheet(
    ProgramDetailModel program, {
    DayOfWeek? preferredDay,
  }) async {
    final result = await showAssignRoutineSheet(
      context: context,
      programId: widget.programId,
      assignedDays: program.routines.map((r) => r.dayOfWeek).toList(),
      initialDay: preferredDay,
    );
    if (result == true && mounted) {
      ref.read(programDetailProvider(widget.programId).notifier).load();
      // Also refresh the programs list to update routine counts
      ref.read(coachProgramsProvider.notifier).loadPrograms();
    }
  }

  Future<void> _confirmRemoveRoutine(ProgramRoutineSlotModel slot) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Remove Routine',
      message:
          'Remove "${slot.routine.name}" from ${slot.dayOfWeek.label}? The routine itself will not be deleted.',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.remove_circle_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(programDetailProvider(widget.programId).notifier)
          .removeProgramRoutine(slot.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Routine removed from program');
          ref.read(coachProgramsProvider.notifier).loadPrograms();
        } else {
          AppToast.error(context, 'Failed to remove routine');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Day Slot Card
// ──────────────────────────────────────────────────────────

class _DaySlotCard extends StatelessWidget {
  const _DaySlotCard({
    required this.slot,
    required this.isDark,
    required this.programId,
    required this.onRemove,
  });

  final ProgramRoutineSlotModel slot;
  final bool isDark;
  final String programId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routine = slot.routine;

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.2)
                      : AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot.dayOfWeek.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: isDark ? AppColors.error : AppColors.errorLight,
                tooltip: 'Remove from program',
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Routine name
          InkWell(
            onTap: () => context.push(
              AppRoutes.coachRoutineDetail.replaceFirst(':id', routine.id),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(routine.name, style: theme.textTheme.titleMedium),
                        if (routine.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            routine.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ],
              ),
            ),
          ),

          // Exercise summary
          if (routine.exercises.isNotEmpty) ...[
            const Divider(height: 16),
            ...routine.exercises
                .take(3)
                .map(
                  (re) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            re.exercise?.name ?? 'Exercise',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${re.sets}×${re.repsMin}-${re.repsMax}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (routine.exercises.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${routine.exercises.length - 3} more exercises',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard({
    required this.day,
    required this.isDark,
    required this.onAssign,
  });

  final DayOfWeek day;
  final bool isDark;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.elevated(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1Dark : AppColors.mutedLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rest Day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onAssign,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
