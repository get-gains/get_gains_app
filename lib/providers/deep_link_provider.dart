import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/utils/logger.dart';
import '../services/storage/secure_storage_service.dart';

part 'deep_link_provider.g.dart';

/// Deep Link Event
///
/// Represents an incoming deep link with parsed path and query parameters.
class DeepLinkEvent {
  const DeepLinkEvent({required this.path, this.queryParameters = const {}});

  /// The path of the deep link (e.g., '/auth/email-verified')
  final String path;

  /// Query parameters from the deep link URL
  final Map<String, String> queryParameters;

  @override
  String toString() => 'DeepLinkEvent(path: $path, params: $queryParameters)';
}

/// Deep Link Provider
///
/// Listens for incoming deep links and exposes them as state.
/// The router watches this provider to handle navigation on deep link events.
///
/// Supported deep links:
/// - getgains://auth/email-verified → Navigate to /email-verified
/// - getgains://auth/reset-password?access_token=xxx&refresh_token=xxx → Store tokens, navigate to /reset-password
@Riverpod(keepAlive: true)
class DeepLinkNotifier extends _$DeepLinkNotifier {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  @override
  DeepLinkEvent? build() {
    _appLinks = AppLinks();

    // Listen for incoming deep links (while app is running)
    _subscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        AppLogger.error(
          'Deep link stream error',
          tag: 'DeepLink',
          error: error,
        );
      },
    );

    // Check for initial deep link (app was launched from a deep link)
    _checkInitialLink();

    // Clean up subscription on dispose
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return null;
  }

  /// Check if the app was launched from a deep link
  Future<void> _checkInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.info('Initial deep link: $initialUri', tag: 'DeepLink');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      AppLogger.error(
        'Failed to get initial deep link',
        tag: 'DeepLink',
        error: e,
      );
    }
  }

  /// Handle an incoming deep link URI
  Future<void> _handleDeepLink(Uri uri) async {
    AppLogger.info('Deep link received: $uri', tag: 'DeepLink');

    // Parse the deep link
    // URI format: getgains://auth/email-verified
    // URI format: getgains://auth/reset-password?access_token=xxx&refresh_token=xxx
    final path = '/${uri.host}${uri.path}'; // e.g., /auth/email-verified
    final queryParams = uri.queryParameters;

    // If this is a reset password deep link, store the recovery tokens
    if (path == '/auth/reset-password') {
      final accessToken = queryParams['access_token'];
      final refreshToken = queryParams['refresh_token'];

      if (accessToken != null) {
        final secureStorage = ref.read(secureStorageServiceProvider);
        // Store as recovery tokens (separate from regular auth tokens)
        await secureStorage.saveRecoveryToken(accessToken);
        if (refreshToken != null) {
          await secureStorage.saveRecoveryRefreshToken(refreshToken);
        }
        AppLogger.info(
          'Recovery tokens stored from deep link',
          tag: 'DeepLink',
        );
      }
    }

    state = DeepLinkEvent(path: path, queryParameters: queryParams);
  }

  /// Clear the current deep link event (after it's been handled)
  void clearDeepLink() {
    state = null;
  }
}
