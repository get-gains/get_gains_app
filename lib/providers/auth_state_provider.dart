import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/profile/presentation/providers/profile_provider.dart';
import '../features/profile/presentation/providers/user_profile_provider.dart';
import '../features/subscription/presentation/providers/subscription_provider.dart';
import '../services/api/api_client.dart';
import '../services/storage/secure_storage_service.dart';

part 'auth_state_provider.g.dart';

/// Authentication State
enum AuthStatus {
  /// Initial state, checking stored credentials
  initial,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,
}

/// Auth State for the application
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.email,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? userId;
  final String? email;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  String toString() =>
      'AuthState(status: $status, userId: $userId, email: $email, isLoading: $isLoading)';
}

/// Auth State Provider
///
/// Manages authentication state across the app.
/// Use this provider to:
/// - Check if user is logged in
/// - Access current user info
/// - Handle login/logout flows
///
/// Usage:
/// ```dart
/// // In a widget
/// final authState = ref.watch(authStateProvider);
/// if (authState.isAuthenticated) {
///   // Show authenticated UI
/// }
///
/// // To login
/// await ref.read(authStateProvider.notifier).login(email, password);
///
/// // To logout
/// await ref.read(authStateProvider.notifier).logout();
/// ```
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  late SecureStorageService _storage;

  @override
  AuthState build() {
    _storage = ref.watch(secureStorageServiceProvider);

    // Schedule auth check after build completes
    // Using Future.microtask to ensure state is initialized first
    // ignore: avoid_print
    print('[AuthState] build() called, scheduling _checkAuthStatus');
    Future.microtask(() => _checkAuthStatus());

    return const AuthState(isLoading: true);
  }

  /// Check if user has valid stored credentials
  ///
  /// Offline-first: if the access token is expired and refresh fails
  /// (e.g. no internet), the user is still considered authenticated
  /// as long as stored credentials (userId, email) exist. The expired
  /// token will be refreshed automatically on the next successful API
  /// call via the Dio interceptor's 401 handling.
  Future<void> _checkAuthStatus() async {
    // ignore: avoid_print
    print('[AuthState] _checkAuthStatus started');
    try {
      final isAuthenticated = await _storage.isAuthenticated();
      // ignore: avoid_print
      print('[AuthState] isAuthenticated: $isAuthenticated');

      if (isAuthenticated) {
        // If access token is expired, try refreshing before proceeding
        final isExpired = await _storage.isTokenExpired();
        if (isExpired) {
          // ignore: avoid_print
          print('[AuthState] Access token expired, attempting refresh');
          final apiClient = ref.read(apiClientProvider);
          final refreshed = await apiClient.tryRefreshToken();
          if (!refreshed) {
            // ignore: avoid_print
            print('[AuthState] Token refresh failed, checking offline credentials');

            // Offline-first: allow degraded mode if we still have
            // cached user info — the token will refresh on next
            // successful network call (Dio interceptor handles 401).
            final userId = await _storage.getUserId();
            final email = await _storage.getUserEmail();
            if (userId != null) {
              // ignore: avoid_print
              print('[AuthState] Offline auth: using cached credentials');
              state = state.copyWith(
                status: AuthStatus.authenticated,
                userId: userId,
                email: email,
                isLoading: false,
              );
              return;
            }

            // No cached credentials — truly unauthenticated
            state = state.copyWith(
              status: AuthStatus.unauthenticated,
              isLoading: false,
            );
            return;
          }
          // ignore: avoid_print
          print('[AuthState] Token refreshed successfully');
        }

        final userId = await _storage.getUserId();
        final email = await _storage.getUserEmail();

        state = state.copyWith(
          status: AuthStatus.authenticated,
          userId: userId,
          email: email,
          isLoading: false,
        );
        // ignore: avoid_print
        print('[AuthState] Set to authenticated');
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        // ignore: avoid_print
        print('[AuthState] Set to unauthenticated');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AuthState] Error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Failed to check auth status',
      );
    }
  }

  /// Update state after successful login
  /// Called by auth repository after API login succeeds
  Future<void> setAuthenticated({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    DateTime? tokenExpiry,
  }) async {
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: tokenExpiry,
    );
    await _storage.saveUserId(userId);
    await _storage.saveUserEmail(email);

    state = state.copyWith(
      status: AuthStatus.authenticated,
      userId: userId,
      email: email,
      isLoading: false,
    );
  }

  /// Logout and clear all stored credentials
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Clear stored tokens
      await _storage.clearTokens();
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_email');

      state = const AuthState(status: AuthStatus.unauthenticated);

      // Invalidate all user-specific cached providers so the next
      // login always fetches fresh data for the new account.
      ref.invalidate(profileProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(subscriptionProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to logout',
      );
    }
  }

  /// Called when token refresh fails or unauthorized response received
  void onAuthFailure() {
    logout();
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
