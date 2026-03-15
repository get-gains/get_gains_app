import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/logger.dart';
import '../../../../providers/router_provider.dart';
import '../providers/workout_session_provider.dart';

/// Navigates to the workout session screen if a session is active,
/// otherwise navigates to the home screen.
///
/// Used by recording/results screens to ensure consistent "close" behavior
/// that respects the active workout context.
void navigateToWorkoutParentOrHome(BuildContext context, WidgetRef ref) {
  final sessionState = ref.read(workoutSessionProvider);
  final stateType = sessionState.runtimeType;
  if (sessionState is WorkoutSessionActive) {
    AppLogger.debug(
      'Navigating to workout session (state: $stateType, sessionId: ${sessionState.session.id})',
      tag: 'WorkoutNavigation',
    );
    context.go(AppRoutes.workoutSession, extra: {'readOnly': true});
  } else {
    AppLogger.debug(
      'Navigating to home (state: $stateType — no active session)',
      tag: 'WorkoutNavigation',
    );
    context.go(AppRoutes.home);
  }
}
