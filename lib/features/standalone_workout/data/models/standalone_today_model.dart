import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/routine_model.dart';

part 'standalone_today_model.freezed.dart';
part 'standalone_today_model.g.dart';

/// Today's Routine Model (Standalone)
///
/// Represents the server's calculated routine for today based on
/// the user's active standalone program and day-cycle logic.
///
/// Returned by `GET /api/standalone/today`.
///
/// The JSON shape is the same as the coach-assigned
/// [TodayRoutineModel] but scoped to standalone programs.
@freezed
abstract class StandaloneTodayModel with _$StandaloneTodayModel {
  const factory StandaloneTodayModel({
    /// Whether today is a rest day (no routine scheduled).
    @Default(false) bool isRestDay,

    /// Today's routine info — null when [isRestDay] is true or no active program.
    StandaloneTodayDetails? today,

    /// Optional server message (e.g. "Program has not started yet").
    String? message,
  }) = _StandaloneTodayModel;

  factory StandaloneTodayModel.fromJson(Map<String, dynamic> json) =>
      _$StandaloneTodayModelFromJson(json);
}

/// Details of today's scheduled routine within a standalone program.
@freezed
abstract class StandaloneTodayDetails with _$StandaloneTodayDetails {
  const factory StandaloneTodayDetails({
    required String programRoutineId,
    required String dayOfWeek,
    required String assignedProgramId,
    required String programName,
    @RoutineModelConverter()
    required RoutineModel routine,
  }) = _StandaloneTodayDetails;

  factory StandaloneTodayDetails.fromJson(Map<String, dynamic> json) =>
      _$StandaloneTodayDetailsFromJson(json);
}

/// Extension helpers for [StandaloneTodayModel].
extension StandaloneTodayModelX on StandaloneTodayModel {
  /// Whether there is an assigned routine for today.
  bool get hasRoutine => !isRestDay && today != null;

  /// The routine name, or 'Rest Day' / 'No Program'.
  String get displayName =>
      today?.routine.name ?? (isRestDay ? 'Rest Day' : 'No Program');

  /// Number of exercises in today's routine, 0 if rest day.
  int get exerciseCount => today?.routine.exercises.length ?? 0;

  /// Estimated workout duration in minutes.
  int get estimatedMinutes => today?.routine.estimatedDurationMinutes ?? 0;
}
