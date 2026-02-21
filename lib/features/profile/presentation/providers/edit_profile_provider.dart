import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/profile_request_models.dart';
import '../../data/models/user_profile_model.dart';
import 'user_profile_provider.dart';

part 'edit_profile_provider.g.dart';

/// Tracks the current state of the edit-profile form submission.
enum EditProfileStatus {
  /// Form is idle / ready for user input.
  idle,

  /// The profile is being saved (multipart upload in progress).
  saving,

  /// Save completed successfully.
  success,

  /// Save failed.
  error,
}

/// In-memory snapshot of the form fields on the edit screen.
///
/// This is intentionally **not** a Freezed model because it represents
/// transient UI state (dirty tracking, avatar preview, etc.) that never
/// leaves the presentation layer.
@immutable
class EditProfileFormState {
  const EditProfileFormState({
    this.bio,
    this.heightCm,
    this.weightKg,
    this.unitPreference,
    this.sex,
    this.dateOfBirth,
    this.equipment = const [],
    this.injuryHistory,
    this.experienceLevel,
    this.daysAvailable = 3,
    this.sessionDurationMinutes = 60,
    this.avatarFilePath,
    this.removeAvatar = false,
    this.existingAvatarUrl,
    this.status = EditProfileStatus.idle,
    this.errorMessage,
  });

  final String? bio;
  final double? heightCm;
  final double? weightKg;
  final String? unitPreference;
  final Sex? sex;
  final DateTime? dateOfBirth;
  final List<String> equipment;
  final String? injuryHistory;
  final ExperienceLevel? experienceLevel;
  final int daysAvailable;
  final int sessionDurationMinutes;

  /// Local path to a newly picked avatar (not yet uploaded).
  final String? avatarFilePath;

  /// Whether the user wants to remove the existing avatar.
  final bool removeAvatar;

  /// The current avatar URL from the server (for display).
  final String? existingAvatarUrl;

  /// Submission status.
  final EditProfileStatus status;

  /// Error message from the last failed save attempt.
  final String? errorMessage;

  /// Whether the form is currently saving.
  bool get isSaving => status == EditProfileStatus.saving;

