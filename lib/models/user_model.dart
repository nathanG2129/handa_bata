class UserProfile {
  final String profileId;
  final String nickname;
  final int avatarId;
  final List<int> badgeShowcase;
  final int bannerId;
  final int exp;
  final int expCap;
  final bool hasShownCongrats;
  final int level;
  final int totalBadgeUnlocked;
  final int totalStageCleared;
  final List<int> unlockedBadge;
  final List<int> unlockedBanner;
  final String email; // Add email field

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
    required this.email, // Initialize email field
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
      'email': email, // Include email in the map
    };
  }
}