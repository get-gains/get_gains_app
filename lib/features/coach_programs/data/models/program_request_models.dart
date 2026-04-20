import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'program_model.dart';

part 'program_request_models.freezed.dart';
part 'program_request_models.g.dart';

// ──────────────────────────────────────────────────────────
// Client Program Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/clients/:clientId/programs`.
@freezed
abstract class CreateClientProgramRequest with _$CreateClientProgramRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateClientProgramRequest({
    required String name,
    @Default('') String description,
    String? notes,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
  }) = _CreateClientProgramRequest;

  factory CreateClientProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateClientProgramRequestFromJson(json);
}

/// Body for `PATCH /api/coach/programs/:programId`.
@freezed
abstract class UpdateClientProgramRequest with _$UpdateClientProgramRequest {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateClientProgramRequest({
    String? name,
    String? description,
    String? notes,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
  }) = _UpdateClientProgramRequest;

  factory UpdateClientProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateClientProgramRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Program Routine Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/programs/:programId/routines` (template mode).
///
/// Copies an existing routine template into the client's program.
@freezed
abstract class AddProgramRoutineTemplateRequest
    with _$AddProgramRoutineTemplateRequest {
  const factory AddProgramRoutineTemplateRequest({
    @Default('template') String mode,
    @JsonKey(name: 'source_routine_id') required String sourceRoutineId,
    @JsonKey(name: 'days_of_week') required List<DayOfWeek> daysOfWeek,
    @JsonKey(name: 'order_in_program') required int orderInProgram,
  }) = _AddProgramRoutineTemplateRequest;

  factory AddProgramRoutineTemplateRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$AddProgramRoutineTemplateRequestFromJson(json);
}

/// Body for `POST /api/coach/programs/:programId/routines` (inline mode).
///
/// Creates a new routine directly within the client's program.
@freezed
abstract class AddProgramRoutineInlineRequest
    with _$AddProgramRoutineInlineRequest {
  const factory AddProgramRoutineInlineRequest({
    @Default('inline') String mode,
    required String name,
    @Default('') String description,
    @JsonKey(name: 'estimated_duration_minutes')
    required int estimatedDurationMinutes,
    @JsonKey(name: 'days_of_week') required List<DayOfWeek> daysOfWeek,
    @JsonKey(name: 'order_in_program') required int orderInProgram,
    @Default([]) List<InlineExerciseRequest> exercises,
  }) = _AddProgramRoutineInlineRequest;

  factory AddProgramRoutineInlineRequest.fromJson(Map<String, dynamic> json) =>
      _$AddProgramRoutineInlineRequestFromJson(json);
}

/// Exercise entry within an inline routine creation request.
@freezed
abstract class InlineExerciseRequest with _$InlineExerciseRequest {
  const factory InlineExerciseRequest({
    @JsonKey(name: 'exercise_id') required String exerciseId,
    required int sets,
    @JsonKey(name: 'reps_min') required int repsMin,
    @JsonKey(name: 'reps_max') required int repsMax,
    @JsonKey(name: 'rest_seconds') required int restSeconds,
    @JsonKey(name: 'order_in_routine') required int orderInRoutine,
  }) = _InlineExerciseRequest;

  factory InlineExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$InlineExerciseRequestFromJson(json);
}

/// Body for `PATCH /api/coach/programs/:programId/routines/:aprId`.
@freezed
abstract class UpdateProgramRoutineRequest with _$UpdateProgramRoutineRequest {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateProgramRoutineRequest({
    String? name,
    String? description,
    @JsonKey(name: 'estimated_duration_minutes') int? estimatedDurationMinutes,
    @JsonKey(name: 'days_of_week') List<DayOfWeek>? daysOfWeek,
    @JsonKey(name: 'order_in_program') int? orderInProgram,
  }) = _UpdateProgramRoutineRequest;

  factory UpdateProgramRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProgramRoutineRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Program Routine Exercise Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/programs/:programId/routines/:aprId/exercises`.
@freezed
abstract class AddProgramRoutineExerciseRequest
    with _$AddProgramRoutineExerciseRequest {
  const factory AddProgramRoutineExerciseRequest({
    @JsonKey(name: 'exercise_id') required String exerciseId,
    required int sets,
    @JsonKey(name: 'reps_min') required int repsMin,
    @JsonKey(name: 'reps_max') required int repsMax,
    @JsonKey(name: 'rest_seconds') required int restSeconds,
    @JsonKey(name: 'order_in_routine') required int orderInRoutine,
  }) = _AddProgramRoutineExerciseRequest;

  factory AddProgramRoutineExerciseRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$AddProgramRoutineExerciseRequestFromJson(json);
}

/// Body for `PATCH .../exercises/:apreId`.
@freezed
abstract class UpdateProgramRoutineExerciseRequest
    with _$UpdateProgramRoutineExerciseRequest {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateProgramRoutineExerciseRequest({
    @JsonKey(name: 'exercise_id') String? exerciseId,
    int? sets,
    @JsonKey(name: 'reps_min') int? repsMin,
    @JsonKey(name: 'reps_max') int? repsMax,
    @JsonKey(name: 'rest_seconds') int? restSeconds,
    @JsonKey(name: 'order_in_routine') int? orderInRoutine,
  }) = _UpdateProgramRoutineExerciseRequest;

  factory UpdateProgramRoutineExerciseRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateProgramRoutineExerciseRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Routine Template Requests (kept from old schema)
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/routine-templates`.
@freezed
abstract class CreateRoutineRequest with _$CreateRoutineRequest {
  const factory CreateRoutineRequest({
    required String name,
    required String description,
    @JsonKey(name: 'estimated_duration_minutes')
    required int estimatedDurationMinutes,
  }) = _CreateRoutineRequest;

  factory CreateRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRoutineRequestFromJson(json);
}

/// Body for `PATCH /api/coach/routine-templates/:routineId`.
@freezed
abstract class UpdateRoutineRequest with _$UpdateRoutineRequest {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateRoutineRequest({
    String? name,
    String? description,
    @JsonKey(name: 'estimated_duration_minutes') int? estimatedDurationMinutes,
  }) = _UpdateRoutineRequest;

  factory UpdateRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoutineRequestFromJson(json);
}
