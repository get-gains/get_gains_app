// lib/features/workout/presentation/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../home/presentation/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../widgets/total_volume_per_month_card.dart';

/// Progress / Stats Screen (M-CL9)
///
/// Displays the user's workout statistics and progress data:
/// - Weekly stats (workouts, minutes, streak)
/// - Recent workout history summary
/// - Quick navigation to full workout history
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyAsync = ref.watch(unifiedWeeklyStatsProvider);
    final recentAsync = ref.watch(recentActivityProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(unifiedWeeklyStatsProvider);
            ref.invalidate(recentActivityProvider);
            ref.invalidate(monthlyInsightProvider);
            await ref.read(unifiedWeeklyStatsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'Progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Weekly Overview ──────────────────────────
                    _SectionHeader(title: 'This Week', isDark: isDark),
                    const SizedBox(height: 12),
                    weeklyAsync.when(
                      data: (stats) => WeeklyProgressCard(
                        workoutsCompleted: stats.workoutsCompleted,
                        workoutsGoal: 4, // TODO: make configurable
                        totalMinutes: stats.totalMinutes,
                        streakDays: stats.streakDays,
                        completedWeekdays: stats.completedWeekdays,
                        onTap: () => context.push(AppRoutes.workoutCalendar),
                      ),
                      loading: () => const _StatsLoadingSkeleton(),
                      error: (error, _) => AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: AppErrorState(
                            title: 'Could not load stats',
                            description: '$error',
                            onRetry: () =>
                                ref.invalidate(unifiedWeeklyStatsProvider),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Summary Stats Card ──────────────────────
                    weeklyAsync.when(
                      data: (stats) =>
                          _SummaryStatsCard(stats: stats, isDark: isDark),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // ── Per-Source Breakdown ─────────────────────
                    weeklyAsync.when(
                      data: (stats) => stats.sources.isNotEmpty
                          ? _SourceBreakdownSection(
                              stats: stats,
                              isDark: isDark,
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // ── Empty State Encouragement ────────────────
                    weeklyAsync.when(
                      data: (stats) =>
                          _StatsEmptyState(stats: stats, isDark: isDark),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // ── Total Volume per Month ───────────────────
                    TotalVolumePerMonthCard(
                      onTap: () {
                        final month =
                            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
                        context.push(
                          AppRoutes.monthlySessions.replaceFirst(
                            ':month',
                            month,
                          ),
                        );
                      },
                    ),

                    // ── Recent Workouts ─────────────────────────
                    _SectionHeader(
                      title: 'Recent Workouts',
                      isDark: isDark,
                      action: TextButton(
                        onPressed: () => context.push(AppRoutes.workoutHistory),
                        child: const Text('See All'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    recentAsync.when(
                      data: (sessions) => sessions.isEmpty
                          ? AppEmptyState.compact(
                              icon: Icons.history,
                              title: 'No Recent Workouts',
                              description: 'Complete a workout to see it here.',
                            )
                          : Column(
                              children: sessions
                                  .map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _RecentSessionTile(
                                        session: s,
                                        isDark: isDark,
                                        onTap: () => context.push(
                                          AppRoutes.workoutSessionDetail
                                              .replaceFirst(':id', s.id),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => AppEmptyState.compact(
                        icon: Icons.error_outline,
                        title: 'Could not load activity',
                        description: '$error',
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.action,
  });

  final String title;
  final bool isDark;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// Summary card showing key stats in a grid format.
class _SummaryStatsCard extends StatelessWidget {
  const _SummaryStatsCard({required this.stats, required this.isDark});

  final UnifiedWeeklyStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Workouts',
                    value: '${stats.workoutsCompleted}',
                    icon: Icons.fitness_center,
                    iconColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    label: 'Total Time',
                    value: stats.totalTimeDisplay,
                    icon: Icons.timer,
                    iconColor: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Streak',
                    value: '${stats.streakDays} days',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    label: 'Avg / Workout',
                    value: stats.workoutsCompleted > 0
                        ? '${(stats.totalMinutes / stats.workoutsCompleted).round()}m'
                        : '—',
                    icon: Icons.speed,
                    iconColor: isDark
                        ? AppColors.accentDark
                        : const Color(0xFF22C55E),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays per-source breakdown when multiple sources exist.
class _SourceBreakdownSection extends StatelessWidget {
  const _SourceBreakdownSection({required this.stats, required this.isDark});

  final UnifiedWeeklyStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _SectionHeader(title: 'By Source', isDark: isDark),
        const SizedBox(height: 12),
        ...stats.sources.map(
          (source) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SourceCard(source: source, isDark: isDark),
          ),
        ),
      ],
    );
  }
}

/// Card showing stats for a single source (standalone or coach).
class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.isDark});

  final SourceStats source;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isCoach = source.type == 'coach';
    final labelColor = isCoach
        ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    source.sourceLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isCoach && source.programName != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      source.programName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(
                  label: 'Workouts',
                  value: '${source.workoutsCompleted}',
                  isDark: isDark,
                ),
                const SizedBox(width: 24),
                _MiniStat(
                  label: 'Time',
                  value: source.totalTimeDisplay,
                  isDark: isDark,
                ),
                const SizedBox(width: 24),
                _MiniStat(
                  label: 'Streak',
                  value: '${source.streakDays}d',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact stat display for source breakdown cards.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tile for a recent workout session.
class _RecentSessionTile extends StatelessWidget {
  const _RecentSessionTile({
    required this.session,
    required this.isDark,
    this.onTap,
  });

  final WorkoutSessionSummary session;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatRelativeDate(session.startedAt);

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              session.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: session.isCompleted
                  ? (isDark ? AppColors.accentDark : const Color(0xFF22C55E))
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              session.durationDisplay,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Skeleton loading placeholder for the weekly stats card.
class _StatsLoadingSkeleton extends StatelessWidget {
  const _StatsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface2Dark
                    : AppColors.surface2Light,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 10,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface2Dark
                    : AppColors.surface2Light,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface2Dark
                          : AppColors.surface2Light,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface2Dark
                          : AppColors.surface2Light,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface2Dark
                          : AppColors.surface2Light,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Contextual empty state encouragement based on source availability.
///
/// - Both sources empty → general "Start a Workout" CTA
/// - No standalone sessions → "Start a Workout" encouragement
/// - No coach sessions (subscribed user) → "Start a Coach Program" message
class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState({required this.stats, required this.isDark});

  final UnifiedWeeklyStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // If user has activity, no empty state needed
    if (stats.hasActivity) return const SizedBox.shrink();

    // Both sources empty — general encouragement
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppEmptyState.compact(
        icon: Icons.fitness_center,
        title: 'No Workouts This Week',
        description:
            'Start a workout to track your progress and build streaks!',
      ),
    );
  }
}
