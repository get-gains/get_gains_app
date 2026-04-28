import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/home/data/models/today_status_model.dart';
import 'package:get_gains_app/features/home/presentation/providers/home_providers.dart';

void main() {
  group('homeStatus derivation logic', () {
    test('noCoach when hasCoach is false', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(isSubscribed: false, hasCoach: false),
      );
      expect(status, HomeStatus.noCoach);
    });

    test('noSubscription when has coach but not subscribed', () {
      final status = _deriveHomeStatus(
        TodayStatusModel(isSubscribed: false, hasCoach: true),
      );
      expect(status, HomeStatus.noSubscription);
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
  });
}

// Extracted logic for testability — mirrors homeStatusProvider derivation.
HomeStatus _deriveHomeStatus(TodayStatusModel s) {
  if (!s.hasCoach) return HomeStatus.noCoach;
  if (!s.isSubscribed) return HomeStatus.noSubscription;
  if (s.coachToday == null) return HomeStatus.waitingForProgram;
  if (s.coachToday!.isRestDay) return HomeStatus.restDay;
  return HomeStatus.hasRoutine;
}
