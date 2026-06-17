import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_settings_repository.dart';
import '../../data/models/coach_settings_model.dart';

part 'coach_settings_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for coach settings.
sealed class CoachSettingsState {
  const CoachSettingsState();
}

class CoachSettingsInitial extends CoachSettingsState {
  const CoachSettingsInitial();
}

class CoachSettingsLoading extends CoachSettingsState {
  const CoachSettingsLoading();
}

class CoachSettingsLoaded extends CoachSettingsState {
  const CoachSettingsLoaded({
    required this.settings,
    this.isUpdating = false,
  });

  final CoachSettingsModel settings;
  final bool isUpdating;

  CoachSettingsLoaded copyWith({
    CoachSettingsModel? settings,
    bool? isUpdating,
  }) {
    return CoachSettingsLoaded(
      settings: settings ?? this.settings,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class CoachSettingsError extends CoachSettingsState {
  const CoachSettingsError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Coach Settings Notifier (ML-5)
// ──────────────────────────────────────────────────────────

/// Manages the authenticated coach's settings.
///
/// Handles:
/// - `maxClients` — hard cap on active client count
/// - `acceptingClients` — manual on/off for intake
/// - `isDiscoverable` — public search visibility
@riverpod
class CoachSettingsNotifier extends _$CoachSettingsNotifier {
  @override
  CoachSettingsState build() => const CoachSettingsInitial();

  CoachSettingsRepository get _repo =>
      ref.read(coachSettingsRepositoryProvider);

  /// Load the coach's current settings.
  Future<void> load() async {
    state = const CoachSettingsLoading();

    final result = await _repo.getSettings();

    result.when(
      success: (settings) {
        state = CoachSettingsLoaded(settings: settings);
      },
      failure: (error) {
        AppLogger.error(
          'Load coach settings failed: ${error.message}',
          tag: 'CoachSettingsNotifier',
        );
        state = CoachSettingsError(error);
      },
    );
  }

  /// Update one or more settings fields.
  ///
  /// Only non-null fields in [request] are sent. On success the state
  /// is updated with the server's response (authoritative).
  /// Returns `null` on success, or the [AppError] on failure.
  Future<AppError?> updateSettings(UpdateCoachSettingsRequest request) async {
    final current = state;
    if (current is CoachSettingsLoaded) {
      state = current.copyWith(isUpdating: true);
    }

    final result = await _repo.updateSettings(request);

    return result.when(
      success: (settings) {
        state = CoachSettingsLoaded(settings: settings);
        return null;
      },
      failure: (error) {
        AppLogger.error(
          'Update coach settings failed: ${error.message}',
          tag: 'CoachSettingsNotifier',
        );
        if (current is CoachSettingsLoaded) {
          state = current.copyWith(isUpdating: false);
        }
        return error;
      },
    );
  }

  /// Toggle the `acceptingClients` flag.
  Future<AppError?> toggleAcceptingClients() async {
    final current = state;
    if (current is! CoachSettingsLoaded) {
      return const UnknownError(message: 'Settings not loaded');
    }

    return updateSettings(
      UpdateCoachSettingsRequest(
        acceptingClients: !current.settings.acceptingClients,
      ),
    );
  }

  /// Toggle the `isDiscoverable` flag.
  Future<AppError?> toggleDiscoverability() async {
    final current = state;
    if (current is! CoachSettingsLoaded) {
      return const UnknownError(message: 'Settings not loaded');
    }

    return updateSettings(
      UpdateCoachSettingsRequest(
        isDiscoverable: !current.settings.isDiscoverable,
      ),
    );
  }

  /// Set the max client capacity.
  Future<AppError?> setMaxClients(int maxClients) async {
    return updateSettings(UpdateCoachSettingsRequest(maxClients: maxClients));
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Whether coach settings are currently loading.
@riverpod
bool coachSettingsLoading(Ref ref) {
  final state = ref.watch(coachSettingsProvider);
  return state is CoachSettingsLoading;
}

/// Whether a settings update is in progress.
@riverpod
bool coachSettingsUpdating(Ref ref) {
  final state = ref.watch(coachSettingsProvider);
  return switch (state) {
    CoachSettingsLoaded(:final isUpdating) => isUpdating,
    _ => false,
  };
}

/// The loaded coach settings, or null if not yet loaded.
@riverpod
CoachSettingsModel? currentCoachSettings(Ref ref) {
  final state = ref.watch(coachSettingsProvider);
  return switch (state) {
    CoachSettingsLoaded(:final settings) => settings,
    _ => null,
  };
}

/// Whether the coach is currently accepting new clients.
@riverpod
bool isAcceptingClients(Ref ref) {
  final settings = ref.watch(currentCoachSettingsProvider);
  return settings?.acceptingClients ?? true;
}

/// Whether the coach is visible in public discovery.
@riverpod
bool isCoachDiscoverable(Ref ref) {
  final settings = ref.watch(currentCoachSettingsProvider);
  return settings?.isDiscoverable ?? true;
}

/// The coach's maximum client capacity.
@riverpod
int coachMaxClients(Ref ref) {
  final settings = ref.watch(currentCoachSettingsProvider);
  return settings?.maxClients ?? 40;
}
