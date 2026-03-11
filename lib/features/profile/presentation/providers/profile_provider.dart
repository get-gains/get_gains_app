// lib/features/profile/presentation/providers/profile_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../services/api/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/services/user_preferences_service.dart';

part 'profile_provider.g.dart';

/// Fetches the current user's profile from the API.
/// Falls back to Hive-cached user when offline.
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
    final prefs = ref.watch(userPreferencesServiceProvider);
    final result = await apiClient.get<Map<String, dynamic>>(
      ApiConstants.userProfile,
    );

    if (result is Success<Map<String, dynamic>, AppError>) {
      final data = result.value;
      final userMap = data['user'] as Map<String, dynamic>? ?? data;
      final user = UserModel.fromJson(userMap);
      AppLogger.debug('Profile loaded', tag: 'Profile');
      // Cache for offline use
      prefs.cacheUser(user);
      return user;
    }

    // Server failed — try cached user
    AppLogger.warning('Profile server failed — using cache', tag: 'Profile');
    final cached = await prefs.getCachedUser();
    if (cached != null) {
      AppLogger.info('Profile loaded from cache', tag: 'Profile');
      return cached;
    }

    final failure = result as Failure<Map<String, dynamic>, AppError>;
    throw Exception(failure.error.message);
  }
}
