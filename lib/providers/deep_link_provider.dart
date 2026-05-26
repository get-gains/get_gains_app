import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/utils/logger.dart';

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

    final path = '/${uri.host}${uri.path}';
    final queryParams = uri.queryParameters;

    state = DeepLinkEvent(path: path, queryParameters: queryParams);
  }

  /// Clear the current deep link event (after it's been handled)
  void clearDeepLink() {
    state = null;
  }
}
