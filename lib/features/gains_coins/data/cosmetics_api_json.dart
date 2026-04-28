/// Coerce nullable / missing string fields from cosmetics API payloads before [fromJson].
/// Prevents `type 'Null' is not a subtype of type 'String'` when the server omits deprecated keys.
String _str(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

Map<String, dynamic> sanitizeUserCosmeticInventoryJson(
  Map<String, dynamic> json,
) {
  return {
    ...json,
    'id': _str(json, 'id'),
    'cosmeticId': _str(json, 'cosmeticId'),
    'name': _str(json, 'name'),
    'category': _str(json, 'category'),
    'previewImageUrl': _str(json, 'previewImageUrl'),
    'unityAssetRef': _str(json, 'unityAssetRef'),
  };
}

Map<String, dynamic> sanitizeEquippedCosmeticJson(Map<String, dynamic> json) {
  return {
    ...json,
    'cosmeticId': _str(json, 'cosmeticId'),
    'category': _str(json, 'category'),
    'unityAssetRef': _str(json, 'unityAssetRef'),
  };
}

Map<String, dynamic> sanitizeShopCosmeticJson(Map<String, dynamic> json) {
  return {
    ...json,
    'id': _str(json, 'id'),
    'name': _str(json, 'name'),
    'category': _str(json, 'category'),
    'previewImageUrl': _str(json, 'previewImageUrl'),
    'unityAssetRef': _str(json, 'unityAssetRef'),
    'status': _str(json, 'status'),
  };
}