  EditProfileFormState copyWith({
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
    String? avatarFilePath,
    bool? removeAvatar,
    String? existingAvatarUrl,
    EditProfileStatus? status,
    String? errorMessage,
    // Allow explicitly clearing nullable fields
    bool clearBio = false,
    bool clearHeightCm = false,
    bool clearWeightKg = false,
    bool clearUnitPreference = false,
    bool clearSex = false,
    bool clearDateOfBirth = false,
    bool clearInjuryHistory = false,
    bool clearExperienceLevel = false,
    bool clearAvatarFilePath = false,
    bool clearExistingAvatarUrl = false,
    bool clearErrorMessage = false,
  }) {
    return EditProfileFormState(
      bio: clearBio ? null : (bio ?? this.bio),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
      unitPreference: clearUnitPreference
          ? null
          : (unitPreference ?? this.unitPreference),
      sex: clearSex ? null : (sex ?? this.sex),
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      equipment: equipment ?? this.equipment,
      injuryHistory: clearInjuryHistory
          ? null
          : (injuryHistory ?? this.injuryHistory),
      experienceLevel: clearExperienceLevel
          ? null
          : (experienceLevel ?? this.experienceLevel),
      daysAvailable: daysAvailable ?? this.daysAvailable,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      avatarFilePath: clearAvatarFilePath
          ? null
          : (avatarFilePath ?? this.avatarFilePath),
      removeAvatar: removeAvatar ?? this.removeAvatar,
      existingAvatarUrl: clearExistingAvatarUrl
          ? null
          : (existingAvatarUrl ?? this.existingAvatarUrl),
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  /// Builds the [UpdateUserProfileRequest] from the current form state.
  UpdateUserProfileRequest toUpdateRequest() {
    return UpdateUserProfileRequest(
      bio: bio,
      heightCm: heightCm,
      weightKg: weightKg,
      unitPreference: unitPreference,
      sex: sex,
      dateOfBirth: dateOfBirth,
      equipment: equipment,
      injuryHistory: injuryHistory,
      experienceLevel: experienceLevel,
      daysAvailable: daysAvailable,
      sessionDurationMinutes: sessionDurationMinutes,
      avatarFilePath: avatarFilePath,
      removeAvatar: removeAvatar,
    );
  }
}

/// Notifier that manages edit-profile form state and submission.
///
/// Initialised from the current [UserProfileModel] when the edit screen
/// opens. Exposes field-level setters so individual form fields can call
/// `ref.read(editProfileProvider.notifier).updateBio('...')`.
///
/// Submission calls [UserProfileNotifier.updateProfile] which handles
/// multipart upload and local cache invalidation.
@riverpod
class EditProfileNotifier extends _$EditProfileNotifier {
  static const _tag = 'EditProfileNotifier';

  @override
  EditProfileFormState build() {
    // Pre-populate from the current fitness profile (if any)
    final profileAsync = ref.read(userProfileProvider);
    final profile = profileAsync.value;

    if (profile != null) {
      return EditProfileFormState(
        bio: profile.bio,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        unitPreference: profile.unitPreference,
        sex: profile.sex,
        dateOfBirth: profile.dateOfBirth,
        equipment: profile.equipment,
        injuryHistory: profile.injuryHistory,
        experienceLevel: profile.experienceLevel,
        daysAvailable: profile.daysAvailable,
        sessionDurationMinutes: profile.sessionDurationMinutes,
        existingAvatarUrl: profile.avatarUrl,
      );
    }

    return const EditProfileFormState();
  }

  // ─── Field setters ──────────────────────────────────────────────────

  void updateBio(String? value) =>
      state = state.copyWith(bio: value, clearBio: value == null);

  void updateHeightCm(double? value) =>
      state = state.copyWith(heightCm: value, clearHeightCm: value == null);

  void updateWeightKg(double? value) =>
      state = state.copyWith(weightKg: value, clearWeightKg: value == null);

  void updateUnitPreference(String? value) => state = state.copyWith(
    unitPreference: value,
    clearUnitPreference: value == null,
  );

  void updateSex(Sex? value) =>
      state = state.copyWith(sex: value, clearSex: value == null);

  void updateDateOfBirth(DateTime? value) => state = state.copyWith(
    dateOfBirth: value,
    clearDateOfBirth: value == null,
  );

  void updateEquipment(List<String> value) =>
      state = state.copyWith(equipment: value);

  void updateInjuryHistory(String? value) => state = state.copyWith(
    injuryHistory: value,
    clearInjuryHistory: value == null,
  );

  void updateExperienceLevel(ExperienceLevel? value) => state = state.copyWith(
    experienceLevel: value,
    clearExperienceLevel: value == null,
  );

  void updateDaysAvailable(int value) =>
      state = state.copyWith(daysAvailable: value);

  void updateSessionDuration(int value) =>
      state = state.copyWith(sessionDurationMinutes: value);

  /// Sets a newly picked avatar file path and clears `removeAvatar`.
  void pickAvatar(String filePath) {
    state = state.copyWith(
      avatarFilePath: filePath,
      removeAvatar: false,
      clearAvatarFilePath: false,
    );
  }

  /// Marks the avatar for removal (clear existing + any picked file).
  void removeCurrentAvatar() {
    state = state.copyWith(
      removeAvatar: true,
      clearAvatarFilePath: true,
      clearExistingAvatarUrl: true,
    );
  }

  // ─── Save ───────────────────────────────────────────────────────────

  /// Submits the form via [UserProfileNotifier.updateProfile].
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> save() async {
    if (state.isSaving) return false;

    state = state.copyWith(
      status: EditProfileStatus.saving,
      clearErrorMessage: true,
    );

    try {
      final request = state.toUpdateRequest();
      await ref.read(userProfileProvider.notifier).updateProfile(request);

      state = state.copyWith(status: EditProfileStatus.success);
      AppLogger.info('Profile saved from edit screen', tag: _tag);
      return true;
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'An unexpected error occurred';

      state = state.copyWith(
        status: EditProfileStatus.error,
        errorMessage: message,
      );
      AppLogger.error('Profile save failed', tag: _tag, error: e);
      return false;
    }
  }
}
