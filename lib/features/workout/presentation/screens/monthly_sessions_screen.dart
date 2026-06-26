import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/monthly_sessions_provider.dart';

/// Screen showing all completed sessions for a given month.
///
/// Receives a [month] in YYYY-MM format via the route. Fetches sessions
/// from the server calendar endpoint and displays them as tappable cards.
class MonthlySessionsScreen extends ConsumerWidget {
  const MonthlySessionsScreen({super.key, required this.month});

  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final [yearStr, monthStr] = month.split('-');
    final year = int.parse(yearStr);
    final monthNum = int.parse(monthStr);
    final monthName = DateFormat.MMMM().format(DateTime(year, monthNum));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sessionsAsync = ref.watch(monthlySessionsProvider(month));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('$monthName $year'),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: AppEmptyState.compact(
                icon: Icons.calendar_today_outlined,
                title: 'No sessions this month',
                description: 'Workouts completed in $monthName $year will appear here.',
              ),
            );
          }

          final grouped = _groupByDay(sessions);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: grouped.entries.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              final date = entry.key;
              final daySessions = entry.value;
              final dayLabel = _dayLabel(date, year, monthNum);

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        dayLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    ...daySessions.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SessionCard(
                          session: s,
                          isDark: isDark,
                          onTap: () => context.push(
                            AppRoutes.workoutSessionDetail.replaceFirst(
                              ':id',
                              s.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: AppEmptyState.compact(
            icon: Icons.error_outline,
            title: 'Failed to load',
            description: error.toString(),
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<WorkoutSessionSummary>> _groupByDay(
    List<WorkoutSessionSummary> sessions,
  ) {
    final map = <DateTime, List<WorkoutSessionSummary>>{};
    for (final s in sessions) {
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }

  String _dayLabel(DateTime date, int year, int monthNum) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == todayDay) return 'Today — ${DateFormat.MMMd().format(date)}';
    if (day == todayDay.subtract(const Duration(days: 1))) {
      return 'Yesterday — ${DateFormat.MMMd().format(date)}';
    }
    return DateFormat.MMMd().add_EEEE().format(date);
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isDark,
    this.onTap,
  });

  final WorkoutSessionSummary session;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.jm().format(session.startedAt);
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (session.isCompleted
                        ? (isDark ? AppColors.accentDark : const Color(0xFF22C55E))
                        : (isDark ? AppColors.primaryDark : AppColors.primaryLight))
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: secondaryText),
                  ),
                ],
              ),
            ),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: secondaryText),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
