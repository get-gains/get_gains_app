import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/utils/logger.dart';
import '../features/auth/auth.dart';
import '../features/coach_pose/coach_pose.dart';
import '../features/home/home.dart';
import '../features/profile/profile.dart';
import '../features/workout/workout.dart';
import '../features/unity/unity.dart';
import 'auth_state_provider.dart';
import '../features/programs/screens/program_screen.dart';
import '../features/programs/screens/program_details_screen.dart';
import '../features/programs/screens/calendar_screen.dart';
import '../features/programs/screens/create_program_screen.dart';

import 'deep_link_provider.dart';

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
  static const String emailVerified = '/email-verified';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';

  // Workout routes
  static const String routines = '/routines';
  static const String workoutSession = '/workout-session';
  static const String unityTest = '/unity-test';
  static const String programs = '/programs';
  static const String createProgram = '/create-program';
  static const String programDetails = '/program-details';
  static const String calendar = '/calendar';

  // Coach Pose routes
  static const String coachExercises = '/coach/exercises';
  static const String createExercise = '/coach/exercises/create';
  static const String exerciseDetail = '/coach/exercises/:id';
  static const String recordForm = '/coach/exercises/:id/record';
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

  final routerInstance = GoRouter(
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
      // TODO: Remove unityTest from public routes when auth is required for Unity screen
      final isPublicAuthRoute =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.checkEmail ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.emailVerified ||
          location ==
              AppRoutes
                  .unityTest; // Temporary: no auth required for dev/testing

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
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Auth Routes (Semi-Authenticated)
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerified,
        builder: (context, state) => const EmailVerifiedScreen(),
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

      // GoRoute(
      //   path: AppRoutes.home,
      //   builder: (context, state) => const ProgramsScreen(),
      // ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
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
      GoRoute(
        path: AppRoutes.unityTest,
        builder: (context, state) => const UnityTestScreen(),
      ),
      GoRoute(
        path: AppRoutes.programs,
        builder: (context, state) => const ProgramsScreen(),
      ),

      GoRoute(
        path: AppRoutes.createProgram,
        builder: (context, state) => const CreateProgramScreen(),
      ),

      GoRoute(
        path: AppRoutes.programDetails,
        builder: (context, state) {
          final program = state.extra as Map;
          return ProgramDetailsScreen(program: program);
        },
      ),

      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),

      // Coach Pose Routes
      GoRoute(
        path: AppRoutes.coachExercises,
        builder: (context, state) => const ExerciseListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createExercise,
        builder: (context, state) => const CreateExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.exerciseDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final exercise = state.extra as ExerciseModel?;
          return ExerciseDetailScreen(exerciseId: id, exercise: exercise);
        },
      ),
      GoRoute(
        path: AppRoutes.recordForm,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FormRecordingScreen(exerciseId: id);
        },
      ),
    ],

    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );

  // Listen for deep links and navigate accordingly
  ref.listen<DeepLinkEvent?>(deepLinkProvider, (
    DeepLinkEvent? previous,
    DeepLinkEvent? next,
  ) {
    if (next != null) {
      AppLogger.info('Navigating from deep link: ${next.path}', tag: 'Router');

      switch (next.path) {
        case '/auth/email-verified':
          routerInstance.go(AppRoutes.emailVerified);
          break;
        case '/auth/reset-password':
          routerInstance.go(AppRoutes.resetPassword);
          break;
        default:
          AppLogger.warning(
            'Unknown deep link path: ${next.path}',
            tag: 'Router',
          );
      }

      // Clear the deep link after handling
      ref.read(deepLinkProvider.notifier).clearDeepLink();
    }
  });

  return routerInstance;
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
