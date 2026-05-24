// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    _NotificationModel(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      data: json['data'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$NotificationModelToJson(_NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
      'isRead': instance.isRead,
      'readAt': instance.readAt?.toIso8601String(),
      'data': instance.data,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.programAssigned: 'program_assigned',
  NotificationType.coachSubscribed: 'coach_subscribed',
  NotificationType.rosterRemoved: 'roster_removed',
  NotificationType.subscriptionExpiring: 'subscription_expiring',
};
