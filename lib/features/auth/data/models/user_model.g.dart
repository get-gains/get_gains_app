// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  nickname: json['nickname'] as String,
  supabaseId: json['supabaseId'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'nickname': instance.nickname,
      'supabaseId': instance.supabaseId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_PartialUserModel _$PartialUserModelFromJson(Map<String, dynamic> json) =>
    _PartialUserModel(
      email: json['email'] as String,
      supabaseId: json['supabaseId'] as String,
    );

Map<String, dynamic> _$PartialUserModelToJson(_PartialUserModel instance) =>
    <String, dynamic>{
      'email': instance.email,
      'supabaseId': instance.supabaseId,
    };
