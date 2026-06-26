import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/program_model.dart';
import '../providers/client_profile_provider.dart';
import '../providers/coach_assignment_provider.dart';

/// Client Assignments Screen
///
/// Displays the active program for a specific client.
/// When no program exists, shows a "Build a Program" CTA.
/// When a program exists, shows the program tree with an "Edit" button.
///
/// Full wizard UI is built in Phase 3. This is a minimal working screen
/// that compiles against Phase 2 providers.
class ClientAssignmentsScreen extends ConsumerStatefulWidget {
  const ClientAssignmentsScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  final String userId;
  final String? userName;

  @override
  ConsumerState<ClientAssignmentsScreen> createState() =>
      _ClientAssignmentsScreenState();
}

class _ClientAssignmentsScreenState
    extends ConsumerState<ClientAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(clientAssignmentsProvider(widget.userId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientAssignmentsProvider(widget.userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName != null
              ? '${widget.userName}\'s Program'
              : 'Client Program',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(ClientAssignmentsState state, bool isDark) {
    final content = switch (state) {
      ClientAssignmentsInitial() || ClientAssignmentsLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ClientAssignmentsError(:final error) => Center(
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
                  .read(clientAssignmentsProvider(widget.userId).notifier)
                  .load(),
            ),
          ],
        ),
      ),
      ClientAssignmentsLoaded(:final activeProgram) =>
        activeProgram == null
            ? _buildEmpty(isDark)
            : _buildProgramView(activeProgram, isDark),
    };

    return Column(
      children: [
        _ClientAvailabilityBar(userId: widget.userId),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildEmpty(bool isDark) {
    return AppEmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Active Program',
      description: 'Build a program for this client to get them started.',
      actionLabel: 'Build a Program',
      onAction: () => _navigateToBuilder(),
    );
  }

  Widget _buildProgramView(ClientProgramModel program, bool isDark) {
    final theme = Theme.of(context);
    final sortedRoutines = [...program.routines]
      ..sort((a, b) => a.orderInProgram.compareTo(b.orderInProgram));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientAssignmentsProvider(widget.userId).notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Program header
          Row(
            children: [
              Expanded(
                child: Text(program.name, style: theme.textTheme.headlineSmall),
              ),
              AppBadge(
                label: program.isActive ? 'Active' : 'Inactive',
                variant: program.isActive
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.secondary,
              ),
            ],
          ),
          if (program.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              program.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              AppBadge(
                label: '${program.routineCount} routines',
                variant: AppBadgeVariant.info,
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: '${program.totalExerciseCount} exercises',
                variant: AppBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Edit button
          AppButton.outline(
            label: 'Edit Program',
            icon: Icons.edit_outlined,
            onPressed: () => _navigateToBuilder(programId: program.id),
            isFullWidth: true,
          ),
          const SizedBox(height: 16),

          // Routines list
          if (sortedRoutines.isEmpty)
            AppEmptyState.compact(
              icon: Icons.calendar_today,
              title: 'No Routines Yet',
              description: 'Edit the program to add routines.',
            )
          else
            ...sortedRoutines.map(
              (routine) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoutineCard(routine: routine, isDark: isDark),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToBuilder({String? programId}) async {
    final uri = Uri(
      path: AppRoutes.programBuilder.replaceFirst(':userId', widget.userId),
      queryParameters: {
        if (programId != null) 'programId': programId,
        if (widget.userName != null) 'name': widget.userName!,
      },
    );
    await context.push(uri.toString());
    // Refresh assignments after returning from the wizard
    if (mounted) {
      ref.read(clientAssignmentsProvider(widget.userId).notifier).load();
    }
  }
}

// ──────────────────────────────────────────────────────────
// Routine Card
// ──────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.isDark});

  final ProgramRoutineModel routine;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + day chips
          Row(
            children: [
              Expanded(
                child: Text(routine.name, style: theme.textTheme.titleMedium),
              ),
              if (routine.estimatedDurationMinutes > 0)
                Text(
                  '${routine.estimatedDurationMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
            ],
          ),

          // Day chips
          if (routine.daysOfWeek.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: routine.daysOfWeek.map((day) {
                return Chip(
                  label: Text(
                    day.shortName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],

          // Exercise summary
          if (routine.exercises.isNotEmpty) ...[
            const Divider(height: 16),
            ...routine.exercises
                .take(3)
                .map(
                  (ex) => Padding(
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
                            ex.exercise?.name ?? 'Exercise',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${ex.sets}×${ex.repsMin}-${ex.repsMax}',
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

// ──────────────────────────────────────────────────────────
// Client Availability Bar
// ──────────────────────────────────────────────────────────

/// Compact bar showing the client's active weekdays.
///
/// Fetches the client profile via [clientProfileNotifierProvider] and
/// displays day chips so the coach knows the client's availability.
class _ClientAvailabilityBar extends ConsumerWidget {
  const _ClientAvailabilityBar({required this.userId});

  final String userId;

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _dayValues = DayOfWeek.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clientProfileProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final activeDays = profile.activeWeekdays;
        if (activeDays.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Days',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontFamily: AppTextStyles.fontFamilySans,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_dayValues.length, (i) {
                  final isActive = activeDays.any((d) => d.name == _dayValues[i].name);
                  return _DayChip(
                    label: _dayLabels[i],
                    isActive: isActive,
                    isDark: isDark,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.isActive,
    required this.isDark,
  });

  final String label;
  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryDark
            : (isDark ? AppColors.surface2Dark : AppColors.surface2Light),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? Colors.white
              : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          fontFamily: AppTextStyles.fontFamilySans,
        ),
      ),
    );
  }
}
