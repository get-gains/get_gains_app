import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_history_model.freezed.dart';
part 'exercise_history_model.g.dart';

/// Response wrapper for the client exercise history endpoint.
@freezed
abstract class ClientExerciseHistoryResponse
    with _$ClientExerciseHistoryResponse {
  const factory ClientExerciseHistoryResponse({
    required ExerciseInfo exercise,
    @Default([]) List<ExerciseHistoryEntry> history,
    @Default(0) int total,
  }) = _ClientExerciseHistoryResponse;

  factory ClientExerciseHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$ClientExerciseHistoryResponseFromJson(json);
}

/// Basic exercise metadata.
@freezed
abstract class ExerciseInfo with _$ExerciseInfo {
  const factory ExerciseInfo({
    required String id,
    required String name,
    String? primaryMuscleGroup,
  }) = _ExerciseInfo;

  factory ExerciseInfo.fromJson(Map<String, dynamic> json) =>
      _$ExerciseInfoFromJson(json);
}

/// A single session's worth of sets for a given exercise (history entry).
@freezed
abstract class ExerciseHistoryEntry with _$ExerciseHistoryEntry {
  const factory ExerciseHistoryEntry({
    required String sessionId,
    required DateTime date,
    @Default([]) List<ExerciseHistorySet> sets,
    required ExerciseHistorySummary summary,
  }) = _ExerciseHistoryEntry;

  factory ExerciseHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistoryEntryFromJson(json);
}

/// A set within an exercise history entry.
///
/// JSON keys are snake_case to match the server's Prisma-sourced response.
@freezed
abstract class ExerciseHistorySet with _$ExerciseHistorySet {
  const factory ExerciseHistorySet({
    @JsonKey(name: 'set_number') required int setNumber,
    @JsonKey(name: 'reps') @Default(0) int repsCompleted,
    @JsonKey(name: 'weight') double? weightKg,
    @JsonKey(name: 'overall_score') int? overallScore,
  }) = _ExerciseHistorySet;

  factory ExerciseHistorySet.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistorySetFromJson(json);
}

/// Summary statistics for a single exercise history entry (one session).
@freezed
abstract class ExerciseHistorySummary with _$ExerciseHistorySummary {
  const factory ExerciseHistorySummary({
    @Default(0) int totalSets,
    @Default(0) int totalReps,
    @Default(0.0) double maxWeight,
    @Default(0.0) double totalVolume,
    ExerciseHistorySet? bestSet,
  }) = _ExerciseHistorySummary;

  factory ExerciseHistorySummary.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistorySummaryFromJson(json);
}
