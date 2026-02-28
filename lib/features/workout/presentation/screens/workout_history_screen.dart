// lib/features/workout/presentation/screens/workout_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

/// Paginated workout session history provider.
///
/// Fetches workout sessions in pages of 20. The family parameter
/// is the page number (0-based).
final workoutHistoryPageProvider = FutureProvider.autoDispose
    .family<WorkoutHistoryResponse, int>((ref, page) async {
  const pageSize = 20;
  final repo = ref.watch(workoutRepositoryProvider);
  final result = await repo.getSessionHistory(
    limit: pageSize,
    offset: page * pageSize,
  );
  return result.when(
    success: (response) => response,
    failure: (error) => throw error,
  );
});

/// Workout History Screen (M-CL5)
///
/// Displays a paginated list of completed workout sessions.
/// Each session shows the routine name, date, duration, and sets count.
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  final List<WorkoutSessionSummary> _sessions = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    // We trigger the provider and wait for its result
    try {
      final response =
          await ref.read(workoutHistoryPageProvider(page).future);
      if (mounted) {
        setState(() {
          if (page == 0) _sessions.clear();
          _sessions.addAll(response.sessions);
          _hasMore = response.pagination.hasMore;
          _currentPage = page;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(workoutHistoryPageProvider);
    await _loadPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstPageAsync = ref.watch(workoutHistoryPageProvider(0));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Workout History',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            // Handle initial loading / error
            if (_sessions.isEmpty)
              firstPageAsync.when(
                data: (_) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: AppErrorState(
                    title: 'Failed to load history',
                    description: '$error',
                    onRetry: _onRefresh,
                  ),
                ),
              )
            else ...[
              // Sessions list
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _sessions.length) {
                        // Load more trigger
                        if (_hasMore && !_isLoadingMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadPage(_currentPage + 1);
                          });
                        }
                        return _hasMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      final session = _sessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionCard(
                          session: session,
                          isDark: isDark,
                        ),
                      );
                    },
                    childCount: _sessions.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
            ],

            // Empty state
            if (_sessions.isEmpty && firstPageAsync.hasValue)
              SliverFillRemaining(
                child: AppEmptyState(
                  icon: Icons.history,
                  title: 'No Workouts Yet',
                  description:
                      'Your completed workouts will appear here. Start a workout to build your history!',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying a single workout session summary.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.isDark});

  final WorkoutSessionSummary session;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMd().format(session.startedAt);
    final timeStr = DateFormat.jm().format(session.startedAt);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (session.isCompleted
                        ? (isDark
                            ? AppColors.accentDark
                            : const Color(0xFF22C55E))
                        : (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                session.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.timer_outlined,
                color: session.isCompleted
                    ? (isDark
                        ? AppColors.accentDark
                        : const Color(0xFF22C55E))
                    : (isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateStr · $timeStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            // Right-side stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.durationDisplay,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.totalSets} sets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
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
