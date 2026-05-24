import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationType {
  @JsonValue('program_assigned')
  programAssigned,
  @JsonValue('coach_subscribed')
  coachSubscribed,
  @JsonValue('roster_removed')
  rosterRemoved,
  @JsonValue('subscription_expiring')
  subscriptionExpiring,
}

@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    required DateTime createdAt,
    @Default(false) bool isRead,
    DateTime? readAt,
    @Default({}) Map<String, dynamic> data,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}

extension NotificationModelX on NotificationModel {
  bool get hasDeepLink =>
      type == NotificationType.programAssigned ||
      type == NotificationType.coachSubscribed ||
      type == NotificationType.subscriptionExpiring;
}
