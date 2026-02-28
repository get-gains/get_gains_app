import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/standalone_session_provider.dart';

/// Standalone Session History Screen
///
/// Displays a paginated list of past workout sessions with
/// pull-to-refresh and infinite scroll.
class StandaloneSessionHistoryScreen extends ConsumerStatefulWidget {
  const StandaloneSessionHistoryScreen({super.key});

  @override
  ConsumerState<StandaloneSessionHistoryScreen> createState() =>
      _StandaloneSessionHistoryScreenState();
}

class _StandaloneSessionHistoryScreenState
    extends ConsumerState<StandaloneSessionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(standaloneSessionHistoryProvider.notifier).loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standaloneSessionHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(StandaloneSessionHistoryState state, bool isDark) {
    return switch (state) {
      StandaloneSessionHistoryInitial() || StandaloneSessionHistoryLoading() =>
        const Center(child: CircularProgressIndicator()),
      StandaloneSessionHistoryError(:final error) => _buildError(error, isDark),
      StandaloneSessionHistoryLoaded(:final sessions) =>
        sessions.isEmpty
            ? _buildEmpty()
            : _buildList(state as StandaloneSessionHistoryLoaded, isDark),
    };
  }

  Widget _buildEmpty() {
    return const AppEmptyState(
      icon: Icons.history,
      title: 'No Sessions Yet',
      description: 'Complete your first workout to see it here.',
    );
  }

  Widget _buildError(AppError error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? AppColors.error : AppColors.errorLight,
          ),
          const SizedBox(height: 12),
          Text(
            error.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: () => ref
                .read(standaloneSessionHistoryProvider.notifier)
                .loadHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(StandaloneSessionHistoryLoaded loaded, bool isDark) {
    final sessions = loaded.sessions;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(standaloneSessionHistoryProvider.notifier).loadHistory(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: sessions.length + (loaded.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= sessions.length) {
            Future.microtask(
              () => ref
                  .read(standaloneSessionHistoryProvider.notifier)
                  .loadMore(),
            );
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final session = sessions[index];
          return _SessionCard(session: session, isDark: isDark);
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Session Card
// ──────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.isDark});

  final StandaloneSessionSummary session;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.Hm();

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.displayName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppBadge(
                label: session.isCompleted ? 'Completed' : 'In Progress',
                variant: session.isCompleted
                    ? AppBadgeVariant.primary
                    : AppBadgeVariant.warning,
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
                dateFormat.format(session.startedAt.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: 14,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(width: 4),
              Text(
                timeFormat.format(session.startedAt.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(width: 12),
              if (session.isCompleted) ...[
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 4),
                Text(
                  session.durationDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ],
          ),
          if (session.totalSets > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.totalSets} sets',
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
            const Divider(height: 16),
            Text(
              session.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
