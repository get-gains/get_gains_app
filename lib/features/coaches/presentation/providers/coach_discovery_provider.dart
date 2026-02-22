import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_repository.dart';
import '../../data/models/coach_model.dart';

part 'coach_discovery_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for coach discovery list.
sealed class CoachDiscoveryState {
  const CoachDiscoveryState();
}

class CoachDiscoveryInitial extends CoachDiscoveryState {
  const CoachDiscoveryInitial();
}

class CoachDiscoveryLoading extends CoachDiscoveryState {
  const CoachDiscoveryLoading();
}

class CoachDiscoveryLoaded extends CoachDiscoveryState {
  const CoachDiscoveryLoaded({required this.coaches, required this.pagination});

  final List<CoachSummaryModel> coaches;
  final CoachPaginationMeta pagination;
}

class CoachDiscoveryError extends CoachDiscoveryState {
  const CoachDiscoveryError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Coach Discovery Notifier
// ──────────────────────────────────────────────────────────

/// Manages coach discovery with search, filtering, and pagination.
///
/// Clients use this to browse and search for public coaches.
@riverpod
class CoachDiscoveryNotifier extends _$CoachDiscoveryNotifier {
  @override
  CoachDiscoveryState build() => const CoachDiscoveryInitial();

  CoachRepository get _repo => ref.read(coachRepositoryProvider);

  /// Load coaches (replaces current list).
  Future<void> loadCoaches({
    String? search,
    String? specialty,
    int limit = 50,
    int offset = 0,
  }) async {
    state = const CoachDiscoveryLoading();

    final result = await _repo.discoverCoaches(
      search: search,
      specialty: specialty,
      limit: limit,
      offset: offset,
    );

    result.when(
      success: (response) {
        state = CoachDiscoveryLoaded(
          coaches: response.coaches,
          pagination: response.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load coaches failed: ${error.message}',
          tag: 'CoachDiscoveryNotifier',
        );
        state = CoachDiscoveryError(error);
      },
    );
  }

  /// Load next page (appends to current list).
  Future<void> loadMore({String? search, String? specialty}) async {
    final current = state;
    if (current is! CoachDiscoveryLoaded || !current.pagination.hasMore) return;

    final nextOffset = current.pagination.offset + current.pagination.limit;

    final result = await _repo.discoverCoaches(
      search: search,
      specialty: specialty,
      limit: current.pagination.limit,
      offset: nextOffset,
    );

    result.when(
      success: (response) {
        state = CoachDiscoveryLoaded(
          coaches: [...current.coaches, ...response.coaches],
          pagination: response.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load more coaches failed: ${error.message}',
          tag: 'CoachDiscoveryNotifier',
        );
        // Keep existing data on pagination failure
      },
    );
  }

  /// Subscribe to a coach and add them to the loaded list with `subscribedAt`.
  ///
  /// Server-side guards handle:
  /// - ML-2: 403 if no platform subscription
  /// - ML-5: 409 if coach not accepting / at capacity
  Future<bool> subscribeToCoach(String coachId) async {
    final result = await _repo.subscribeToCoach(coachId);

    return result.when(
      success: (subscribedCoach) {
        AppLogger.info(
          'Subscribed to coach: ${subscribedCoach.name}',
          tag: 'CoachDiscoveryNotifier',
        );
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Subscribe to coach failed: ${error.message}',
          tag: 'CoachDiscoveryNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Whether the discovery list is currently loading.
@riverpod
bool coachDiscoveryLoading(Ref ref) {
  final state = ref.watch(coachDiscoveryProvider);
  return state is CoachDiscoveryLoading;
}

/// The list of discovered coaches, or empty if not loaded.
@riverpod
List<CoachSummaryModel> discoveredCoachesList(Ref ref) {
  final state = ref.watch(coachDiscoveryProvider);
  return switch (state) {
    CoachDiscoveryLoaded(:final coaches) => coaches,
    _ => [],
  };
}

/// Pagination metadata for the discovery list.
@riverpod
CoachPaginationMeta? coachDiscoveryPagination(Ref ref) {
  final state = ref.watch(coachDiscoveryProvider);
  return switch (state) {
    CoachDiscoveryLoaded(:final pagination) => pagination,
    _ => null,
  };
}

/// The current error, if any.
@riverpod
AppError? coachDiscoveryError(Ref ref) {
  final state = ref.watch(coachDiscoveryProvider);
  return switch (state) {
    CoachDiscoveryError(:final error) => error,
    _ => null,
  };
}
