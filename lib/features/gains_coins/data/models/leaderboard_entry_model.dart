import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry_model.freezed.dart';
part 'leaderboard_entry_model.g.dart';

@freezed
abstract class LeaderboardEntryModel with _$LeaderboardEntryModel {
  const factory LeaderboardEntryModel({
    required String userId,
    required String displayName,
    required int rank,
    required int sessionsCompleted,
    required int streakDays,
    required double avgAccuracy,
    required double compositeScore,
    @Default(false) bool isCurrentUser,
  }) = _LeaderboardEntryModel;

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryModelFromJson(json);
}
