import 'package:freezed_annotation/freezed_annotation.dart';

part 'standalone_stats_model.freezed.dart';
part 'standalone_stats_model.g.dart';

@freezed
abstract class StandaloneStats with _$StandaloneStats {
  const factory StandaloneStats({
    required int workoutsThisWeek,
    required int streakDays,
    required int totalDurationMinutes,
    required int totalWorkouts,
    required int totalSets,
    DateTime? weekStart,
  }) = _StandaloneStats;

  factory StandaloneStats.fromJson(Map<String, dynamic> json) =>
      _$StandaloneStatsFromJson(json);
}

@freezed
abstract class StandaloneExerciseStat with _$StandaloneExerciseStat {
  const factory StandaloneExerciseStat({
    required String exerciseId,
    StandaloneExerciseLastSet? lastSet,
  }) = _StandaloneExerciseStat;

  factory StandaloneExerciseStat.fromJson(Map<String, dynamic> json) =>
      _$StandaloneExerciseStatFromJson(json);
}

@freezed
abstract class StandaloneExerciseLastSet with _$StandaloneExerciseLastSet {
  const factory StandaloneExerciseLastSet({
    required int reps,
    required double weight,
    required int setNumber,
    DateTime? createdAt,
  }) = _StandaloneExerciseLastSet;

  factory StandaloneExerciseLastSet.fromJson(Map<String, dynamic> json) =>
      _$StandaloneExerciseLastSetFromJson(json);
}
