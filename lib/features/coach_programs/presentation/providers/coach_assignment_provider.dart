import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_program_repository.dart';
import '../../data/models/program_model.dart';

part 'coach_assignment_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for a client's active program.
sealed class ClientAssignmentsState {
  const ClientAssignmentsState();
}

class ClientAssignmentsInitial extends ClientAssignmentsState {
  const ClientAssignmentsInitial();
}

class ClientAssignmentsLoading extends ClientAssignmentsState {
  const ClientAssignmentsLoading();
}

/// Holds the client's current active program (or `null` if none).
class ClientAssignmentsLoaded extends ClientAssignmentsState {
  const ClientAssignmentsLoaded(this.activeProgram);
  final ClientProgramModel? activeProgram;
}

class ClientAssignmentsError extends ClientAssignmentsState {
  const ClientAssignmentsError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Client Assignments Notifier (family by userId)
// ──────────────────────────────────────────────────────────

/// Manages the active program for a specific client.
///
/// Family provider — one instance per client user ID.
/// Mutations (create / edit / delete program, add routines, etc.) are
/// handled by `ProgramBuilderProvider` (Phase 2). This provider only
/// reads the current active program.
@riverpod
class ClientAssignmentsNotifier extends _$ClientAssignmentsNotifier {
  @override
  ClientAssignmentsState build(String userId) =>
      const ClientAssignmentsInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load the active program for this client.
  Future<void> load() async {
    state = const ClientAssignmentsLoading();

    final result = await _repo.getClientActiveProgram(userId);

    result.when(
      success: (program) => state = ClientAssignmentsLoaded(program),
      failure: (error) {
        AppLogger.error(
          'Load client active program failed: ${error.message}',
          tag: 'ClientAssignmentsNotifier',
        );
        state = ClientAssignmentsError(error);
      },
    );
  }
}
