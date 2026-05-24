import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_stats_model.freezed.dart';
part 'profile_stats_model.g.dart';

@freezed
abstract class ProfileStatsModel with _$ProfileStatsModel {
  const factory ProfileStatsModel({
    @Default(0) int workoutsThisWeek,
    @Default(0) int setsToday,
    @Default(0) int streakDays,
    @Default(0) int allTimeWorkouts,
    @Default(0) int allTimeSets,
    @Default(0) int totalMinutesWeek,
    @Default(false) bool completedToday,
    String? weekStart,
    String? weekEnd,
    @Default([]) List<String> sessionDates,
  }) = _ProfileStatsModel;

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileStatsModelFromJson(json);
}
