import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/auth.dart';
import '../features/home/home.dart';
import '../features/workout/workout.dart';
import 'auth_state_provider.dart';

part 'router_provider.g.dart';

/// Route Paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String checkEmail = '/check-email';
  static const String completeProfile = '/complete-profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Workout routes
  static const String routines = '/routines';
  static const String workoutSession = '/workout-session';
}

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
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Create a notifier that listens to auth state changes
  final refreshNotifier = _GoRouterRefreshStream(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,

    redirect: (context, state) {
      // Read auth state inside redirect so it's always current
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isInitial = authState.status == AuthStatus.initial;
      final location = state.uri.path;

      // Public auth routes (accessible without authentication)
      final isPublicAuthRoute =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.checkEmail ||
          location == AppRoutes.forgotPassword;

      // Semi-authenticated routes (require temp tokens but not full profile)
      // - reset-password: User has token from email link
      // - complete-profile: User has Google tokens but needs to complete profile
      final isSemiAuthRoute =
          location == AppRoutes.resetPassword ||
          location == AppRoutes.completeProfile;

      // Still loading auth state
      if (isInitial) {
        return AppRoutes.splash;
      }

      // Unauthenticated on splash, go to login
      if (!isAuthenticated && location == AppRoutes.splash) {
        return AppRoutes.login;
      }

      // Not authenticated and not on public auth route
      if (!isAuthenticated &&
          !isPublicAuthRoute &&
          !isSemiAuthRoute &&
          location != AppRoutes.splash) {
        return AppRoutes.login;
      }

      // Authenticated but on public auth route (except semi-auth routes)
      if (isAuthenticated && isPublicAuthRoute) {
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

      // Auth Routes (Public)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkEmail,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return CheckEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Forgot Password'),
      ),

      // Auth Routes (Semi-Authenticated)
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Reset Password'),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // Main App Routes (Fully Authenticated)
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
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

      // Workout Routes
      GoRoute(
        path: AppRoutes.routines,
        builder: (context, state) => const RoutineListScreen(),
      ),
      GoRoute(
        path: AppRoutes.workoutSession,
        builder: (context, state) => const WorkoutSessionScreen(),
      ),
    ],

    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Refresh notifier for router when auth state changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      // ignore: avoid_print
      print(
        '[Router] Auth state changed: ${previous?.status} -> ${next.status}',
      );
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
