// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Router Provider
///
/// Centralized routing with go_router.
/// Handles auth-based redirects automatically.
///
/// Route Guard Logic:
/// - Unauthenticated users can only access: login, register, forgot-password
/// - reset-password is an authenticated route (user comes from email link with token)
/// - complete-profile is for Google sign-up flow (has temp tokens)
/// - All other routes require full authentication
///
/// Usage:
/// ```dart
/// // In MaterialApp
/// MaterialApp.router(
///   routerConfig: ref.watch(routerProvider),
/// )
///
/// // Navigation
/// context.go(AppRoutes.home);
/// context.push(AppRoutes.profile);
/// ```

@ProviderFor(router)
const routerProvider = RouterProvider._();

/// Router Provider
///
/// Centralized routing with go_router.
/// Handles auth-based redirects automatically.
///
/// Route Guard Logic:
/// - Unauthenticated users can only access: login, register, forgot-password
/// - reset-password is an authenticated route (user comes from email link with token)
/// - complete-profile is for Google sign-up flow (has temp tokens)
/// - All other routes require full authentication
///
/// Usage:
/// ```dart
/// // In MaterialApp
/// MaterialApp.router(
///   routerConfig: ref.watch(routerProvider),
/// )
///
/// // Navigation
/// context.go(AppRoutes.home);
/// context.push(AppRoutes.profile);
/// ```

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Router Provider
  ///
  /// Centralized routing with go_router.
  /// Handles auth-based redirects automatically.
  ///
  /// Route Guard Logic:
  /// - Unauthenticated users can only access: login, register, forgot-password
  /// - reset-password is an authenticated route (user comes from email link with token)
  /// - complete-profile is for Google sign-up flow (has temp tokens)
  /// - All other routes require full authentication
  ///
  /// Usage:
  /// ```dart
  /// // In MaterialApp
  /// MaterialApp.router(
  ///   routerConfig: ref.watch(routerProvider),
  /// )
  ///
  /// // Navigation
  /// context.go(AppRoutes.home);
  /// context.push(AppRoutes.profile);
  /// ```
  const RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'99d426605790f20b1ee6bc46275884b01bed072b';
