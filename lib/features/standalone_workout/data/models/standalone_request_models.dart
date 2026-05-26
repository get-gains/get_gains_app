import 'package:freezed_annotation/freezed_annotation.dart';

part 'standalone_request_models.freezed.dart';
part 'standalone_request_models.g.dart';

// ──────────── Program CRUD ────────────

@freezed
abstract class CreateStandaloneProgramRequest
    with _$CreateStandaloneProgramRequest {
  const factory CreateStandaloneProgramRequest({
    required String name,
    required String description,
  }) = _CreateStandaloneProgramRequest;

  factory CreateStandaloneProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateStandaloneProgramRequestFromJson(json);
}

@freezed
abstract class UpdateStandaloneProgramRequest
    with _$UpdateStandaloneProgramRequest {
  const factory UpdateStandaloneProgramRequest({
    String? name,
    String? description,
  }) = _UpdateStandaloneProgramRequest;

  factory UpdateStandaloneProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStandaloneProgramRequestFromJson(json);
}

// ──────────── Program Builder (bulk) ────────────

@freezed
abstract class BuilderRoutineExerciseRequest
    with _$BuilderRoutineExerciseRequest {
  const factory BuilderRoutineExerciseRequest({
    required String exerciseId,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
  }) = _BuilderRoutineExerciseRequest;

  factory BuilderRoutineExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$BuilderRoutineExerciseRequestFromJson(json);
}

@freezed
abstract class BuilderRoutineRequest with _$BuilderRoutineRequest {
  const factory BuilderRoutineRequest({
    required String routineId,
    required int orderInProgram,
    @Default([]) List<BuilderRoutineExerciseRequest> exercises,
  }) = _BuilderRoutineRequest;

  factory BuilderRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$BuilderRoutineRequestFromJson(json);
}

@freezed
abstract class BuildStandaloneProgramRequest
    with _$BuildStandaloneProgramRequest {
  const factory BuildStandaloneProgramRequest({
    required String name,
    required String description,
    required List<BuilderRoutineRequest> routines,
  }) = _BuildStandaloneProgramRequest;

  factory BuildStandaloneProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$BuildStandaloneProgramRequestFromJson(json);
}

// ──────────── Program Routine ────────────

@freezed
abstract class AddProgramRoutineRequest with _$AddProgramRoutineRequest {
  const factory AddProgramRoutineRequest({
    required String routineId,
    required int orderInProgram,
  }) = _AddProgramRoutineRequest;

  factory AddProgramRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$AddProgramRoutineRequestFromJson(json);
}

@freezed
abstract class UpdateProgramRoutineRequest with _$UpdateProgramRoutineRequest {
  const factory UpdateProgramRoutineRequest({
    required int orderInProgram,
  }) = _UpdateProgramRoutineRequest;

  factory UpdateProgramRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProgramRoutineRequestFromJson(json);
}

// ──────────── Routine Exercise ────────────

@freezed
abstract class AddRoutineExerciseRequest with _$AddRoutineExerciseRequest {
  const factory AddRoutineExerciseRequest({
    required String exerciseId,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
  }) = _AddRoutineExerciseRequest;

  factory AddRoutineExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$AddRoutineExerciseRequestFromJson(json);
}

@freezed
abstract class UpdateRoutineExerciseRequest
    with _$UpdateRoutineExerciseRequest {
  const factory UpdateRoutineExerciseRequest({
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    int? orderInRoutine,
  }) = _UpdateRoutineExerciseRequest;

  factory UpdateRoutineExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoutineExerciseRequestFromJson(json);
}

// ──────────── Session ────────────

@freezed
abstract class StartStandaloneSessionRequest
    with _$StartStandaloneSessionRequest {
  const factory StartStandaloneSessionRequest({
    required String programRoutineId,
  }) = _StartStandaloneSessionRequest;

  factory StartStandaloneSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$StartStandaloneSessionRequestFromJson(json);
}

@freezed
abstract class CompleteStandaloneSessionRequest
    with _$CompleteStandaloneSessionRequest {
  const factory CompleteStandaloneSessionRequest({
    String? feedback,
  }) = _CompleteStandaloneSessionRequest;

  factory CompleteStandaloneSessionRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$CompleteStandaloneSessionRequestFromJson(json);
}

// ──────────── Performed Set ────────────

@freezed
abstract class LogStandaloneSetRequest with _$LogStandaloneSetRequest {
  const factory LogStandaloneSetRequest({
    required String routineExerciseId,
    required int setNumber,
    required int reps,
    required double weight,
  }) = _LogStandaloneSetRequest;

  factory LogStandaloneSetRequest.fromJson(Map<String, dynamic> json) =>
      _$LogStandaloneSetRequestFromJson(json);
}

@freezed
abstract class UpdateStandaloneSetRequest with _$UpdateStandaloneSetRequest {
  const factory UpdateStandaloneSetRequest({
    int? reps,
    double? weight,
  }) = _UpdateStandaloneSetRequest;

  factory UpdateStandaloneSetRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStandaloneSetRequestFromJson(json);
}
