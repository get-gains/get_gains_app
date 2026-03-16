import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../data/guidance_repository.dart';
import '../../data/models/tour_step_model.dart';

part 'tour_provider.g.dart';

// ---------------------------------------------------------------------------
// Tour state — hand-written sealed class (per constitution Provider Lifecycle)
// ---------------------------------------------------------------------------

/// State for the active tour.
sealed class TourState {
  const TourState();
}

/// No tour is active.
class TourIdle extends TourState {
  const TourIdle();
}

/// A tour is in progress.
class TourActive extends TourState {
  const TourActive({
    required this.tourId,
    required this.steps,
    required this.currentStepIndex,
  });

  final String tourId;
  final List<TourStepModel> steps;
  final int currentStepIndex;

  /// The current step being shown.
  TourStepModel get currentStep => steps[currentStepIndex];

  /// Whether we are on the last step.
  bool get isLastStep => currentStepIndex >= steps.length - 1;

  /// Human-readable progress label (e.g. "2 of 5").
  String get progress => '${currentStepIndex + 1} of ${steps.length}';
}

/// A tour was just completed (transient — automatically returns to Idle).
class TourCompleted extends TourState {
  const TourCompleted({required this.tourId});

  final String tourId;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

@riverpod
class TourNotifier extends _$TourNotifier {
  @override
  TourState build() => const TourIdle();

  /// Begin a spotlight tour. No-op if a tour is already active.
  void startTour(String tourId, List<TourStepModel> steps) {
    if (state is TourActive) {
      AppLogger.warning(
        'startTour($tourId) ignored — tour already active',
        tag: 'TourNotifier',
      );
      return;
    }
    if (steps.isEmpty) {
      AppLogger.warning(
        'startTour($tourId) ignored — empty step list',
        tag: 'TourNotifier',
      );
      return;
    }
    AppLogger.debug(
      'Starting tour: $tourId (${steps.length} steps)',
      tag: 'TourNotifier',
    );
    state = TourActive(tourId: tourId, steps: steps, currentStepIndex: 0);
  }

  /// Advance to the next step, or complete if on the last step.
  void advance() {
    final current = state;
    if (current is! TourActive) return;

    if (current.isLastStep) {
      _complete(current.tourId);
    } else {
      state = TourActive(
        tourId: current.tourId,
        steps: current.steps,
        currentStepIndex: current.currentStepIndex + 1,
      );
    }
  }

  /// Skip the remaining tour and mark complete.
  void skip() {
    final current = state;
    if (current is! TourActive) return;
    _complete(current.tourId);
  }

  /// Internal: mark tour completed, persist the flag, return to idle.
  void _complete(String tourId) {
    AppLogger.debug('Tour completed: $tourId', tag: 'TourNotifier');

    // Persist via GuidanceRepository
    ref.read(guidanceRepositoryProvider).markCompleted(tourId);

    state = TourCompleted(tourId: tourId);

    // Transition to idle on next micro-task so listeners see TourCompleted.
    Future.microtask(() {
      if (state is TourCompleted) {
        state = const TourIdle();
      }
    });
  }
}
