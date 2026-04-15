/// Guidance Feature
///
/// In-app guidance and onboarding system including:
/// - Spotlight coach-mark tours for first-time users
/// - Contextual help via info icons on every screen
/// - Screen-by-screen guidance explaining components and metrics
///
/// Usage:
/// ```dart
/// import 'package:get_gains_app/features/guidance/guidance.dart';
///
/// // Access repository
/// final repo = ref.read(guidanceRepositoryProvider);
///
/// // Start a tour
/// ref.read(tourProvider.notifier).startTour('routine_detail', kRoutineDetailTourSteps);
/// ```
library;

export 'data/data.dart';
export 'presentation/presentation.dart';
