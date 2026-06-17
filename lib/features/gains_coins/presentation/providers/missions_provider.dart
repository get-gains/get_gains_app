import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/missions_repository.dart';
import '../../data/models/mission_list_item_model.dart';

part 'missions_provider.g.dart';

/// Active missions for the current user (server).
@Riverpod(keepAlive: false)
Future<List<MissionListItemModel>> missionsList(Ref ref) async {
  final repo = ref.watch(missionsRepositoryProvider);
  final res = await repo.fetchActiveMissions();
  return res.when(
    success: (missions) => missions,
    failure: (e) => throw Exception(e.message),
  );
}

/// Offer tag of the first unclaimed coupon reward the user has earned.
/// Null if no coupon mission is completed but not yet redeemed.
@riverpod
Future<String?> activeCouponOfferTag(Ref ref) async {
  final missions = await ref.watch(missionsListProvider.future);
  for (final mission in missions) {
    if (mission.rewardType == 'COUPON' &&
        mission.isCompleted &&
        mission.coupon != null &&
        !mission.coupon!.claimed) {
      return mission.coupon!.offerTag;
    }
  }
  return null;
}
