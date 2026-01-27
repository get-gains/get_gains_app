import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/utils/logger.dart';
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
  Future<void> _checkAuthStatus() async {
    // ignore: avoid_print
    print('[AuthState] _checkAuthStatus started');
    try {
      final isAuthenticated = await _storage.isAuthenticated();
      // ignore: avoid_print
      print('[AuthState] isAuthenticated: $isAuthenticated');

      if (isAuthenticated) {
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
