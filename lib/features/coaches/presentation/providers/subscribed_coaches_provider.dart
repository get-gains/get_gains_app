import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_repository.dart';
import '../../data/models/coach_model.dart';

part 'subscribed_coaches_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for the user's subscribed coaches list.
sealed class SubscribedCoachesState {
  const SubscribedCoachesState();
}

class SubscribedCoachesInitial extends SubscribedCoachesState {
  const SubscribedCoachesInitial();
}

class SubscribedCoachesLoading extends SubscribedCoachesState {
  const SubscribedCoachesLoading();
}

class SubscribedCoachesLoaded extends SubscribedCoachesState {
  const SubscribedCoachesLoaded({
    required this.coaches,
    required this.pagination,
  });

  final List<CoachSummaryModel> coaches;
  final CoachPaginationMeta pagination;
}

class SubscribedCoachesError extends SubscribedCoachesState {
  const SubscribedCoachesError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Subscribed Coaches Notifier
// ──────────────────────────────────────────────────────────

/// Manages the authenticated user's list of subscribed coaches.
///
/// Each coach in the list includes a `subscribedAt` timestamp.
@riverpod
class SubscribedCoachesNotifier extends _$SubscribedCoachesNotifier {
  @override
  SubscribedCoachesState build() => const SubscribedCoachesInitial();

  CoachRepository get _repo => ref.read(coachRepositoryProvider);

  /// Load subscribed coaches (replaces current list).
  Future<void> loadCoaches({int limit = 50, int offset = 0}) async {
    state = const SubscribedCoachesLoading();

    final result = await _repo.getSubscribedCoaches(
      limit: limit,
      offset: offset,
    );

    result.when(
      success: (response) {
        state = SubscribedCoachesLoaded(
          coaches: response.coaches,
          pagination: response.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load subscribed coaches failed: ${error.message}',
          tag: 'SubscribedCoachesNotifier',
        );
        state = SubscribedCoachesError(error);
      },
    );
  }

  /// Load next page (appends to current list).
  Future<void> loadMore() async {
    final current = state;
    if (current is! SubscribedCoachesLoaded || !current.pagination.hasMore) {
      return;
    }

    final nextOffset = current.pagination.offset + current.pagination.limit;

    final result = await _repo.getSubscribedCoaches(
      limit: current.pagination.limit,
      offset: nextOffset,
    );

    result.when(
      success: (response) {
        state = SubscribedCoachesLoaded(
          coaches: [...current.coaches, ...response.coaches],
          pagination: response.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load more subscribed coaches failed: ${error.message}',
          tag: 'SubscribedCoachesNotifier',
        );
        // Keep existing data on pagination failure
      },
    );
  }

  /// Subscribe to a coach and refresh the list.
  ///
  /// Server-side guards handle:
  /// - ML-2: 403 if no platform subscription
  /// - ML-5: 409 if coach not accepting / at capacity
  Future<bool> subscribeToCoach(String coachId) async {
    final result = await _repo.subscribeToCoach(coachId);

    return result.when(
      success: (subscribedCoach) {
        // Optimistically prepend if the list is loaded; otherwise
        // trigger a full load so isSubscribedToCoach reflects the new state.
        final current = state;
        if (current is SubscribedCoachesLoaded) {
          state = SubscribedCoachesLoaded(
            coaches: [subscribedCoach, ...current.coaches],
            pagination: current.pagination.copyWith(
              total: current.pagination.total + 1,
            ),
          );
        } else {
          // State is Initial/Loading/Error — do a full load so the derived
          // providers pick up the new subscription immediately.
          loadCoaches();
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Subscribe failed: ${error.message}',
          tag: 'SubscribedCoachesNotifier',
        );
        return false;
      },
    );
  }

  /// Unsubscribe from a coach and remove them from the list.
  Future<bool> unsubscribeFromCoach(String coachId) async {
    final result = await _repo.unsubscribeFromCoach(coachId);

    return result.when(
      success: (_) {
        final current = state;
        if (current is SubscribedCoachesLoaded) {
          state = SubscribedCoachesLoaded(
            coaches: current.coaches.where((c) => c.id != coachId).toList(),
            pagination: current.pagination.copyWith(
              total: (current.pagination.total - 1).clamp(0, 999999),
            ),
          );
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Unsubscribe failed: ${error.message}',
          tag: 'SubscribedCoachesNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Whether the subscribed coaches list is currently loading.
@riverpod
bool subscribedCoachesLoading(Ref ref) {
  final state = ref.watch(subscribedCoachesProvider);
  return state is SubscribedCoachesLoading;
}

/// The list of subscribed coaches, or empty if not loaded.
@riverpod
List<CoachSummaryModel> subscribedCoachesList(Ref ref) {
  final state = ref.watch(subscribedCoachesProvider);
  return switch (state) {
    SubscribedCoachesLoaded(:final coaches) => coaches,
    _ => [],
  };
}

/// Whether the user is subscribed to a specific coach.
@riverpod
bool isSubscribedToCoach(Ref ref, String coachId) {
  final coaches = ref.watch(subscribedCoachesListProvider);
  return coaches.any((c) => c.id == coachId);
}

/// Number of coaches the user is subscribed to.
@riverpod
int subscribedCoachCount(Ref ref) {
  final state = ref.watch(subscribedCoachesProvider);
  return switch (state) {
    SubscribedCoachesLoaded(:final pagination) => pagination.total,
    _ => 0,
  };
}
