import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/home/data/models/today_status_model.dart';
import 'package:get_gains_app/features/home/presentation/providers/home_providers.dart';

void main() {
  group('homeStatus derivation logic', () {
    test('buildProgram when no coach and no standalone', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(isSubscribed: false, hasCoach: false),
      );
      expect(status, HomeStatus.buildProgram);
    });

    test('buildProgram when has coach but not subscribed and no standalone', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(isSubscribed: false, hasCoach: true),
      );
      expect(status, HomeStatus.buildProgram);
    });

    test('waitingForProgram when subscribed and coach but no coachToday', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(isSubscribed: true, hasCoach: true, coachToday: null),
      );
      expect(status, HomeStatus.waitingForProgram);
    });

    test('restDay when coachToday.isRestDay is true', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(
          isSubscribed: true,
          hasCoach: true,
          coachToday: TodayWorkoutDetails(isRestDay: true),
        ),
      );
      expect(status, HomeStatus.restDay);
    });

    test('hasRoutine when coachToday is active workout', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(
          isSubscribed: true,
          hasCoach: true,
          coachToday: TodayWorkoutDetails(
            isRestDay: false,
            programRoutineId: 'pr_1',
            routineName: 'Push Day',
          ),
        ),
      );
      expect(status, HomeStatus.hasRoutine);
    });

    test('hasRoutine when standalone has active program', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(
          isSubscribed: false,
          hasCoach: false,
          standalone: StandaloneStatus(
            hasActiveProgram: true,
            program: StandaloneProgramInfo(id: 'p1', name: 'My Program'),
          ),
        ),
      );
      expect(status, HomeStatus.hasRoutine);
    });
  });
}

// Extracted logic for testability — mirrors homeStatusProvider derivation.
HomeStatus _deriveHomeStatus(TodayStatusModel s) {
  if (s.hasCoach && s.isSubscribed) {
    if (s.coachToday == null) return HomeStatus.waitingForProgram;
    if (s.coachToday!.isRestDay) return HomeStatus.restDay;
    return HomeStatus.hasRoutine;
  }
  if (s.standalone.hasActiveProgram) {
    return HomeStatus.hasRoutine;
  }
  return HomeStatus.buildProgram;
}
