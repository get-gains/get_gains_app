// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) =>
    _AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(_AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

_RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    _RegisterResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegisterResponseToJson(_RegisterResponse instance) =>
    <String, dynamic>{'user': instance.user};

_GoogleSignInResponse _$GoogleSignInResponseFromJson(
  Map<String, dynamic> json,
) => _GoogleSignInResponse(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  user: PartialUserModel.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GoogleSignInResponseToJson(
  _GoogleSignInResponse instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'user': instance.user,
};

_TokenRefreshResponse _$TokenRefreshResponseFromJson(
  Map<String, dynamic> json,
) => _TokenRefreshResponse(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
);

Map<String, dynamic> _$TokenRefreshResponseToJson(
  _TokenRefreshResponse instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
};
