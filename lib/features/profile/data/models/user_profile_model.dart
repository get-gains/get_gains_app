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

/// Enum matching the server's DayOfWeek enum.
///
/// Values match the Prisma DayOfWeek enum and DAY_NAMES on the server.
enum DayOfWeek {
  @JsonValue('SUNDAY')
  sunday,
  @JsonValue('MONDAY')
  monday,
  @JsonValue('TUESDAY')
  tuesday,
  @JsonValue('WEDNESDAY')
  wednesday,
  @JsonValue('THURSDAY')
  thursday,
  @JsonValue('FRIDAY')
  friday,
  @JsonValue('SATURDAY')
  saturday,
}

/// User fitness profile returned from GET /api/profile.
///
/// Maps 1:1 to the server's `toProfileDto` shape.
/// The server always returns a profile (the user row exists since
/// registration). [isOnboarded] is derived server-side from whether
/// any optional profile fields have been filled in.
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
    Sex? sex,
    DateTime? dateOfBirth,
    @Default([]) List<String> equipment,
    String? injuryHistory,
    ExperienceLevel? experienceLevel,
    @Default([]) List<DayOfWeek> activeWeekdays,

    // Onboarding status (derived server-side)
    @Default(false) bool isOnboarded,

    // Timestamps
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}
