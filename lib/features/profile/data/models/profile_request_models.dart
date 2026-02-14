import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_profile_model.dart';

part 'profile_request_models.freezed.dart';
part 'profile_request_models.g.dart';

/// Request body for POST /api/profile (onboarding).
///
/// `daysAvailable` and `sessionDurationMinutes` are required by the server.
/// All other fields are optional and can be filled in during onboarding or
/// later via profile editing.
@freezed
abstract class CreateUserProfileRequest with _$CreateUserProfileRequest {
  const factory CreateUserProfileRequest({
    // Availability — required for onboarding
    required int daysAvailable,
    required int sessionDurationMinutes,

    // Personal Data — optional
    String? bio,
    String? avatarUrl,
    double? heightCm,
    double? weightKg,
    String? unitPreference,
    Sex? sex,
    DateTime? dateOfBirth,
    @Default([]) List<String> equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,
  }) = _CreateUserProfileRequest;

  factory CreateUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserProfileRequestFromJson(json);
}

/// Request body for PATCH /api/profile (editing).
///
/// Every field is optional. Only provided fields are updated on the server.
/// Use explicit `null` for clearable fields (avatarUrl, dateOfBirth,
/// injuryHistory) to unset them.
@freezed
abstract class UpdateUserProfileRequest with _$UpdateUserProfileRequest {
  const factory UpdateUserProfileRequest({
    String? bio,
    String? avatarUrl,
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
  }) = _UpdateUserProfileRequest;

  factory UpdateUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserProfileRequestFromJson(json);
}
