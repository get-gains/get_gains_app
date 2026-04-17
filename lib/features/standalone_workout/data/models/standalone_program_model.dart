import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../coach_programs/data/models/program_model.dart' show DayOfWeek;
import '../../../workout/data/models/routine_model.dart';

export '../../../coach_programs/data/models/program_model.dart' show DayOfWeek;

part 'standalone_program_model.freezed.dart';
part 'standalone_program_model.g.dart';

// ──────────────────────────────────────────────────────────
// Personal Program Models (standalone – user-owned)
// ──────────────────────────────────────────────────────────

/// Program summary for list views.
///
/// Returned by `GET /api/standalone/programs` (paginated).
@freezed
abstract class StandaloneProgramSummaryModel
    with _$StandaloneProgramSummaryModel {
  const factory StandaloneProgramSummaryModel({
    required String id,
    required String name,
    required String description,

    /// Number of routine day-slots in this program.
    @Default(0) int routineCount,

    /// User who owns this program.
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StandaloneProgramSummaryModel;

  factory StandaloneProgramSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramSummaryModelFromJson(json);
}

/// Full program detail with nested routine/exercise tree.
///
/// Returned by `GET /api/standalone/programs/:programId`.
@freezed
abstract class StandaloneProgramDetailModel
    with _$StandaloneProgramDetailModel {
  const factory StandaloneProgramDetailModel({
    required String id,
    required String name,
    required String description,
    String? userId,
    @Default([]) List<StandaloneProgramRoutineSlotModel> routines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StandaloneProgramDetailModel;

  factory StandaloneProgramDetailModel.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramDetailModelFromJson(json);
}

/// Extension for program detail helpers.
extension StandaloneProgramDetailModelX on StandaloneProgramDetailModel {
  /// Total number of day-slots in this program.
  int get totalDays => routines.length;
}

// ──────────────────────────────────────────────────────────
// ProgramRoutine Junction
// ──────────────────────────────────────────────────────────

/// A day-slot linking a [RoutineModel] to a program on a specific day.
///
/// Returned inside [StandaloneProgramDetailModel.routines].
@freezed
abstract class StandaloneProgramRoutineSlotModel
    with _$StandaloneProgramRoutineSlotModel {
  const factory StandaloneProgramRoutineSlotModel({
    required String id,
    required DayOfWeek dayOfWeek,
    @RoutineModelConverter()
    required RoutineModel routine,
  }) = _StandaloneProgramRoutineSlotModel;

  factory StandaloneProgramRoutineSlotModel.fromJson(
    Map<String, dynamic> json,
  ) => _$StandaloneProgramRoutineSlotModelFromJson(json);
}

/// Raw ProgramRoutine record returned by assign/update operations.
@freezed
abstract class StandaloneProgramRoutineModel
    with _$StandaloneProgramRoutineModel {
  const factory StandaloneProgramRoutineModel({
    required String id,
    required String programId,
    required String routineId,
    required DayOfWeek dayOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StandaloneProgramRoutineModel;

  factory StandaloneProgramRoutineModel.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramRoutineModelFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Self-Assignment / Active Program
// ──────────────────────────────────────────────────────────

/// Assigned (active/inactive) program for the user.
///
/// Returned by `POST /activate`, `POST /deactivate`, `GET /active`.
@freezed
abstract class StandaloneAssignedProgramModel
    with _$StandaloneAssignedProgramModel {
  const factory StandaloneAssignedProgramModel({
    required String id,
    required String userId,
    required String programId,
    required DateTime startDate,
    DateTime? endDate,
    @Default(true) bool isActive,

    /// Minimal program info (name/description) nested.
    StandaloneAssignmentProgramInfo? program,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StandaloneAssignedProgramModel;

  factory StandaloneAssignedProgramModel.fromJson(Map<String, dynamic> json) =>
      _$StandaloneAssignedProgramModelFromJson(json);
}

/// Minimal program info inside an assignment response.
@freezed
abstract class StandaloneAssignmentProgramInfo
    with _$StandaloneAssignmentProgramInfo {
  const factory StandaloneAssignmentProgramInfo({
    required String id,
    required String name,
    String? description,
    int? routineCount,
  }) = _StandaloneAssignmentProgramInfo;

  factory StandaloneAssignmentProgramInfo.fromJson(Map<String, dynamic> json) =>
      _$StandaloneAssignmentProgramInfoFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Paginated List Response
// ──────────────────────────────────────────────────────────

/// Paginated response for standalone program list.
@freezed
abstract class StandaloneProgramListResponse
    with _$StandaloneProgramListResponse {
  const factory StandaloneProgramListResponse({
    required List<StandaloneProgramSummaryModel> programs,
    required int total,
    required int limit,
    required int offset,
    @Default(false) bool hasMore,
  }) = _StandaloneProgramListResponse;

  factory StandaloneProgramListResponse.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramListResponseFromJson(json);
}
