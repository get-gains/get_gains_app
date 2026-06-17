import 'package:get_gains_app/core/constants/api_constants.dart';
import 'package:get_gains_app/core/utils/app_error.dart';
import 'package:get_gains_app/core/utils/result.dart';
import 'package:get_gains_app/services/api/api_client.dart';

/// Repository for coach invitation redemption and coach profile creation.
class CoachInviteRepository {
  const CoachInviteRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Verifies a 6-digit coach invitation code.
  Future<Result<bool, AppError>> verifyInvite(String code) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.coachVerifyInvite,
      data: {'code': code},
    );

    return result.map((_) => true);
  }

  /// Creates the coach profile and redeems the invitation.
  Future<Result<bool, AppError>> createCoachProfile({
    required String invitationCode,
    required List<String> certifications,
    required List<String> specialties,
    List<String>? socialLinks,
    int? yearsExperience,
    int? maxClients,
    bool acceptingClients = true,
    bool isDiscoverable = true,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.coachProfile,
      data: {
        'invitation_code': invitationCode,
        'certifications': certifications,
        'specialties': specialties,
        'social_links': socialLinks?.isNotEmpty == true ? socialLinks : null,
        'years_experience': yearsExperience,
        'max_clients': maxClients,
        'accepting_clients': acceptingClients,
        'is_discoverable': isDiscoverable,
      },
    );

    return result.map((_) => true);
  }
}
