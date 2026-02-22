import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../data/coach_repository.dart';
import '../../data/models/coach_model.dart';

part 'coach_profile_provider.g.dart';

// ──────────────────────────────────────────────────────────
// State Classes
// ──────────────────────────────────────────────────────────

/// Sealed state for a single coach profile detail view (ML-1).
sealed class CoachProfileState {
  const CoachProfileState();
}

class CoachProfileInitial extends CoachProfileState {
  const CoachProfileInitial();
}

class CoachProfileLoading extends CoachProfileState {
  const CoachProfileLoading();
}

class CoachProfileLoaded extends CoachProfileState {
  const CoachProfileLoaded({required this.coach});
  final CoachDetailModel coach;
}

class CoachProfileError extends CoachProfileState {
  const CoachProfileError(this.error);
  final AppError error;
}

// ──────────────────────────────────────────────────────────
// Coach Profile Notifier (Family by coachId)
// ──────────────────────────────────────────────────────────

/// Manages a single coach's full public profile.
///
/// This is a **family provider** parameterized by `coachId`, matching the
/// pattern used by `ProgramDetailNotifier` and `RoutineDetailNotifier`.
///
/// Addresses **ML-1**: fetches the new `GET /user/coaches/:coachId` endpoint
/// which returns extended fields (`socialLinks`, etc.) not in the list view.
@riverpod
class CoachProfileNotifier extends _$CoachProfileNotifier {
  @override
  CoachProfileState build(String coachId) => const CoachProfileInitial();

  CoachRepository get _repo => ref.read(coachRepositoryProvider);

  /// Load the full coach profile.
  Future<void> load() async {
    state = const CoachProfileLoading();

    final result = await _repo.getCoachProfile(coachId);

    result.when(
      success: (coach) {
        state = CoachProfileLoaded(coach: coach);
      },
      failure: (error) {
        AppLogger.error(
          'Load coach profile failed: ${error.message}',
          tag: 'CoachProfileNotifier',
        );
        state = CoachProfileError(error);
      },
    );
  }
}
