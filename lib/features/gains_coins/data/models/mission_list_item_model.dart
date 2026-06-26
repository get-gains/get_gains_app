/// Partner summary on a mission (from GET /api/missions).
class MissionPartnerModel {
  const MissionPartnerModel({
    required this.id,
    required this.name,
    required this.logoKey,
    required this.bio,
    required this.socialLinks,
  });

  final String id;
  final String name;
  final String logoKey;
  final String bio;
  final List<String> socialLinks;

  factory MissionPartnerModel.fromJson(Map<String, dynamic> json) {
    return MissionPartnerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoKey: json['logoKey'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      socialLinks: (json['socialLinks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Coupon attached to a mission reward.
class MissionCouponModel {
  const MissionCouponModel({
    required this.id,
    required this.offerTag,
    this.description,
    required this.discountPercent,
    required this.claimed,
  });

  final String id;
  final String offerTag;
  final String? description;
  final int discountPercent;
  final bool claimed;

  factory MissionCouponModel.fromJson(Map<String, dynamic> json) {
    return MissionCouponModel(
      id: json['id'] as String,
      offerTag: json['offerTag'] as String? ?? 'mission-20-off',
      description: json['description'] as String?,
      discountPercent: json['discountPercent'] as int? ?? 20,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}

/// Raffle state for a mission reward.
class MissionRaffleModel {
  const MissionRaffleModel({
    required this.entryCount,
    required this.isWinner,
    this.winnerRank,
  });

  final int entryCount;
  final bool isWinner;
  final int? winnerRank;

  factory MissionRaffleModel.fromJson(Map<String, dynamic> json) {
    return MissionRaffleModel(
      entryCount: json['entryCount'] as int? ?? 0,
      isWinner: json['isWinner'] as bool? ?? false,
      winnerRank: json['winnerRank'] as int?,
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
    required this.rewardType,
    required this.rewardCoins,
    this.rewardTitle,
    this.rewardDescription,
    this.rewardImageKey,
    this.maxWinners,
    required this.isRepeatable,
    required this.isClosed,
    this.startsAt,
    this.endsAt,
    this.partner,
    this.coupon,
    this.raffle,
    this.userMission,
  });

  final String id;
  final String? partnerId;
  final String title;
  final String description;
  final String goalType;
  final int goalToReach;
  final String rewardType;
  final int rewardCoins;
  final String? rewardTitle;
  final String? rewardDescription;
  final String? rewardImageKey;
  final int? maxWinners;
  final bool isRepeatable;
  final bool isClosed;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final MissionPartnerModel? partner;
  final MissionCouponModel? coupon;
  final MissionRaffleModel? raffle;
  final UserMissionProgressModel? userMission;

  int get displayProgress => userMission?.progress ?? 0;
  bool get isCompleted => userMission?.status == 'completed';

  factory MissionListItemModel.fromJson(Map<String, dynamic> json) {
    return MissionListItemModel(
      id: json['id'] as String,
      partnerId: json['partnerId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      goalType: json['goalType'] as String,
      goalToReach: json['goalToReach'] as int,
      rewardType: json['rewardType'] as String? ?? 'COINS',
      rewardCoins: json['rewardCoins'] as int? ?? 0,
      rewardTitle: json['rewardTitle'] as String?,
      rewardDescription: json['rewardDescription'] as String?,
      rewardImageKey: json['rewardImageKey'] as String?,
      maxWinners: json['maxWinners'] as int?,
      isRepeatable: json['isRepeatable'] as bool? ?? false,
      isClosed: json['isClosed'] as bool? ?? false,
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
      coupon: json['coupon'] != null
          ? MissionCouponModel.fromJson(
              json['coupon'] as Map<String, dynamic>,
            )
          : null,
      raffle: json['raffle'] != null
          ? MissionRaffleModel.fromJson(
              json['raffle'] as Map<String, dynamic>,
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
