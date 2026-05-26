import 'package:freezed_annotation/freezed_annotation.dart';

part 'standalone_program_model.freezed.dart';
part 'standalone_program_model.g.dart';

@freezed
abstract class StandaloneProgram with _$StandaloneProgram {
  const factory StandaloneProgram({
    required String id,
    required String name,
    required String description,
    @Default(false) bool isActive,
    @Default(0) int routineCount,
    DateTime? createdAt,
    DateTime? updatedAt,
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
    @Default(false) bool isActive,
    @Default([]) List<StandaloneProgramRoutine> routines,
    DateTime? createdAt,
  }) = _StandaloneProgramDetail;

  factory StandaloneProgramDetail.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramDetailFromJson(json);
}

@freezed
abstract class StandaloneProgramRoutine with _$StandaloneProgramRoutine {
  const factory StandaloneProgramRoutine({
    required String id,
    required String routineId,
    required String routineName,
    @Default('') String routineDescription,
    required int orderInProgram,
    @Default([]) List<StandaloneRoutineExercise> exercises,
  }) = _StandaloneProgramRoutine;

  factory StandaloneProgramRoutine.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramRoutineFromJson(json);
}

@freezed
abstract class StandaloneRoutineExercise with _$StandaloneRoutineExercise {
  const factory StandaloneRoutineExercise({
    required String id,
    required String exerciseId,
    required String exerciseName,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
    double? lastWeight,
    int? lastReps,
  }) = _StandaloneRoutineExercise;

  factory StandaloneRoutineExercise.fromJson(Map<String, dynamic> json) =>
      _$StandaloneRoutineExerciseFromJson(json);
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
