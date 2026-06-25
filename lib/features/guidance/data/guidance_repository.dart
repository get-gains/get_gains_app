import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../../auth/services/user_preferences_service.dart';

part 'guidance_repository.g.dart';

/// Manages tour completion flags in Hive via [UserPreferencesService].
///
/// All flags use the pattern `tour_completed_{screenId}` with value `"true"`.
class GuidanceRepository {
  GuidanceRepository({required UserPreferencesService prefs}) : _prefs = prefs;

  final UserPreferencesService _prefs;

  static const String _prefix = 'tour_completed_';

  // Screen ID constants
  static const String kHome = 'home';
  static const String kRoutineDetail = 'routine_detail';
  static const String kViewForm = 'view_form';
  static const String kRecording = 'recording';
  static const String kResults = 'results';
  static const String kWorkoutSession = 'workout_session';
  static const String kSetLogger = 'set_logger';
  static const String kCoachHome = 'coach_home';

  /// All known screen IDs for reset operations.
  static const List<String> _allScreenIds = [
    kHome,
    kRoutineDetail,
    kViewForm,
    kRecording,
    kResults,
    kWorkoutSession,
    kSetLogger,
    kCoachHome,
  ];

  /// Returns `true` if the tour for [screenId] has been completed.
  bool isCompleted(String screenId) {
    return _prefs.readRaw('$_prefix$screenId') == 'true';
  }

  /// Marks the tour for [screenId] as completed.
  void markCompleted(String screenId) {
    _prefs.cacheRaw('$_prefix$screenId', 'true');
    AppLogger.debug(
      'Tour marked completed: $screenId',
      tag: 'GuidanceRepository',
    );
  }

  /// Resets the tour for [screenId] so it triggers again on next visit.
  void resetTour(String screenId) {
    _prefs.deleteRaw('$_prefix$screenId');
    AppLogger.debug('Tour reset: $screenId', tag: 'GuidanceRepository');
  }

  /// Resets all tour completion flags.
  void resetAllTours() {
    for (final screenId in _allScreenIds) {
      _prefs.deleteRaw('$_prefix$screenId');
    }
    AppLogger.info('All tours reset', tag: 'GuidanceRepository');
  }
}

/// Provides a singleton [GuidanceRepository] backed by Hive.
@Riverpod(keepAlive: true)
GuidanceRepository guidanceRepository(Ref ref) {
  final prefs = ref.watch(userPreferencesServiceProvider);
  return GuidanceRepository(prefs: prefs);
}
