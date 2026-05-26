import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../services/api/api_client.dart';
import '../../data/models/profile_stats_model.dart';

part 'profile_stats_provider.g.dart';

@riverpod
Future<ProfileStatsModel> profileStats(Ref ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.get<Map<String, dynamic>>(
    ApiConstants.profileStats,
  );

  if (result case Success(value: final data)) {
    return ProfileStatsModel.fromJson(data);
  }

  AppLogger.warning('Failed to load profile stats, returning defaults',
      tag: 'ProfileStats');
  return const ProfileStatsModel();
}
