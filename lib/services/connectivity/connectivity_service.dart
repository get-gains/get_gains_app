import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';

part 'connectivity_service.g.dart';

/// Service that monitors network connectivity status.
///
/// Provides a [Stream] of connectivity changes and a synchronous check
/// for the current status. Used throughout the app to gate online-only
/// operations (e.g. profile creation/editing) while still allowing
/// offline reads from local caches.
///
/// Usage:
/// ```dart
/// final isOnline = ref.watch(isOnlineProvider);
/// if (!isOnline) showOfflineBanner();
/// ```
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  static const _tag = 'ConnectivityService';

  /// Returns `true` if the device currently has a network connection
  /// (Wi-Fi, mobile data, ethernet, VPN).
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasConnection(results);
    } catch (e) {
      AppLogger.error('Connectivity check failed', tag: _tag, error: e);
      // Assume online if check fails – let the actual request fail naturally
      return true;
    }
  }

  /// Stream of connectivity changes.
  ///
  /// Emits `true` when the device gains a connection and `false` when it
  /// loses all connections.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }
}

/// Singleton [ConnectivityService] provider.
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService();
}

/// Reactive provider that emits `true` when the device is online.
///
/// Starts with an initial connectivity check, then listens to the
/// connectivity change stream. Used by the presentation layer to
/// conditionally enable/disable online-only actions.
///
/// Usage:
/// ```dart
/// final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
/// ```
@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);

  // Create a stream that starts with the current connectivity and then
  // continues with live changes.
  return _connectivityStream(service);
}

Stream<bool> _connectivityStream(ConnectivityService service) async* {
  yield await service.isConnected();
  yield* service.onConnectivityChanged;
}
