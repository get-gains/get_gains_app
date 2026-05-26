import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/home/data/models/today_status_model.dart';
import 'package:get_gains_app/features/home/presentation/providers/home_providers.dart';

void main() {
  group('homeStatus derivation logic', () {
    test('buildProgram when no coach and no standalone program', () {
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

    test('hasRoutine when non-subscribed user has standalone program', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(
          isSubscribed: false,
          hasCoach: true,
          standaloneToday: TodayWorkoutDetails(
            isRestDay: false,
            programRoutineId: 'sr_1',
            routineName: 'Leg Day',
          ),
        ),
      );
      expect(status, HomeStatus.hasRoutine);
    });

    test('restDay when non-subscribed user has standalone rest day', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(
          isSubscribed: false,
          hasCoach: true,
          standaloneToday: TodayWorkoutDetails(isRestDay: true),
        ),
      );
      expect(status, HomeStatus.restDay);
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

    test('hasRoutine when subscribed user without coach has standalone program', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(
          isSubscribed: true,
          hasCoach: false,
          standaloneToday: TodayWorkoutDetails(
            isRestDay: false,
            programRoutineId: 'sr_1',
            routineName: 'Pull Day',
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

  if (s.standaloneToday != null) {
    return s.standaloneToday!.isRestDay
        ? HomeStatus.restDay
        : HomeStatus.hasRoutine;
  }

  return HomeStatus.buildProgram;
}
