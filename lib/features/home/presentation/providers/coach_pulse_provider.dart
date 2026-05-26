// lib/features/home/presentation/providers/coach_pulse_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/coach_programs/data/coach_program_repository.dart';

part 'coach_pulse_provider.g.dart';

/// Summary stats for the coach pulse block.
class CoachPulseStats {
  const CoachPulseStats({
    required this.totalClients,
    required this.clientsAssigned,
    required this.clientsUnassigned,
  });

  final int totalClients;
  final int clientsAssigned;
  final int clientsUnassigned;
}

/// Aggregates coach dashboard stats: client count and program assignment status.
///
/// @returns [CoachPulseStats] with counts derived from the coach client list.
@riverpod
Future<CoachPulseStats> coachPulse(Ref ref) async {
  final repo = ref.watch(coachProgramRepositoryProvider);
  final result = await repo.getClients(limit: 50, offset: 0);

  return result.when(
    success: (data) {
      final assigned = data.clients.where((c) => c.isAssigned).length;
      return CoachPulseStats(
        totalClients: data.pagination.total,
        clientsAssigned: assigned,
        clientsUnassigned: data.clients.length - assigned,
      );
    },
    failure: (_) => const CoachPulseStats(
      totalClients: 0,
      clientsAssigned: 0,
      clientsUnassigned: 0,
    ),
  );
}
