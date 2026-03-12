import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_transaction_model.freezed.dart';
part 'coin_transaction_model.g.dart';

@freezed
abstract class CoinTransactionModel with _$CoinTransactionModel {
  const factory CoinTransactionModel({
    required String id,
    required String type,
    required int amount,
    required int balanceAfter,
    int? setCoins,
    double? accuracyMultiplier,
    int? completionBonus,
    int? durationBonus,
    int? streakBonus,
    int? streakValue,
    int? setsCompleted,
    double? avgAccuracy,
    int? sessionDurationMin,
    String? workoutSessionId,
    String? userCosmeticId,
    required DateTime createdAt,
  }) = _CoinTransactionModel;

  factory CoinTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$CoinTransactionModelFromJson(json);
}
