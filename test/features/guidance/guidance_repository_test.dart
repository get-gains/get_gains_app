import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/auth/services/user_preferences_service.dart';
import 'package:get_gains_app/features/guidance/data/guidance_repository.dart';

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

  /// Expose the store for assertions.
  Map<String, String> get store => Map.unmodifiable(_store);
}

void main() {
  late FakeUserPreferencesService fakePrefs;
  late GuidanceRepository repo;

  setUp(() {
    fakePrefs = FakeUserPreferencesService();
    repo = GuidanceRepository(prefs: fakePrefs);
  });

  group('GuidanceRepository', () {
    test('isCompleted returns false for unknown screenId', () {
      expect(repo.isCompleted('unknown_screen'), isFalse);
    });

    test('isCompleted returns false when not marked', () {
      expect(repo.isCompleted(GuidanceRepository.kHome), isFalse);
      expect(repo.isCompleted(GuidanceRepository.kRecording), isFalse);
    });

    test('markCompleted sets flag to true', () {
      repo.markCompleted(GuidanceRepository.kHome);
      expect(repo.isCompleted(GuidanceRepository.kHome), isTrue);
    });

    test('markCompleted uses correct Hive key pattern', () {
      repo.markCompleted(GuidanceRepository.kRoutineDetail);
      expect(fakePrefs.store['tour_completed_routine_detail'], equals('true'));
    });

    test('resetTour removes the flag so tour re-triggers', () {
      repo.markCompleted(GuidanceRepository.kViewForm);
      expect(repo.isCompleted(GuidanceRepository.kViewForm), isTrue);

      repo.resetTour(GuidanceRepository.kViewForm);
      expect(repo.isCompleted(GuidanceRepository.kViewForm), isFalse);
    });

    test('resetAllTours removes all tour flags', () {
      repo.markCompleted(GuidanceRepository.kHome);
      repo.markCompleted(GuidanceRepository.kRecording);
      repo.markCompleted(GuidanceRepository.kResults);
      repo.markCompleted(GuidanceRepository.kWorkoutSession);
      repo.markCompleted(GuidanceRepository.kSetLogger);

      expect(repo.isCompleted(GuidanceRepository.kHome), isTrue);
      expect(repo.isCompleted(GuidanceRepository.kRecording), isTrue);

      repo.resetAllTours();

      expect(repo.isCompleted(GuidanceRepository.kHome), isFalse);
      expect(repo.isCompleted(GuidanceRepository.kRecording), isFalse);
      expect(repo.isCompleted(GuidanceRepository.kResults), isFalse);
      expect(repo.isCompleted(GuidanceRepository.kWorkoutSession), isFalse);
      expect(repo.isCompleted(GuidanceRepository.kSetLogger), isFalse);
    });

    test('multiple markCompleted calls are idempotent', () {
      repo.markCompleted(GuidanceRepository.kHome);
      repo.markCompleted(GuidanceRepository.kHome);
      repo.markCompleted(GuidanceRepository.kHome);
      expect(repo.isCompleted(GuidanceRepository.kHome), isTrue);
    });

    test('screen ID constants are correct', () {
      expect(GuidanceRepository.kHome, equals('home'));
      expect(GuidanceRepository.kRoutineDetail, equals('routine_detail'));
      expect(GuidanceRepository.kViewForm, equals('view_form'));
      expect(GuidanceRepository.kRecording, equals('recording'));
      expect(GuidanceRepository.kResults, equals('results'));
      expect(GuidanceRepository.kWorkoutSession, equals('workout_session'));
      expect(GuidanceRepository.kSetLogger, equals('set_logger'));
    });
  });
}
