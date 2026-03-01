import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_session_model.freezed.dart';
part 'client_session_model.g.dart';

/// Summary of a single client workout session (list view).
@freezed
abstract class ClientSessionSummary with _$ClientSessionSummary {
  const factory ClientSessionSummary({
    required String id,
    String? assignedProgramId,
    String? programName,
    required DateTime startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    @Default(0) int totalSets,
    @Default(0) int uniqueExercises,
    String? notes,
  }) = _ClientSessionSummary;

  factory ClientSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$ClientSessionSummaryFromJson(json);
}

/// Full detail for a single client workout session with exercises and sets.
@freezed
abstract class ClientSessionDetail with _$ClientSessionDetail {
  const factory ClientSessionDetail({
    required String id,
    required String userId,
    String? assignedProgramId,
    String? programName,
    required DateTime startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    String? notes,
    @Default([]) List<SessionExerciseGroup> exercises,
    @Default(0) int totalSets,
    @Default(0) int totalReps,
    @Default(0.0) double totalVolume,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ClientSessionDetail;

  factory ClientSessionDetail.fromJson(Map<String, dynamic> json) =>
      _$ClientSessionDetailFromJson(json);
}

/// A group of performed sets for a single exercise within a session.
@freezed
abstract class SessionExerciseGroup with _$SessionExerciseGroup {
  const factory SessionExerciseGroup({
    required String exerciseId,
    required String exerciseName,
    String? primaryMuscleGroup,
    @Default([]) List<PerformedSetDetail> sets,
  }) = _SessionExerciseGroup;

  factory SessionExerciseGroup.fromJson(Map<String, dynamic> json) =>
      _$SessionExerciseGroupFromJson(json);
}

/// A single performed set within a session exercise group.
@freezed
abstract class PerformedSetDetail with _$PerformedSetDetail {
  const factory PerformedSetDetail({
    required String id,
    required int setNumber,
    @Default(0) int repsCompleted,
    double? weightKg,
    int? rpe,
    String? notes,
    required DateTime createdAt,
  }) = _PerformedSetDetail;

  factory PerformedSetDetail.fromJson(Map<String, dynamic> json) =>
      _$PerformedSetDetailFromJson(json);
}
