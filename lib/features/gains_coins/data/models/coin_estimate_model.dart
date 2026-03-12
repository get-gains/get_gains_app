import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_estimate_model.freezed.dart';
part 'coin_estimate_model.g.dart';

@freezed
abstract class CoinEstimateModel with _$CoinEstimateModel {
  const factory CoinEstimateModel({
    required int estimatedTotal,
    required int setCoins,
    required double accuracyMultiplier,
    required String accuracyLabel,
    required int completionBonus,
    required int durationBonus,
    required int streakBonus,
    required int streakValue,
    required int setsCompleted,
    required int sessionDurationMin,
    @Default(true) bool isEstimate,
  }) = _CoinEstimateModel;

  factory CoinEstimateModel.fromJson(Map<String, dynamic> json) =>
      _$CoinEstimateModelFromJson(json);
}
