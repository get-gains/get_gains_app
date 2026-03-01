// lib/features/coach_client_progress/presentation/screens/performance_dashboard_screen.dart

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

/// Performance Dashboard Screen
///
/// Displays a detailed performance report across all of a coach's clients:
/// - Summary cards (total clients, good standing, falling behind, avg adherence)
/// - Filterable & paginated client performance list
/// - Tap a client row to navigate to their progress detail
///
/// Navigated from the Coach Hub via `AppRoutes.coachPerformanceDashboard`.
class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen> {
  String _filterStatus = 'all'; // 'all' | 'good' | 'falling_behind'

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(detailedPerformanceProvider.notifier).loadPerformance(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(detailedPerformanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Performance Dashboard',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: switch (state) {
        DetailedPerformanceInitial() || DetailedPerformanceLoading() =>
          const Center(child: CircularProgressIndicator()),
        DetailedPerformanceError(:final error) => Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load performance data',
            description: error.message,
            actionLabel: 'Retry',
            onAction: () => ref
                .read(detailedPerformanceProvider.notifier)
                .loadPerformance(),
          ),
        ),
        DetailedPerformanceLoaded(
          :final performance,
          :final summary,
          :final pagination,
        ) =>
          _buildContent(context, performance, summary, pagination, isDark),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ClientPerformanceEntry> performance,
    PerformanceSummary summary,
    PaginationMeta pagination,
    bool isDark,
  ) {
    // Apply local filter
    final filtered = _filterStatus == 'all'
        ? performance
        : performance.where((e) => e.status == _filterStatus).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(detailedPerformanceProvider.notifier).loadPerformance(),
      child: Column(
        children: [
          // ── Summary Cards ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppStatsCard(
                        label: 'Total Clients',
                        value: '${summary.total}',
                        icon: Icons.people,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppStatsCard(
                        label: 'Avg Adherence',
                        value: '${summary.averageAdherence}%',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppStatsCard(
                        label: 'Good Standing',
                        value: '${summary.good}',
                        icon: Icons.thumb_up_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppStatsCard(
                        label: 'Falling Behind',
                        value: '${summary.fallingBehind}',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Filter Tabs ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppTabs(
              tabs: const ['All', 'Good', 'Falling Behind'],
              selectedIndex: _filterStatus == 'all'
                  ? 0
                  : _filterStatus == 'good'
                  ? 1
                  : 2,
              onChanged: (index) {
                setState(() {
                  _filterStatus = switch (index) {
                    0 => 'all',
                    1 => 'good',
                    _ => 'falling_behind',
                  };
                });
              },
              variant: AppTabVariant.segmented,
              size: AppTabSize.sm,
            ),
          ),

          // ── Client List ────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: AppEmptyState(
                      icon: Icons.check_circle,
                      title: 'No clients in this category',
                      description: _filterStatus == 'falling_behind'
                          ? 'Great — all your clients are on track!'
                          : 'No clients match this filter.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length + (pagination.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= filtered.length) {
                        Future.microtask(
                          () => ref
                              .read(detailedPerformanceProvider.notifier)
                              .loadMore(),
                        );
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final entry = filtered[index];
                      return _PerformanceClientCard(
                        entry: entry,
                        isDark: isDark,
                        onTap: () => context.push(
                          AppRoutes.clientProgress.replaceFirst(
                            ':userId',
                            entry.id,
                          ),
                          extra: entry.nickname ?? entry.name,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Performance Client Card
// ──────────────────────────────────────────────────────────

class _PerformanceClientCard extends StatelessWidget {
  const _PerformanceClientCard({
    required this.entry,
    required this.isDark,
    required this.onTap,
  });

  final ClientPerformanceEntry entry;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = entry.nickname ?? entry.name;
    final isFallingBehind = entry.status == 'falling_behind';

    return AppCard.interactive(
      onTap: onTap,
      borderColor: isFallingBehind
          ? (isDark ? AppColors.warning : AppColors.warningMuted)
          : null,
      child: Row(
        children: [
          AppAvatar(name: displayName, size: AppAvatarSize.md),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppBadge(
                      label: isFallingBehind ? 'Needs Attention' : 'Good',
                      variant: isFallingBehind
                          ? AppBadgeVariant.warning
                          : AppBadgeVariant.success,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Stats row
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MiniMetric(
                      icon: Icons.fitness_center,
                      value: '${entry.sessionsThisWeek} sessions',
                      isDark: isDark,
                    ),
                    _MiniMetric(
                      icon: Icons.monitor_weight_outlined,
                      value: '${entry.totalVolume.toStringAsFixed(0)} kg',
                      isDark: isDark,
                    ),
                    if (entry.adherenceRate != null)
                      _MiniMetric(
                        icon: Icons.check_circle_outline,
                        value: '${entry.adherenceRate}% adherence',
                        isDark: isDark,
                      ),
                  ],
                ),
                if (entry.activeProgramName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.activeProgramName!,
                    style: theme.textTheme.labelSmall?.copyWith(
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
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
        ),
      ],
    );
  }
}
