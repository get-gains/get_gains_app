import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_program_repository.dart';
import '../../data/models/coach_client_model.dart';
import '../../data/models/program_model.dart';

part 'coach_roster_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for the coach's class roster.
sealed class CoachRosterState {
  const CoachRosterState();
}

class CoachRosterInitial extends CoachRosterState {
  const CoachRosterInitial();
}

class CoachRosterLoading extends CoachRosterState {
  const CoachRosterLoading();
}

class CoachRosterLoaded extends CoachRosterState {
  const CoachRosterLoaded({required this.clients, required this.pagination});

  final List<RosterClientModel> clients;
  final PaginationMeta pagination;
}

class CoachRosterError extends CoachRosterState {
  const CoachRosterError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Coach Roster Notifier (ML-4)
// ──────────────────────────────────────────────────────────

/// Manages the coach's class roster — all subscribed clients.
///
/// Each client includes `subscriptionExpiresAt` (ML-4) so coaches can
/// see when a client's platform subscription expires. No status, plan name,
/// tier level, or price data is exposed — only the expiry date.
@riverpod
class CoachRosterNotifier extends _$CoachRosterNotifier {
  @override
  CoachRosterState build() => const CoachRosterInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load the class roster (replaces current list).
  Future<void> loadRoster({int limit = 50, int offset = 0}) async {
    state = const CoachRosterLoading();

    final result = await _repo.getClassRoster(limit: limit, offset: offset);

    result.when(
      success: (data) {
        state = CoachRosterLoaded(
          clients: data.clients,
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load roster failed: ${error.message}',
          tag: 'CoachRosterNotifier',
        );
        state = CoachRosterError(error);
      },
    );
  }

  /// Load next page (appends to current list).
  Future<void> loadMore() async {
    final current = state;
    if (current is! CoachRosterLoaded || !current.pagination.hasMore) return;

    final nextOffset = current.pagination.offset + current.pagination.limit;

    final result = await _repo.getClassRoster(
      limit: current.pagination.limit,
      offset: nextOffset,
    );

    result.when(
      success: (data) {
        state = CoachRosterLoaded(
          clients: [...current.clients, ...data.clients],
          pagination: data.pagination,
        );
      },
      failure: (error) {
        AppLogger.error(
          'Load more roster failed: ${error.message}',
          tag: 'CoachRosterNotifier',
        );
        // Keep existing data on pagination failure
      },
    );
  }

  /// Remove a client from the class and update the list.
  Future<bool> removeClient(String clientId) async {
    final result = await _repo.removeClientFromClass(clientId);

    return result.when(
      success: (_) {
        final current = state;
        if (current is CoachRosterLoaded) {
          state = CoachRosterLoaded(
            clients: current.clients.where((c) => c.id != clientId).toList(),
            pagination: current.pagination.copyWith(
              total: (current.pagination.total - 1).clamp(0, 999999),
            ),
          );
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Remove client failed: ${error.message}',
          tag: 'CoachRosterNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Whether the roster is currently loading.
@riverpod
bool coachRosterLoading(Ref ref) {
  final state = ref.watch(coachRosterProvider);
  return state is CoachRosterLoading;
}

/// The list of roster clients, or empty if not loaded.
@riverpod
List<RosterClientModel> rosterClientsList(Ref ref) {
  final state = ref.watch(coachRosterProvider);
  return switch (state) {
    CoachRosterLoaded(:final clients) => clients,
    _ => [],
  };
}

/// Total number of clients on the roster.
@riverpod
int rosterClientCount(Ref ref) {
  final state = ref.watch(coachRosterProvider);
  return switch (state) {
    CoachRosterLoaded(:final pagination) => pagination.total,
    _ => 0,
  };
}

/// Clients whose subscription is expiring within 7 days.
@riverpod
List<RosterClientModel> expiringClients(Ref ref) {
  final clients = ref.watch(rosterClientsListProvider);
  return clients.where((c) => c.isExpiringSoon).toList();
}
