import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/app_bottom_sheet.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/models.dart';
import '../providers/calendar_provider.dart';
import '../widgets/month_grid.dart';

/// Workout calendar screen — monthly view with workout day indicators.
///
/// Shows a month grid with green dots on days the user worked out.
/// Tapping a day opens a bottom sheet listing each session for that day.
/// Arrow buttons navigate between months. Pull-to-refresh reloads data.
class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Use toLocal() so the calendar opens on the correct local month
    // for users in UTC+ timezones past UTC midnight.
    final now = DateTime.now().toLocal();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthLabel = DateFormat('MMMM yyyy').format(_currentMonth);

    final workoutAsync =
        ref.watch(monthlyWorkoutDaysProvider(_currentMonth));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(monthlyWorkoutDaysProvider(_currentMonth));
            await ref.read(
              monthlyWorkoutDaysProvider(_currentMonth).future,
            );
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
                  'Workout Calendar',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                    // Month nav
                    _MonthNavHeader(
                      monthLabel: monthLabel,
                      isDark: isDark,
                      onPrevious: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month - 1,
                            1,
                          );
                        });
                      },
                      onNext: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month + 1,
                            1,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Calendar grid
                    workoutAsync.when(
                      data: (workoutDays) => MonthGrid(
                        month: _currentMonth,
                        workoutDays: workoutDays,
                        selectedDay: _selectedDay,
                        onDayTap: (date) {
                          setState(() => _selectedDay = date);
                          final sessions = workoutDays[date];
                          _showDayDetail(context, date, sessions ?? []);
                        },
                      ),
                      loading: () => Column(
                        children: [
                          MonthGrid(
                            month: _currentMonth,
                            workoutDays: const {},
                            onDayTap: (_) {},
                          ),
                          const SizedBox(height: 16),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                      error: (error, _) => Column(
                        children: [
                          MonthGrid(
                            month: _currentMonth,
                            workoutDays: const {},
                            onDayTap: (_) {},
                          ),
                          const SizedBox(height: 16),
                          AppErrorState(
                            title: 'Could not load calendar',
                            description: '$error',
                            onRetry: () => ref.invalidate(
                              monthlyWorkoutDaysProvider(_currentMonth),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Monthly summary
                    workoutAsync.when(
                      data: (workoutDays) =>
                          _MonthSummary(workoutDays: workoutDays, isDark: isDark),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
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

  void _showDayDetail(
    BuildContext context,
    DateTime date,
    List<WorkoutSessionSummary> sessions,
  ) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(date);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppBottomSheet(
      context: context,
      builder: (sheetContext) => _DayDetailSheet(
        dateLabel: dateLabel,
        sessions: sessions,
        isDark: isDark,
      ),
    );
  }
}

/// Month navigation header with `<` `>` arrows.
class _MonthNavHeader extends StatelessWidget {
  const _MonthNavHeader({
    required this.monthLabel,
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
  });

  final String monthLabel;
  final bool isDark;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.foregroundDark : AppColors.foregroundLight;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: mutedColor),
              onPressed: onPrevious,
            ),
            Text(
              monthLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: mutedColor),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing sessions for a selected day.
class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({
    required this.dateLabel,
    required this.sessions,
    required this.isDark,
  });

  final String dateLabel;
  final List<WorkoutSessionSummary> sessions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _RestDayContent(dateLabel: dateLabel, isDark: isDark);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          dateLabel,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${sessions.length} workout${sessions.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: 16),

        // Session list
        ...sessions.map((s) => _SessionTile(session: s, isDark: isDark)),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Empty state for days with no workouts.
class _RestDayContent extends StatelessWidget {
  const _RestDayContent({required this.dateLabel, required this.isDark});

  final String dateLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState.compact(
      icon: Icons.bedtime_rounded,
      title: dateLabel,
      description: 'Rest day — no workouts recorded.',
    );
  }
}

/// Individual session tile in the day detail sheet.
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.isDark});

  final WorkoutSessionSummary session;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final startTime =
        DateFormat('h:mm a').format(session.startedAt.toLocal());
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () {
          final route =
              AppRoutes.workoutSessionDetail.replaceFirst(':id', session.id);
          context.push(route);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 20,
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$startTime · ${session.durationDisplay} · ${session.totalSets} sets',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary stats for the current month.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.workoutDays, required this.isDark});

  final Map<DateTime, List<WorkoutSessionSummary>> workoutDays;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalSessions =
        workoutDays.values.fold<int>(0, (sum, s) => sum + s.length);
    final totalDays = workoutDays.length;

    if (totalDays == 0) {
      return const SizedBox.shrink();
    }

    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Workout Days',
                value: '$totalDays',
                icon: Icons.calendar_month,
                iconColor: primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Total Sessions',
                value: '$totalSessions',
                icon: Icons.fitness_center,
                iconColor: const Color(0xFF4ADE80),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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
