import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/exercise_model.dart';
import '../../../workout/data/models/routine_model.dart';

export '../../../workout/data/models/exercise_model.dart'
    show MuscleGroup, MuscleGroupX;

part 'program_model.freezed.dart';
part 'program_model.g.dart';

// ──────────────────────────────────────────────────────────
// Day of Week Enum
// ──────────────────────────────────────────────────────────

enum DayOfWeek {
  @JsonValue('MONDAY') monday,
  @JsonValue('TUESDAY') tuesday,
  @JsonValue('WEDNESDAY') wednesday,
  @JsonValue('THURSDAY') thursday,
  @JsonValue('FRIDAY') friday,
  @JsonValue('SATURDAY') saturday,
  @JsonValue('SUNDAY') sunday;

  /// Human-readable label, e.g. DayOfWeek.monday.label == 'Monday'
  String get label {
    switch (this) {
      case DayOfWeek.monday: return 'Monday';
      case DayOfWeek.tuesday: return 'Tuesday';
      case DayOfWeek.wednesday: return 'Wednesday';
      case DayOfWeek.thursday: return 'Thursday';
      case DayOfWeek.friday: return 'Friday';
      case DayOfWeek.saturday: return 'Saturday';
      case DayOfWeek.sunday: return 'Sunday';
    }
  }

  /// Short 3-letter label, e.g. 'Mon'
  String get shortLabel {
    switch (this) {
      case DayOfWeek.monday: return 'Mon';
      case DayOfWeek.tuesday: return 'Tue';
      case DayOfWeek.wednesday: return 'Wed';
      case DayOfWeek.thursday: return 'Thu';
      case DayOfWeek.friday: return 'Fri';
      case DayOfWeek.saturday: return 'Sat';
      case DayOfWeek.sunday: return 'Sun';
    }
  }

  /// Returns the DayOfWeek matching today (based on DateTime.now())
  static DayOfWeek get today {
    // DateTime.weekday: 1=Monday ... 7=Sunday
    return DayOfWeek.values[DateTime.now().weekday - 1];
  }
}

// ──────────────────────────────────────────────────────────
// Program Models
// ──────────────────────────────────────────────────────────

