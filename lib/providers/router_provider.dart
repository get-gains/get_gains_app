import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_state_provider.dart';

part 'router_provider.g.dart';

/// Route Paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

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
@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterRefreshStream(ref),

    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isInitial = authState.status == AuthStatus.initial;
      final location = state.uri.path;

      // Auth routes
      final isAuthRoute =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword;

      // Still loading auth state
      if (isInitial) {
        return AppRoutes.splash;
      }

      // Not authenticated and not on auth route
      if (!isAuthenticated && !isAuthRoute && location != AppRoutes.splash) {
        return AppRoutes.login;
      }

      // Authenticated but on auth route
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      // Authenticated on splash, go to home
      if (isAuthenticated && location == AppRoutes.splash) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      // Splash/Loading
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Loading...'),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Register'),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Forgot Password'),
      ),

      // Main App Routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Settings'),
      ),
    ],

    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Refresh notifier for router when auth state changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(this._ref) {
    _ref.listen(authStateProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Placeholder screen - replace with actual screens
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Screen\n(Placeholder)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

/// Error screen for invalid routes
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
