import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/auth/services/user_preferences_service.dart';
import 'package:get_gains_app/features/guidance/data/guidance_repository.dart';
import 'package:get_gains_app/features/guidance/data/models/tour_step_model.dart';
import 'package:get_gains_app/features/guidance/presentation/providers/tour_provider.dart';

/// In-memory fake of [UserPreferencesService] for testing.
class FakeUserPreferencesService extends Fake
    implements UserPreferencesService {
  final Map<String, String> _store = {};

  @override
  void cacheRaw(String key, String value) {
    _store[key] = value;
  }

  @override
  String? readRaw(String key) {
    return _store[key];
  }

  @override
  void deleteRaw(String key) {
    _store.remove(key);
  }
}

const _testSteps = [
  TourStepModel(
    targetKey: 'step_one',
    title: 'Step One',
    body: 'First step',
    order: 0,
  ),
  TourStepModel(
    targetKey: 'step_two',
    title: 'Step Two',
    body: 'Second step',
    order: 1,
  ),
  TourStepModel(
    targetKey: 'step_three',
    title: 'Step Three',
    body: 'Third step',
    order: 2,
  ),
];

void main() {
  late ProviderContainer container;
  late FakeUserPreferencesService fakePrefs;

  setUp(() {
    fakePrefs = FakeUserPreferencesService();
    container = ProviderContainer(
      overrides: [userPreferencesServiceProvider.overrideWithValue(fakePrefs)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TourNotifier', () {
    test('initial state is TourIdle', () {
      final state = container.read(tourProvider);
      expect(state, isA<TourIdle>());
    });

    test('startTour transitions to TourActive', () {
      container.read(tourProvider.notifier).startTour('test_tour', _testSteps);

      final state = container.read(tourProvider);
      expect(state, isA<TourActive>());
      final active = state as TourActive;
      expect(active.tourId, equals('test_tour'));
      expect(active.currentStepIndex, equals(0));
      expect(active.steps.length, equals(3));
      expect(active.currentStep.targetKey, equals('step_one'));
      expect(active.isLastStep, isFalse);
      expect(active.progress, equals('1 of 3'));
    });

    test('advance increments step index', () {
      container.read(tourProvider.notifier).startTour('test_tour', _testSteps);
      container.read(tourProvider.notifier).advance();

      final state = container.read(tourProvider);
      expect(state, isA<TourActive>());
      final active = state as TourActive;
      expect(active.currentStepIndex, equals(1));
      expect(active.currentStep.targetKey, equals('step_two'));
      expect(active.progress, equals('2 of 3'));
    });

    test('advance on last step transitions to TourCompleted', () async {
      container.read(tourProvider.notifier).startTour('test_tour', _testSteps);
      container.read(tourProvider.notifier).advance(); // -> step 1
      container.read(tourProvider.notifier).advance(); // -> step 2 (last)
      container.read(tourProvider.notifier).advance(); // -> complete

      final state = container.read(tourProvider);
      expect(state, isA<TourCompleted>());
      final completed = state as TourCompleted;
      expect(completed.tourId, equals('test_tour'));

      // Verify Hive flag was written
      final repo = container.read(guidanceRepositoryProvider);
      expect(repo.isCompleted('test_tour'), isTrue);

      // After microtask, should return to idle
      await Future.delayed(Duration.zero);
      final afterState = container.read(tourProvider);
      expect(afterState, isA<TourIdle>());
    });

    test('skip transitions to TourCompleted', () async {
      container.read(tourProvider.notifier).startTour('test_tour', _testSteps);
      container.read(tourProvider.notifier).skip();

      final state = container.read(tourProvider);
      expect(state, isA<TourCompleted>());

      // Verify Hive flag was written
      final repo = container.read(guidanceRepositoryProvider);
      expect(repo.isCompleted('test_tour'), isTrue);

      // After microtask, should return to idle
      await Future.delayed(Duration.zero);
      final afterState = container.read(tourProvider);
      expect(afterState, isA<TourIdle>());
    });

    test('startTour while active is a no-op', () {
      container.read(tourProvider.notifier).startTour('first', _testSteps);
      container.read(tourProvider.notifier).startTour('second', _testSteps);

      final state = container.read(tourProvider);
      expect(state, isA<TourActive>());
      final active = state as TourActive;
      expect(active.tourId, equals('first'));
    });

    test('startTour with empty steps is a no-op', () {
      container.read(tourProvider.notifier).startTour('empty', const []);

      final state = container.read(tourProvider);
      expect(state, isA<TourIdle>());
    });

    test('advance when idle is a no-op', () {
      container.read(tourProvider.notifier).advance();

      final state = container.read(tourProvider);
      expect(state, isA<TourIdle>());
    });

    test('skip when idle is a no-op', () {
      container.read(tourProvider.notifier).skip();

      final state = container.read(tourProvider);
      expect(state, isA<TourIdle>());
    });

    test(
      'full tour lifecycle: Idle -> Active -> advance x3 -> Complete -> Idle',
      () async {
        // Start
        final notifier = container.read(tourProvider.notifier);
        expect(container.read(tourProvider), isA<TourIdle>());

        notifier.startTour('lifecycle', _testSteps);
        expect(container.read(tourProvider), isA<TourActive>());

        // Advance through all steps
        notifier.advance(); // 0 -> 1
        expect(
          (container.read(tourProvider) as TourActive).currentStepIndex,
          equals(1),
        );

        notifier.advance(); // 1 -> 2
        expect(
          (container.read(tourProvider) as TourActive).currentStepIndex,
          equals(2),
        );
        expect((container.read(tourProvider) as TourActive).isLastStep, isTrue);

        notifier.advance(); // 2 -> complete
        expect(container.read(tourProvider), isA<TourCompleted>());

        // Wait for microtask
        await Future.delayed(Duration.zero);
        expect(container.read(tourProvider), isA<TourIdle>());
      },
    );
  });
}
