import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/exercise_model.dart';

part 'standalone_request_models.freezed.dart';
part 'standalone_request_models.g.dart';

// ──────────────────────────────────────────────────────────
// Exercise Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/standalone/exercises`.
@freezed
abstract class CreateStandaloneExerciseRequest
    with _$CreateStandaloneExerciseRequest {
  const factory CreateStandaloneExerciseRequest({
    required String name,
    required String description,
    required MuscleGroup primaryMuscleGroup,
    @Default([]) List<String> equipmentNeeded,
    @Default(false) bool isPublic,
  }) = _CreateStandaloneExerciseRequest;

  factory CreateStandaloneExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateStandaloneExerciseRequestFromJson(json);
}

/// Body for `PATCH /api/standalone/exercises/:exerciseId`.
@freezed
abstract class UpdateStandaloneExerciseRequest
    with _$UpdateStandaloneExerciseRequest {
  const factory UpdateStandaloneExerciseRequest({
    String? name,
    String? description,
    MuscleGroup? primaryMuscleGroup,
    List<String>? equipmentNeeded,
    bool? isPublic,
  }) = _UpdateStandaloneExerciseRequest;

  factory UpdateStandaloneExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStandaloneExerciseRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Routine Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/standalone/routines`.
@freezed
abstract class CreateStandaloneRoutineRequest
    with _$CreateStandaloneRoutineRequest {
  const factory CreateStandaloneRoutineRequest({
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,
  }) = _CreateStandaloneRoutineRequest;

  factory CreateStandaloneRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateStandaloneRoutineRequestFromJson(json);
}

/// Body for `PATCH /api/standalone/routines/:routineId`.
@freezed
abstract class UpdateStandaloneRoutineRequest
    with _$UpdateStandaloneRoutineRequest {
  const factory UpdateStandaloneRoutineRequest({
    String? name,
    String? description,
    int? estimatedDurationMinutes,
    List<MuscleGroup>? muscleGroupsTargeted,
  }) = _UpdateStandaloneRoutineRequest;

  factory UpdateStandaloneRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStandaloneRoutineRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Routine Exercise Junction Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/standalone/routines/:routineId/exercises`.
@freezed
abstract class AddStandaloneRoutineExerciseRequest
    with _$AddStandaloneRoutineExerciseRequest {
  const factory AddStandaloneRoutineExerciseRequest({
    required String exerciseId,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int restSeconds,
    required int orderInRoutine,
    String? notes,
  }) = _AddStandaloneRoutineExerciseRequest;

  factory AddStandaloneRoutineExerciseRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$AddStandaloneRoutineExerciseRequestFromJson(json);
}

/// Body for `PATCH /api/standalone/routines/:routineId/exercises/:routineExerciseId`.
@freezed
abstract class UpdateStandaloneRoutineExerciseRequest
    with _$UpdateStandaloneRoutineExerciseRequest {
  const factory UpdateStandaloneRoutineExerciseRequest({
    int? sets,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
    int? orderInRoutine,
    String? notes,
  }) = _UpdateStandaloneRoutineExerciseRequest;

  factory UpdateStandaloneRoutineExerciseRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateStandaloneRoutineExerciseRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Program Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/standalone/programs`.
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

/// Body for `PATCH /api/standalone/programs/:programId`.
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

// ──────────────────────────────────────────────────────────
// ProgramRoutine Junction Requests
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/standalone/programs/:programId/routines`.
@freezed
abstract class AssignStandaloneRoutineRequest
    with _$AssignStandaloneRoutineRequest {
  const factory AssignStandaloneRoutineRequest({
    required String routineId,
    required int dayNumber,
  }) = _AssignStandaloneRoutineRequest;

  factory AssignStandaloneRoutineRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignStandaloneRoutineRequestFromJson(json);
}

/// Body for `PATCH /api/standalone/programs/:programId/routines/:programRoutineId`.
@freezed
abstract class UpdateStandaloneProgramRoutineRequest
    with _$UpdateStandaloneProgramRoutineRequest {
  const factory UpdateStandaloneProgramRoutineRequest({
    required int dayNumber,
  }) = _UpdateStandaloneProgramRoutineRequest;

  factory UpdateStandaloneProgramRoutineRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateStandaloneProgramRoutineRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Activation Request
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/standalone/programs/:programId/activate`.
@freezed
abstract class ActivateStandaloneProgramRequest
    with _$ActivateStandaloneProgramRequest {
  const factory ActivateStandaloneProgramRequest({
    /// Start date in ISO 8601 format. Defaults to current date on server.
    String? startDate,
  }) = _ActivateStandaloneProgramRequest;

  factory ActivateStandaloneProgramRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$ActivateStandaloneProgramRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Session Request
// ──────────────────────────────────────────────────────────

/// Body for `POST /api/standalone/sessions`.
@freezed
abstract class StartStandaloneSessionRequest
    with _$StartStandaloneSessionRequest {
  const factory StartStandaloneSessionRequest({
    /// Optional: link session to an active standalone program assignment.
    String? assignedProgramId,
  }) = _StartStandaloneSessionRequest;

  factory StartStandaloneSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$StartStandaloneSessionRequestFromJson(json);
}
