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
    required String id,
    required SubscriptionStatus status,
    required int tierLevel,
    required DateTime currentPeriodEnd,
  }) = _TodaySubscriptionInfo;

  factory TodaySubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      _$TodaySubscriptionInfoFromJson(json);
}

/// Top-level response model for GET /api/today.
@freezed
abstract class TodayStatusModel with _$TodayStatusModel {
  const factory TodayStatusModel({
    required bool isSubscribed,
    required bool hasCoach,
    TodaySubscriptionInfo? subscription,
    TodayWorkoutDetails? coachToday,
    TodayWorkoutDetails? standaloneToday,
  }) = _TodayStatusModel;

  factory TodayStatusModel.fromJson(Map<String, dynamic> json) =>
      _$TodayStatusModelFromJson(json);
}

/// Today's workout details — shared shape for coach and standalone responses.
@freezed
abstract class TodayWorkoutDetails with _$TodayWorkoutDetails {
  const factory TodayWorkoutDetails({
    required bool isRestDay,
    String? programRoutineId,
    int? dayNumber,
    String? programName,
    String? routineName,
    @Default(0) int exerciseCount,
    @Default(0) int estimatedMinutes,
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
    return TodayRoutineModel(
      isRestDay: false,
      today: TodayRoutineDetails(
        programRoutineId: programRoutineId!,
        dayNumber: dayNumber ?? 1,
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
