import 'package:freezed_annotation/freezed_annotation.dart';

import 'routine_model.dart';

part 'today_routine_model.freezed.dart';
part 'today_routine_model.g.dart';

/// Today's Routine Model
///
/// Represents the server's calculated routine for today based on
/// the user's active assigned program and day-cycle logic.
///
/// Returned by `GET /api/workout/today`.
@freezed
abstract class TodayRoutineModel with _$TodayRoutineModel {
  const factory TodayRoutineModel({
    /// Whether today is a rest day (no routine scheduled).
    @Default(false) bool isRestDay,

    /// Today's routine info — null when [isRestDay] is true.
    TodayRoutineDetails? today,

    /// Whether the user has already completed a session today.
    @Default(false) bool completedToday,
  }) = _TodayRoutineModel;

  factory TodayRoutineModel.fromJson(Map<String, dynamic> json) =>
      _$TodayRoutineModelFromJson(json);
}

/// Details of today's scheduled routine within a program.
@freezed
abstract class TodayRoutineDetails with _$TodayRoutineDetails {
  const factory TodayRoutineDetails({
    required String programRoutineId,
    required int dayNumber,
    required String assignedProgramId,
    required String programName,
    required RoutineModel routine,
  }) = _TodayRoutineDetails;

  factory TodayRoutineDetails.fromJson(Map<String, dynamic> json) =>
      _$TodayRoutineDetailsFromJson(json);
}

/// Extension helpers for [TodayRoutineModel].
extension TodayRoutineModelX on TodayRoutineModel {
  /// Whether there is an assigned routine for today.
  bool get hasRoutine => !isRestDay && today != null;

  /// The routine name, or 'Rest Day' when none is scheduled.
  String get displayName =>
      today?.routine.name ?? (isRestDay ? 'Rest Day' : 'No Program');

  /// Number of exercises in today's routine, 0 if rest day.
  int get exerciseCount => today?.routine.exercises.length ?? 0;

  /// Estimated workout duration in minutes.
  int get estimatedMinutes => today?.routine.estimatedDurationMinutes ?? 0;
}