/// Program List Item
///
/// Lightweight summary returned by `GET /api/coach/programs`.
@freezed
abstract class ProgramSummaryModel with _$ProgramSummaryModel {
  const factory ProgramSummaryModel({
    required String id,
    required String name,
    required String description,
    @Default(0) int routineCount,
    @Default(0) int assignedClientCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ProgramSummaryModel;

  factory ProgramSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramSummaryModelFromJson(json);
}

/// Program Detail Model
///
/// Full program with nested routine / exercise tree
/// returned by `GET /api/coach/programs/:programId`.
@freezed
abstract class ProgramDetailModel with _$ProgramDetailModel {
  const factory ProgramDetailModel({
    required String id,
    required String name,
    required String description,
    required String coachId,
    @Default([]) List<ProgramRoutineSlotModel> routines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ProgramDetailModel;

  factory ProgramDetailModel.fromJson(Map<String, dynamic> json) {
    final normalizedJson = Map<String, dynamic>.from(json);

    normalizedJson['coachId'] ??=
        normalizedJson['coach_id'] ??
        normalizedJson['userId'] ??
        normalizedJson['user_id'];
    normalizedJson['createdAt'] ??= normalizedJson['created_at'];
    normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];
    normalizedJson['description'] ??= '';
    normalizedJson['routines'] ??= const [];

    return _$ProgramDetailModelFromJson(normalizedJson);
  }
}

/// Extension for program detail
extension ProgramDetailModelX on ProgramDetailModel {
  /// Total number of day-slots in this program
  int get totalDays => routines.length;
}

// ──────────────────────────────────────────────────────────
// ProgramRoutine Junction Models
// ──────────────────────────────────────────────────────────

/// A day-slot that links a [RoutineModel] to a program on a specific day.
///
/// Returned inside [ProgramDetailModel.routines].
@freezed
abstract class ProgramRoutineSlotModel with _$ProgramRoutineSlotModel {
  const factory ProgramRoutineSlotModel({
    required String id,
    required DayOfWeek dayOfWeek,
    required RoutineModel routine,
  }) = _ProgramRoutineSlotModel;

  factory ProgramRoutineSlotModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramRoutineSlotModelFromJson(json);
}

/// Raw ProgramRoutine record returned by assign / update operations.
@freezed
abstract class ProgramRoutineModel with _$ProgramRoutineModel {
  const factory ProgramRoutineModel({
    required String id,
    required String programId,
    required String routineId,
    required DayOfWeek dayOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ProgramRoutineModel;

  factory ProgramRoutineModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramRoutineModelFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Routine Summary (list view with counts)
// ──────────────────────────────────────────────────────────

/// Routine summary with exercise and program counts.
///
/// Returned by `GET /api/coach/routines`.
@freezed
abstract class RoutineSummaryModel with _$RoutineSummaryModel {
  const factory RoutineSummaryModel({
    required String id,
    required String coachId,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,
    @Default(0) int exerciseCount,
    @Default(0) int programCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RoutineSummaryModel;

  factory RoutineSummaryModel.fromJson(Map<String, dynamic> json) {
    final normalizedJson = Map<String, dynamic>.from(json);

    normalizedJson['coachId'] ??=
        normalizedJson['coach_id'] ??
        normalizedJson['userId'] ??
        normalizedJson['user_id'] ??
        'unknown';
    normalizedJson['estimatedDurationMinutes'] ??=
        normalizedJson['estimated_duration_minutes'] ??
        0;
    normalizedJson['muscleGroupsTargeted'] = normalizeMuscleGroupApiList(
      normalizedJson['muscleGroupsTargeted'] ??
          normalizedJson['muscle_groups_targeted'],
    );
    normalizedJson['exerciseCount'] ??= normalizedJson['exercise_count'] ?? 0;
    normalizedJson['programCount'] ??= normalizedJson['program_count'] ?? 0;
    normalizedJson['createdAt'] ??= normalizedJson['created_at'];
    normalizedJson['updatedAt'] ??= normalizedJson['updated_at'];
    normalizedJson['description'] ??= '';

    return _$RoutineSummaryModelFromJson(normalizedJson);
  }
}

// ──────────────────────────────────────────────────────────
// Assigned Program Models
// ──────────────────────────────────────────────────────────

/// Program assignment linking a program to a client.
@freezed
abstract class AssignedProgramModel with _$AssignedProgramModel {
  const factory AssignedProgramModel({
    required String id,
    required String userId,
    required String programId,
    required DateTime startDate,
    DateTime? endDate,
    @Default(true) bool isActive,
    String? notes,
    AssignmentProgramInfo? program,
    AssignmentUserInfo? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AssignedProgramModel;

  factory AssignedProgramModel.fromJson(Map<String, dynamic> json) =>
      _$AssignedProgramModelFromJson(json);
}

/// Minimal program info nested in an assignment.
@freezed
abstract class AssignmentProgramInfo with _$AssignmentProgramInfo {
  const factory AssignmentProgramInfo({
    required String id,
    required String name,
    String? description,
    int? routineCount,
  }) = _AssignmentProgramInfo;

  factory AssignmentProgramInfo.fromJson(Map<String, dynamic> json) =>
      _$AssignmentProgramInfoFromJson(json);
}

/// Minimal user info nested in an assignment.
@freezed
abstract class AssignmentUserInfo with _$AssignmentUserInfo {
  const factory AssignmentUserInfo({
    required String id,
    required String email,
    String? name,
    String? nickname,
  }) = _AssignmentUserInfo;

  factory AssignmentUserInfo.fromJson(Map<String, dynamic> json) =>
      _$AssignmentUserInfoFromJson(json);
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
