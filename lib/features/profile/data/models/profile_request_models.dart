import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_profile_model.dart';

part 'profile_request_models.freezed.dart';
part 'profile_request_models.g.dart';

/// Request body for POST /api/profile (onboarding).
///
/// `daysAvailable` and `sessionDurationMinutes` are required by the server.
/// All other fields are optional and can be filled in during onboarding or
/// later via profile editing.
///
/// **Avatar handling**: The optional [avatarFilePath] is NOT serialised to
/// JSON — it is only used by [UserProfileRepository] when building a
/// multipart/form-data request.  The server stores the avatar in S3 and
/// returns a presigned URL in the response `avatarUrl` field.
@freezed
abstract class CreateUserProfileRequest with _$CreateUserProfileRequest {
  const factory CreateUserProfileRequest({
    // Availability — required for onboarding
    required int daysAvailable,
    required int sessionDurationMinutes,

    // Personal Data — optional
    String? bio,
    double? heightCm,
    double? weightKg,
    String? unitPreference,
    Sex? sex,
    DateTime? dateOfBirth,
    @Default([]) List<String> equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,

    /// Local file path for avatar image to upload.
    /// Excluded from JSON – handled via multipart form-data in the repository.
    @JsonKey(includeToJson: false, includeFromJson: false)
    String? avatarFilePath,
  }) = _CreateUserProfileRequest;

  factory CreateUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserProfileRequestFromJson(json);
}

/// Request body for PATCH /api/profile (editing).
///
/// Every field is optional. Only provided fields are updated on the server.
/// Use explicit `null` for clearable fields (dateOfBirth, injuryHistory)
/// to unset them.
///
/// **Avatar management**:
/// - Provide [avatarFilePath] to upload a new avatar (replaces existing).
/// - Set [removeAvatar] to `true` to delete the current avatar without
///   replacement.
/// - Leave both unset to keep the avatar unchanged.
@freezed
abstract class UpdateUserProfileRequest with _$UpdateUserProfileRequest {
  const factory UpdateUserProfileRequest({
    String? bio,
    double? heightCm,
    double? weightKg,
    String? unitPreference,
    Sex? sex,
    DateTime? dateOfBirth,
    List<String>? equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,
    int? daysAvailable,
    int? sessionDurationMinutes,

    /// Local file path for a new avatar image to upload.
    /// Excluded from JSON – handled via multipart form-data in the repository.
    @JsonKey(includeToJson: false, includeFromJson: false)
    String? avatarFilePath,

    /// When `true`, deletes the current avatar from S3 without replacement.
    /// Excluded from JSON – sent as a form field in the repository.
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default(false)
    bool removeAvatar,
  }) = _UpdateUserProfileRequest;

  factory UpdateUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserProfileRequestFromJson(json);
}
