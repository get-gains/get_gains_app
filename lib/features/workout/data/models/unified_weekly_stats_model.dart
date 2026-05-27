import 'package:freezed_annotation/freezed_annotation.dart';

part 'unified_weekly_stats_model.freezed.dart';
part 'unified_weekly_stats_model.g.dart';

/// Unified Weekly Stats Model
///
/// Server-aggregated weekly workout statistics returned by
/// `GET /api/stats/weekly`. Contains combined totals and
/// per-source breakdowns (standalone vs. coach).
@freezed
abstract class UnifiedWeeklyStats with _$UnifiedWeeklyStats {
  const factory UnifiedWeeklyStats({
    /// Start of the stats week (Monday), ISO date string.
    required String weekStart,

    /// End of the stats week (Sunday), ISO date string.
    required String weekEnd,

    /// Combined total completed workout sessions this week.
    @Default(0) int workoutsCompleted,

    /// Combined total workout time in minutes this week.
    @Default(0) int totalMinutes,

    /// Combined consecutive-day workout streak (90-day lookback).
    @Default(0) int streakDays,

    /// Per-source breakdown. Free users get standalone only;
    /// subscribed users get both standalone and coach entries.
    @Default([]) List<SourceStats> sources,

    /// UTC ISO-8601 timestamps of each completed session's started_at this
    /// week. Used by the UI to derive which local calendar days had workouts.
    @Default([]) List<String> sessionDates,
  }) = _UnifiedWeeklyStats;

  factory UnifiedWeeklyStats.fromJson(Map<String, dynamic> json) =>
      _$UnifiedWeeklyStatsFromJson(json);
}

/// Per-source stats breakdown entry.
///
/// Each entry represents stats for either "standalone" or "coach" workouts.
@freezed
abstract class SourceStats with _$SourceStats {
  const factory SourceStats({
    /// Source type: "standalone" or "coach".
    required String type,

    /// Number of completed sessions from this source this week.
    @Default(0) int workoutsCompleted,

    /// Total workout time from this source in minutes.
    @Default(0) int totalMinutes,

    /// Consecutive-day streak for this specific source.
    @Default(0) int streakDays,

    /// Program name (only present for coach source).
    String? programName,
  }) = _SourceStats;

  factory SourceStats.fromJson(Map<String, dynamic> json) =>
      _$SourceStatsFromJson(json);
}

/// Extension helpers for [UnifiedWeeklyStats].
extension UnifiedWeeklyStatsX on UnifiedWeeklyStats {
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

  /// Set of local weekday indices (1=Mon … 7=Sun, matching [DateTime.weekday])
  /// derived from [sessionDates] by converting each UTC timestamp to local time.
  Set<int> get completedWeekdays =>
      sessionDates.map((iso) => DateTime.parse(iso).toLocal().weekday).toSet();

  /// Get standalone source stats, if present.
  SourceStats? get standaloneStats =>
      sources.where((s) => s.type == 'standalone').firstOrNull;

  /// Get coach source stats, if present.
  SourceStats? get coachStats =>
      sources.where((s) => s.type == 'coach').firstOrNull;

  /// Whether this response includes coach stats.
  bool get hasCoachStats => coachStats != null;

  /// Whether this response includes standalone stats.
  bool get hasStandaloneStats => standaloneStats != null;
}

/// Extension helpers for [SourceStats].
extension SourceStatsX on SourceStats {
  /// Display-friendly source label.
  String get sourceLabel => type == 'coach' ? 'Coach' : 'Solo';

  /// Formatted total time for this source.
  String get totalTimeDisplay {
    if (totalMinutes == 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}
