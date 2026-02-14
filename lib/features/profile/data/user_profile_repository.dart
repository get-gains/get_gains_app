import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import 'models/profile_request_models.dart';
import 'models/user_profile_model.dart';

part 'user_profile_repository.g.dart';

/// Repository for user fitness profile operations (onboarding & editing).
///
/// Wraps the `/api/profile` endpoints:
/// - GET    → [getProfile]
/// - POST   → [createProfile]  (onboarding)
/// - PATCH  → [updateProfile]  (editing)
///
/// Also exposes [hasProfile] as a convenience check used by the onboarding
/// guard in the presentation layer.
@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) {
  return UserProfileRepository(ref.watch(apiClientProvider));
}

class UserProfileRepository {
  UserProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  static const _tag = 'UserProfileRepository';

  // ─── GET /profile ───────────────────────────────────────────────────

  /// Fetches the authenticated user's fitness profile.
  ///
  /// Returns `Success(null)` when the server responds with
  /// `{ data: { profile: null } }` — meaning the user has not completed
  /// onboarding yet. This is NOT treated as an error.
  Future<Result<UserProfileModel?, AppError>> getProfile() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.profile,
    );

    return result.when(
      success: (data) {
        final profileJson = data['profile'];
        if (profileJson == null) {
          AppLogger.debug('Profile is null – onboarding required', tag: _tag);
          return const Success(null);
        }

        final profile = UserProfileModel.fromJson(
          profileJson as Map<String, dynamic>,
        );
        AppLogger.debug('Profile loaded', tag: _tag);
        return Success(profile);
      },
      failure: (error) {
        AppLogger.error('Failed to fetch profile', tag: _tag, error: error);
        return Failure(error);
      },
    );
  }

  // ─── POST /profile (onboarding) ────────────────────────────────────

  /// Creates a new fitness profile during onboarding.
  ///
  /// The server returns 409 if a profile already exists.
  Future<Result<UserProfileModel, AppError>> createProfile(
    CreateUserProfileRequest request,
  ) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.profile,
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final profileJson = data['profile'] as Map<String, dynamic>;
        final profile = UserProfileModel.fromJson(profileJson);
        AppLogger.info('Profile created (onboarding)', tag: _tag);
        return Success(profile);
      },
      failure: (error) {
        AppLogger.error('Failed to create profile', tag: _tag, error: error);
        return Failure(error);
      },
    );
  }

  // ─── PATCH /profile (editing) ──────────────────────────────────────

  /// Partially updates the authenticated user's fitness profile.
  ///
  /// Only the fields present in [request] are sent to the server.
  /// Returns 404 if no profile exists (onboarding not completed).
  Future<Result<UserProfileModel, AppError>> updateProfile(
    UpdateUserProfileRequest request,
  ) async {
    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiConstants.profile,
      data: request.toJson(),
    );

    return result.when(
      success: (data) {
        final profileJson = data['profile'] as Map<String, dynamic>;
        final profile = UserProfileModel.fromJson(profileJson);
        AppLogger.info('Profile updated', tag: _tag);
        return Success(profile);
      },
      failure: (error) {
        AppLogger.error('Failed to update profile', tag: _tag, error: error);
        return Failure(error);
      },
    );
  }

  // ─── Onboarding guard helper ───────────────────────────────────────

  /// Checks whether the authenticated user has completed profile onboarding.
  ///
  /// Returns:
  /// - `Success(true)` if a profile exists
  /// - `Success(false)` if the server returns `profile: null`
  /// - `Failure(error)` on network/server errors
  Future<Result<bool, AppError>> hasProfile() async {
    final result = await getProfile();
    return result.when(
      success: (profile) => Success(profile != null),
      failure: (error) => Failure(error),
    );
  }
}
