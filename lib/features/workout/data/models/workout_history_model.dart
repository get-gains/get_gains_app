import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_history_model.freezed.dart';
part 'workout_history_model.g.dart';

/// Workout Session Summary from server pagination.
///
/// Lightweight model for history list views — returned by
/// `GET /api/workout/sessions` with pagination metadata.
@freezed
abstract class WorkoutSessionSummary with _$WorkoutSessionSummary {
  const factory WorkoutSessionSummary({
    required String id,
    required String userId,
    @JsonKey(name: 'assignedProgramRoutineId') String? assignedProgramId,
    String? routineId,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,

    /// Total sets logged in this session (server-computed).
    @Default(0) int totalSets,

    /// Routine name resolved by the server (optional).
    String? routineName,

    /// Session source: "standalone" or "coach".
    String? source,
  }) = _WorkoutSessionSummary;

  factory WorkoutSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionSummaryFromJson(json);
}

/// Paginated response for workout session history.
@freezed
abstract class WorkoutHistoryResponse with _$WorkoutHistoryResponse {
  const factory WorkoutHistoryResponse({
    required List<WorkoutSessionSummary> sessions,
    required WorkoutHistoryPagination pagination,
  }) = _WorkoutHistoryResponse;

  factory WorkoutHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkoutHistoryResponseFromJson(json);
}

/// Pagination metadata for workout history.
@freezed
abstract class WorkoutHistoryPagination with _$WorkoutHistoryPagination {
  const factory WorkoutHistoryPagination({
    @Default(0) int total,
    @Default(20) int limit,
    @Default(0) int offset,
    @Default(false) bool hasMore,
  }) = _WorkoutHistoryPagination;

  factory WorkoutHistoryPagination.fromJson(Map<String, dynamic> json) =>
      _$WorkoutHistoryPaginationFromJson(json);
}

/// Extension helpers for [WorkoutSessionSummary].
extension WorkoutSessionSummaryX on WorkoutSessionSummary {
  /// Whether the session has been completed.
  bool get isCompleted => completedAt != null;

  /// Duration of the workout session.
  Duration? get duration =>
      completedAt != null ? completedAt!.difference(startedAt) : null;

  /// Formatted duration string (e.g., "45m" or "1h 12m").
  String get durationDisplay {
    final d = duration;
    if (d == null) return '—';
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Display name for the session (routine name or fallback).
  String get displayName => routineName ?? 'Workout';
}
