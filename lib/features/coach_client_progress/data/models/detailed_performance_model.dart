import 'package:freezed_annotation/freezed_annotation.dart';

part 'detailed_performance_model.freezed.dart';
part 'detailed_performance_model.g.dart';

/// A single client row in the detailed performance report.
@freezed
abstract class ClientPerformanceEntry with _$ClientPerformanceEntry {
  const factory ClientPerformanceEntry({
    required String id,
    required String email,
    required String name,
    String? nickname,
    @Default('good') String status,
    DateTime? lastCompletedAt,
    @Default(0) int sessionsThisWeek,
    @Default(0) int totalSets,
    @Default(0) int totalReps,
    @Default(0.0) double totalVolume,
    @Default(0) int averageSessionDuration,
    int? adherenceRate,
    String? activeProgramName,
  }) = _ClientPerformanceEntry;

  factory ClientPerformanceEntry.fromJson(Map<String, dynamic> json) =>
      _$ClientPerformanceEntryFromJson(json);
}

/// Summary stats across all clients in the detailed performance report.
@freezed
abstract class PerformanceSummary with _$PerformanceSummary {
  const factory PerformanceSummary({
    @Default(0) int total,
    @Default(0) int good,
    @Default(0) int fallingBehind,
    @Default(0) int averageAdherence,
  }) = _PerformanceSummary;

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) =>
      _$PerformanceSummaryFromJson(json);
}
