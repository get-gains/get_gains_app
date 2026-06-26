import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../features/subscription/data/models/subscription_model.dart';
import '../../../../features/workout/data/models/today_routine_model.dart';
import '../../../../features/workout/data/models/routine_model.dart';

part 'today_status_model.freezed.dart';
part 'today_status_model.g.dart';

/// Lightweight subscription info returned by GET /api/today.
/// Uses [SubscriptionStatus] from [SubscriptionModel] for shared enum.
@freezed
abstract class TodaySubscriptionInfo with _$TodaySubscriptionInfo {
  const factory TodaySubscriptionInfo({
    @Default('') String id,
    @Default(SubscriptionStatus.expired) SubscriptionStatus status,
    @Default(0) int tierLevel,
    required DateTime currentPeriodEnd,
  }) = _TodaySubscriptionInfo;

  factory TodaySubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      _$TodaySubscriptionInfoFromJson(json);
}

/// Top-level response model for GET /api/today.
@freezed
abstract class TodayStatusModel with _$TodayStatusModel {
  const factory TodayStatusModel({
    /// True when the current user account is a coach.
    @Default(false) bool isCoach,

    required bool isSubscribed,

    /// True when the current user has an active coach relationship
    /// as a client (`subscribed_coach.ended_at IS NULL`).
    required bool hasCoach,
    TodaySubscriptionInfo? subscription,
    TodayWorkoutDetails? coachToday,
    @Default(StandaloneStatus()) StandaloneStatus standalone,
  }) = _TodayStatusModel;

  factory TodayStatusModel.fromJson(Map<String, dynamic> json) =>
      _$TodayStatusModelFromJson(json);
}

/// Standalone (free-tier) program status returned by GET /api/today.
@freezed
abstract class StandaloneStatus with _$StandaloneStatus {
  const factory StandaloneStatus({
    @Default(false) bool hasActiveProgram,
    StandaloneProgramInfo? program,
  }) = _StandaloneStatus;

  factory StandaloneStatus.fromJson(Map<String, dynamic> json) =>
      _$StandaloneStatusFromJson(json);
}

/// Lightweight standalone program info.
@freezed
abstract class StandaloneProgramInfo with _$StandaloneProgramInfo {
  const factory StandaloneProgramInfo({
    required String id,
    required String name,
  }) = _StandaloneProgramInfo;

  factory StandaloneProgramInfo.fromJson(Map<String, dynamic> json) =>
      _$StandaloneProgramInfoFromJson(json);
}

/// Today's workout details — shared shape for coach and standalone responses.
@freezed
abstract class TodayWorkoutDetails with _$TodayWorkoutDetails {
  const factory TodayWorkoutDetails({
    required bool isRestDay,
    String? programRoutineId,
    String? dayOfWeek,
    int? dayNumber,
    String? programName,
    String? routineName,
    @Default(0) int exerciseCount,
    @Default(0) int estimatedMinutes,
    @Default(false) bool completedToday,
  }) = _TodayWorkoutDetails;

  factory TodayWorkoutDetails.fromJson(Map<String, dynamic> json) =>
      _$TodayWorkoutDetailsFromJson(json);
}

/// Converts [TodayWorkoutDetails] to [TodayRoutineModel] for workout screens.
extension TodayWorkoutDetailsX on TodayWorkoutDetails {
  TodayRoutineModel toRoutineModel() {
    if (isRestDay || programRoutineId == null) {
      return const TodayRoutineModel(isRestDay: true);
    }

    final resolvedDayOfWeek = _resolveDayOfWeek(dayOfWeek, dayNumber);

    return TodayRoutineModel(
      isRestDay: false,
      completedToday: completedToday,
      today: TodayRoutineDetails(
        programRoutineId: programRoutineId!,
        dayOfWeek: resolvedDayOfWeek,
        assignedProgramId: '',
        programName: programName ?? '',
        routine: RoutineModel(
          id: programRoutineId!,
          name: routineName ?? '',
          description: '',
          estimatedDurationMinutes: estimatedMinutes,
          exercises: const [],
        ),
      ),
    );
  }
}

String _resolveDayOfWeek(String? dayOfWeek, int? dayNumber) {
  final normalizedDayOfWeek = dayOfWeek?.trim().toUpperCase();
  if (normalizedDayOfWeek != null && normalizedDayOfWeek.isNotEmpty) {
    return normalizedDayOfWeek;
  }

  const weekdayOrder = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  if (dayNumber == null) {
    return weekdayOrder[DateTime.now().weekday - 1];
  }

  final normalizedIndex =
      ((dayNumber - 1) % weekdayOrder.length + weekdayOrder.length) %
      weekdayOrder.length;
  return weekdayOrder[normalizedIndex];
}
