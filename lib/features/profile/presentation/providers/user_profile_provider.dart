import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/profile_request_models.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/user_profile_repository.dart';

part 'user_profile_provider.g.dart';

/// Async notifier that manages the authenticated user's fitness profile.
///
/// ## States
/// - **loading** → initial fetch in progress
/// - **data(null)** → user has no profile (onboarding required)
/// - **data(UserProfileModel)** → profile exists
/// - **error** → network/server failure
///
/// ## Usage
/// ```dart
/// // Watch for profile state (screens, onboarding guards)
/// final profileAsync = ref.watch(userProfileNotifierProvider);
///
/// // Check if onboarding is needed
/// final needsOnboarding = ref.watch(needsOnboardingProvider);
///
/// // Create profile during onboarding
/// await ref.read(userProfileNotifierProvider.notifier).createProfile(request);
///
/// // Update profile from edit screen
/// await ref.read(userProfileNotifierProvider.notifier).updateProfile(request);
/// ```
@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
  static const _tag = 'UserProfileNotifier';

  @override
  Future<UserProfileModel?> build() async {
    final repo = ref.watch(userProfileRepositoryProvider);
    final result = await repo.getProfile();

    return result.when(
      success: (profile) {
        AppLogger.debug(
          profile != null ? 'Profile loaded' : 'No profile – onboarding needed',
          tag: _tag,
        );
        return profile;
      },
      failure: (error) {
        AppLogger.error('Failed to load profile', tag: _tag, error: error);
        throw Exception(error.message);
      },
    );
  }

  /// Creates a new profile during onboarding and updates the local state.
  ///
  /// On success the notifier state transitions from `data(null)` →
  /// `data(UserProfileModel)`, which downstream consumers (e.g. the
  /// onboarding guard) can react to.
  Future<UserProfileModel> createProfile(
    CreateUserProfileRequest request,
  ) async {
    final repo = ref.read(userProfileRepositoryProvider);
    final result = await repo.createProfile(request);

    return result.when(
      success: (profile) {
        state = AsyncData(profile);
        AppLogger.info('Profile created – onboarding complete', tag: _tag);
        return profile;
      },
      failure: (error) {
        AppLogger.error('Create profile failed', tag: _tag, error: error);
        throw Exception(error.message);
      },
    );
  }

  /// Partially updates the profile and replaces the local state.
  Future<UserProfileModel> updateProfile(
    UpdateUserProfileRequest request,
  ) async {
    final repo = ref.read(userProfileRepositoryProvider);
    final result = await repo.updateProfile(request);

    return result.when(
      success: (profile) {
        state = AsyncData(profile);
        AppLogger.info('Profile updated', tag: _tag);
        return profile;
      },
      failure: (error) {
        AppLogger.error('Update profile failed', tag: _tag, error: error);
        throw Exception(error.message);
      },
    );
  }

  /// Re-fetches the profile from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }

  /// Clears the cached profile (e.g. on logout).
  void clear() {
    state = const AsyncData(null);
  }
}

// ─── Derived convenience providers ──────────────────────────────────

/// Whether the authenticated user still needs to complete onboarding.
///
/// Returns `true` when the profile has been fetched successfully and is
/// `null`.  Returns `false` while loading or on error (to avoid false
/// positives that would flash the onboarding screen).
///
/// Usage in the home screen or a route guard:
/// ```dart
/// final needsOnboarding = ref.watch(needsOnboardingProvider);
/// if (needsOnboarding) {
///   // Show onboarding dialog / redirect
/// }
/// ```
@riverpod
bool needsOnboarding(Ref ref) {
  final profileAsync = ref.watch(userProfileProvider);

  return profileAsync.when(
    data: (profile) => profile == null,
    loading: () => false,
    error: (e, st) => false,
  );
}

/// Whether the profile has been loaded (regardless of null or populated).
///
/// Useful for gating UI that depends on knowing the profile status.
@riverpod
bool isProfileLoaded(Ref ref) {
  return ref.watch(userProfileProvider).hasValue;
}
