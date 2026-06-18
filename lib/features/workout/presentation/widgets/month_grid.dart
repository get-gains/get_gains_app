import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../workout/data/models/models.dart';

/// Calendar month grid showing workout days with indicators.
///
/// Displays a 7×6 grid of day cells. Days with workouts get a dot indicator.
/// Today gets a ring border. Tapping a day triggers [onDayTap].
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.workoutDays,
    required this.onDayTap,
    this.selectedDay,
  });

  final DateTime month;
  final Map<DateTime, List<WorkoutSessionSummary>> workoutDays;
  final ValueChanged<DateTime> onDayTap;
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Offset: Mon=0 ... Sun=6
    // DateTime.weekday: Mon=1 ... Sun=7
    final firstWeekday = firstDayOfMonth.weekday - 1;
    final daysInMonth = lastDayOfMonth.day;

    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const _CalendarDay.empty());
    }

    // Day cells
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final hasWorkout = workoutDays.containsKey(date);
      final isToday = _isToday(date);
      final isSelected = selectedDay != null &&
          date.year == selectedDay!.year &&
          date.month == selectedDay!.month &&
          date.day == selectedDay!.day;

      cells.add(
        _CalendarDay(
          day: d,
          hasWorkout: hasWorkout,
          isToday: isToday,
          isSelected: isSelected,
          onTap: () => onDayTap(date),
        ),
      );
    }

    // Fill remaining cells to complete 6 rows (42 total)
    while (cells.length < 42) {
      cells.add(const _CalendarDay.empty());
    }

    // Build 7-column day headers
    final dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        _DayHeaderRow(labels: dayHeaders),
        const SizedBox(height: 4),
        SizedBox(
          height: 42 * 6, // 6 rows
          child: GridView.count(
            crossAxisCount: 7,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            childAspectRatio: 1,
            children: cells,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    // Use toLocal() explicitly so the comparison is always against the
    // device's local calendar date, not UTC (critical for UTC+ timezones).
    final now = DateTime.now().toLocal();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.hasWorkout,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  }) : isEmpty = false;

  const _CalendarDay.empty()
      : day = 0,
        hasWorkout = false,
        isToday = false,
        isSelected = false,
        isEmpty = true,
        onTap = null;

  final int day;
  final bool hasWorkout;
  final bool isToday;
  final bool isSelected;
  final bool isEmpty;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final accent = AppColors.accentDark;

    if (isEmpty) {
      return const SizedBox.shrink();
    }

    // Day background when workout exists
    final dayBackground = hasWorkout
        ? const BoxDecoration(
            color: Color(0xFF4ADE80),
            shape: BoxShape.circle,
          )
        : null;

    Widget cell = Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: dayBackground,
        child: Center(
          child: Text(
            '$day',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasWorkout
                      ? Colors.black
                      : (isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight),
                  fontWeight: isToday || hasWorkout
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
          ),
        ),
      ),
    );

    cell = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isToday
            ? Border.all(
                color: hasWorkout ? accent : primary,
                width: 2,
              )
            : null,
      ),
      child: cell,
    );

    if (onTap != null) {
      cell = GestureDetector(
        onTap: onTap,
        child: cell,
      );
    }

    return cell;
  }
}
