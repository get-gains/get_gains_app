import 'package:freezed_annotation/freezed_annotation.dart';

part 'standalone_session_model.freezed.dart';
part 'standalone_session_model.g.dart';

@freezed
abstract class StandaloneSession with _$StandaloneSession {
  const factory StandaloneSession({
    required String id,
    required String userId,
    required String programRoutineId,
    required DateTime startedAt,
    DateTime? completedAt,
    String? feedback,
    String? routineName,
    @Default([]) List<StandalonePerformedSet> performedSets,
    @Default([]) List<StandaloneSessionExercise> exercises,
    @Default(0) int setCount,
    DateTime? createdAt,
  }) = _StandaloneSession;

  factory StandaloneSession.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionFromJson(json);
}

@freezed
abstract class StandalonePerformedSet with _$StandalonePerformedSet {
  const factory StandalonePerformedSet({
    required String id,
    required String routineExerciseId,
    required int setNumber,
    required int reps,
    required double weight,
    DateTime? createdAt,
  }) = _StandalonePerformedSet;

  factory StandalonePerformedSet.fromJson(Map<String, dynamic> json) =>
      _$StandalonePerformedSetFromJson(json);
}

@freezed
abstract class StandaloneSessionExercise with _$StandaloneSessionExercise {
  const factory StandaloneSessionExercise({
    required String id,
    required String exerciseId,
    required String exerciseName,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
  }) = _StandaloneSessionExercise;

  factory StandaloneSessionExercise.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionExerciseFromJson(json);
}

@freezed
abstract class StandaloneSessionSummary with _$StandaloneSessionSummary {
  const factory StandaloneSessionSummary({
    required String id,
    required String routineName,
    required DateTime startedAt,
    DateTime? completedAt,
    String? feedback,
    @Default(0) int setCount,
  }) = _StandaloneSessionSummary;

  factory StandaloneSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionSummaryFromJson(json);
}

extension StandaloneSessionSummaryX on StandaloneSessionSummary {
  Duration? get duration =>
      completedAt != null ? completedAt!.difference(startedAt) : null;

  String get durationDisplay {
    final d = duration;
    if (d == null) return '—';
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

@freezed
abstract class StandaloneSessionListResponse
    with _$StandaloneSessionListResponse {
  const factory StandaloneSessionListResponse({
    required List<StandaloneSessionSummary> sessions,
    required int total,
    required int limit,
    required int offset,
    @Default(false) bool hasMore,
  }) = _StandaloneSessionListResponse;

  factory StandaloneSessionListResponse.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionListResponseFromJson(json);
}
