// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AuthStateNotifier)
const authStateProvider = AuthStateNotifierProvider._();

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
final class AuthStateNotifierProvider
    extends $NotifierProvider<AuthStateNotifier, AuthState> {
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
  const AuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateNotifierHash();

  @$internal
  @override
  AuthStateNotifier create() => AuthStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authStateNotifierHash() => r'621b9332b20fe9be975d97fef40d1469ad0f4a18';

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

abstract class _$AuthStateNotifier extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
