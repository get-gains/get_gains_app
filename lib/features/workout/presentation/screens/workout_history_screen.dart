// lib/features/workout/presentation/screens/workout_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/workout_repository.dart';

/// Source filter options for session history.
enum _SourceFilter {
  all('All', 'all'),
  coach('Coach', 'coach'),
  solo('Solo', 'standalone');

  const _SourceFilter(this.label, this.queryValue);
  final String label;
  final String queryValue;
}

/// Paginated workout session history provider.
///
/// Fetches workout sessions in pages of 20. The family parameter
/// is the page number (0-based). Uses local DB for offline-first access.
final workoutHistoryPageProvider = FutureProvider.autoDispose
    .family<WorkoutHistoryResponse, int>((ref, page) async {
      const pageSize = 20;
      final repo = ref.watch(workoutRepositoryProvider);
      final userId = ref.watch(authStateProvider).userId;

      if (userId == null) throw Exception('Not authenticated');

      // Try local DB first (offline-first)
      final localResult = await repo.getLocalSessionHistory(
        userId: userId,
        limit: pageSize,
        offset: page * pageSize,
      );
      return localResult.when(
        success: (response) => response,
        failure: (error) => throw error,
      );
    });

/// Workout History Screen
///
/// Displays a paginated list of completed workout sessions from both
/// standalone and coach sources. Each session shows a source badge
/// ("Coach" or "Solo"), routine name, date, duration, and sets count.
///
/// Filter tabs (All / Coach / Solo) allow filtering by source.
/// Free and expired users see full session history including historical
/// coach sessions — no subscription gating on read access (FR-014).
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  final List<UnifiedSessionSummary> _sessions = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoad = true;
  bool _hasError = false;
  String _errorMessage = '';
  _SourceFilter _activeFilter = _SourceFilter.all;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      if (page == 0) _hasError = false;
    });

    final repo = ref.read(workoutRepositoryProvider);
    final result = await repo.getUnifiedSessionHistory(
      source: _activeFilter.queryValue,
      limit: _pageSize,
      offset: page * _pageSize,
    );

    if (!mounted) return;

    result.when(
      success: (response) {
        setState(() {
          if (page == 0) _sessions.clear();
          _sessions.addAll(response.sessions);
          _hasMore = response.pagination.hasMore;
          _currentPage = page;
          _isLoadingMore = false;
          _isInitialLoad = false;
        });
      },
      failure: (error) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoad = false;
          if (page == 0) {
            _hasError = true;
            _errorMessage = '$error';
          }
        });
      },
    );
  }

  Future<void> _onRefresh() async {
    await _loadPage(0);
  }

  void _onFilterChanged(_SourceFilter filter) {
    if (filter == _activeFilter) return;
    setState(() {
      _activeFilter = filter;
      _sessions.clear();
      _isInitialLoad = true;
      _hasMore = true;
      _currentPage = 0;
    });
    _loadPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),

              // Filter tabs
              SliverToBoxAdapter(
                child: _FilterTabs(
                  activeFilter: _activeFilter,
                  onFilterChanged: _onFilterChanged,
                  isDark: isDark,
                ),
              ),

              // Initial loading state
              if (_isInitialLoad)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              // Error state
              else if (_hasError && _sessions.isEmpty)
                SliverFillRemaining(
                  child: AppErrorState(
                    title: 'Failed to load history',
                    description: _errorMessage,
                    onRetry: _onRefresh,
                  ),
                )
              // Empty state
              else if (_sessions.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.history,
                    title: _activeFilter == _SourceFilter.all
                        ? 'No Workouts Yet'
                        : 'No ${_activeFilter.label} Workouts',
                    description: _activeFilter == _SourceFilter.all
                        ? 'Your completed workouts will appear here. Start a workout to build your history!'
                        : _activeFilter == _SourceFilter.coach
                        ? 'You don\'t have any coach workout sessions yet.'
                        : 'You don\'t have any solo workout sessions yet.',
                  ),
                )
              // Sessions list
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      final session = _sessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _UnifiedSessionCard(
                          session: session,
                          isDark: isDark,
                        ),
                      );
                    }, childCount: _sessions.length + (_hasMore ? 1 : 0)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter tabs for session history: All / Coach / Solo.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.isDark,
  });

  final _SourceFilter activeFilter;
  final ValueChanged<_SourceFilter> onFilterChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: _SourceFilter.values.map((filter) {
          final isActive = filter == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isActive,
              onSelected: (_) => onFilterChanged(filter),
              selectedColor: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                  : AppColors.primaryLight.withValues(alpha: 0.2),
              checkmarkColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isActive
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              backgroundColor: isDark
                  ? AppColors.surface2Dark
                  : AppColors.surface2Light,
              side: BorderSide(
                color: isActive
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : Colors.transparent,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Card displaying a single unified session summary with source badge.
class _UnifiedSessionCard extends StatelessWidget {
  const _UnifiedSessionCard({required this.session, required this.isDark});

  final UnifiedSessionSummary session;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMd().format(session.startedAt);
    final timeStr = DateFormat.jm().format(session.startedAt);
    final coachSubtitle = session.coachSubtitle;

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
                color:
                    (session.isCompleted
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
                    ? (isDark ? AppColors.accentDark : const Color(0xFF22C55E))
                    : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          session.displayName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SourceBadge(source: session.source),
                    ],
                  ),
                  if (coachSubtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      coachSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
            const SizedBox(width: 8),
            // Right-side stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.durationDisplay,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
