import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_cosmetic_model.freezed.dart';
part 'user_cosmetic_model.g.dart';

@freezed
abstract class UserCosmeticModel with _$UserCosmeticModel {
  const factory UserCosmeticModel({
    required String id,
    required String cosmeticId,
    required String name,
    String? description,
    required int tier,
    required String category,
    required String previewImageUrl,
    required String unityAssetRef,
    required DateTime purchasedAt,
    @Default(false) bool isEquipped,
  }) = _UserCosmeticModel;

  factory UserCosmeticModel.fromJson(Map<String, dynamic> json) =>
      _$UserCosmeticModelFromJson(json);
}
