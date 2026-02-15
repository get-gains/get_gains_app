import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../services/api/api_client.dart';
import '../../auth/services/user_preferences_service.dart';
import 'models/profile_request_models.dart';
import 'models/user_profile_model.dart';

part 'user_profile_repository.g.dart';

/// Hive storage key for the cached fitness profile.
const String _cachedProfileKey = 'cached_user_profile';

/// Repository for user fitness profile operations (onboarding & editing).
///
/// Wraps the `/api/profile` endpoints:
/// - GET    → [getProfile]   (network-first with local fallback)
/// - POST   → [createProfile]  (onboarding, online only)
/// - PATCH  → [updateProfile]  (editing, online only)
///
/// ## Offline-first display
///
/// On a successful `GET /profile` the response is cached to Hive via
/// [UserPreferencesService]. When the device is offline (or the request
/// fails), the repository falls back to the cached version so the UI
/// can still display profile data.
///
/// ## Avatar upload
///
/// Both `createProfile` and `updateProfile` accept an optional
/// `avatarFilePath` on the request model. When present, the repository
/// builds a `multipart/form-data` request so the file is uploaded
/// alongside the other profile fields.  The server stores the image
/// in S3 and returns a presigned URL in the response.
@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) {
  return UserProfileRepository(
    ref.watch(apiClientProvider),
    ref.watch(userPreferencesServiceProvider),
  );
}

class UserProfileRepository {
  UserProfileRepository(this._apiClient, this._prefs);

  final ApiClient _apiClient;
  final UserPreferencesService _prefs;

  static const _tag = 'UserProfileRepository';

  // ─── GET /profile ───────────────────────────────────────────────────

