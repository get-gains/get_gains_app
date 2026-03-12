import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/leaderboard_repository.dart';
import '../../data/models/leaderboard_entry_model.dart';

part 'leaderboard_provider.g.dart';

/// Leaderboard UI State
sealed class LeaderboardState {
  const LeaderboardState();
}

/// Initial state — not yet loaded
class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

/// Loading leaderboard data
class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

/// Leaderboard loaded
class LeaderboardLoaded extends LeaderboardState {
  const LeaderboardLoaded({
    required this.coaches,
    required this.selectedCoachId,
    required this.entries,
    required this.coachName,
    this.currentUserRank,
    required this.totalClients,
    required this.lastUpdated,
    this.isRefreshing = false,
  });

  final List<LeaderboardCoach> coaches;
  final String? selectedCoachId;
  final List<LeaderboardEntryModel> entries;
  final String coachName;
  final int? currentUserRank;
  final int totalClients;
  final DateTime lastUpdated;
  final bool isRefreshing;

  /// Whether the user has no coach subscriptions
  bool get hasNoSubscriptions => coaches.isEmpty;

  /// Get selected coach info
  LeaderboardCoach? get selectedCoach {
    if (selectedCoachId == null) return null;
    return coaches.where((c) => c.coachId == selectedCoachId).firstOrNull;
  }

  /// Formatted "Last updated" timestamp
  String get lastUpdatedFormatted {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  LeaderboardLoaded copyWith({
    List<LeaderboardCoach>? coaches,
    String? Function()? selectedCoachId,
    List<LeaderboardEntryModel>? entries,
    String? coachName,
    int? Function()? currentUserRank,
    int? totalClients,
    DateTime? lastUpdated,
    bool? isRefreshing,
  }) {
    return LeaderboardLoaded(
      coaches: coaches ?? this.coaches,
      selectedCoachId: selectedCoachId != null
          ? selectedCoachId()
          : this.selectedCoachId,
      entries: entries ?? this.entries,
      coachName: coachName ?? this.coachName,
      currentUserRank: currentUserRank != null
          ? currentUserRank()
          : this.currentUserRank,
      totalClients: totalClients ?? this.totalClients,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Error loading leaderboard
class LeaderboardError extends LeaderboardState {
  const LeaderboardError({required this.error});
  final AppError error;
}

/// Leaderboard State Notifier
///
/// Manages class leaderboard state. Loads coaches list first,
/// then fetches the leaderboard for the selected coach.
/// Supports coach switching, pull-to-refresh, and offline cache.
@Riverpod(keepAlive: true)
class LeaderboardNotifier extends _$LeaderboardNotifier {
  late LeaderboardRepository _repository;

  @override
  LeaderboardState build() {
    _repository = ref.watch(leaderboardRepositoryProvider);
    Future.microtask(() => load());
    return const LeaderboardInitial();
  }

  /// Load — fetch coaches, then leaderboard for the first coach
  Future<void> load() async {
    state = const LeaderboardLoading();

    // Try cached coaches first
    final cachedCoachesResult = await _repository.getCachedCoaches();
    List<LeaderboardCoach> coaches = [];
    cachedCoachesResult.when(
      success: (cached) {
        if (cached.isNotEmpty) {
          coaches = cached;
        }
      },
      failure: (_) {},
    );

    // Sync coaches from server
    final coachesResult = await _repository.syncCoaches();
    coachesResult.when(
      success: (synced) {
        coaches = synced;
      },
      failure: (error) {
        // If we have cached coaches, continue with those
        if (coaches.isEmpty) {
          state = LeaderboardError(error: error);
          return;
        }
      },
    );

    if (coaches.isEmpty) {
      // No subscriptions — show empty state
      state = LeaderboardLoaded(
        coaches: [],
        selectedCoachId: null,
        entries: [],
        coachName: '',
        totalClients: 0,
        lastUpdated: DateTime.now(),
      );
      return;
    }

    // Select the first coach
    final firstCoach = coaches.first;
    await _loadLeaderboardForCoach(coaches, firstCoach.coachId);
  }

  /// Select a different coach and load their leaderboard
  Future<void> selectCoach(String coachId) async {
    final currentState = state;
    if (currentState is! LeaderboardLoaded) return;

    state = currentState.copyWith(isRefreshing: true);
    await _loadLeaderboardForCoach(currentState.coaches, coachId);
  }

  /// Refresh the current leaderboard
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is LeaderboardLoaded &&
        currentState.selectedCoachId != null) {
      state = currentState.copyWith(isRefreshing: true);

      // Also refresh coaches list
      final coachesResult = await _repository.syncCoaches();
      final coaches = coachesResult.when(
        success: (synced) => synced,
        failure: (_) => currentState.coaches,
      );

      await _loadLeaderboardForCoach(coaches, currentState.selectedCoachId!);
    } else {
      await load();
    }
  }

  /// Load leaderboard for a specific coach
  Future<void> _loadLeaderboardForCoach(
    List<LeaderboardCoach> coaches,
    String coachId,
  ) async {
    // Try cached leaderboard first
    final cachedResult = await _repository.getCachedLeaderboard(coachId);
    cachedResult.when(
      success: (cached) {
        if (cached != null) {
          state = LeaderboardLoaded(
            coaches: coaches,
            selectedCoachId: coachId,
            entries: cached.entries,
            coachName: cached.coachName,
            currentUserRank: cached.currentUserRank,
            totalClients: cached.totalClients,
            lastUpdated: cached.lastUpdated,
          );
        }
      },
      failure: (_) {},
    );

    // Sync from server
    final result = await _repository.syncLeaderboard(coachId);
    result.when(
      success: (leaderboard) {
        state = LeaderboardLoaded(
          coaches: coaches,
          selectedCoachId: coachId,
          entries: leaderboard.entries,
          coachName: leaderboard.coachName,
          currentUserRank: leaderboard.currentUserRank,
          totalClients: leaderboard.totalClients,
          lastUpdated: leaderboard.lastUpdated,
        );
        AppLogger.debug(
          'Leaderboard loaded for $coachId: ${leaderboard.entries.length} entries',
          tag: 'LeaderboardProvider',
        );
      },
      failure: (error) {
        // If we have cached data, keep showing it
        if (state is LeaderboardLoaded) {
          AppLogger.warning(
            'Failed to refresh leaderboard, keeping cached: ${error.message}',
            tag: 'LeaderboardProvider',
          );
          state = (state as LeaderboardLoaded).copyWith(isRefreshing: false);
          return;
        }
        state = LeaderboardError(error: error);
      },
    );
  }
}

// ── Convenience providers ──

/// Whether the leaderboard is currently loading
@riverpod
bool isLeaderboardLoading(Ref ref) {
  final state = ref.watch(leaderboardProvider);
  return state is LeaderboardLoading || state is LeaderboardInitial;
}

/// The current user's rank (null if not ranked or not loaded)
@riverpod
int? currentUserLeaderboardRank(Ref ref) {
  final state = ref.watch(leaderboardProvider);
  return switch (state) {
    LeaderboardLoaded(:final currentUserRank) => currentUserRank,
    _ => null,
  };
}

/// Available coaches for the leaderboard coach picker
@riverpod
List<LeaderboardCoach> leaderboardCoaches(Ref ref) {
  final state = ref.watch(leaderboardProvider);
  return switch (state) {
    LeaderboardLoaded(:final coaches) => coaches,
    _ => [],
  };
}
