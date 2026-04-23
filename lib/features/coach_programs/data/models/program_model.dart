import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/exercise_model.dart'
    show normalizeMuscleGroupApiList;
export '../../../workout/data/models/exercise_model.dart'
    show MuscleGroup, MuscleGroupX;

part 'program_model.freezed.dart';
part 'program_model.g.dart';

Map<String, dynamic> _normalizeProgramDetailModelJson(
  Map<String, dynamic> json,
) {
  final normalizedJson = Map<String, dynamic>.from(json);

  normalizedJson['coachId'] ??=
      normalizedJson['coach_id'] ??
      normalizedJson['userId'] ??
      normalizedJson['user_id'];
  normalizedJson['createdAt'] ??= normalizedJson['created_at'];
  normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];
  normalizedJson['description'] ??= '';
  normalizedJson['routines'] ??= const [];

  return normalizedJson;
}

Map<String, dynamic> _normalizeProgramSummaryModelJson(
  Map<String, dynamic> json,
) {
  final normalizedJson = Map<String, dynamic>.from(json);

  normalizedJson['routineCount'] ??= normalizedJson['routine_count'] ?? 0;
  normalizedJson['assignedClientCount'] ??=
      normalizedJson['assigned_client_count'] ?? 0;
  normalizedJson['createdAt'] ??= normalizedJson['created_at'];
  normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];
  normalizedJson['description'] ??= '';

  return normalizedJson;
}

Map<String, dynamic> _normalizeRoutineSummaryModelJson(
  Map<String, dynamic> json,
) {
  final normalizedJson = Map<String, dynamic>.from(json);

  normalizedJson['coachId'] ??=
      normalizedJson['coach_id'] ??
      normalizedJson['userId'] ??
      normalizedJson['user_id'] ??
      'unknown';
  normalizedJson['estimatedDurationMinutes'] ??=
      normalizedJson['estimated_duration_minutes'] ?? 0;
  normalizedJson['muscleGroupsTargeted'] = normalizeMuscleGroupApiList(
    normalizedJson['muscleGroupsTargeted'] ??
        normalizedJson['muscle_groups_targeted'],
  );
  normalizedJson['exerciseCount'] ??= normalizedJson['exercise_count'] ?? 0;
  normalizedJson['programCount'] ??= normalizedJson['program_count'] ?? 0;
  normalizedJson['createdAt'] ??= normalizedJson['created_at'];
  normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];
  normalizedJson['description'] ??= '';

  return normalizedJson;
}

// ──────────────────────────────────────────────────────────
// Day of Week
// ──────────────────────────────────────────────────────────

/// Days of the week matching the server's `DayOfWeek` enum.
enum DayOfWeek {
  @JsonValue('SUNDAY')
  sunday,
  @JsonValue('MONDAY')
  monday,
  @JsonValue('TUESDAY')
  tuesday,
  @JsonValue('WEDNESDAY')
  wednesday,
  @JsonValue('THURSDAY')
  thursday,
  @JsonValue('FRIDAY')
  friday,
  @JsonValue('SATURDAY')
  saturday,
}

/// Display helpers for [DayOfWeek].
extension DayOfWeekX on DayOfWeek {
  /// Full display name (e.g. "Monday").
  String get displayName => switch (this) {
    DayOfWeek.sunday => 'Sunday',
    DayOfWeek.monday => 'Monday',
    DayOfWeek.tuesday => 'Tuesday',
    DayOfWeek.wednesday => 'Wednesday',
    DayOfWeek.thursday => 'Thursday',
    DayOfWeek.friday => 'Friday',
    DayOfWeek.saturday => 'Saturday',
  };

  /// Short display name (e.g. "Mon").
  String get shortName => switch (this) {
    DayOfWeek.sunday => 'Sun',
    DayOfWeek.monday => 'Mon',
    DayOfWeek.tuesday => 'Tue',
    DayOfWeek.wednesday => 'Wed',
    DayOfWeek.thursday => 'Thu',
    DayOfWeek.friday => 'Fri',
    DayOfWeek.saturday => 'Sat',
  };

  /// Single-letter abbreviation (e.g. "M").
  String get letter => switch (this) {
    DayOfWeek.sunday => 'S',
    DayOfWeek.monday => 'M',
    DayOfWeek.tuesday => 'T',
    DayOfWeek.wednesday => 'W',
    DayOfWeek.thursday => 'T',
    DayOfWeek.friday => 'F',
    DayOfWeek.saturday => 'S',
  };
}

// ──────────────────────────────────────────────────────────
// Client Program (full tree)
// ──────────────────────────────────────────────────────────

