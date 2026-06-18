/// A single month in the 6-month volume sparkline window.
///
/// Derived from [MonthlyInsight.sparklineVolumes] and
/// [MonthlyInsight.sparklineSessions], which are session-grained
/// (server already divides by session ID arrays, not set counts).

import 'monthly_insight_model.dart';

class MonthlyVolume {
  /// Short month label, e.g. "Jan", "Feb".
  final String month;

  /// Total kg lifted in that month (sum of reps × weight across all sets).
  final double totalVolume;

  /// Number of distinct completed workout sessions in that month.
  /// Session-grained, not set-grained. Verified by audit 2026-06-18.
  final int sessionCount;

  /// Percent change in totalVolume vs the previous month (null for oldest).
  final double? percentChangeVsPrevMonth;

  const MonthlyVolume({
    required this.month,
    required this.totalVolume,
    required this.sessionCount,
    this.percentChangeVsPrevMonth,
  });

  /// Derives a [List<MonthlyVolume>] from a [MonthlyInsight] by pairing
  /// [sparklineVolumes] and [sparklineSessions] at each index and
  /// computing month labels relative to the target month.
  ///
  /// Index 5 is the current/target month, index 4 is one month prior, etc.
  static List<MonthlyVolume> fromSparkline(MonthlyInsight insight) {
    const monthLabels = [
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

    // Parse the target month from insight.month ("YYYY-MM")
    final parts = insight.month.split('-');
    final targetYear = int.parse(parts[0]);
    final targetMonth = int.parse(parts[1]);

    final length = insight.sparklineVolumes.length;
    if (length == 0) return const [];

    final result = <MonthlyVolume>[];

    for (int i = 0; i < length; i++) {
      // Month offset: index 5 = target month, index 4 = target-1, etc.
      final offsetFromTarget = -(length - 1 - i);
      final rawMonth = targetMonth - 1 + offsetFromTarget; // 0-based
      final year = targetYear + (rawMonth ~/ 12);
      final monthIdx = ((rawMonth % 12) + 12) % 12; // positive modulo
      final label = monthLabels[monthIdx];

      final volume = i < insight.sparklineVolumes.length
          ? insight.sparklineVolumes[i]
          : 0.0;
      final sessions = i < insight.sparklineSessions.length
          ? insight.sparklineSessions[i]
          : 0;

      double? pctChange;
      if (i > 0) {
        final prevVolume = result[i - 1].totalVolume;
        if (prevVolume > 0) {
          pctChange =
              ((volume - prevVolume) / prevVolume * 100).roundToDouble();
        }
      }

      result.add(MonthlyVolume(
        month: label,
        totalVolume: volume,
        sessionCount: sessions,
        percentChangeVsPrevMonth: pctChange,
      ));
    }

    return result;
  }
}
