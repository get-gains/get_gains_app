import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_client_model.freezed.dart';
part 'coach_client_model.g.dart';

// ──────────────────────────────────────────────────────────
// Coach Client / Roster Models (ML-4)
// ──────────────────────────────────────────────────────────

/// A client on the coach's class roster.
///
/// Returned by `GET /api/coach/class`.
/// Includes `subscriptionExpiresAt` (ML-4) so coaches can see when a
/// client's platform subscription ends — **no status/plan data is exposed**
/// to respect privacy boundaries.
@freezed
abstract class RosterClientModel with _$RosterClientModel {
  const factory RosterClientModel({
    required String id,
    required String email,
    String? name,
    String? nickname,
    required DateTime subscribedAt,

    /// When the client's platform subscription expires.
    /// `null` means the client has no active subscription (edge case —
    /// should not normally appear after ML-3 eviction is active).
    ///
    /// Added by ML-4. Coaches see only the date — no status, plan name,
    /// tier level, or price data is exposed.
    DateTime? subscriptionExpiresAt,
  }) = _RosterClientModel;

  factory RosterClientModel.fromJson(Map<String, dynamic> json) =>
      _$RosterClientModelFromJson(json);
}

/// A client with program assignment info on the coach's full client list.
///
/// Returned by `GET /api/coach/clients`.
/// Extends [RosterClientModel] fields with assignment data.
@freezed
abstract class CoachClientModel with _$CoachClientModel {
  const factory CoachClientModel({
    required String id,
    required String email,
    String? name,
    String? nickname,
    required DateTime subscribedAt,

    /// When the client's platform subscription expires (ML-4).
    DateTime? subscriptionExpiresAt,

    /// Programs currently assigned to this client.
    @Default([]) List<ClientAssignedProgram> assignedPrograms,

    /// Whether the client has any active program assignment.
    @Default(false) bool isAssigned,
  }) = _CoachClientModel;

  factory CoachClientModel.fromJson(Map<String, dynamic> json) =>
      _$CoachClientModelFromJson(json);
}

/// Minimal program info nested inside [CoachClientModel.assignedPrograms].
@freezed
abstract class ClientAssignedProgram with _$ClientAssignedProgram {
  const factory ClientAssignedProgram({
    required String programId,
    ClientAssignedProgramInfo? program,
  }) = _ClientAssignedProgram;

  factory ClientAssignedProgram.fromJson(Map<String, dynamic> json) =>
      _$ClientAssignedProgramFromJson(json);
}

/// Minimal program name/info.
@freezed
abstract class ClientAssignedProgramInfo with _$ClientAssignedProgramInfo {
  const factory ClientAssignedProgramInfo({required String name}) =
      _ClientAssignedProgramInfo;

  factory ClientAssignedProgramInfo.fromJson(Map<String, dynamic> json) =>
      _$ClientAssignedProgramInfoFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Extensions
// ──────────────────────────────────────────────────────────

/// Convenience helpers for [RosterClientModel].
extension RosterClientModelX on RosterClientModel {
  /// Display name — falls back through name → nickname → email.
  String get displayName => name ?? nickname ?? email;

  /// Days until subscription expires. `null` if no expiry date.
  int? get daysUntilExpiry {
    if (subscriptionExpiresAt == null) return null;
    final now = DateTime.now();
    if (subscriptionExpiresAt!.isBefore(now)) return 0;
    return subscriptionExpiresAt!.difference(now).inDays;
  }

  /// Whether the subscription is expiring within 7 days.
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 7;
  }
}

/// Convenience helpers for [CoachClientModel].
extension CoachClientModelX on CoachClientModel {
  /// Display name — falls back through name → nickname → email.
  String get displayName => name ?? nickname ?? email;

  /// Days until subscription expires. `null` if no expiry date.
  int? get daysUntilExpiry {
    if (subscriptionExpiresAt == null) return null;
    final now = DateTime.now();
    if (subscriptionExpiresAt!.isBefore(now)) return 0;
    return subscriptionExpiresAt!.difference(now).inDays;
  }

  /// Whether the subscription is expiring within 7 days.
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 7;
  }

  /// Number of programs assigned to this client.
  int get assignedProgramCount => assignedPrograms.length;
}
