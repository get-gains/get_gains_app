import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_model.freezed.dart';
part 'coach_model.g.dart';

// ──────────────────────────────────────────────────────────
// Coach Models — Client-Facing
// ──────────────────────────────────────────────────────────

/// Coach summary returned from discovery list (`GET /user/coaches`)
/// and subscribed list (`GET /user/coaches/subscribed`).
@freezed
abstract class CoachSummaryModel with _$CoachSummaryModel {
  const factory CoachSummaryModel({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    String? bio,
    @Default(0) int yearsExperience,
    @Default([]) List<String> certifications,
    @Default([]) List<String> awards,
    @Default([]) List<String> specialties,
    @Default(false) bool isVerified,
    DateTime? createdAt,

    /// Only present when fetched from subscribed coaches list.
    /// Maps from `startedAt` on the server.
    DateTime? subscribedAt,
  }) = _CoachSummaryModel;

  factory CoachSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$CoachSummaryModelFromJson(json);
}

/// Full coach profile returned from `GET /user/coaches/:coachId` (ML-1).
/// Extends the summary with additional detail-view fields.
@freezed
abstract class CoachDetailModel with _$CoachDetailModel {
  const factory CoachDetailModel({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    String? bio,
    @Default(0) int yearsExperience,
    @Default([]) List<String> certifications,
    @Default([]) List<String> awards,
    @Default([]) List<String> specialties,
    @Default(false) bool isVerified,
    @Default([]) List<String> socialLinks,
    DateTime? createdAt,
  }) = _CoachDetailModel;

  factory CoachDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CoachDetailModelFromJson(json);
}

/// Paginated coach list response wrapper.
@freezed
abstract class CoachListResponse with _$CoachListResponse {
  const factory CoachListResponse({
    required List<CoachSummaryModel> coaches,
    required CoachPaginationMeta pagination,
  }) = _CoachListResponse;

  factory CoachListResponse.fromJson(Map<String, dynamic> json) =>
      _$CoachListResponseFromJson(json);
}

/// Pagination metadata for coach list endpoints.
@freezed
abstract class CoachPaginationMeta with _$CoachPaginationMeta {
  const factory CoachPaginationMeta({
    @Default(0) int total,
    @Default(50) int limit,
    @Default(0) int offset,
    @Default(false) bool hasMore,
  }) = _CoachPaginationMeta;

  factory CoachPaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$CoachPaginationMetaFromJson(json);
}

// ──────────────────────────────────────────────────────────
// Extensions
// ──────────────────────────────────────────────────────────

/// Convenience helpers for [CoachSummaryModel].
extension CoachSummaryModelX on CoachSummaryModel {
  /// Whether this coach was fetched from the subscribed list.
  bool get isSubscribed => subscribedAt != null;

  /// Display-friendly specialties string.
  String get specialtiesDisplay =>
      specialties.isEmpty ? 'General' : specialties.join(', ');
}
