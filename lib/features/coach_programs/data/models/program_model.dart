import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/exercise_model.dart';
import '../../../workout/data/models/routine_model.dart';

export '../../../workout/data/models/exercise_model.dart'
    show MuscleGroup, MuscleGroupX;

part 'program_model.freezed.dart';
part 'program_model.g.dart';

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

  factory ProgramDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramDetailModelFromJson(json);
}

/// Extension for program detail
extension ProgramDetailModelX on ProgramDetailModel {
  /// Total number of day-slots in this program
  int get totalDays => routines.length;

  /// Max day number (defines the cycle length)
  int get cycleLengthDays => routines.isEmpty
      ? 0
      : routines.map((r) => r.dayNumber).reduce((a, b) => a > b ? a : b);
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
    required int dayNumber,
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
    required int dayNumber,
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

  factory RoutineSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineSummaryModelFromJson(json);
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
