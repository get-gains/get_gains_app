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

String _$routerHash() => r'ec799ccac348537a2c7a3c21d3020f0468dd5b67';
