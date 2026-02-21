import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_program_repository.dart';
import '../../data/models/coach_client_model.dart';
import '../../data/models/program_model.dart';

part 'coach_client_list_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for the coach's full client list with assignment data.
sealed class CoachClientListState {
  const CoachClientListState();
}

class CoachClientListInitial extends CoachClientListState {
  const CoachClientListInitial();
}

class CoachClientListLoading extends CoachClientListState {
  const CoachClientListLoading();
}

class CoachClientListLoaded extends CoachClientListState {
  const CoachClientListLoaded({
    required this.clients,
    required this.pagination,
  });

  final List<CoachClientModel> clients;
  final PaginationMeta pagination;
}

class CoachClientListError extends CoachClientListState {
  const CoachClientListError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Coach Client List Notifier (ML-4)
// ──────────────────────────────────────────────────────────

/// Manages the coach's full client list with assignment data.
///
/// Richer than [CoachRosterNotifier] — includes `assignedPrograms`,
/// `isAssigned`, and `subscriptionExpiresAt` (ML-4) per client.
///
/// Supports filtering by assignment status.
@riverpod
class CoachClientListNotifier extends _$CoachClientListNotifier {
  @override
  CoachClientListState build() => const CoachClientListInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load client list (replaces current list).
  Future<void> loadClients({
    int limit = 50,
    int offset = 0,
    bool? isAssigned,
  }) async {
    state = const CoachClientListLoading();

    final result = await _repo.getClients(
      limit: limit,
      offset: offset,
      isAssigned: isAssigned,
    );

    result.when(
      success: (data) {
        state = CoachClientListLoaded(
          clients: data.clients,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load client list failed: ${error.message}',
          tag: 'CoachClientListNotifier',
        );
        state = CoachClientListError(error);
      },
    );
  }

  /// Load next page (appends to current list).
  Future<void> loadMore({bool? isAssigned}) async {
    final current = state;
    if (current is! CoachClientListLoaded || !current.pagination.hasMore) {
      return;
    }

    final nextOffset = current.pagination.offset + current.pagination.limit;

    final result = await _repo.getClients(
      limit: current.pagination.limit,
      offset: nextOffset,
      isAssigned: isAssigned,
    );

    result.when(
      success: (data) {
        state = CoachClientListLoaded(
          clients: [...current.clients, ...data.clients],
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load more clients failed: ${error.message}',
          tag: 'CoachClientListNotifier',
        );
        // Keep existing data on pagination failure
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Whether the client list is currently loading.
@riverpod
bool coachClientListLoading(Ref ref) {
  final state = ref.watch(coachClientListProvider);
  return state is CoachClientListLoading;
}

/// The list of clients, or empty if not loaded.
@riverpod
List<CoachClientModel> coachClientsList(Ref ref) {
  final state = ref.watch(coachClientListProvider);
  return switch (state) {
    CoachClientListLoaded(:final clients) => clients,
    _ => [],
  };
}

/// Clients with no assigned programs.
@riverpod
List<CoachClientModel> unassignedClients(Ref ref) {
  final clients = ref.watch(coachClientsListProvider);
  return clients.where((c) => !c.isAssigned).toList();
}

/// Clients whose subscription is expiring within 7 days.
@riverpod
List<CoachClientModel> expiringClientsFull(Ref ref) {
  final clients = ref.watch(coachClientsListProvider);
  return clients.where((c) => c.isExpiringSoon).toList();
}
