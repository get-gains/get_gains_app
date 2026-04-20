import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/utils/logger.dart';
import '../features/auth/auth.dart';
import '../features/client_pose/client_pose.dart';
import '../features/coach_pose/coach_pose.dart';
import '../features/coach_client_progress/coach_client_progress.dart';
import '../features/coach_programs/coach_programs.dart';
import '../features/coach_settings/coach_settings.dart';
import '../features/coaches/coaches.dart';
import '../features/home/home.dart';
import '../features/profile/profile.dart';
import '../features/workout/workout.dart';
import '../features/standalone_workout/standalone_workout.dart';
import '../features/unity/unity.dart';
import '../features/gains_coins/presentation/screens/coin_history_screen.dart';
import '../features/gains_coins/presentation/screens/coin_reward_screen.dart';
import '../features/gains_coins/presentation/screens/shop_screen.dart';
import '../features/gains_coins/presentation/screens/cosmetic_detail_screen.dart';
import '../features/gains_coins/presentation/screens/inventory_screen.dart';
import '../features/gains_coins/presentation/screens/leaderboard_screen.dart';
import '../features/gains_coins/data/models/cosmetic_model.dart';
import 'auth_state_provider.dart';
import '../features/programs/screens/program_screen.dart';
import '../features/programs/screens/program_details_screen.dart';
import '../features/programs/screens/calendar_screen.dart';
import '../features/programs/screens/create_program_screen.dart';

import 'deep_link_provider.dart';

