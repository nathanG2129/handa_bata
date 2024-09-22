class UserProfile {
  final String profileId;
  final String username;
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
  final String email;
  final String birthday;

  UserProfile({
    required this.profileId,
    required this.username,
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
    required this.email,
    required this.birthday,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'username': username,
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
      'email': email,
      'birthday': birthday,
    };
  }

  // Default guest profile
  static final UserProfile guestProfile = UserProfile(
    profileId: 'guest',
    username: 'Guest',
    nickname: 'Guest',
    avatarId: 0,
    badgeShowcase: [],
    bannerId: 0,
    exp: 0,
    expCap: 100,
    hasShownCongrats: false,
    level: 1,
    totalBadgeUnlocked: 0,
    totalStageCleared: 0,
    unlockedBadge: [],
    unlockedBanner: [],
    email: 'guest@example.com',
    birthday: '2000-01-01',
  );
}