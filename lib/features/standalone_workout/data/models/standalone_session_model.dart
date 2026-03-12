import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../workout/data/models/workout_session_model.dart';

export '../../../workout/data/models/workout_session_model.dart';
export '../../../workout/data/models/weekly_stats_model.dart';

part 'standalone_session_model.freezed.dart';
part 'standalone_session_model.g.dart';

/// Standalone session list response (paginated).
///
/// Returned by `GET /api/standalone/sessions`.
/// Server wraps pagination in a nested `pagination` object.
@freezed
abstract class StandaloneSessionListResponse
    with _$StandaloneSessionListResponse {
  const factory StandaloneSessionListResponse({
    required List<StandaloneSessionSummary> sessions,
    required StandaloneSessionPagination pagination,
  }) = _StandaloneSessionListResponse;

  factory StandaloneSessionListResponse.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionListResponseFromJson(json);
}

/// Pagination metadata for standalone session history.
@freezed
abstract class StandaloneSessionPagination with _$StandaloneSessionPagination {
  const factory StandaloneSessionPagination({
    @Default(0) int total,
    @Default(20) int limit,
    @Default(0) int offset,
    @Default(false) bool hasMore,
  }) = _StandaloneSessionPagination;

  factory StandaloneSessionPagination.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionPaginationFromJson(json);
}

/// Lightweight session summary for history list views.
///
/// Returned inside [StandaloneSessionListResponse].
@freezed
abstract class StandaloneSessionSummary with _$StandaloneSessionSummary {
  const factory StandaloneSessionSummary({
    required String id,
    required String userId,
    String? assignedProgramId,
    String? routineId,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,

    /// Total sets logged (server-computed).
    @Default(0) int totalSets,

    /// Routine name resolved by the server.
    String? routineName,
  }) = _StandaloneSessionSummary;

  factory StandaloneSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$StandaloneSessionSummaryFromJson(json);
}

/// Extension helpers for [StandaloneSessionSummary].
extension StandaloneSessionSummaryX on StandaloneSessionSummary {
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

  /// Convert to [WorkoutSessionModel] for reuse in shared session UI.
  WorkoutSessionModel toWorkoutSessionModel() => WorkoutSessionModel(
    id: id,
    userId: userId,
    assignedProgramId: assignedProgramId,
    routineId: routineId,
    startedAt: startedAt,
    completedAt: completedAt,
    notes: notes,
  );
}
