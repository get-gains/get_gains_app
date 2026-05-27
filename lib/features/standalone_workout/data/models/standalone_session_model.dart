import 'package:freezed_annotation/freezed_annotation.dart';

part 'standalone_session_model.freezed.dart';
part 'standalone_session_model.g.dart';

Map<String, dynamic> _normalizeSessionExerciseJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  if (normalized['exercise'] is Map<String, dynamic>) {
    final exercise = normalized['exercise'] as Map<String, dynamic>;
    normalized['exercise_name'] ??= exercise['name'];
  }

  return normalized;
}

Map<String, dynamic> _normalizeSessionJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  if (normalized['program_routine'] is Map<String, dynamic>) {
    final pr = normalized['program_routine'] as Map<String, dynamic>;

    if (pr['routine'] is Map<String, dynamic>) {
      final routine = pr['routine'] as Map<String, dynamic>;
      normalized['routineName'] ??= routine['name'];
    }

    if (pr['exercises'] is List) {
      normalized['exercises'] = (pr['exercises'] as List)
          .map((e) => _normalizeSessionExerciseJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  if (normalized['performed_sets'] is List) {
    normalized['performed_sets'] =
        (normalized['performed_sets'] as List).map((e) {
      return e is Map<String, dynamic> ? e : e;
    }).toList();
  }

  return normalized;
}

@freezed
abstract class StandaloneSession with _$StandaloneSession {
  const factory StandaloneSession({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'program_routine_id') required String programRoutineId,
    @JsonKey(name: 'started_at') required DateTime startedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    String? feedback,
    String? routineName,
    @JsonKey(name: 'performed_sets') @Default([])
    List<StandalonePerformedSet> performedSets,
    @Default([]) List<StandaloneSessionExercise> exercises,
    @JsonKey(name: 'set_count') @Default(0) int setCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _StandaloneSession;

  factory StandaloneSession.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionFromJson(_normalizeSessionJson(json));
}

@freezed
abstract class StandalonePerformedSet with _$StandalonePerformedSet {
  const factory StandalonePerformedSet({
    required String id,
    @JsonKey(name: 'routine_exercise_id') required String routineExerciseId,
    @JsonKey(name: 'set_number') required int setNumber,
    required int reps,
    required double weight,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _StandalonePerformedSet;

  factory StandalonePerformedSet.fromJson(Map<String, dynamic> json) =>
      _$StandalonePerformedSetFromJson(json);
}

@freezed
abstract class StandaloneSessionExercise with _$StandaloneSessionExercise {
  const factory StandaloneSessionExercise({
    required String id,
    @JsonKey(name: 'exercise_id') required String exerciseId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    required int sets,
    @JsonKey(name: 'reps_min') required int repsMin,
    @JsonKey(name: 'reps_max') required int repsMax,
    @JsonKey(name: 'rest_seconds') required int restSeconds,
    @JsonKey(name: 'order_in_routine') required int orderInRoutine,
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