part 'router_provider.g.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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
  static const String routineDetail = '/routines/:id';
  static const String workoutSession = '/workout-session';
  static const String unityTest = '/unity-test';
  static const String programs = '/programs';
  static const String createProgram = '/create-program';
  static const String programDetails = '/program-details';
  static const String calendar = '/calendar';

  // Coach Hub
  static const String coachHub = '/coach/hub';

  // Workout History & Progress
  static const String workoutHistory = '/workout/history';
  static const String progress = '/progress';

  // Coach Pose routes
  static const String coachExercises = '/coach/exercises';
  static const String createExercise = '/coach/exercises/create';
  static const String exerciseDetail = '/coach/exercises/:id';
  static const String recordForm = '/coach/exercises/:id/record';
  static const String coachViewForm = '/coach/exercises/:id/forms/:formId/view';
  static const String coachForm3DPreview =
      '/coach/exercises/:id/forms/:formId/3d-preview';

  // Client Pose routes
  static const String clientViewForm = '/client/exercise/:id/view-form';
  static const String clientForm3DPreview =
      '/client/exercise/:id/form-3d-preview';
  static const String clientCompareForm = '/client/exercise/:id/compare';
  static const String clientUnityRecord = '/client/exercise/:id/unity-record';
  // Coach Program routes
  static const String coachRoutines = '/coach/routines';
  static const String coachCreateRoutine = '/coach/routines/create';
  static const String coachEditRoutine = '/coach/routines/:id/edit';
  static const String coachRoutineDetail = '/coach/routines/:id';
  static const String clientAssignments = '/coach/clients/:userId/programs';
  static const String programBuilder = '/coach/clients/:userId/program-builder';
  static const String coachRoster = '/coach/roster';
  static const String coachSettings = '/coach/settings';

  // Coach Client Progress routes
  static const String clientProgress = '/coach/clients/:userId/progress';
  static const String clientSessionDetail =
      '/coach/clients/:userId/sessions/:sessionId';
  static const String clientExerciseHistory =
      '/coach/clients/:userId/exercises/:exerciseId/history';
  static const String clientFormReview =
      '/coach/clients/:userId/form-results/:resultId';
  static const String coachPerformanceDashboard = '/coach/performance';

  // Coach Discovery routes (client-facing)
  static const String discoverCoaches = '/coaches/discover';
  static const String coachProfile = '/coaches/:id';
  static const String subscribedCoaches = '/coaches/subscribed';

  // Standalone Workout routes
  static const String standaloneExercises = '/standalone/exercises';
  static const String standaloneCreateExercise = '/standalone/exercises/create';
  static const String standaloneExerciseEdit = '/standalone/exercises/:id/edit';
  static const String standaloneRoutines = '/standalone/routines';
  static const String standaloneCreateRoutine = '/standalone/routines/create';
  static const String standaloneRoutineDetail = '/standalone/routines/:id';
  static const String standaloneEditRoutine = '/standalone/routines/:id/edit';
  static const String standalonePrograms = '/standalone/programs';
  static const String standaloneCreateProgram = '/standalone/programs/create';
  static const String standaloneProgramDetail = '/standalone/programs/:id';
  static const String standaloneEditProgram = '/standalone/programs/:id/edit';
  static const String standaloneToday = '/standalone/today';
  static const String standaloneSessionHistory = '/standalone/sessions';

  // Gains Coins routes
  static const String coinReward = '/coins/reward';
  static const String coinHistory = '/coins/history';
  static const String shop = '/shop';
  static const String cosmeticDetail = '/shop/cosmetic';
  static const String inventory = '/inventory';
  static const String leaderboard = '/leaderboard';
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
    navigatorKey: appNavigatorKey,
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
        path: AppRoutes.routineDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final routine = state.extra as RoutineModel?;
          return RoutineDetailScreen(routineId: id, routine: routine);
        },
      ),
      GoRoute(
        path: AppRoutes.workoutSession,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final rawNextSetNavigation = extra?['nextSetNavigation'];
          return WorkoutSessionScreen(
            readOnly: (extra?['readOnly'] as bool?) ?? false,
            nextSetNavigation: rawNextSetNavigation is Map
                ? Map<String, dynamic>.from(rawNextSetNavigation)
                : null,
          );
        },
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

      // Coach Hub
      GoRoute(
        path: AppRoutes.coachHub,
        builder: (context, state) => const CoachHubScreen(),
      ),

      // Workout History & Progress
      GoRoute(
        path: AppRoutes.workoutHistory,
        builder: (context, state) => const WorkoutHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => const ProgressScreen(),
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
      GoRoute(
        path: AppRoutes.coachViewForm,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final formId = state.pathParameters['formId']!;
          return CoachViewFormScreen(exerciseId: id, formId: formId);
        },
      ),
      GoRoute(
        path: AppRoutes.coachForm3DPreview,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final frames = extra?['landmarkFrames'] as List<LandmarkFrame>? ?? [];
          final angle = extra?['cameraAngle'] as String? ?? 'FRONT';
          return Form3DPreviewScreen(
            landmarkFrames: frames,
            cameraAngle: angle,
          );
        },
      ),

      // Client Pose Routes
      GoRoute(
        path: AppRoutes.clientViewForm,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ViewFormScreen(exerciseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.clientForm3DPreview,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final frames = extra?['landmarkFrames'] as List<LandmarkFrame>? ?? [];
          final angle = extra?['cameraAngle'] as String? ?? 'FRONT';
          return Form3DPreviewScreen(
            landmarkFrames: frames,
            cameraAngle: angle,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.clientCompareForm,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClientRecordingScreen(exerciseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.clientUnityRecord,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ClientUnityRecordingScreen(
            exerciseId: id,
            workoutSessionId: extra?['workoutSessionId'] as String?,
            routineExerciseId: extra?['routineExerciseId'] as String?,
            routineExercises:
                extra?['routineExercises'] as List<RoutineExerciseModel>?,
            currentExerciseIndex: (extra?['currentExerciseIndex'] as int?) ?? 0,
            currentSetNumber: (extra?['currentSetNumber'] as int?) ?? 1,
          );
        },
      ),

      // Coach Routine Routes
      GoRoute(
        path: AppRoutes.coachRoutines,
        builder: (context, state) => const CoachRoutinesScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachCreateRoutine,
        builder: (context, state) => const CoachRoutineFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachRoutineDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CoachRoutineDetailScreen(routineId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.coachEditRoutine,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CoachRoutineFormScreen(routineId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.clientAssignments,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final userName = state.uri.queryParameters['name'];
          return ClientAssignmentsScreen(userId: userId, userName: userName);
        },
      ),
      GoRoute(
        path: AppRoutes.programBuilder,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final programId = state.uri.queryParameters['programId'];
          final clientName = state.uri.queryParameters['name'];
          return ProgramBuilderScreen(
            clientId: userId,
            programId: programId,
            clientName: clientName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.coachRoster,
        builder: (context, state) => const CoachRosterScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachSettings,
        builder: (context, state) => const CoachSettingsScreen(),
      ),

      // Coach Client Progress Routes
      GoRoute(
        path: AppRoutes.clientProgress,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final userName = state.extra as String?;
          return ClientProgressScreen(userId: userId, userName: userName);
        },
      ),
      GoRoute(
        path: AppRoutes.clientSessionDetail,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final sessionId = state.pathParameters['sessionId']!;
          return SessionDetailScreen(userId: userId, sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutes.clientExerciseHistory,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final exerciseId = state.pathParameters['exerciseId']!;
          final exerciseName = state.extra as String?;
          return ExerciseHistoryScreen(
            userId: userId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.clientFormReview,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final resultId = state.pathParameters['resultId']!;
          final result = state.extra as ClientFormResult?;
          return FormReviewScreen(
            userId: userId,
            resultId: resultId,
            result: result,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.coachPerformanceDashboard,
        builder: (context, state) => const PerformanceDashboardScreen(),
      ),

      // Coach Discovery Routes (Client-Facing)
      // IMPORTANT: Literal routes must come before parametric `:id` route
      // to prevent GoRouter from matching e.g. `/coaches/subscribed` as `:id`.
      GoRoute(
        path: AppRoutes.discoverCoaches,
        builder: (context, state) => const CoachDiscoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscribedCoaches,
        builder: (context, state) => const SubscribedCoachesScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachProfile,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CoachProfileScreen(coachId: id);
        },
      ),

      // Standalone Workout Routes
      GoRoute(
        path: AppRoutes.standaloneExercises,
        builder: (context, state) => const StandaloneExercisesScreen(),
      ),
      GoRoute(
        path: AppRoutes.standaloneCreateExercise,
        builder: (context, state) => const StandaloneExerciseFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.standaloneExerciseEdit,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StandaloneExerciseFormScreen(exerciseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.standaloneRoutines,
        builder: (context, state) => const StandaloneRoutinesScreen(),
      ),
      GoRoute(
        path: AppRoutes.standaloneCreateRoutine,
        builder: (context, state) => const StandaloneRoutineFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.standaloneRoutineDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StandaloneRoutineDetailScreen(routineId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.standaloneEditRoutine,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StandaloneRoutineFormScreen(routineId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.standalonePrograms,
        builder: (context, state) => const StandaloneProgramsScreen(),
      ),
      GoRoute(
        path: AppRoutes.standaloneCreateProgram,
        builder: (context, state) => const StandaloneProgramFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.standaloneProgramDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StandaloneProgramDetailScreen(programId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.standaloneEditProgram,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StandaloneProgramFormScreen(programId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.standaloneToday,
        builder: (context, state) => const StandaloneTodayScreen(),
      ),
      GoRoute(
        path: AppRoutes.standaloneSessionHistory,
        builder: (context, state) => const StandaloneSessionHistoryScreen(),
      ),

      // ── Gains Coins ──
      GoRoute(
        path: AppRoutes.coinReward,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CoinRewardScreen(
            setsCompleted: (extra['setsCompleted'] as int?) ?? 0,
            sessionDurationMin: (extra['sessionDurationMin'] as int?) ?? 0,
            avgAccuracy: (extra['avgAccuracy'] as double?) ?? 1.0,
            streakDays: (extra['streakDays'] as int?) ?? 0,
            showWorkoutSummaryAfterContinue:
                (extra['showWorkoutSummaryAfterCoins'] as bool?) ?? false,
            workoutSummary: extra['workoutSummary'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.coinHistory,
        builder: (context, state) => const CoinHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.shop,
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: AppRoutes.cosmeticDetail,
        builder: (context, state) {
          final cosmetic = state.extra as CosmeticModel;
          return CosmeticDetailScreen(cosmetic: cosmetic);
        },
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
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
