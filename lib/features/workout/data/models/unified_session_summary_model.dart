import 'package:freezed_annotation/freezed_annotation.dart';

part 'unified_session_summary_model.freezed.dart';
part 'unified_session_summary_model.g.dart';

/// A single session in the unified session history.
///
/// Returned by `GET /api/sessions/history`. Each session includes
/// a derived `source` field ("standalone" or "coach") and optional
/// `programName` / `coachName` for coach-assigned sessions.
@freezed
abstract class UnifiedSessionSummary with _$UnifiedSessionSummary {
  const factory UnifiedSessionSummary({
    required String id,
    required String userId,
    String? assignedProgramId,
    String? routineId,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,
    @Default(0) int totalSets,
    String? routineName,

    /// "standalone" or "coach"
    required String source,
    String? programName,
    String? coachName,
  }) = _UnifiedSessionSummary;

  factory UnifiedSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$UnifiedSessionSummaryFromJson(json);
}

/// Paginated response for unified session history.
@freezed
abstract class UnifiedSessionHistoryResponse
    with _$UnifiedSessionHistoryResponse {
  const factory UnifiedSessionHistoryResponse({
    required List<UnifiedSessionSummary> sessions,
    required SessionHistoryPagination pagination,
  }) = _UnifiedSessionHistoryResponse;

  factory UnifiedSessionHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedSessionHistoryResponseFromJson(json);
}

/// Pagination metadata for unified session history.
@freezed
abstract class SessionHistoryPagination with _$SessionHistoryPagination {
  const factory SessionHistoryPagination({
    @Default(0) int total,
    @Default(20) int limit,
    @Default(0) int offset,
    @Default(false) bool hasMore,
  }) = _SessionHistoryPagination;

  factory SessionHistoryPagination.fromJson(Map<String, dynamic> json) =>
      _$SessionHistoryPaginationFromJson(json);
}

/// Extension helpers for [UnifiedSessionSummary].
extension UnifiedSessionSummaryX on UnifiedSessionSummary {
  /// Whether the session has been completed.
  bool get isCompleted => completedAt != null;

  /// Whether this is a coach-assigned session.
  bool get isCoach => source == 'coach';

  /// Whether this is a standalone session.
  bool get isStandalone => source == 'standalone';

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

  /// Subtitle for coach sessions: "Program Name · Coach Name"
  String? get coachSubtitle {
    if (!isCoach) return null;
    final parts = <String>[];
    if (programName != null) parts.add(programName!);
    if (coachName != null) parts.add(coachName!);
    return parts.isNotEmpty ? parts.join(' · ') : null;
  }
}
