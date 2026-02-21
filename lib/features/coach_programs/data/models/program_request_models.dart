import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/exercise_model.dart';

part 'program_request_models.freezed.dart';
part 'program_request_models.g.dart';

// ──────────────────────────────────────────────────────────
// Program Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/programs`.
@freezed
abstract class CreateProgramRequest with _$CreateProgramRequest {
  const factory CreateProgramRequest({
    required String name,
    required String description,
  }) = _CreateProgramRequest;

  factory CreateProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateProgramRequestFromJson(json);
}

/// Body for `PATCH /api/coach/programs/:programId`.
@freezed
abstract class UpdateProgramRequest with _$UpdateProgramRequest {
  const factory UpdateProgramRequest({String? name, String? description}) =
      _UpdateProgramRequest;

  factory UpdateProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProgramRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Routine Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/routines`.
@freezed
abstract class CreateRoutineRequest with _$CreateRoutineRequest {
  const factory CreateRoutineRequest({
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,
  }) = _CreateRoutineRequest;

  factory CreateRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRoutineRequestFromJson(json);
}

/// Body for `PATCH /api/coach/routines/:routineId`.
@freezed
abstract class UpdateRoutineRequest with _$UpdateRoutineRequest {
  const factory UpdateRoutineRequest({
    String? name,
    String? description,
    int? estimatedDurationMinutes,
    List<MuscleGroup>? muscleGroupsTargeted,
  }) = _UpdateRoutineRequest;

  factory UpdateRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoutineRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// ProgramRoutine Junction Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/programs/:programId/routines`.
@freezed
abstract class AssignRoutineRequest with _$AssignRoutineRequest {
  const factory AssignRoutineRequest({
    required String routineId,
    required int dayNumber,
  }) = _AssignRoutineRequest;

  factory AssignRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignRoutineRequestFromJson(json);
}

/// Body for `PATCH /api/coach/programs/:programId/routines/:programRoutineId`.
@freezed
abstract class UpdateProgramRoutineRequest with _$UpdateProgramRoutineRequest {
  const factory UpdateProgramRoutineRequest({required int dayNumber}) =
      _UpdateProgramRoutineRequest;

  factory UpdateProgramRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProgramRoutineRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// RoutineExercise Junction Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/programs/routines/:routineId/exercises`.
@freezed
abstract class AddRoutineExerciseRequest with _$AddRoutineExerciseRequest {
  const factory AddRoutineExerciseRequest({
    required String exerciseId,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
    String? notes,
  }) = _AddRoutineExerciseRequest;

  factory AddRoutineExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$AddRoutineExerciseRequestFromJson(json);
}

/// Body for `PATCH /api/coach/programs/routines/:routineId/exercises/:routineExerciseId`.
@freezed
abstract class UpdateRoutineExerciseRequest
    with _$UpdateRoutineExerciseRequest {
  const factory UpdateRoutineExerciseRequest({
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    int? orderInRoutine,
    String? notes,
  }) = _UpdateRoutineExerciseRequest;

  factory UpdateRoutineExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoutineExerciseRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Assignment Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/coach/assign-program`.
@freezed
abstract class AssignProgramRequest with _$AssignProgramRequest {
  const factory AssignProgramRequest({
    required String userId,
    required String programId,
    required String startDate,
    String? endDate,
    String? notes,
  }) = _AssignProgramRequest;

  factory AssignProgramRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignProgramRequestFromJson(json);
}

/// Body for `PATCH /api/coach/assign-program/:assignmentId`.
@freezed
abstract class UpdateAssignmentRequest with _$UpdateAssignmentRequest {
  const factory UpdateAssignmentRequest({
    String? startDate,
    String? endDate,
    String? notes,
    bool? isActive,
  }) = _UpdateAssignmentRequest;

  factory UpdateAssignmentRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAssignmentRequestFromJson(json);
}
