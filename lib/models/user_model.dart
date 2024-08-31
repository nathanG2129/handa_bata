class UserProfile {
  String profileId;
  String nickname;
  int avatarId;
  List<int> badgeShowcase;
  int bannerId;
  int exp;
  int expCap;
  bool hasShownCongrats;
  int level;
  int totalBadgeUnlocked;
  int totalStageCleared;
  List<int> unlockedBadge;
  List<int> unlockedBanner;

  UserProfile({
    required this.profileId,
    required this.nickname,
    required this.avatarId,
    required this.badgeShowcase,
    required this.bannerId,
    required this.exp,
    required this.expCap,
    required this.hasShownCongrats,
    required this.level,
    required this.totalBadgeUnlocked,
    required this.totalStageCleared,
    required this.unlockedBadge,
    required this.unlockedBanner,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'nickname': nickname,
      'avatarId': avatarId,
      'badgeShowcase': badgeShowcase,
      'bannerId': bannerId,
      'exp': exp,
      'expCap': expCap,
      'hasShownCongrats': hasShownCongrats,
      'level': level,
      'totalBadgeUnlocked': totalBadgeUnlocked,
      'totalStageCleared': totalStageCleared,
      'unlockedBadge': unlockedBadge,
      'unlockedBanner': unlockedBanner,
    };
  }
}