  /// Fetches the authenticated user's fitness profile.
  ///
  /// **Network-first with local fallback:**
  /// 1. Attempts to fetch from server.
  /// 2. On success, caches the result locally and returns it.
  /// 3. On failure, attempts to return the locally-cached profile.
  /// 4. If no cache exists either, returns the original error.
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
          // Clear any stale cache when the server confirms no profile
          _clearCachedProfile();
          return const Success(null);
        }

        final profile = UserProfileModel.fromJson(
          profileJson as Map<String, dynamic>,
        );
        AppLogger.debug('Profile loaded from server', tag: _tag);

        // Cache for offline use
        _cacheProfile(profile);

        return Success(profile);
      },
      failure: (error) {
        AppLogger.warning(
          'Server fetch failed – attempting local cache',
          tag: _tag,
        );
        return _getCachedProfileOrError(error);
      },
    );
  }

  /// Returns the locally-cached fitness profile without a network call.
  ///
  /// Useful when the caller already knows the device is offline and wants
  /// to avoid a network round-trip.
  Future<UserProfileModel?> getCachedProfile() async {
    return _readCachedProfile();
  }

  // ─── POST /profile (onboarding) ────────────────────────────────────

  /// Creates a new fitness profile during onboarding.
  ///
  /// Sends a `multipart/form-data` request so an optional avatar image
  /// can be uploaded alongside the profile fields.
  ///
  /// The server returns `409` if a profile already exists.
  Future<Result<UserProfileModel, AppError>> createProfile(
    CreateUserProfileRequest request,
  ) async {
    try {
      final formData = await _buildFormData(
        fields: _profileFieldsFromCreate(request),
        avatarFilePath: request.avatarFilePath,
      );

      final result = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.profile,
        data: formData,
      );

      return result.when(
        success: (data) {
          final profileJson = data['profile'] as Map<String, dynamic>;
          final profile = UserProfileModel.fromJson(profileJson);
          AppLogger.info('Profile created (onboarding)', tag: _tag);
          _cacheProfile(profile);
          return Success(profile);
        },
        failure: (error) {
          AppLogger.error('Failed to create profile', tag: _tag, error: error);
          return Failure(error);
        },
      );
    } catch (e) {
      AppLogger.error('Create profile exception', tag: _tag, error: e);
      return Failure(UnknownError(originalError: e));
    }
  }

  // ─── PATCH /profile (editing) ──────────────────────────────────────

  /// Partially updates the authenticated user's fitness profile.
  ///
  /// Sends a `multipart/form-data` request when an avatar file is
  /// included. When [request.removeAvatar] is `true`, the server
  /// deletes the current avatar from S3.
  ///
  /// Only provided fields are sent to the server.
  /// Returns `404` if no profile exists (onboarding not completed).
  Future<Result<UserProfileModel, AppError>> updateProfile(
    UpdateUserProfileRequest request,
  ) async {
    try {
      final fields = _profileFieldsFromUpdate(request);
      final formData = await _buildFormData(
        fields: fields,
        avatarFilePath: request.avatarFilePath,
        removeAvatar: request.removeAvatar,
      );

      final result = await _apiClient.patch<Map<String, dynamic>>(
        ApiConstants.profile,
        data: formData,
      );

      return result.when(
        success: (data) {
          final profileJson = data['profile'] as Map<String, dynamic>;
          final profile = UserProfileModel.fromJson(profileJson);
          AppLogger.info('Profile updated', tag: _tag);
          _cacheProfile(profile);
          return Success(profile);
        },
        failure: (error) {
          AppLogger.error('Failed to update profile', tag: _tag, error: error);
          return Failure(error);
        },
      );
    } catch (e) {
      AppLogger.error('Update profile exception', tag: _tag, error: e);
      return Failure(UnknownError(originalError: e));
    }
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

  // ─── FormData helpers ──────────────────────────────────────────────

  /// Builds a [FormData] instance for multipart/form-data requests.
  ///
  /// Includes only non-null [fields]. When [avatarFilePath] is provided
  /// the file is attached under the `avatar` field name.  When
  /// [removeAvatar] is `true`, a `removeAvatar=true` field is added.
  Future<FormData> _buildFormData({
    required Map<String, dynamic> fields,
    String? avatarFilePath,
    bool removeAvatar = false,
  }) async {
    final map = <String, dynamic>{};

    // Add all non-null profile fields as string values
    for (final entry in fields.entries) {
      if (entry.value != null) {
        final value = entry.value;
        if (value is List) {
          // Encode lists as JSON strings (e.g. equipment)
          map[entry.key] = jsonEncode(value);
        } else if (value is DateTime) {
          map[entry.key] = value.toIso8601String();
        } else if (value is Sex) {
          map[entry.key] = value.name.toUpperCase();
        } else if (value is ExperienceLevel) {
          map[entry.key] = value.name.toUpperCase();
        } else {
          map[entry.key] = value.toString();
        }
      }
    }

    // Avatar file
    if (avatarFilePath != null) {
      map['avatar'] = await MultipartFile.fromFile(avatarFilePath);
    }

    // Remove avatar flag
    if (removeAvatar) {
      map['removeAvatar'] = 'true';
    }

    return FormData.fromMap(map);
  }

  /// Extracts non-null field values from a [CreateUserProfileRequest].
  Map<String, dynamic> _profileFieldsFromCreate(
    CreateUserProfileRequest request,
  ) {
    return {
      'daysAvailable': request.daysAvailable,
      'sessionDurationMinutes': request.sessionDurationMinutes,
      if (request.bio != null) 'bio': request.bio,
      if (request.heightCm != null) 'heightCm': request.heightCm,
      if (request.weightKg != null) 'weightKg': request.weightKg,
      if (request.unitPreference != null)
        'unitPreference': request.unitPreference,
      if (request.sex != null) 'sex': request.sex,
      if (request.dateOfBirth != null) 'dateOfBirth': request.dateOfBirth,
      if (request.equipment.isNotEmpty) 'equipment': request.equipment,
      if (request.injuryHistory != null) 'injuryHistory': request.injuryHistory,
      if (request.experienceLevel != null)
        'experienceLevel': request.experienceLevel,
    };
  }

  /// Extracts non-null field values from an [UpdateUserProfileRequest].
  Map<String, dynamic> _profileFieldsFromUpdate(
    UpdateUserProfileRequest request,
  ) {
    return {
      if (request.bio != null) 'bio': request.bio,
      if (request.heightCm != null) 'heightCm': request.heightCm,
      if (request.weightKg != null) 'weightKg': request.weightKg,
      if (request.unitPreference != null)
        'unitPreference': request.unitPreference,
      if (request.sex != null) 'sex': request.sex,
      if (request.dateOfBirth != null) 'dateOfBirth': request.dateOfBirth,
      if (request.equipment != null) 'equipment': request.equipment,
      if (request.injuryHistory != null) 'injuryHistory': request.injuryHistory,
      if (request.experienceLevel != null)
        'experienceLevel': request.experienceLevel,
      if (request.daysAvailable != null) 'daysAvailable': request.daysAvailable,
      if (request.sessionDurationMinutes != null)
        'sessionDurationMinutes': request.sessionDurationMinutes,
    };
  }

  // ─── Local cache helpers (Hive) ────────────────────────────────────

  /// Persists the profile as a JSON string in Hive.
  void _cacheProfile(UserProfileModel profile) {
    try {
      final jsonString = jsonEncode(profile.toJson());
      _prefs.cacheRaw(_cachedProfileKey, jsonString);
      AppLogger.debug('Profile cached locally', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to cache profile', tag: _tag, error: e);
    }
  }

  /// Reads the locally-cached profile from Hive.
  UserProfileModel? _readCachedProfile() {
    try {
      final jsonString = _prefs.readRaw(_cachedProfileKey);
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfileModel.fromJson(json);
    } catch (e) {
      AppLogger.error('Failed to read cached profile', tag: _tag, error: e);
      return null;
    }
  }

  /// Returns the cached profile as a [Success], or the original [error]
  /// as a [Failure] when no cache exists.
  Result<UserProfileModel?, AppError> _getCachedProfileOrError(AppError error) {
    final cached = _readCachedProfile();
    if (cached != null) {
      AppLogger.info('Returning cached profile (offline)', tag: _tag);
      return Success(cached);
    }
    AppLogger.error('No cached profile available', tag: _tag, error: error);
    return Failure(error);
  }

  /// Removes the cached profile (e.g. on logout or when the server
  /// confirms the user has no profile).
  void _clearCachedProfile() {
    try {
      _prefs.deleteRaw(_cachedProfileKey);
    } catch (e) {
      AppLogger.error('Failed to clear cached profile', tag: _tag, error: e);
    }
  }

  /// Clears the locally cached fitness profile.
  ///
  /// Should be called on logout to remove stale data.
  void clearCache() => _clearCachedProfile();
}
