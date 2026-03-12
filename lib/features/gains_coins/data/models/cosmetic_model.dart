import 'package:freezed_annotation/freezed_annotation.dart';

part 'cosmetic_model.freezed.dart';
part 'cosmetic_model.g.dart';

@freezed
abstract class CosmeticModel with _$CosmeticModel {
  const factory CosmeticModel({
    required String id,
    required String name,
    String? description,
    required int tier,
    required int coinCost,
    required String category,
    required String previewImageUrl,
    required String unityAssetRef,
    @Default('ACTIVE') String status,
    @Default(0) int sortOrder,
  }) = _CosmeticModel;

  factory CosmeticModel.fromJson(Map<String, dynamic> json) =>
      _$CosmeticModelFromJson(json);
}
