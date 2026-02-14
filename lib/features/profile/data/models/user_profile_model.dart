import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

/// Enum matching the server's Sex enum.
enum Sex {
  @JsonValue('MALE')
  male,
  @JsonValue('FEMALE')
  female,
}

/// Enum matching the server's ExperienceLevel enum.
enum ExperienceLevel {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('INTERMEDIATE')
  intermediate,
  @JsonValue('ADVANCED')
  advanced,
}

/// User fitness profile returned from GET /api/profile.
///
/// Maps 1:1 to the server's `profileSelect` shape.
/// `daysAvailable` and `sessionDurationMinutes` are required on the server
/// during creation but the full profile response always includes them, so
/// they are non-nullable here.
@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String id,
    required String userId,
    String? bio,
    String? avatarUrl,

    // Personal Data
    double? heightCm,
    double? weightKg,
    String? unitPreference,
    Sex? sex,
    DateTime? dateOfBirth,
    @Default([]) List<String> equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,

    // Availability
    required int daysAvailable,
    required int sessionDurationMinutes,

    // Timestamps
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}
