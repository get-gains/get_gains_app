import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_stats_model.freezed.dart';
part 'weekly_stats_model.g.dart';

/// Weekly Stats Model
///
/// Server-aggregated weekly workout statistics returned by
/// `GET /api/workout/stats/weekly`.
@freezed
abstract class WeeklyStatsModel with _$WeeklyStatsModel {
  const factory WeeklyStatsModel({
    /// Start of the stats week (Monday).
    required DateTime weekStart,

    /// End of the stats week (Sunday).
    required DateTime weekEnd,

    /// Number of completed workout sessions this week.
    @Default(0) int workoutsCompleted,

    /// Total workout time in minutes this week.
    @Default(0) int totalMinutes,

    /// Current consecutive-day workout streak.
    @Default(0) int streakDays,
  }) = _WeeklyStatsModel;

  factory WeeklyStatsModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyStatsModelFromJson(json);
}

/// Extension helpers for [WeeklyStatsModel].
extension WeeklyStatsModelX on WeeklyStatsModel {
  /// Formatted total workout time (e.g., "1h 30m").
  String get totalTimeDisplay {
    if (totalMinutes == 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Whether the user has done any workouts this week.
  bool get hasActivity => workoutsCompleted > 0;
}
