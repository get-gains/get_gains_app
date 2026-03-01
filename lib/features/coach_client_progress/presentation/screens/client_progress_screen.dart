// lib/features/coach_client_progress/presentation/screens/client_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../../coach_programs/data/models/program_model.dart';
import '../providers/client_progress_providers.dart';

/// Client Progress Screen (Coach → Client detail)
///
/// Displays a tabbed view of a client's workout progress:
/// - **Overview**: Weekly stats cards with deltas
/// - **Sessions**: Paginated list of completed workout sessions
/// - **Form Results**: Form comparison results with scores
///
/// Navigated from the coach roster via `AppRoutes.clientProgress`.
class ClientProgressScreen extends ConsumerStatefulWidget {
  const ClientProgressScreen({super.key, required this.userId, this.userName});

  final String userId;
  final String? userName;

  @override
  ConsumerState<ClientProgressScreen> createState() =>
      _ClientProgressScreenState();
}

class _ClientProgressScreenState extends ConsumerState<ClientProgressScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(clientWeeklyStatsProvider.notifier)
          .loadWeeklyStats(widget.userId);
      ref.read(clientSessionsProvider.notifier).loadSessions(widget.userId);
      ref
          .read(clientFormResultsProvider.notifier)
          .loadFormResults(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.userName ?? 'Client Progress',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppTabs(
              tabs: const ['Overview', 'Sessions', 'Form Results'],
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _OverviewTab(userId: widget.userId, isDark: isDark),
                _SessionsTab(userId: widget.userId, isDark: isDark),
                _FormResultsTab(userId: widget.userId, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Overview Tab — Weekly stats with deltas
// ──────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.userId, required this.isDark});

  final String userId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientWeeklyStatsProvider);

    return switch (state) {
      ClientWeeklyStatsInitial() || ClientWeeklyStatsLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ClientWeeklyStatsError(:final error) => Center(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load stats',
          description: error.message,
          actionLabel: 'Retry',
          onAction: () => ref
              .read(clientWeeklyStatsProvider.notifier)
              .loadWeeklyStats(userId),
        ),
      ),
      ClientWeeklyStatsLoaded(:final stats) => _buildStatsContent(
        context,
        stats,
      ),
    };
  }

  Widget _buildStatsContent(BuildContext context, ClientWeeklyStats stats) {
    final delta = stats.delta;

    return RefreshIndicator(
      onRefresh: () async {
        // Need ProviderScope to read — this is a ConsumerWidget so we can't
        // use ref here, but RefreshIndicator only works with ScrollView
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week range header
            AppCard.flat(
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatShortDate(stats.weekStart)} – ${_formatShortDate(stats.weekEnd)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: AppStatsCard(
                    label: 'Sessions',
                    value: '${stats.sessionsCompleted}',
                    icon: Icons.fitness_center,
                    trend: delta != null
                        ? _formatDelta(delta.sessionsCompleted)
                        : null,
                    trendPositive:
                        delta != null && delta.sessionsCompleted >= 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatsCard(
                    label: 'Total Volume',
                    value: '${stats.totalVolume.toStringAsFixed(0)} kg',
                    icon: Icons.monitor_weight_outlined,
                    trend: delta != null
                        ? _formatDeltaDouble(delta.totalVolume)
                        : null,
                    trendPositive: delta != null && delta.totalVolume >= 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppStatsCard(
                    label: 'Total Sets',
                    value: '${stats.totalSets}',
                    icon: Icons.repeat,
                    trend: delta != null ? _formatDelta(delta.totalSets) : null,
                    trendPositive: delta != null && delta.totalSets >= 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatsCard(
                    label: 'Total Reps',
                    value: '${stats.totalReps}',
                    icon: Icons.sync,
                    trend: delta != null ? _formatDelta(delta.totalReps) : null,
                    trendPositive: delta != null && delta.totalReps >= 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppStatsCard(
                    label: 'Workout Time',
                    value: '${stats.totalMinutes} min',
                    icon: Icons.timer_outlined,
                    trend: delta != null
                        ? _formatDelta(delta.totalMinutes)
                        : null,
                    trendPositive: delta != null && delta.totalMinutes >= 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatsCard(
                    label: 'Avg Duration',
                    value: '${stats.averageSessionDuration} min',
                    icon: Icons.schedule_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDelta(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }

  String _formatDeltaDouble(double value) {
    if (value > 0) return '+${value.toStringAsFixed(0)}';
    return value.toStringAsFixed(0);
  }
}

// ──────────────────────────────────────────────────────────
// Sessions Tab — Paginated list of workout sessions
// ──────────────────────────────────────────────────────────

class _SessionsTab extends ConsumerWidget {
  const _SessionsTab({required this.userId, required this.isDark});

  final String userId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientSessionsProvider);

    return switch (state) {
      ClientSessionsInitial() || ClientSessionsLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ClientSessionsError(:final error) => Center(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load sessions',
          description: error.message,
          actionLabel: 'Retry',
          onAction: () =>
              ref.read(clientSessionsProvider.notifier).loadSessions(userId),
        ),
      ),
      ClientSessionsLoaded(:final sessions, :final pagination) =>
        sessions.isEmpty
            ? const Center(
                child: AppEmptyState(
                  icon: Icons.fitness_center,
                  title: 'No Sessions Yet',
                  description:
                      'This client hasn\'t completed any workout sessions.',
                ),
              )
            : _buildSessionList(context, ref, sessions, pagination),
    };
  }

  Widget _buildSessionList(
    BuildContext context,
    WidgetRef ref,
    List<ClientSessionSummary> sessions,
    PaginationMeta pagination,
  ) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientSessionsProvider.notifier).loadSessions(userId),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sessions.length + (pagination.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= sessions.length) {
            Future.microtask(
              () => ref.read(clientSessionsProvider.notifier).loadMore(userId),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final session = sessions[index];
          return _SessionCard(
            session: session,
            isDark: isDark,
            onTap: () => context.push(
              AppRoutes.clientSessionDetail
                  .replaceFirst(':userId', userId)
                  .replaceFirst(':sessionId', session.id),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isDark,
    required this.onTap,
  });

  final ClientSessionSummary session;
  final bool isDark;
  final VoidCallback onTap;

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
                  session.programName ?? 'Standalone Workout',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (session.completedAt != null)
                AppBadge(label: 'Completed', variant: AppBadgeVariant.success)
              else
                const AppBadge(
                  label: 'Active',
                  variant: AppBadgeVariant.warning,
                ),
            ],
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
                _formatDate(session.startedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              if (session.durationMinutes != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.durationMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(
                label: '${session.totalSets} sets',
                icon: Icons.repeat,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: '${session.uniqueExercises} exercises',
                icon: Icons.fitness_center,
                isDark: isDark,
              ),
            ],
          ),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              session.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.mutedForegroundDark
                  : AppColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Form Results Tab — Paginated form comparison results
// ──────────────────────────────────────────────────────────

class _FormResultsTab extends ConsumerWidget {
  const _FormResultsTab({required this.userId, required this.isDark});

  final String userId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientFormResultsProvider);

    return switch (state) {
      ClientFormResultsInitial() || ClientFormResultsLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ClientFormResultsError(:final error) => Center(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load form results',
          description: error.message,
          actionLabel: 'Retry',
          onAction: () => ref
              .read(clientFormResultsProvider.notifier)
              .loadFormResults(userId),
        ),
      ),
      ClientFormResultsLoaded(:final results, :final pagination) =>
        results.isEmpty
            ? const Center(
                child: AppEmptyState(
                  icon: Icons.compare,
                  title: 'No Form Results',
                  description:
                      'This client hasn\'t submitted any form comparisons yet.',
                ),
              )
            : _buildFormList(context, ref, results, pagination),
    };
  }

  Widget _buildFormList(
    BuildContext context,
    WidgetRef ref,
    List<ClientFormResult> results,
    PaginationMeta pagination,
  ) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientFormResultsProvider.notifier).loadFormResults(userId),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: results.length + (pagination.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= results.length) {
            Future.microtask(
              () =>
                  ref.read(clientFormResultsProvider.notifier).loadMore(userId),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final result = results[index];
          return _FormResultCard(
            result: result,
            isDark: isDark,
            onTap: () => context.push(
              AppRoutes.clientFormReview
                  .replaceFirst(':userId', userId)
                  .replaceFirst(':resultId', result.id),
              extra: result,
            ),
          );
        },
      ),
    );
  }
}

class _FormResultCard extends StatelessWidget {
  const _FormResultCard({
    required this.result,
    required this.isDark,
    required this.onTap,
  });

  final ClientFormResult result;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scorePercent = (result.overallScore * 100).toInt();
    final exerciseName =
        result.exerciseForm?.exercise?.name ?? 'Unknown Exercise';
    final coachName = result.exerciseForm?.coach?.name;

    return AppCard.interactive(
      onTap: onTap,
      child: Row(
        children: [
          // Score circle
          _ScoreBadge(score: scorePercent, isDark: isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (coachName != null)
                  Text(
                    'Coach: $coachName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(result.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                    if (result.corrections.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      AppBadge(
                        label: '${result.corrections.length} corrections',
                        variant: AppBadgeVariant.warning,
                      ),
                    ],
                  ],
                ),
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

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.isDark});

  final int score;
  final bool isDark;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.15),
        border: Border.all(color: _color, width: 2),
      ),
      child: Center(
        child: Text(
          '$score%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
