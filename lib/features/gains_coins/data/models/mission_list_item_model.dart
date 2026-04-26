/// Partner summary on a mission (from GET /api/missions).
class MissionPartnerModel {
  const MissionPartnerModel({
    required this.id,
    required this.name,
    required this.logoKey,
  });

  final String id;
  final String name;
  final String logoKey;

  factory MissionPartnerModel.fromJson(Map<String, dynamic> json) {
    return MissionPartnerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoKey: json['logoKey'] as String,
    );
  }
}

/// User progress row for a mission.
class UserMissionProgressModel {
  const UserMissionProgressModel({
    required this.id,
    required this.status,
    required this.progress,
    this.completedAt,
  });

  final String id;
  final String status;
  final int progress;
  final DateTime? completedAt;

  factory UserMissionProgressModel.fromJson(Map<String, dynamic> json) {
    return UserMissionProgressModel(
      id: json['id'] as String,
      status: json['status'] as String,
      progress: json['progress'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}

/// One mission card in the missions list.
class MissionListItemModel {
  const MissionListItemModel({
    required this.id,
    this.partnerId,
    required this.title,
    required this.description,
    required this.goalType,
    required this.goalToReach,
    required this.rewardCoins,
    this.rewardTitle,
    this.rewardDescription,
    this.rewardImageKey,
    this.maxWinners,
    required this.isRepeatable,
    this.startsAt,
    this.endsAt,
    this.partner,
    this.userMission,
  });

  final String id;
  final String? partnerId;
  final String title;
  final String description;
  final String goalType;
  final int goalToReach;
  final int rewardCoins;
  final String? rewardTitle;
  final String? rewardDescription;
  final String? rewardImageKey;
  final int? maxWinners;
  final bool isRepeatable;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final MissionPartnerModel? partner;
  final UserMissionProgressModel? userMission;

  int get displayProgress => userMission?.progress ?? 0;

  factory MissionListItemModel.fromJson(Map<String, dynamic> json) {
    return MissionListItemModel(
      id: json['id'] as String,
      partnerId: json['partnerId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      goalType: json['goalType'] as String,
      goalToReach: json['goalToReach'] as int,
      rewardCoins: json['rewardCoins'] as int? ?? 0,
      rewardTitle: json['rewardTitle'] as String?,
      rewardDescription: json['rewardDescription'] as String?,
      rewardImageKey: json['rewardImageKey'] as String?,
      maxWinners: json['maxWinners'] as int?,
      isRepeatable: json['isRepeatable'] as bool? ?? false,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'] as String)
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'] as String)
          : null,
      partner: json['partner'] != null
          ? MissionPartnerModel.fromJson(
              json['partner'] as Map<String, dynamic>,
            )
          : null,
      userMission: json['userMission'] != null
          ? UserMissionProgressModel.fromJson(
              json['userMission'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
