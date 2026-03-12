import 'package:freezed_annotation/freezed_annotation.dart';

part 'equipped_cosmetic_model.freezed.dart';
part 'equipped_cosmetic_model.g.dart';

@freezed
abstract class EquippedCosmeticModel with _$EquippedCosmeticModel {
  const factory EquippedCosmeticModel({
    required String cosmeticId,
    required String category,
    required String unityAssetRef,
    required DateTime equippedAt,
  }) = _EquippedCosmeticModel;

  factory EquippedCosmeticModel.fromJson(Map<String, dynamic> json) =>
      _$EquippedCosmeticModelFromJson(json);
}
