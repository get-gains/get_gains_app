import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/standalone_program_provider.dart';
import '../providers/standalone_session_provider.dart';
import '../providers/standalone_today_provider.dart';

/// Standalone Today Screen
///
/// Displays today's workout from the active standalone program.
/// Shows rest day if no routine is scheduled, or a prompt to activate a program.
/// Allows starting/completing a workout session.
class StandaloneTodayScreen extends ConsumerStatefulWidget {
  const StandaloneTodayScreen({super.key});

  @override
  ConsumerState<StandaloneTodayScreen> createState() =>
      _StandaloneTodayScreenState();
}

class _StandaloneTodayScreenState extends ConsumerState<StandaloneTodayScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayAsync = ref.watch(standaloneTodayProvider);
    final sessionState = ref.watch(standaloneSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Workout"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Session History',
            onPressed: () => context.push(AppRoutes.standaloneSessionHistory),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(standaloneTodayProvider);
          ref.invalidate(standaloneActiveProgramProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            // Active session banner
            _buildSessionBanner(sessionState, isDark),

            // Today's workout card
            todayAsync.when(
              data: (today) => _buildTodayCard(today, isDark, sessionState),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _buildNoActiveProgram(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionBanner(StandaloneSessionState sessionState, bool isDark) {
    if (sessionState is StandaloneSessionActive) {
      final session = sessionState.session;
      final elapsed = DateTime.now().difference(session.startedAt);
      final mins = elapsed.inMinutes;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Workout In Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${mins}m elapsed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 12),
              AppButton.primary(
                label: 'Complete Workout',
                onPressed: () => _completeSession(),
                isFullWidth: true,
              ),
            ],
          ),
        ),
      );
    }

    if (sessionState is StandaloneSessionCompleted) {
      final completedSession = sessionState.session;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Workout Complete!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppButton.primary(
                label: 'View Coin Reward',
                onPressed: () {
                  ref.read(standaloneSessionProvider.notifier).reset();
                  context.go(
                    AppRoutes.coinReward,
                    extra: <String, dynamic>{
                      'setsCompleted': completedSession.completedSetsCount,
                      'sessionDurationMin':
                          completedSession.duration?.inMinutes ?? 0,
                    },
                  );
                },
                isFullWidth: true,
              ),
              const SizedBox(height: 8),
              AppButton.outline(
                label: 'Dismiss',
                onPressed: () =>
                    ref.read(standaloneSessionProvider.notifier).reset(),
                isFullWidth: true,
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTodayCard(
    StandaloneTodayModel today,
    bool isDark,
    StandaloneSessionState sessionState,
  ) {
    final theme = Theme.of(context);

    if (today.isRestDay) {
      return AppCard.elevated(
        child: Column(
          children: [
            Icon(
              Icons.self_improvement,
              size: 48,
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
            const SizedBox(height: 12),
            Text('Rest Day', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              today.message ?? 'Take it easy today — your body needs recovery.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!today.hasRoutine) {
      return _buildNoActiveProgram(isDark);
    }

    final details = today.today!;
    final routine = details.routine;

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day label & program name
          Row(
            children: [
              AppBadge(
                label: _formatDayLabel(details.dayOfWeek),
                variant: AppBadgeVariant.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  details.programName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Routine name
          Text(routine.name, style: theme.textTheme.headlineSmall),
          if (routine.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              routine.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.fitness_center,
                label: '${today.exerciseCount} exercises',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              if (today.estimatedMinutes > 0)
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: '~${today.estimatedMinutes}m',
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Exercise list
          if (routine.exercises.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            ...routine.exercises.map(
              (re) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
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
                        style: theme.textTheme.bodyMedium,
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
          ],

          // Start workout button
          if (sessionState is! StandaloneSessionActive &&
              sessionState is! StandaloneSessionCompleted) ...[
            const SizedBox(height: 16),
            AppButton.primary(
              label: 'Start Workout',
              onPressed: () => _startSession(details.assignedProgramId),
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  /// Converts a DayOfWeek string (e.g. 'MONDAY') to a display label (e.g. 'Monday').
  String _formatDayLabel(String dayOfWeek) {
    if (dayOfWeek.isEmpty) return '';
    return dayOfWeek[0] + dayOfWeek.substring(1).toLowerCase();
  }

  Widget _buildNoActiveProgram(bool isDark) {
    return AppEmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Active Program',
      description: 'Activate a program to see your daily workout here.',
      actionLabel: 'My Programs',
      onAction: () => context.push(AppRoutes.standalonePrograms),
    );
  }

  Future<void> _startSession(String? assignedProgramId) async {
    final success = await ref
        .read(standaloneSessionProvider.notifier)
        .startSession(assignedProgramId: assignedProgramId);
    if (mounted) {
      if (success) {
        AppToast.success(context, 'Workout started!');
      } else {
        AppToast.error(context, 'Failed to start workout');
      }
    }
  }

  Future<void> _completeSession() async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Complete Workout',
      message: 'Mark this workout as complete?',
      confirmLabel: 'Complete',
      icon: Icons.check_circle_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(standaloneSessionProvider.notifier)
          .completeSession();
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Workout complete!');
        } else {
          AppToast.error(context, 'Failed to complete workout');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Stat Chip
// ──────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
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
