import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Server responses use snake_case (`created_at`, `is_read`, `read_at`);
/// the model expects camelCase (`createdAt`, `isRead`, `readAt`).
Map<String, dynamic> _normalizeNotificationJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);
  out['createdAt'] = out['createdAt'] ?? out['created_at'];
  out['isRead'] = out['isRead'] ?? out['is_read'];
  out['readAt'] = out['readAt'] ?? out['read_at'];
  return out;
}

enum NotificationType {
  @JsonValue('program_assigned')
  programAssigned,
  @JsonValue('coach_subscribed')
  coachSubscribed,
  @JsonValue('roster_removed')
  rosterRemoved,
  @JsonValue('subscription_expiring')
  subscriptionExpiring,
  @JsonValue('mission_raffle_won')
  missionRaffleWon,
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
      _$NotificationModelFromJson(_normalizeNotificationJson(json));
}

extension NotificationModelX on NotificationModel {
  bool get hasDeepLink =>
      type == NotificationType.programAssigned ||
      type == NotificationType.coachSubscribed ||
      type == NotificationType.subscriptionExpiring;
}
