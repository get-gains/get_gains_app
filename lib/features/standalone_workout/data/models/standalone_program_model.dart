import 'package:freezed_annotation/freezed_annotation.dart';

part 'standalone_program_model.freezed.dart';
part 'standalone_program_model.g.dart';

Map<String, dynamic> _normalizeStandaloneProgramRoutineJson(
  Map<String, dynamic> json,
) {
  final normalized = Map<String, dynamic>.from(json);

  if (normalized['routine'] is Map<String, dynamic>) {
    final routine = normalized['routine'] as Map<String, dynamic>;
    normalized['routineName'] ??= routine['name'];
    normalized['routineDescription'] ??= routine['description'] ?? '';
  }

  if (normalized['exercises'] is List) {
    normalized['exercises'] = (normalized['exercises'] as List)
        .map(
          (e) =>
              _normalizeStandaloneRoutineExerciseJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  return normalized;
}

Map<String, dynamic> _normalizeStandaloneRoutineExerciseJson(
  Map<String, dynamic> json,
) {
  final normalized = Map<String, dynamic>.from(json);

  if (normalized['exercise'] is Map<String, dynamic>) {
    final exercise = normalized['exercise'] as Map<String, dynamic>;
    normalized['exerciseName'] ??= exercise['name'];
  }

  return normalized;
}

Map<String, dynamic> _normalizeStandaloneProgramDetailJson(
  Map<String, dynamic> json,
) {
  final normalized = Map<String, dynamic>.from(json);

  if (normalized['routines'] is List) {
    normalized['routines'] = (normalized['routines'] as List)
        .map(
          (e) =>
              _normalizeStandaloneProgramRoutineJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  return normalized;
}

@freezed
abstract class StandaloneProgram with _$StandaloneProgram {
  const factory StandaloneProgram({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'routine_count') @Default(0) int routineCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _StandaloneProgram;

  factory StandaloneProgram.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramFromJson(json);
}

@freezed
abstract class StandaloneProgramDetail with _$StandaloneProgramDetail {
  const factory StandaloneProgramDetail({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @Default([]) List<StandaloneProgramRoutine> routines,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _StandaloneProgramDetail;

  factory StandaloneProgramDetail.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramDetailFromJson(
        _normalizeStandaloneProgramDetailJson(json),
      );
}

@freezed
abstract class StandaloneProgramRoutine with _$StandaloneProgramRoutine {
  const factory StandaloneProgramRoutine({
    required String id,
    @JsonKey(name: 'routine_id') required String routineId,
    required String routineName,
    @Default('') String routineDescription,
    @JsonKey(name: 'order_in_program') required int orderInProgram,
    @Default([]) List<StandaloneRoutineExercise> exercises,
  }) = _StandaloneProgramRoutine;

  factory StandaloneProgramRoutine.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramRoutineFromJson(
        _normalizeStandaloneProgramRoutineJson(json),
      );
}

@freezed
abstract class StandaloneRoutineExercise with _$StandaloneRoutineExercise {
  const factory StandaloneRoutineExercise({
    required String id,
    @JsonKey(name: 'exercise_id') required String exerciseId,
    required String exerciseName,
    required int sets,
    @JsonKey(name: 'reps_min') required int repsMin,
    @JsonKey(name: 'reps_max') required int repsMax,
    @JsonKey(name: 'rest_seconds') required int restSeconds,
    @JsonKey(name: 'order_in_routine') required int orderInRoutine,
    double? lastWeight,
    int? lastReps,
  }) = _StandaloneRoutineExercise;

  factory StandaloneRoutineExercise.fromJson(Map<String, dynamic> json) =>
      _$StandaloneRoutineExerciseFromJson(
        _normalizeStandaloneRoutineExerciseJson(json),
      );
}

@freezed
abstract class StandaloneProgramListResponse
    with _$StandaloneProgramListResponse {
  const factory StandaloneProgramListResponse({
    required List<StandaloneProgram> programs,
    required int total,
    required int limit,
    required int offset,
    @Default(false) bool hasMore,
  }) = _StandaloneProgramListResponse;

  factory StandaloneProgramListResponse.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramListResponseFromJson(json);
}
