// lib/features/coach_client_progress/presentation/screens/exercise_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/client_progress_providers.dart';

/// Exercise History Screen
///
/// Displays a client's progress for a single exercise over time:
/// - Exercise name and muscle group header
/// - Per-session history entries (most-recent first)
/// - Each entry shows sets, max weight, total volume, and best set
///
/// Useful for coaches to track progression.
class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  const ExerciseHistoryScreen({
    super.key,
    required this.userId,
    required this.exerciseId,
    this.exerciseName,
  });

  final String userId;
  final String exerciseId;
  final String? exerciseName;

  @override
  ConsumerState<ExerciseHistoryScreen> createState() =>
      _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(clientExerciseHistoryProvider.notifier)
          .loadExerciseHistory(widget.userId, widget.exerciseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientExerciseHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.exerciseName ?? 'Exercise History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: switch (state) {
        ClientExerciseHistoryInitial() || ClientExerciseHistoryLoading() =>
          const Center(child: CircularProgressIndicator()),
        ClientExerciseHistoryError(:final error) => Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load history',
            description: error.message,
            actionLabel: 'Retry',
            onAction: () => ref
                .read(clientExerciseHistoryProvider.notifier)
                .loadExerciseHistory(widget.userId, widget.exerciseId),
          ),
        ),
        ClientExerciseHistoryLoaded(:final response) => _buildContent(
          context,
          response,
          isDark,
        ),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClientExerciseHistoryResponse response,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    if (response.history.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.trending_up,
          title: 'No History',
          description: 'No sessions found for this exercise yet.',
        ),
      );
    }

    // Calculate global best across all entries for the highlight card
    double globalMaxWeight = 0;
    double globalMaxVolume = 0;
    int totalSessions = response.total;

    for (final entry in response.history) {
      if (entry.summary.maxWeight > globalMaxWeight) {
        globalMaxWeight = entry.summary.maxWeight;
      }
      if (entry.summary.totalVolume > globalMaxVolume) {
        globalMaxVolume = entry.summary.totalVolume;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exercise Info ──────────────────────────────
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: isDark
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
                        response.exercise.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (response.exercise.primaryMuscleGroup != null)
                        Text(
                          response.exercise.primaryMuscleGroup!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                    ],
                  ),
                ),
                AppBadge(
                  label: '$totalSessions sessions',
                  variant: AppBadgeVariant.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Highlight Stats ────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppStatsCard(
                  label: 'Max Weight',
                  value: '${globalMaxWeight.toStringAsFixed(1)} kg',
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppStatsCard(
                  label: 'Best Volume',
                  value: '${globalMaxVolume.toStringAsFixed(0)} kg',
                  icon: Icons.bar_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── History Timeline ───────────────────────────
          Text(
            'Session History',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...response.history.asMap().entries.map((entry) {
            final index = entry.key;
            final historyEntry = entry.value;
            // Calculate volume delta from previous entry (older)
            String? trendText;
            bool trendPositive = true;
            if (index < response.history.length - 1) {
              final prevEntry = response.history[index + 1];
              final volumeDiff =
                  historyEntry.summary.totalVolume -
                  prevEntry.summary.totalVolume;
              if (volumeDiff != 0) {
                trendText = volumeDiff > 0
                    ? '+${volumeDiff.toStringAsFixed(0)} kg vol'
                    : '${volumeDiff.toStringAsFixed(0)} kg vol';
                trendPositive = volumeDiff > 0;
              }
            }

            return _HistoryEntryCard(
              entry: historyEntry,
              isDark: isDark,
              trendText: trendText,
              trendPositive: trendPositive,
            );
          }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// History Entry Card
// ──────────────────────────────────────────────────────────

class _HistoryEntryCard extends StatefulWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.isDark,
    this.trendText,
    this.trendPositive = true,
  });

  final ExerciseHistoryEntry entry;
  final bool isDark;
  final String? trendText;
  final bool trendPositive;

  @override
  State<_HistoryEntryCard> createState() => _HistoryEntryCardState();
}

class _HistoryEntryCardState extends State<_HistoryEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.entry.summary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(widget.entry.date),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.trendText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (widget.trendPositive
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            child: Text(
                              widget.trendText!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: widget.trendPositive
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: AppTheme.durationNormal,
                          child: Icon(
                            Icons.expand_more,
                            size: 20,
                            color: widget.isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniStat(
                          label: '${summary.totalSets} sets',
                          isDark: widget.isDark,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          label: '${summary.totalReps} reps',
                          isDark: widget.isDark,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          label:
                              '${summary.maxWeight.toStringAsFixed(1)} kg max',
                          isDark: widget.isDark,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          label:
                              '${summary.totalVolume.toStringAsFixed(0)} kg vol',
                          isDark: widget.isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded sets detail
            AnimatedCrossFade(
              firstChild: _buildSetsDetail(theme),
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

  Widget _buildSetsDetail(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Sets header
          Row(
            children: [
              _headerCell(theme, 'Set', flex: 1),
              _headerCell(theme, 'Reps', flex: 2),
              _headerCell(theme, 'Weight', flex: 2),
              _headerCell(theme, 'RPE', flex: 1),
            ],
          ),
          const SizedBox(height: 4),
          ...widget.entry.sets.map(
            (set) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _dataCell(theme, '${set.setNumber}', flex: 1),
                  _dataCell(theme, '${set.repsCompleted}', flex: 2),
                  _dataCell(
                    theme,
                    set.weightKg != null
                        ? '${set.weightKg!.toStringAsFixed(1)} kg'
                        : '—',
                    flex: 2,
                  ),
                  _dataCell(
                    theme,
                    set.rpe != null ? '${set.rpe}' : '—',
                    flex: 1,
                  ),
                ],
              ),
            ),
          ),
          if (widget.entry.summary.bestSet != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Best set: ${widget.entry.summary.bestSet!.repsCompleted} reps'
                    '${widget.entry.summary.bestSet!.weightKg != null ? ' @ ${widget.entry.summary.bestSet!.weightKg!.toStringAsFixed(1)} kg' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(ThemeData theme, String text, {int flex = 1}) {
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

  Widget _dataCell(ThemeData theme, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: isDark
            ? AppColors.mutedForegroundDark
            : AppColors.mutedForegroundLight,
      ),
    );
  }
}
