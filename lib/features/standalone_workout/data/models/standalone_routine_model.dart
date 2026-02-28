import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/exercise_model.dart';
import '../../../workout/data/models/routine_model.dart';

part 'standalone_routine_model.freezed.dart';
part 'standalone_routine_model.g.dart';

// ──────────────────────────────────────────────────────────
// Personal Routine Models (standalone – user-owned)
// ──────────────────────────────────────────────────────────

/// Standalone routine summary for list views.
///
/// Returned by `GET /api/standalone/routines` (paginated).
@freezed
abstract class StandaloneRoutineSummaryModel
    with _$StandaloneRoutineSummaryModel {
  const factory StandaloneRoutineSummaryModel({
    required String id,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
    @Default([]) List<MuscleGroup> muscleGroupsTargeted,

    /// Number of exercises in this routine (server-computed).
    @Default(0) int exerciseCount,

    /// User who owns this routine.
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StandaloneRoutineSummaryModel;

  factory StandaloneRoutineSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$StandaloneRoutineSummaryModelFromJson(json);
}

/// Extension for routine summary helpers.
extension StandaloneRoutineSummaryModelX on StandaloneRoutineSummaryModel {
  /// Convert to full [RoutineModel] with empty exercises list.
  RoutineModel toRoutineModel() => RoutineModel(
    id: id,
    name: name,
    description: description,
    estimatedDurationMinutes: estimatedDurationMinutes,
    muscleGroupsTargeted: muscleGroupsTargeted,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Standalone routine detail with exercises.
///
/// Returned by `GET /api/standalone/routines/:routineId`.
/// Re-uses the existing [RoutineModel] + [RoutineExerciseModel] from the
/// workout feature — the JSON shape is identical.
///
/// See [RoutineModel] for fields.

/// Paginated response for standalone routine list.
@freezed
abstract class StandaloneRoutineListResponse
    with _$StandaloneRoutineListResponse {
  const factory StandaloneRoutineListResponse({
    required List<StandaloneRoutineSummaryModel> routines,
    required int total,
    required int limit,
    required int offset,
    @Default(false) bool hasMore,
  }) = _StandaloneRoutineListResponse;

  factory StandaloneRoutineListResponse.fromJson(Map<String, dynamic> json) =>
      _$StandaloneRoutineListResponseFromJson(json);
}
