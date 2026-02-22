import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_program_repository.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_request_models.dart';

part 'coach_assignment_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for a client's program assignments.
sealed class ClientAssignmentsState {
  const ClientAssignmentsState();
}

class ClientAssignmentsInitial extends ClientAssignmentsState {
  const ClientAssignmentsInitial();
}

class ClientAssignmentsLoading extends ClientAssignmentsState {
  const ClientAssignmentsLoading();
}

class ClientAssignmentsLoaded extends ClientAssignmentsState {
  const ClientAssignmentsLoaded(this.assignments);
  final List<AssignedProgramModel> assignments;
}

class ClientAssignmentsError extends ClientAssignmentsState {
  const ClientAssignmentsError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Client Assignments Notifier (family by userId)
// ──────────────────────────────────────────────────────────

/// Manages program assignments for a specific client.
///
/// Family provider — one instance per client user ID.
@riverpod
class ClientAssignmentsNotifier extends _$ClientAssignmentsNotifier {
  @override
  ClientAssignmentsState build(String userId) =>
      const ClientAssignmentsInitial();

  CoachProgramRepository get _repo => ref.read(coachProgramRepositoryProvider);

  /// Load all assignments for this client.
  Future<void> load() async {
    state = const ClientAssignmentsLoading();

    final result = await _repo.getClientPrograms(userId);

    result.when(
      success: (assignments) => state = ClientAssignmentsLoaded(assignments),
      failure: (error) {
        AppLogger.error(
          'Load client assignments failed: ${error.message}',
          tag: 'ClientAssignmentsNotifier',
        );
        state = ClientAssignmentsError(error);
      },
    );
  }

  /// Assign a program to this client, then refresh.
  Future<bool> assignProgram(AssignProgramRequest request) async {
    final result = await _repo.assignProgram(request);

    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Assign program failed: ${error.message}',
          tag: 'ClientAssignmentsNotifier',
        );
        return false;
      },
    );
  }

  /// Update an assignment's dates, notes, or active status, then refresh.
  Future<bool> updateAssignment(
    String assignmentId,
    UpdateAssignmentRequest request,
  ) async {
    final result = await _repo.updateAssignment(assignmentId, request);

    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Update assignment failed: ${error.message}',
          tag: 'ClientAssignmentsNotifier',
        );
        return false;
      },
    );
  }

  /// Delete an assignment, then refresh.
  Future<bool> deleteAssignment(String assignmentId) async {
    final result = await _repo.deleteAssignment(assignmentId);

    return result.when(
      success: (_) {
        final current = state;
        if (current is ClientAssignmentsLoaded) {
          state = ClientAssignmentsLoaded(
            current.assignments.where((a) => a.id != assignmentId).toList(),
          );
        }
        return true;
      },
      failure: (error) {
        AppLogger.error(
          'Delete assignment failed: ${error.message}',
          tag: 'ClientAssignmentsNotifier',
        );
        return false;
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Convenience Providers
// ──────────────────────────────────────────────────────────

/// Active assignments for a client.
@riverpod
List<AssignedProgramModel> clientActiveAssignments(Ref ref, String userId) {
  final state = ref.watch(clientAssignmentsProvider(userId));
  if (state is ClientAssignmentsLoaded) {
    return state.assignments.where((a) => a.isActive).toList();
  }
  return [];
}
