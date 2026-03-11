// lib/features/profile/presentation/providers/profile_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../services/api/api_client.dart';
import '../../../auth/data/models/user_model.dart';

part 'profile_provider.g.dart';

/// Fetches the current user's profile from the API.
///
/// Usage:
/// ```dart
/// final profileAsync = ref.watch(profileProvider);
/// profileAsync.when(
///   data: (user) => Text(user.name),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// // Refresh
/// ref.invalidate(profileProvider);
/// ```
@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  @override
  Future<UserModel> build() async {
    // Rebuild automatically when the authenticated user changes.
    ref.watch(authStateProvider);
    final apiClient = ref.watch(apiClientProvider);
    final result = await apiClient.get<Map<String, dynamic>>(
      ApiConstants.userProfile,
    );
    return result.when(
      success: (data) {
        final userMap = data['user'] as Map<String, dynamic>? ?? data;
        AppLogger.debug('Profile loaded', tag: 'Profile');
        return UserModel.fromJson(userMap);
      },
      failure: (error) {
        AppLogger.error('Profile load failed', tag: 'Profile', error: error);
        throw Exception(error.message);
      },
    );
  }
}
