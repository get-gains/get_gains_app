import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_balance_model.freezed.dart';
part 'coin_balance_model.g.dart';

@freezed
abstract class CoinBalanceModel with _$CoinBalanceModel {
  const factory CoinBalanceModel({
    required int currentBalance,
    required int lifetimeEarned,
    required int lifetimeSpent,
    DateTime? updatedAt,
  }) = _CoinBalanceModel;

  factory CoinBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$CoinBalanceModelFromJson(json);
}
