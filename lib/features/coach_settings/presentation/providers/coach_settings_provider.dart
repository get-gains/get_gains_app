import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_settings_repository.dart';
import '../../data/models/coach_settings_model.dart';

part 'coach_settings_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Identifies which coach setting field is currently being saved.
enum CoachSettingsUpdateField {
  acceptingClients,
  isDiscoverable,
  maxClients,
}

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
    this.updatingField,
  });

  final CoachSettingsModel settings;
  final CoachSettingsUpdateField? updatingField;

  CoachSettingsLoaded copyWith({
    CoachSettingsModel? settings,
    CoachSettingsUpdateField? updatingField,
    bool clearUpdatingField = false,
  }) {
    return CoachSettingsLoaded(
      settings: settings ?? this.settings,
      updatingField: clearUpdatingField
          ? null
          : (updatingField ?? this.updatingField),
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
  Future<AppError?> updateSettings(
    UpdateCoachSettingsRequest request, {
    required CoachSettingsUpdateField field,
  }) async {
    final current = state;
    if (current is CoachSettingsLoaded) {
      state = current.copyWith(updatingField: field);
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
          state = current.copyWith(clearUpdatingField: true);
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
      field: CoachSettingsUpdateField.acceptingClients,
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
      field: CoachSettingsUpdateField.isDiscoverable,
    );
  }

  /// Set the max client capacity.
  Future<AppError?> setMaxClients(int maxClients) async {
    return updateSettings(
      UpdateCoachSettingsRequest(maxClients: maxClients),
      field: CoachSettingsUpdateField.maxClients,
    );
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
    CoachSettingsLoaded(:final updatingField) => updatingField != null,
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
