import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/api/api_client.dart';
import '../../../profile/data/models/user_profile_model.dart';

part 'client_profile_provider.g.dart';

/// Fetches a client's profile from the coach endpoint.
///
/// Family provider keyed by client user ID. Returns the profile model
/// or `null` on error so the UI can degrade gracefully.
@riverpod
class ClientProfileNotifier extends _$ClientProfileNotifier {
  @override
  AsyncValue<UserProfileModel?> build(String userId) {
    _fetch();
    return const AsyncLoading();
  }

  Future<void> _fetch() async {
    final api = ref.read(apiClientProvider);
    final result = await api.get<Map<String, dynamic>>(
      ApiConstants.clientProfile(userId),
    );

    result.when(
      success: (data) {
        final profileJson = data['profile'];
        if (profileJson == null) {
          state = const AsyncData(null);
          return;
        }
        final profile = UserProfileModel.fromJson(
          profileJson as Map<String, dynamic>,
        );
        state = AsyncData(profile);
      },
      failure: (error) {
        AppLogger.warning(
          'Failed to fetch client profile: ${error.message}',
          tag: 'ClientProfileNotifier',
        );
        state = const AsyncData(null);
      },
    );
  }
}
