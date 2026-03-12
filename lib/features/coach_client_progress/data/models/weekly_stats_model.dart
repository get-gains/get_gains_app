import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_stats_model.freezed.dart';
part 'weekly_stats_model.g.dart';

/// Weekly aggregated workout statistics for a client.
@freezed
abstract class ClientWeeklyStats with _$ClientWeeklyStats {
  const factory ClientWeeklyStats({
    required DateTime weekStart,
    required DateTime weekEnd,
    @Default(0) int sessionsCompleted,
    @Default(0) int totalSets,
    @Default(0) int totalReps,
    @Default(0.0) double totalVolume,
    @Default(0) int totalMinutes,
    @Default(0) int averageSessionDuration,
    WeeklyStatsDelta? delta,
  }) = _ClientWeeklyStats;

  factory ClientWeeklyStats.fromJson(Map<String, dynamic> json) =>
      _$ClientWeeklyStatsFromJson(json);
}

/// Delta values comparing the current week to the previous week.
/// Positive values indicate improvement.
@freezed
abstract class WeeklyStatsDelta with _$WeeklyStatsDelta {
  const factory WeeklyStatsDelta({
    @Default(0) int sessionsCompleted,
    @Default(0) int totalSets,
    @Default(0) int totalReps,
    @Default(0.0) double totalVolume,
    @Default(0) int totalMinutes,
  }) = _WeeklyStatsDelta;

  factory WeeklyStatsDelta.fromJson(Map<String, dynamic> json) =>
      _$WeeklyStatsDeltaFromJson(json);
}