/// A client-specific training program with nested routines and exercises.
///
/// Returned by `GET /api/coach/clients/:clientId/program`,
/// `GET /api/coach/programs/:programId`, and most mutation endpoints.
@freezed
abstract class ClientProgramModel with _$ClientProgramModel {
  const factory ClientProgramModel({
    required String id,
    @JsonKey(name: 'coach_id') required String coachId,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    required String description,
    String? notes,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @Default([]) List<ProgramRoutineModel> routines,
  }) = _ClientProgramModel;

  factory ClientProgramModel.fromJson(Map<String, dynamic> json) =>
      _$ClientProgramModelFromJson(json);
}

/// Convenience helpers for [ClientProgramModel].
extension ClientProgramModelX on ClientProgramModel {
  /// Total number of routines in the program.
  int get routineCount => routines.length;

  /// Total number of exercises across all routines.
  int get totalExerciseCount =>
      routines.fold(0, (sum, r) => sum + r.exercises.length);
}

// ──────────────────────────────────────────────────────────
// Program Routine
// ──────────────────────────────────────────────────────────

/// A self-contained routine within a client's program.
///
/// Replaces the old `ProgramRoutineSlotModel` — data is owned by the
/// assignment, not a live FK to the template library.
@freezed
abstract class ProgramRoutineModel with _$ProgramRoutineModel {
  const factory ProgramRoutineModel({
    required String id,
    @JsonKey(name: 'source_routine_id') String? sourceRoutineId,
    required String name,
    required String description,
    @JsonKey(name: 'estimated_duration_minutes')
    required int estimatedDurationMinutes,
    @JsonKey(name: 'order_in_program') required int orderInProgram,
    @JsonKey(name: 'days_of_week') @Default([]) List<DayOfWeek> daysOfWeek,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @Default([]) List<ProgramRoutineExerciseModel> exercises,
  }) = _ProgramRoutineModel;

  factory ProgramRoutineModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramRoutineModelFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Program Routine Exercise
// ──────────────────────────────────────────────────────────

/// An exercise prescription within a program routine.
///
/// The `exercise` field contains a lightweight snapshot of the exercise
/// catalog entry (name, description, target muscles) — not the full
/// [ExerciseModel].
@freezed
abstract class ProgramRoutineExerciseModel with _$ProgramRoutineExerciseModel {
  const factory ProgramRoutineExerciseModel({
    required String id,
    @JsonKey(name: 'exercise_id') required String exerciseId,
    required int sets,
    @JsonKey(name: 'reps_min') required int repsMin,
    @JsonKey(name: 'reps_max') required int repsMax,
    @JsonKey(name: 'rest_seconds') required int restSeconds,
    @JsonKey(name: 'order_in_routine') required int orderInRoutine,
    ProgramExerciseInfo? exercise,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ProgramRoutineExerciseModel;

  factory ProgramRoutineExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramRoutineExerciseModelFromJson(json);
}

/// Lightweight exercise info embedded in program routine exercise responses.
///
/// Not the full [ExerciseModel] — only the fields the server projects
/// from the exercise catalog for display within a program tree.
@freezed
abstract class ProgramExerciseInfo with _$ProgramExerciseInfo {
  const factory ProgramExerciseInfo({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'target_muscles') @Default([]) List<String> targetMuscles,
  }) = _ProgramExerciseInfo;

  factory ProgramExerciseInfo.fromJson(Map<String, dynamic> json) =>
      _$ProgramExerciseInfoFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Routine Summary (template library)
// ──────────────────────────────────────────────────────────

/// Routine template summary returned by `GET /api/coach/routine-templates`.
///
/// Used by the template library screens. Does not include `programCount`,
/// `muscleGroupsTargeted`, or `exerciseCount` — the new server endpoint
/// no longer returns those.
@freezed
abstract class RoutineSummaryModel with _$RoutineSummaryModel {
  const factory RoutineSummaryModel({
    required String id,

    /// The owning coach's user ID.
    @JsonKey(name: 'user_id') required String coachId,
    required String name,
    required String description,
    @JsonKey(name: 'estimated_duration_minutes')
    required int estimatedDurationMinutes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _RoutineSummaryModel;

  factory RoutineSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineSummaryModelFromJson(_normalizeRoutineSummaryModelJson(json));
}

// ──────────────────────────────────────────────────────────
// Pagination
// ──────────────────────────────────────────────────────────

/// Standard pagination meta returned by paginated list endpoints.
@freezed
abstract class PaginationMeta with _$PaginationMeta {
  const factory PaginationMeta({
    required int total,
    required int limit,
    required int offset,
    @Default(false) bool hasMore,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
}
