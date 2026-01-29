// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_request_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    _RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(_RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'nickname': instance.nickname,
    };

_GoogleSignInRequest _$GoogleSignInRequestFromJson(Map<String, dynamic> json) =>
    _GoogleSignInRequest(idToken: json['idToken'] as String);

Map<String, dynamic> _$GoogleSignInRequestToJson(
  _GoogleSignInRequest instance,
) => <String, dynamic>{'idToken': instance.idToken};

_CreateUserFromGoogleRequest _$CreateUserFromGoogleRequestFromJson(
  Map<String, dynamic> json,
) => _CreateUserFromGoogleRequest(
  email: json['email'] as String,
  name: json['name'] as String,
  nickname: json['nickname'] as String,
  supabaseId: json['supabaseId'] as String,
);

Map<String, dynamic> _$CreateUserFromGoogleRequestToJson(
  _CreateUserFromGoogleRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'name': instance.name,
  'nickname': instance.nickname,
  'supabaseId': instance.supabaseId,
};

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

_SendRecoveryEmailRequest _$SendRecoveryEmailRequestFromJson(
  Map<String, dynamic> json,
) => _SendRecoveryEmailRequest(email: json['email'] as String);

Map<String, dynamic> _$SendRecoveryEmailRequestToJson(
  _SendRecoveryEmailRequest instance,
) => <String, dynamic>{'email': instance.email};

_ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => _ResetPasswordRequest(
  accessToken: json['accessToken'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  _ResetPasswordRequest instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'newPassword': instance.newPassword,
};
