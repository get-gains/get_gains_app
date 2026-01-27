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

_ApiErrorResponse _$ApiErrorResponseFromJson(Map<String, dynamic> json) =>
    _ApiErrorResponse(
      errors: (json['errors'] as List<dynamic>)
          .map((e) => ApiError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ApiErrorResponseToJson(_ApiErrorResponse instance) =>
    <String, dynamic>{'errors': instance.errors};

_ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => _ApiError(
  message: json['message'] as String,
  field: json['field'] as String?,
);

Map<String, dynamic> _$ApiErrorToJson(_ApiError instance) => <String, dynamic>{
  'message': instance.message,
  'field': instance.field,
};
