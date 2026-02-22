import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_settings_model.freezed.dart';
part 'coach_settings_model.g.dart';

// ──────────────────────────────────────────────────────────
// Coach Settings Models (ML-5)
// ──────────────────────────────────────────────────────────

/// Coach settings model — 1-to-1 with Coach.
///
/// Returned by `GET /api/coach/settings` and `PATCH /api/coach/settings`.
/// Created automatically (with defaults) when a coach profile is created.
///
/// Settings:
/// - `maxClients` — Hard cap on active client count (default 40)
/// - `acceptingClients` — Manual on/off switch for new intake (default true)
/// - `isDiscoverable` — Appear in public search results (default true)
@freezed
abstract class CoachSettingsModel with _$CoachSettingsModel {
  const factory CoachSettingsModel({
    required String id,
    required String coachId,

    /// Hard cap on the number of active clients.
    /// Coach can lower it to close intake early.
    @Default(40) int maxClients,

    /// Manual kill-switch for new client intake.
    /// Allows a coach to pause intake without changing [maxClients].
    @Default(true) bool acceptingClients,

    /// Controls whether the coach appears in `GET /api/user/coaches`.
    /// Useful for coaches who want to onboard by invite only.
    @Default(true) bool isDiscoverable,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CoachSettingsModel;

  factory CoachSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$CoachSettingsModelFromJson(json);
}

/// Request model for updating coach settings.
///
/// All fields are optional — only included fields are updated.
/// `PATCH /api/coach/settings`
@freezed
abstract class UpdateCoachSettingsRequest with _$UpdateCoachSettingsRequest {
  const factory UpdateCoachSettingsRequest({
    /// New max client capacity (1–1000).
    int? maxClients,

    /// Whether to accept new clients.
    bool? acceptingClients,

    /// Whether to appear in public search.
    bool? isDiscoverable,
  }) = _UpdateCoachSettingsRequest;

  factory UpdateCoachSettingsRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateCoachSettingsRequestFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Extensions
// ──────────────────────────────────────────────────────────

/// Convenience helpers for [CoachSettingsModel].
extension CoachSettingsModelX on CoachSettingsModel {
  /// Whether the coach is currently open for new clients
  /// (both accepting AND not at capacity).
  ///
  /// Note: This is a client-side approximation — the server does the
  /// authoritative capacity check with a real-time client count.
  bool get isOpenForClients => acceptingClients;

  /// Whether the coach is hidden from public discovery.
  bool get isHidden => !isDiscoverable;
}

/// Extension to strip null fields for PATCH requests.
extension UpdateCoachSettingsRequestX on UpdateCoachSettingsRequest {
  /// Converts to a JSON map with only non-null fields.
  /// Used for PATCH where omitted fields mean "no change".
  Map<String, dynamic> toJsonNonNull() {
    final json = <String, dynamic>{};
    if (maxClients != null) json['maxClients'] = maxClients;
    if (acceptingClients != null) json['acceptingClients'] = acceptingClients;
    if (isDiscoverable != null) json['isDiscoverable'] = isDiscoverable;
    return json;
  }
}
