// lib/features/home/presentation/providers/floating_mission_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/gains_coins/data/models/mission_list_item_model.dart';
import '../../../../features/gains_coins/presentation/providers/missions_provider.dart';

part 'floating_mission_provider.g.dart';

/// Up to 3 in-progress missions ordered by progress descending.
///
/// Returns an empty list when there are no in-progress missions.
/// The floating layer renders nothing in that case (no empty stack frame).
@riverpod
Future<List<MissionListItemModel>> floatingMissions(Ref ref) async {
  final missions = await ref.watch(missionsListProvider.future);

  final inProgress = missions.where((m) {
    final status = m.userMission?.status;
    return status == 'inProgress' || status == 'in_progress';
  }).toList()
    ..sort((a, b) => b.displayProgress.compareTo(a.displayProgress));

  return inProgress.take(3).toList();
}
