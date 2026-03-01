// lib/features/coach_client_progress/presentation/screens/session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/client_progress_providers.dart';

/// Session Detail Screen
///
/// Displays the full breakdown of a client's workout session, including:
/// - Session metadata (date, duration, program)
/// - Summary stats (total volume, sets, reps)
/// - Exercises grouped with their performed sets
///
/// Each exercise group is an expandable tile. Tapping an exercise name
/// navigates to the exercise history screen.
class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.userId,
    required this.sessionId,
  });

  final String userId;
  final String sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(clientSessionDetailProvider.notifier)
          .loadSessionDetail(widget.userId, widget.sessionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientSessionDetailProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Session Detail',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: switch (state) {
        ClientSessionDetailInitial() || ClientSessionDetailLoading() =>
          const Center(child: CircularProgressIndicator()),
        ClientSessionDetailError(:final error) => Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load session',
            description: error.message,
            actionLabel: 'Retry',
            onAction: () => ref
                .read(clientSessionDetailProvider.notifier)
                .loadSessionDetail(widget.userId, widget.sessionId),
          ),
        ),
        ClientSessionDetailLoaded(:final session) => _buildContent(
          context,
          session,
          isDark,
        ),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClientSessionDetail session,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Session Header ─────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.programName != null)
                  Text(
                    session.programName!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Standalone Workout',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(session.startedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ),
                if (session.durationMinutes != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${session.durationMinutes} minutes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ],
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    session.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Summary Stats ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppStatsCard(
                  label: 'Volume',
                  value: '${session.totalVolume.toStringAsFixed(0)} kg',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppStatsCard(
                  label: 'Sets',
                  value: '${session.totalSets}',
                  icon: Icons.repeat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppStatsCard(
                  label: 'Reps',
                  value: '${session.totalReps}',
                  icon: Icons.sync,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Exercises Section ──────────────────────────
          Text(
            'Exercises',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...session.exercises.map(
            (group) => _ExerciseGroupTile(
              group: group,
              isDark: isDark,
              onExerciseTap: () => context.push(
                AppRoutes.clientExerciseHistory
                    .replaceFirst(':userId', widget.userId)
                    .replaceFirst(':exerciseId', group.exerciseId),
                extra: group.exerciseName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute';
  }
}

// ──────────────────────────────────────────────────────────
// Exercise Group Tile — expandable exercise with sets
// ──────────────────────────────────────────────────────────

class _ExerciseGroupTile extends StatefulWidget {
  const _ExerciseGroupTile({
    required this.group,
    required this.isDark,
    required this.onExerciseTap,
  });

  final SessionExerciseGroup group;
  final bool isDark;
  final VoidCallback onExerciseTap;

  @override
  State<_ExerciseGroupTile> createState() => _ExerciseGroupTileState();
}

class _ExerciseGroupTileState extends State<_ExerciseGroupTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Exercise header (tappable to expand/collapse)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (widget.isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        size: 20,
                        color: widget.isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.exerciseName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.group.primaryMuscleGroup != null)
                            Text(
                              widget.group.primaryMuscleGroup!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Link to exercise history
                    IconButton(
                      icon: Icon(
                        Icons.trending_up,
                        size: 20,
                        color: widget.isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                      tooltip: 'View exercise history',
                      onPressed: widget.onExerciseTap,
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppTheme.durationNormal,
                      child: Icon(
                        Icons.expand_more,
                        color: widget.isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sets table
            AnimatedCrossFade(
              firstChild: _buildSetsTable(theme),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: AppTheme.durationNormal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsTable(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _tableHeader(theme, 'Set', flex: 1),
                _tableHeader(theme, 'Reps', flex: 2),
                _tableHeader(theme, 'Weight', flex: 2),
                _tableHeader(theme, 'RPE', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1),
          // Set rows
          ...widget.group.sets.map(
            (set) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _tableCell(theme, '${set.setNumber}', flex: 1),
                  _tableCell(theme, '${set.repsCompleted}', flex: 2),
                  _tableCell(
                    theme,
                    set.weightKg != null
                        ? '${set.weightKg!.toStringAsFixed(1)} kg'
                        : '—',
                    flex: 2,
                  ),
                  _tableCell(
                    theme,
                    set.rpe != null ? '${set.rpe}' : '—',
                    flex: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(ThemeData theme, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: widget.isDark
              ? AppColors.mutedForegroundDark
              : AppColors.mutedForegroundLight,
        ),
      ),
    );
  }

  Widget _tableCell(ThemeData theme, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}
